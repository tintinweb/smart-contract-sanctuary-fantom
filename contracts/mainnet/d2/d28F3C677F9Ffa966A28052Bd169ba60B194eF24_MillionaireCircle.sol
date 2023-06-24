// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.8;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MillionaireCircle is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    constructor(address _usdc, address _platformToken, address _marketing) {
        usdc = IERC20(_usdc);
        platformToken = IERC20(_platformToken);
        marketing = _marketing;

        globalEarnings.push(14 * 1e5);
        globalEarnings.push(6 * 1e6);

        privateEarnings[1].push(142 * 1e4);
        privateEarnings[1].push(25 * 1e5);

        privateEarnings[2].push(15 * 1e5);
        privateEarnings[2].push(175 * 1e5);

        privateEarnings[3].push(3125 * 1e4);
        privateEarnings[3].push(35 * 1e6);

        privateEarnings[4].push(475 * 1e5);
        privateEarnings[4].push(525 * 1e5);

        privateEarnings[5].push(60 * 1e6);
        privateEarnings[5].push(70 * 1e6);

        privateEarnings[6].push(140 * 1e6);
        privateEarnings[6].push(140 * 1e6);

        startDate = block.timestamp;

        Member storage newUser = accounts[1];
        newUser.walletAddress = msg.sender;
        newUser.globalLevel = 1;
        newUser.privateLevel = 1;
        newUser.regDate = block.timestamp;
        newUser.lastMiningDate = block.timestamp;
        myIds[msg.sender].push(1);
        lastId = 1;
    }

    function withdraw(uint256 id) external {
        Member storage user = accounts[id];
        require(user.walletAddress == msg.sender, "NOT ALLOWED");

        uint256 amount = amountAvailableForMining(id);
        user.lastMiningDate = block.timestamp;

        platformToken.transfer(user.walletAddress, amount);
    }

    function activateAll(uint256 refId, address walletAddress) public {
        uint256 id = addGlobalAccount(refId, walletAddress);
        activatePrivateAccount(id);
    }

    function addGlobalAccount(
        uint256 refId,
        address walletAddress
    ) public returns (uint256) {
        require(running, "NOT RUNNING");
        usdc.transferFrom(msg.sender, address(this), GLOBAL_FEE);

        uint256 id = lastId + 1;
        require(refId > 0 && refId < id, "Invalid Ref ID");

        myIds[walletAddress].push(id);

        Member storage newUser = accounts[id];
        newUser.refId = refId;
        newUser.walletAddress = walletAddress;
        newUser.globalLevel = 1;
        newUser.regDate = block.timestamp;
        newUser.lastMiningDate = block.timestamp;

        accounts[refId].referrals.push(id);

        uint256 earnerId = getGlobalEarner(id);
        Member storage earner = accounts[earnerId];
        uint256 currentGlobalSlot = earner.globalSlot[1] + 1;
        earner.globalSlot[1] = currentGlobalSlot;
        uint256 globalEarning = globalEarnings[0];
        if (currentGlobalSlot <= 10) {
            earner.totalEarnings = earner.totalEarnings + globalEarning;
            usdc.transfer(earner.walletAddress, globalEarning);
            usdc.transfer(marketing, GLOBAL_FEE.div(10));
        }
        if (currentGlobalSlot >= 10) {
            moveToGlobalLevelTwo(earnerId);
        }

        platformToken.transfer(walletAddress, INIT_PLATFORM_TOKEN_EARNING);
        emit NewGlobalLevel(id, earnerId, 1, globalEarning);
        lastId = id;
        return id;
    }

    function addMultipleAccounts(
        uint256 refId,
        address walletAddress,
        uint256 no,
        bool activatePrivate
    ) external {
        if (activatePrivate) {
            for (uint256 i = 0; i < no; i++) {
                activateAll(refId, walletAddress);
            }
        } else {
            for (uint256 i = 0; i < no; i++) {
                addGlobalAccount(refId, walletAddress);
            }
        }
    }

    function payPendingEarnings(uint256 userId, uint256 level) private {
        Member storage user = accounts[userId];

        uint256 pendingEarning;
        if (user.privateSlot[level] > 0) {
            uint256 pendingCount = user.privateSlot[level];
            if (pendingCount > 10) {
                pendingCount = 10;
            }
            pendingEarning = pendingCount * privateEarnings[level][0];

            if (user.privateSlot[1] > 10) {
                pendingCount = user.privateSlot[level] - 10;
                pendingEarning =
                    pendingEarning +
                    pendingCount *
                    privateEarnings[level][1];
            }
        }
        if (pendingEarning > 0) {
            user.totalEarnings = user.totalEarnings + pendingEarning;
            usdc.transfer(user.walletAddress, pendingEarning);
        }
    }

    function activatePrivateAccount(uint256 id) public {
        require(running, "NOT RUNNING");
        Member storage user = accounts[id];
        require(user.globalLevel > 0, "INVALID ID");
        require(user.privateLevel == 0, "ALREADY ACTIVATED");

        usdc.transferFrom(msg.sender, address(this), PRIVATE_FEE);
        user.privateLevel = 1;

        // pay the user pending earnings
        payPendingEarnings(id, 1);

        Member storage upline = accounts[user.refId];
        uint256 currentPrivateSlot = upline.privateSlot[1];
        if (currentPrivateSlot >= 100) {
            return;
        }

        uint256 privateEarning = privateEarnings[1][1];
        if (currentPrivateSlot < 10) {
            privateEarning = privateEarnings[1][0];
            if (upline.privateLevel > 0) {
                upline.totalEarnings = upline.totalEarnings + privateEarning;
                usdc.transfer(upline.walletAddress, privateEarning);
            }

            usdc.transfer(marketing, PRIVATE_FEE.div(10));
            emit NewPrivateLevel(id, user.refId, 1, privateEarning);
            currentPrivateSlot = currentPrivateSlot + 1;
            upline.privateSlot[1] = currentPrivateSlot;
            if (currentPrivateSlot == 10) {
                moveToNextPrivateLevel(user.refId);
            }
            return;
        }

        usdc.transfer(marketing, PRIVATE_FEE.div(10));
        usdc.transfer(upline.walletAddress, privateEarning);
        emit NewPrivateLevel(id, user.refId, 1, privateEarning);
        upline.privateSlot[1] = currentPrivateSlot + 1;
    }

    function changeWallet(uint256 id, address newWallet) external {
        require(msg.sender == accounts[id].walletAddress, "NOT ALLOWED");
        accounts[id].walletAddress = newWallet;
    }

    function changeMarketingWallet(address newWallet) external onlyOwner {
        marketing = newWallet;
    }

    function endNetworkingPhase(address listingAddress) external onlyOwner {
        require(
            lastId >= 100000 ||
                block.timestamp < startDate.add(5 days) ||
                block.timestamp > startDate.add(180 days),
            "NETWORKING PHASE NOT COMPLETED"
        );
        running = false;
        usdc.transfer(listingAddress, usdc.balanceOf(address(this)));
        platformToken.transfer(
            listingAddress,
            platformToken.balanceOf(address(this))
        );
    }

    function launch() external onlyOwner {
        running = true;
    }

    bool running;
    uint256 public startDate;
    uint256 public constant GLOBAL_FEE = 5 * 10 ** 6;
    uint256 public constant PRIVATE_FEE = 5 * 10 ** 6;
    uint256 public constant INIT_PLATFORM_TOKEN_EARNING = 30 * 10 ** 18;
    uint256 public constant MINE_PLATFORM_TOKEN_EARNING = 70 * 10 ** 18;

    IERC20 public platformToken;
    IERC20 public usdc;
    address public marketing;
    uint256 public lastId;

    struct Member {
        uint256 refId;
        address walletAddress;
        uint256 globalLevel;
        uint256 privateLevel;
        uint256 totalEarnings;
        uint256 regDate;
        uint256 lastMiningDate;
        uint256[] referrals;
        mapping(uint256 => uint256) globalSlot;
        mapping(uint256 => uint256) privateSlot;
    }

    event NewGlobalLevel(
        uint256 indexed userId,
        uint256 indexed earnerId,
        uint256 level,
        uint256 amountEarned
    );

    event NewPrivateLevel(
        uint256 indexed userId,
        uint256 indexed earnerId,
        uint256 level,
        uint256 amountEarned
    );

    mapping(uint256 => Member) accounts;
    mapping(address => uint256[]) public myIds;

    uint256[] public globalEarnings;
    mapping(uint256 => uint256[]) public privateEarnings;

    function getGlobalEarner(uint256 newId) private pure returns (uint256) {
        uint256 id = (newId - newId % 10) / 10;
        if (id == 0) {
            id = 1;
        }

        return id;
    }

    function moveToGlobalLevelTwo(uint256 id) private {
        uint256 earnerId = getGlobalEarner(id);
        Member storage earner = accounts[earnerId];
        accounts[id].globalLevel = 2;

        uint256 currentGlobalSlot = earner.globalSlot[2] + 1;
        earner.globalSlot[2] = currentGlobalSlot;
        uint256 globalEarning = globalEarnings[1];
        if (currentGlobalSlot <= 10) {
            earner.totalEarnings = earner.totalEarnings + globalEarning;
            usdc.transfer(earner.walletAddress, globalEarning);
        }
        if (currentGlobalSlot >= 10) {
            moveToGlobalLevelTwo(earnerId);
        }
        emit NewGlobalLevel(id, earnerId, 2, globalEarning);
    }

    function moveToNextPrivateLevel(uint256 id) private {
        Member storage user = accounts[id];
        Member storage upline = accounts[user.refId];
        uint256 newLevel = user.privateLevel + 1;
        user.privateLevel = newLevel;

        payPendingEarnings(id, newLevel);

        uint256 uplinePrivateSlot = upline.privateSlot[newLevel];
        if (uplinePrivateSlot >= 100) {
            return;
        }

        uint256 privateEarning = privateEarnings[newLevel][1];
        if (uplinePrivateSlot < 14) {
            privateEarning = privateEarnings[newLevel][0];
            if (upline.privateLevel >= newLevel) {
                upline.totalEarnings = upline.totalEarnings + privateEarning;
                usdc.transfer(upline.walletAddress, privateEarning);
            }

            emit NewPrivateLevel(id, user.refId, newLevel + 1, privateEarning);
            uplinePrivateSlot = uplinePrivateSlot + 1;
            upline.privateSlot[newLevel] = uplinePrivateSlot;
            if (uplinePrivateSlot == 14) {
                moveToNextPrivateLevel(user.refId);
            }
            return;
        }

        usdc.transfer(upline.walletAddress, privateEarning);
        emit NewPrivateLevel(id, user.refId, newLevel, privateEarning);
        upline.privateSlot[1] = uplinePrivateSlot + 1;
    }

    function amountAvailableForMining(
        uint256 id
    ) public view returns (uint256) {
        uint256 totalMinable = MINE_PLATFORM_TOKEN_EARNING;
        Member storage user = accounts[id];
        if (user.privateLevel > 0) {
            totalMinable = totalMinable * 2;
        }

        uint256 maxMineDate = user.regDate + 90 days;
        uint256 daysLeft = maxMineDate - user.lastMiningDate;
        uint256 daysAccumulated = block.timestamp - user.lastMiningDate;

        return (daysAccumulated * totalMinable) / daysLeft;
    }

    function getUser(
        uint256 id
    )
        external
        view
        returns (
            uint256 refId,
            address walletAddress,
            uint256 globalLevel,
            uint256 privateLevel,
            uint256 regDate,
            uint256 lastMiningDate,
            uint256 totalEarnings
        )
    {
        refId = accounts[id].refId;
        walletAddress = accounts[id].walletAddress;
        globalLevel = accounts[id].globalLevel;
        privateLevel = accounts[id].privateLevel;
        regDate = accounts[id].regDate;
        lastMiningDate = accounts[id].lastMiningDate;
        totalEarnings = accounts[id].totalEarnings;
    }

    function referralCount(uint256 userId) external view returns (uint256) {
        return accounts[userId].referrals.length;
    }

    function referral(
        uint256 userId,
        uint256 index
    ) external view returns (uint256) {
        return accounts[userId].referrals[index];
    }

    function myAccountsCount(address wallet) external view returns (uint256) {
        return myIds[wallet].length;
    }

    function myFirstId() external view returns (uint256) {
        if (myIds[msg.sender].length == 0) {
            return 0;
        }

        return myIds[msg.sender][0];
    }

    function globalSlot(
        uint256 id,
        uint256 level
    ) external view returns (uint256) {
        return accounts[id].globalSlot[level];
    }

    function privateSlot(
        uint256 id,
        uint256 level
    ) external view returns (uint256) {
        return accounts[id].privateSlot[level];
    }
}