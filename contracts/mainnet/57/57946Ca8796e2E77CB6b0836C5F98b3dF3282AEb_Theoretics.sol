// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./utils/ContractGuard.sol";
import "./interfaces/IBasisAsset.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IFarm.sol";
import "./interfaces/IERC20Lockable.sol";
import "./Authorizable.sol";

contract ShareWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Lockable;

    IERC20Lockable public share;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        share.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdrawWithFee(uint256 amount, uint256 fee, address feeFund) internal {
        uint256 theoristShare = _balances[msg.sender];
        require(theoristShare >= amount, "Theoretics: withdraw request greater than staked amount");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = theoristShare.sub(amount);
        uint256 feeAmount = amount.mul(fee).div(10000);
        uint256 amountToGive = amount.sub(feeAmount);
        if(feeAmount > 0) share.safeTransfer(feeFund, feeAmount);
        share.safeTransfer(msg.sender, amountToGive);
    }
}

contract Theoretics is ShareWrapper, Authorizable, ContractGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== DATA STRUCTURES ========== */

    struct TheoristSeat {
        uint256 lastSnapshotIndex;
        uint256 rewardEarned;
        uint256 epochTimerStart;
        uint256 lastDepositBlock;
        uint256 lastWithdrawTime;
        uint256 firstDepositTime;
    }

    struct TheoreticsSnapshot {
        uint256 time;
        uint256 rewardReceived;
        uint256 rewardPerShare;
    }

    /* ========== STATE VARIABLES ========== */

    // flags
    bool public initialized = false;

    IERC20Lockable public game;
    ITreasury public treasury;
    IFarm public farm;

    mapping(address => TheoristSeat) public theorists;
    TheoreticsSnapshot[] public theoreticsHistory;

    uint256 public withdrawLockupEpochs;
    uint256 public rewardLockupEpochs;
    uint256 public pegMaxUnlock; //What TWAP do we have to be at to incur 0% lock?
    uint256 public sameBlockFee;
    uint256[] public feeStagePercentage; //In 10000s for decimal
    uint256[] public feeStageTime;


    /* ========== EVENTS ========== */

    event Initialized(address indexed executor, uint256 at);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward, uint256 lockAmount);
    event RewardAdded(address indexed user, uint256 reward);

    /* ========== Modifiers =============== */

    modifier theoristExists {
        require(balanceOf(msg.sender) > 0, "Theoretics: The theorist does not exist");
        _;
    }

    modifier updateReward(address theorist) {
        if (theorist != address(0)) {
            TheoristSeat memory seat = theorists[theorist];
            seat.rewardEarned = earned(theorist);
            seat.lastSnapshotIndex = latestSnapshotIndex();
            theorists[theorist] = seat;
        }
        _;
    }

    modifier notInitialized {
        require(!initialized, "Theoretics: already initialized");
        _;
    }

    /* ========== GOVERNANCE ========== */

    function initialize(
        IERC20Lockable _game,
        IERC20Lockable _share,
        ITreasury _treasury,
        IFarm _farm
    ) public notInitialized {
        require(_treasury.initialized(), "Treasury must be initialized first.");
        initialized = true;
        game = _game;
        share = _share;
        treasury = _treasury;
        farm = _farm;

        TheoreticsSnapshot memory genesisSnapshot = TheoreticsSnapshot({time : block.number, rewardReceived : 0, rewardPerShare : 0});
        theoreticsHistory.push(genesisSnapshot);

        withdrawLockupEpochs = 6; // Lock for 6 epochs (36h) before release withdraw
        rewardLockupEpochs = 3; // Lock for 3 epochs (18h) before release claimReward

        pegMaxUnlock = treasury.gamePriceOne().mul(4);
        sameBlockFee = 2500;
        feeStageTime = [0, 1 hours, 1 days, 3 days, 5 days, 2 weeks, 4 weeks];
        feeStagePercentage = [800, 400, 200, 100, 50, 25, 1];

        emit Initialized(msg.sender, block.number);
    }

    function setFeeStages(uint256[] memory _feeStageTime, uint256[] memory _feeStagePercentage) public onlyAuthorized() {
        require(_feeStageTime.length > 0
            && _feeStageTime[0] == 0
            && _feeStagePercentage.length == _feeStageTime.length,
            "Fee stage arrays must be equal in non-zero length and time should start at 0.");
        feeStageTime = _feeStageTime;
        uint256 i;
        uint256 len = _feeStagePercentage.length;
        for(i = 0; i < len; i += 1)
        {
            require(_feeStagePercentage[i] <= 800, "Fee can't be higher than 8%.");
        }
        feeStagePercentage = _feeStagePercentage;
    }

    function setSameBlockFee(uint256 _fee) public onlyAuthorized() {
        require(_fee <= 2500, "Fee can't be higher than 25%.");
        sameBlockFee = _fee;
    }

    function getWithdrawFeeOf(address _user) public view returns (uint256)
    {
        TheoristSeat storage user = theorists[_user];
        uint256 fee = sameBlockFee;
        if(block.number != user.lastDepositBlock)
        {
            if (!(user.firstDepositTime > 0)) {
                return feeStagePercentage[0];
            }
            uint256 deltaTime = user.lastWithdrawTime > 0 ?
            block.timestamp - user.lastWithdrawTime :
            block.timestamp - user.firstDepositTime;
            uint256 len = feeStageTime.length;
            uint256 n;
            uint256 i;
            for (n = len; n > 0; n -= 1) {
                i = n-1;
                if(deltaTime >= feeStageTime[i])
                {
                    fee = feeStagePercentage[i];
                    break;
                }
            }
        }
        return fee;
    }

    function setLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs, uint256 _pegMaxUnlock) external onlyAuthorized onlyOneBlock { // Switched to onlyAuthorized just in case we vote on a new lock up period later. The max is now the default, so this can only help users.
        require(_withdrawLockupEpochs >= _rewardLockupEpochs && _withdrawLockupEpochs <= 6 && _rewardLockupEpochs <= 3, "lockup epochs out of range"); // <= 6 epochs (36 hours)
        require(_pegMaxUnlock > treasury.gamePriceCeiling()
            && _pegMaxUnlock <= treasury.gamePriceOne().mul(4),
            "Max peg unlock must be greater than the GAME ceiling and lower than the price of one GAME times 4.");
        withdrawLockupEpochs = _withdrawLockupEpochs;
        rewardLockupEpochs = _rewardLockupEpochs;
        pegMaxUnlock = _pegMaxUnlock;
    }

    /* ========== VIEW FUNCTIONS ========== */

    // =========== Snapshot getters

    function latestSnapshotIndex() public view returns (uint256) {
        return theoreticsHistory.length.sub(1);
    }

    function getLatestSnapshot() internal view returns (TheoreticsSnapshot memory) {
        return theoreticsHistory[latestSnapshotIndex()];
    }

    function getLastSnapshotIndexOf(address theorist) public view returns (uint256) {
        return theorists[theorist].lastSnapshotIndex;
    }

    function getLastSnapshotOf(address theorist) internal view returns (TheoreticsSnapshot memory) {
        return theoreticsHistory[getLastSnapshotIndexOf(theorist)];
    }

    function canWithdraw(address theorist) external view returns (bool) {
        uint256 fullLock = 100;
        uint256 currentTime = block.timestamp;
        uint256 unlockPercentage = fullLock.sub(farm.getLockPercentage(currentTime > 0 ? currentTime.sub(1) : currentTime, currentTime));
        require(unlockPercentage <= 100, "Invalid unlock percentage, check farm contract."); // Don't worry: The max is not 100.  It is just here for simplicity. I should use assert instead of require but I prefer having the reason there when it asserts.
        return theorists[theorist].epochTimerStart.add(withdrawLockupEpochs.mul(unlockPercentage).div(100)) <= treasury.epoch();
    }

    function epoch() external view returns (uint256) {
        return treasury.epoch();
    }

    function canClaimReward(address theorist) external view returns (bool) {
        uint256 fullLock = 100;
        uint256 currentTime = block.timestamp;
        uint256 unlockPercentage = fullLock.sub(farm.getLockPercentage(currentTime > 0 ? currentTime.sub(1) : currentTime, currentTime));
        require(unlockPercentage <= 100, "Invalid unlock percentage, check farm contract.");
        return theorists[theorist].epochTimerStart.add(rewardLockupEpochs.mul(unlockPercentage).div(100)) <= treasury.epoch();
    }

    function nextEpochPoint() external view returns (uint256) {
        return treasury.nextEpochPoint();
    }

    function getGamePrice() external view returns (uint256) {
        return treasury.getGamePrice();
    }

    // =========== Theorist getters

    function rewardPerShare() public view returns (uint256) {
        return getLatestSnapshot().rewardPerShare;
    }

    function earned(address theorist) public view returns (uint256) {
        uint256 latestRPS = getLatestSnapshot().rewardPerShare;
        uint256 storedRPS = getLastSnapshotOf(theorist).rewardPerShare;

        return balanceOf(theorist).mul(latestRPS.sub(storedRPS)).div(1e18).add(theorists[theorist].rewardEarned);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function reviseDeposit(address _user, uint256 _time) public onlyAuthorized() {
        theorists[_user].firstDepositTime = _time;
    }

    function reviseWithdraw(address _user, uint256 _time) public onlyAuthorized() {
        theorists[_user].lastWithdrawTime = _time;
    }

    function stake(uint256 amount) public override onlyOneBlock updateReward(msg.sender) {
        require(amount > 0, "Theoretics: Cannot stake 0");
        super.stake(amount);
        TheoristSeat storage user = theorists[msg.sender];
        user.epochTimerStart = treasury.epoch(); // reset timer
        user.lastDepositBlock = block.number;
        if (!(user.firstDepositTime > 0)) {
            user.firstDepositTime = block.timestamp;
        }
        emit Staked(msg.sender, amount);
    }

    function getCurrentWithdrawEpochs() public view returns (uint256)
    {
        uint256 fullLock = 100;
        uint256 currentTime = block.timestamp;
        uint256 unlockPercentage = fullLock.sub(farm.getLockPercentage(currentTime > 0 ? currentTime.sub(1) : currentTime, currentTime));
        require(unlockPercentage <= 100, "Invalid unlock percentage, check farm contract.");
        return (withdrawLockupEpochs.mul(unlockPercentage).div(100));
    }

    function getCurrentClaimEpochs() public view returns (uint256)
    {
        uint256 fullLock = 100;
        uint256 currentTime = block.timestamp;
        uint256 unlockPercentage = fullLock.sub(farm.getLockPercentage(currentTime > 0 ? currentTime.sub(1) : currentTime, currentTime));
        require(unlockPercentage <= 100, "Invalid unlock percentage, check farm contract.");
        return (rewardLockupEpochs.mul(unlockPercentage).div(100));
    }

    // TODO: GAS OPTIMIZATION? user can be memory, manipulated, and then stored in theorists storage.
    // For safety reasons, I am not doing this now. I am also not sure if modifying all at once makes a difference.
    function withdraw(uint256 amount) public onlyOneBlock theoristExists updateReward(msg.sender) {
        require(amount > 0, "Theoretics: Cannot withdraw 0");
        uint256 fullLock = 100;
        uint256 currentTime = block.timestamp;
        uint256 unlockPercentage = fullLock.sub(farm.getLockPercentage(currentTime > 0 ? currentTime.sub(1) : currentTime, currentTime));
        require(unlockPercentage <= 100, "Invalid unlock percentage, check farm contract.");
        TheoristSeat storage user = theorists[msg.sender];
        require(user.epochTimerStart.add(withdrawLockupEpochs.mul(unlockPercentage).div(100)) <= treasury.epoch(), "Theoretics: still in withdraw lockup");
        claimReward();
        uint256 fee = sameBlockFee;
        if(block.number != user.lastDepositBlock)
        {
            uint256 deltaTime = user.lastWithdrawTime > 0 ?
            block.timestamp - user.lastWithdrawTime :
            block.timestamp - user.firstDepositTime;
            uint256 len = feeStageTime.length;
            uint256 n;
            uint256 i;
            for (n = len; n > 0; n -= 1) {
                i = n-1;
                if(deltaTime >= feeStageTime[i])
                {
                    fee = feeStagePercentage[i];
                    break;
                }
            }
        }
        user.lastWithdrawTime = block.timestamp;
        withdrawWithFee(amount, fee, treasury.daoFund());
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
    }

    function invLerpPercent95(uint256 _from, uint256 _to, uint _current) internal pure returns (uint256)
    {
        require(_to > _from, "Invalid parameters.");
        if(_current <= _from) return 0;
        if(_current >= _to) return 95;
        return (_current.sub(_from)).mul(95).div(_to.sub(_from));
    }

    function getLockPercentage() public view returns (uint256) {
        uint256 twap = treasury.getGamePrice();
        // By default, GAME is 100% locked for 1 year at <= 1.01, and fully unlocked at >= 2.0
        uint256 fullUnlock = 95;
        uint256 lockPercentage = fullUnlock.sub(invLerpPercent95(treasury.gamePriceCeiling(), pegMaxUnlock, twap));
        require(lockPercentage <= 100, "Invalid lock percentage, check this contract.");
        if (lockPercentage > 95) lockPercentage = 95; // Invalid but not TOO invalid. Okay, I admit, it is so that it stays consistent with all the other requires.
        return lockPercentage;
    }

    function claimReward() public onlyOneBlock updateReward(msg.sender) {
        uint256 reward = theorists[msg.sender].rewardEarned;
        if (reward > 0) {
            uint256 fullLock = 100;
            uint256 currentTime = block.timestamp;
            uint256 unlockPercentage = fullLock.sub(farm.getLockPercentage(currentTime > 0 ? currentTime.sub(1) : currentTime, currentTime));
            require(unlockPercentage <= 100, "Invalid unlock percentage, check farm contract.");
            require(theorists[msg.sender].epochTimerStart.add(rewardLockupEpochs.mul(unlockPercentage).div(100)) <= treasury.epoch(), "Theoretics: still in reward lockup");
            theorists[msg.sender].epochTimerStart = treasury.epoch(); // reset timer
            theorists[msg.sender].rewardEarned = 0;
            game.safeTransfer(msg.sender, reward);
            // GAME can always be locked.
            uint256 lockAmount = 0;
            uint256 lockPercentage = getLockPercentage();
            require(lockPercentage <= 100, "Invalid lock percentage, check this contract.");
            lockAmount = reward.mul(lockPercentage).div(100);
            if(lockAmount > 0) game.lock(msg.sender, lockAmount);
            emit RewardPaid(msg.sender, reward, lockAmount);
        }
    }

    function allocateSeigniorage(uint256 amount) external onlyOneBlock onlyOperator {
        require(amount > 0, "Theoretics: Cannot allocate 0");
        require(totalSupply() > 0, "Theoretics: Cannot allocate when totalSupply is 0");

        // Create & add new snapshot
        uint256 prevRPS = getLatestSnapshot().rewardPerShare;
        uint256 nextRPS = prevRPS.add(amount.mul(1e18).div(totalSupply()));

        TheoreticsSnapshot memory newSnapshot = TheoreticsSnapshot({
            time: block.number,
            rewardReceived: amount,
            rewardPerShare: nextRPS
        });
        theoreticsHistory.push(newSnapshot);

        game.safeTransferFrom(msg.sender, address(this), amount);
        emit RewardAdded(msg.sender, amount);
    }

    function governanceRecoverUnsupported(IERC20 _token, uint256 _amount, address _to) external onlyOperator { //This can remain onlyOperator since we can call this from the Treasury anyways.
        // do not allow to drain core tokens
        require(address(_token) != address(game), "game");
        require(address(_token) != address(share), "share");
        _token.safeTransfer(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity 0.6.12;

contract ContractGuard {
    mapping(uint256 => mapping(address => bool)) private _status;

    function checkSameOriginReentranted() internal view returns (bool) {
        return _status[block.number][tx.origin];
    }

    function checkSameSenderReentranted() internal view returns (bool) {
        return _status[block.number][msg.sender];
    }

    modifier onlyOneBlock() {
        require(!checkSameOriginReentranted(), "ContractGuard: one block, one function");
        require(!checkSameSenderReentranted(), "ContractGuard: one block, one function");

        _;

        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;
    }
}

pragma solidity ^0.6.0;

interface IBasisAsset {
    function mint(address recipient, uint256 amount) external returns (bool);

    function burn(uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function isOperator() external returns (bool);

    function operator() external view returns (address);

    function transferOperator(address newOperator_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ITreasury {
    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function getGamePrice() external view returns (uint256);

    function gamePriceOne() external view returns (uint256);
    function gamePriceCeiling() external view returns (uint256);
    function initialized() external view returns (bool);
    function daoFund() external view returns (address);

    function buyBonds(uint256 amount, uint256 targetPrice) external;

    function redeemBonds(uint256 amount, uint256 targetPrice) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IFarm {
    function getLockPercentage(uint256 _from, uint256 _to) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Lockable is IERC20 {
    function lock(address _holder, uint256 _amount) external;
}

pragma solidity 0.6.12;
import "./owner/Operator.sol";

contract Authorizable is Operator {
    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender || operator() == msg.sender, "caller is not authorized");
        _;
    }

    function addAuthorized(address _toAdd) public onlyOwner {
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) public onlyOwner {
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() internal {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOperator { // Not sure why owner is allowed to change operator.  For security reasons, the operator will be the only one allowed to do this. This way we can change parameters without being able to do many scary things.
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}