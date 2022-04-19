// SPDX-License-Identifier: MIT

//     ___                         __ 
//    /   |  _____________  ____  / /_
//   / /| | / ___/ ___/ _ \/ __ \/ __/
//  / ___ |(__  |__  )  __/ / / / /_  
// /_/  |_/____/____/\___/_/ /_/\__/  
// 
// 2022 - Assent Protocol

pragma solidity 0.8.11;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./lckAssentToken.sol";

contract AssentLocker is Ownable, ReentrancyGuard {
  using SafeMath for uint256;

  using SafeERC20 for IERC20;

  // Stacking token
  IERC20 public sToken;
	// Locked token (receipt)
  lckAssentToken immutable public lckToken;  

  // Info of each user on locked deposits
  struct UserLockSlotInfo {
    uint256 amount; // How many LP tokens the user has provided
    uint256 lockDurationSeconds; // The lock duration in seconds
    uint256 depositTime; // The time at which the user made his deposit
    uint256 multiplier; // Active multiplier (times 1e4)
    uint256 amountWithMultiplier; // Amount + lock bonus faked amount (amount + amount*multiplier)
    uint256 unlockTime; // The time at which the user can unlock from the slot
  }

  // Used to directly set disableLockSlot without having to go through the timelock
  address public operator;

  // Amount of sToken deposited in the locker - all users, all slots
  uint256 public totalAmountLocked;

  mapping(address => UserLockSlotInfo[]) public userLockSlotInfo;

  uint256 public constant MAX_USER_LOCK_SLOT = 5; // Locking slots allocation / user / pool
  uint256 public immutable MAX_LOCK_DURATION_SECONDS; // 15552000 = 180 days = 6months
  uint256 public immutable MIN_LOCK_DURATION_SECONDS; // 864000 = 10 days
  uint256 public constant MAX_MULTIPLIER = 100; // 50 = 50% / 100 = 100%

  // Disables the lock slot feature for all pools:
  //  - Enables WithdrawOnLockSlot even if lockDuration has not ended
  //  - Disables the deposits
  bool public disableLockSlot = false;

  constructor(
    IERC20 _sToken,
    lckAssentToken _lckToken,
    uint256 maxLockDuration,
    uint256 minLockDuration
  ) {
    sToken = _sToken;
    lckToken = _lckToken;
    operator = msg.sender;
    MAX_LOCK_DURATION_SECONDS = maxLockDuration;
    MIN_LOCK_DURATION_SECONDS = minLockDuration;    
  }

  /********************************************/
  /****************** EVENTS ******************/
  /********************************************/

  event DepositOnLockSlot(
    address indexed user,
    uint256 slotId,
    uint256 amount,
    uint256 lockDurationSeconds
  );
  event RenewLockSlot(
    address indexed user,
    uint256 slotId,
    uint256 amount,
    uint256 lockDurationSeconds
  );
  event WithdrawOnLockSlot(address indexed user, uint256 slotId, uint256 amount);
  event EmergencyWithdrawOnLockSlot(address indexed user, uint256 slotId, uint256 amount);
  event DisableLockSlot(bool isDisable);

  /**************************************************/
  /****************** PUBLIC VIEWS ******************/
  /**************************************************/

  /**
   * @dev Returns the number of available pools
   */
  function getUserSlotLength(address account) external view returns (uint256) {
    return userLockSlotInfo[account].length;
  }

  /**
   * @dev Returns user data of a given pool and slot
   */
  function getUserLockSlotInfo(
    address userAddress,
    uint256 slotId
  )
    external
    view
    returns (
      uint256 amount,
      uint256 lockDurationSeconds,
      uint256 depositTime,
      uint256 multiplier,
      uint256 amountWithMultiplier,
      uint256 unlockTime
    )
  {
    UserLockSlotInfo storage userSlot = userLockSlotInfo[userAddress][slotId];
    {
      return (
        userSlot.amount,
        userSlot.lockDurationSeconds,
        userSlot.depositTime,
        userSlot.multiplier,
        userSlot.amountWithMultiplier,
        userSlot.unlockTime
      );
    }
  }

  /**
   * @dev Returns true if user can unlock the slot
   */
  function userCanUnlockSlot(address userAddress, uint256 slotId) external view returns (bool) {
    UserLockSlotInfo storage userSlot = userLockSlotInfo[userAddress][slotId];
    return _currentBlockTimestamp() >= userSlot.unlockTime;
  }

  /**
   * @dev Returns expected multiplier for a "lockDurationSeconds" duration lock on a slot (result is *1e8)
   */
  function getMultiplierByLockDurationSeconds(uint256 lockDurationSeconds) public view returns (uint256 multiplier) {
    // capped to MAX_LOCK_DURATION_SECONDS
    if (lockDurationSeconds > MAX_LOCK_DURATION_SECONDS) lockDurationSeconds = MAX_LOCK_DURATION_SECONDS;
    return MAX_MULTIPLIER.mul(lockDurationSeconds).mul(1e6).div(MAX_LOCK_DURATION_SECONDS);
  }

  /****************************************************************/
  /****************** EXTERNAL PUBLIC FUNCTIONS  ******************/
  /****************************************************************/

  /**
   * @dev Deposit tokens on a lock slot
   * - A lock slot must be available
   * - Tokens will be locked for "lockDurationSeconds"
   * - lckToken amount minted for user will be proportional to the lock duration specified here
   */
  function depositOnLockSlot(
    uint256 amount,
    uint256 lockDurationSeconds
  ) external virtual nonReentrant {
    require(!disableLockSlot, "lock slot disabled");
    require(amount > 0, "amount zero");

    address userAddress = msg.sender;

    // handle tokens with transfer tax
    uint256 previousBalance = sToken.balanceOf(address(this));
    sToken.safeTransferFrom(userAddress, address(this), amount);
    amount = sToken.balanceOf(address(this)).sub(previousBalance);

    uint256 amountWithMultiplier = _lockAmount(userAddress, amount, lockDurationSeconds);
    //Mint lckToken corresponding to amountWithMultiplier
    lckToken.mint(userAddress, amountWithMultiplier);
  }

  /**
   * @dev Redeposit tokens on an already active given lock slot
   *  - Reset the lock
   *
   * if "fromRegularDeposit" is :
   * - set to true: the tokens will be transferred from the user's regular slot (userInfo), so no fees will be charged
   * - set to false: the tokens will be transferred from the user's wallet, so deposit fees will be charged
   */
  function redepositOnLockSlot(
    uint256 slotId,
    uint256 amountToAdd
  ) external virtual nonReentrant {
    require(!disableLockSlot, "lock slot disabled");
    require(amountToAdd > 0, "zero amount");

    address userAddress = msg.sender;

    // handle tokens with transfer tax
    uint256 previousBalance = sToken.balanceOf(address(this));
    sToken.safeTransferFrom(userAddress, address(this), amountToAdd);
    amountToAdd = sToken.balanceOf(address(this)).sub(previousBalance);

    totalAmountLocked += amountToAdd;

    UserLockSlotInfo storage userSlot = userLockSlotInfo[userAddress][slotId];

    require(
      userSlot.depositTime.add(userSlot.lockDurationSeconds) >= _currentBlockTimestamp(),
      "can't renew after lock time"
    );

    uint256 amountToAddWithMultiplier = amountToAdd.mul(userSlot.multiplier.add(1e8)).div(1e8);
    //Mint extra lckToken corresponding to amountToAddWithMultiplier
    lckToken.mint(userAddress, amountToAddWithMultiplier);

    // adjust balances with new deposit amount
    userSlot.amount = userSlot.amount.add(amountToAdd);
    userSlot.amountWithMultiplier = userSlot.amountWithMultiplier.add(amountToAddWithMultiplier);
    //Renew lock time for total user amount in slot with actual time
    userSlot.depositTime = _currentBlockTimestamp();
    //Update unlockTime
    userSlot.unlockTime = userSlot.depositTime.add(userSlot.lockDurationSeconds);

    emit RenewLockSlot(userAddress, slotId, userSlot.amount, userSlot.lockDurationSeconds);
  }

  /**
   * @dev Withdraw tokens from given pool and lock slot
   * - burn lckToken
   * - withdraw the deposited amount to the user's wallet
   *
   * lockDurationSeconds must be over
   */
  function withdrawOnLockSlot(uint256 slotId)
    external
    virtual
    nonReentrant
  {
    address userAddress = msg.sender;

    UserLockSlotInfo storage userSlot = userLockSlotInfo[userAddress][slotId];

    require(
      userSlot.depositTime.add(userSlot.lockDurationSeconds) <= _currentBlockTimestamp() ||
        disableLockSlot,
      "withdraw locked"
    );



    uint256 withdrawAmount = userSlot.amount;
    uint256 amountWithMultiplier = userSlot.amountWithMultiplier;

    require(lckToken.balanceOf(userAddress) >= amountWithMultiplier, "not enough lckToken");

    totalAmountLocked -= withdrawAmount;

    lckToken.burnFrom(userAddress, amountWithMultiplier);
    sToken.transfer(userAddress, withdrawAmount);

    _removeUserLockSlot(userAddress, slotId);

    emit WithdrawOnLockSlot(userAddress, slotId, withdrawAmount);
  }

  /*****************************************************************/
  /****************** EXTERNAL OWNABLE FUNCTIONS  ******************/
  /*****************************************************************/

  /**
   * @dev Unlock all locked deposits, forbid any new deposit on lock slots
   *
   * Must only be called by the owner.
   */
  function setDisableLockSlot(bool isDisable) external onlyOwner {
    disableLockSlot = isDisable;
    emit DisableLockSlot(isDisable);
  }

  function inCaseTokensGetStuck(address _token) external onlyOwner {
      require(_token != address(sToken), "Token cannot be same as deposit token");

      uint256 amount = IERC20(_token).balanceOf(address(this));
      IERC20(_token).safeTransfer(msg.sender, amount);
  }

  /********************************************************/
  /****************** INTERNAL FUNCTIONS ******************/
  /********************************************************/

  /**
   * @dev Locks amount for a given pool during lockDurationSeconds into a free slot
   */
  function _lockAmount(
    address userAddress,
    uint256 amount,
    uint256 lockDurationSeconds
  ) internal returns (uint256 amountWithMultiplier) {
    require(userLockSlotInfo[userAddress].length < MAX_USER_LOCK_SLOT, "no slot available");
    require(lockDurationSeconds >= MIN_LOCK_DURATION_SECONDS, "lockDuration mustn't exceed the minimum");
    require(lockDurationSeconds <= MAX_LOCK_DURATION_SECONDS, "lockDuration mustn't exceed the maximum");

    uint256 multiplier = getMultiplierByLockDurationSeconds(lockDurationSeconds);
    amountWithMultiplier = amount.mul(multiplier.add(1e8)).div(1e8);

    totalAmountLocked += amount;

    // create new lock slot
    userLockSlotInfo[userAddress].push(
      UserLockSlotInfo({
        amount: amount,
        lockDurationSeconds: lockDurationSeconds,
        depositTime: _currentBlockTimestamp(),
        multiplier: multiplier,
        amountWithMultiplier: amountWithMultiplier,
        unlockTime: _currentBlockTimestamp().add(lockDurationSeconds)
      })
    );
    emit DepositOnLockSlot(
      userAddress,
      userLockSlotInfo[userAddress].length.sub(1),
      amount,
      lockDurationSeconds
    );
    return amountWithMultiplier;
  }

  /**
   * @dev Removes a slot from userLockSlotInfo by index
   */
  function _removeUserLockSlot(
    address userAddress,
    uint256 slotId
  ) internal {
    UserLockSlotInfo[] storage userSlots = userLockSlotInfo[userAddress];

    // slot removal
    userSlots[slotId] = userSlots[userSlots.length - 1];
    userSlots.pop();
  }

  /**
   * @dev Utility function to get the current block timestamp
   */
  function _currentBlockTimestamp() internal view virtual returns (uint256) {
    return block.timestamp;
  }

}