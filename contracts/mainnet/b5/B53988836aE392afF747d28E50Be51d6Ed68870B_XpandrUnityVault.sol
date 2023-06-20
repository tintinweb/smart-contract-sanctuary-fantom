// SPDX-License-Identifier: No License (None)
// No permissions granted before Sunday, 5th May 2025, then GPL-3.0 after this date.

/** 
@title  - XpandrUnityVault
@author - Nikar0 
@notice - Immutable, streamlined, security & gas considerate unified Vault + Strategy contract.
          Includes: / 0% withdraw fee default / Vault profit in USD /  Deposit & harvest buffers / Timestamp & Slippage protection /


https://www.github.com/nikar0/Xpandr4626  @Nikar0_


Vault based on EIP-4626 by @joey_santoro, @transmissions11, et all.
https://eips.ethereum.org/EIPS/eip-4626

Using solmate libs for ERC20, ERC4626
https://github.com/transmissions11/solmate

Using solady SafeTransferLib
https://github.com/Vectorized/solady/

Special thanks to 543 from Equalizer/Guru_Network for the brainstorming & QA

@notice - AccessControl = modified solmate Owned.sol w/ added Strategist + error codes.
        - Pauser = modified OZ Pausable.sol using uint8 instead of bool + error codes.
**/

pragma solidity ^0.8.19;

import {ERC20, ERC4626, FixedPointMathLib} from "./interfaces/solmate/ERC4626light.sol";
import {SafeTransferLib} from "./interfaces/solady/SafeTransferLib.sol";
import {AccessControl} from "./interfaces/AccessControl.sol";
import {Pauser} from "./interfaces/Pauser.sol";
import {XpandrErrors} from "./interfaces/XpandrErrors.sol";
import {IEqualizerPair} from "./interfaces/IEqualizerPair.sol";
import {IEqualizerRouter} from "./interfaces/IEqualizerRouter.sol";
import {IEqualizerGauge} from "./interfaces/IEqualizerGauge.sol";

//Equalizer EQUAL-FTM

