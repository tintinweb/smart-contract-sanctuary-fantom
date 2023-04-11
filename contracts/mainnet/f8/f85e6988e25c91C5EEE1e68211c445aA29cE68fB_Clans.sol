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
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {IBrushToken} from "../interfaces/IBrushToken.sol";
import {IPlayers} from "../interfaces/IPlayers.sol";
import {IClans, Clan} from "../interfaces/IClans.sol";
import {IBankFactory} from "../interfaces/IBankFactory.sol";

contract Clans is UUPSUpgradeable, OwnableUpgradeable, IClans {
  event ClanCreated(uint clanId, uint playerId, string name, uint imageId, uint tierId);
  event AdminAdded(uint clanId, uint playerId);
  event AdminRemoved(uint clanId, uint playerId);
  event InviteSent(uint clanId, uint playerId, uint fromPlayerId);
  event InviteAccepted(uint clanId, uint playerId);
  event MemberLeft(uint clanId, uint playerId);
  event JoinRequestSent(uint clanId, uint playerId);
  event JoinRequestAccepted(uint clanId, uint playerId, uint acceptedByPlayerId);
  event JoinRequestRemoved(uint clanId, uint playerId);
  event ClanOwnershipTransferred(uint clanId, uint playerId);
  event AddTiers(Tier[] tiers);
  event EditTier(Tier tier);
  event ClanOwnerLeft(uint clanId, uint playerId);
  event ClanEdited(uint clanId, uint playerId, string name, uint imageId);
  event ClanUpgraded(uint clanId, uint playerId, uint tierId);
  event ClanDestroyed(uint clanId);

  error OnlyOwner();
  error OnlyAdmin();
  error AlreadyInClan();
  error UserAlreadyAdmin();
  error NotOwnerOfPlayer();
  error NotOwnerOfPlayerAndActive();
  error NotMemberOfClan();
  error NotAdmin();
  error ClanIsFull();
  error NoInviteRequest();
  error NotInClan();
  error OwnerExists();
  error InvalidTier();
  error PlayerAlreadyAdmin();
  error CannotBeCalledOnOwner();
  error CannotBeCalledOnSelf();
  error InvalidImageId();
  error InvalidName();
  error ClanDoesNotExist();
  error TierDoesNotExist();
  error CannotDowngradeTier();
  error TierAlreadyExists();
  error NameAlreadyExists();
  error OnlyOwnerCanKickAdmin();
  error OnlyOwnerOrSelf();
  error OnlyAdminsOrOwnerCanKickMember();
  error ClanDestroyFailedHasMembers();
  error PriceTooLow();
  error MemberCapacityTooLow();
  error BankCapacityTooLow();
  error ImageIdTooLow();
  error AlreadySentInvite();
  error AlreadySentJoinRequest();

  struct PlayerInfo {
    uint32 clanId; // What clan they are in
    uint32 requestedClanId; // What clan they have requested to join
  }

  struct Tier {
    uint8 id;
    uint16 maxMemberCapacity;
    uint16 maxBankCapacity;
    uint24 maxImageId;
    uint40 minimumAge; // How old the clan must be before it can be upgraded to this tier
    uint80 price;
  }

  modifier isOwnerOfPlayer(uint _playerId) {
    if (!players.isOwnerOfPlayer(msg.sender, _playerId)) {
      revert NotOwnerOfPlayer();
    }
    _;
  }

  modifier isOwnerOfPlayerAndActive(uint _playerId) {
    if (!players.isOwnerOfPlayerAndActive(msg.sender, _playerId)) {
      revert NotOwnerOfPlayerAndActive();
    }
    _;
  }

  modifier onlyClanAdmin(uint _clanId, uint _playerId) {
    if (!clans[_clanId].admins[_playerId]) {
      revert OnlyAdmin();
    }
    _;
  }

  modifier isMemberOfClan(uint _clanId, uint _playerId) {
    if (!clans[_clanId].members[_playerId]) {
      revert NotMemberOfClan();
    }
    _;
  }

  IBrushToken private brushToken;
  IPlayers private players;
  IBankFactory public bankFactory;
  address private pool;
  uint public nextClanId;
  mapping(uint clanId => Clan clan) public clans;
  mapping(uint playerId => PlayerInfo) public playerInfo;
  mapping(uint id => Tier tier) public tiers;
  mapping(string name => bool exists) public lowercaseNames;
  mapping(uint clanId => uint40 timestampLeft) public ownerlessClanTimestamps; // timestamp

  // TODO Permissions

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(IBrushToken _brushToken, address _pool) external initializer {
    __UUPSUpgradeable_init();
    __Ownable_init();
    brushToken = _brushToken;
    pool = _pool;
    nextClanId = 1;
  }

  function createClan(
    uint _playerId,
    string calldata _name,
    uint24 _imageId,
    uint8 _tierId
  ) external isOwnerOfPlayerAndActive(_playerId) {
    PlayerInfo storage player = playerInfo[_playerId];
    if (player.clanId != 0) {
      revert AlreadyInClan();
    }

    Tier storage tier = tiers[_tierId];
    if (tier.id != _tierId) {
      revert InvalidTier();
    }

    _checkClanSettings(_imageId, tier.maxImageId);

    uint clanId = nextClanId++;
    Clan storage clan = clans[clanId];
    clan.owner = uint80(_playerId);
    clan.tierId = _tierId;
    clan.imageId = _imageId;
    clan.members[_playerId] = true;
    clan.memberCount = 1;
    clan.admins[_playerId] = true;
    clan.adminCount = 1;
    clan.createdTimestamp = uint40(block.timestamp);

    player.clanId = uint32(clanId);
    if (player.requestedClanId != 0) {
      removeJoinRequest(clanId, _playerId);
    }

    _setName(clanId, _name);
    emit ClanCreated(clanId, _playerId, _name, _imageId, _tierId);
    if (_tierId != 1) {
      _upgradeClan(clanId, _playerId, _tierId);
    }

    bankFactory.createBank(msg.sender, clanId);
  }

  function _checkClanSettings(uint _imageId, uint _maxImageId) private pure {
    if (_imageId == 0 || _imageId > _maxImageId) {
      revert InvalidImageId();
    }
  }

  function _setName(uint _clanId, string calldata _name) private {
    if (bytes(_name).length == 0 || bytes(_name).length > 20) {
      revert InvalidName();
    }

    string memory lowercaseName = _toLower(_name);
    if (lowercaseNames[lowercaseName]) {
      revert NameAlreadyExists();
    }
    lowercaseNames[lowercaseName] = true;
    string storage oldName = clans[_clanId].name;
    if (bytes(oldName).length > 0) {
      delete lowercaseNames[oldName];
    }
    clans[_clanId].name = _name;
  }

  function editClan(
    uint _clanId,
    uint _playerId,
    string calldata _name,
    uint _imageId
  ) external isOwnerOfPlayer(_playerId) {
    Clan storage clan = clans[_clanId];
    Tier storage tier = tiers[clan.tierId];
    _checkClanSettings(_imageId, tier.maxImageId);
    _setName(_clanId, _name);
    emit ClanEdited(_clanId, _playerId, _name, _imageId);
  }

  function editClanAsAdmin(
    uint _clanId,
    uint _playerId,
    uint _imageId
  ) external isOwnerOfPlayer(_playerId) onlyClanAdmin(_clanId, _playerId) {
    Clan storage clan = clans[_clanId];
    Tier storage tier = tiers[clan.tierId];
    _checkClanSettings(_imageId, tier.maxImageId);
    emit ClanEdited(_clanId, _playerId, clan.name, _imageId);
  }

  function _addAdmin(uint _clanId, uint _admin) private {
    Clan storage clan = clans[_clanId];
    clan.admins[_admin] = true;
    ++clan.adminCount;
    emit AdminAdded(_clanId, _admin);
  }

  function addAdmin(uint _clanId, uint _admin) public isOwnerOfPlayer(clans[_clanId].owner) {
    Clan storage clan = clans[_clanId];

    if (!clan.members[_admin]) {
      revert NotMemberOfClan();
    }

    if (clan.admins[_admin]) {
      revert PlayerAlreadyAdmin();
    }
    _addAdmin(_clanId, _admin);
  }

  function _removeAdmin(uint _clanId, uint _admin) private {
    Clan storage clan = clans[_clanId];
    // Check they are an admin first
    if (!clan.admins[_admin]) {
      revert NotAdmin();
    }

    // Make sure the owner isn't trying to remove themselves
    if (_admin == clan.owner) {
      revert CannotBeCalledOnOwner();
    }

    clan.admins[_admin] = false;
    --clan.adminCount;
    emit AdminRemoved(_clanId, _admin);
  }

  function removeAdmin(uint _clanId, uint _admin) external {
    if (!players.isOwnerOfPlayer(msg.sender, clans[_clanId].owner) && !players.isOwnerOfPlayer(msg.sender, _admin)) {
      revert OnlyOwnerOrSelf();
    }

    _removeAdmin(_clanId, _admin);
  }

  function inviteMember(
    uint _clanId,
    uint _member,
    uint _playerId
  ) external isOwnerOfPlayer(_playerId) onlyClanAdmin(_clanId, _playerId) {
    Clan storage clan = clans[_clanId];

    Tier storage tier = tiers[clan.tierId];

    if (clan.memberCount >= tier.maxMemberCapacity) {
      revert ClanIsFull();
    }

    if (clan.inviteRequests[_member]) {
      revert AlreadySentInvite();
    }

    clan.inviteRequests[_member] = true;
    emit InviteSent(_clanId, _member, _playerId);
  }

  function acceptInvite(uint _clanId, uint _playerId) external isOwnerOfPlayerAndActive(_playerId) {
    Clan storage clan = clans[_clanId];
    PlayerInfo storage player = playerInfo[_playerId];

    if (!clan.inviteRequests[_playerId]) {
      revert NoInviteRequest();
    }

    clan.inviteRequests[_playerId] = false;
    ++clan.memberCount;
    clan.members[_playerId] = true;

    player.clanId = uint32(_clanId);
    player.requestedClanId = 0;

    emit InviteAccepted(_clanId, _playerId);
  }

  function _destroyClan(uint _clanId) private {
    if (clans[_clanId].memberCount != 0) {
      // Defensive check
      revert ClanDestroyFailedHasMembers();
    }
    lowercaseNames[_toLower(clans[_clanId].name)] = false; // Name can be used again
    delete clans[_clanId]; // Delete the clan
    emit ClanDestroyed(_clanId);
  }

  function _removeFromClan(uint _clanId, uint _playerId) private {
    Clan storage clan = clans[_clanId];
    PlayerInfo storage player = playerInfo[_playerId];

    if (player.clanId != _clanId) {
      revert NotInClan();
    }

    if (clan.owner == _playerId) {
      clan.owner = 0;
      ownerlessClanTimestamps[_clanId] = uint40(block.timestamp);
      emit ClanOwnerLeft(_clanId, _playerId);
    }
    if (clans[_clanId].admins[_playerId]) {
      _removeAdmin(_clanId, _playerId);
    }

    --clan.memberCount;
    if (clan.memberCount == 0) {
      _destroyClan(_clanId);
    } else {
      clan.members[_playerId] = false;
      emit MemberLeft(_clanId, _playerId);
    }
    player.clanId = 0;
  }

  function leaveClan(uint _clanId, uint _playerId) external isOwnerOfPlayerAndActive(_playerId) {
    _removeFromClan(_clanId, _playerId);
  }

  function requestToJoin(uint _clanId, uint _playerId) external isOwnerOfPlayerAndActive(_playerId) {
    Clan storage clan = clans[_clanId];
    if (clan.createdTimestamp == 0) {
      revert ClanDoesNotExist();
    }

    PlayerInfo storage player = playerInfo[_playerId];

    if (player.clanId != 0) {
      revert AlreadyInClan();
    }

    if (player.requestedClanId != 0) {
      if (player.requestedClanId == _clanId) {
        revert AlreadySentJoinRequest();
      }
      emit JoinRequestRemoved(player.requestedClanId, _playerId);
    }

    player.requestedClanId = uint32(_clanId);

    emit JoinRequestSent(_clanId, _playerId);
  }

  function removeJoinRequest(uint _clanId, uint _playerId) public isOwnerOfPlayer(_playerId) {
    playerInfo[_playerId].requestedClanId = 0;
    emit JoinRequestRemoved(_clanId, _playerId);
  }

  function acceptJoinRequest(
    uint _clanId,
    uint _member,
    uint _playerId
  ) public isOwnerOfPlayerAndActive(_playerId) onlyClanAdmin(_clanId, _playerId) {
    Clan storage clan = clans[_clanId];
    PlayerInfo storage player = playerInfo[_member];

    if (clan.inviteRequests[_member]) {
      revert NoInviteRequest();
    }

    clan.inviteRequests[_member] = false;
    clan.memberCount++;
    clan.members[_member] = true;

    player.clanId = uint32(_clanId);
    player.requestedClanId = 0;

    emit JoinRequestAccepted(_clanId, _member, _playerId);
  }

  function kickMember(uint _clanId, uint _member, uint playerId) external isOwnerOfPlayerAndActive(playerId) {
    // Only owner can kick an admin
    if (clans[_clanId].admins[_member] && clans[_clanId].owner != playerId) {
      revert OnlyOwnerCanKickAdmin();
    }
    if (clans[_clanId].owner == _member) {
      revert CannotBeCalledOnOwner();
    }

    // Only admins or owner can kick a member
    if (!clans[_clanId].admins[playerId] && clans[_clanId].owner != playerId) {
      revert OnlyAdminsOrOwnerCanKickMember();
    }
    _removeFromClan(_clanId, _member);
  }

  function isClanAdmin(uint _clanId, uint _playerId) external view override returns (bool) {
    return clans[_clanId].admins[_playerId];
  }

  function isClanMember(uint _clanId, uint _playerId) external view returns (bool) {
    return clans[_clanId].members[_playerId];
  }

  function hasInviteRequest(uint _clanId, uint _playerId) external view returns (bool) {
    return clans[_clanId].inviteRequests[_playerId];
  }

  function maxBankCapacity(uint _clanId) external view override returns (uint16) {
    Tier storage tier = tiers[clans[_clanId].tierId];
    return tier.maxBankCapacity;
  }

  function maxMemberCapacity(uint _clanId) external view override returns (uint16) {
    Tier storage tier = tiers[clans[_clanId].tierId];
    return tier.maxMemberCapacity;
  }

  function _claimOwnership(uint _clanId, uint _playerId) private {
    Clan storage clan = clans[_clanId];
    clan.owner = uint80(_playerId);
    delete ownerlessClanTimestamps[_clanId];

    if (!clan.admins[_playerId]) {
      _addAdmin(_clanId, _playerId);
    }
    emit ClanOwnershipTransferred(_clanId, _playerId);
  }

  function renonuceOwnershipTo(
    uint _clanId,
    uint _admin,
    bool _leaveClan
  ) external isOwnerOfPlayer(clans[_clanId].owner) onlyClanAdmin(_clanId, _admin) {
    Clan storage clan = clans[_clanId];
    uint oldOwnerPlayerId = clan.owner;
    _removeFromClan(_clanId, clan.owner);
    if (!_leaveClan) {
      // Add as a member
      ++clan.memberCount;
      clan.members[oldOwnerPlayerId] = true;
      playerInfo[oldOwnerPlayerId].clanId = uint32(_clanId);
      // Add as an admin
      _addAdmin(_clanId, _admin);
    }
    _claimOwnership(_clanId, _admin);
  }

  // Can claim a clan if there is no owner. Must be an admin if there are any admins, otherwise can be any member.
  function claimOwnership(
    uint _clanId,
    uint _playerId
  ) external isOwnerOfPlayer(_playerId) isMemberOfClan(_clanId, _playerId) {
    Clan storage clan = clans[_clanId];
    if (clan.owner != 0) {
      revert OwnerExists();
    }

    if (clan.adminCount != 0) {
      // Must be an admin
      if (!clan.admins[_playerId]) {
        revert NotAdmin();
      }
    }

    _claimOwnership(_clanId, _playerId);
  }

  function _upgradeClan(uint _clanId, uint _playerId, uint8 _newTierId) private {
    Tier storage oldTier = tiers[clans[_clanId].tierId];
    if (oldTier.id == 0) {
      revert ClanDoesNotExist();
    }

    if (_newTierId <= oldTier.id) {
      revert CannotDowngradeTier();
    }

    Tier storage newTier = tiers[_newTierId];
    if (newTier.id == 0) {
      revert TierDoesNotExist();
    }

    uint priceDifference = newTier.price - oldTier.price;
    uint half = priceDifference / 2;
    brushToken.transferFrom(msg.sender, address(this), priceDifference);
    brushToken.burn(half);
    brushToken.transfer(pool, priceDifference - half);
    clans[_clanId].tierId = _newTierId; // Increase the tier
    emit ClanUpgraded(_clanId, _playerId, _newTierId);
  }

  function upgradeClan(uint _clanId, uint _playerId, uint8 _newTierId) public isOwnerOfPlayer(_playerId) {
    _upgradeClan(_clanId, _playerId, _newTierId);
  }

  function _toLower(string memory _name) private pure returns (string memory) {
    bytes memory lowercaseName = abi.encodePacked(_name);
    for (uint i; i < lowercaseName.length; ++i) {
      if ((uint8(lowercaseName[i]) >= 65) && (uint8(lowercaseName[i]) <= 90)) {
        // So we add 32 to make it lowercase
        lowercaseName[i] = bytes1(uint8(lowercaseName[i]) + 32);
      }
    }
    return string(lowercaseName);
  }

  function getClanName(uint _playerId) external view returns (string memory) {
    uint clanId = playerInfo[_playerId].clanId;
    return clans[clanId].name;
  }

  function _setTier(Tier calldata _tier) private {
    uint tierId = _tier.id;
    // TODO: Some other checks

    // Price should be higher than the one prior
    if (tierId > 1) {
      if (_tier.price < tiers[tierId - 1].price) {
        revert PriceTooLow();
      }
      if (_tier.maxMemberCapacity < tiers[tierId - 1].maxMemberCapacity) {
        revert MemberCapacityTooLow();
      }
      if (_tier.maxBankCapacity < tiers[tierId - 1].maxBankCapacity) {
        revert BankCapacityTooLow();
      }
      if (_tier.maxImageId < tiers[tierId - 1].maxImageId) {
        revert ImageIdTooLow();
      }
    }
    tiers[tierId] = _tier;
  }

  function addTiers(Tier[] calldata _tiers) external onlyOwner {
    for (uint i = 0; i < _tiers.length; ++i) {
      if (tiers[_tiers[i].id].id != 0 || _tiers[i].id == 0) {
        revert TierAlreadyExists();
      }
      _setTier(_tiers[i]);
    }
    emit AddTiers(_tiers);
  }

  function editTier(Tier calldata _tier) external onlyOwner {
    uint tierId = _tier.id;
    if (tiers[tierId].id == 0) {
      revert TierDoesNotExist();
    }
    _setTier(_tier);
    emit EditTier(_tier);
  }

  function setBankFactory(IBankFactory _bankFactory) external onlyOwner {
    bankFactory = _bankFactory;
  }

  function setPlayers(IPlayers _players) external onlyOwner {
    players = _players;
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}
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
  uint32 diff; // This can be uint16.
  uint32 rate; // This can be uint16. Rate of output produced per hour (base 10) 1 decimal
  uint24 xpPerHour;
  uint16 inputTokenId1;
  uint8 num1;
  uint16 inputTokenId2;
  uint8 num2;
  uint16 inputTokenId3;
  uint8 num3;
  uint16 outputTokenId;
  uint8 outputNum;
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
  uint40 startTime; // When the queued action started
  bool isValid; // If we still have the item, TODO: Not used yet
  uint64 queueId; // id of this queued action
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

struct Attire {
  uint16 head;
  uint16 neck;
  uint16 body;
  uint16 arms;
  uint16 legs;
  uint16 feet;
  uint16 ring;
  uint16 reserved1;
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
  uint128 totalXP;
  Skill skillBoosted1;
  Skill skillBoosted2;
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
  Skill skill1; // This is related to skillDiff1 (here to keep packing constant as this replaces an old field)
  uint8 skillDiff1;
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

struct EquipmentInfo {
  uint16 actionId;
  uint64 queueId;
  uint24 elapsedTime;
  uint16 itemTokenId;
  uint24 amount;
}

struct XPInfo {
  uint16 actionId;
  uint64 queueId;
  uint24 elapsedTime;
  uint32 xp;
}

struct DiedInfo {
  uint16 actionId;
  uint64 queueId;
  uint24 elapsedTime;
}

struct RollInfo {
  uint16 actionId;
  uint64 queueId;
  uint24 elapsedTime;
  uint32 numRolls;
}

struct PastRandomRewardInfo {
  uint16 actionId;
  uint64 queueId;
  uint16 itemTokenId;
  uint24 amount;
}

// This is only for viewing so doesn't need to be optimized
struct PendingQueuedActionState {
  EquipmentInfo[] consumed;
  EquipmentInfo[] produced;
  PastRandomRewardInfo[] producedPastRandomRewards;
  Equipment[] producedXPRewards;
  Equipment[] questRewards;
  Equipment[] questConsumed;
  PlayerQuest[] activeQuestInfo;
  DiedInfo[] died;
  RollInfo[] rolls;
  XPInfo[] xpGained;
}

// External view functions that are in other implementation files
interface IPlayersRewardsDelegateView {
  function pendingQueuedActionStateImpl(
    address _owner,
    uint _playerId
  ) external view returns (PendingQueuedActionState memory pendingQueuedActionState);

  function dailyClaimedRewardsImpl(uint _playerId) external view returns (bool[7] memory claimed);
}

interface IPlayersQueueActionsDelegateView {
  function claimableXPThresholdRewardsImpl(
    uint oldTotalXP,
    uint newTotalXP
  ) external view returns (uint[] memory itemTokenIds, uint[] memory amounts);
}

struct FullAttireBonusInput {
  Skill skill;
  uint8 bonusXPPercent;
  uint8 bonusRewardsPercent; // 3 = 3%
  uint16[5] itemTokenIds; // 0 = head, 1 = body, 2 arms, 3 body, 4 = feet
}

struct Quest {
  uint16 dependentQuestId; // The quest that must be completed before this one can be started
  uint16 actionId; // action to do
  uint16 actionNum; // how many (up to 65535)
  uint16 actionId1; // another action to do
  uint16 actionNum1; // how many (up to 65535)
  uint16 actionChoiceId; // actionChoice to perform
  uint16 actionChoiceNum; // how many to do (base number), (up to 65535)
  Skill skillReward; // The skill to reward XP to
  uint16 skillXPGained; // The amount of XP to give (up to 65535)
  uint16 rewardItemTokenId; // Reward an item
  uint16 rewardAmount; // amount of the reward (up to 65535)
  uint16 rewardItemTokenId1; // Reward another item
  uint16 rewardAmount1; // amount of the reward (up to 65535)
  uint16 burnItemTokenId; // Burn an item
  uint16 burnAmount; // amount of the burn (up to 65535)
  uint24 questId; // Unique id for this quest
}

struct PlayerQuest {
  uint32 questId;
  uint24 actionCompletedNum;
  uint24 actionCompletedNum1;
  uint24 actionChoiceCompletedNum;
  bool isFixed;
}

// 4 bytes for each threshold, starts at 500 xp in decimal
bytes constant xpRewardBytes = hex"00000000000001F4000003E8000009C40000138800002710000075300000C350000186A00001D4C0000493E0000557300007A120000927C0000B71B0";

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IBankFactory {
  function bankAddress(uint clanId) external view returns (address);

  function createdHere(address bank) external view returns (bool);

  function createBank(address from, uint clanId) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBrushToken is IERC20 {
  function burn(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct Clan {
  uint80 owner; // player id
  uint24 imageId;
  uint16 memberCount;
  uint16 adminCount;
  uint40 createdTimestamp;
  uint8 tierId;
  string name;
  mapping(uint playerId => bool onlyClanAdmin) admins;
  mapping(uint playerId => bool isMember) members;
  mapping(uint playerId => bool invited) inviteRequests;
}

interface IClans {
  function isClanAdmin(uint clanId, uint playerId) external view returns (bool);

  function maxBankCapacity(uint clanId) external view returns (uint16);

  function maxMemberCapacity(uint clanId) external view returns (uint16);
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

  function mintedPlayer(address from, uint playerId, Skill[2] calldata startSkills, bool makeActive) external;

  function isOwnerOfPlayer(address from, uint playerId) external view returns (bool);

  function isOwnerOfPlayerAndActive(address from, uint playerId) external view returns (bool);
}