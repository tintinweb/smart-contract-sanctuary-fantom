/**
 *Submitted for verification at FtmScan.com on 2023-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IERC20 {
    // transfer and tranferFrom have been removed, because they don't work on all tokens (some aren't ERC20 complaint).
    // By removing them you can't accidentally use them.
    // name, symbol and decimals have been removed, because they are optional and sometimes wrongly implemented (MKR).
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

/// @notice Tokenized Vaults with a single underlying EIP-20 token.
interface IERC4626 {
    /// @notice The address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
    function asset() external view returns (IERC20 assetTokenAddress);

    /// @notice Total amount of the underlying asset that is “managed” by Vault.
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /// @notice The amount of shares that the Vault would exchange for the amount of assets provided, in an ideal scenario where all the conditions are met.
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /// @notice The amount of assets that the Vault would exchange for the amount of shares provided, in an ideal scenario where all the conditions are met.
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /// @notice Maximum amount of the underlying asset that can be deposited into the Vault for the receiver, through a deposit call.
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /// @notice Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given current on-chain conditions.
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /// @notice Mints shares Vault shares to receiver by depositing exactly assets of underlying tokens.
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /// @notice Maximum amount of shares that can be minted from the Vault for the receiver, through a mint call.
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /// @notice Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given current on-chain conditions.
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /// @notice Mints exactly shares Vault shares to receiver by depositing assets of underlying tokens.
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /// @notice Maximum amount of the underlying asset that can be withdrawn from the owner balance in the Vault, through a withdraw call.
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /// @notice Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block, given current on-chain conditions.
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /// @notice Burns shares from owner and sends exactly assets of underlying tokens to receiver.
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /// @notice Maximum amount of Vault shares that can be redeemed from the owner balance in the Vault, through a redeem call.
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /// @notice Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block, given current on-chain conditions.
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /// @notice Burns exactly shares from owner and sends assets of underlying tokens to receiver.
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);
}

interface IMlpManager {
    // Returns AUM of MLP for calculating price.
    function getAum(bool maximise) external view returns (uint256);
}

contract PessimisticWmlpOracle {
    IMlpManager public immutable mlpManager;
    IERC20 public immutable mlp;
    IERC4626 public immutable wMlp;

    mapping(uint => uint) public dailyLows; // day => price

    constructor(
        IMlpManager _mlpManager,
        IERC20 _mlp,
        IERC4626 _wMlp
    ) {
        mlpManager = _mlpManager;
        mlp = _mlp;
        wMlp = _wMlp;
    }
    event RecordDailyLow(uint price);

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function _getPrice() internal view returns (uint256) {
        uint256 normalizedPrice = _getNormalizedPrice();
        uint day = block.timestamp / 1 days;
        // get today's low
        uint todaysLow = dailyLows[day];
        if(todaysLow == 0 || normalizedPrice < todaysLow) {
            todaysLow = normalizedPrice;
        }
        
        // get yesterday's low
        uint yesterdaysLow = dailyLows[day - 1];
        
        // calculate price based on two-day low
        uint twoDayLow = todaysLow > yesterdaysLow && yesterdaysLow > 0 ? yesterdaysLow : todaysLow;
        if(twoDayLow > 0 && normalizedPrice > twoDayLow) {
            return twoDayLow;
        }
        
        // if the current price is our lowest, use it
        return normalizedPrice;
    }

    
    /// @notice Gets the current price of wMLP colateral
    /// @return The 48-hour low price of wMLP
    function getPrice() public view returns (uint256) {
        return _getPrice();
    }
    
    function _getNormalizedPrice() internal view returns (uint256 normalizedPrice) {
        uint256 mlpPrice = (uint256(mlpManager.getAum(false)) / mlp.totalSupply());
        //get normalized price
        normalizedPrice = 1e30 / wMlp.convertToAssets(mlpPrice);
    }


    /// @notice Checks current wMLP price and saves the price if it is the day's lowest.
    function updatePrice() external {
        // get normalized price
        uint normalizedPrice = _getNormalizedPrice();
        
        // potentially store price as today's low
        uint day = block.timestamp / 1 days;
        uint todaysLow = dailyLows[day];
        if(todaysLow == 0 || normalizedPrice < todaysLow) {
            dailyLows[day] = normalizedPrice;
            todaysLow = normalizedPrice;
            emit RecordDailyLow(normalizedPrice);
        }
    }


}