/**
 *Submitted for verification at FtmScan.com on 2022-05-09
*/

/*
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
*/
// Sources flattened with hardhat v2.7.0 https://hardhat.org

// File contracts/IMasterChef721TokenBoosts.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IMasterChef721TokenBoosts {
    function getBoost(uint256 _tokenId) external view returns (uint256);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)



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
    function transferFrom(
        address sender,
        address recipient,
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


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)



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


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)



/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)



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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)



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


// File @openzeppelin/contracts/utils/math/[email protected]


// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)



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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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


/*
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
*/
// File contracts/MasterChef721PartnerRewards.sol


// The ERC721 MasterChef is a fork of MasterChef by SushiSwap
// The biggest change made is to support ERC721s instead of ERC20s
// for staking, and using per-second instead of per-block for rewards
// This is due to Fantoms extremely inconsistent block times.
//
// The `MasterChef721` contract functions similar to a ERC20 MasterChef, except for a few critical differences:
//
// 1. Each `user` (each UserInfo struct instance) corresponds to a tokenId of an ERC721
// 2. Each `pool` and corresponds to a different ERC721 (NFT Collection), and the corresponding `lp` (as in `lpToken`) is an ERC721 address.
// 3. The contract is non-custodial and simply keeps track of which tokenIds have been deposited by making the corresponding `userInfo.amount` greater than 1
// 4. Since the contract is non-custodial and pending rewards need to be summed per-tokenId when a user claims rewards, there is a separate function `claimRewards` instead of using the classic MasterChef route of `deposit(pid, 0)` performing a claim. `deposit` no longer claims rewards.
// 5. By default each tokenId in a collection receives equal rewards, but via the `setBoosts(pid...)`, specific tokenIds can get a rewards multiplier (2x, 3x ...).
// 6. `deposit()`, `pendingRewards()`, `claimRewards()` and `withdraw()` all operate on a list of tokenIds. In other words, a user deposits a specific set of tokenIds, and then specifies those tokenIds when claiming rewards or withdrawing.

