// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {BaseStrategy} from "./BaseStrategy.sol";
import {IERC20Upgradeable} from "./IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "./SafeMathUpgradeable.sol";
import {SafeERC20Upgradeable} from "./SafeERC20Upgradeable.sol";
import {IUniswapV2Router02} from "./IUniswapV2Router02.sol";
import {IComptroller} from "./IComptroller.sol";
import {IVToken} from "./IVToken.sol";

contract MyStrategy is BaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    // constant SCREAM address
    address public constant comptroller = 0x260E596DAbE3AFc463e75B6CC05d8c46aCAcFB09;  //Scream unitroller address
    address public constant iToken = 0x4565DC3Ef685E4775cdF920129111DdF43B9d882;      //iToken address scWBtc
    address public constant screamToken = 0xe0654C8e6fd4D733349ac7E09f6f23DA256bF475; //claimComp Token address; SCREAM token
    address public constant wftmToken = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;    //wFtm Token address
    address[] public markets;       //Scream Markets, here is just scWBtc

    // constant swap address using Spooky Swap
    address public constant unirouter = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;   //Spooky Swap address
    address[] public swapToWantRoute;     //Scream -> WFtm -> WBtc, three address

    // variables to configure the risk and leverage
    uint256 public borrowRate;                     // the % percentage of collateral per leverage level
    uint256 public borrowRateMax;                  // a limit for collateral rate per leverage level; Scream official limit is 75%
    uint256 public borrowDepth;                    // the number of leverage levels we will stake and borrow  
    uint256 public minLeverage;                    // the minimum amount of balance to leverage
    uint256 public constant BORROW_DEPTH_MAX = 10; // the maximum number of leverage levels we will stake and borrow      
    uint256 public reserves;                       // need some amount of underlying token (here WBtc) reserve to deleverage 
    uint256 public balanceInPool;                  // overall balance of this strategy in iToken (here scWBtc) 


    // event
    event DepositMoreThanAvailable(uint256 depositAmount, uint256 availableAmount);
    event BorrowConfigureRenew(uint256 borrowRate, uint256 borrowDepth);
    event ComptrollerNotWorking(address comptroller);

    //Emitted when claimComp harvest 
    event ClaimCompHarvest(
        address indexed token,
        uint256 amount,
        uint256 indexed blockNumber,
        uint256 timestamp
    ); 

    //Emitted when withdraw less than want 
    event WithdrawLessThanWant(
        address indexed token,
        uint256 amount,
        uint256 indexed blockNumber,
        uint256 timestamp
    );

    event claimComGain(uint256 _claimCompGain);


    /// @dev Initialize the Strategy with security settings as well as tokens
    /// @notice Proxies will set any non constant variable you declare as default value
    /// @dev add any extra changeable variable at end of initializer as shown
    function initialize(address _vault, address[1] memory _wantConfig) public initializer {
        __BaseStrategy_init(_vault);
        /// @dev Add config here
        want = _wantConfig[0];

        /// @dev set the default value
        borrowRate = 60;   // 60%
        borrowRateMax = 75;   // 75%
        borrowDepth = 5;   // 5
        minLeverage = 1;   // 1

        ///@dev set allownance
        _setAllowances();

        ///@dev swap to want path
        swapToWantRoute = new address[](3);
        swapToWantRoute[0] = screamToken;
        swapToWantRoute[1] = wftmToken;
        swapToWantRoute[2] = want;

        ///@dev enter markets to stake and borrow in Scream
        markets.push(iToken);                             // add the iToken market address
        IComptroller(comptroller).enterMarkets(markets);  // enter scWbtc market for this strategy
    }
    
    /// @dev Return the name of the strategy
    function getName() external pure override returns (string memory) {
        return "StrategyBadger-ScreamWBtc";
    }

    /// @dev Return a list of protected tokens
    /// @notice It's very important all tokens that are meant to be in the strategy to be marked as protected
    /// @notice this provides security guarantees to the depositors they can't be sweeped away
    function getProtectedTokens() public view virtual override returns (address[] memory) {
        address[] memory protectedTokens = new address[](4);
        protectedTokens[0] = want;
        protectedTokens[1] = iToken;
        protectedTokens[2] = wftmToken;
        protectedTokens[3] = screamToken;
        return protectedTokens;
    }

    /// @dev Deposit `_amount` of want, investing it to earn yield
    function _deposit(uint256 _amount) internal override {
        // Add code here to invest `_amount` of want to earn yield 
        uint256 wantBal = availableWant();
        if (_amount > wantBal) {
            emit DepositMoreThanAvailable(_amount, wantBal);            
            _amount = wantBal;
        }
        if (_amount > minLeverage) {
            _leverage(_amount);
        }
    }

    /// @dev Withdraw all funds, this is used for migrations, most of the time for emergency reasons
    /// @notice deleverage all, and send all underlying tokes to vault
    function _withdrawAll() internal override {
        
        _deleverage();
        uint256 wantBal = IERC20Upgradeable(want).balanceOf(address(this));
        IERC20Upgradeable(want).safeTransfer(vault, wantBal);

    }

    /// @dev Withdraw `_amount` of want, so that it can be sent to the vault
    /// @param _amount amount of want to withdraw
    /// @return wantBal amount actually withdrawn
    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        
        uint256 wantBal = availableWant();

        if (wantBal < _amount) {
            _deleverage();
            wantBal = IERC20Upgradeable(want).balanceOf(address(this));
        }

        if (wantBal > _amount) {
            wantBal = _amount;
        }

        IERC20Upgradeable(want).safeTransfer(vault, wantBal);

        //@dev if withdraw less than want, need to emit event, but not revert
        if (wantBal < _amount) {
            uint256 diff = _diff(_amount, wantBal).mul(10_000).div(_amount);
            // uint256 diff = _diff(_amount, wantBal);
            if (diff >= withdrawalMaxDeviationThreshold) {
                emit WithdrawLessThanWant(
                    address(want),
                    diff,
                    block.number,
                    block.timestamp
                );
            } 
        }
        uint256 _avlWantBl = availableWant();
        if ( _avlWantBl > minLeverage) {
            _leverage(_avlWantBl);
        } 

        return wantBal;
    }


    /// @dev Does this function require `tend` to be called?
    function _isTendable() internal override pure returns (bool) {
        return true; // Change to true if the strategy should be tended
    }

    /**
     * @dev harvest the SCREAM token
     * @notice core internal function to harvest
    */
    function _harvest() internal override returns (TokenAmount[] memory harvested) {
        
        // get balance before operation
        uint256 _before = IERC20Upgradeable(want).balanceOf(address(this));

        harvested = new TokenAmount[](1);

        if (IComptroller(comptroller).pendingComptrollerImplementation() == address(0)) 
        {
            // Get the SCREAM Token Reward
            IComptroller(comptroller).claimComp(address(this), markets);
            uint256 outputBal = IERC20Upgradeable(screamToken).balanceOf(address(this));
            harvested[0] = TokenAmount(screamToken, outputBal);
            // Swap from scream token to want token
            IUniswapV2Router02(unirouter).swapExactTokensForTokens(
                outputBal,
                0,
                swapToWantRoute,
                address(this),
                now
            );
            // for calculating the amount harvested
            uint256 _after = IERC20Upgradeable(want).balanceOf(address(this));
            uint256 _claimCompGain = _after.sub(_before);


            /// @notice report the amount of want harvested to the sett and calculate the fee
            /// @notice If consider borrow and supply balance in iToken, the amout is higher than the whole estimated profit.
            // But borrow and supply balance is not leveraged and converted to underlying token, the whole estimated profict
            // is an estimate, not the real profit. There is no need to deleverage and leverage all tokens just to
            // get the real profit.
            emit ClaimCompHarvest(
                    address(want),
                    _claimCompGain,
                    block.number,
                    block.timestamp
            );
            _reportToVault(_claimCompGain);

            // Leverage the underlying token to earn again
            uint256 wantBal = availableWant();
            if (wantBal > minLeverage) {
                _leverage(wantBal);
            }    

        } else {
            //scream is not working, pause now
            _pause();
            _deleverage();
            _removeAllowances();
            harvested[0] = TokenAmount(screamToken, 0);

            emit ComptrollerNotWorking(comptroller);
        }
        return harvested;
    }


    /// @dev Leverage any left want token
    function _tend() internal override returns (TokenAmount[] memory tended){
        // Nothing tended
        uint256 wantBal = availableWant();
        tended = new TokenAmount[](1);

        if(wantBal > minLeverage) {
            _leverage(wantBal);
            tended[0] = TokenAmount(want, wantBal);
        } else {
            tended[0] = TokenAmount(want, 0);
        }
        return tended;
    }

    /// @dev Return the balance (in want) that the strategy has invested somewhere
    function balanceOfPool() public view override returns (uint256) {
        return balanceInPool;
    }

    /// @dev Return the balance of rewards that the strategy has accrued
    /// @notice Used for offChain APY and Harvest Health monitoring
    function balanceOfRewards() public view override returns (TokenAmount[] memory rewards) {
        rewards = new TokenAmount[](1);
        rewards[0] = TokenAmount(screamToken, IERC20Upgradeable(screamToken).balanceOf(address(this)));
        return rewards;
    }

    /*********************************************************************************/
    /*********************************  New Function *********************************/
    /*********************************************************************************/

    /// @dev set allowance
    function _setAllowances() internal {
        IERC20Upgradeable(want).safeApprove(iToken, uint256(-1));
        IERC20Upgradeable(screamToken).safeApprove(unirouter, uint256(-1));
    }

    /// @dev remove allowance
    function _removeAllowances() internal {
        IERC20Upgradeable(want).safeApprove(iToken, 0);
        IERC20Upgradeable(screamToken).safeApprove(unirouter, 0);
    }

    /// @dev get the want token balance minus the reserves
    function availableWant() public view returns (uint256) {
        uint256 wantBal = IERC20Upgradeable(want).balanceOf(address(this));
        return wantBal.sub(reserves);
    }

    /**
     * @dev Repeat to leverage given the _amount, borrowDepth times 
     * @param _amount amount of want to leverage
     * @notice core internal function to leverage
    */
    function _leverage(uint256 _amount) internal {

        require(_amount > minLeverage, "Leverage amount is little!");

        for (uint256 i = 0; i < borrowDepth; i++) {
            //callrout: scWbtc -> implementation -> doTransferIn -> transferFrom
            IVToken(iToken).mint(_amount);
            _amount = _amount.mul(borrowRate).div(100);
            //callrout: scWbtc -> implementation -> doTransferOut -> transfer
            IVToken(iToken).borrow(_amount);
        }

        // reserves + _amount, there is still _amount do not use.
        // to assure have enough reserves to repay the last borrow amount, for the sake of risk
        reserves = reserves.add(_amount);

        updatePoolBalance();
    }

    /**
     * @dev deleverage all
     * @notice core internal function to deleverage
    */
    function _deleverage() internal {

        uint256 wantBal = IERC20Upgradeable(want).balanceOf(address(this));
        uint256 borrowBal = IVToken(iToken).borrowBalanceCurrent(address(this));

        while (wantBal < borrowBal) {
            IVToken(iToken).repayBorrow(wantBal);

            borrowBal = IVToken(iToken).borrowBalanceCurrent(address(this));
            uint256 targetSupply = borrowBal.mul(100).div(borrowRate);

            uint256 supplyBal = IVToken(iToken).balanceOfUnderlying(
                address(this)
            );
            IVToken(iToken).redeemUnderlying(supplyBal.sub(targetSupply));
            wantBal = IERC20Upgradeable(want).balanceOf(address(this));
        }

        IVToken(iToken).repayBorrow(uint256(-1));

        // If there is iToken left, redeem iToken to want token 
        uint256 iTokenBal = IERC20Upgradeable(iToken).balanceOf(address(this));
        IVToken(iToken).redeem(iTokenBal);

        // deleverage all, there is no need to reserve
        reserves = 0;

        updatePoolBalance();
    }

    /**
     * @dev _deleverage() unwinds for many times, so the want token balance may not afford the function call
     * in consideration of gascost. If the current borrowRate is less than borrowRateMax, we can raise the 
     * borrowRate a little to get some more underlying tokens back to afford function call cost.  
     * @param _borrowRate configurable borrow rate in case it's required to unwind successfully
     */
    function deleverageOnce(uint256 _borrowRate) external {
        _onlyAuthorizedActors();

        require(_borrowRate <= borrowRateMax, "Borrow rate too high!");

        uint256 wantBal = IERC20Upgradeable(want).balanceOf(address(this));
        IVToken(iToken).repayBorrow(wantBal);

        uint256 borrowBal = IVToken(iToken).borrowBalanceCurrent(address(this));
        uint256 targetSupply = borrowBal.mul(100).div(_borrowRate);

        uint256 supplyBal = IVToken(iToken).balanceOfUnderlying(address(this));
        IVToken(iToken).redeemUnderlying(supplyBal.sub(targetSupply));

        wantBal = IERC20Upgradeable(want).balanceOf(address(this));
        reserves = wantBal;

        updatePoolBalance();
    }

    /**
     * @dev Updates the risk profile and rebalances the vault funds accordingly.
     * @param _borrowRate percent to borrow on each leverage level.
     * @param _borrowDepth how many levels to leverage the funds.
     */
    function rebalance(uint256 _borrowRate, uint256 _borrowDepth) external
    {
        _onlyAuthorizedActors();

        require(_borrowRate <= borrowRateMax, "Borrow rate too high!");
        require(_borrowDepth <= BORROW_DEPTH_MAX, "Borrow depth too more!");

        _deleverage();
        borrowRate = _borrowRate;
        borrowDepth = _borrowDepth;

        uint256 wantBal = IERC20Upgradeable(want).balanceOf(address(this));
        _leverage(wantBal);

        emit BorrowConfigureRenew(borrowRate, borrowDepth);
    }

    /// @dev update the iToken pool balance based on the supplyBal and borrowBal
    function updatePoolBalance() public {
        uint256 supplyBal = IVToken(iToken).balanceOfUnderlying(address(this));
        uint256 borrowBal = IVToken(iToken).borrowBalanceCurrent(address(this));
        balanceInPool = supplyBal.sub(borrowBal);
    }

    /// @dev pause the strategy from governance or keeper
    function pauseStrategy() external {
        _onlyAuthorizedActors();

        _pause();
        _deleverage();
        _removeAllowances();
    }
 
    /// @dev unpause the strategy from governance or keeper
    function unpauseStrategy() external {
        _onlyAuthorizedActors();
        
        _unpause();
        _setAllowances();
        uint256 wantBal = availableWant();
        if (wantBal > minLeverage) {
            _leverage(wantBal);
        }
    }

}