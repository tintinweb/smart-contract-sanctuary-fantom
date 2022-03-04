// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./interfaces/tokens/IERC20Mintable.sol";
import "./interfaces/tokens/IEXCToken.sol";
import "./interfaces/IMasterExcalibur.sol";
import "./MasterChef.sol";

/*
 * This contract is used to implement the Excalibur locking system to the Master contract
 *
 * It gives to each user lock slots on each pool, with which he's able to get bonus rewards proportionally to the
 * lock duration he decided on deposit
 *
 * The regular slot is the classic system used by every standard MasterChef contract
 * The lock slots are based on the regular, but with the addition of lock features
 *
 */
contract MasterExcalibur is Ownable, ReentrancyGuard, MasterChef, IMasterExcalibur {
  using SafeMath for uint256;

  using SafeERC20 for IERC20;
  using SafeERC20 for IERC20Mintable;

  // Info of each user on locked deposits
  struct UserLockSlotInfo {
    uint256 amount; // How many LP tokens the user has provided
    uint256 rewardDebt; // Reward debt
    uint256 lockDurationSeconds; // The lock duration in seconds
    uint256 depositTime; // The time at which the user made his deposit
    uint256 multiplier; // Active multiplier (times 1e4)
    uint256 amountWithMultiplier; // Amount + lock bonus faked amount (amount + amount*multiplier)
    uint256 bonusRewards; // Rewards earned from the lock bonus
  }

  // Used to directly set disableLockSlot without having to go through the timelock
  address public operator;

  mapping(uint256 => mapping(address => UserLockSlotInfo[])) public userLockSlotInfo;

  uint256 public constant MAX_USER_LOCK_SLOT = 2; // Locking slots allocation / user / pool
  uint256 public immutable MAX_LOCK_DURATION_SECONDS;
  uint256 public immutable MIN_LOCK_DURATION_SECONDS;
  uint256 public constant MAX_MULTIPLIER = 50; // 50%

  // Disables the lock slot feature for all pools:
  //  - Enables the emergencyWithdrawOnLockSlot and WithdrawOnLockSlot even if lockDuration has not ended
  //  - Disables the deposits
  bool public disableLockSlot = false;

  constructor(
    IEXCToken excToken_,
    IERC20Mintable grailToken_,
    uint256 startTime_,
    address devAddress_,
    address feeAddress_,
    uint256 maxLockDuration,
    uint256 minLockDuration
  ) MasterChef(excToken_, grailToken_, startTime_, devAddress_, feeAddress_) {
    operator = msg.sender;

    MAX_LOCK_DURATION_SECONDS = maxLockDuration;
    MIN_LOCK_DURATION_SECONDS = minLockDuration;
  }

  /********************************************/
  /****************** EVENTS ******************/
  /********************************************/

  event DepositOnLockSlot(
    address indexed user,
    uint256 indexed pid,
    uint256 slotId,
    uint256 amount,
    uint256 lockDurationSeconds
  );
  event RenewLockSlot(
    address indexed user,
    uint256 indexed pid,
    uint256 slotId,
    uint256 amount,
    uint256 lockDurationSeconds
  );
  event HarvestOnLockSlot(address indexed user, uint256 indexed pid, uint256 slotId, uint256 amount);
  event WithdrawOnLockSlot(address indexed user, uint256 indexed pid, uint256 slotId, uint256 amount);
  event EmergencyWithdrawOnLockSlot(address indexed user, uint256 indexed pid, uint256 slotId, uint256 amount);
  event DisableLockSlot(bool isDisable);

  event OperatorTransferred(address indexed previousOwner, address indexed newOwner);

  /***********************************************/
  /****************** MODIFIERS ******************/
  /***********************************************/

  /**
   * @dev Throws if called by any account other than the operator.
   */
  modifier onlyOperator() {
    require(operator == msg.sender, "onlyOperator: caller is not the operator");
    _;
  }

  /*
   * @dev Checks if a slot exists on the pool with given pid for userAddress
   */
  modifier validateSlot(
    uint256 pid,
    address userAddress,
    uint256 slotId
  ) {
    require(pid < poolInfo.length, "validateSlot: pool exists?");
    require(slotId < userLockSlotInfo[pid][userAddress].length, "validateSlot: slot exists?");
    _;
  }

  /**************************************************/
  /****************** PUBLIC VIEWS ******************/
  /**************************************************/

  /*
   * @dev Checks if pool is inactive
   */
  function isPoolClosed(uint256 pid) public view returns (bool) {
    return poolInfo[pid].accRewardsPerShare > 0 && poolInfo[pid].allocPoint == 0;
  }

  /**
   * @dev Returns the number of available pools
   */
  function getUserSlotLength(uint256 pid, address account) external view override returns (uint256) {
    return userLockSlotInfo[pid][account].length;
  }

  /**
   * @dev Returns user data of a given pool and slot
   */
  function getUserLockSlotInfo(
    uint256 pid,
    address userAddress,
    uint256 slotId
  )
    external
    view
    virtual
    override
    returns (
      uint256 amount,
      uint256 rewardDebt,
      uint256 lockDurationSeconds,
      uint256 depositTime,
      uint256 multiplier,
      uint256 amountWithMultiplier,
      uint256 bonusRewards
    )
  {
    UserLockSlotInfo storage userSlot = userLockSlotInfo[pid][userAddress][slotId];
    {
      return (
        userSlot.amount,
        userSlot.rewardDebt,
        userSlot.lockDurationSeconds,
        userSlot.depositTime,
        userSlot.multiplier,
        userSlot.amountWithMultiplier,
        userSlot.bonusRewards
      );
    }
  }

  /**
   * @dev Returns expected multiplier for a "lockDurationSeconds" duration lock on a slot (result is *1e8)
   */
  function getMultiplierByLockDurationSeconds(uint256 lockDurationSeconds) public view returns (uint256 multiplier) {
    // capped to MAX_LOCK_DURATION_SECONDS
    if (lockDurationSeconds > MAX_LOCK_DURATION_SECONDS) lockDurationSeconds = MAX_LOCK_DURATION_SECONDS;
    return MAX_MULTIPLIER.mul(lockDurationSeconds).mul(1e6).div(MAX_LOCK_DURATION_SECONDS);
  }

  /**
   * @dev Returns the (locked and unlocked) pending rewards for a user slot on a pool
   */
  function pendingRewardsOnLockSlot(
    uint256 pid,
    address userAddress,
    uint256 slotId
  )
    external
    view
    virtual
    override
    returns (
      uint256 pending,
      uint256 bonusRewards,
      bool canHarvestBonusRewards
    )
  {
    if(pid >= poolInfo.length || slotId >= userLockSlotInfo[pid][userAddress].length) return (0, 0, false);

    uint256 accRewardsPerShare = _getCurrentAccRewardsPerShare(pid);
    UserLockSlotInfo storage userSlot = userLockSlotInfo[pid][userAddress][slotId];

    if(userSlot.amountWithMultiplier == 0) return (0, 0, false);

    uint256 rewardsWithMultiplier = userSlot.amountWithMultiplier.mul(accRewardsPerShare).div(1e18).sub(
      userSlot.rewardDebt
    );

    pending = rewardsWithMultiplier.mul(userSlot.amount).div(userSlot.amountWithMultiplier);
    bonusRewards = rewardsWithMultiplier.add(userSlot.bonusRewards).sub(pending);
    canHarvestBonusRewards = _currentBlockTimestamp() >= userSlot.depositTime.add(userSlot.lockDurationSeconds);
    return (pending, bonusRewards, canHarvestBonusRewards);
  }

  /****************************************************************/
  /****************** EXTERNAL PUBLIC FUNCTIONS  ******************/
  /****************************************************************/

  /**
   * @dev Harvest user's pending rewards on a given pool and lock slot
   *
   *  If lockDuration is over :
   *    - harvest regular + bonus rewards
   *    - transfer user amount from lock slot to regular slot
   *  Else :
   *    - harvest regular rewards
   *    - bonus rewards remain locked
   */
  function harvestOnLockSlot(uint256 pid, uint256 slotId)
    external
    virtual
    override
    validateSlot(pid, msg.sender, slotId)
    nonReentrant
  {
    address userAddress = msg.sender;

    _updatePool(pid);
    _harvestOnLockSlot(pid, userAddress, slotId, false);

    UserLockSlotInfo storage userSlot = userLockSlotInfo[pid][userAddress][slotId];

    // check if lockDuration is over and so if the lockSlot is now unlocked
    if (_currentBlockTimestamp() >= userSlot.depositTime.add(userSlot.lockDurationSeconds)) {
      UserInfo storage user = userInfo[pid][userAddress];
      PoolInfo storage pool = poolInfo[pid];

      // transfer userLockSlotInfo.amount to userInfo.amount (to regular slot) and delete the now empty userLockSlot
      _harvest(pid, pool, user, userAddress);
      user.amount = user.amount.add(userSlot.amount);
      user.rewardDebt = user.amount.mul(pool.accRewardsPerShare).div(1e18);

      pool.lpSupplyWithMultiplier = pool.lpSupplyWithMultiplier.sub(userSlot.amountWithMultiplier).add(userSlot.amount);

      emit WithdrawOnLockSlot(userAddress, pid, slotId, userSlot.amount);
      emit Deposit(userAddress, pid, userSlot.amount);

      _removeUserLockSlot(pid, userAddress, slotId);
    }
  }

  /**
   * @dev Deposit tokens on a given pool for rewards allocation (lock slot)
   * - A lock slot must be available
   * - Tokens will be locked for "lockDurationSeconds"
   * - Bonus rewards amount will be proportional to the lock duration specified here
   *
   * if "fromRegularDeposit" is :
   * - set to true: the tokens will be transferred from the user's regular slot (userInfo), so no fees will be charged
   * - set to false: the tokens will be transferred from the user's wallet, so deposit fees will be charged
   */
  function depositOnLockSlot(
    uint256 pid,
    uint256 amount,
    uint256 lockDurationSeconds,
    bool fromRegularDeposit
  ) external virtual override validatePool(pid) nonReentrant {
    require(!disableLockSlot, "lock slot disabled");
    require(amount > 0, "amount zero");

    address userAddress = msg.sender;

    _updatePool(pid);
    PoolInfo storage pool = poolInfo[pid];

    // check whether the deposit should come from the regular slot of the pool or from the user's wallet
    if (fromRegularDeposit) {
      UserInfo storage user = userInfo[pid][userAddress];
      require(user.amount >= amount, "amount not available");

      _harvest(pid, pool, user, userAddress);

      // remove the amount to lock from the "regular" balances
      user.amount = user.amount.sub(amount);
      user.rewardDebt = user.amount.mul(pool.accRewardsPerShare).div(1e18);
      pool.lpSupply = pool.lpSupply.sub(amount);
      pool.lpSupplyWithMultiplier = pool.lpSupplyWithMultiplier.sub(amount);
      emit Withdraw(userAddress, pid, amount);
    } else {
      // handle tokens with transfer tax
      uint256 previousBalance = pool.lpToken.balanceOf(address(this));
      pool.lpToken.safeTransferFrom(userAddress, address(this), amount);
      amount = pool.lpToken.balanceOf(address(this)).sub(previousBalance);

      if (pool.depositFeeBP > 0) {
        // check if depositFee is enabled
        uint256 depositFee = amount.mul(pool.depositFeeBP).div(1e4);
        amount = amount.sub(depositFee);
        pool.lpToken.safeTransfer(feeAddress, depositFee);
      }
    }

    _lockAmount(pid, userAddress, amount, lockDurationSeconds);
  }

  /**
   * @dev Renew a lock slot
   *   - harvest regular + bonus rewards
   *   - reset the lock slot duration to lockDurationSeconds
   * If previous lockDurationSeconds has not ended :
   *   - requires lockDurationSeconds >= previousLockDuration
   */
  function renewLockSlot(
    uint256 pid,
    uint256 slotId,
    uint256 lockDurationSeconds
  ) external virtual override validateSlot(pid, msg.sender, slotId) nonReentrant {
    require(!disableLockSlot, "lock slot disabled");
    uint256 currentBlockTimestamp = _currentBlockTimestamp();

    address userAddress = msg.sender;
    UserLockSlotInfo storage userSlot = userLockSlotInfo[pid][userAddress][slotId];

    // if the slot is still locked, check if the new lockDurationSeconds is at least the same as the previous one
    if (currentBlockTimestamp < userSlot.depositTime.add(userSlot.lockDurationSeconds)) {
      require(userSlot.lockDurationSeconds <= lockDurationSeconds, "lockDurationSeconds too low");
    }

    _updatePool(pid);
    PoolInfo storage pool = poolInfo[pid];

    _harvestOnLockSlot(pid, userAddress, slotId, true);

    userSlot.depositTime = currentBlockTimestamp;

    // if the new lockDurationSeconds has changed, adjust the rewards multiplier
    if (userSlot.lockDurationSeconds != lockDurationSeconds) {
      userSlot.lockDurationSeconds = lockDurationSeconds;
      userSlot.multiplier = getMultiplierByLockDurationSeconds(lockDurationSeconds);
      uint256 amountWithMultiplier = userSlot.amount.mul(userSlot.multiplier.add(1e8)).div(1e8);
      pool.lpSupplyWithMultiplier = pool.lpSupplyWithMultiplier.sub(userSlot.amountWithMultiplier).add(
        amountWithMultiplier
      );
      userSlot.amountWithMultiplier = amountWithMultiplier;
    }
    userSlot.rewardDebt = userSlot.amountWithMultiplier.mul(pool.accRewardsPerShare).div(1e18);

    emit RenewLockSlot(userAddress, pid, slotId, userSlot.amount, userSlot.lockDurationSeconds);
  }

  /**
   * @dev Redeposit tokens on an already active given lock slot
   *  - Harvest all rewards (regular and bonus)
   *  - Reset the lock
   *
   * if "fromRegularDeposit" is :
   * - set to true: the tokens will be transferred from the user's regular slot (userInfo), so no fees will be charged
   * - set to false: the tokens will be transferred from the user's wallet, so deposit fees will be charged
   */
  function redepositOnLockSlot(
    uint256 pid,
    uint256 slotId,
    uint256 amountToAdd,
    bool fromRegularDeposit
  ) external virtual override validateSlot(pid, msg.sender, slotId) nonReentrant {
    require(!disableLockSlot, "lock slot disabled");
    require(amountToAdd > 0, "zero amount");

    address userAddress = msg.sender;

    _updatePool(pid);
    PoolInfo storage pool = poolInfo[pid];

    // check whether the deposit should come from the regular slot of the pool or from the user's wallet
    if (fromRegularDeposit) {
      UserInfo storage user = userInfo[pid][userAddress];
      require(user.amount >= amountToAdd, "amount not available");

      _harvest(pid, pool, user, userAddress);

      // remove the amount to lock from the "regular" balances
      user.amount = user.amount.sub(amountToAdd);
      user.rewardDebt = user.amount.mul(pool.accRewardsPerShare).div(1e18);
      pool.lpSupply = pool.lpSupply.sub(amountToAdd);
      pool.lpSupplyWithMultiplier = pool.lpSupplyWithMultiplier.sub(amountToAdd);

      emit Withdraw(userAddress, pid, amountToAdd);
    } else {
      // handle tokens with transfer tax
      uint256 previousBalance = pool.lpToken.balanceOf(address(this));
      pool.lpToken.safeTransferFrom(userAddress, address(this), amountToAdd);
      amountToAdd = pool.lpToken.balanceOf(address(this)).sub(previousBalance);

      if (pool.depositFeeBP > 0) {
        // check if depositFee is enabled
        uint256 depositFee = amountToAdd.mul(pool.depositFeeBP).div(1e4);
        amountToAdd = amountToAdd.sub(depositFee);
        pool.lpToken.safeTransfer(feeAddress, depositFee);
      }
    }

    _harvestOnLockSlot(pid, userAddress, slotId, true);

    // adjust balances with new deposit amount
    UserLockSlotInfo storage userSlot = userLockSlotInfo[pid][userAddress][slotId];
    uint256 amountToAddWithMultiplier = amountToAdd.mul(userSlot.multiplier.add(1e8)).div(1e8);

    userSlot.amount = userSlot.amount.add(amountToAdd);
    userSlot.amountWithMultiplier = userSlot.amountWithMultiplier.add(amountToAddWithMultiplier);
    userSlot.rewardDebt = userSlot.amountWithMultiplier.mul(pool.accRewardsPerShare).div(1e18);
    userSlot.depositTime = _currentBlockTimestamp();

    pool.lpSupply = pool.lpSupply.add(amountToAdd);
    pool.lpSupplyWithMultiplier = pool.lpSupplyWithMultiplier.add(amountToAddWithMultiplier);

    emit RenewLockSlot(userAddress, pid, slotId, userSlot.amount, userSlot.lockDurationSeconds);
  }

  /**
   * @dev Withdraw tokens from given pool and lock slot
   * - harvest if there is pending rewards
   * - withdraw the deposited amount to the user's wallet
   *
   * lockDurationSeconds must be over
   */
  function withdrawOnLockSlot(uint256 pid, uint256 slotId)
    external
    virtual
    override
    validateSlot(pid, msg.sender, slotId)
    nonReentrant
  {
    address userAddress = msg.sender;

    PoolInfo storage pool = poolInfo[pid];
    UserLockSlotInfo storage userSlot = userLockSlotInfo[pid][userAddress][slotId];

    require(
      userSlot.depositTime.add(userSlot.lockDurationSeconds) <= _currentBlockTimestamp() ||
        isPoolClosed(pid) ||
        disableLockSlot,
      "withdraw locked"
    );

    _updatePool(pid);
    // if lock slot feature has been disabled by the admin (disableLockSlot), we force the harvest of
    // all the user's bonus rewards
    _harvestOnLockSlot(pid, userAddress, slotId, true);

    uint256 withdrawAmount = userSlot.amount;

    pool.lpSupply = pool.lpSupply.sub(withdrawAmount);
    pool.lpSupplyWithMultiplier = pool.lpSupplyWithMultiplier.sub(userSlot.amountWithMultiplier);
    _removeUserLockSlot(pid, userAddress, slotId);

    emit WithdrawOnLockSlot(userAddress, pid, slotId, withdrawAmount);
    pool.lpToken.safeTransfer(userAddress, withdrawAmount);
  }

  /**
   * @dev Withdraw without caring about rewards, EMERGENCY ONLY
   *
   * Can't be called for locked deposits, except if disableLockSlot is set to true
   */
  function emergencyWithdrawOnLockSlot(uint256 pid, uint256 slotId)
    external
    virtual
    override
    validateSlot(pid, msg.sender, slotId)
    nonReentrant
  {
    address userAddress = msg.sender;
    PoolInfo storage pool = poolInfo[pid];
    UserLockSlotInfo storage userSlot = userLockSlotInfo[pid][userAddress][slotId];
    require(
      userSlot.depositTime.add(userSlot.lockDurationSeconds) <= _currentBlockTimestamp() ||
        isPoolClosed(pid) ||
        disableLockSlot,
      "withdraw locked"
    );
    uint256 amount = userSlot.amount;

    pool.lpSupply = pool.lpSupply.sub(userSlot.amount);
    pool.lpSupplyWithMultiplier = pool.lpSupplyWithMultiplier.sub(userSlot.amountWithMultiplier);

    _removeUserLockSlot(pid, userAddress, slotId);

    pool.lpToken.safeTransfer(userAddress, amount);
    emit EmergencyWithdrawOnLockSlot(userAddress, pid, slotId, amount);
  }

  /*****************************************************************/
  /****************** EXTERNAL OWNABLE FUNCTIONS  ******************/
  /*****************************************************************/

  /**
   * @dev Transfers the operator of the contract to a new account (`newOperator`).
   *
   * Must only be called by the current operator.
   */
  function transferOperator(address newOperator) external onlyOperator {
    require(newOperator != address(0), "transferOperator: new operator is the zero address");
    emit OperatorTransferred(operator, newOperator);
    operator = newOperator;
  }

  /**
   * @dev Unlock all locked deposits, forbid any new deposit on lock slots
   *
   * Must only be called by the operator.
   */
  function setDisableLockSlot(bool isDisable) external onlyOperator {
    disableLockSlot = isDisable;
    emit DisableLockSlot(isDisable);
  }

  /********************************************************/
  /****************** INTERNAL FUNCTIONS ******************/
  /********************************************************/

  /**
   * @dev Locks amount for a given pool during lockDurationSeconds into a free slot
   */
  function _lockAmount(
    uint256 pid,
    address userAddress,
    uint256 amount,
    uint256 lockDurationSeconds
  ) internal {
    require(userLockSlotInfo[pid][userAddress].length < MAX_USER_LOCK_SLOT, "no slot available");
    require(lockDurationSeconds >= MIN_LOCK_DURATION_SECONDS, "lockDuration mustn't exceed the minimum");
    require(lockDurationSeconds <= MAX_LOCK_DURATION_SECONDS, "lockDuration mustn't exceed the maximum");

    PoolInfo storage pool = poolInfo[pid];
    uint256 multiplier = getMultiplierByLockDurationSeconds(lockDurationSeconds);
    uint256 amountWithMultiplier = amount.mul(multiplier.add(1e8)).div(1e8);

    pool.lpSupply = pool.lpSupply.add(amount);
    pool.lpSupplyWithMultiplier = pool.lpSupplyWithMultiplier.add(amountWithMultiplier);

    // create new lock slot
    userLockSlotInfo[pid][userAddress].push(
      UserLockSlotInfo({
        amount: amount,
        rewardDebt: amountWithMultiplier.mul(pool.accRewardsPerShare).div(1e18),
        lockDurationSeconds: lockDurationSeconds,
        depositTime: _currentBlockTimestamp(),
        multiplier: multiplier,
        amountWithMultiplier: amountWithMultiplier,
        bonusRewards: 0
      })
    );
    emit DepositOnLockSlot(
      userAddress,
      pid,
      userLockSlotInfo[pid][userAddress].length.sub(1),
      amount,
      lockDurationSeconds
    );
  }

  /**
   * @dev Harvests the pending rewards for given pool and user on a lock slot
   */
  function _harvestOnLockSlot(
    uint256 pid,
    address userAddress,
    uint256 slotId,
    bool forceHarvestBonus
  ) internal {
    UserLockSlotInfo storage userSlot = userLockSlotInfo[pid][userAddress][slotId];

    uint256 rewardsWithMultiplier = userSlot.amountWithMultiplier.mul(poolInfo[pid].accRewardsPerShare).div(1e18).sub(
      userSlot.rewardDebt
    );
    uint256 pending = rewardsWithMultiplier.mul(userSlot.amount).div(userSlot.amountWithMultiplier);
    uint256 bonusRewards = rewardsWithMultiplier.sub(pending);

    // check if lockDurationSeconds is over
    if (_currentBlockTimestamp() >= userSlot.depositTime.add(userSlot.lockDurationSeconds) || forceHarvestBonus) {
      // bonus rewards are not locked anymore
      pending = pending.add(userSlot.bonusRewards).add(bonusRewards);
      userSlot.bonusRewards = 0;
    } else {
      userSlot.bonusRewards = userSlot.bonusRewards.add(bonusRewards);
    }

    userSlot.rewardDebt = userSlot.amountWithMultiplier.mul(poolInfo[pid].accRewardsPerShare).div(1e18);
    if (pending > 0) {
      if (poolInfo[pid].isGrailRewards) {
        _safeRewardsTransfer(userAddress, pending, _grailToken);
      } else {
        _safeRewardsTransfer(userAddress, pending, _excToken);
      }
      emit HarvestOnLockSlot(userAddress, pid, slotId, pending);
    }
  }

  /**
   * @dev Removes a slot from userLockSlotInfo by index
   */
  function _removeUserLockSlot(
    uint256 pid,
    address userAddress,
    uint256 slotId
  ) internal {
    UserLockSlotInfo[] storage userSlots = userLockSlotInfo[pid][userAddress];

    // in case of emergencyWithdraw : burn the remaining bonus rewards on the slot, so they won't be locked on the master forever
    uint256 remainingRewardsAmount = userSlots[slotId].bonusRewards;
    if (remainingRewardsAmount > 0) {
      poolInfo[pid].isGrailRewards ? _grailToken.burn(remainingRewardsAmount) : _excToken.burn(remainingRewardsAmount);
    }

    // slot removal
    userSlots[slotId] = userSlots[userSlots.length - 1];
    userSlots.pop();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "./IERC20Mintable.sol";

interface IRegularToken is IERC20Mintable {
  function divTokenContractAddress() external view returns (address);

  function initializeDivTokenContractAddress(address _divToken) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./IRegularToken.sol";

interface IEXCToken is IRegularToken {
  function autoBurnRate() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Mintable is IERC20 {
  function mint(address to, uint256 amount) external returns (bool);

  function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./IMasterChef.sol";

interface IMasterExcalibur is IMasterChef {
  function getUserSlotLength(uint256 pid, address account) external view returns (uint256);

  function getUserLockSlotInfo(
    uint256 pid,
    address userAddress,
    uint256 slotId
  )
    external
    view
    returns (
      uint256 amount,
      uint256 rewardDebt,
      uint256 lockDurationBlock,
      uint256 depositBlock,
      uint256 multiplier,
      uint256 amountWithMultiplier,
      uint256 lockedBonusRewards
    );

  function pendingRewardsOnLockSlot(
    uint256 pid,
    address userAddress,
    uint256 slotId
  )
    external
    view
    returns (
      uint256 pending,
      uint256 lockedBonusRewards,
      bool canHarvestLockedBonusRewards
    );

  function harvestOnLockSlot(uint256 pid, uint256 slotId) external;

  function depositOnLockSlot(
    uint256 pid,
    uint256 amount,
    uint256 lockDurationBlock,
    bool fromRegularSlot
  ) external;

  function renewLockSlot(
    uint256 pid,
    uint256 slotId,
    uint256 lockDurationBlock
  ) external;

  function redepositOnLockSlot(
    uint256 pid,
    uint256 slotId,
    uint256 amountToAdd,
    bool fromRegularDeposit
  ) external;

  function withdrawOnLockSlot(uint256 pid, uint256 slotId) external;

  function emergencyWithdrawOnLockSlot(uint256 pid, uint256 slotId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

interface IMasterChef {
  function excToken() external view returns (address);

  function grailToken() external view returns (address);

  function getUserInfo(uint256 pid, address account) external view returns (uint256 amount, uint256 rewardDebt);

  function getPoolInfo(uint256 pid)
    external
    view
    returns (
      address lpToken,
      uint256 allocPoint,
      uint256 lastRewardTime,
      uint256 accRewardsPerShare,
      uint256 depositFeeBP,
      bool isGrailRewards,
      uint256 lpSupply,
      uint256 lpSupplyWithMultiplier
    );

  function harvest(uint256 pid) external;

  function deposit(uint256 pid, uint256 amount) external;

  function withdraw(uint256 pid, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./interfaces/tokens/IERC20Mintable.sol";
import "./interfaces/tokens/IEXCToken.sol";
import "./interfaces/IMasterExcalibur.sol";
import "./interfaces/IMasterChef.sol";

contract MasterChef is Ownable, ReentrancyGuard, IMasterChef {
  using SafeMath for uint256;

  using SafeERC20 for IERC20;
  using SafeERC20 for IERC20Mintable;
  using SafeERC20 for IEXCToken;

  // Info of each user.
  struct UserInfo {
    uint256 amount; // How many LP tokens the user has provided
    uint256 rewardDebt; // Reward debt. See explanation below
    /**
     * We do some fancy math here. Basically, any point in time, the amount of EXCs
     * entitled to a user but is pending to be distributed is:
     *
     * pending reward = (user.amount * pool.accRewardsPerShare) - user.rewardDebt
     *
     * Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
     *   1. The pool's `accRrewardsPerShare` (and `lastRewardTime`) gets updated
     *   2. User receives the pending reward sent to his/her address
     *   3. User's `amount` gets updated
     *   4. User's `rewardDebt` gets updated
     */
  }

  // Info of each pool.
  struct PoolInfo {
    IERC20 lpToken; // Address of LP token contract
    uint256 lpSupply; // Sum of LP staked on this pool
    uint256 lpSupplyWithMultiplier; // Sum of LP staked on this pool including the user's multiplier
    uint256 allocPoint; // How many allocation points assigned to this pool. EXC or GRAIL to distribute per second
    uint256 lastRewardTime; // Last time that EXC or GRAIL distribution occurs
    uint256 accRewardsPerShare; // Accumulated Rewards (EXC or GRAIL token) per share, times 1e18. See below
    uint256 depositFeeBP; // Deposit Fee
    bool isGrailRewards; // Are the rewards GRAIL token (if not, rewards are EXC)
  }

  IEXCToken internal immutable _excToken; // Address of the EXC token contract
  IERC20Mintable internal immutable _grailToken; // Address of the GRAIL token contract

  address public devAddress; // Dev address
  address public feeAddress; // Deposit Fee address

  mapping(uint256 => mapping(address => UserInfo)) public userInfo; // Info of each user that stakes LP tokens
  PoolInfo[] public poolInfo; // Info of each pool
  uint256 public totalAllocPoint = 0; // Total allocation points. Must be the sum of all allocation points in all pools
  uint256 public immutable startTime; // The time at which mining starts

  uint256 public constant MAX_DEPOSIT_FEE_BP = 400; // 4%

  uint256 public constant INITIAL_EMISSION_RATE = 1 ether; // Initial emission rate : EXC+GRAIL per second
  uint256 public constant MINIMUM_EMISSION_RATE = 0.1 ether;
  uint256 public rewardsPerSecond; // Token rewards created per second

  constructor(
    IEXCToken excToken_,
    IERC20Mintable grailToken_,
    uint256 startTime_,
    address devAddress_,
    address feeAddress_
  ) {
    require(devAddress_ != address(0), "constructor: devAddress init with zero address");
    require(feeAddress_ != address(0), "constructor: feeAddress init with zero address");

    _excToken = excToken_;
    _grailToken = grailToken_;
    startTime = startTime_;
    rewardsPerSecond = INITIAL_EMISSION_RATE;
    devAddress = devAddress_;
    feeAddress = feeAddress_;

    // staking pool
    poolInfo.push(
      PoolInfo({
        lpToken: excToken_,
        lpSupply: 0,
        lpSupplyWithMultiplier: 0,
        allocPoint: 800,
        lastRewardTime: startTime_,
        accRewardsPerShare: 0,
        depositFeeBP: 0,
        isGrailRewards: false
      })
    );
    totalAllocPoint = 800;
  }

  /********************************************/
  /****************** EVENTS ******************/
  /********************************************/

  event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

  event EmissionRateUpdated(uint256 previousEmissionRate, uint256 newEmissionRate);
  event PoolAdded(uint256 indexed pid, uint256 allocPoint, address lpToken, uint256 depositFeeBP, bool isGrailRewards);
  event PoolConfigUpdated(uint256 indexed pid, uint256 allocPoint, address lpToken, uint256 depositFeeBP);
  event PoolUpdated(uint256 indexed pid, uint256 lastRewardTime, uint256 accRewardsPerShare);

  event FeeAddressUpdated(address previousAddress, address newAddress);
  event DevAddressUpdated(address previousAddress, address newAddress);

  /***********************************************/
  /****************** MODIFIERS ******************/
  /***********************************************/

  /*
   * @dev Check if a pid exists
   */
  modifier validatePool(uint256 pid) {
    require(pid < poolInfo.length, "validatePool: pool exists?");
    _;
  }

  /**************************************************/
  /****************** PUBLIC VIEWS ******************/
  /**************************************************/

  function excToken() external view override returns (address) {
    return address(_excToken);
  }

  function grailToken() external view override returns (address) {
    return address(_grailToken);
  }

  /**
   * @dev Returns the number of available pools
   */
  function poolLength() external view returns (uint256) {
    return poolInfo.length;
  }

  /**
   * @dev Returns user data for a given pool
   */
  function getUserInfo(uint256 pid, address userAddress)
    external
    view
    override
    returns (uint256 amount, uint256 rewardDebt)
  {
    UserInfo storage user = userInfo[pid][userAddress];
    return (user.amount, user.rewardDebt);
  }

  /**
   * @dev Returns data of a given pool
   */
  function getPoolInfo(uint256 pid)
    external
    view
    override
    returns (
      address lpToken,
      uint256 allocPoint,
      uint256 lastRewardTime,
      uint256 accRewardsPerShare,
      uint256 depositFeeBP,
      bool isGrailRewards,
      uint256 lpSupply,
      uint256 lpSupplyWithMultiplier
    )
  {
    PoolInfo storage pool = poolInfo[pid];
    return (
      address(pool.lpToken),
      pool.allocPoint,
      pool.lastRewardTime,
      pool.accRewardsPerShare,
      pool.depositFeeBP,
      pool.isGrailRewards,
      pool.lpSupply,
      pool.lpSupplyWithMultiplier
    );
  }

  /**
   * @dev Returns a given user pending rewards for a given pool
   */
  function pendingRewards(uint256 pid, address userAddress) external view returns (uint256 pending) {
    uint256 accRewardsPerShare = _getCurrentAccRewardsPerShare(pid);
    UserInfo storage user = userInfo[pid][userAddress];
    pending = user.amount.mul(accRewardsPerShare).div(1e18).sub(user.rewardDebt);
    return pending;
  }

  /****************************************************************/
  /****************** EXTERNAL PUBLIC FUNCTIONS  ******************/
  /****************************************************************/

  /**
   * @dev Updates rewards states of the given pool to be up-to-date
   */
  function updatePool(uint256 pid) external nonReentrant validatePool(pid) {
    _updatePool(pid);
  }

  /**
   * @dev Updates rewards states for all pools
   *
   * Be careful of gas spending
   */
  function massUpdatePools() external nonReentrant {
    _massUpdatePools();
  }

  /**
   * @dev Harvests user's pending rewards on a given pool
   */
  function harvest(uint256 pid) external override nonReentrant validatePool(pid) {
    address userAddress = msg.sender;
    PoolInfo storage pool = poolInfo[pid];
    UserInfo storage user = userInfo[pid][userAddress];

    _updatePool(pid);
    _harvest(pid, pool, user, userAddress);

    user.rewardDebt = user.amount.mul(pool.accRewardsPerShare).div(1e18);
  }

  /**
   * @dev Deposits LP tokens on a given pool for rewards allocation
   */
  function deposit(uint256 pid, uint256 amount) external override nonReentrant validatePool(pid) {
    address userAddress = msg.sender;
    PoolInfo storage pool = poolInfo[pid];
    UserInfo storage user = userInfo[pid][userAddress];

    _updatePool(pid);
    _harvest(pid, pool, user, userAddress);

    if (amount > 0) {
      // handle tokens with auto burn
      uint256 previousBalance = pool.lpToken.balanceOf(address(this));
      pool.lpToken.safeTransferFrom(userAddress, address(this), amount);
      amount = pool.lpToken.balanceOf(address(this)).sub(previousBalance);

      // check if depositFee is enabled
      if (pool.depositFeeBP > 0) {
        uint256 depositFee = amount.mul(pool.depositFeeBP).div(10000);
        amount = amount.sub(depositFee);
        pool.lpToken.safeTransfer(feeAddress, depositFee);
      }

      user.amount = user.amount.add(amount);

      pool.lpSupply = pool.lpSupply.add(amount);
      pool.lpSupplyWithMultiplier = pool.lpSupplyWithMultiplier.add(amount);
    }
    user.rewardDebt = user.amount.mul(pool.accRewardsPerShare).div(1e18);
    emit Deposit(userAddress, pid, amount);
  }

  /**
   * @dev Withdraw LP tokens from a given pool
   */
  function withdraw(uint256 pid, uint256 amount) external override nonReentrant validatePool(pid) {
    address userAddress = msg.sender;
    PoolInfo storage pool = poolInfo[pid];
    UserInfo storage user = userInfo[pid][userAddress];

    require(user.amount >= amount, "withdraw: invalid amount");

    _updatePool(pid);
    _harvest(pid, pool, user, userAddress);

    if (amount > 0) {
      user.amount = user.amount.sub(amount);

      pool.lpSupply = pool.lpSupply.sub(amount);
      pool.lpSupplyWithMultiplier = pool.lpSupplyWithMultiplier.sub(amount);
      pool.lpToken.safeTransfer(userAddress, amount);
    }
    user.rewardDebt = user.amount.mul(pool.accRewardsPerShare).div(1e18);
    emit Withdraw(userAddress, pid, amount);
  }

  /**
   * @dev Withdraw without caring about rewards, EMERGENCY ONLY
   */
  function emergencyWithdraw(uint256 pid) external validatePool(pid) {
    PoolInfo storage pool = poolInfo[pid];
    UserInfo storage user = userInfo[pid][msg.sender];
    uint256 amount = user.amount;

    pool.lpSupply = pool.lpSupply.sub(user.amount);
    pool.lpSupplyWithMultiplier = pool.lpSupplyWithMultiplier.sub(user.amount);
    user.amount = 0;
    user.rewardDebt = 0;

    emit EmergencyWithdraw(msg.sender, pid, amount);
    pool.lpToken.safeTransfer(msg.sender, amount);
  }

  /*****************************************************************/
  /****************** EXTERNAL OWNABLE FUNCTIONS  ******************/
  /*****************************************************************/

  /**
   * @dev Updates dev address
   *
   * Must only be called by devAddress
   */
  function setDevAddress(address newDevAddress) external {
    require(msg.sender == devAddress, "caller is not devAddress");
    require(newDevAddress != address(0), "zero address");
    emit DevAddressUpdated(devAddress, newDevAddress);
    devAddress = newDevAddress;
  }

  /**
   * @dev Updates fee address
   *
   * Must only be called by the owner
   */
  function setFeeAddress(address newFeeAddress) external onlyOwner {
    require(newFeeAddress != address(0), "zero address");
    emit FeeAddressUpdated(feeAddress, newFeeAddress);
    feeAddress = newFeeAddress;
  }

  /**
   * @dev Updates the emission rate
   * param withUpdate should be set to true every time it's possible
   *
   * Must only be called by the owner
   */
  function updateEmissionRate(uint256 newEmissionRate, bool withUpdate) external onlyOwner {
    require(newEmissionRate >= MINIMUM_EMISSION_RATE, "rewardsPerSecond mustn't exceed the minimum");
    require(newEmissionRate <= INITIAL_EMISSION_RATE, "rewardsPerSecond mustn't exceed the maximum");
    if(withUpdate) _massUpdatePools();
    emit EmissionRateUpdated(rewardsPerSecond, newEmissionRate);
    rewardsPerSecond = newEmissionRate;
  }

  /**
   * @dev Adds a new pool
   * param withUpdate should be set to true every time it's possible
   *
   * Must only be called by the owner
   */
  function add(
    uint256 allocPoint,
    IERC20 lpToken,
    uint256 depositFeeBP,
    bool isGrailRewards,
    bool withUpdate
  ) external onlyOwner {
    require(depositFeeBP <= MAX_DEPOSIT_FEE_BP, "add: invalid deposit fee basis points");
    uint256 currentBlockTimestamp = _currentBlockTimestamp();

    if (withUpdate && allocPoint > 0) {
      // Updates all pools if new pool allocPoint > 0
      _massUpdatePools();
    }

    uint256 lastRewardTime = currentBlockTimestamp > startTime ? currentBlockTimestamp : startTime;
    totalAllocPoint = totalAllocPoint.add(allocPoint);
    poolInfo.push(
      PoolInfo({
        lpToken: lpToken,
        lpSupply: 0,
        lpSupplyWithMultiplier: 0,
        allocPoint: allocPoint,
        lastRewardTime: lastRewardTime,
        accRewardsPerShare: 0,
        depositFeeBP: depositFeeBP,
        isGrailRewards: isGrailRewards
      })
    );

    emit PoolAdded(poolInfo.length.sub(1), allocPoint, address(lpToken), depositFeeBP, isGrailRewards);
  }

  /**
   * @dev Updates configuration on existing pool
   * param withUpdate should be set to true every time it's possible
   *
   * Must only be called by the owner
   */
  function set(
    uint256 pid,
    uint256 allocPoint,
    uint256 depositFeeBP,
    bool withUpdate
  ) external onlyOwner {
    require(depositFeeBP <= MAX_DEPOSIT_FEE_BP, "set: invalid deposit fee basis points");
    PoolInfo storage pool = poolInfo[pid];
    uint256 prevAllocPoint = pool.allocPoint;

    if (withUpdate && allocPoint != prevAllocPoint) {
      // Updates each existent pool if new allocPoints differ from the previously ones
      _massUpdatePools();
    }

    pool.allocPoint = allocPoint;
    pool.depositFeeBP = depositFeeBP;
    if (prevAllocPoint != allocPoint) {
      totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(allocPoint);
    }

    emit PoolConfigUpdated(pid, allocPoint, address(pool.lpToken), depositFeeBP);
  }

  /********************************************************/
  /****************** INTERNAL FUNCTIONS ******************/
  /********************************************************/

  /**
   * @dev Returns the accRewardsPerShare adjusted for current block of a given pool
   */
  function _getCurrentAccRewardsPerShare(uint256 pid) internal view returns (uint256) {
    uint256 currentBlockTimestamp = _currentBlockTimestamp();
    PoolInfo storage pool = poolInfo[pid];
    uint256 accRewardsPerShare = pool.accRewardsPerShare;

    // check if pool is active and not already up-to-date
    if (currentBlockTimestamp > pool.lastRewardTime && pool.lpSupplyWithMultiplier > 0) {
      uint256 nbSeconds = currentBlockTimestamp.sub(pool.lastRewardTime);
      uint256 tokensReward = nbSeconds.mul(rewardsPerSecond).mul(pool.allocPoint).mul(1e18).div(totalAllocPoint);
      return accRewardsPerShare.add(tokensReward.div(pool.lpSupplyWithMultiplier));
    }

    return accRewardsPerShare;
  }

  /**
   * @dev Harvests the pending rewards for a given pool and user
   * Does not update user.rewardDebt !
   * Functions calling this must update rewardDebt themselves
   */
  function _harvest(
    uint256 pid,
    PoolInfo storage pool,
    UserInfo storage user,
    address userAddress
  ) internal {
    if (user.amount > 0) {
      uint256 pending = user.amount.mul(pool.accRewardsPerShare).div(1e18).sub(user.rewardDebt);
      if (pending > 0) {
        if (pool.isGrailRewards) {
          _safeRewardsTransfer(userAddress, pending, _grailToken);
        } else {
          _safeRewardsTransfer(userAddress, pending, _excToken);
        }
        emit Harvest(userAddress, pid, pending);
      }
    }
  }

  /**
   * @dev Safe token transfer function, in case rounding error causes pool to not have enough tokens
   */
  function _safeRewardsTransfer(
    address to,
    uint256 amount,
    IERC20Mintable tokenReward
  ) internal {
    uint256 tokenRewardBalance = tokenReward.balanceOf(address(this));
    bool transferSuccess = false;
    if (amount > tokenRewardBalance) {
      transferSuccess = tokenReward.transfer(to, tokenRewardBalance);
    } else {
      transferSuccess = tokenReward.transfer(to, amount);
    }
    require(transferSuccess, "safeRewardTransfer: Transfer failed");
  }

  /**
   * @dev Updates rewards states of the given pool to be up-to-date
   */
  function _updatePool(uint256 pid) internal {
    uint256 currentBlockTimestamp = _currentBlockTimestamp();
    PoolInfo storage pool = poolInfo[pid];

    if (currentBlockTimestamp <= pool.lastRewardTime) {
      return;
    }

    if (pool.lpSupplyWithMultiplier == 0) {
      pool.lastRewardTime = currentBlockTimestamp;
      return;
    }

    uint256 nbSeconds = currentBlockTimestamp.sub(pool.lastRewardTime);
    uint256 tokensReward = nbSeconds.mul(rewardsPerSecond).mul(pool.allocPoint).div(totalAllocPoint);
    pool.accRewardsPerShare = pool.accRewardsPerShare.add(tokensReward.mul(1e18).div(pool.lpSupplyWithMultiplier));
    pool.lastRewardTime = currentBlockTimestamp;

    _excToken.mint(devAddress, tokensReward.div(10));
    if (pool.isGrailRewards) {
      _grailToken.mint(address(this), tokensReward);
    } else {
      _excToken.mint(address(this), tokensReward);
    }

    emit PoolUpdated(pid, pool.lastRewardTime, pool.accRewardsPerShare);
  }

  /**
   * @dev Updates rewards states for all pools
   *
   * Be careful of gas spending
   */
  function _massUpdatePools() internal {
    uint256 length = poolInfo.length;
    for (uint256 pid = 0; pid < length; ++pid) {
      _updatePool(pid);
    }
  }

  /**
   * @dev Utility function to get the current block timestamp
   */
  function _currentBlockTimestamp() internal view virtual returns (uint256) {
    return block.timestamp;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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
    constructor () {
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