// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {UnsafeMath} from '../UnsafeMath.sol';

using UnsafeMath for uint256;

type U256 is uint256;

using {
    add as +,
    sub as -,
    mul as *,
    div as /,
    neq as !=,
    eq as ==,
    lt as <,
    lte as <=,
    gt as >,
    gte as >=
} for U256 global;

function add(U256 _u256, U256 _addend) pure returns (U256) {
    return U256.wrap(U256.unwrap(_u256).add(U256.unwrap(_addend)));
}

function sub(U256 _u256, U256 _subtrahend) pure returns (U256) {
    return U256.wrap(U256.unwrap(_u256).sub(U256.unwrap(_subtrahend)));
}

function mul(U256 _u256, U256 _multiplier) pure returns (U256) {
    return U256.wrap(U256.unwrap(_u256).mul(U256.unwrap(_multiplier)));
}

function div(U256 _u256, U256 _divisor) pure returns (U256) {
    return U256.wrap(U256.unwrap(_u256).div(U256.unwrap(_divisor)));
}

function neq(U256 _u256, U256 _bounds) pure returns (bool) {
    return U256.unwrap(_u256) != U256.unwrap(_bounds);
}

function eq(U256 _u256, U256 _bounds) pure returns (bool) {
    return U256.unwrap(_u256) == U256.unwrap(_bounds);
}

function lt(U256 _u256, U256 _bounds) pure returns (bool) {
    return U256.unwrap(_u256) < U256.unwrap(_bounds);
}

function lte(U256 _u256, U256 _bounds) pure returns (bool) {
    return U256.unwrap(_u256) <= U256.unwrap(_bounds);
}

function gt(U256 _u256, U256 _bounds) pure returns (bool) {
    return U256.unwrap(_u256) > U256.unwrap(_bounds);
}

