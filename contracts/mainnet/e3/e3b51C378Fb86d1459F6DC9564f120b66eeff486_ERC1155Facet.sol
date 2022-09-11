// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\__0xFluffyBeard__/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\____vbranden___/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

interface SharedErrors {
    error NotImplemented();
    error ArrayLengthNotTheSame(uint256 array1Length, uint256 array2Length);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.9;

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
library LibContext {
    function msgSender() internal view returns (address) {
        return msg.sender;
    }

    function msgData() internal view returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\__0xFluffyBeard__/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\____vbranden___/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import {LibRoles} from "./LibRoles.sol";
import {LibContext} from "../../libraries/LibContext.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @dev Library version of the OpenZeppelin AccessControlEnumerable contract with Diamond storage.
 * See: https://docs.openzeppelin.com/contracts/4.x/api/access#AccessControl
 * See: https://docs.openzeppelin.com/contracts/4.x/api/access#AccessControlEnumerable
 * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol
 * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControlEnumerable.sol
 */
library LibAccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct Storage {
        mapping(bytes32 => RoleData) roles;
        mapping(bytes32 => EnumerableSet.AddressSet) roleMembers;
    }

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes32 private constant STORAGE_SLOT =
        keccak256("solarprotocol.contracts.access.LibAccessControl");

    /**
     * @dev Returns the storage.
     */
    function _storage() private pure returns (Storage storage s) {
        bytes32 slot = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := slot
        }
    }

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        internal
        view
        returns (bool)
    {
        return
            _storage().roles[role].members[account] ||
            _storage().roles[getRoleAdmin(role)].members[account];
    }

    /**
     * @dev Revert with a standard message if `LibContext.msgSender()` is missing `role`.
     * @notice This function is identical to {checkRole} but is following the naming convention.
     */
    function enforceRole(bytes32 role) internal view {
        checkRole(role, LibContext.msgSender());
    }

    /**
     * @dev Revert with a standard message if `LibContext.msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {checkRole}.
     *
     * _Available since v4.6._
     */
    function checkRole(bytes32 role) internal view {
        checkRole(role, LibContext.msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) internal view returns (bytes32) {
        return _storage().roles[role].adminRole;
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _storage().roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function grantRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) {
            _storage().roles[role].members[account] = true;
            _storage().roleMembers[role].add(account);
            emit RoleGranted(role, account, LibContext.msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            _storage().roles[role].members[account] = false;
            _storage().roleMembers[role].remove(account);
            emit RoleRevoked(role, account, LibContext.msgSender());
        }
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index)
        internal
        view
        returns (address)
    {
        return _storage().roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) internal view returns (uint256) {
        return _storage().roleMembers[role].length();
    }
}

// SPDX-License-Identifier: MIT

//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\__0xFluffyBeard__/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\____vbranden___/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

/**
 * @dev Library with a set of default roles to use across different other contracts.
 */
library LibRoles {
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant BLACKLIST_MANAGER_ROLE =
        keccak256("BLACKLIST_MANAGER_ROLE");
    bytes32 public constant PAUSE_MANAGER_ROLE =
        keccak256("PAUSE_MANAGER_ROLE");
    bytes32 public constant STABLE_PRICE_MANAGER_ROLE =
        keccak256("STABLE_PRICE_MANAGER_ROLE");
    bytes32 public constant TESTER_ROLE = keccak256("TESTER_ROLE");
}

// SPDX-License-Identifier: MIT

//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\__0xFluffyBeard__/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\____vbranden___/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

/*
 * @dev External interface of a simple blacklist.
 */
interface ISimpleBlacklist {
    /*
     * @dev Emitted when an address was added to the blacklist
     * @param account The address of the account added to the blacklist
     * @param reason The reason string
     */
    event Blacklisted(address indexed account, string indexed reason);

    /*
     * @dev Emitted when an address was removed from the blacklist
     * @param account The address of the account removed from the blacklist
     * @param reason The reason string
     */
    event UnBlacklisted(address indexed account, string indexed reason);