contract XpandrUnityVault is ERC4626, AccessControl, Pauser {
    using FixedPointMathLib for uint;

    /*//////////////////////////////////////////////////////////////
                          VARIABLES & EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event Harvest(address indexed harvester);
    event SetRouterOrGauge(address indexed newRouter, address indexed newGauge);
    event Panic(address indexed caller);
    event SetFeesAndRecipient(uint64 withdrawFee, uint64 totalFees, address indexed newRecipient);
    event SlippageSetDelaySet(uint8 slippage, uint64 delay);
    event SlippageSet(uint8 percent);
    event CustomTx(address indexed from, uint indexed amount);
    event StuckTokens(address indexed caller, uint indexed amount, address indexed token);
    
    // Tokens
    address internal constant wftm = address(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
    address internal constant equal = address(0x3Fd3A0c85B70754eFc07aC9Ac0cbBDCe664865A6);
    address[] internal rewardTokens;
    address[2] internal slippageLPs;

    // 3rd party contracts
    address public gauge;
    address public router;

    // Xpandr addresses
    address public feeRecipient;

    // Fee Structure
    uint64 internal constant FEE_DIVISOR = 1000;               
    uint64 public constant platformFee = 35;                // 3.5% Platform fee cap
    uint64 public withdrawFee;                              // 0% withdraw fee. Logic kept in case spam/economic attacks bypass buffers, can only be set to 0 or 0.1%
    uint64 public treasuryFee = 590;
    uint64 public callFee = 120;
    uint64 public stratFee = 290;  
    uint64 public recipientFee;

    // Controllers
    uint64 internal lastHarvest;                            // Safeguard only allows harvest being called if > delay
    uint64 internal vaultProfit;                            // Excludes performance fees
    uint64 internal delay;
    uint8 internal harvestOnDeposit; 
    uint8 internal slippage;  
    uint8 internal constant slippageDiv = 100;                                                         
    mapping(address => uint64) internal lastUserDeposit;    //Safeguard only allows same user deposits if > delay

    constructor(
        ERC20 _asset,
        address _gauge,
        address _router,
        uint8 _slippage,
        address _strategist
        )
       ERC4626(
            _asset,
            string(abi.encodePacked("XPANDR CHILL-FTM EQUALIZER")),
            string(abi.encodePacked("XpE-CHILL-FTM"))
        )
        {
        gauge = _gauge;
        router = _router;
        strategist = _strategist;
        emit SetStrategist(address(0), strategist);
        delay = 600; // 10 mins
        slippage = _slippage;

        slippageLPs = [address(0x7547d05dFf1DA6B4A2eBB3f0833aFE3C62ABD9a1), address(0x76fa7935a5AFEf7fefF1C88bA858808133058908)];
        rewardTokens.push(equal);
        lastHarvest = uint64(block.timestamp);
        _addAllowance();
    }

    /*//////////////////////////////////////////////////////////////
                          DEPOSIT/WITHDRAW
    //////////////////////////////////////////////////////////////*/

     function depositAll() external {
        deposit(SafeTransferLib.balanceOf(address(asset), msg.sender), msg.sender);
    }

    // Deposit 'asset' into the vault which then deposits funds into the farm.  
    function deposit(uint assets, address receiver) public override whenNotPaused returns (uint shares) {
        if(tx.origin != receiver){revert XpandrErrors.NotAccountOwner();}
        if(lastUserDeposit[receiver] != 0) {if(_timestamp() < lastUserDeposit[receiver] + delay) {revert XpandrErrors.UnderTimeLock();}}
        if(assets > SafeTransferLib.balanceOf(address(asset), receiver)){revert XpandrErrors.OverCap();}
        shares = convertToShares(assets);
        if(assets == 0 || shares == 0){revert XpandrErrors.ZeroAmount();}

        lastUserDeposit[receiver] = _timestamp();
        emit Deposit(receiver, receiver, assets, shares);

        SafeTransferLib.safeTransferFrom(address(asset), receiver, address(this), assets); // Need to transfer before minting or ERC777s could reenter.
        _mint(receiver, shares);
        _earn();

        if(harvestOnDeposit != 0) {afterDeposit(assets, shares);}
    }

    function withdrawAll() external {
        withdraw(SafeTransferLib.balanceOf(address(this), msg.sender), msg.sender, msg.sender);
    }

    // Withdraw 'asset' from farm into vault & sends to receiver.
    function withdraw(uint shares, address receiver, address _owner) public override returns (uint assets) {
        if(tx.origin != receiver && tx.origin != _owner){revert XpandrErrors.NotAccountOwner();}
        if(shares > SafeTransferLib.balanceOf(address(this), _owner)){revert XpandrErrors.OverCap();}
        assets = convertToAssets(shares);
        if(assets == 0 || shares == 0){revert XpandrErrors.ZeroAmount();}
       
        _burn(_owner, shares);
        emit Withdraw(_owner, receiver, _owner, assets, shares);
        _collect(assets);

        uint assetBal = SafeTransferLib.balanceOf(address(asset), address(this));
        if (assetBal > assets) {assetBal = assets;}

        if(withdrawFee != 0){
            uint withdrawFeeAmt = assetBal * withdrawFee / FEE_DIVISOR;
            SafeTransferLib.safeTransfer(address(asset), receiver, assetBal - withdrawFeeAmt);
        } else {SafeTransferLib.safeTransfer(address(asset), receiver, assetBal);}
    }

    function harvest() external {
        if(msg.sender != tx.origin){revert XpandrErrors.NotEOA();}
        if(_timestamp() < lastHarvest + delay){revert XpandrErrors.UnderTimeLock();}
        _harvest(msg.sender);
    }

    function _harvest(address caller) internal whenNotPaused {
        lastHarvest = _timestamp();
        emit Harvest(caller);
        IEqualizerGauge(gauge).getReward(address(this), rewardTokens);
        uint outputBal = SafeTransferLib.balanceOf(equal, address(this));

        if (outputBal != 0 ) {
            _chargeFees(caller);
            _addLiquidity();
        }
        _earn();
    }

    /*//////////////////////////////////////////////////////////////
                             INTERNAL
    //////////////////////////////////////////////////////////////*/

    // Deposits funds in the farm
    function _earn() internal {
        uint assetBal = SafeTransferLib.balanceOf(address(asset), address(this));
        IEqualizerGauge(gauge).deposit(assetBal);
    }

    // Withdraws funds from the farm
    function _collect(uint _amount) internal {
        uint assetBal = SafeTransferLib.balanceOf(address(asset), address(this));
        if (assetBal < _amount) {
            IEqualizerGauge(gauge).withdraw(_amount - assetBal);
        }
    }

    function _chargeFees(address caller) internal {                   
        uint equalBal = SafeTransferLib.balanceOf(equal, address(this));
        uint feeBal = equalBal * platformFee / FEE_DIVISOR;
        uint toProfit = equalBal - feeBal;

        uint usdProfit = IEqualizerPair(slippageLPs[1]).sample(equal, toProfit, 1, 1)[0];
        vaultProfit = vaultProfit + uint64(usdProfit);

        uint callAmt = feeBal * callFee / FEE_DIVISOR;
        SafeTransferLib.safeTransfer(equal, caller, callAmt);

        if(recipientFee != 0){
        uint recipientAmt = feeBal * recipientFee / FEE_DIVISOR;
        SafeTransferLib.safeTransfer(equal, feeRecipient, recipientAmt);
        }

        uint treasuryAmt = feeBal * treasuryFee / FEE_DIVISOR;
        SafeTransferLib.safeTransfer(equal, treasury, treasuryAmt);
                                                
        uint stratAmt = feeBal * stratFee / FEE_DIVISOR;
        SafeTransferLib.safeTransfer(equal, strategist, stratAmt);
    }

    function _addLiquidity() internal {
        uint equalHalf = SafeTransferLib.balanceOf(equal, address(this)) >> 1;
        (uint minAmt) = getSlippage(equalHalf, address(asset), equal);
        IEqualizerRouter(router).swapExactTokensForTokensSimple(equalHalf, minAmt, equal, wftm, false, address(this), lastHarvest);

        uint t1Bal = SafeTransferLib.balanceOf(equal, address(this));
        uint t2Bal = SafeTransferLib.balanceOf(wftm, address(this));
        (uint t1Min, uint t2Min,) = IEqualizerRouter(router).quoteAddLiquidity(equal, wftm, false, t1Bal, t2Bal);
        IEqualizerRouter(router).addLiquidity(equal, wftm, false, t1Bal, t2Bal, t1Min * slippage / slippageDiv, t2Min * slippage / slippageDiv, address(this), lastHarvest);
    }

    /*//////////////////////////////////////////////////////////////
                               VIEWS
    //////////////////////////////////////////////////////////////*/

    // Returns amount of reward in native upon calling the harvest function
    function callReward() public view returns (uint) {
        uint outputBal = IEqualizerGauge(gauge).earned(equal, address(this));
        uint wrappedOut;
        if (outputBal != 0) {
            (wrappedOut,) = IEqualizerRouter(router).getAmountOut(outputBal, equal, wftm);
        } 
        return wrappedOut * platformFee / FEE_DIVISOR * callFee / FEE_DIVISOR;
    }

    function idleFunds() external view returns (uint) {
        return SafeTransferLib.balanceOf(address(asset), address(this));
    }
    
    // Returns total amount of 'asset' held by the vault and contracts it deposits in.
    function totalAssets() public view override returns (uint) {
        return SafeTransferLib.balanceOf(address(asset), address(this)) + balanceOfPool();
    }

    //Return how much 'asset' the vault has working in the farm
    function balanceOfPool() public view returns (uint) {
        return IEqualizerGauge(gauge).balanceOf(address(this));
    }

    // Returns rewards unharvested
    function rewardBalance() external view returns (uint) {
        return IEqualizerGauge(gauge).earned(equal, address(this));
    }

    // Function for UIs to display the current value of 1 vault share
    function getPricePerFullShare() external view returns (uint) {
        return totalSupply == 0 ? 1e18 : totalAssets() * 1e18 / totalSupply;
    }

    function convertToShares(uint assets) public view override returns (uint) {
        uint supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint shares) public view override returns (uint) {
        uint supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function vaultProfits() external view returns (uint64){
        return vaultProfit / 1e6;
    }

    /*//////////////////////////////////////////////////////////////
                             SECURITY
    //////////////////////////////////////////////////////////////*/

    // Pauses the vault & executes emergency withdraw
    function panic() external onlyAdmin {
        pause();
        emit Panic(msg.sender);
        IEqualizerGauge(gauge).withdraw(balanceOfPool());
    }

    function pause() public onlyAdmin {
        _pause();
        _subAllowance();
    }

    function unpause() external whenPaused onlyAdmin {
        _unpause();
        _addAllowance();
        _earn();
    }

    //Guards against timestamp spoofing
    function _timestamp() internal view returns (uint64 timestamp){
        uint lastBlock = IEqualizerPair(slippageLPs[0]).blockTimestampLast();
        timestamp = uint64(lastBlock + 300);
    }

    //Guards against sandwich attacks
    function getSlippage(uint _amount, address _lp, address _token) internal view returns(uint minAmt){
        uint[] memory t1Amts = IEqualizerPair(_lp).sample(_token, _amount, 2, 1);
        minAmt = (t1Amts[0] + t1Amts[1] ) / 2;
        minAmt = minAmt - (minAmt *  slippage / slippageDiv);
    }

    /*//////////////////////////////////////////////////////////////
                               SETTERS
    //////////////////////////////////////////////////////////////*/

    function setFeesAndRecipient(uint64 _withdrawFee, uint64 _callFee, uint64 _treasuryFee, uint64 _stratFee, uint64 _recipientFee, address _recipient) external onlyAdmin {
        if(_withdrawFee != 0 && _withdrawFee != 1){revert XpandrErrors.OverCap();}
        uint64 sum = _callFee + _stratFee + _treasuryFee + _recipientFee;
        if(sum > FEE_DIVISOR){revert XpandrErrors.OverCap();}
        if(_recipient != address(0) && _recipient != feeRecipient){feeRecipient = _recipient;}

        callFee = _callFee;
        stratFee = _stratFee;
        withdrawFee = _withdrawFee;
        treasuryFee = _treasuryFee;
        recipientFee = _recipientFee;
        emit SetFeesAndRecipient(withdrawFee, sum, feeRecipient);
    }

    function setRouterOrGauge(address _router, address _gauge) external onlyOwner {
        if(_router == address(0) || _gauge == address(0)){revert XpandrErrors.ZeroAddress();}
        if(_router != router){router = _router;}
        if(_gauge != gauge){gauge = _gauge;}
        emit SetRouterOrGauge(router, gauge);
    }

    function setHarvestOnDeposit(uint8 _harvestOnDeposit) external onlyAdmin {
        if(_harvestOnDeposit != 0 && _harvestOnDeposit != 1){revert XpandrErrors.OverCap();}
        harvestOnDeposit = _harvestOnDeposit;
    } 

    function setSlippageSetDelay(uint8 _slippage, uint64 _delay) external onlyAdmin{
        if(_delay > 1800 || _delay < 600) {revert XpandrErrors.InvalidDelay();}
        if(_slippage > 5 || _slippage < 1){revert XpandrErrors.OverCap();}

        if(_delay != delay){delay = _delay;}
        if(_slippage != slippage){slippage = _slippage;}
        emit SlippageSetDelaySet(slippage, delay);
    }

    /*//////////////////////////////////////////////////////////////
                               UTILS
    //////////////////////////////////////////////////////////////

    This function exists for cases where a vault may receive sporadic 3rd party rewards such as airdrop from it's deposit in a farm.
    Enables convert that token into more of this vault's reward. */ 
    function customTx(address _token, uint _amount, IEqualizerRouter.Routes[] memory _path) external onlyOwner {
        if(_token == equal || _token == wftm || _token == address(asset)){revert XpandrErrors.InvalidTokenOrPath();}
        uint bal;
        if(_amount == 0) {bal = SafeTransferLib.balanceOf(_token, address(this));}
        else {bal = _amount;}
        
        emit CustomTx(_token, bal);
        SafeTransferLib.safeApprove(_token, router, 0);
        SafeTransferLib.safeApprove(_token, router, type(uint).max);
        IEqualizerRouter(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(bal, 1, _path, address(this), _timestamp());
    }

    //Rescues random funds stuck that the vault can't handle.
    function stuckTokens(address _token, uint _amount) external onlyOwner {
        if(ERC20(_token) == asset){revert XpandrErrors.InvalidTokenOrPath();}
        uint amount;

        if(_amount == 0){amount = SafeTransferLib.balanceOf(_token, address(this));} else {amount = _amount;}
        SafeTransferLib.safeTransfer(_token, msg.sender, amount);
        emit StuckTokens(msg.sender, amount, _token);
    }

    function _subAllowance() internal {
        SafeTransferLib.safeApprove(address(asset), gauge, 0);
        SafeTransferLib.safeApprove(equal, router, 0);
        SafeTransferLib.safeApprove(wftm, router, 0);
    }

    function _addAllowance() internal {
        SafeTransferLib.safeApprove(address(asset), gauge, type(uint).max);
        SafeTransferLib.safeApprove(equal, router, type(uint).max);
        SafeTransferLib.safeApprove(wftm, router, type(uint).max);
    }

    //ERC4626 hook. Called by deposit if harvestOnDeposit = 1. Args unused but part of spec
    function afterDeposit(uint assets, uint shares) internal override {
        _harvest(tx.origin);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IEqualizerGauge {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getReward(address user, address[] memory rewards) external;
    function earned(address token, address user) external view returns (uint256);
    function balanceOf(address user) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

contract XpandrErrors {
    error ZeroAmount();
    error ZeroAddress();
    error NotVault();
    error NotEOA();
    error NotAccountOwner();
    error OverCap();
    error UnderTimeLock();
    error InvalidDelay();
    error InvalidProposal();
    error InvalidTokenOrPath();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH
    /// that disallows any storage writes.
    uint256 internal constant _GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    /// Multiply by a small constant (e.g. 2), if needed.
    uint256 internal constant _GAS_STIPEND_NO_GRIEF = 100000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` (in wei) ETH to `to`.
    /// Reverts upon failure.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gasStipend, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                if iszero(create(amount, 0x0b, 0x16)) {
                    // For better gas estimation.
                    if iszero(gt(gas(), 1000000)) { revert(0, 0) }
                }
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a gas stipend
    /// equal to `_GAS_STIPEND_NO_GRIEF`. This gas stipend is a reasonable default
    /// for 99% of cases and can be overriden with the three-argument version of this
    /// function if necessary.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        // Manually inlined because the compiler doesn't inline functions with branches.
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(_GAS_STIPEND_NO_GRIEF, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                if iszero(create(amount, 0x0b, 0x16)) {
                    // For better gas estimation.
                    if iszero(gt(gas(), 1000000)) { revert(0, 0) }
                }
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// Simply use `gasleft()` for `gasStipend` if you don't need a gas stipend.
    ///
    /// Note: Does NOT revert upon failure.
    /// Returns whether the transfer of ETH is successful instead.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            success := call(gasStipend, to, amount, 0, 0, 0, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            mstore(0x60, amount) // Store the `amount` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x0c, 0x23b872dd000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends all of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferAllFrom(address token, address from, address to)
        internal
        returns (uint256 amount)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            // Store the function selector of `balanceOf(address)`.
            mstore(0x0c, 0x70a08231000000000000000000000000)
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x60, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x00, 0x23b872dd)
            // The `amount` argument is already written to the memory word at 0x6c.
            amount := mload(0x60)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            // Store the function selector of `transfer(address,uint256)`.
            mstore(0x00, 0xa9059cbb000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Sends all of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransferAll(address token, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, address()) // Store the address of the current contract.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x34, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x14, to) // Store the `to` argument.
            // The `amount` argument is already written to the memory word at 0x34.
            amount := mload(0x34)
            // Store the function selector of `transfer(address,uint256)`.
            mstore(0x00, 0xa9059cbb000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            // Store the function selector of `approve(address,uint256)`.
            mstore(0x00, 0x095ea7b3000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `ApproveFailed()`.
                mstore(0x00, 0x3e3f8f73)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    /// Returns zero if the `token` does not exist.
    function balanceOf(address token, address account) internal view returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, account) // Store the `account` argument.
            // Store the function selector of `balanceOf(address)`.
            mstore(0x00, 0x70a08231000000000000000000000000)
            amount :=
                mul(
                    mload(0x20),
                    and( // The arguments of `and` are evaluated from right to left.
                        gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                        staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20)
                    )
                )
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.19;

/**
@notice - Modified version of OZ's Pausable.sol, using uint instead of bool &error codes w/ Ifs 
          instead of requires w/ strings for cheaper gas costs
 */

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */

error NotPaused();
error Paused();

abstract contract Pauser {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event WasPaused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    uint8 public _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = 0;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns 1 if the contract is paused, and 0 otherwise.
     */
    function paused() public view virtual returns (uint8) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        //require(paused() != 0, "Pausable: paused");
        if(paused() != 0){revert Paused();}
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        //require(paused() == 1, "Pausable: not paused");
        if(paused() != 1){revert NotPaused();}

    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = 1;
        emit WasPaused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = 0;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IEqualizerPair {
    function blockTimestampLast() external view returns (uint);
    function sample(address tokenIn, uint amountIn, uint points, uint window) external view returns (uint[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

/**
@notice Based on solmate's Owned.sol with added access control for an operator & error code + if instead of requires.
 */

 error NoAuth();
 error NotStrategist();

abstract contract AccessControl {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);
    event SetStrategist(address indexed user, address indexed newStrategist);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;
    address public strategist;
    address public constant treasury = address(0xE37058057B0751bD2653fdeB27e8218439e0f726);
    address public constant devMultiSig = address(0x3522f55fE566420f14f89bd46820EC66D3A5eb7c);


    modifier onlyOwner() virtual {
        checkOwner();
        _;
    }

    modifier onlyAdmin() virtual {
        checkAdmin();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        owner = devMultiSig;
        emit OwnershipTransferred(address(0), owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) external virtual onlyOwner {
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }

    function setStrategist(address _newStrategist) external virtual {
        if(msg.sender != strategist){revert NotStrategist();}
        strategist = _newStrategist;
        emit SetStrategist(msg.sender, strategist);
    }

    function checkOwner() internal virtual {
        if(tx.origin != owner){revert NoAuth();}
    }

    function checkAdmin() internal virtual {
        if(tx.origin != owner && tx.origin != strategist){revert NoAuth();}
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IEqualizerRouter {

    // Routes
    struct Routes {
        address from;
        address to;
        bool stable;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function swapExactTokensForTokensSimple(
        uint amountIn, 
        uint amountOutMin, 
        address tokenFrom, 
        address tokenTo,
        bool stable, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);

     function swapExactTokensForTokens(
        uint amountIn, 
        uint amountOutMin, 
        Routes[] memory route, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);

     function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        Routes[] calldata routes,
        address to,
        uint deadline
    ) external;

    function quoteAddLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired
    ) external view returns (uint amountA, uint amountB, uint liquidity);

    function getAmountOut(uint amountIn, address tokenIn, address tokenOut) external view returns (uint amount, bool stable);

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {ERC20} from "./ERC20.sol";
import {SafeTransferLib} from "../solady/SafeTransferLib.sol";
import {FixedPointMathLib} from "./FixedPointMathLib.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol)
abstract contract ERC4626 is ERC20 {
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, _asset.decimals()) {
        asset = _asset;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = convertToShares(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        SafeTransferLib.safeTransferFrom(address(asset), msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        //afterDeposit(assets, shares);
    }
    
    /*
    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }
    */

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        shares = convertToShares(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        //beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        SafeTransferLib.safeTransfer(address(asset), receiver, assets);
    }
    /*
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }
    */
    
    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    /*
     function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }
    
    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    //////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////
    
    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    ///////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/
   
    //function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }*/

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}