function gte(U256 _u256, U256 _bounds) pure returns (bool) {
    return U256.unwrap(_u256) >= U256.unwrap(_bounds);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable func-name-mixedcase

library UnsafeMath {
    // UINT256

    function add(uint256 _uint256, uint256 _addend) internal pure returns (uint256) {
        unchecked {
            return _uint256 + _addend;
        }
    }

    function sub(uint256 _uint256, uint256 _subtrahend) internal pure returns (uint256) {
        unchecked {
            return _uint256 - _subtrahend;
        }
    }

    function mul(uint256 a, uint256 _multiplier) internal pure returns (uint256) {
        unchecked {
            return a * _multiplier;
        }
    }

    function div(uint256 _uint256, uint256 _divisor) internal pure returns (uint256) {
        unchecked {
            uint256 result;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                result := div(_uint256, _divisor)
            }
            return result;
        }
    }

    function inc(uint256 _uint256) internal pure returns (uint256) {
        unchecked {
            return ++_uint256;
        }
    }

    function dec(uint256 _uint256) internal pure returns (uint256) {
        unchecked {
            return --_uint256;
        }
    }

    // INT256

    function add(int256 _int256, int256 _addend) internal pure returns (int256) {
        unchecked {
            return _int256 + _addend;
        }
    }

    function sub(int256 _int256, int256 _subtrahend) internal pure returns (int256) {
        unchecked {
            return _int256 - _subtrahend;
        }
    }

    function mul(int256 _int256, int256 _multiplier) internal pure returns (int256) {
        unchecked {
            return _int256 * _multiplier;
        }
    }

    function div(int256 _int256, int256 _divisor) internal pure returns (int256) {
        unchecked {
            int256 result;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                result := sdiv(_int256, _divisor)
            }
            return result;
        }
    }

    function inc(int256 _int256) internal pure returns (int256) {
        unchecked {
            return ++_int256;
        }
    }

    function dec(int256 _int256) internal pure returns (int256) {
        unchecked {
            return --_int256;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {UnsafeMath} from './UnsafeMath.sol';
import {U256} from './types/U256.sol';

library UnsafeU256 {
    using UnsafeMath for uint256;

    function asU256(int256 _i256) internal pure returns (U256) {
        return U256.wrap(uint256(_i256));
    }

    function asU256(uint256 _u256) internal pure returns (U256) {
        return U256.wrap(_u256);
    }

    function asUint256(U256 _u256) internal pure returns (uint256) {
        return U256.unwrap(_u256);
    }

    function asUint128(U256 _u256) internal pure returns (uint128) {
        return uint128(U256.unwrap(_u256));
    }

    function asUint64(U256 _u256) internal pure returns (uint64) {
        return uint64(U256.unwrap(_u256));
    }

    function asUint32(U256 _u256) internal pure returns (uint32) {
        return uint32(U256.unwrap(_u256));
    }

    function asUint16(U256 _u256) internal pure returns (uint16) {
        return uint16(U256.unwrap(_u256));
    }

    function asUint8(U256 _u256) internal pure returns (uint8) {
        return uint8(U256.unwrap(_u256));
    }

    function asInt256(U256 _u256) internal pure returns (int256) {
        return int256(U256.unwrap(_u256));
    }

    function asInt128(U256 _u256) internal pure returns (int128) {
        return int128(int256(U256.unwrap(_u256)));
    }

    function asInt64(U256 _u256) internal pure returns (int64) {
        return int64(int256(U256.unwrap(_u256)));
    }

    function asInt32(U256 _u256) internal pure returns (int32) {
        return int32(int256(U256.unwrap(_u256)));
    }

    function asInt16(U256 _u256) internal pure returns (int16) {
        return int16(int256(U256.unwrap(_u256)));
    }

    function asInt8(U256 _u256) internal pure returns (int8) {
        return int8(int256(U256.unwrap(_u256)));
    }

    function inc(U256 _u256) internal pure returns (U256) {
        return U256.wrap(U256.unwrap(_u256).inc());
    }

    function dec(U256 _u256) internal pure returns (U256) {
        return U256.wrap(U256.unwrap(_u256).dec());
    }

    function add(U256 _u256, uint256 _addend) internal pure returns (U256) {
        return U256.wrap(U256.unwrap(_u256).add(_addend));
    }

    function sub(U256 _u256, uint256 _subtrahend) internal pure returns (U256) {
        return U256.wrap(U256.unwrap(_u256).sub(_subtrahend));
    }

    function mul(U256 _u256, uint256 _multiplier) internal pure returns (U256) {
        return U256.wrap(U256.unwrap(_u256).mul(_multiplier));
    }

    function div(U256 _u256, uint256 _divisor) internal pure returns (U256) {
        return U256.wrap(U256.unwrap(_u256).div(_divisor));
    }

    function neq(U256 _u256, uint256 _value) internal pure returns (bool) {
        return U256.unwrap(_u256) != _value;
    }

    function eq(U256 _u256, uint256 _value) internal pure returns (bool) {
        return U256.unwrap(_u256) == _value;
    }

    function gt(U256 _u256, uint256 _value) internal pure returns (bool) {
        return U256.unwrap(_u256) > _value;
    }

    function gte(U256 _u256, uint256 _value) internal pure returns (bool) {
        return U256.unwrap(_u256) >= _value;
    }

    function lt(U256 _u256, uint256 _value) internal pure returns (bool) {
        return U256.unwrap(_u256) < _value;
    }

    function lte(U256 _u256, uint256 _value) internal pure returns (bool) {
        return U256.unwrap(_u256) <= _value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract AdminAccess is UUPSUpgradeable, OwnableUpgradeable {
  mapping(address admin => bool isAdmin) private admins;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address[] calldata _admins) public initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
    for (uint i; i < _admins.length; ++i) {
      admins[_admins[i]] = true;
    }
  }

  function addAdmins(address[] calldata _admins) external onlyOwner {
    for (uint i = 0; i < _admins.length; ++i) {
      admins[_admins[i]] = true;
    }
  }

  function addAdmin(address _admin) external onlyOwner {
    admins[_admin] = true;
  }

  function removeAdmin(address _admin) external onlyOwner {
    admins[_admin] = false;
  }

  function isAdmin(address _admin) external view returns (bool) {
    return admins[_admin];
  }

  // solhint-disable-next-line no-empty-blocks
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Skill, Attire, CombatStyle} from "./players.sol";

enum ActionQueueStatus {
  NONE,
  APPEND,
  KEEP_LAST_IN_PROGRESS
}

// This is effectively a ratio to produce 1 of outputTokenId.
// Fixed based available actions that can be undertaken for an action
struct ActionChoice {
  Skill skill;
  uint32 minXP;
  uint32 diff;
  uint32 rate; // rate of output produced per hour (base 10) 1 decimal
  uint24 xpPerHour;
  uint16 inputTokenId1;
  uint8 num1;
  uint16 inputTokenId2;
  uint8 num2;
  uint16 inputTokenId3;
  uint8 num3;
  uint16 outputTokenId; // Always num of 1
  uint8 outputNum; // Not used yet
  uint8 successPercent; // 0-100
}

// The user chooses these
struct QueuedActionInput {
  // Keep this first
  Attire attire;
  uint16 actionId;
  uint16 regenerateId; // Food (combat), maybe something for non-combat later
  uint16 choiceId; // Melee/Arrow/Magic (combat), logs, ore (non-combat)
  uint16 choiceId1; // Reserved (TBD)
  uint16 choiceId2; // Reserved (TBD)
  uint16 rightHandEquipmentTokenId; // Axe/Sword/bow, can be empty
  uint16 leftHandEquipmentTokenId; // Shield, can be empty
  uint24 timespan; // How long to queue the action for
  CombatStyle combatStyle; // specific style of combat,  can also be used
  Skill skill; // Skill from the action, so will be Skill.COMBAT for combat actions for instance
  //  bool reusePrev; // If true, then the previous queued action attire is reused?
  // 8 bytes left
}

struct QueuedAction {
  // Keep this first
  Attire attire;
  uint16 actionId;
  uint16 regenerateId; // Food (combat), maybe something for non-combat later
  uint16 choiceId; // Melee/Arrow/Magic (combat), logs, ore (non-combat)
  uint16 choiceId1; // Reserved (TBD)
  uint16 choiceId2; // Reserved (TBD)
  uint16 rightHandEquipmentTokenId; // Axe/Sword/bow, can be empty
  uint16 leftHandEquipmentTokenId; // Shield, can be empty
  uint24 timespan; // How long to queue the action for
  CombatStyle combatStyle; // specific style of combat,  can also be used
  uint40 startTime; // Filled in by the function
  bool isValid; // If we still have the item, TODO: Not used yet
  Skill skill; // Skill from the action, so will be Skill.COMBAT for combat actions for instance
  //  bool reusePrev; // If true, then the previous queued action attire is reused?
  // 8 bytes left
}

struct ActionInfo {
  Skill skill;
  bool isAvailable;
  bool isDynamic;
  bool actionChoiceRequired; // If true, then the user must choose an action choice
  uint24 xpPerHour;
  uint32 minXP;
  uint16 numSpawned; // Mostly for combat, capped respawn rate for xp/drops
  uint16 handItemTokenIdRangeMin; // Inclusive
  uint16 handItemTokenIdRangeMax; // Inclusive
  uint8 successPercent; // 0-100
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

uint16 constant NONE = 0;
// 1 - 255 (head)
uint16 constant HEAD_BASE = 1;
uint16 constant BRONZE_HELMET = HEAD_BASE;
uint16 constant IRON_HELMET = HEAD_BASE + 1;
uint16 constant MITHRIL_HELMET = HEAD_BASE + 2;
uint16 constant ADAMANTINE_HELMET = HEAD_BASE + 3;
uint16 constant RUNITE_HELMET = HEAD_BASE + 4;
uint16 constant TITANIUM_HELMET = HEAD_BASE + 5;
uint16 constant ORICHALCUM_HELMET = HEAD_BASE + 6;
uint16 constant NATUOW_HOOD = HEAD_BASE + 7;
uint16 constant BAT_WING_HAT = HEAD_BASE + 8;
uint16 constant NATURE_MASK = HEAD_BASE + 9;
uint16 constant APPRENTICE_HAT = HEAD_BASE + 10;
uint16 constant MAGE_HOOD = HEAD_BASE + 11;
uint16 constant SORCERER_HAT = HEAD_BASE + 12;
uint16 constant SEERS_HOOD = HEAD_BASE + 13;
uint16 constant SHAMAN_HOOD = HEAD_BASE + 14;
uint16 constant MASTER_HAT = HEAD_BASE + 15;
uint16 constant HEAD_MAX = HEAD_BASE + 254; // Inclusive
// 257 - 511 (neck)
uint16 constant NECK_BASE = 257;
uint16 constant SAPPHIRE_AMULET = NECK_BASE;
uint16 constant EMERALD_AMULET = NECK_BASE + 1;
uint16 constant RUBY_AMULET = NECK_BASE + 2;
uint16 constant AMETHYST_AMULET = NECK_BASE + 3;
uint16 constant DIAMOND_AMULET = NECK_BASE + 4;
uint16 constant DRAGONSTONE_AMULET = NECK_BASE + 5;
uint16 constant NECK_MAX = NECK_BASE + 254;

// 513 - 767 (body)
uint16 constant BODY_BASE = 513;
uint16 constant BRONZE_ARMOR = BODY_BASE;
uint16 constant IRON_ARMOR = BODY_BASE + 1;
uint16 constant MITHRIL_ARMOR = BODY_BASE + 2;
uint16 constant ADAMANTINE_ARMOR = BODY_BASE + 3;
uint16 constant RUNITE_ARMOR = BODY_BASE + 4;
uint16 constant TITANIUM_ARMOR = BODY_BASE + 5;
uint16 constant ORICHALCUM_ARMOR = BODY_BASE + 6;
uint16 constant NATUOW_BODY = BODY_BASE + 7;
uint16 constant BAT_WING_BODY = BODY_BASE + 8;
uint16 constant NATURE_BODY = BODY_BASE + 9;
uint16 constant APPRENTICE_BODY = BODY_BASE + 10;
uint16 constant MAGE_BODY = BODY_BASE + 11;
uint16 constant SORCERER_BODY = BODY_BASE + 12;
uint16 constant SEERS_BODY = BODY_BASE + 13;
uint16 constant SHAMAN_BODY = BODY_BASE + 14;
uint16 constant MASTER_BODY = BODY_BASE + 15;
uint16 constant BODY_MAX = BODY_BASE + 254;
// 769 - 1023 (arms)
uint16 constant ARMS_BASE = 769;
uint16 constant BRONZE_GAUNTLETS = ARMS_BASE;
uint16 constant IRON_GAUNTLETS = ARMS_BASE + 1;
uint16 constant MITHRIL_GAUNTLETS = ARMS_BASE + 2;
uint16 constant ADAMANTINE_GAUNTLETS = ARMS_BASE + 3;
uint16 constant RUNITE_GAUNTLETS = ARMS_BASE + 4;
uint16 constant TITANIUM_GAUNTLETS = ARMS_BASE + 5;
uint16 constant ORICHALCUM_GAUNTLETS = ARMS_BASE + 6;
uint16 constant NATUOW_BRACERS = ARMS_BASE + 7;
uint16 constant BAT_WING_BRACERS = ARMS_BASE + 8;
uint16 constant NATURE_BRACERS = ARMS_BASE + 9;
uint16 constant APPRENTICE_GAUNTLETS = ARMS_BASE + 10;
uint16 constant MAGE_BRACERS = ARMS_BASE + 11;
uint16 constant SORCERER_GAUNTLETS = ARMS_BASE + 12;
uint16 constant SEERS_BRACERS = ARMS_BASE + 13;
uint16 constant SHAMAN_GAUNTLETS = ARMS_BASE + 14;
uint16 constant MASTER_BRACERS = ARMS_BASE + 15;
uint16 constant ARMS_MAX = ARMS_BASE + 254;
// 1025 - 1279 (legs)
uint16 constant LEGS_BASE = 1025;
uint16 constant BRONZE_TASSETS = LEGS_BASE;
uint16 constant IRON_TASSETS = LEGS_BASE + 1;
uint16 constant MITHRIL_TASSETS = LEGS_BASE + 2;
uint16 constant ADAMANTINE_TASSETS = LEGS_BASE + 3;
uint16 constant RUNITE_TASSETS = LEGS_BASE + 4;
uint16 constant TITANIUM_TASSETS = LEGS_BASE + 5;
uint16 constant ORICHALCUM_TASSETS = LEGS_BASE + 6;
uint16 constant NATUOW_TASSETS = LEGS_BASE + 7;
uint16 constant BAT_WING_TROUSERS = LEGS_BASE + 8;
uint16 constant NATURE_TROUSERS = LEGS_BASE + 9;
uint16 constant APPRENTICE_TROUSERS = LEGS_BASE + 10;
uint16 constant MAGE_TROUSERS = LEGS_BASE + 11;
uint16 constant SORCERER_TROUSERS = LEGS_BASE + 12;
uint16 constant SEERS_TROUSERS = LEGS_BASE + 13;
uint16 constant SHAMAN_TROUSERS = LEGS_BASE + 14;
uint16 constant MASTER_TROUSERS = LEGS_BASE + 15;
uint16 constant LEGS_MAX = LEGS_BASE + 254;

// 1281 - 1535 (feet)
uint16 constant FEET_BASE = 1281;
uint16 constant BRONZE_BOOTS = FEET_BASE;
uint16 constant IRON_BOOTS = FEET_BASE + 1;
uint16 constant MITHRIL_BOOTS = FEET_BASE + 2;
uint16 constant ADAMANTINE_BOOTS = FEET_BASE + 3;
uint16 constant RUNITE_BOOTS = FEET_BASE + 4;
uint16 constant TITANIUM_BOOTS = FEET_BASE + 5;
uint16 constant ORICHALCUM_BOOTS = FEET_BASE + 6;
uint16 constant NATUOW_BOOTS = FEET_BASE + 7;
uint16 constant BAT_WING_BOOTS = FEET_BASE + 8;
uint16 constant NATURE_BOOTS = FEET_BASE + 9;
uint16 constant APPRENTICE_BOOTS = FEET_BASE + 10;
uint16 constant MAGE_BOOTS = FEET_BASE + 11;
uint16 constant SORCERER_BOOTS = FEET_BASE + 12;
uint16 constant SEERS_BOOTS = FEET_BASE + 13;
uint16 constant SHAMAN_BOOTS = FEET_BASE + 14;
uint16 constant MASTER_BOOTS = FEET_BASE + 15;
uint16 constant BOOTS_MAX = FEET_BASE + 254;

// 1536 - 1791 spare(1)
// 1792 - 2047 spare(2)

// Combat (right arm) (2048 - 2303)
uint16 constant COMBAT_BASE = 2048;
// Melee
uint16 constant SWORD_BASE = COMBAT_BASE;
uint16 constant BRONZE_SWORD = SWORD_BASE;
uint16 constant IRON_SWORD = COMBAT_BASE + 1;
uint16 constant MITHRIL_SWORD = COMBAT_BASE + 2;
uint16 constant ADAMANTINE_SWORD = COMBAT_BASE + 3;
uint16 constant RUNITE_SWORD = COMBAT_BASE + 4;
uint16 constant TITANIUM_SWORD = COMBAT_BASE + 5;
uint16 constant ORICHALCUM_SWORD = COMBAT_BASE + 6;
uint16 constant SWORD_MAX = SWORD_BASE + 49;
// Magic
uint16 constant STAFF_BASE = COMBAT_BASE + 50;
uint16 constant TOTEM_STAFF = STAFF_BASE;
uint16 constant SAPPHIRE_STAFF = STAFF_BASE + 1;
uint16 constant EMERALD_STAFF = STAFF_BASE + 2;
uint16 constant RUBY_STAFF = STAFF_BASE + 3;
uint16 constant AMETHYST_STAFF = STAFF_BASE + 4;
uint16 constant DIAMOND_STAFF = STAFF_BASE + 5;
uint16 constant DRAGONSTONE_STAFF = STAFF_BASE + 6;
uint16 constant STAFF_MAX = STAFF_BASE + 49;
// Ranged
uint16 constant BOW_BASE = COMBAT_BASE + 100;
uint16 constant BOW_MAX = BOW_BASE + 49;
// Shields (left arm)
uint16 constant SHIELD_BASE = COMBAT_BASE + 150;
uint16 constant BRONZE_SHIELD = SHIELD_BASE;
uint16 constant IRON_SHIELD = SHIELD_BASE + 1;
uint16 constant MITHRIL_SHIELD = SHIELD_BASE + 2;
uint16 constant ADAMANTINE_SHIELD = SHIELD_BASE + 3;
uint16 constant RUNITE_SHIELD = SHIELD_BASE + 4;
uint16 constant TITANIUM_SHIELD = SHIELD_BASE + 5;
uint16 constant ORICHALCUM_SHIELD = SHIELD_BASE + 6;
uint16 constant SHIELD_MAX = SHIELD_BASE + 49;

uint16 constant COMBAT_MAX = COMBAT_BASE + 255;

// Mining (2560 - 2815)
uint16 constant MINING_BASE = 2560;
uint16 constant BRONZE_PICKAXE = MINING_BASE;
uint16 constant IRON_PICKAXE = MINING_BASE + 1;
uint16 constant MITHRIL_PICKAXE = MINING_BASE + 2;
uint16 constant ADAMANTINE_PICKAXE = MINING_BASE + 3;
uint16 constant RUNITE_PICKAXE = MINING_BASE + 4;
uint16 constant TITANIUM_PICKAXE = MINING_BASE + 5;
uint16 constant ORICHALCUM_PICKAXE = MINING_BASE + 6;
uint16 constant MINING_MAX = MINING_BASE + 255;

// Woodcutting (2816 - 3071)
uint16 constant WOODCUTTING_BASE = 2816;
uint16 constant BRONZE_AXE = WOODCUTTING_BASE;
uint16 constant IRON_AXE = WOODCUTTING_BASE + 1;
uint16 constant MITHRIL_AXE = WOODCUTTING_BASE + 2;
uint16 constant ADAMANTINE_AXE = WOODCUTTING_BASE + 3;
uint16 constant RUNITE_AXE = WOODCUTTING_BASE + 4;
uint16 constant TITANIUM_AXE = WOODCUTTING_BASE + 5;
uint16 constant ORICHALCUM_AXE = WOODCUTTING_BASE + 6;
uint16 constant WOODCUTTING_MAX = WOODCUTTING_BASE + 255;

// Fishing (3072 - 3327)
uint16 constant FISHING_BASE = 3072;
uint16 constant NET_STICK = FISHING_BASE;
uint16 constant MEDIUM_NET = FISHING_BASE + 1;
uint16 constant WOOD_FISHING_ROD = FISHING_BASE + 2;
uint16 constant TITANIUM_FISHING_ROD = FISHING_BASE + 3;
uint16 constant HARPOON = FISHING_BASE + 4;
uint16 constant LARGE_NET = FISHING_BASE + 5;
uint16 constant MAGIC_NET = FISHING_BASE + 6;
uint16 constant CAGE = FISHING_BASE + 7;
uint16 constant FISHING_MAX = FISHING_BASE + 255;

// Firemaking (3328 - 3583)
uint16 constant FIRE_BASE = 3328;
uint16 constant MAGIC_FIRE_STARTER = FIRE_BASE;
uint16 constant FIRE_MAX = FIRE_BASE + 255;

// Smithing (none needed)
// Crafting (none needed)
// Cooking (none needed)

// 10000+ it'a all other items

// Bars
uint16 constant BAR_BASE = 10240; // (256 * 40)
uint16 constant BRONZE_BAR = BAR_BASE;
uint16 constant IRON_BAR = BAR_BASE + 1;
uint16 constant MITHRIL_BAR = BAR_BASE + 2;
uint16 constant ADAMANTINE_BAR = BAR_BASE + 3;
uint16 constant RUNITE_BAR = BAR_BASE + 4;
uint16 constant TITANIUM_BAR = BAR_BASE + 5;
uint16 constant ORICHALCUM_BAR = BAR_BASE + 6;
uint16 constant BAR_MAX = BAR_BASE + 255;

// Logs
uint16 constant LOG_BASE = 10496;
uint16 constant LOG = LOG_BASE;
uint16 constant OAK_LOG = LOG_BASE + 1;
uint16 constant WILLOW_LOG = LOG_BASE + 2;
uint16 constant MAPLE_LOG = LOG_BASE + 3;
uint16 constant REDWOOD_LOG = LOG_BASE + 4;
uint16 constant MAGICAL_LOG = LOG_BASE + 5;
uint16 constant ASH_LOG = LOG_BASE + 6;
uint16 constant ENCHANTED_LOG = LOG_BASE + 7;
uint16 constant LIVING_LOG = LOG_BASE + 8;
uint16 constant LOG_MAX = LOG_BASE + 255;

// Fish
uint16 constant RAW_FISH_BASE = 10752;
uint16 constant RAW_MINNUS = RAW_FISH_BASE;
uint16 constant RAW_BLEKK = RAW_FISH_BASE + 1;
uint16 constant RAW_SKRIMP = RAW_FISH_BASE + 2;
uint16 constant RAW_FEOLA = RAW_FISH_BASE + 3;
uint16 constant RAW_ANCHO = RAW_FISH_BASE + 4;
uint16 constant RAW_TROUT = RAW_FISH_BASE + 5;
uint16 constant RAW_ROJJA = RAW_FISH_BASE + 6;
uint16 constant RAW_BOWFISH = RAW_FISH_BASE + 7;
uint16 constant RAW_GOLDFISH = RAW_FISH_BASE + 8;
uint16 constant RAW_MYSTY_BLUE = RAW_FISH_BASE + 9;
uint16 constant RAW_FLITFISH = RAW_FISH_BASE + 10;
uint16 constant RAW_RAZORFISH = RAW_FISH_BASE + 11;
uint16 constant RAW_QUAFFER = RAW_FISH_BASE + 12;
uint16 constant RAW_ROXA = RAW_FISH_BASE + 13;
uint16 constant RAW_AZACUDDA = RAW_FISH_BASE + 14;
uint16 constant RAW_STONECLAW = RAW_FISH_BASE + 15;
uint16 constant RAW_CRUSKAN = RAW_FISH_BASE + 16;
uint16 constant RAW_CHODFISH = RAW_FISH_BASE + 17;
uint16 constant RAW_DOUBTFISH = RAW_FISH_BASE + 18;
uint16 constant RAW_ROSEFIN = RAW_FISH_BASE + 19;
uint16 constant RAW_SPHINX_FISH = RAW_FISH_BASE + 20;
uint16 constant RAW_SHAW = RAW_FISH_BASE + 21;
uint16 constant RAW_VANISHING_PERCH = RAW_FISH_BASE + 22;
uint16 constant RAW_VIPER_BASS = RAW_FISH_BASE + 23;
uint16 constant RAW_WATER_SERPENT = RAW_FISH_BASE + 24;
uint16 constant RAW_WHISKFIN = RAW_FISH_BASE + 25;
uint16 constant RAW_MHARA = RAW_FISH_BASE + 26;
uint16 constant RAW_GRAN_SQUIN = RAW_FISH_BASE + 27;
uint16 constant RAW_LANCER = RAW_FISH_BASE + 28;
uint16 constant RAW_OCTACLE = RAW_FISH_BASE + 29;
uint16 constant RAW_DRAGONFISH = RAW_FISH_BASE + 30;
uint16 constant RAW_YERESPATUM = RAW_FISH_BASE + 31;
uint16 constant RAW_FISH_MAX = RAW_FISH_BASE + 255;

// Cooked fish
uint16 constant COOKED_FISH_BASE = 11008;
uint16 constant COOKED_MINNUS = COOKED_FISH_BASE;
uint16 constant COOKED_BLEKK = COOKED_FISH_BASE + 1;
uint16 constant COOKED_SKRIMP = COOKED_FISH_BASE + 2;
uint16 constant COOKED_FEOLA = COOKED_FISH_BASE + 3;
uint16 constant COOKED_ANCHO = COOKED_FISH_BASE + 4;
uint16 constant COOKED_TROUT = COOKED_FISH_BASE + 5;
uint16 constant COOKED_ROJJA = COOKED_FISH_BASE + 6;
uint16 constant COOKED_BOWFISH = COOKED_FISH_BASE + 7;
uint16 constant COOKED_GOLDFISH = COOKED_FISH_BASE + 8;
uint16 constant COOKED_MYSTY_BLUE = COOKED_FISH_BASE + 9;
uint16 constant COOKED_FLITFISH = COOKED_FISH_BASE + 10;
uint16 constant COOKED_RAZORFISH = COOKED_FISH_BASE + 11;
uint16 constant COOKED_QUAFFER = COOKED_FISH_BASE + 12;
uint16 constant COOKED_ROXA = COOKED_FISH_BASE + 13;
uint16 constant COOKED_AZACUDDA = COOKED_FISH_BASE + 14;
uint16 constant COOKED_STONECLAW = COOKED_FISH_BASE + 15;
uint16 constant COOKED_CRUSKAN = COOKED_FISH_BASE + 16;
uint16 constant COOKED_CHODFISH = COOKED_FISH_BASE + 17;
uint16 constant COOKED_DOUBTFISH = COOKED_FISH_BASE + 18;
uint16 constant COOKED_ROSEFIN = COOKED_FISH_BASE + 19;
uint16 constant COOKED_SPHINX_FISH = COOKED_FISH_BASE + 20;
uint16 constant COOKED_SHAW = COOKED_FISH_BASE + 21;
uint16 constant COOKED_VANISHING_PERCH = COOKED_FISH_BASE + 22;
uint16 constant COOKED_VIPER_BASS = COOKED_FISH_BASE + 23;
uint16 constant COOKED_WATER_SERPENT = COOKED_FISH_BASE + 24;
uint16 constant COOKED_WHISKFIN = COOKED_FISH_BASE + 25;
uint16 constant COOKED_MHARA = COOKED_FISH_BASE + 26;
uint16 constant COOKED_GRAN_SQUIN = COOKED_FISH_BASE + 27;
uint16 constant COOKED_LANCER = COOKED_FISH_BASE + 28;
uint16 constant COOKED_OCTACLE = COOKED_FISH_BASE + 29;
uint16 constant COOKED_DRAGONFISH = COOKED_FISH_BASE + 30;
uint16 constant COOKED_YERESPATUM = COOKED_FISH_BASE + 31;
uint16 constant COOKED_FISH_MAX = COOKED_FISH_BASE + 255;

// Farming
uint16 constant FARMING_BASE = 11264;
uint16 constant BONEMEAL = FARMING_BASE;
uint16 constant FARMING_MAX = FARMING_BASE + 255;

// Mining
uint16 constant ORE_BASE = 11520;
uint16 constant COPPER_ORE = ORE_BASE;
uint16 constant TIN_ORE = ORE_BASE + 1;
uint16 constant IRON_ORE = ORE_BASE + 2;
uint16 constant SAPPHIRE = ORE_BASE + 3;
uint16 constant COAL_ORE = ORE_BASE + 4;
uint16 constant EMERALD = ORE_BASE + 5;
uint16 constant MITHRIL_ORE = ORE_BASE + 6;
uint16 constant RUBY = ORE_BASE + 7;
uint16 constant ADAMANTINE_ORE = ORE_BASE + 8;
uint16 constant AMETHYST = ORE_BASE + 9;
uint16 constant DIAMOND = ORE_BASE + 10;
uint16 constant RUNITE_ORE = ORE_BASE + 11;
uint16 constant DRAGONSTONE = ORE_BASE + 12;
uint16 constant TITANIUM_ORE = ORE_BASE + 13;
uint16 constant ORICHALCUM_ORE = ORE_BASE + 14;
uint16 constant ORE_MAX = ORE_BASE + 255;

// Arrows
uint16 constant ARROW_BASE = 11776;
uint16 constant BRONZE_ARROW = ARROW_BASE;
uint16 constant ARROW_MAX = ARROW_BASE + 255;

// Scrolls
uint16 constant SCROLL_BASE = 12032;
uint16 constant SHADOW_SCROLL = SCROLL_BASE;
uint16 constant NATURE_SCROLL = SCROLL_BASE + 1;
uint16 constant AQUA_SCROLL = SCROLL_BASE + 2;
uint16 constant HELL_SCROLL = SCROLL_BASE + 3;
uint16 constant AIR_SCROLL = SCROLL_BASE + 4;
uint16 constant BARRAGE_SCROLL = SCROLL_BASE + 5;
uint16 constant FREEZE_SCROLL = SCROLL_BASE + 6;
uint16 constant ANCIENT_SCROLL = SCROLL_BASE + 7;
uint16 constant SCROLL_MAX = SCROLL_BASE + 255;

// Free interval
uint16 constant NOT_USED_BASE = 12544;
uint16 constant NOT_USED_MAX = 12799;

// Boosts
uint16 constant BOOST_BASE = 12800;
uint16 constant COMBAT_BOOST = BOOST_BASE;
uint16 constant XP_BOOST = BOOST_BASE + 1;
uint16 constant GATHERING_BOOST = BOOST_BASE + 2;
uint16 constant SKILL_BOOST = BOOST_BASE + 3;
uint16 constant ABSENCE_BOOST = BOOST_BASE + 4;
uint16 constant PRAY_TO_THE_BEARDIE = BOOST_BASE + 5;
uint16 constant GO_OUTSIDE = BOOST_BASE + 6;
uint16 constant RAINING_RARES = BOOST_BASE + 7;
uint16 constant BOOST_MAX = 13055;

// MISC
uint16 constant MISC_BASE = 65535;
uint16 constant MYSTERY_BOX = MISC_BASE;
uint16 constant RAID_PASS = MISC_BASE - 1;
uint16 constant NATUOW_HIDE = MISC_BASE - 2;
uint16 constant NATUOW_LEATHER = MISC_BASE - 3;
uint16 constant SMALL_BONE = MISC_BASE - 4;
uint16 constant MEDIUM_BONE = MISC_BASE - 5;
uint16 constant LARGE_BONE = MISC_BASE - 6;
uint16 constant DRAGON_BONE = MISC_BASE - 7;
uint16 constant DRAGON_TEETH = MISC_BASE - 8;
uint16 constant DRAGON_SCALE = MISC_BASE - 9;
uint16 constant POISON = MISC_BASE - 10;
uint16 constant STRING = MISC_BASE - 11;
uint16 constant ROPE = MISC_BASE - 12;
uint16 constant LEAF_FRAGMENTS = MISC_BASE - 13;
uint16 constant VENOM_POUCH = MISC_BASE - 14;
uint16 constant BAT_WING = MISC_BASE - 15;
uint16 constant BAT_WING_PATCH = MISC_BASE - 16;
uint16 constant THREAD_NEEDLE = MISC_BASE - 17;
uint16 constant LOSSUTH_TEETH = MISC_BASE - 18;
uint16 constant LOSSUTH_SCALE = MISC_BASE - 19;
uint16 constant FEATHER = MISC_BASE - 20;
uint16 constant QUARTZ_INFUSED_FEATHER = MISC_BASE - 21;
uint16 constant BARK_CHUNK = MISC_BASE - 22;
uint16 constant APPRENTICE_FABRIC = MISC_BASE - 23;
uint16 constant MAGE_FABRIC = MISC_BASE - 24;
uint16 constant SORCERER_FABRIC = MISC_BASE - 25;
uint16 constant SEERS_FABRIC = MISC_BASE - 26;
uint16 constant SHAMAN_FABRIC = MISC_BASE - 27;
uint16 constant MASTER_FABRIC = MISC_BASE - 28;
uint16 constant DRAGON_KEY = MISC_BASE - 29;
uint16 constant BONE_KEY = MISC_BASE - 30;
uint16 constant NATURE_KEY = MISC_BASE - 31;
uint16 constant AQUA_KEY = MISC_BASE - 32;
uint16 constant BLUECANAR = MISC_BASE - 33;
uint16 constant ANURGAT = MISC_BASE - 34;
uint16 constant RUFARUM = MISC_BASE - 35;
uint16 constant WHITE_DEATH_SPORE = MISC_BASE - 36;
uint16 constant ENCHANTED_ACORN = MISC_BASE - 37;
uint16 constant ACORN_PATCH = MISC_BASE - 38;
uint16 constant MISC_MIN = 32768;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {QueuedAction} from "./actions.sol";

// 4 bytes for each level. 0x00000000 is the first level, 0x00000054 is the second, etc.
bytes constant XP_BYTES = hex"0000000000000054000000AE0000010E00000176000001E60000025E000002DE00000368000003FD0000049B00000546000005FC000006C000000792000008730000096400000A6600000B7B00000CA400000DE100000F36000010A200001229000013CB0000158B0000176B0000196E00001B9400001DE20000205A000022FF000025D5000028DD00002C1E00002F99000033540000375200003B9A000040300000451900004A5C00004FFF0000560900005C810000637000006ADD000072D100007B570000847900008E42000098BE0000A3F90000B0020000BCE70000CAB80000D9860000E9630000FA6200010C990001201D0001350600014B6F0001637300017D2E000198C10001B64E0001D5F80001F7E600021C430002433B00026CFD000299BE0002C9B30002FD180003342B00036F320003AE730003F23D00043AE3000488BE0004DC2F0005359B000595700005FC2400066A360006E02D00075E990007E6160008774C000912EB0009B9B4000A6C74000B2C06000BF956000CD561000DC134000EBDF3000FCCD40010EF24";

enum EquipPosition {
  NONE,
  HEAD,
  NECK,
  BODY,
  ARMS,
  LEGS,
  FEET,
  SPARE1,
  SPARE2,
  LEFT_HAND,
  RIGHT_HAND,
  BOTH_HANDS,
  ARROW_SATCHEL,
  MAGIC_BAG,
  FOOD,
  AUX, // wood, seeds  etc..
  BOOST_VIAL
}

// Equipment (leave at the bottom to allow for further ones)
struct Attire {
  uint16 head; // tokenId for the head (1 - 255)
  uint16 neck; // tokenId for the neck (256 - 511) (256 * i -> 256 * (i + 1))
  uint16 body;
  uint16 arms;
  uint16 legs;
  uint16 feet;
  uint16 ring;
  uint16 reserved1;
  uint128 queueId; // Just here for packing purposes
}

struct CombatStats {
  // From skill points
  int16 melee;
  int16 magic;
  int16 range;
  int16 health;
  // These include equipment
  int16 meleeDefence;
  int16 magicDefence;
  int16 rangeDefence;
}

struct Player {
  // Combat levels, (Cached from skill points so this doesn't need to be calculated every combat)
  int16 melee;
  int16 magic;
  int16 range;
  int16 defence;
  int16 health;
  uint8 version; // This is used in case we want to do some migration of old characters, like halt them at level 30 from gaining XP
  uint160 totalXP;
  // TODO: Can be up to 7
  QueuedAction[] actionQueue;
}

enum BoostType {
  NONE,
  ANY_XP,
  COMBAT_XP,
  NON_COMBAT_XP,
  GATHERING,
  ABSENCE
}

enum CombatStyle {
  NONE,
  ATTACK,
  DEFENCE
}

struct Equipment {
  uint16 itemTokenId;
  uint24 amount;
}

// For optimization purposes this contains a few data items, and everything except combat stats (although it could fit?)
struct Item {
  EquipPosition equipPosition;
  bool exists;
  // Can it be transferred?
  bool isTransferable;
  // Food
  uint16 healthRestored;
  // Boost vial
  BoostType boostType;
  uint16 boostValue; // Varies, could be the % increase
  uint24 boostDuration; // How long the effect of the boost last
  // Combat stats
  int16 melee;
  int16 magic;
  int16 range;
  int16 meleeDefence;
  int16 magicDefence;
  int16 rangeDefence;
  int16 health;
  // Minimum requirements in this skill to use this item (can be NONE)
  Skill skill;
  uint32 minXP;
  // Noncombat skill
  Skill skill1;
  int16 skillDiff1;
}

struct PlayerBoostInfo {
  uint40 startTime;
  uint24 duration;
  uint16 val;
  uint16 itemTokenId; // Get the effect of it
  BoostType boostType;
}

enum Skill {
  NONE,
  COMBAT, // This is a helper which incorporates all combat skills, attack <-> magic, defence, health etc
  MELEE,
  RANGE,
  MAGIC,
  DEFENCE,
  HEALTH,
  MINING,
  WOODCUTTING,
  FISHING,
  SMITHING,
  THIEVING,
  CRAFTING,
  COOKING,
  FIREMAKING
}

struct AvatarInfo {
  bytes32 name;
  string description;
  string imageURI;
  Skill[2] startSkills; // Can be NONE
}

struct PendingFlags {
  bool includeLoot; // Guaranteed loot from actions, and random loot if claiming quite late
  bool includePastRandomRewards; // This is random loot from previous actions
  bool includeXPRewards; // Passing any xp thresholds gives you extra rewards
}

// This is only for viewing so doesn't need to be optimized
struct PendingOutput {
  Equipment[] consumed;
  Equipment[] produced;
  Equipment[] producedPastRandomRewards;
  Equipment[] producedXPRewards;
  uint32 xpGained;
  bool died;
}

// External view functions that are in other implementation files
interface IPlayersDelegateView {
  function pendingRewardsImpl(
    address _owner,
    uint _playerId,
    PendingFlags memory _flags
  ) external view returns (PendingOutput memory pendingOutput);

  function dailyClaimedRewardsImpl(uint _playerId) external view returns (bool[7] memory claimed);

  function getRandomBytesImpl(
    uint _numTickets,
    uint _skillEndTime,
    uint _playerId
  ) external view returns (bytes memory b);
}

struct FullAttireBonusInput {
  Skill skill;
  uint8 bonusPercent; // 3 = 3%
  uint16[5] itemTokenIds; // 0 = head, 1 = body, 2 arms, 3 body, 4 = feet
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Equipment} from "./players.sol";

// Loot
struct GuaranteedReward {
  uint16 itemTokenId;
  uint16 rate; // num per hour, base 10 (1 decimals) or percentage chance (out of 65535)
}

struct RandomReward {
  uint16 itemTokenId;
  uint16 chance; // out of 65535
  uint8 amount; // out of 255
}

struct PendingRandomReward {
  uint16 actionId;
  uint16 choiceId;
  uint40 timestamp;
  uint24 elapsedTime;
  uint128 queueId;
}

struct ActionRewards {
  uint16 guaranteedRewardTokenId1;
  uint16 guaranteedRewardRate1; // Num per hour, base 10 (1 decimal). Max 6533.5 per hour
  uint16 guaranteedRewardTokenId2;
  uint16 guaranteedRewardRate2;
  uint16 guaranteedRewardTokenId3;
  uint16 guaranteedRewardRate3;
  // Random chance rewards
  uint16 randomRewardTokenId1;
  uint16 randomRewardChance1; // out of 65335
  uint8 randomRewardAmount1; // out of 255
  uint16 randomRewardTokenId2;
  uint16 randomRewardChance2;
  uint8 randomRewardAmount2;
  uint16 randomRewardTokenId3;
  uint16 randomRewardChance3;
  uint8 randomRewardAmount3;
  uint16 randomRewardTokenId4;
  uint16 randomRewardChance4;
  uint8 randomRewardAmount4;
  // No more room!
}

struct XPThresholdReward {
  uint32 xpThreshold;
  Equipment[] rewards;
}

uint constant MAX_GUARANTEED_REWARDS_PER_ACTION = 3;
uint constant MAX_RANDOM_REWARDS_PER_ACTION = 4;
uint constant MAX_REWARDS_PER_ACTION = MAX_GUARANTEED_REWARDS_PER_ACTION + MAX_RANDOM_REWARDS_PER_ACTION;
uint constant MAX_CONSUMED_PER_ACTION = 3;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBrushToken is IERC20 {
  function burn(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Skill} from "../globals/players.sol";

interface IPlayers {
  function clearEverythingBeforeTokenTransfer(address from, uint tokenId) external;

  function getURI(
    uint playerId,
    bytes32 name,
    bytes32 avatarName,
    string calldata avatarDescription,
    string calldata imageURI
  ) external view returns (string memory);

  function mintBatch(address to, uint[] calldata ids, uint256[] calldata amounts) external;

  function itemBeforeTokenTransfer(address from, uint[] calldata tokenIds, uint256[] calldata amounts) external;

  function mintedPlayer(address from, uint playerId, Skill[2] calldata startSkills, bool makeActive) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {IERC2981, IERC165} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

import {UnsafeMath, UnsafeU256, U256} from "@0xdoublesharp/unsafe-math/contracts/UnsafeU256.sol";
import {IBrushToken} from "./interfaces/IBrushToken.sol";
import {IPlayers} from "./interfaces/IPlayers.sol";
import {World} from "./World.sol";
import {AdminAccess} from "./AdminAccess.sol";

/* solhint-disable no-global-import */
import "./globals/players.sol";
import "./globals/items.sol";

/* solhint-enable no-global-import */

// The NFT contract contains data related to the items and who owns them
contract ItemNFT is ERC1155Upgradeable, UUPSUpgradeable, OwnableUpgradeable, IERC2981, Multicall {
  using UnsafeMath for uint256;
  using UnsafeU256 for U256;

  event AddItem(Item item, uint16 tokenId);
  event AddItems(Item[] items, uint16[] tokenIds);
  event EditItem(Item item, uint16 tokenId);

  error IdTooHigh();
  error ItemNotTransferable();
  error InvalidChainId();
  error InvalidTokenId();
  error ItemAlreadyExists();
  error ItemDoesNotExist(uint16);
  error EquipmentPositionShouldNotChange();
  error OnlyForHardhat();
  error NotAllowedHardhat();
  error ERC1155ReceiverNotApproved();
  error NotPlayersOrShop();
  error NotAdmin();

  // Input only
  struct NonCombatStats {
    Skill skill;
    int16 diff;
  }

  // Contains everything you need to create an item
  struct InputItem {
    CombatStats combatStats;
    NonCombatStats nonCombatStats;
    uint16 tokenId;
    EquipPosition equipPosition;
    // Can it be transferred?
    bool isTransferable;
    // Minimum requirements in this skill
    Skill skill;
    uint32 minXP;
    // Food
    uint16 healthRestored;
    // Boost
    BoostType boostType;
    uint16 boostValue; // Varies, could be the % increase
    uint24 boostDuration; // How long the effect of the boost vial last
    // uri
    string metadataURI;
  }

  World public world;
  string private baseURI;

  // How many of this item exist
  mapping(uint itemId => uint amount) public itemBalances;

  address public players;
  address public shop;

  // Royalties
  uint public royaltyFee;
  address public royaltyReceiver;

  uint public uniqueItems; // unique number of items

  mapping(uint itemId => string tokenURI) private tokenURIs;
  mapping(uint itemId => CombatStats combatStats) public combatStats;
  mapping(uint itemId => Item item) public items;

  AdminAccess private adminAccess;

  modifier onlyPlayersOrShop() {
    if (msg.sender != players && msg.sender != shop) {
      revert NotPlayersOrShop();
    }
    _;
  }

  modifier isAdmin() {
    if (!adminAccess.isAdmin(_msgSender())) {
      revert NotAdmin();
    }
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    World _world,
    address _shop,
    address _royaltyReceiver,
    AdminAccess _adminAccess,
    string calldata _baseURI
  ) public initializer {
    __ERC1155_init("");
    __Ownable_init();
    __UUPSUpgradeable_init();
    world = _world;
    shop = _shop;
    baseURI = _baseURI;
    royaltyFee = 250; // 2.5%
    royaltyReceiver = _royaltyReceiver;
    adminAccess = _adminAccess;
  }

  function _mintItem(address _to, uint _tokenId, uint256 _amount) internal {
    if (_tokenId >= type(uint16).max) {
      revert IdTooHigh();
    }
    //    require(_exists(_tokenId));
    uint existingBalance = itemBalances[_tokenId];
    if (existingBalance == 0) {
      uniqueItems = uniqueItems.inc();
    }

    itemBalances[_tokenId] = existingBalance + _amount;
    _mint(_to, uint(_tokenId), _amount, "");
  }

  function _mintBatchItems(address _to, uint[] calldata _tokenIds, uint[] calldata _amounts) internal {
    U256 numNewItems;
    U256 tokenIdsLength = U256.wrap(_tokenIds.length);
    for (U256 iter; iter < tokenIdsLength; iter = iter.inc()) {
      uint i = iter.asUint256();
      uint tokenId = _tokenIds[i];
      if (tokenId >= type(uint16).max) {
        revert IdTooHigh();
      }
      //      require(_exists(_tokenIds[i]));
      uint existingBalance = itemBalances[tokenId];
      if (existingBalance == 0) {
        // Brand new item
        numNewItems = numNewItems.inc();
      }

      itemBalances[tokenId] = existingBalance + _amounts[i];
    }
    if (numNewItems.neq(0)) {
      uniqueItems += numNewItems.asUint256();
    }
    _mintBatch(_to, _tokenIds, _amounts, "");
  }

  function mint(address _to, uint _tokenId, uint256 _amount) external onlyPlayersOrShop {
    _mintItem(_to, _tokenId, _amount);
  }

  // Can't use Item[] array unfortunately so they don't support array casts
  function mintBatch(address _to, uint[] calldata _ids, uint256[] calldata _amounts) external onlyPlayersOrShop {
    _mintBatchItems(_to, _ids, _amounts);
  }

  function uri(uint256 _tokenId) public view virtual override returns (string memory) {
    if (!_exists(_tokenId)) {
      revert ItemDoesNotExist(uint16(_tokenId));
    }
    return string(abi.encodePacked(baseURI, tokenURIs[_tokenId]));
  }

  function _exists(uint _tokenId) private view returns (bool) {
    return items[_tokenId].exists;
  }

  function _getItem(uint16 _tokenId) private view returns (Item memory) {
    if (!_exists(_tokenId)) {
      revert ItemDoesNotExist(_tokenId);
    }
    return items[_tokenId];
  }

  function getItem(uint16 _tokenId) external view returns (Item memory) {
    return _getItem(_tokenId);
  }

  function getMinRequirement(uint16 _tokenId) public view returns (Skill, uint32) {
    return (items[_tokenId].skill, items[_tokenId].minXP);
  }

  function getEquipPosition(uint16 _tokenId) public view returns (EquipPosition) {
    if (!_exists(_tokenId)) {
      revert ItemDoesNotExist(_tokenId);
    }
    return items[_tokenId].equipPosition;
  }

  function getMinRequirements(
    uint16[] calldata _tokenIds
  ) external view returns (Skill[] memory skills, uint32[] memory minXPs) {
    skills = new Skill[](_tokenIds.length);
    minXPs = new uint32[](_tokenIds.length);
    U256 tokenIdsLength = U256.wrap(_tokenIds.length);
    for (U256 iter; iter < tokenIdsLength; iter = iter.inc()) {
      uint i = iter.asUint256();
      (skills[i], minXPs[i]) = getMinRequirement(_tokenIds[i]);
    }
  }

  function getItems(uint16[] calldata _tokenIds) external view returns (Item[] memory _items) {
    U256 tokenIdsLength = U256.wrap(_tokenIds.length);
    _items = new Item[](tokenIdsLength.asUint256());
    for (U256 iter; iter < tokenIdsLength; iter = iter.inc()) {
      uint i = iter.asUint256();
      _items[i] = _getItem(_tokenIds[i]);
    }
  }

  function getEquipPositions(
    uint16[] calldata _tokenIds
  ) external view returns (EquipPosition[] memory equipPositions) {
    U256 tokenIdsLength = U256.wrap(_tokenIds.length);
    equipPositions = new EquipPosition[](tokenIdsLength.asUint256());
    for (U256 iter; iter < tokenIdsLength; iter = iter.inc()) {
      uint i = iter.asUint256();
      equipPositions[i] = getEquipPosition(_tokenIds[i]);
    }
  }

  // If an item is burnt, remove it from the total
  function _removeAnyBurntFromTotal(uint[] memory _ids, uint[] memory _amounts) private {
    U256 iter = U256.wrap(_ids.length);
    while (iter.neq(0)) {
      iter = iter.dec();
      uint i = iter.asUint256();
      itemBalances[_ids[i]] -= _amounts[i];
    }
  }

  function _checkIsTransferable(uint[] memory _ids) private view {
    U256 iter = U256.wrap(_ids.length);
    while (iter.neq(0)) {
      iter = iter.dec();
      uint i = iter.asUint256();
      if (_exists(_ids[i]) && !items[_ids[i]].isTransferable) {
        revert ItemNotTransferable();
      }
    }
  }

  function _beforeTokenTransfer(
    address /*_operator*/,
    address _from,
    address _to,
    uint[] memory _ids,
    uint[] memory _amounts,
    bytes memory /*_data*/
  ) internal virtual override {
    if (_from == address(0) || _amounts.length == 0 || _from == _to) {
      // When minting or self sending, then no further processing is required
      return;
    }

    bool isBurnt = _to == address(0) || _to == 0x000000000000000000000000000000000000dEaD;
    if (isBurnt) {
      _removeAnyBurntFromTotal(_ids, _amounts);
    } else {
      _checkIsTransferable(_ids);
    }
    if (players != address(0)) {
      IPlayers(players).itemBeforeTokenTransfer(_from, _ids, _amounts);
    } else {
      if (block.chainid != 31337) {
        revert InvalidChainId();
      }
    }
  }

  /**
   * @dev See {IERC1155-balanceOfBatch}. This implementation is not standard ERC1155, it's optimized for the single account case
   */
  function balanceOfs(address _account, uint16[] memory _ids) external view returns (uint256[] memory batchBalances) {
    U256 iter = U256.wrap(_ids.length);
    batchBalances = new uint256[](iter.asUint256());
    while (iter.neq(0)) {
      iter = iter.dec();
      uint i = iter.asUint256();
      batchBalances[i] = balanceOf(_account, _ids[i]);
    }
  }

  function burn(address _from, uint _tokenId, uint _quantity) external {
    if (
      _from != _msgSender() && !isApprovedForAll(_from, _msgSender()) && players != _msgSender() && shop != _msgSender()
    ) {
      revert ERC1155ReceiverNotApproved();
    }
    _burn(_from, _tokenId, _quantity);
  }

  function _setItem(InputItem calldata _item) private returns (Item storage item) {
    if (_item.tokenId == 0) {
      revert InvalidTokenId();
    }
    bool hasCombat;
    CombatStats calldata _combatStats = _item.combatStats;
    assembly ("memory-safe") {
      hasCombat := not(iszero(_combatStats))
    }
    item = items[_item.tokenId];
    item.equipPosition = _item.equipPosition;
    item.isTransferable = _item.isTransferable;
    item.exists = true;

    if (hasCombat) {
      // Combat stats
      item.melee = int8(_item.combatStats.melee);
      item.magic = int8(_item.combatStats.magic);
      item.range = int8(_item.combatStats.range);
      item.meleeDefence = int8(_item.combatStats.meleeDefence);
      item.magicDefence = int8(_item.combatStats.magicDefence);
      item.rangeDefence = int8(_item.combatStats.rangeDefence);
      item.health = int8(_item.combatStats.health);
    }
    item.skill1 = _item.nonCombatStats.skill;
    item.skillDiff1 = _item.nonCombatStats.diff;

    if (_item.healthRestored != 0) {
      item.healthRestored = _item.healthRestored;
    }

    if (_item.boostType != BoostType.NONE) {
      item.boostType = _item.boostType;
      item.boostValue = _item.boostValue;
      item.boostDuration = _item.boostDuration;
    }

    item.minXP = _item.minXP;
    item.skill = _item.skill;
    tokenURIs[_item.tokenId] = _item.metadataURI;
  }

  function royaltyInfo(
    uint256 /*_tokenId*/,
    uint256 _salePrice
  ) external view override returns (address receiver, uint256 royaltyAmount) {
    uint256 amount = (_salePrice * royaltyFee) / 10000;
    return (royaltyReceiver, amount);
  }

  function supportsInterface(bytes4 interfaceId) public view override(IERC165, ERC1155Upgradeable) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  function name() external pure returns (string memory) {
    return "Estfor Items (Alpha)";
  }

  function symbol() external pure returns (string memory) {
    return "EST4I_A";
  }

  // Or make it constants and redeploy the contracts
  function addItem(InputItem calldata _inputItem) external onlyOwner {
    if (_exists(_inputItem.tokenId)) {
      revert ItemAlreadyExists();
    }
    Item storage item = _setItem(_inputItem);
    emit AddItem(item, _inputItem.tokenId);
  }

  function addItems(InputItem[] calldata _inputItems) external onlyOwner {
    U256 iter = U256.wrap(_inputItems.length);
    Item[] memory _items = new Item[](iter.asUint256());
    uint16[] memory tokenIds = new uint16[](iter.asUint256());
    while (iter.neq(0)) {
      iter = iter.dec();
      uint i = iter.asUint256();
      if (_exists(_inputItems[i].tokenId)) {
        revert ItemAlreadyExists();
      }
      _items[i] = _setItem(_inputItems[i]);
      tokenIds[i] = _inputItems[i].tokenId;
    }
    emit AddItems(_items, tokenIds);
  }

  function editItem(InputItem calldata _inputItem) external onlyOwner {
    if (!_exists(_inputItem.tokenId)) {
      revert ItemDoesNotExist(_inputItem.tokenId);
    }
    if (items[_inputItem.tokenId].equipPosition != _inputItem.equipPosition) {
      revert EquipmentPositionShouldNotChange();
    }
    Item storage item = _setItem(_inputItem);
    emit EditItem(item, _inputItem.tokenId);
  }

  function setPlayers(address _players) external onlyOwner {
    players = _players;
  }

  function setBaseURI(string calldata _baseURI) external onlyOwner {
    baseURI = _baseURI;
  }

  // solhint-disable-next-line no-empty-blocks
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  // These are just to make tests easier to run by allowing arbitrary minting
  function testMint(address _to, uint _tokenId, uint _amount) external isAdmin {
    _mintItem(_to, _tokenId, _amount);
  }

  function testMints(address _to, uint[] calldata _tokenIds, uint[] calldata _amounts) external isAdmin {
    _mintBatchItems(_to, _tokenIds, _amounts);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2Upgradeable is Initializable {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private vrfCoordinator;

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  // solhint-disable-next-line func-name-mixedcase
  function __VRFConsumerBaseV2_init(address _vrfCoordinator) internal onlyInitializing {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";

import {UnsafeU256, U256} from "@0xdoublesharp/unsafe-math/contracts/UnsafeU256.sol";
import {VRFConsumerBaseV2Upgradeable} from "./VRFConsumerBaseV2Upgradeable.sol";

/* solhint-disable no-global-import */
import "./globals/players.sol";
import "./globals/actions.sol";
import "./globals/items.sol";
import "./globals/rewards.sol";

/* solhint-enable no-global-import */

// Fantom VRF
// VRF 0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634
// LINK token 0x6F43FF82CCA38001B6699a8AC47A2d0E66939407
// PREMIUM 0.0005 LINK
contract World is VRFConsumerBaseV2Upgradeable, UUPSUpgradeable, OwnableUpgradeable, Multicall {
  using UnsafeU256 for U256;

  event RequestSent(uint256 requestId, uint32 numWords);
  event RequestFulfilled(uint256 requestId, uint256[3] randomWords);
  event AddAction(Action action);
  event EditAction(Action action);
  event SetAvailableAction(uint16 actionId, bool available);
  event AddDynamicActions(uint16[] actionIds);
  event RemoveDynamicActions(uint16[] actionIds);
  event AddActionChoice(uint16 actionId, uint16 actionChoiceId, ActionChoice choice);
  event AddActionChoices(uint16 actionId, uint16[] actionChoiceIds, ActionChoice[] choices);
  event NewDailyRewards(Equipment[8] dailyRewards);
  error RandomWordsCannotBeUpdatedYet();
  error CanOnlyRequestAfterTheNextCheckpoint(uint256 currentTime, uint256 checkpoint);
  error RequestAlreadyFulfilled();
  error NoValidRandomWord();
  error CanOnlyRequestAfter1DayHasPassed();
  error ActionIdZeroNotAllowed();
  error MinCannotBeGreaterThanMax();
  error DynamicActionsCannotBeAdded();
  error ActionAlreadyExists();
  error ActionDoesNotExist();
  error ActionChoiceIdZeroNotAllowed();
  error OnlySupportingMax1Output();
  error DynamicActionsCannotBeSet();
  error LengthMismatch();
  error NoActionChoices();
  error ActionChoiceAlreadyExists();
  error GuaranteedRewardsNoDuplicates();
  error RandomRewardsMustBeInOrder();
  error RandomRewardNoDuplicates();

  // This is only used as an input arg
  struct Action {
    uint16 actionId;
    ActionInfo info;
    GuaranteedReward[] guaranteedRewards;
    RandomReward[] randomRewards;
    CombatStats combatStats;
  }

  // solhint-disable-next-line var-name-mixedcase
  VRFCoordinatorV2Interface public COORDINATOR;

  // Your subscription ID.
  uint64 public subscriptionId;

  // Past request ids
  uint[] public requestIds; // Each one is a set of random words for 1 day
  mapping(uint requestId => uint[3] randomWord) public randomWords;
  uint40 public lastRandomWordsUpdatedTime;
  uint40 public startTime;
  uint40 public weeklyRewardCheckpoint;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network, this is 10000gwei
  // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
  bytes32 public constant KEY_HASH = 0x5881eea62f9876043df723cf89f0c2bb6f950da25e9dfe66995c24f919c8f8ab;

  uint32 public constant CALLBACK_GAS_LIMIT = 100000;
  // The default is 3, but you can set this higher.
  uint16 public constant REQUEST_CONFIRMATIONS = 1;
  // For this example, retrieve 3 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 public constant NUM_WORDS = 3;

  uint32 public constant MIN_RANDOM_WORDS_UPDATE_TIME = 1 days;
  uint32 public constant MIN_DYNAMIC_ACTION_UPDATE_TIME = 1 days;

  mapping(uint actionId => ActionInfo actionInfo) public actions;
  uint16[] private lastAddedDynamicActions;
  uint public lastDynamicUpdatedTime;

  bytes32 public dailyRewards; // Effectively stores Equipment[8] which is packed, first 7 are daily, last one is weekly reward

  mapping(uint actionId => mapping(uint16 choiceId => ActionChoice actionChoice)) private actionChoices;
  mapping(uint actionId => CombatStats combatStats) private actionCombatStats;

  mapping(uint actionId => ActionRewards actionRewards) private actionRewards;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(VRFCoordinatorV2Interface _coordinator, uint64 _subscriptionId) public initializer {
    __VRFConsumerBaseV2_init(address(_coordinator));
    __Ownable_init();
    __UUPSUpgradeable_init();

    COORDINATOR = _coordinator;
    subscriptionId = _subscriptionId;
    startTime = uint40((block.timestamp / MIN_RANDOM_WORDS_UPDATE_TIME) * MIN_RANDOM_WORDS_UPDATE_TIME) - 5 days; // Floor to the nearest day 00:00 UTC
    lastRandomWordsUpdatedTime = startTime + 5 days;
    weeklyRewardCheckpoint = uint40((block.timestamp - 4 days) / 1 weeks) * 1 weeks + 4 days + 1 weeks;

    // Issue new available daily rewards
    Equipment[8] memory rewards = [
      Equipment(COPPER_ORE, 100),
      Equipment(COAL_ORE, 200),
      Equipment(RUBY, 100),
      Equipment(MITHRIL_BAR, 200),
      Equipment(COOKED_BOWFISH, 100),
      Equipment(LEAF_FRAGMENTS, 20),
      Equipment(HELL_SCROLL, 300),
      Equipment(XP_BOOST, 1)
    ];

    _storeDailyRewards(rewards);
    emit NewDailyRewards(rewards);

    // Initialize 5 days worth of random words
    for (uint i = 0; i < 5; ++i) {
      uint requestId = 200 + i;
      requestIds.push(requestId);
      emit RequestSent(requestId, NUM_WORDS);
      uint[] memory _randomWords = new uint[](3);
      _randomWords[0] = uint(
        blockhash(block.number - 5 + i) ^ 0x3632d8eba811d69784e6904a58de6e0ab55f32638189623b309895beaa6920c4
      );
      _randomWords[1] = uint(
        blockhash(block.number - 5 + i) ^ 0xca820e9e57e5e703aeebfa2dc60ae09067f931b6e888c0a7c7a15a76341ab2c2
      );
      _randomWords[2] = uint(
        blockhash(block.number - 5 + i) ^ 0xd1f1b7d57307aee9687ae39dbb462b1c1f07a406d34cd380670360ef02f243b6
      );
      fulfillRandomWords(requestId, _randomWords);
    }
  }

  function _getDailyReward(uint256 _day) private view returns (Equipment memory equipment) {
    bytes32 rewardItemTokenId = (dailyRewards & ((bytes32(hex"ffff0000") >> (_day * 32)))) >> ((7 - _day) * 32 + 16);
    bytes32 rewardAmount = (dailyRewards & ((bytes32(hex"0000ffff") >> (_day * 32)))) >> ((7 - _day) * 32);
    assembly ("memory-safe") {
      mstore(equipment, rewardItemTokenId)
      mstore(add(equipment, 32), rewardAmount)
    }
  }

  function _getUpdatedDailyReward(
    uint _index,
    Equipment memory _equipment,
    bytes32 _rewards
  ) private pure returns (bytes32) {
    bytes32 rewardItemTokenId;
    bytes32 rewardAmount;
    assembly ("memory-safe") {
      rewardItemTokenId := mload(_equipment)
      rewardAmount := mload(add(_equipment, 32))
    }

    _rewards = _rewards | (rewardItemTokenId << ((7 - _index) * 32 + 16));
    _rewards = _rewards | (rewardAmount << ((7 - _index) * 32));
    return _rewards;
  }

  function _storeDailyRewards(Equipment[8] memory equipments) private {
    bytes32 rewards;
    for (uint i = 0; i < equipments.length; ++i) {
      rewards = _getUpdatedDailyReward(i, equipments[i], rewards);
    }
    dailyRewards = rewards;
  }

  function canRequestRandomWord() external view returns (bool) {
    // Last one has not been fulfilled yet
    if (requestIds.length != 0 && randomWords[requestIds[requestIds.length - 1]][0] == 0) {
      return false;
    }
    if (lastRandomWordsUpdatedTime + MIN_RANDOM_WORDS_UPDATE_TIME > block.timestamp) {
      return false;
    }
    return true;
  }

  function requestRandomWords() external returns (uint256 requestId) {
    // Last one has not been fulfilled yet
    if (requestIds.length != 0 && randomWords[requestIds[requestIds.length - 1]][0] == 0) {
      revert RandomWordsCannotBeUpdatedYet();
    }
    if (lastRandomWordsUpdatedTime + MIN_RANDOM_WORDS_UPDATE_TIME > block.timestamp) {
      revert CanOnlyRequestAfterTheNextCheckpoint(
        block.timestamp,
        lastRandomWordsUpdatedTime + MIN_RANDOM_WORDS_UPDATE_TIME
      );
    }

    // Will revert if subscription is not set and funded.
    requestId = COORDINATOR.requestRandomWords(
      KEY_HASH,
      subscriptionId,
      REQUEST_CONFIRMATIONS,
      CALLBACK_GAS_LIMIT,
      NUM_WORDS
    );

    requestIds.push(requestId);
    lastRandomWordsUpdatedTime += MIN_RANDOM_WORDS_UPDATE_TIME;
    emit RequestSent(requestId, NUM_WORDS);
    return requestId;
  }

  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
    //    require(_requestId == requestIds[requestIds.length - 1], "request not found");
    if (randomWords[_requestId][0] != 0) {
      revert RequestAlreadyFulfilled();
    }

    uint256[3] memory random = [_randomWords[0], _randomWords[1], _randomWords[2]];

    if (random[0] == 0) {
      // Not sure if 0 can be selected, but in case use previous block hash as pseudo random number
      random[0] = uint(blockhash(block.number - 1));
    }
    if (random[1] == 0) {
      random[1] = uint(blockhash(block.number - 2));
    }
    if (random[2] == 0) {
      random[2] = uint(blockhash(block.number - 3));
    }

    randomWords[_requestId] = random;
    emit RequestFulfilled(_requestId, random);

    // Are we at the threshold for a new week
    if (weeklyRewardCheckpoint <= ((block.timestamp) / 1 days) * 1 days) {
      // Issue new daily rewards based on the new random words (TODO)
      Equipment[8] memory rewards = [
        Equipment(COPPER_ORE, 100),
        Equipment(COAL_ORE, 200),
        Equipment(RUBY, 100),
        Equipment(MITHRIL_BAR, 200),
        Equipment(COOKED_BOWFISH, 100),
        Equipment(LEAF_FRAGMENTS, 20),
        Equipment(HELL_SCROLL, 300),
        Equipment(XP_BOOST, 1)
      ];
      _storeDailyRewards(rewards);
      emit NewDailyRewards(rewards);
      weeklyRewardCheckpoint = uint40((block.timestamp - 4 days) / 1 weeks) * 1 weeks + 4 days + 1 weeks;
    }
  }

  function getDailyReward() external view returns (Equipment memory equipment) {
    uint checkpoint = ((block.timestamp - 4 days) / 1 weeks) * 1 weeks + 4 days;
    uint day = ((block.timestamp / 1 days) * 1 days - checkpoint) / 1 days;
    equipment = _getDailyReward(day);
  }

  function getWeeklyReward() external view returns (Equipment memory equipment) {
    equipment = _getDailyReward(7);
  }

  function _getRandomWordOffset(uint _timestamp) private view returns (uint) {
    return (_timestamp - startTime) / MIN_RANDOM_WORDS_UPDATE_TIME;
  }

  // Just returns the first random word of the array
  function _getRandomWord(uint _timestamp) private view returns (uint) {
    uint offset = _getRandomWordOffset(_timestamp);
    if (requestIds.length <= offset) {
      return 0;
    }
    return randomWords[requestIds[offset]][0];
  }

  function hasRandomWord(uint _timestamp) external view returns (bool) {
    return _getRandomWord(_timestamp) != 0;
  }

  function getRandomWord(uint _timestamp) external view returns (uint randomWord) {
    randomWord = _getRandomWord(_timestamp);
    if (randomWord == 0) {
      revert NoValidRandomWord();
    }
  }

  function _getFullRandomWords(uint _timestamp) private view returns (uint[3] memory) {
    uint offset = _getRandomWordOffset(_timestamp);
    if (requestIds.length <= offset) {
      return [uint256(0), uint256(0), uint256(0)];
    }
    return randomWords[requestIds[offset]];
  }

  function getFullRandomWords(uint _timestamp) external view returns (uint[3] memory) {
    return _getFullRandomWords(_timestamp);
  }

  function getMultipleFullRandomWords(uint _timestamp) external view returns (uint[3][5] memory words) {
    for (uint i = 0; i < 5; ++i) {
      words[i] = _getFullRandomWords(_timestamp - i * 1 days);
    }
  }

  // Can be called by anyone as long as over 1 day has passed since the last call
  /*
  function updateDynamicActions() external {
    if ((lastDynamicUpdatedTime + MIN_DYNAMIC_ACTION_UPDATE_TIME) > block.timestamp) {
      revert CanOnlyRequestAfter1DayHasPassed();
    }

    emit RemoveDynamicActions(lastAddedDynamicActions);

    // These are no longer available as existing actions
    U256 iter = U256.wrap(lastAddedDynamicActions.length);
    while (iter.neq(0)) {
      iter = iter.dec();
      actions[lastAddedDynamicActions[iter.asUint256()]].isAvailable = false;
    }

    delete lastAddedDynamicActions;
    uint randomWord = getRandomWord(block.timestamp);

    uint16[] memory actionIdsToAdd = new uint16[](1);

    if (randomWord % 2 == 0) {
      // If it's even do X
      actionIdsToAdd[0] = 1; // ?
    } else {
      actionIdsToAdd[0] = 2; // ?
    }

    lastAddedDynamicActions = actionIdsToAdd;
    iter = U256.wrap(actionIdsToAdd.length);
    while (iter.neq(0)) {
      iter = iter.dec();
      actions[actionIdsToAdd[iter.asUint256()]].isAvailable = true;
    }

    lastDynamicUpdatedTime = block.timestamp;
    emit AddDynamicActions(actionIdsToAdd);
  } */

  function getSkill(uint _actionId) external view returns (Skill) {
    return actions[_actionId].skill;
  }

  function getActionRewards(uint _actionId) external view returns (ActionRewards memory) {
    return actionRewards[_actionId];
  }

  function getPermissibleItemsForAction(
    uint _actionId
  )
    external
    view
    returns (
      uint16 handItemTokenIdRangeMin,
      uint16 handItemTokenIdRangeMax,
      bool actionChoiceRequired,
      Skill skill,
      uint32 minXP,
      bool actionAvailable
    )
  {
    ActionInfo storage actionInfo = actions[_actionId];
    return (
      actionInfo.handItemTokenIdRangeMin,
      actionInfo.handItemTokenIdRangeMax,
      actionInfo.actionChoiceRequired,
      actionInfo.skill,
      actionInfo.minXP,
      actionInfo.isAvailable
    );
  }

  function getXPPerHour(uint16 _actionId, uint16 _actionChoiceId) external view returns (uint24 xpPerHour) {
    return _actionChoiceId != 0 ? actionChoices[_actionId][_actionChoiceId].xpPerHour : actions[_actionId].xpPerHour;
  }

  function getNumSpawn(uint16 _actionId) external view returns (uint numSpawned) {
    return actions[_actionId].numSpawned;
  }

  function getCombatStats(uint16 _actionId) external view returns (CombatStats memory stats) {
    stats = actionCombatStats[_actionId];
  }

  function getActionChoice(uint16 _actionId, uint16 _choiceId) external view returns (ActionChoice memory) {
    return actionChoices[_actionId][_choiceId];
  }

  function getActionSuccessPercentAndMinXP(
    uint16 _actionId
  ) external view returns (uint8 successPercent, uint32 minXP) {
    return (actions[_actionId].successPercent, actions[_actionId].minXP);
  }

  function getRewardsHelper(uint16 _actionId) external view returns (ActionRewards memory, Skill, uint) {
    return (actionRewards[_actionId], actions[_actionId].skill, actions[_actionId].numSpawned);
  }

  function _setAction(Action calldata _action) private {
    if (_action.actionId == 0) {
      revert ActionIdZeroNotAllowed();
    }
    if (_action.info.handItemTokenIdRangeMin > _action.info.handItemTokenIdRangeMax) {
      revert MinCannotBeGreaterThanMax();
    }
    actions[_action.actionId] = _action.info;

    // Set the rewards
    ActionRewards storage actionReward = actionRewards[_action.actionId];
    _setActionGuaranteedRewards(_action, actionReward);
    // Now do the same for randomRewards
    _setActionRandomRewards(_action, actionReward);

    if (_action.info.skill == Skill.COMBAT) {
      actionCombatStats[_action.actionId] = _action.combatStats;
    }
  }

  function _setActionGuaranteedRewards(Action calldata _action, ActionRewards storage _actionRewards) private {
    if (_action.guaranteedRewards.length != 0) {
      _actionRewards.guaranteedRewardTokenId1 = _action.guaranteedRewards[0].itemTokenId;
      _actionRewards.guaranteedRewardRate1 = _action.guaranteedRewards[0].rate;
    }
    if (_action.guaranteedRewards.length > 1) {
      _actionRewards.guaranteedRewardTokenId2 = _action.guaranteedRewards[1].itemTokenId;
      _actionRewards.guaranteedRewardRate2 = _action.guaranteedRewards[1].rate;
      if (_actionRewards.guaranteedRewardTokenId1 == _actionRewards.guaranteedRewardTokenId2) {
        revert GuaranteedRewardsNoDuplicates();
      }
    }
    if (_action.guaranteedRewards.length > 2) {
      _actionRewards.guaranteedRewardTokenId3 = _action.guaranteedRewards[2].itemTokenId;
      _actionRewards.guaranteedRewardRate3 = _action.guaranteedRewards[2].rate;

      for (uint i; i < _action.guaranteedRewards.length - 1; ++i) {
        if (
          _action.guaranteedRewards[i].itemTokenId ==
          _action.guaranteedRewards[_action.guaranteedRewards.length - 1].itemTokenId
        ) {
          revert GuaranteedRewardsNoDuplicates();
        }
      }
    }
  }

  // Random rewards but have most common one first
  function _setActionRandomRewards(Action calldata _action, ActionRewards storage actionReward) private {
    if (_action.randomRewards.length != 0) {
      actionReward.randomRewardTokenId1 = _action.randomRewards[0].itemTokenId;
      actionReward.randomRewardChance1 = _action.randomRewards[0].chance;
      actionReward.randomRewardAmount1 = _action.randomRewards[0].amount;
    }
    if (_action.randomRewards.length > 1) {
      actionReward.randomRewardTokenId2 = _action.randomRewards[1].itemTokenId;
      actionReward.randomRewardChance2 = _action.randomRewards[1].chance;
      actionReward.randomRewardAmount2 = _action.randomRewards[1].amount;

      if (actionReward.randomRewardChance2 > actionReward.randomRewardChance1) {
        revert RandomRewardsMustBeInOrder();
      }
      if (actionReward.randomRewardTokenId1 == actionReward.randomRewardTokenId2) {
        revert RandomRewardNoDuplicates();
      }
    }
    if (_action.randomRewards.length > 2) {
      actionReward.randomRewardTokenId3 = _action.randomRewards[2].itemTokenId;
      actionReward.randomRewardChance3 = _action.randomRewards[2].chance;
      actionReward.randomRewardAmount3 = _action.randomRewards[2].amount;

      if (actionReward.randomRewardChance3 > actionReward.randomRewardChance2) {
        revert RandomRewardsMustBeInOrder();
      }
      for (uint i; i < _action.randomRewards.length - 1; ++i) {
        if (
          _action.randomRewards[i].itemTokenId == _action.randomRewards[_action.randomRewards.length - 1].itemTokenId
        ) {
          revert RandomRewardNoDuplicates();
        }
      }
    }
    if (_action.randomRewards.length > 3) {
      actionReward.randomRewardTokenId4 = _action.randomRewards[3].itemTokenId;
      actionReward.randomRewardChance4 = _action.randomRewards[3].chance;
      actionReward.randomRewardAmount4 = _action.randomRewards[3].amount;
      if (actionReward.randomRewardChance4 > actionReward.randomRewardChance3) {
        revert RandomRewardsMustBeInOrder();
      }
      for (uint i; i < _action.randomRewards.length - 1; ++i) {
        if (
          _action.randomRewards[i].itemTokenId == _action.randomRewards[_action.randomRewards.length - 1].itemTokenId
        ) {
          revert RandomRewardNoDuplicates();
        }
      }
    }
  }

  function _addAction(Action calldata _action) private {
    if (_action.info.isDynamic) {
      revert DynamicActionsCannotBeAdded();
    }
    if (actions[_action.actionId].skill != Skill.NONE) {
      revert ActionAlreadyExists();
    }
    _setAction(_action);
    emit AddAction(_action);
  }

  function addActions(Action[] calldata _actions) external onlyOwner {
    U256 iter = U256.wrap(_actions.length);
    while (iter.neq(0)) {
      iter = iter.dec();
      uint16 i = iter.asUint16();
      _addAction(_actions[i]);
    }
  }

  function addAction(Action calldata _action) external onlyOwner {
    _addAction(_action);
  }

  function editAction(Action calldata _action) external onlyOwner {
    if (actions[_action.actionId].skill == Skill.NONE) {
      revert ActionDoesNotExist();
    }
    _setAction(_action);
    emit EditAction(_action);
  }

  function _addActionChoice(uint16 _actionId, uint16 _actionChoiceId, ActionChoice calldata _actionChoice) private {
    if (_actionChoiceId == 0) {
      revert ActionChoiceIdZeroNotAllowed();
    }
    if (_actionChoice.outputTokenId != 0 && _actionChoice.outputNum != 1) {
      revert OnlySupportingMax1Output();
    }
    if (actionChoices[_actionId][_actionChoiceId].skill != Skill.NONE) {
      revert ActionChoiceAlreadyExists();
    }
    actionChoices[_actionId][_actionChoiceId] = _actionChoice;
  }

  // actionId of 0 means it is not tied to a specific action (combat)
  function addActionChoice(
    uint16 _actionId,
    uint16 _actionChoiceId,
    ActionChoice calldata _actionChoice
  ) external onlyOwner {
    _addActionChoice(_actionId, _actionChoiceId, _actionChoice);
    emit AddActionChoice(_actionId, _actionChoiceId, _actionChoice);
  }

  /*
  function addActionChoices(
    uint16 _actionId,
    uint16[] calldata _actionChoiceIds,
    ActionChoice[] calldata _actionChoices
  ) external onlyOwner {
    if (_actionChoiceIds.length != _actionChoices.length) {
      revert LengthMismatch();
    }
    U256 iter = U256.wrap(_actionChoices.length);
    if (iter.eq(0)) {
      revert NoActionChoices();
    }
    while (iter.neq(0)) {
      iter = iter.dec();
      uint16 i = iter.asUint16();
      _addActionChoice(_actionId, _actionChoiceIds[i], _actionChoices[i]);
    }
    emit AddActionChoices(_actionId, _actionChoiceIds, _actionChoices);
  } */

  function addBulkActionChoices(
    uint16[] calldata _actionIds,
    uint16[][] calldata _actionChoiceIds,
    ActionChoice[][] calldata _actionChoices
  ) external onlyOwner {
    U256 iter = U256.wrap(0);
    if (_actionIds.length != _actionChoices.length) {
      revert LengthMismatch();
    }
    if (_actionIds.length == 0) {
      revert NoActionChoices();
    }

    while (iter.lt(_actionIds.length)) {
      uint16 i = iter.asUint16();
      uint16 actionId = _actionIds[i];
      emit AddActionChoices(actionId, _actionChoiceIds[i], _actionChoices[i]);
      U256 iter2 = U256.wrap(0);
      if (_actionChoiceIds[i].length != _actionChoices[i].length) {
        revert LengthMismatch();
      }

      while (iter2.lt(_actionChoices[i].length)) {
        uint16 j = iter2.asUint16();
        _addActionChoice(actionId, _actionChoiceIds[i][j], _actionChoices[i][j]);
        iter2 = iter2.inc();
      }
      iter = iter.inc();
    }
  }

  function setAvailable(uint16 _actionId, bool _isAvailable) external onlyOwner {
    if (actions[_actionId].skill == Skill.NONE) {
      revert ActionDoesNotExist();
    }
    if (actions[_actionId].isDynamic) {
      revert DynamicActionsCannotBeSet();
    }
    actions[_actionId].isAvailable = _isAvailable;
    emit SetAvailableAction(_actionId, _isAvailable);
  }

  // solhint-disable-next-line no-empty-blocks
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}