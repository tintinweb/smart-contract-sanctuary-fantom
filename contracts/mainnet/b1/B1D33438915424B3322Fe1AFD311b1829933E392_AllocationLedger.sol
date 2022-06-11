//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.9;

import "./PausableActions.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev This contract can be used to keep a ledger of deposits.
 *      Users can deposit an ERC20 token into the contract.
 *      The owner can withdraw the deposited funds.
 *      The contract will keep the ledger of the ammounts deposited by the users.
 *      The contract can calculate the percentage of deposits for each user.
 */
contract AllocationLedger is
    ReentrancyGuard,
    Context,
    Ownable,
    PausableActions
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant PRECISION = 10**6;

    bytes32 public constant PAUSE_ACTION_DEPOSIT =
        keccak256("PAUSE_ACTION_DEPOSIT");
    bytes32 public constant PAUSE_ACTION_CLAIM =
        keccak256("PAUSE_ACTION_CLAIM");

    // Address of the token used for deposits.
    IERC20 public depositToken;
    // Address of the reward token
    IERC20 public rewardsToken;
    // Optional overall deposit limit. Disabled if 0.
    uint256 public depositMax = 0;
    // Optional max amount a single user can deposit. Disabled if 0.
    uint256 public depositUserMax = 0;
    // Optional min amount a single user should deposit. Disabled if 0.
    uint256 public depositUserMin = 0;
    // Number of addresses in the whitelist. Used to check if the whitelist is enable.
    uint256 public whitelistLength = 0;

    // Total sum of all deposits.
    uint256 public totalDeposits = 0;
    // Total amount of rewards deposited.
    uint256 public totalRewardsDeposited;
    // Total amount of rewards claimed.
    uint256 public totalRewardsClaimed;

    // List of all users who diposited tokens.
    address[] public accounts;

    // Mapping of all user deposits.
    mapping(address => uint256) public deposits;

    // Mapping of all user claims.
    mapping(address => uint256) public claims;

    // Mapping with addresses, who can deposit.
    mapping(address => bool) public whitelisted;

    // Emited when an address is added to the whitelist.
    event WhitelistEntryAdded(address indexed account);
    // Emited when an address is removed from the whitelist.
    event WhitelistEntryRemoved(address indexed account);
    // Emited when a user depoasits funds.
    event DepositAdded(
        address indexed account,
        uint256 amount,
        uint256 oldDeposit,
        uint256 newDeposit
    );
    // Emited when the owner withdraws the deposited funds.
    event Withdrawn(address indexed account, uint256 amount);
    // Emited when the owner deposits the reward tokens.
    event RewardsDeposited(address indexed account, uint256 amount);
    // Emited when the user claims rewards.
    event RewardsClaimed(
        address indexed account,
        uint256 amount,
        uint256 oldAmount
    );

    /**
     * @dev Reverts the transaction if the `account` is not whitelist while the whitelist is enabled.
     */
    modifier onlyWhitelisted(address account) {
        require(
            whitelistLength == 0 || whitelisted[account],
            "Account not whitelisted"
        );
        _;
    }

    /**
     * @dev Constructor with the default values.
     * @param depositToken_ Address of the ERC20 token contract that will be deposited to this contract.
     * @param depositMax_ Maximumn amount of tokens that can be deposited to this contract. Will be disabled if equal 0.
     * @param depositUserMax_ Maximum amount a single account can deposit to this contract. Will be disabled if equal 0.
     * @param whitelist_ List of addresses to add to the whitelist. If the array is empty, the whitelist will be disabled.
     */
    constructor(
        IERC20 depositToken_,
        uint256 depositMax_,
        uint256 depositUserMax_,
        uint256 depositUserMin_,
        address[] memory whitelist_,
        IERC20 rewardsToken_
    ) {
        depositToken = depositToken_;
        rewardsToken = rewardsToken_;

        setLimits(depositMax_, depositUserMax_, depositUserMin_);
        addToWhitelist(whitelist_);

        _pause(PAUSE_ACTION_CLAIM);
    }

    /**
     * @dev Transfers the `depositAmount` from the caller to this contract.
     *      Prior calling this function, user must give this contract an allowance >= `depositAmount`.
     */
    function deposit(uint256 depositAmount)
        external
        nonReentrant
        whenNotPausedAction(PAUSE_ACTION_DEPOSIT)
        onlyWhitelisted(_msgSender())
    {
        uint256 _oldDeposit = deposits[_msgSender()];
        uint256 _newDeposit = _oldDeposit.add(depositAmount);
        uint256 _newTotalDeposits = totalDeposits.add(depositAmount);

        require(
            depositMax == 0 || _newTotalDeposits < depositMax,
            "Global deposit limit exceded"
        );
        require(
            depositUserMax == 0 || _newDeposit <= depositUserMax,
            "User max deposit limit exceded"
        );
        require(
            depositUserMin == 0 || _newDeposit >= depositUserMin,
            "User min deposit not reached"
        );

        depositToken.safeTransferFrom(
            _msgSender(),
            address(this),
            depositAmount
        );

        if (_oldDeposit == 0) {
            accounts.push(_msgSender());
        }

        deposits[_msgSender()] = _newDeposit;
        totalDeposits = _newTotalDeposits;

        emit DepositAdded(
            _msgSender(),
            depositAmount,
            _oldDeposit,
            _newDeposit
        );
    }

    /**
     * @dev Used to claim available rewards to the `_msgSender()` address.
     */
    function claimRewards()
        external
        whenPausedAction(PAUSE_ACTION_DEPOSIT)
        whenNotPausedAction(PAUSE_ACTION_CLAIM)
        onlyWhitelisted(_msgSender())
    {
        require(deposits[_msgSender()] > 0, "Account never deposited");

        uint256 accountShare = getAccountRewards(_msgSender());
        uint256 alreadyClaimed = claims[_msgSender()];
        uint256 amount = accountShare - alreadyClaimed;

        require(amount > 0, "Nothing to claim");

        rewardsToken.transfer(_msgSender(), amount);
        claims[_msgSender()] = alreadyClaimed.add(amount);
        totalRewardsClaimed += amount;
        emit RewardsClaimed(_msgSender(), amount, alreadyClaimed);
    }

    /**
     * @dev Used by the owner to withdraw all deposited funds to the `_msgSender()` address.
     */
    function withdrawDeposits(uint256 amount, bool pauseDeposits_)
        external
        nonReentrant
        onlyOwner
    {
        depositToken.safeTransfer(_msgSender(), amount);

        emit Withdrawn(_msgSender(), amount);

        if (pauseDeposits_) {
            _pause(PAUSE_ACTION_DEPOSIT);
        }
    }

    /**
     * @dev Used by the owner to deposit the rewards tokens.
     */
    function depositRewards(uint256 amount) external onlyOwner {
        require(address(rewardsToken) != address(0), "Rewards token not set");
        require(totalDeposits > 0, "No deposits");

        rewardsToken.transferFrom(_msgSender(), address(this), amount);
        totalRewardsDeposited += amount;
    }

    /**
     * @dev Used by the owner to withdraw rest of the rewards.
     */
    function withdrawRewards(uint256 amount) external onlyOwner {
        uint256 availableRewards = totalRewardsDeposited - totalRewardsClaimed;
        require(availableRewards >= amount, "Not enough rewards");

        rewardsToken.safeTransfer(_msgSender(), amount);

        totalRewardsDeposited -= amount;
    }

    /**
     * @dev Returns the account's share of the total deposits in percent.
     * @notice To get the percentage, the return value must be devided by PRECISION (10 ** 6).
     */
    function getAccountShare(address account) public view returns (uint256) {
        return deposits[account].mul(100).mul(PRECISION).div(totalDeposits);
    }

    /**
     * @dev Returns the account's share of the total rewards in wei.
     */
    function getAccountRewards(address account) public view returns (uint256) {
        if (totalRewardsDeposited == 0) {
            return 0;
        }

        uint256 accountShare = getAccountShare(account);

        if (accountShare == 0) {
            return 0;
        }

        return totalRewardsDeposited.mul(accountShare).div(PRECISION).div(100);
    }

    /**
     * @dev Set the deposit limits.
     */
    function setLimits(
        uint256 depositMax_,
        uint256 depositUserMax_,
        uint256 depositUserMin_
    ) public onlyOwner {
        depositMax = depositMax_;
        depositUserMax = depositUserMax_;
        depositUserMin = depositUserMin_;
    }

    /**
     * @dev Set the rewards token address if not deposited before.
     *
     * Requirements:
     *
     * - No rewards must be deposited
     */
    function setRewardsToken(IERC20 rewardsToken_) external onlyOwner {
        require(totalRewardsDeposited == 0, "Already deposited");
        rewardsToken = rewardsToken_;
    }

    /**
     * @dev Adds a list of accounts to the whitelist.
     */
    function addToWhitelist(address[] memory accounts_) public onlyOwner {
        for (uint256 index = 0; index < accounts_.length; index++) {
            whitelisted[accounts_[index]] = true;
            emit WhitelistEntryAdded(accounts_[index]);
        }

        whitelistLength += accounts_.length;
    }

    /**
     * @dev Removes a list of accounts from the whitelist.
     */
    function removeFromWhitelist(address[] memory accounts_) public onlyOwner {
        for (uint256 index = 0; index < accounts_.length; index++) {
            whitelisted[accounts_[index]] = false;
            emit WhitelistEntryRemoved(accounts_[index]);
        }

        whitelistLength -= accounts_.length;
    }

    /**
     * @dev External function to pause the default action.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev External function to pause an action.
     */
    function pauseAction(bytes32 action) external onlyOwner {
        _pause(action);
    }

    /**
     * @dev External function to pause the deposits.
     */
    function pauseDeposit() external onlyOwner {
        _pause(PAUSE_ACTION_DEPOSIT);
    }

    /**
     * @dev External function to pause the claiming.
     */
    function pauseClaim() external onlyOwner {
        _pause(PAUSE_ACTION_CLAIM);
    }

    /**
     * @dev External function to unpause the default action.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev External function to unpause an action.
     */
    function unpauseAction(bytes32 action) external onlyOwner {
        _unpause(action);
    }

    /**
     * @dev External function to unpause the deposits.
     */
    function unpauseDeposit() external onlyOwner {
        _unpause(PAUSE_ACTION_DEPOSIT);
    }

    /**
     * @dev External function to unpause the claiming.
     */
    function unpauseClaim() external onlyOwner {
        _unpause(PAUSE_ACTION_CLAIM);
    }

    /**
     * @dev Revert the transaction if the owner tries to renounce the ownership.
     *      If this would happen, all funds would be trapped in this contract.
     */
    function renounceOwnership() public virtual override onlyOwner {
        revert("Renounce not allowed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract which allows children to implement an emergency stop
 * for different types of actions.
 *
 * @notice Based on OpenZeppelin pausable
 * See: https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable
 */
abstract contract PausableActions is Context {
    // Constant with the name of the default action.
    bytes32 public constant PAUSE_ACTION_DEFAULT = 0x00;

    /**
     * @dev Emitted when `account` triggers the pause for `action`
     */
    event Paused(address account, bytes32 action);

    /**
     * @dev Emitted when `account` lifts the pause for `action`
     */
    event Unpaused(address account, bytes32 action);

    // Mapping with the pause state of different actions.
    mapping(bytes32 => bool) public _pausedActions;

    /**
     * Returns true if the default action is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _pausedActions[PAUSE_ACTION_DEFAULT];
    }

    /**
     * Returns true if the `action` is paused, and false otherwise.
     */
    function pausedAction(bytes32 action) public view virtual returns (bool) {
        return _pausedActions[action];
    }

    /**
     * @dev Modifier to make a function callable only when the default action is not paused.
     *
     * Requirements:
     *
     * - The default action must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the `action` is paused.
     *
     * Requirements:
     *
     * - The `action` must not be paused.
     */
    modifier whenNotPausedAction(bytes32 action) {
        require(!pausedAction(action), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the default action is  paused.
     *
     * Requirements:
     *
     * - The default action must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the `action` is  paused.
     *
     * Requirements:
     *
     * - The `action` must be paused.
     */
    modifier whenPausedAction(bytes32 action) {
        require(pausedAction(action), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers paused state for default action.
     *
     * Requirements:
     *
     * - Default action must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _pause(PAUSE_ACTION_DEFAULT);
    }

    /**
     * @dev Triggers paused state for `action`.
     *
     * Requirements:
     *
     * - `action` must not be paused.
     */
    function _pause(bytes32 action)
        internal
        virtual
        whenNotPausedAction(action)
    {
        _pausedActions[action] = true;
        emit Paused(_msgSender(), action);
    }

    /**
     * @dev Returns to normal state for default action.
     *
     * Requirements:
     *
     * - The default action must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _unpause(PAUSE_ACTION_DEFAULT);
    }

    /**
     * @dev Returns to normal state for `action`.
     *
     * Requirements:
     *
     * - The `action` must be paused.
     */
    function _unpause(bytes32 action)
        internal
        virtual
        whenPausedAction(action)
    {
        _pausedActions[action] = false;
        emit Unpaused(_msgSender(), action);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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