contract MasterChef721PartnerRewards is Ownable {

    // Info of each user. Note: a "user" here is really a tokenId. This struct is left similar to the classic MasterChef to make for easier compatibility with dapps
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided. Note: this is really just a per-tokenId multiplier for the 721 chef
        uint256 rewardDebt; // Reward debt. See explanation below.
        // Any point in time, the amount of rewards
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardsPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardsPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC721 lpToken;                  // Address of LP token contract for this pool. Note: this is really the NFT collection, but is left as 'lpToken' to more easily maintain parallels and compatibility with classic MasterChef dapps
        IMasterChef721TokenBoosts boosts; // Address of the contract to get per-tokenId boosts for this LP
        bool hasBoosts;
        uint256 allocPoint;               // How many allocation points assigned to this pool. Rewards to distribute per block.
        uint256 lastRewardTime;           // Last block time that rewards distribution occurs.
        uint256 accRewardsPerShare;       // Accumulated rewards per share, times 1e12. See below.
        uint256 tokensStaked;             // How many tokens have been staked here - need this instead of balanceOf since non-custodial
    }

    // the token being distributed as rewards
    IERC20 public rewardToken;

    // rewardToken tokens created per second
    uint256 public rewardsPerSecond;

    // set a max rewards per second, which can never be higher than 1 per second
    uint256 public constant maxRewardsPerSecond = 1e18;

    uint256 public constant MaxAllocPoint = 4000;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    // The block time when rewards mining starts and ends.
    uint256 public immutable startTime;

    uint256 public endTime;

    // Info of each pool.
    // There is one pool per 721/NFT-collection
    PoolInfo[] public poolInfo;

    // For each pool/LP (NFT collection), which token IDs should have boosted rewards, and by what mulitplier
    // Boost of 0 just means 'no boost/multiplier'. Boost of 1 = 2x rewards, 2 = 3x rewards...
    // Note: if boost changes post-deposit, staker must withdraw and redeposit to update their rewards multiplier
    uint256 private maxBoost = 1;

    // Info of each user that stakes LP tokens.
    // For this 721 version of MasterChef, this is really per-tokenId info for each pool
    mapping (uint256 => mapping (uint256 => UserInfo)) public userInfo;

    error DontOwn(address sender, uint256 pid, uint256 tokenId);
    error NotStaked(address sender, uint256 pid, uint256 tokenId);
    error AlreadyStaked(address sender, uint256 pid, uint256 tokenId);

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        IERC20 _rewardToken,
        uint256 _rewardsPerSecond,
        uint256 _startTime,
        uint256 _endTime
    ) {
        rewardToken = _rewardToken;
        rewardsPerSecond = _rewardsPerSecond;
        startTime = _startTime;
        endTime = _endTime;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function setEndTime(uint256 _endTime) external onlyOwner {
        endTime = _endTime;
    }

    // Changes rewardToken reward per second, with a cap of maxrewards per second
    // Good practice to update pools without messing up the contract
    function setRewardsPerSecond(uint256 _rewardsPerSecond) external onlyOwner {
        require(_rewardsPerSecond <= maxRewardsPerSecond, "setRewardsPerSecond: rewards > max!");

        // This MUST be done or pool rewards will be calculated with new rewards per second
        // This could unfairly punish small pools that dont have frequent deposits/withdraws/harvests
        massUpdatePools();

        rewardsPerSecond = _rewardsPerSecond;
    }

    function checkForDuplicate(IERC721 _lpToken) internal view {
        uint256 length = poolInfo.length;
        for (uint256 _pid; _pid < length; ) {
            require(poolInfo[_pid].lpToken != _lpToken, "add: pool already exists!");
            unchecked { ++_pid; }
        }
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IERC721 _lpToken, IMasterChef721TokenBoosts _boosts, bool _hasBoosts) external onlyOwner {
        require(_allocPoint <= MaxAllocPoint, "add: too many alloc points!!");

        checkForDuplicate(_lpToken); // ensure you cant add duplicate pools

        massUpdatePools();

        uint256 lastRewardTime = block.timestamp > startTime ? block.timestamp : startTime;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            boosts: _boosts,
            hasBoosts: _hasBoosts,
            allocPoint: _allocPoint,
            lastRewardTime: lastRewardTime,
            accRewardsPerShare: 0,
            tokensStaked: 0
        }));
    }

    // Update the given pool's rewards allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint) external onlyOwner {
        require(_allocPoint <= MaxAllocPoint, "add: too many alloc points!!");

        massUpdatePools();

        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Set max boost possible for per-tokenId boosts/multipliers
    function setMaxBoost(uint256 _max) external onlyOwner {
        maxBoost = _max;
    }
    // Set contract for per-tokenId boosts/multipliers for an LP (721). Optional.
    function setBoosts(uint256 _pid, IMasterChef721TokenBoosts _boosts) external onlyOwner {
        poolInfo[_pid].boosts = _boosts;
        poolInfo[_pid].hasBoosts = true;
    }

    // Note: disable all boosts - if boosts are reenabled, old boosts will remain in effect
    function disableBoosts(uint256 _pid) external onlyOwner {
        poolInfo[_pid].hasBoosts = false;
    }


    // Return reward multiplier over the given _from to _to timestamp.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        // Rewards only exist within the startTime -> endTime window
        // Clip from -> to window to fit the rewards range
        _from = _from > startTime ? _from : startTime;
        _to   = _to < endTime ? _to : endTime;

        if (_to < startTime) {
            return 0;  // rewards have not started
        } else if (_from >= endTime) {
            return 0;  // rewards have ended
        } else {
            return _to - _from;
        }
    }

    // View function to see pending rewards on frontend.
    function pendingRewards(uint256 _pid, uint256[] memory _tokenIds) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];

        // Pull relevant pool info into memory post-update
        uint256 accRewardsPerShare = pool.accRewardsPerShare;
        uint256 lpSupply = pool.tokensStaked;

        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
            uint256 rewards = multiplier * rewardsPerSecond * pool.allocPoint / totalAllocPoint;
            accRewardsPerShare += rewards * 1e12 / lpSupply;
        }

        uint256 pending = 0;
        for (uint256 i; i < _tokenIds.length;) {
            UserInfo storage user = userInfo[_pid][_tokenIds[i]];
            pending += user.amount * accRewardsPerShare / 1e12 - user.rewardDebt;
            unchecked { ++i; }
        }
        return pending;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid; pid < length;) {
            updatePool(pid);
            unchecked { ++pid; }
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public returns (IERC721, uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) return (pool.lpToken, pool.accRewardsPerShare);

        uint256 lpSupply = pool.tokensStaked;
        if (lpSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return (pool.lpToken, pool.accRewardsPerShare);
        }

        uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
        uint256 rewards = multiplier * rewardsPerSecond * pool.allocPoint / totalAllocPoint;

        pool.accRewardsPerShare = pool.accRewardsPerShare + rewards * 1e12 / lpSupply;
        pool.lastRewardTime = block.timestamp;
        return (pool.lpToken, pool.accRewardsPerShare / 1e12);
    }

    // Claim rewards for the specified tokenIds of the specified pool/721.
    function claimRewards(uint256 _pid, uint256[] memory _tokenIds) public {
        // Relevant pool info must be pulled into memory AFTER the pool updates
        (IERC721 lpToken, uint256 accRewardsPerShare) = updatePool(_pid);

        uint256 pending;
        uint256 len = _tokenIds.length;
        for (uint256 i; i < len;) {
            uint256 tokenId = _tokenIds[i];

            if (lpToken.ownerOf(tokenId) != msg.sender) revert DontOwn(msg.sender, _pid, tokenId);

            UserInfo storage user = userInfo[_pid][tokenId];
            uint256 amount = user.amount;

            // user.amount > 0 for a tokenId means that it is staked
            if (amount == 0) revert NotStaked(msg.sender, _pid, tokenId);

            pending += amount * accRewardsPerShare - user.rewardDebt;

            user.rewardDebt = amount * accRewardsPerShare;

            unchecked { ++i; }
        }
        if (pending > 0) {
            safeRewardTokenTransfer(msg.sender, pending);
            emit Claim(msg.sender, _pid, pending);
        }
    }

    // Deposit LP tokens to MasterChef for rewards allocation.
    // Since this version of the chef is non-custodial, just flag each tokenId's
    // `userInfo.amount` as > 0 to flag it as staked.
    function deposit(uint256 _pid, uint256[] memory _tokenIds) public {
        PoolInfo storage pool = poolInfo[_pid];
        // Relevant pool info must be pulled into memory AFTER the pool updates
        (IERC721 lpToken, uint256 accRewardsPerShare) = updatePool(_pid);

        // Pull relevant pool info into memory post-update
        IMasterChef721TokenBoosts boosts = pool.boosts;
        bool hasBoosts = pool.hasBoosts;

        uint256 newlyStaked;
        uint256 len = _tokenIds.length;
        for (uint256 i; i < len;) {
            uint256 tokenId = _tokenIds[i];

            if (lpToken.ownerOf(tokenId) != msg.sender) revert DontOwn(msg.sender, _pid, tokenId);

            UserInfo storage user = userInfo[_pid][tokenId];

            // user.amount > 0 for a tokenId means that it is staked
            if (user.amount > 0) revert AlreadyStaked(msg.sender, _pid, tokenId);

            // (don't need to do transfer tokens to this contract - just set amount to 0)
            uint256 amount;
            if (hasBoosts) {
                uint256 boost = boosts.getBoost(tokenId);
                amount = boost < maxBoost ? boost + 1 : maxBoost + 1;
            } else {
                amount = 1;
            }

            newlyStaked += amount;
            user.amount = amount;

            user.rewardDebt = amount * accRewardsPerShare;

            unchecked { ++i; }
        }

        if (newlyStaked > 0) {
            pool.tokensStaked += newlyStaked;
        }

        emit Deposit(msg.sender, _pid, newlyStaked);
    }

    // Withdraw LP tokens from MasterChef.
    // For this 721 version, this just stops the specified tokenIds from receiving rewards.
    // Withdraw triggers 'claimRewards' as well.
    function withdraw(uint256 _pid, uint256[] memory _tokenIds) public {
        // Relevant pool info must be pulled into memory AFTER the pool updates
        (IERC721 lpToken, uint256 accRewardsPerShare) = updatePool(_pid);

        uint256 pending;
        uint256 amountUnstaked;
        uint256 len = _tokenIds.length;
        for (uint256 i; i < len;) {
            uint256 tokenId = _tokenIds[i];

            if (lpToken.ownerOf(tokenId) != msg.sender) revert DontOwn(msg.sender, _pid, tokenId);

            UserInfo storage user = userInfo[_pid][tokenId];

            uint256 amount = user.amount;
            // user.amount > 0 for a tokenId means that it is staked
            if (amount == 0) revert NotStaked(msg.sender, _pid, tokenId);

            pending += amount * accRewardsPerShare - user.rewardDebt;
            amountUnstaked += amount;

            user.rewardDebt = amount * accRewardsPerShare;
            user.amount = 0;

            unchecked { ++i; }
        }

        poolInfo[_pid].tokensStaked -= amountUnstaked;

        if (pending > 0) safeRewardTokenTransfer(msg.sender, pending);

        emit Withdraw(msg.sender, _pid, _tokenIds.length);
    }

    // Safe rewardToken transfer function, just in case if rounding error causes pool to not have enough rewards.
    function safeRewardTokenTransfer(address _to, uint256 _amount) internal {
        uint256 rewardBal = rewardToken.balanceOf(address(this));
        if (_amount > rewardBal) {
            rewardToken.transfer(_to, rewardBal);
        } else {
            rewardToken.transfer(_to, _amount);
        }
    }
}