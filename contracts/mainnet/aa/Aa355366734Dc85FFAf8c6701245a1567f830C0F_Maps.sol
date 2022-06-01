/**
 *Submitted for verification at FtmScan.com on 2022-06-01
*/

// File: @openzeppelin/contracts/utils/math/SignedMath.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol

// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
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
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
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
    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
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
    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
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
    function values(Bytes32Set storage set)
        internal
        view
        returns (bytes32[] memory)
    {
        return _values(set._inner);
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
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
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
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
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
    function values(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

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
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
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
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
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
    function values(UintSet storage set)
        internal
        view
        returns (uint256[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// File: contracts/storage/_LandStorage.sol

pragma solidity ^0.8.13;

contract _LandStorage {
    using EnumerableSet for EnumerableSet.UintSet;

    uint8 public constant MAP_X = 120;
    uint8 public constant MAP_Y = 120;
    uint8 public constant BIOMES_NUMBER = 20;
    uint8 internal constant BIOMES_ATTR_NUMBER = 8;
    uint8 internal constant ACRE_ATTR_NUMBER = 3;
    uint8 internal constant ACRE_X = 0;
    uint8 internal constant ACRE_Y = 1;
    uint8 internal constant ACRE_HQ = 2;
    uint8 internal constant ACRE_TYPE = 2;
    uint8 internal constant MAP_ATTR_NUMBER = 3;
    uint8 internal constant N_VALID = 2;
    uint8 internal constant N_ATTR = 3;
    uint8 internal constant N_NUM = 6;
    uint16 internal constant EMPTY_FARM = FARMS_NUMBER + 1;
    uint16 public constant FARMS_NUMBER = 400;
    address internal constant ZERO_ADDRESS = address(0);
    bytes32 internal constant LAND_STORAGE_POSITION =
        keccak256("games.wolfland.contracts.landstorage");

    struct LandStorage {
        Acre[MAP_Y][MAP_X] map;
        uint96[BIOMES_ATTR_NUMBER][BIOMES_NUMBER] biomes;
        Farm[FARMS_NUMBER] farms;
        address[FARMS_NUMBER] ownedFarms;
        mapping(uint256 => uint16) lands;
        EnumerableSet.UintSet vacantFarms;
    }

    struct Farm {
        uint8[ACRE_ATTR_NUMBER][] acres;
        uint256 hq;
        string image;
    }

    struct Acre {
        uint8 biome;
        uint16 farmId;
    }

    function landStorage() internal pure returns (LandStorage storage ls) {
        bytes32 position = LAND_STORAGE_POSITION;
        assembly {
            ls.slot := position
        }
    }
}

// File: contracts/utils/Maps.sol

pragma solidity ^0.8.0;

library Maps {
    using EnumerableSet for EnumerableSet.UintSet;

    uint8 private constant ACRE_X = 0;
    uint8 private constant ACRE_Y = 1;
    uint8 private constant MAP_X = 120;
    uint8 private constant MAP_Y = 120;
    uint8 private constant X = 0;
    uint8 private constant Y = 1;
    uint8 private constant N_VALID = 2;
    uint8 private constant N_ATTR = 3;
    uint8 private constant N_NUM = 6;
    uint16 private constant EMPTY_FARM = FARMS_NUMBER + 1;
    uint16 private constant FARMS_NUMBER = 400;
    address internal constant ZERO_ADDRESS = address(0);
    bytes32 private constant LAND_STORAGE_POSITION =
        keccak256("games.wolfland.contracts.landstorage");

    function getNeighbors(uint8 x, uint8 y)
        public
        pure
        returns (uint8[N_ATTR][N_NUM] memory)
    {
        uint256 size = 0;
        uint8[N_ATTR][N_NUM] memory neighbors;
        if (y > 0) {
            neighbors[size][X] = x;
            neighbors[size][Y] = y - 1;
            neighbors[size][N_VALID] = 1;
            size++;
        }
        if (y < (MAP_Y - 1)) {
            neighbors[size][X] = x;
            neighbors[size][Y] = y + 1;
            neighbors[size][N_VALID] = 1;
            size++;
        }
        if (x < (MAP_X - 1)) {
            neighbors[size][X] = x + 1;
            neighbors[size][Y] = y;
            neighbors[size][N_VALID] = 1;
            size++;
            if (x % 2 == 0) {
                if (y > 0) {
                    neighbors[size][X] = x + 1;
                    neighbors[size][Y] = y - 1;
                    neighbors[size][N_VALID] = 1;
                    size++;
                }
            } else {
                if (y < (MAP_Y - 1)) {
                    neighbors[size][X] = x + 1;
                    neighbors[size][Y] = y + 1;
                    neighbors[size][N_VALID] = 1;
                    size++;
                }
            }
        }
        if (x > 0) {
            neighbors[size][X] = x - 1;
            neighbors[size][Y] = y;
            neighbors[size][N_VALID] = 1;
            size++;

            if (x % 2 == 0) {
                if (y > 0) {
                    neighbors[size][X] = x - 1;
                    neighbors[size][Y] = y - 1;
                    neighbors[size][N_VALID] = 1;
                }
            } else {
                if (y < (MAP_Y - 1)) {
                    neighbors[size][X] = x - 1;
                    neighbors[size][Y] = y + 1;
                    neighbors[size][N_VALID] = 1;
                }
            }
        }
        return neighbors;
    }

    function getDistance(
        uint8 x1,
        uint8 y1,
        uint8 x2,
        uint8 y2
    ) external pure returns (uint256 distance) {
        int256 _q;
        int256 _r;
        int256 q;
        int256 r;
        (_q, _r) = _axial(x1, y1);
        (q, r) = _axial(x2, y2);
        return
            (SignedMath.abs(_q - q) +
                SignedMath.abs(_q + _r - q - r) +
                SignedMath.abs(_r - r)) / 2;
    }

    function canBuy(
        uint8 x,
        uint8 y,
        uint16 farmId
    ) external view returns (bool) {
        _LandStorage.LandStorage storage ls = _landStorage();
        uint16 target = ls.map[x][y].farmId;
        if (
            target != EMPTY_FARM &&
            (ls.ownedFarms[target] != ZERO_ADDRESS ||
                ls.vacantFarms.contains(target))
        ) {
            return false;
        }
        uint8[N_ATTR][N_NUM] memory neighbors = getNeighbors(x, y);
        for (uint256 i = 0; i < N_NUM; i++) {
            if (
                neighbors[i][N_VALID] == 1 &&
                ls.map[neighbors[i][ACRE_X]][neighbors[i][ACRE_Y]].farmId ==
                farmId
            ) {
                return true;
            }
        }
        return false;
    }

    function _landStorage()
        private
        pure
        returns (_LandStorage.LandStorage storage ls)
    {
        bytes32 position = LAND_STORAGE_POSITION;
        assembly {
            ls.slot := position
        }
    }

    function _axial(uint256 x, uint256 y)
        private
        pure
        returns (int256 q, int256 r)
    {
        q = int256(x);
        r = int256(y) - int256((x - (x % 2)) / 2);
    }
}