    /*
     * @dev Check if `account` is on the blacklist.
     */
    function isBlacklisted(address account) external view returns (bool);

    /*
     * @dev Check if any address in `accounts` is on the blacklist.
     */
    function isBlacklisted(address[] memory accounts)
        external
        view
        returns (bool);

    /*
     * @dev Adds `account` to the blacklist with `reason`.
     *
     * The `reason` is optional and can be an empty string.
     *
     * Emits {Blacklisted} event, if `account` was added to the blacklist.
     */
    function blacklist(address account, string calldata reason) external;

    /*
     * @dev Adds `accounts` to the blacklist with `reasons`.
     *
     * The `reasons` is optional and can be an array of empty strings.
     * Length of the `accounts`and `reasons` arrays must be equal.
     *
     * Emits {Blacklisted} events, for each account that was added to the blacklist
     */
    function blacklist(address[] calldata accounts, string[] calldata reasons)
        external;

    /*
     * @dev Removes `account` from the blacklist with `reason`.
     *
     * The `reason` is optional and can be an empty string.
     *
     * Emits {UnBlacklisted} event, if `account` was removed from the blacklist
     */
    function unblacklist(address account, string calldata reason) external;

    /*
     * @dev Removes multiple `accounts` from the blacklist with `reasons`.
     *
     * The `reasons` is optional and can be an array of empty strings.
     * Length of the `accounts`and `reasons` arrays must be equal.
     *
     * Emits {UnBlacklisted} events, for each account that was removed from the blacklist
     */
    function unblacklist(address[] calldata accounts, string[] calldata reasons)
        external;
}

// SPDX-License-Identifier: MIT

//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\__0xFluffyBeard__/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\____vbranden___/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import {ISimpleBlacklist} from "./ISimpleBlacklist.sol";
import {LibContext} from "../../libraries/LibContext.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

library LibSimpleBlacklist {
    struct Storage {
        mapping(address => bool) accounts;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("solarprotocol.contracts.blacklist.LibSimpleBlacklist");

    /**
     * @dev Returns the storage.
     */
    function _storage() private pure returns (Storage storage s) {
        bytes32 slot = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := slot
        }
    }

    /*
     * @dev Emitted when an address was added to the blacklist
     * @param account The address of the account added to the blacklist
     * @param reason The reason string
     */
    event Blacklisted(address indexed account, string indexed reason);

    /*
     * @dev Emitted when an address was removed from the blacklist
     * @param account The address of the account removed from the blacklist
     * @param reason The reason string
     */
    event UnBlacklisted(address indexed account, string indexed reason);

    /**
     * @dev Revert with a standard message if `LibContext.msgSender()` is blacklisted.
     */
    function enforceNotBlacklisted() internal view {
        checkBlacklisted(LibContext.msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is blacklisted.
     */
    function enforceNotBlacklisted(address account) internal view {
        checkBlacklisted(account);
    }

    /**
     * @dev Returns `true` if `account` is blacklisted.
     */
    function isBlacklisted(address account) internal view returns (bool) {
        return _storage().accounts[account];
    }

    /**
     * @dev Returns `true` if any address in `accounts` is on the blacklist.
     */
    function isBlacklisted(address[] memory accounts)
        internal
        view
        returns (bool)
    {
        for (uint256 index = 0; index < accounts.length; index++) {
            if (isBlacklisted(accounts[index])) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev Revert with a standard message if `account` is blacklisted.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^SimpleBlacklist: account (0x[0-9a-f]{40}) is blacklisted$/
     */
    function checkBlacklisted(address account) internal view {
        if (isBlacklisted(account)) {
            revert(
                string(
                    abi.encodePacked(
                        "SimpleBlacklist: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is blacklisted"
                    )
                )
            );
        }
    }

    /**
     * @dev Adds `account` to the blacklist.
     *
     * Internal function without access restriction.
     */
    function blacklist(address account, string memory reason) internal {
        if (!isBlacklisted(account)) {
            _storage().accounts[account] = true;
            emit Blacklisted(account, reason);
        }
    }

    /**
     * @dev Removes `account` from the blacklist.
     *
     * Internal function without access restriction.
     */
    function unblacklist(address account, string memory reason) internal {
        if (isBlacklisted(account)) {
            _storage().accounts[account] = false;
            emit UnBlacklisted(account, reason);
        }
    }
}

// SPDX-License-Identifier: MIT

//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\__0xFluffyBeard__/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\____vbranden___/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import {LibNft} from "../libraries/LibNft.sol";
import {IERC1155} from "../interfaces/IERC1155.sol";
import {LibContext} from "../../../libraries/LibContext.sol";
import {LibSimpleBlacklist} from "../../blacklist/LibSimpleBlacklist.sol";
import {LibPausable} from "../../pausable/LibPausable.sol";
import {SharedErrors} from "../../../SharedErrors.sol";

contract ERC1155Facet is IERC1155 {
    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256)
    {
        return LibNft.balanceOf(account, id);
    }

    /**
     * @dev Batched version of `balanceOf`.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory)
    {
        // solhint-disable-next-line reason-string
        require(
            accounts.length == ids.length,
            "ERC1155: accounts and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = LibNft.balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external {
        revert SharedErrors.NotImplemented();

        LibPausable.enforceNotPaused();
        LibSimpleBlacklist.enforceNotBlacklisted();
        LibSimpleBlacklist.enforceNotBlacklisted(operator);

        LibNft.setApprovalForAll(LibContext.msgSender(), operator, approved);
    }

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool)
    {
        return LibNft.isApprovedForAll(account, operator);
    }

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
    ) external {
        revert SharedErrors.NotImplemented();

        LibPausable.enforceNotPaused();

        LibSimpleBlacklist.enforceNotBlacklisted();
        LibSimpleBlacklist.enforceNotBlacklisted(from);
        LibSimpleBlacklist.enforceNotBlacklisted(to);

        LibNft.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev Batched version of `safeTransferFrom`.
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
    ) external {
        revert SharedErrors.NotImplemented();

        LibPausable.enforceNotPaused();

        LibSimpleBlacklist.enforceNotBlacklisted();
        LibSimpleBlacklist.enforceNotBlacklisted(from);
        LibSimpleBlacklist.enforceNotBlacklisted(to);

        LibNft.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT

//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\__0xFluffyBeard__/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\____vbranden___/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * @notice Based on the OpenZeppelin IERC1155 but without IERC165 since ERC165 is handled on diamond level.
 */
interface IERC1155 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

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
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev Batched version of `balanceOf`.
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
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

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
     * @dev Batched version of `safeTransferFrom`.
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

//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\__0xFluffyBeard__/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\____vbranden___/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import {LibContext} from "../../../libraries/LibContext.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @dev Basic ERC1155 library with additional separation of (semi-)fungible tokens.
 * Based on OpenZeppelin's ERC1155 contract.
 * See: https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155
 * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol
 *
 * ToDo: Make the library compatible for a ERC721 facet.
 */
library LibNft {
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;

    error TokenNotFound(uint256 tokenId);
    error TokenNotFungible(uint256 tokenId);

    enum TokenTypes {
        FUNGIBLE,
        NFT
    }

    struct FungibleToken {
        uint256 id;
        string name;
        string symbol;
        uint256 totalSupply;
    }

    struct Storage {
        // Array of fungible token IDs
        uint256[] fungibleTokenIds;
        // Mapping from token ID to fungible token settings
        mapping(uint256 => FungibleToken) fungibleTokens;
        // Mapping from token ID to account balances
        mapping(uint256 => mapping(address => uint256)) balances;
        // Mapping from account to operator approvals
        mapping(address => mapping(address => bool)) operatorApprovals;
        mapping(uint256 => address) nftOwners;
        // Mapping from account to owned NFT tokens
        mapping(address => EnumerableSet.UintSet) accountNftTokens;
        // Mapping with last token IDs
        mapping(TokenTypes => uint256) lastTokenIncrements;
    }

    uint256 internal constant FUNGIBLE_RESERVED_IDS = 1000;

    bytes32 internal constant STORAGE_SLOT =
        keccak256("solarprotocol.contracts.nft.LibNft");

    /**
     * @dev Returns the storage.
     */
    function _storage() private pure returns (Storage storage s) {
        bytes32 slot = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := slot
        }
    }

    /**
     * @dev Emitted when a new fungible token was created.
     */
    event FungibleTokenCreated(
        uint256 indexed tokenId,
        string name,
        string symbol
    );

    /**
     * @dev Emitted when fungible token `tokenId` was updated.
     */
    event FungibleTokenUpdated(
        uint256 indexed tokenId,
        string name,
        string symbol
    );

    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

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
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    error NotOwnerOf(uint256 id, address account);

    function enforceOwnerOf(uint256 id, address account) internal view {
        if (!isOwnerOf(id, account)) {
            revert NotOwnerOf(id, account);
        }
    }

    /**
     * @dev Creates a new fungible token.
     * @param name Name of the token.
     * @param symbol Symbol of the token.
     */
    function createFungibleToken(string memory name, string memory symbol)
        internal
        returns (uint256 tokenId)
    {
        tokenId = _incrementLastTokenId(TokenTypes.FUNGIBLE);

        FungibleToken memory token = FungibleToken({
            id: tokenId,
            name: name,
            symbol: symbol,
            totalSupply: 0
        });

        _storage().fungibleTokens[tokenId] = token;
        _storage().fungibleTokenIds.push(tokenId);
    }

    /**
     * @dev Updates an existing fungible token.
     * @param tokenId Id of the fungible token.
     * @param name Name of the token.
     * @param symbol Symbol of the token.
     */
    function updateFungibleToken(
        uint256 tokenId,
        string memory name,
        string memory symbol
    ) internal {
        FungibleToken memory token = _storage().fungibleTokens[tokenId];

        if (token.id != tokenId) {
            revert TokenNotFound(tokenId);
        }

        token.name = name;
        token.symbol = symbol;

        _storage().fungibleTokens[tokenId] = token;
    }

    /**
     * Returns the fungible token with id `tokenId`.
     * @param tokenId Id of the fungible token.
     */
    function getFungibleToken(uint256 tokenId)
        internal
        view
        returns (FungibleToken memory token)
    {
        token = _storage().fungibleTokens[tokenId];

        if (token.id != tokenId) {
            revert TokenNotFound(tokenId);
        }
    }

    /**
     * @dev Returns a list of all fungible tokens.
     */
    function getFungibleTokens()
        internal
        view
        returns (FungibleToken[] memory)
    {
        uint256[] memory fungibleTokenIds = _storage().fungibleTokenIds;
        mapping(uint256 => FungibleToken) storage fungibleTokens = _storage()
            .fungibleTokens;

        FungibleToken[] memory tokens = new FungibleToken[](
            fungibleTokenIds.length
        );
        for (uint256 index = 0; index < fungibleTokenIds.length; index++) {
            uint256 tokenId = fungibleTokenIds[index + 1];
            tokens[index] = fungibleTokens[tokenId];
        }

        return tokens;
    }

    /**
     * @dev Returns `true` if `tokenId` is a fungible token.
     */
    function isTokenFungible(uint256 tokenId) internal view returns (bool) {
        return _storage().fungibleTokens[tokenId].id == tokenId;
    }

    /**
     * @dev Mints `amount` of fungible token `tokenId` to `account`.
     */
    function mintFungible(
        address account,
        uint256 tokenId,
        uint256 amount
    ) internal {
        _mint(account, tokenId, amount, "", true);
    }

    /**
     * @dev Mints a batch `amounts` of fungible tokens `tokenIds` to `account`.
     */
    function mintFungibleBatch(
        address account,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) internal {
        _mintBatch(account, tokenIds, amounts, "", true);
    }

    /**
     * @dev Mints one NFT to `account and returns it's `tokenId`.
     */
    function mintNft(address account) internal returns (uint256 tokenId) {
        tokenId = _incrementLastTokenId(TokenTypes.NFT);

        _mint(account, tokenId, 1, "", false);
    }

    /**
     * @dev Mints `amount` of NFTs to `account` and returns their `tokenIds`.
     */
    function mintNftBatch(address account, uint256 amount)
        internal
        returns (uint256[] memory)
    {
        uint256[] memory amounts = new uint256[](amount);
        uint256[] memory tokenIds = new uint256[](amount);

        for (uint256 i = 0; i < amount; ++i) {
            uint256 tokenId = _incrementLastTokenId(TokenTypes.NFT);
            tokenIds[i] = tokenId;
            amounts[i] = 1;
        }

        _mintBatch(account, tokenIds, amounts, "", false);

        return tokenIds;
    }

    /**
     * @dev Returns a list of all NFT `tokenIds` owned by `account`.
     */
    function getNftsOf(address account)
        internal
        view
        returns (uint256[] memory tokens)
    {
        tokens = _storage().accountNftTokens[account].values();
    }

    /**
     * @dev Returns the owner of nft with `id`.
     */
    function ownerOf(uint256 id) internal view returns (address account) {
        return _storage().nftOwners[id];
    }

    /**
     * @dev Returns true if `account` is the owner of NFT with `id`
     * false otherwise.
     */
    function isOwnerOf(uint256 id, address account)
        internal
        view
        returns (bool)
    {
        return _storage().nftOwners[id] == account;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        internal
        view
        returns (uint256)
    {
        // solhint-disable-next-line reason-string
        require(
            account != address(0),
            "ERC1155: balance query for the zero address"
        );
        return _storage().balances[id][account];
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        // solhint-disable-next-line reason-string
        require(owner != operator, "ERC1155: setting approval status for self");
        _storage().operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator)
        internal
        view
        returns (bool)
    {
        return _storage().operatorApprovals[account][operator];
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        // solhint-disable-next-line reason-string
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = LibContext.msgSender();
        //uint256[] memory ids = _asSingletonArray(id);
        //uint256[] memory amounts = _asSingletonArray(amount);

        //_beforeTokenTransfer(operator, from, to, ids, amounts, data);

        _transferBalance(from, to, id, amount);

        emit TransferSingle(operator, from, to, id, amount);

        //_afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev Batched version of `safeTransferFrom`.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        // solhint-disable-next-line reason-string
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        // solhint-disable-next-line reason-string
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = LibContext.msgSender();

        //_beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _transferBalance(from, to, id, amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        //_afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Updates the balances during a transfer `amount` of token `id` `from` `to`.
     */
    function _transferBalance(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) private {
        uint256 fromBalance = _storage().balances[id][from];
        // solhint-disable-next-line reason-string
        require(
            fromBalance >= amount,
            "ERC1155: insufficient balance for transfer"
        );
        unchecked {
            _storage().balances[id][from] = fromBalance - amount;
        }
        _storage().balances[id][to] += amount;

        if (!isTokenFungible(id)) {
            _storage().accountNftTokens[from].remove(id);
            _storage().accountNftTokens[to].add(id);
            _storage().nftOwners[id] = to;
        }
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
        bytes memory data,
        bool enforceFungible
    ) private {
        // solhint-disable-next-line reason-string
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = LibContext.msgSender();
        //uint256[] memory ids = _asSingletonArray(id);
        //uint256[] memory amounts = _asSingletonArray(amount);

        //_beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _storage().balances[id][to] += amount;
        if (!isTokenFungible(id)) {
            if (enforceFungible) {
                revert TokenNotFungible(id);
            }
            _storage().accountNftTokens[to].add(id);
            _storage().nftOwners[id] = to;
        }

        emit TransferSingle(operator, address(0), to, id, amount);

        //_afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            id,
            amount,
            data
        );
    }

    /**
     * @dev Batched version of `_mint`.
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
        bytes memory data,
        bool enforceFungible
    ) private {
        // solhint-disable-next-line reason-string
        require(to != address(0), "ERC1155: mint to the zero address");
        // solhint-disable-next-line reason-string
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = LibContext.msgSender();

        //_beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _storage().balances[ids[i]][to] += amounts[i];

            if (!isTokenFungible(ids[i])) {
                if (enforceFungible) {
                    revert TokenNotFungible(ids[i]);
                }
                _storage().accountNftTokens[to].add(ids[i]);
                _storage().nftOwners[ids[i]] = to;
            }
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        //_afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal {
        // solhint-disable-next-line reason-string
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = LibContext.msgSender();
        //uint256[] memory ids = _asSingletonArray(id);
        //uint256[] memory amounts = _asSingletonArray(amount);

        //_beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _storage().balances[id][from];
        // solhint-disable-next-line reason-string
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _storage().balances[id][from] = fromBalance - amount;
        }
        _storage().accountNftTokens[from].remove(id);
        _storage().nftOwners[id] = address(0);

        emit TransferSingle(operator, from, address(0), id, amount);

        //_afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Batched version of `_burn`.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        // solhint-disable-next-line reason-string
        require(from != address(0), "ERC1155: burn from the zero address");
        // solhint-disable-next-line reason-string
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = LibContext.msgSender();

        //_beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _storage().balances[id][from];

            // solhint-disable-next-line reason-string
            require(
                fromBalance >= amount,
                "ERC1155: burn amount exceeds balance"
            );
            unchecked {
                _storage().balances[id][from] = fromBalance - amount;
            }
            _storage().accountNftTokens[from].remove(id);
            _storage().nftOwners[id] = address(0);
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        //_afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    // solhint-disable-next-line reason-string
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                // solhint-disable-next-line reason-string
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
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
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    // solhint-disable-next-line reason-string
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                // solhint-disable-next-line reason-string
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * Handles ID incrementation for the 2 token types.
     */
    function _incrementLastTokenId(TokenTypes tokenType)
        private
        returns (uint256 id)
    {
        id = _storage().lastTokenIncrements[tokenType];

        // Switch to NFT ID pool if the fungible tokens reach the limit of the reserved pool
        if (tokenType == TokenTypes.FUNGIBLE && id == FUNGIBLE_RESERVED_IDS) {
            tokenType = TokenTypes.NFT;
            id = _storage().lastTokenIncrements[tokenType];
        }

        // Initialize the NFT id pool to start after the fungible reserved pool
        if (tokenType == TokenTypes.NFT && id == 0) {
            id = FUNGIBLE_RESERVED_IDS;
        }

        _storage().lastTokenIncrements[tokenType] = ++id;
    }
}

// SPDX-License-Identifier: MIT

//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\__0xFluffyBeard__/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\____vbranden___/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import {LibContext} from "../../libraries/LibContext.sol";
import {LibAccessControl} from "../access/LibAccessControl.sol";
import {LibRoles} from "../access/LibRoles.sol";

/**
 * @dev Library version of the OpenZeppelin Pausable contract with Diamond storage.
 * See: https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable
 * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol
 */
library LibPausable {
    struct Storage {
        bool paused;
    }

    bytes32 private constant STORAGE_SLOT =
        keccak256("solarprotocol.contracts.pausable.LibPausable");

    /**
     * @dev Returns the storage.
     */
    function _storage() private pure returns (Storage storage s) {
        bytes32 slot = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := slot
        }
    }

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Reverts when paused.
     */
    function enforceNotPaused() internal view {
        require(
            !paused() ||
                LibAccessControl.hasRole(
                    LibRoles.TESTER_ROLE,
                    LibContext.msgSender()
                ),
            "Pausable: paused"
        );
    }

    /**
     * @dev Reverts when not paused.
     */
    function enforcePaused() internal view {
        require(
            paused() ||
                LibAccessControl.hasRole(
                    LibRoles.TESTER_ROLE,
                    LibContext.msgSender()
                ),
            "Pausable: not paused"
        );
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() internal view returns (bool) {
        return _storage().paused;
    }

    /**
     * @dev Triggers stopped state.
     */
    function pause() internal {
        _storage().paused = true;
        emit Paused(LibContext.msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function unpause() internal {
        _storage().paused = false;
        emit Unpaused(LibContext.msgSender());
    }
}