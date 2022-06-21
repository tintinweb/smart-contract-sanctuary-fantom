// SPDX-License-Identifier: MIT-0
// (c) 2022 Ooze.Finance team
pragma solidity ^0.8.9;

// solhint-disable not-rely-on-time

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./include/IOozeSwap.sol";
import "./include/IERC20Taxable.sol";

/**
 * @dev Slime Token / Internal Dex (Manhole)
 *
 *
 * Deployment Requirements:
 *  1. This must be set as a tax exempt sender for the Ooze token (for tax-free buys).
 *  2. OozeTaxVault is a tax exempt recipient for the Ooze token.
 *  3. Marketing Wallet is a tax exempt recipient for the Ooze token.
 *  4. Accounts adding liquidity must approve this contract for Ooze and USDC
 *  5. Accounts removing liquidity must approve this contract for Slime
 *  6. Swaps require approval for the incoming token.
 */

contract SlimeToken is ERC20, Pausable, AccessControl, IOozeSwap {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private constant TRANSFER_FAILED = "TRANSFER FAILED";

    // Liquidity Pair
    address public tokenAddress;
    IERC20Taxable private token;

    address public constant COLLATERAL_TOKEN_ADDRESS = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    IERC20 private constant COLLATERAL_TOKEN = IERC20(COLLATERAL_TOKEN_ADDRESS);

    // Stats
    uint256 private lastBalanceTime;
    uint256 private trackingInterval = 5 seconds;

    /**
     * @dev  In the period immediately following launch, there will be
     *       a substantial early sales tax for predetermined duration of time,
     *       planned for 8 days. During this time, an additional amount of tax, expressed
     *       as a percentage, will be deducted from the transferred amount on sells to the dex.
     *       The early tax rate declines from its setting linearly over the course of
     *       the early sell tax duration (ie the additional tax is
     *
     *     let t = number of seconds remaining until early tax period ends, rounded down to the
     *             nearest multiple of 3600 seconds (1 hour)
     *                                                        t
     *     effectiveEarlyTax = earlySellTax *   --------------------------------
     *                                           length of early tax period
     *
     *        such that as time approaches the end of the duration, the additional tax approaches 0.
     */
    uint8 public earlySellTax = 40;
    uint256 public earlyTaxStart = 0;
    uint256 public earlyTaxDuration = 0;

    /**
     * @dev During the same earlySellTax period, a portion of the taxes are earmarked for marketing purposes.
     *      marketingShare reflects that portion, and when applicable, that portion of taxes is transferred to
     *      the marketing wallet
     */
    uint8 public marketingShare = 30;
    address public marketingWallet;

    // Tax Vault for early sell tax
    address public oozeTaxVault;

    // Events
    event TokenPurchase(address indexed buyer, uint256 indexed collateralSold, uint256 indexed tokensBought);
    event CollateralPurchase(address indexed buyer, uint256 indexed tokensSold, uint256 indexed collateralBought);
    event TaxPaid(address from, address vault, uint256 amount);
    event TaxPaidToMarketingWallet(address from, address marketingWallet, uint256 amount);
    event Price(uint256 price, uint256 tokenReserves, uint256 collateralReserves, uint256 supply);

    event AddLiquidity(address indexed provider, uint256 indexed collateralAmount, uint256 indexed tokenAmount);
    event RemoveLiquidity(address indexed provider, uint256 indexed collateralAmount, uint256 indexed tokenAmount);
    event Liquidity(address indexed provider, uint256 indexed amount);

    constructor(address owner, address oozeTokenAddress) ERC20("SlimeToken", "SLIME") {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(PAUSER_ROLE, owner);
        _grantRole(MINTER_ROLE, owner);

        tokenAddress = oozeTokenAddress;
        token = IERC20Taxable(oozeTokenAddress);

        lastBalanceTime = block.timestamp;
    }

    /**
     * Decimals set to 6 to match USDC
     */
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    /************************************************
     * Admin Methods                                *
     ************************************************/

    /**
     * @dev Set tracking interval.
     * A more frequent interval may be useful at launch.
     */
    function setTrackingInterval(uint256 interval) external onlyRole(DEFAULT_ADMIN_ROLE) {
        trackingInterval = interval;
    }

    /**
     * @dev Taxes, exclusive of those earmarked for marketing, go to the tax vault.
     */
    function setTaxVaultAddress(address _newVaultAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        oozeTaxVault = _newVaultAddress;
    }

    /**
     * @dev During the initial run-in period, A portion of transfer taxes go to the marketing wallet.
     */
    function setMarketingAddress(address _newMarketingAddress, uint8 share) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(share <= 40, "Invalid marketing share amount");
        marketingShare = share;
        marketingWallet = _newMarketingAddress;
    }

    /**
     * @dev Set the early sell tax parameters. Under no circumstances should the additional sell tax exceed 40%
     */
    function setEarlySellTax(
        uint8 tax,
        uint256 start,
        uint256 duration
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tax <= 40, "Invalid Early Sell tax amount");
        require(start > block.timestamp, "Early tax period must start in the future");
        require(earlyTaxStart == 0 || block.timestamp < earlyTaxStart, "Early tax start can't be changed after it has started");

        earlySellTax = tax;
        earlyTaxStart = start;
        earlyTaxDuration = duration;
    }

    /************************************************
     * Do not receive native currency               *
     ************************************************/

    // solhint-disable-next-line payable-fallback
    fallback() external {}

    /************************************************
     * Exchange Pricing functions                   *
     ************************************************/

    /* *
     * @dev Pricing function for converting between Collateral && Tokens.
     * @param inputAmount Amount of Collateral or Tokens being sold.
     * @param inputReserve Amount of Collateral or Tokens (input type) in exchange reserves.
     * @param outputReserve Amount of Collateral or Tokens (output type) in exchange reserves.
     * @return Amount of Collateral or Tokens bought.
     */
    function getInputPrice(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "INVALID_VALUE");
        uint256 inputAmountWithFee = inputAmount * 997;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 1000) + inputAmountWithFee;
        return numerator / denominator;
    }

    /* *
     * @dev Pricing function for converting between Collateral && Tokens.
     * @param outputAmount Amount of Collateral or Tokens being bought.
     * @param inputReserve Amount of Collateral or Tokens (input type) in exchange reserves.
     * @param outputReserve Amount of Collateral or Tokens (output type) in exchange reserves.
     * @return Amount of Collateral or Tokens sold.
     */
    function getOutputPrice(
        uint256 outputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "INVALID_VALUE");
        uint256 numerator = inputReserve * outputAmount * 1000;
        uint256 denominator = (outputReserve - outputAmount) * 997;
        return numerator / denominator;
    }

    /*********************************************************
     * Swap Collateral for Tokens Implementation - No Tax    *
     ********************************************************/

    /**
     * @notice Convert Collateral to Tokens.
     * @dev User specifies exact input  && minimum output.
     * @param minTokens Minimum Tokens bought.
     * @return Amount of Tokens bought.
     */
    function collateralToTokenSwapInput(uint256 collateralSold, uint256 minTokens) external whenNotPaused returns (uint256) {
        require(collateralSold > 0 && minTokens > 0, "INVALID_VALUE");
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 collateralReserve = COLLATERAL_TOKEN.balanceOf(address(this));

        uint256 tokensBought = getInputPrice(collateralSold, collateralReserve, tokenReserve);
        require(tokensBought >= minTokens);
        require(COLLATERAL_TOKEN.transferFrom(msg.sender, address(this), collateralSold), TRANSFER_FAILED);
        require(token.transfer(msg.sender, tokensBought), TRANSFER_FAILED);

        emit TokenPurchase(msg.sender, collateralSold, tokensBought);
        trackStats();
        return tokensBought;
    }

    /**
     * @notice Convert Collateral to Tokens.
     * @dev User specifies maximum input && exact output.
     * @param tokensBought Amount of tokens bought.
     * @return Amount of Collateral sold.
     */
    function collateralToTokenSwapOutput(uint256 tokensBought, uint256 maxCollateral) external whenNotPaused returns (uint256) {
        require(tokensBought > 0 && maxCollateral > 0);
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 collateralReserve = COLLATERAL_TOKEN.balanceOf(address(this));
        uint256 collateralSold = getOutputPrice(tokensBought, collateralReserve, tokenReserve);

        require(collateralSold <= maxCollateral);

        require(COLLATERAL_TOKEN.transferFrom(msg.sender, address(this), collateralSold), TRANSFER_FAILED);
        require(token.transfer(msg.sender, tokensBought), TRANSFER_FAILED);

        emit TokenPurchase(msg.sender, collateralSold, tokensBought);
        trackStats();
        return collateralSold;
    }

    /*********************************************************
     * Swap Tokens for Collateral Implementation - Taxed     *
     ********************************************************/

    /**
     * @dev Helper price function for token input
     * @param tokensSold Amount of Tokens sold.
     * @return collateralOutput Amount of Collateral that can be bought with input Tokens.
     * @return toVault Amount to be sent to tax vault
     * @return toMarketingWallet Amount for marketing wallet
     */
    function _getTokenToCollateralInputPriceWithTax(uint256 tokensSold, address seller)
        private
        view
        returns (
            uint256 collateralOutput,
            uint256 toVault,
            uint256 toMarketingWallet
        )
    {
        require(tokensSold > 0, "TOKENS SOLD MUST BE > 0");

        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 collateralReserve = COLLATERAL_TOKEN.balanceOf(address(this));

        (uint256 defaultTaxRate1e12, uint256 taxRate1e12, uint256 extraTaxRate, uint256 marketingTax) = calculateSalesTax(seller);
        toVault = 0;

        uint256 effectiveTokensSold = tokensSold;

        // Reduce the number of tokens to exchange to satisfy tax requirements
        if (taxRate1e12 > 0) {
            uint256 taxAmount = (tokensSold * taxRate1e12) / 100e12;
            // Calculate remaining tokens for sale
            effectiveTokensSold -= taxAmount;

            // Transfer tax charged by the dex
            uint256 defaultTaxAmount = (defaultTaxRate1e12 * tokensSold) / 100e12;

            // Distribute taxes
            if (extraTaxRate > 0) {
                toMarketingWallet = (marketingTax * tokensSold) / 100e12;
                toVault = taxAmount - defaultTaxAmount - toMarketingWallet;
            } else {
                toMarketingWallet = taxAmount - defaultTaxAmount;
            }
        }

        // Calculate price for remaining tokens after tax has been deducted
        collateralOutput = getInputPrice(effectiveTokensSold, tokenReserve, collateralReserve);
    }

    /**
     * @notice Helper price function for Token to Collateral trades with an exact output, with Taxes
     * @param collateralOutput Amount of output Collateral.
     * @return tokensSold Amount of Tokens needed to buy output Collateral.
     * @return toVault Amount to be sent to tax vault
     * @return toMarketingWallet Amount for marketing wallet
     */
    function _getTokenToCollateralOutputPriceWithTax(uint256 collateralOutput, address seller)
        private
        view
        returns (
            uint256 tokensSold,
            uint256 toVault,
            uint256 toMarketingWallet
        )
    {
        require(collateralOutput > 0, "COLLATERAL OUTPUT MUST BE > 0");

        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 collateralReserve = COLLATERAL_TOKEN.balanceOf(address(this));

        // Determine the number of tokens needed to get the expected output
        uint256 baseTokensSold = getOutputPrice(collateralOutput, tokenReserve, collateralReserve);

        // Get Tax rates
        (uint256 defaultTaxRate1e12, uint256 taxRate1e12, uint256 extraTaxRate, uint256 marketingTax) = calculateSalesTax(seller);

        tokensSold = baseTokensSold;
        toVault = 0;

        // Increase the number of tokens to exchange to account for the added tax
        if (taxRate1e12 > 0) {
            tokensSold = (baseTokensSold * 100e12) / (100e12 - taxRate1e12);
            uint256 taxAmount = tokensSold - baseTokensSold;

            // Transfer tax charged by the dex
            uint256 defaultTaxAmount = (defaultTaxRate1e12 * tokensSold) / 100e12;

            // Distribute taxes
            if (extraTaxRate > 0) {
                toMarketingWallet = (marketingTax * tokensSold) / 100e12;
                toVault = taxAmount - defaultTaxAmount - toMarketingWallet;
            } else {
                toMarketingWallet = taxAmount - defaultTaxAmount;
            }
        }
    }

    /**
     * @dev Helper function to effect the final transfer of tokens in and collateral out.
     * Also distributes the additional taxes, if any.
     */
    function _tokenToCollateral(
        address seller,
        uint256 tokensSold,
        uint256 collateralOutput,
        uint256 toVault,
        uint256 toMarketingWallet
    ) private returns (uint256) {
        // Since transfer taxes are proportional to the amount, transfer the whole amount here and then distribute the additional taxes
        require(token.transferFrom(seller, address(this), tokensSold));

        // Distribute any extra taxes to the tax vault
        if (toVault > 0) {
            require(token.transfer(oozeTaxVault, toVault));
            emit TaxPaid(seller, oozeTaxVault, toVault);
        }
        // Distribute Marketing share to the marketing wallet
        if (toMarketingWallet > 0) {
            require(token.transfer(marketingWallet, toMarketingWallet));
            emit TaxPaidToMarketingWallet(seller, marketingWallet, toMarketingWallet);
        }
        // Send the collateral
        require(COLLATERAL_TOKEN.transfer(seller, collateralOutput));

        emit CollateralPurchase(seller, tokensSold, collateralOutput);
        trackStats();
        return collateralOutput;
    }

    /**
     * @notice Convert Tokens to Collateral.
     * @dev User specifies exact input && minimum output.
     * @param tokensSold Amount of Tokens sold.
     * @param minCollateral Minimum Collateral purchased.
     * @return Amount of Collateral bought.
     */
    function tokenToCollateralSwapInput(uint256 tokensSold, uint256 minCollateral) external whenNotPaused returns (uint256) {
        require(tokensSold > 0 && minCollateral > 0);

        (uint256 collateralOutput, uint256 toVault, uint256 toMarketingWallet) = _getTokenToCollateralInputPriceWithTax(tokensSold, msg.sender);

        require(collateralOutput >= minCollateral);

        return _tokenToCollateral(msg.sender, tokensSold, collateralOutput, toVault, toMarketingWallet);
    }

    /**
     * @notice Convert Tokens to Collateral.
     * @dev User specifies maximum input && exact output.
     * @param collateralOutput Amount of Collateral purchased.
     * @param maxTokens Maximum Tokens sold.
     * @return Amount of Tokens sold.
     */
    function tokenToCollateralSwapOutput(uint256 collateralOutput, uint256 maxTokens) external whenNotPaused returns (uint256) {
        require(collateralOutput > 0);

        (uint256 tokensSold, uint256 toVault, uint256 toMarketingWallet) = _getTokenToCollateralOutputPriceWithTax(collateralOutput, msg.sender);

        // tokens sold is always > 0
        require(maxTokens >= tokensSold);

        return _tokenToCollateral(msg.sender, tokensSold, collateralOutput, toVault, toMarketingWallet);
    }

    /*******************************
     * Stats                     *
     *******************************/

    /**
     * @dev Track statistics that will be useful.
     * These do not need to be reported every transaction, but with some predetermined frequency
     * May be useful to develop price data over time, etc.
     */
    function trackStats() private {
        if (block.timestamp - lastBalanceTime > trackingInterval) {
            // This is useful for charting, but will lag on the last transaction
            uint256 price = getCollateralToTokenOutputPrice(1e18);
            (uint256 tokenReserves, uint256 collateralReserves) = getReserves();

            emit Price(price, tokenReserves, collateralReserves, totalSupply());

            lastBalanceTime = block.timestamp;
        }
    }

    /*******************************
     * Getters                     *
     *******************************/

    /**
     * @dev Get liquidity reserves.
     * @return tokenBalance
     * @return collateralBalance
     */
    function getReserves() public view returns (uint256, uint256) {
        return (token.balanceOf(address(this)), COLLATERAL_TOKEN.balanceOf(address(this)));
    }

    /**
     * @dev Calculate the sales tax for the specific seller
     * @return defaultTaxRate1e12 The tax rate charged by the dex
     * @return taxRate1e12 Total tax rate for this seller
     * @return extraTax Rate of extra tax (may be adjusted for marketing)
     * @return marketingTax Rate to apply to marketing
     */
    function calculateSalesTax(address seller)
        public
        view
        returns (
            uint256 defaultTaxRate1e12,
            uint256 taxRate1e12,
            uint256 extraTax,
            uint256 marketingTax
        )
    {
        defaultTaxRate1e12 = token.calculateTransferTaxRate(seller, address(this)) * 1e12;
        taxRate1e12 = defaultTaxRate1e12;

        extraTax = 0;

        // During the early sell period, up to a specified percentage of collected taxes is directed toward marketing, but no more than
        // the additional tax collected from early sells.
        // This amount is calculated here too, and deducted from extra tax

        // Apply early sell tax
        if (oozeTaxVault != address(0) && taxRate1e12 > 0 && block.timestamp >= earlyTaxStart && block.timestamp < earlyTaxStart + earlyTaxDuration) {
            // Additional tax declines semi-linearly with time to 0 over earlyTaxDuration seconds. Stair-steps at 3600 seconds to minimize
            // variation from ui to execution
            uint256 timeLeft = earlyTaxDuration - (block.timestamp - earlyTaxStart);
            timeLeft -= timeLeft % 3600; // Round down to the hour
            extraTax = (uint256(earlySellTax) * 1e12 * timeLeft) / earlyTaxDuration;
            taxRate1e12 += extraTax;

            // Calculate the marketing Share
            if (marketingWallet != address(0)) {
                marketingTax = (marketingShare * taxRate1e12) / 100;
                if (marketingTax > extraTax) {
                    marketingTax = extraTax;
                    extraTax = 0;
                } else {
                    extraTax -= marketingTax;
                }
            }
        }
    }

    /**
     * @notice Public price function for collateral to Token trades with an exact input.
     * @param collateralSold Amount of Collateral sold.
     * @return tokensBought Amount of Tokens that can be bought with input collateral.
     */
    function getCollateralToTokenInputPrice(uint256 collateralSold) external view returns (uint256) {
        require(collateralSold > 0);
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 collateralReserve = COLLATERAL_TOKEN.balanceOf(address(this));

        return getInputPrice(collateralSold, collateralReserve, tokenReserve);
    }

    /**
     * @notice Public price function for collateral to Token trades with an exact output.
     * @param tokensBought Amount of Tokens bought.
     * @return collateralSold Amount of collateral needed to buy output Tokens.
     */
    function getCollateralToTokenOutputPrice(uint256 tokensBought) public view returns (uint256) {
        require(tokensBought > 0);
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 collateralReserve = COLLATERAL_TOKEN.balanceOf(address(this));
        return getOutputPrice(tokensBought, collateralReserve, tokenReserve);
    }

    /**
     * @notice Public price function for Token to collateral trades with an exact input.
     * Does not account for any taxes.
     * @param tokensSold Amount of Tokens sold.
     * @return collateralBought Amount of Collateral that can be bought with input Tokens.
     */
    function getTokenToCollateralInputPrice(uint256 tokensSold) external view returns (uint256) {
        require(tokensSold > 0, "token sold < 0");
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 collateralReserve = COLLATERAL_TOKEN.balanceOf(address(this));

        return getInputPrice(tokensSold, tokenReserve, collateralReserve);
    }

    /**
     * @notice Public price function for Token to Collateral trades with an exact output.
     * Does not account for any taxes.
     * @param collateralBought Amount of output Collateral.
     * @return tokensSold Amount of Tokens needed to buy output Collateral.
     */
    function getTokenToCollateralOutputPrice(uint256 collateralBought) external view returns (uint256) {
        require(collateralBought > 0);
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 collateralReserve = COLLATERAL_TOKEN.balanceOf(address(this));

        return getOutputPrice(collateralBought, tokenReserve, collateralReserve);
    }

    /**
     * @notice Public price function for Token to collateral trades with an exact input, with taxes
     * @param tokensSold Amount of Tokens sold.
     * @return collateralOutput Amount of Collateral that can be bought with input Tokens.
     */
    function getTokenToCollateralInputPriceWithTax(uint256 tokensSold, address seller) external view returns (uint256 collateralOutput) {
        (collateralOutput, , ) = _getTokenToCollateralInputPriceWithTax(tokensSold, seller);
    }

    /**
     * @notice Public price function for Token to Collateral trades with an exact output, with Taxes
     * @param collateralOutput Amount of output Collateral.
     * @return tokensSold Amount of Tokens needed to buy output Collateral.
     */
    function getTokenToCollateralOutputPriceWithTax(uint256 collateralOutput, address seller) external view returns (uint256 tokensSold) {
        (tokensSold, , ) = _getTokenToCollateralOutputPriceWithTax(collateralOutput, seller);
    }

    /*******************************
     * Liquidity Implementation    *
     *******************************/

    /**
     * @notice Deposit Collateral && Tokens (token) at current ratio to mint LP tokens.
     * @dev minLiquidity does nothing when total LP supply is 0.
     * @param minLiquidity Minimum number of LPs sender will mint if total LP supply is greater than 0.
     * @param maxTokens Maximum number of tokens deposited. Deposits max amount if total LP supply is 0.
     * @return uint256 The amount of LP minted.
     */
    function addLiquidity(
        uint256 collateral,
        uint256 minLiquidity,
        uint256 maxTokens
    ) external returns (uint256) {
        // Role requirements and pause-ability are a bit more complicated here.
        // We allow the DEFAULT_ADMIN_ROLE to add liquidity even if paused.

        require((hasRole(MINTER_ROLE, msg.sender) && !paused()) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        require(maxTokens > 0 && collateral > 0, "Invalid arguments");
        uint256 totalLiquidity = totalSupply();

        if (totalLiquidity > 0) {
            require(minLiquidity > 0, "Invalid minLiquidity");
            uint256 collateralReserve = COLLATERAL_TOKEN.balanceOf(address(this));
            uint256 tokenReserve = token.balanceOf(address(this));

            // Tokens to pair = tokenReserve * (collateral/collateralReserve)
            // Or proportion of token reserve corresponding to proportion of collateral
            // i.e. if the collateral injected is 1% of the collateral reserve, the number of tokens to pair is 1% of the token reserve
            // +1 to avoid 0s. This is the amount of ooze tokens to add to correspond to added collateral
            uint256 tokenAmount = ((collateral * tokenReserve) / collateralReserve) + 1;

            // LP pairs created = collateral injected * (total liquidity in tokens/collateral reserve)
            // or the number of tokens that is the same proportion of tokens to total as collateral to collateral reserve.
            // Number of new LPs to mint
            uint256 liquidityMinted = (collateral * totalLiquidity) / collateralReserve;

            require(maxTokens >= tokenAmount && liquidityMinted >= minLiquidity, "Liquidity out of range");

            // Transfer both assets to contract
            require(token.transferFrom(msg.sender, address(this), tokenAmount), "Token Transfer Failed");
            require(COLLATERAL_TOKEN.transferFrom(msg.sender, address(this), collateral), "Collateral Transfer Failed");

            // Add LPs
            _mint(msg.sender, liquidityMinted);

            emit AddLiquidity(msg.sender, collateral, tokenAmount);
            emit Liquidity(msg.sender, balanceOf(msg.sender));
            return liquidityMinted;
        } else {
            require(token.transferFrom(msg.sender, address(this), maxTokens), "Token Transfer Failed");
            require(COLLATERAL_TOKEN.transferFrom(msg.sender, address(this), collateral), "Collateral Transfer Failed");

            // Mint LPs equal in amount to collateral injected
            _mint(msg.sender, collateral);

            emit AddLiquidity(msg.sender, collateral, maxTokens);
            emit Liquidity(msg.sender, balanceOf(msg.sender));
            return collateral;
        }
    }

    /**
     * @dev Burn LP tokens to withdraw Collateral && Tokens at current ratio.
     * @param amount Amount of LP burned.
     * @param minCollateral Minimum Collateral withdrawn.
     * @param minTokens Minimum Tokens withdrawn.
     * @return (uint256, uint256) The amount of Collateral && Tokens withdrawn.
     */
    function removeLiquidity(
        uint256 amount,
        uint256 minCollateral,
        uint256 minTokens
    ) external returns (uint256, uint256) {
        // Role requirements and pause-ability are a bit more complicated here.
        // We allow the DEFAULT_ADMIN_ROLE to withdraw owned lp tokens even if paused.
        // However, the caller must still be in possession of the LP tokens to be burned.
        // Initial liquidity will be stored in the LiquidityVault contract, which has a 1-week time-lock
        // delay on transfers. Therefore, initial liquidity can only be accessed in emergency fashion
        // by triggering the emergency withdraw on the LiquidityVault, which emits the BeginEmergencyWithdrawal
        // event, and delays withdrawal for one week.

        require((hasRole(MINTER_ROLE, msg.sender) && !paused()) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        require(amount > 0 && minCollateral > 0 && minTokens > 0, "Invalid arguments");
        uint256 totalLiquidity = totalSupply();

        require(totalLiquidity > 0, "No Liquidity");
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 collateralReserve = COLLATERAL_TOKEN.balanceOf(address(this));

        uint256 collateralAmount = (amount * collateralReserve) / totalLiquidity;
        uint256 tokenAmount = (amount * tokenReserve) / totalLiquidity;

        require(collateralAmount >= minCollateral && tokenAmount >= minTokens, "insufficient amount");

        _burn(msg.sender, amount);
        require(COLLATERAL_TOKEN.transfer(msg.sender, collateralAmount), "Collateral transfer failed");
        require(token.transfer(msg.sender, tokenAmount), "Token transfer failed");

        emit RemoveLiquidity(msg.sender, collateralAmount, tokenAmount);
        emit Liquidity(msg.sender, balanceOf(msg.sender));
        return (collateralAmount, tokenAmount);
    }

    /*******************************
     * Pausable Implementation     *
     *******************************/

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!paused() || hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT-0
// (c) 2022 Ooze.Finance team

pragma solidity ^0.8.9;

interface IOozeSwap {
    /**
     * @dev Pricing function for converting between Collateral && Tokens.
     * @param inputAmount Amount of Collateral or Tokens being sold.
     * @param inputReserve Amount of Collateral or Tokens (input type) in exchange reserves.
     * @param outputReserve Amount of Collateral or Tokens (output type) in exchange reserves.
     * @return Amount of Collateral or Tokens bought.
     */
    function getInputPrice(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) external pure returns (uint256);

    /**
     * @dev Pricing function for converting between Collateral && Tokens.
     * @param outputAmount Amount of Collateral or Tokens being bought.
     * @param inputReserve Amount of Collateral or Tokens (input type) in exchange reserves.
     * @param outputReserve Amount of Collateral or Tokens (output type) in exchange reserves.
     * @return Amount of Collateral or Tokens sold.
     */
    function getOutputPrice(
        uint256 outputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) external pure returns (uint256);

    /**
     * @notice Convert Collateral to Tokens.
     * @dev User specifies exact input && minimum output.
     * @param minTokens Minimum Tokens bought.
     * @return Amount of Tokens bought.
     */
    function collateralToTokenSwapInput(uint256 collateralSold, uint256 minTokens) external returns (uint256);

    /**
     * @notice Convert Collateral to Tokens.
     * @dev User specifies maximum input && exact output.
     * @param tokensBought Amount of tokens bought.
     * @return Amount of Collateral sold.
     */
    function collateralToTokenSwapOutput(uint256 tokensBought, uint256 maxCollateral) external returns (uint256);

    /**
     * @notice Convert Tokens to Collateral.
     * @dev User specifies exact input && minimum output.
     * @param tokensSold Amount of Tokens sold.
     * @param minCollateral Minimum Collateral purchased.
     * @return Amount of Collateral bought.
     */
    function tokenToCollateralSwapInput(uint256 tokensSold, uint256 minCollateral) external returns (uint256);

    /**
     * @notice Convert Tokens to Collateral.
     * @dev User specifies maximum input && exact output.
     * @param collateralBought Amount of Collateral purchased.
     * @param maxTokens Maximum Tokens sold.
     * @return Amount of Tokens sold.
     */
    function tokenToCollateralSwapOutput(uint256 collateralBought, uint256 maxTokens) external returns (uint256);

    /*******************************
     * Getters                     *
     *******************************/

    function getReserves() external view returns (uint256, uint256);

    /**
     * @notice Public price function for collateral to Token trades with an exact input.
     * @param collateralSold Amount of Collateral sold.
     * @return Amount of Tokens that can be bought with input collateral.
     */
    function getCollateralToTokenInputPrice(uint256 collateralSold) external view returns (uint256);

    /**
     * @notice Public price function for collateral to Token trades with an exact output.
     * @param tokensBought Amount of Tokens bought.
     * @return Amount of collateral needed to buy output Tokens.
     */
    function getCollateralToTokenOutputPrice(uint256 tokensBought) external view returns (uint256);

    /**
     * @notice Public price function for Token to collateral trades with an exact input.
     * @param tokensSold Amount of Tokens sold.
     * @return Amount of collateral that can be bought with input Tokens.
     */
    function getTokenToCollateralInputPrice(uint256 tokensSold) external view returns (uint256);

    /**
     * @notice Public price function for Token to Collateral trades with an exact output.
     * @param collateralBought Amount of output collateral.
     * @return Amount of Tokens needed to buy output collateral.
     */
    function getTokenToCollateralOutputPrice(uint256 collateralBought) external view returns (uint256);

    /**
     * @notice Public price function for Token to collateral trades with an exact input, with taxes
     * @param tokensSold Amount of Tokens sold.
     * @return collateralOutput Amount of Collateral that can be bought with input Tokens.
     */
    function getTokenToCollateralInputPriceWithTax(uint256 tokensSold, address seller) external view returns (uint256 collateralOutput);

    /**
     * @notice Public price function for Token to Collateral trades with an exact output, with Taxes
     * @param collateralOutput Amount of output Collateral.
     * @return tokensSold Amount of Tokens needed to buy output Collateral.
     */
    function getTokenToCollateralOutputPriceWithTax(uint256 collateralOutput, address seller) external view returns (uint256 tokensSold);

    /*******************************
     * Liquidity Implementation    *
     *******************************/

    /**
     * @notice Deposit Collateral && Tokens (token) at current ratio to mint LP tokens.
     * @dev minLiquidity does nothing when total LP supply is 0.
     * @param minLiquidity Minimum number of LPs sender will mint if total LP supply is greater than 0.
     * @param maxTokens Maximum number of tokens deposited. Deposits max amount if total LP supply is 0.
     * @return uint256 The amount of LP minted.
     */
    function addLiquidity(
        uint256 collateral,
        uint256 minLiquidity,
        uint256 maxTokens
    ) external returns (uint256);

    /**
     * @dev Burn LP tokens to withdraw Collateral && Tokens at current ratio.
     * @param amount Amount of LP burned.
     * @param minCollateral Minimum Collateral withdrawn.
     * @param minTokens Minimum Tokens withdrawn.
     * @return (uint256, uint256) The amount of Collateral && Tokens withdrawn.
     */
    function removeLiquidity(
        uint256 amount,
        uint256 minCollateral,
        uint256 minTokens
    ) external returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT-0
// (c) 2022 Ooze.Finance team

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Taxable is IERC20 {
    function calculateTransferTaxRate(address _from, address _to) external view returns (uint256);

    function calculateTransferTax(
        address _from,
        address _to,
        uint256 _value
    )
        external view
        returns (
            uint256 adjustedValue,
            uint256 taxAmount
        );

    function defaultTaxRate() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}