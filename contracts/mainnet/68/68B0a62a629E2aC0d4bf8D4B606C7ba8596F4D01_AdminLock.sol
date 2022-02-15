// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IGarden.sol";
import "../interfaces/IClaimLock.sol";

contract AdminLock is Ownable {
    IERC20 public _lp;
    IERC20 public _twoToken; 
    IClaimLock public _claimLock;
    IGarden public _farm;
    uint256 public constant LOCK_PERIOD = 14 weeks; //14 week
    address public constant initLpHolder=0xa86C5582404919822370EE2f2E3e247218054CC9;
    mapping(address => mapping(uint256 => uint256)) public _startTimestamp;
    mapping(address => mapping(uint256 => uint256)) public _depositList;

    constructor(IERC20 lp,IGarden farm,IERC20 two,IClaimLock claimLock) {
        _lp = lp;
        _farm = farm;
        _twoToken=two;
        _claimLock=claimLock;
    }

    receive() external payable {}

    function depositLP(uint256 amount) public {
        _lp.approve(address(_farm),amount);
        _lp.transferFrom(initLpHolder, address(this), amount);
        _farm.deposit(1, amount);
        _depositList[initLpHolder][1] += amount;
        _startTimestamp[initLpHolder][1] = block.timestamp;
    }

    function withdrawLP() public {
        require(block.timestamp >= _startTimestamp[initLpHolder][1] + LOCK_PERIOD, "STILL LOCKED.");

        uint256 amount = _depositList[initLpHolder][1];
        _farm.withdraw(1, amount);
        _lp.transfer(initLpHolder, _lp.balanceOf(address(this)));
        _twoToken.transfer(initLpHolder, _twoToken.balanceOf(address(this)));
        _depositList[initLpHolder][1] = 0;
    }

    function harvestAll() public {
        _farm.harvestAll();
    }

    function claim(uint256[] memory index) public {
        _claimLock.claimFarmReward(index);
    }

    function version() public pure returns (uint256) {
        return 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGarden {
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event HarvestAll(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How any LP tokens the user has provided.
        uint256 rewardDebt;
        uint256 depositTime;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. TWOs to distribute per block.
        uint256 lastRewardBlock; // Last block time that OXDs distribution occurs.
        uint256 accTwoPerShare; // Accumulated TWOs per share, times 1e12. See below.
    }

    struct VirtualPool {
        address farmer;
        uint256 allocPoint;
        uint256 lastRewardBlock;
    }

    function harvestAll() external;

    function withdraw(uint256 pid, uint256 amount) external;

    function deposit(uint256 pid, uint256 amount) external;

    function pendingReward(uint256 pid, address user) external view returns (uint256);

    function emergencyWithdraw(uint256 pid) external;

    function poolInfo() external view returns (PoolInfo[] memory);

    function virtualPoolInfo() external view returns (VirtualPool[] memory);

    function virtualPoolClaim(uint256 pid, address forUser) external returns (uint256);

    function pendingVirtualPoolReward(uint256 pid) external view returns (uint256);

     function daylyReward(uint256 pid) external view returns (uint256) ;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IClaimLock {
    struct LockedFarmReward {
        uint256 _locked;
        uint256 _blockNumber;
        uint256 _currentTime;
    }

    function lockFarmReward(address account, uint256 amount) external;

    function claimFarmReward(uint256[] memory index) external;

    function getFarmAccInfo(address account)
        external
        view
        returns (LockedFarmReward[] memory lockedReward, uint256[] memory claimableReward);

    function getClaimableFarmReward(address account, uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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