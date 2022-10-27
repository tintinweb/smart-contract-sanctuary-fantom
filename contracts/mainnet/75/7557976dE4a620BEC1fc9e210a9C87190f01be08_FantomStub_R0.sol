pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

import "../interfaces/IFantomStub.sol";
import "../interfaces/IOwnable.sol";
import "../interfaces/IPausable.sol";
import "../interfaces/IStakingPool.sol";
import "../interfaces/ISFC.sol";

contract FantomStub_R0 is PausableUpgradeable, ReentrancyGuardUpgradeable, ERC165Upgradeable, OwnableUpgradeable, IFantomStub {
    address payable public sfc;
    address payable public pool;
    address public operator;

    // currently active wrIds are [firstWrId, lastWrId)
    mapping(uint256 => uint256) public firstWrID; // validatorId => firstWrId
    mapping(uint256 => uint256) public lastWrID; // validatorId => lastWrId


    modifier onlyOperator() {
        require(msg.sender == owner() || msg.sender == operator, "Only Owner or Operator");
        _;
    }

    function initialize(address payable _sfc, address payable _pool, address _operator) public initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        sfc = _sfc;
        pool = _pool;
        operator = _operator;
    }

    receive() external payable {}

    function delegate(uint256 toValidatorId, uint256 amount) public onlyOperator {
        require(amount <= address(this).balance, "Stub balance is too low");
        ISFC(sfc).delegate{value: amount}(toValidatorId);
    }

    function undelegate(uint256 toValidatorID, uint256 amount) public onlyOperator {
        ISFC(sfc).undelegate(toValidatorID, lastWrID[toValidatorID], amount);
        lastWrID[toValidatorID]++;
    }

    function withdraw(uint256 toValidatorID) public onlyOperator {
        require(firstWrID[toValidatorID] < lastWrID[toValidatorID], "There are no pending withdrawal requests");
        ISFC(sfc).withdraw(toValidatorID, firstWrID[toValidatorID]);
        firstWrID[toValidatorID]++;
    }

    function lockStake(uint256 toValidatorID, uint256 lockupDuration, uint256 amount) public onlyOperator {
        ISFC(sfc).relockStake(toValidatorID, lockupDuration, amount);
    }

    function claimRewards(uint256 toValidatorID) public onlyOperator {
        ISFC(sfc).claimRewards(toValidatorID);
    }

    function restakeRewards(uint256 toValidatorID) public onlyOperator {
        ISFC(sfc).restakeRewards(toValidatorID);
    }

    function unlockStake(uint256 toValidatorID, uint256 amount) public onlyOperator returns (uint256) {
        return ISFC(sfc).unlockStake(toValidatorID, amount);
    }

    function flush() public onlyOperator {
        uint256 balance = address(this).balance;
        (bool sent, bytes memory data) = pool.call{value: balance}("");
        require(sent, "Failed to send funds back to pool");
    }

    function setWithdrawalBounds(uint256 validatorId, uint256 _firstWrID, uint256 _lastWrId) public onlyOperator {
        require(_firstWrID <= _lastWrId, "Must provide interval");
        firstWrID[validatorId] = _firstWrID;
        lastWrID[validatorId] = _lastWrId;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId)
        || interfaceId == type(IOwnable).interfaceId
        || interfaceId == type(IPausable).interfaceId
        || interfaceId == type(IFantomStub).interfaceId;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IStakingPool {
    event StakeReceived(address indexed staker, uint256 amount);

    event TokensBurned(address indexed staker, uint256 amount, uint256 shares, uint256 fee, uint256 indexed wrId);

    event ManualWithdrawalExpected(address indexed staker, uint256 amount, uint256 indexed wrId);

    event Withdrawn(address indexed staker, uint256 amount, uint256 indexed wrId);

    event FeeRuleUpdated(uint256 minFeeRatio, uint256 maxFeeRatio, uint256 feeIncreaseStart, uint256 feeIncreaseStop);

    function stake() external payable;

    function burn(uint256 amount) external;

    function sendToStub(uint256 amount, uint256 stubId) external;

    function getBurnFee(uint256 amount) external view returns (uint256);

    function withdrawLast() external;

    function withdrawManual(uint256 wrId) external;

    function updateFeeParameters(uint256 minFeeRatio, uint256 maxFeeRatio, uint256 feeIncreaseStart, uint256 feeIncreaseStop) external;

}

pragma solidity ^0.8.0;

interface ISFC {
    function delegate(uint256 toValidatorID) external payable;

    function undelegate(uint256 toValidatorID, uint256 wrID, uint256 amount) external;

    function withdraw(uint256 toValidatorID, uint256 wrID) external;

    function claimRewards(uint256 toValidatorID) external;

    function restakeRewards(uint256 toValidatorID) external;

    function relockStake(uint256 toValidatorID, uint256 lockupDuration, uint256 amount) external;

    function unlockStake(uint256 toValidatorID, uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IPausable {

    event Paused(address account);

    event Unpaused(address account);

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IOwnable {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IFantomStub {
    function delegate(uint256 toValidatorId, uint256 amount) external;

    function undelegate(uint256 toValidatorID, uint256 amount) external;

    function withdraw(uint256 toValidatorID) external;

    function lockStake(uint256 toValidatorID, uint256 lockupDuration, uint256 amount) external;

    function claimRewards(uint256 toValidatorID) external;

    function restakeRewards(uint256 toValidatorID) external;

    function unlockStake(uint256 toValidatorID, uint256 amount) external returns (uint256);

    function flush() external;

    function setWithdrawalBounds(uint256 validatorId, uint256 _firstWrID, uint256 _lastWrId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}