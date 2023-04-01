// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./IPaymentTokenRegistry.sol";

contract PaymentTokenRegistry is IPaymentTokenRegistry, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    uint32 private _currentIncrementalId;
    mapping(uint32 => address) paymentTokenRecords;
    mapping(address => uint32) paymentTokenIds;

    EnumerableSet.UintSet private _globalPaymentTokenIds;
    mapping(address => EnumerableSet.UintSet)
        private _collectionPaymentTokenIds;

    /**
     * @dev See {IPaymentTokenRegistry-isAllowedPaymentToken}.
     */
    function isAllowedPaymentToken(
        address collectionAddress,
        uint32 paymentTokenId
    ) external view returns (bool) {
        return
            _globalPaymentTokenIds.contains(paymentTokenId) ||
            _collectionPaymentTokenIds[collectionAddress].contains(
                paymentTokenId
            );
    }

    /**
     * @dev See {IPaymentTokenRegistry-getPaymentTokenIdByAddress}.
     */
    function getPaymentTokenIdByAddress(
        address token
    ) external view returns (uint32) {
        return paymentTokenIds[token];
    }

    /**
     * @dev See {IPaymentTokenRegistry-getPaymentTokenAddressById}.
     */
    function getPaymentTokenAddressById(
        uint32 id
    ) external view returns (address) {
        return paymentTokenRecords[id];
    }

    /**
     * @dev See {IPaymentTokenRegistry-globalAllowedPaymentTokens}.
     */
    function globalAllowedPaymentTokens()
        external
        view
        returns (PaymentTokenRecord[] memory paymentTokens)
    {
        paymentTokens = new PaymentTokenRecord[](
            _globalPaymentTokenIds.length()
        );

        for (uint256 i; i < _globalPaymentTokenIds.length(); i++) {
            uint32 id = uint32(_globalPaymentTokenIds.at(i));
            paymentTokens[i] = PaymentTokenRecord(id, paymentTokenRecords[id]);
        }
    }

    /**
     * @dev See {IPaymentTokenRegistry-allowedPaymentTokensOfCollection}.
     */
    function allowedPaymentTokensOfCollection(
        address collectionAddress
    ) external view returns (PaymentTokenRecord[] memory paymentTokens) {
        uint256 tokenCount = _collectionPaymentTokenIds[collectionAddress]
            .length();
        paymentTokens = new PaymentTokenRecord[](tokenCount);

        for (uint256 i; i < tokenCount; i++) {
            uint32 id = uint32(
                _collectionPaymentTokenIds[collectionAddress].at(i)
            );
            paymentTokens[i] = PaymentTokenRecord(id, paymentTokenRecords[id]);
        }
    }

    /**
     * @dev See {IPaymentTokenRegistry-addGlobalPaymentToken}.
     */
    function addPaymentTokenRecord(address token) external onlyOwner {
        require(
            paymentTokenIds[token] == 0,
            "PaymentTokenRegistry: token already exist"
        );

        _currentIncrementalId += 1;
        paymentTokenRecords[_currentIncrementalId] = token;
        paymentTokenIds[token] = _currentIncrementalId;

        emit PaymentTokenRecoredAdded(
            _currentIncrementalId,
            token,
            _msgSender()
        );
    }

    /**
     * @dev See {IPaymentTokenRegistry-addGlobalPaymentToken}.
     */
    function addGlobalPaymentToken(uint32 id) external onlyOwner {
        require(
            !_globalPaymentTokenIds.contains(id),
            "PaymentTokenRegistry: token already exist"
        );

        _globalPaymentTokenIds.add(id);

        emit GlobalPaymentTokenAdded(id, paymentTokenRecords[id], _msgSender());
    }

    /**
     * @dev See {IPaymentTokenRegistry-removeGlobalPaymentToken}.
     */
    function removeGlobalPaymentToken(uint32 id) external onlyOwner {
        require(
            _globalPaymentTokenIds.contains(id),
            "PaymentTokenRegistry: token doesn't exist"
        );

        _globalPaymentTokenIds.remove(id);

        emit GlobalPaymentTokenRemoved(
            id,
            paymentTokenRecords[id],
            _msgSender()
        );
    }

    /**
     * @dev See {IPaymentTokenRegistry-addCollectionPaymentToken}.
     */
    function addCollectionPaymentToken(
        address collectionAddress,
        uint32 id
    ) external onlyOwner {
        require(
            !_collectionPaymentTokenIds[collectionAddress].contains(id),
            "PaymentTokenRegistry: token already exist for this collection"
        );

        _collectionPaymentTokenIds[collectionAddress].add(id);

        emit CollectionPaymentTokenAdded(
            collectionAddress,
            id,
            paymentTokenRecords[id],
            _msgSender()
        );
    }

    /**
     * @dev See {IPaymentTokenRegistry-removeCollectionPaymentToken}.
     */
    function removeCollectionPaymentToken(
        address collectionAddress,
        uint32 id
    ) external onlyOwner {
        require(
            _collectionPaymentTokenIds[collectionAddress].contains(id),
            "PaymentTokenRegistry: token doesn't exist for this collection"
        );

        _collectionPaymentTokenIds[collectionAddress].remove(id);

        emit CollectionPaymentTokenRemoved(
            collectionAddress,
            id,
            paymentTokenRecords[id],
            _msgSender()
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./IPaymentTokenReader.sol";

interface IPaymentTokenRegistry is IPaymentTokenReader {
    struct PaymentTokenRecord {
        uint32 id;
        address token;
    }

    event PaymentTokenRecoredAdded(uint32 id, address token, address sender);
    event PaymentTokenRecoredRemoved(uint32 id, address token, address sender);

    event GlobalPaymentTokenAdded(uint32 id, address token, address sender);

    event GlobalPaymentTokenRemoved(uint32 id, address token, address sender);

    event CollectionPaymentTokenAdded(
        address collectionAddress,
        uint32 id,
        address token,
        address sender
    );

    event CollectionPaymentTokenRemoved(
        address collectionAddress,
        uint32 id,
        address token,
        address sender
    );

    /**
     * @dev get list of globally allowed payment tokens
     */
    function globalAllowedPaymentTokens()
        external
        view
        returns (PaymentTokenRecord[] memory);

    /**
     * @dev get list of allowed payment tokens for a collection
     * this doesn't include globally allowed ones
     */
    function allowedPaymentTokensOfCollection(
        address collectionAddress
    ) external view returns (PaymentTokenRecord[] memory);

    /**
     * @dev add payment tokens records
     */
    function addPaymentTokenRecord(address token) external;

    /**
     * @dev add globally allowed payment tokens
     */
    function addGlobalPaymentToken(uint32 id) external;

    /**
     * @dev remove globally allowed payment tokens
     */
    function removeGlobalPaymentToken(uint32 id) external;

    /**
     * @dev add allowed payment tokens to collection
     */
    function addCollectionPaymentToken(
        address collectionAddress,
        uint32 id
    ) external;

    /**
     * @dev remove allowed payment tokens from collection
     */
    function removeCollectionPaymentToken(
        address collectionAddress,
        uint32 id
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

interface IPaymentTokenReader {
    /**
     * @dev Check if a payment token is allowed for a collection
     */
    function isAllowedPaymentToken(
        address collectionAddress,
        uint32 paymentTokenId
    ) external view returns (bool);

    /**
     * @dev get payment token id by address
     */
    function getPaymentTokenIdByAddress(
        address token
    ) external view returns (uint32);

    /**
     * @dev get payment token address by id
     */
    function getPaymentTokenAddressById(
        uint32 id
    ) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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