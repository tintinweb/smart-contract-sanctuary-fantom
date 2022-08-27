/**
 *Submitted for verification at FtmScan.com on 2022-08-27
*/

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**`
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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// File: contracts/storage/_BarnStakerStorage.sol



pragma solidity ^0.8.16;

contract _BarnStakerStorage {
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 internal constant BARN_STAKER_STORAGE_POSITION =
        keccak256("games.wolfland.contracts.barnstakerstorage");

    struct BarnStakerStorage {
        mapping(uint16 => mapping(uint256 => Stake[])) stakes;
        mapping(uint16 => mapping(uint256 => uint256)) stakeSize;
        mapping(uint16 => Agreement) agreements;
        EnumerableSet.UintSet vacantBarns;
        address[] stakables;
        uint256 shearBase;
        uint256 fee;
        uint256 capacityMultiplier;
        uint256 fertilityMultiplier;
        address babyWool;
    }

    struct Agreement {
        uint256 interest;
        uint256 capacity;
        uint256 fertility;
    }

    struct Stake {
        uint256 start;
        uint256 fertility;
        uint256[] stakable;
        uint256 interest;
        address owner;
    }

    function barnStakerStorage()
        internal
        pure
        returns (BarnStakerStorage storage _storage)
    {
        bytes32 position = BARN_STAKER_STORAGE_POSITION;
        assembly {
            _storage.slot := position
        }
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;







/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
}

// File: @openzeppelin/contracts/access/IAccessControl.sol


// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// File: @openzeppelin/contracts/access/AccessControl.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;




/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }
}

// File: @openzeppelin/contracts/interfaces/IERC2981.sol


// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/common/ERC2981.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// File: contracts/abstract/_ERC721.sol


pragma solidity ^0.8.4;






contract _ERC721 is
    ERC721,
    ERC721Enumerable,
    Pausable,
    AccessControl,
    ERC721Burnable,
    ERC2981
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint96 public constant ROYALTY_FEE = 500;

    constructor(
        string memory name,
        string memory symbol,
        address royaltyReceiver
    ) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _setDefaultRoyalty(royaltyReceiver, ROYALTY_FEE);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setRoyaltyReceiver(address royaltyReceiver)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(royaltyReceiver, ROYALTY_FEE);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        _resetTokenRoyalty(tokenId);
        super._burn(tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// File: contracts/abstract/_ERC20.sol


pragma solidity ^0.8.4;




contract _ERC20 is ERC20, ERC20Burnable, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// File: contracts/abstract/_ERC721MultiCurrency.sol



pragma solidity ^0.8.13;



contract _ERC721MultiCurrency is _ERC721 {
    uint256 public constant DEFAULT_CURRENCY = 0;
    Currency[] private _currencies;
    address private _feeAccount;

    constructor(
        string memory name,
        string memory symbol,
        address feeAccount
    ) _ERC721(name, symbol, feeAccount) {
        _feeAccount = feeAccount;
    }

    function getCurrency(uint256 id)
        public
        view
        returns (
            string memory,
            uint256,
            address,
            bool
        )
    {
        Currency memory currency = _currencies[id];
        return (currency.name, currency.price, currency.erc20, currency.burn);
    }

    function addCurrency(
        string memory name,
        uint256 price,
        address erc20,
        bool burn
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _currencies.push(Currency(name, price, erc20, burn));
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        Address.sendValue(payable(_feeAccount), address(this).balance);
    }

    function setFeeAccount(address feeAccount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _feeAccount = feeAccount;
    }

    function getFeeAccount() external view returns (address) {
        return _feeAccount;
    }

    function setCurrency(
        uint256 id,
        string calldata name,
        uint256 price,
        address erc20,
        bool burn
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _currencies[id] = Currency(name, price, erc20, burn);
    }

    function deleteCurrency(uint256 id) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete _currencies[id];
    }

    function _buy(uint256 currencyId, uint256 price) internal {
        if (currencyId == DEFAULT_CURRENCY) {
            require(msg.value == price, "Incorrect value sent.");
        } else {
            Currency memory c = _currencies[currencyId];
            require(c.erc20 != address(0), "Incorrect currency address");
            _ERC20 erc20 = _ERC20(c.erc20);
            require(erc20.balanceOf(msg.sender) >= price, "Not enough value");
            if (c.burn) {
                erc20.transferFrom(msg.sender, address(this), price);
                erc20.burn(price);
            } else {
                erc20.transferFrom(msg.sender, _feeAccount, price);
            }
        }
    }

    struct Currency {
        string name;
        uint256 price;
        address erc20;
        bool burn;
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

// File: contracts/abstract/_Delegator.sol



pragma solidity ^0.8.13;

contract _Delegator {
    mapping(address => string[]) private _delegate;

    function getDelegate(address delegate)
        external
        view
        returns (string[] memory)
    {
        return _delegate[delegate];
    }

    function delegateCall(
        address delegate,
        uint256 methodId,
        bytes memory args
    ) external returns (bytes memory) {
        return
            Address.functionDelegateCall(
                delegate,
                bytes.concat(
                    bytes4(keccak256(bytes(_delegate[delegate][methodId]))),
                    args
                )
            );
    }

    function _addDelegate(
        address delegate,
        string calldata method,
        bytes memory args
    ) internal {
        Address.functionStaticCall(
            delegate,
            bytes.concat(bytes4(keccak256(bytes(method))), args)
        );
        _delegate[delegate].push(method);
    }

    function _setDelegate(
        address delegate,
        uint256 methodId,
        string calldata method,
        bytes memory args
    ) internal {
        Address.functionStaticCall(
            delegate,
            bytes.concat(bytes4(keccak256(bytes(method))), args)
        );
        _delegate[delegate][methodId] = method;
    }

    function _deleteDelegate(address delegate) internal {
        delete _delegate[delegate];
    }
}

// File: @openzeppelin/contracts/utils/Base64.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// File: contracts/utils/Lands.sol



pragma solidity ^0.8.0;



library Lands {
    uint8 private constant TRUE = 1;
    uint8 private constant ACRE_X = 0;
    uint8 private constant ACRE_Y = 1;
    uint8 private constant ACRE_HQ = 2;
    uint8 private constant ACRE_ATTR_NUMBER = 3;
    uint8 private constant BIOMES_NUMBER = 20;
    uint8 private constant BIOMES_ATTR_NUMBER = 8;
    uint8 private constant BIOME_NAME = 0;
    bytes32 private constant LAND_STORAGE_POSITION =
        keccak256("games.wolfland.contracts.landstorage");

    function createURIFor(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        _LandStorage.LandStorage storage ls = _landStorage();
        uint16 farmId = ls.lands[tokenId];
        _LandStorage.Farm memory farm = ls.farms[farmId];
        uint256 acres = farm.acres.length;
        uint8[] memory biomes = new uint8[](acres);
        for (uint256 i = 0; i < acres; i++) {
            uint8 biome = ls
            .map[farm.acres[i][ACRE_X]][farm.acres[i][ACRE_Y]].biome;
            biomes[i] = biome;
        }
        string memory attrJson = _jsonFrom(farm.acres, biomes);
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            "{",
                            '"name" : "Farm ',
                            " #",
                            Strings.toString(farmId),
                            '",',
                            '"description" : "',
                            _description(),
                            '",',
                            '"image" : "',
                            farm.image,
                            '","attributes" : ',
                            attrJson,
                            "}"
                        )
                    )
                )
            );
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

    function _biomeNames() private pure returns (string[BIOMES_NUMBER] memory) {
        string[BIOMES_NUMBER] memory names = [
            "Desert",
            "Rocky Desert",
            "Plains",
            "Grassland",
            "Tundra",
            "Forest",
            "Heavy Forest",
            "Hills",
            "Hills Forest",
            "Mountains",
            "Mountains Forest",
            "Ocean",
            "Desert Oil",
            "Plains Lakes",
            "Tundra Oil",
            "Forest Magic Vibes",
            "Heavy Forest Magic Vibes",
            "Hills Iron Ore",
            "Mountains Gold",
            "Ocean Oil"
        ];
        return names;
    }

    function _jsonFrom(
        uint8[ACRE_ATTR_NUMBER][] memory acres,
        uint8[] memory biomes
    ) private pure returns (string memory) {
        string memory json = string(abi.encodePacked("["));
        for (uint8 i = 0; i < acres.length; i++) {
            json = string(
                abi.encodePacked(
                    json,
                    _jsonFor(acres[i], biomes[i]),
                    i < acres.length - 1 ? "," : "]"
                )
            );
        }
        return json;
    }

    function _jsonFor(uint8[ACRE_ATTR_NUMBER] memory acre, uint8 biome)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{ "trait_type" : "',
                    _nameFor(biome),
                    '", "value" : "',
                    Strings.toString(acre[ACRE_X]),
                    ".",
                    Strings.toString(acre[ACRE_Y]),
                    '" }'
                )
            );
    }

    function _nameFor(uint8 biome) private pure returns (string memory) {
        return _biomeNames()[biome];
    }

    function _tagFor(
        string memory image,
        uint8[ACRE_ATTR_NUMBER][] memory acres
    ) private pure returns (string memory) {
        uint8[ACRE_ATTR_NUMBER] memory hq;
        for (uint256 i = 0; i < acres.length; i++) {
            if (acres[i][ACRE_HQ] == TRUE) {
                hq = acres[i];
            }
        }
        return
            string(
                abi.encodePacked(
                    '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    image,
                    Strings.toString(hq[ACRE_X]),
                    ".",
                    Strings.toString(hq[ACRE_Y]),
                    '"/>'
                )
            );
    }

    function _emptyString() private pure returns (bytes32) {
        string memory empty = "";
        return keccak256(abi.encodePacked(empty));
    }

    function _description() private pure returns (string memory) {
        string
            memory description = "This is to certify that The Presenter of This Certificate is a lawful owner of the land and its nearby territory as per the Land Registry.";
        return description;
    }
}

// File: @openzeppelin/contracts/utils/math/SignedMath.sol


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

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: contracts/Land.sol



pragma solidity ^0.8.13;







contract Land is
    _ERC721MultiCurrency,
    IERC721Receiver,
    _LandStorage,
    _Delegator
{
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    bytes32 public constant LAND_CERTIFICATE = keccak256("CLAND");
    _ERC721 private _landCertificate;
    string private _landImage;

    constructor(
        address landCertificate,
        address feeAccount,
        uint256 defaultPrice,
        string memory landImage
    )
        _ERC721MultiCurrency(
            "Fantom Wolf Game Reborn: Land",
            "LAND",
            feeAccount
        )
    {
        _landCertificate = _ERC721(landCertificate);
        _landImage = landImage;
        addCurrency("FTM", defaultPrice, ZERO_ADDRESS, false);
    }

    function onERC721Received(
        address from,
        address,
        uint256 tokenId,
        bytes memory symbol
    ) public virtual override returns (bytes4) {
        require(LAND_CERTIFICATE == bytes32(symbol), "Incorrect transfer.");

        require(
            address(this) == _landCertificate.ownerOf(tokenId),
            "Incorrect owner."
        );
        _landCertificate.burn(tokenId);

        _assignLand(from);

        return this.onERC721Received.selector;
    }

    function setMap(uint8[MAP_ATTR_NUMBER][] calldata acres)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        LandStorage storage ls = landStorage();
        for (uint256 i = 0; i < acres.length; i++) {
            uint16 farmId = ls.map[acres[i][ACRE_X]][acres[i][ACRE_Y]].farmId;
            require(
                farmId == EMPTY_FARM || ls.ownedFarms[farmId] == ZERO_ADDRESS,
                "Acre is occupied."
            );
            ls.map[acres[i][ACRE_X]][acres[i][ACRE_Y]] = _LandStorage.Acre(
                acres[i][ACRE_TYPE],
                EMPTY_FARM
            );
        }
    }

    function getMap(uint8 x, uint8 y) external view returns (uint8, uint16) {
        LandStorage storage ls = landStorage();
        uint16 farmId = ls.map[x][y].farmId;
        return (
            ls.map[x][y].biome,
            farmId == EMPTY_FARM
                ? farmId
                : ls.ownedFarms[farmId] == ZERO_ADDRESS
                ? EMPTY_FARM
                : farmId
        );
    }

    function setBiome(
        uint8[] calldata id,
        uint96[BIOMES_ATTR_NUMBER][] calldata attributes
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        LandStorage storage ls = landStorage();
        for (uint256 i = 0; i < id.length; i++) {
            ls.biomes[id[i]] = attributes[i];
        }
    }

    function getBiome(uint8 id)
        external
        view
        returns (uint96[BIOMES_ATTR_NUMBER] memory)
    {
        LandStorage storage ls = landStorage();
        return ls.biomes[id];
    }

    function setFarm(
        uint16[] calldata id,
        uint256[] calldata size,
        uint8[ACRE_ATTR_NUMBER][] calldata acres
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        LandStorage storage ls = landStorage();
        uint256 assignedAcres = 0;
        for (uint256 i = 0; i < id.length; i++) {
            require(ls.ownedFarms[id[i]] == ZERO_ADDRESS, "Farm is occupied.");
            for (uint256 j = 0; j < size[i]; j++) {
                uint16 farmId = ls
                .map[acres[j + assignedAcres][ACRE_X]][
                    acres[j + assignedAcres][ACRE_Y]
                ].farmId;
                require(
                    farmId == EMPTY_FARM ||
                        ls.ownedFarms[farmId] == ZERO_ADDRESS,
                    "Acre is occupied."
                );
                ls.farms[id[i]].acres.push(acres[j + assignedAcres]);
                ls
                .map[acres[j + assignedAcres][ACRE_X]][
                    acres[j + assignedAcres][ACRE_Y]
                ].farmId = id[i];
                if (acres[j + assignedAcres][ACRE_HQ] == 1) {
                    ls.farms[id[i]].hq = j;
                }
            }
            ls.farms[id[i]].image = _landImage;
            assignedAcres += size[i];
            ls.vacantFarms.add(id[i]);
        }
    }

    function setFarmImage(uint16[] calldata id, string[] calldata images)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        LandStorage storage ls = landStorage();
        for (uint256 i = 0; i < id.length; i++) {
            ls.farms[id[i]].image = images[i];
        }
    }

    function getFarm(uint16 id, uint256 acre)
        external
        view
        returns (uint8[ACRE_ATTR_NUMBER] memory)
    {
        LandStorage storage ls = landStorage();
        return ls.farms[id].acres[acre];
    }

    function getFarmInfo(uint16 id)
        external
        view
        returns (
            uint256,
            uint256,
            string memory
        )
    {
        LandStorage storage ls = landStorage();
        return (ls.farms[id].hq, ls.farms[id].acres.length, ls.farms[id].image);
    }

    function deleteFarm(uint16[] calldata id)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        LandStorage storage ls = landStorage();
        for (uint256 i = 0; i < id.length; i++) {
            require(ls.ownedFarms[id[i]] == ZERO_ADDRESS, "Farm is occupied.");
            delete ls.farms[id[i]];
            ls.vacantFarms.remove(id[i]);
        }
    }

    function setLandImage(string calldata landImage)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _landImage = landImage;
    }

    function getLandImage() external view returns (string memory) {
        return _landImage;
    }

    function getOwnedFarm(uint16 id) external view returns (address) {
        LandStorage storage ls = landStorage();
        return ls.ownedFarms[id];
    }

    function getVacantFarms() external view returns (uint256) {
        LandStorage storage ls = landStorage();
        return ls.vacantFarms.length();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Non-existent token");
        return Lands.createURIFor(tokenId);
    }

    function getLandCertificate() external view returns (address) {
        return address(_landCertificate);
    }

    function getFarmId(uint256 tokenId) external view returns (uint16) {
        LandStorage storage ls = landStorage();
        return ls.lands[tokenId];
    }

    function buy(
        uint8 x,
        uint8 y,
        uint16 farmId,
        uint256 currencyId
    ) external payable whenNotPaused {
        LandStorage storage ls = landStorage();
        require(ls.ownedFarms[farmId] == _msgSender(), "Incorrect farm owner.");
        require(Maps.canBuy(x, y, farmId), "Incorrect land choice.");
        _buy(currencyId, _calculatePrice(x, y, farmId, currencyId));
        ls.map[x][y].farmId = farmId;
        ls.farms[farmId].acres.push([x, y, 0]);
    }

    function addDelegate(
        address delegate,
        string calldata method,
        bytes memory args
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _addDelegate(delegate, method, args);
    }

    function setDelegate(
        address delegate,
        uint256 methodId,
        string calldata method,
        bytes memory args
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDelegate(delegate, methodId, method, args);
    }

    function deleteDelegate(address delegate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _deleteDelegate(delegate);
    }

    function _burn(uint256 tokenId) internal virtual override {
        LandStorage storage ls = landStorage();
        uint16 farmId = ls.lands[tokenId];
        delete ls.ownedFarms[farmId];
        delete ls.lands[tokenId];
        delete ls.farms[farmId];
        super._burn(tokenId);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        LandStorage storage ls = landStorage();
        uint16 farmId = ls.lands[tokenId];
        ls.ownedFarms[farmId] = to;
        super._afterTokenTransfer(from, to, tokenId);
    }

    function _assignLand(address to) internal {
        LandStorage storage ls = landStorage();
        uint256 vacantFarms = ls.vacantFarms.length();
        require(vacantFarms > 0, "No available farms.");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        uint16 farmId = _selectFarmId(vacantFarms);
        ls.lands[tokenId] = farmId;
        ls.ownedFarms[farmId] = to;
        _safeMint(to, tokenId);
    }

    function _selectFarmId(uint256 mod) private returns (uint16) {
        LandStorage storage ls = landStorage();
        uint256 index = (uint256(uint160(address(block.coinbase))) +
            block.number +
            block.timestamp) % mod;
        uint256 farmId = ls.vacantFarms.at(index);
        assert(ls.ownedFarms[farmId] == ZERO_ADDRESS);
        ls.vacantFarms.remove(farmId);
        return uint16(farmId);
    }

    function _calculatePrice(
        uint8 x,
        uint8 y,
        uint16 farmId,
        uint256 currencyId
    ) private view returns (uint256 price) {
        LandStorage storage ls = landStorage();
        Farm memory farm = ls.farms[farmId];
        uint256 distance = Maps.getDistance(
            farm.acres[farm.hq][ACRE_X],
            farm.acres[farm.hq][ACRE_Y],
            x,
            y
        );
        assert(distance > 0);

        (, price, , ) = _ERC721MultiCurrency.getCurrency(currencyId);
        price *= 2**distance;
    }
}

// File: contracts/storage/_BabyCreatureStorage.sol



pragma solidity ^0.8.15;

contract _BabyCreatureStorage {
    uint256 public constant CREATURE_ATTR_NUM = 13;
    address internal constant ADDRESS_ZERO = address(0);
    bytes32 internal constant STORAGE_POSITION =
        keccak256("games.wolfland.contracts.babycreaturestorage");

    struct BabyCreatureStorage {
        mapping(uint64 => uint256) breedingDuration;
        mapping(uint64 => uint256[]) breedingCurrency;
        mapping(uint256 => uint64[CREATURE_ATTR_NUM]) creatureAttributesMap;
        mapping(address => BreedingStake[]) stakes;
        string[][12] sheepTraitNames;
        string[][12] sheepTraitImages;
        string[][12] wolfTraitNames;
        string[][12] wolfTraitImages;
    }

    struct BreedingStake {
        uint256 start;
        uint256 end;
        uint256 male;
        uint256 female;
    }

    function babyCreatureStorage()
        internal
        pure
        returns (BabyCreatureStorage storage _storage)
    {
        bytes32 position = STORAGE_POSITION;
        assembly {
            _storage.slot := position
        }
    }
}

// File: contracts/BabyWool.sol



pragma solidity ^0.8.13;

contract BabyWool is _ERC20 {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public constant DENOMINATOR = 10000;
    address private _feeReceiver;

    constructor(address feeReceiver) _ERC20("Baby Wool", "BWOOL") {
        _feeReceiver = feeReceiver;
    }

    function mint(
        address to,
        uint256 amount,
        uint256 fee
    ) external onlyRole(MINTER_ROLE) {
        uint256 _fee = 0;
        if (fee > 0) {
            _fee = (amount * fee) / DENOMINATOR;
            _mint(_feeReceiver, _fee);
        }
        _mint(to, amount - _fee);
    }

    function setFeeReceiver(address feeReceiver)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _feeReceiver = feeReceiver;
    }

    function getFeeReceiver() external view returns (address) {
        return _feeReceiver;
    }
}

// File: contracts/utils/BarnStakes.sol



pragma solidity ^0.8.16;





library BarnStakes {
    uint8 private constant MAX_SHEEP = 3;
    uint8 private constant FERTILITY = 4;
    uint8 private constant CREATURE_ATTR_CLASS = 1;
    uint64 private constant WOLF_CLASS = 0;
    uint256 private constant DENOMINATOR = 10000;
    address internal constant ZERO_ADDRESS = address(0);
    bytes32 private constant BARN_STAKER_STORAGE_POSITION =
        keccak256("games.wolfland.contracts.barnstakerstorage");
    bytes32 private constant LAND_STORAGE_POSITION =
        keccak256("games.wolfland.contracts.landstorage");
    bytes32 private constant BABY_CREATURE_STORAGE_POSITION =
        keccak256("games.wolfland.contracts.babycreaturestorage");

    function estimateShear(
        uint16 farmId,
        uint256 stakableType,
        uint256 stakeId
    ) external view returns (uint256) {
        _BarnStakerStorage.BarnStakerStorage
            storage _storage = _barnStakerStorage();
        _BarnStakerStorage.Stake storage _stake = _storage.stakes[farmId][
            stakableType
        ][stakeId];
        if (block.timestamp <= _stake.start) {
            return 0;
        }
        uint256 duration = (block.timestamp - _stake.start);
        uint256 amount = (duration *
            _stake.stakable.length *
            _storage.shearBase *
            _stake.fertility) / DENOMINATOR;

        uint256 interest = 0;
        if (_stake.interest > 0) {
            interest = (amount * _stake.interest) / DENOMINATOR;
        }

        uint256 fee = 0;
        if (_storage.fee > 0) {
            fee = ((amount - interest) * _storage.fee) / DENOMINATOR;
        }

        return amount - fee - interest;
    }

    function getAcreData(uint16 farmId)
        external
        view
        returns (uint256 capacity, uint256 fertility)
    {
        _LandStorage.LandStorage storage ls = _landStorage();
        _LandStorage.Farm memory farm = ls.farms[farmId];
        if (farm.acres.length > 0) {
            uint8[3] memory _acre = farm.acres[farm.hq];
            uint8 biome = ls.map[_acre[0]][_acre[1]].biome;
            capacity = ls.biomes[biome][MAX_SHEEP];
            fertility = ls.biomes[biome][FERTILITY];
        }
    }

    function allSheepDelegate(uint256[] calldata creatureId)
        external
        view
        returns (bool)
    {
        _BabyCreatureStorage.BabyCreatureStorage
            storage _storage = _babyCreatureStorage();
        for (uint256 i = 0; i < creatureId.length; i++) {
            if (
                _storage.creatureAttributesMap[creatureId[i]][
                    CREATURE_ATTR_CLASS
                ] == WOLF_CLASS
            ) {
                return false;
            }
        }
        return true;
    }

    function shear(
        uint16 farmId,
        uint256 stakableType,
        uint256 stakeId,
        address tenant,
        address landlord
    ) external {
        _BarnStakerStorage.BarnStakerStorage
            storage _storage = _barnStakerStorage();
        _BarnStakerStorage.Stake storage _stake = _storage.stakes[farmId][
            stakableType
        ][stakeId];
        uint256 size = _stake.stakable.length;
        if (block.timestamp > _stake.start && size > 0) {
            uint256 duration = (block.timestamp - _stake.start);
            _stake.start = block.timestamp;

            uint256 amount = (duration *
                size *
                _storage.shearBase *
                _stake.fertility) / DENOMINATOR;

            uint256 interest = 0;
            if (_stake.interest > 0) {
                interest = (amount * _stake.interest) / DENOMINATOR;
            }

            BabyWool(_storage.babyWool).mint(
                tenant,
                amount - interest,
                _storage.fee
            );

            if (interest > 0) {
                BabyWool(_storage.babyWool).mint(
                    landlord,
                    interest,
                    _storage.fee
                );
            }
        }
    }

    function withdraw(
        uint16 farmId,
        uint256 stakableType,
        uint256 stakeId,
        uint256[] memory stakableIndex,
        address owner
    ) external {
        _BarnStakerStorage.BarnStakerStorage
            storage _storage = _barnStakerStorage();
        _BarnStakerStorage.Stake[] storage stakes = _storage.stakes[farmId][
            stakableType
        ];
        require(stakeId < stakes.length && stakeId >= 0, "Incorrect stakeId.");
        uint256[] memory stakables = _storage
        .stakes[farmId][stakableType][stakeId].stakable;
        uint256[] storage stakablesRef = _storage
        .stakes[farmId][stakableType][stakeId].stakable;
        uint256 indexSize = stakableIndex.length;
        uint256 stakablesSize = stakables.length;
        require(
            indexSize <= stakablesSize && indexSize > 0,
            "Incorrect stakableIndex length."
        );
        _storage.stakeSize[farmId][stakableType] -= indexSize;
        _ERC721 stakable = _ERC721(_storage.stakables[stakableType]);
        if (indexSize == stakablesSize) {
            stakes[stakeId] = stakes[stakes.length - 1];
            stakes.pop();
            for (uint256 i = 0; i < stakablesSize; i++) {
                if (ZERO_ADDRESS == owner) {
                    stakable.burn(stakables[i]);
                } else {
                    stakable.transferFrom(address(this), owner, stakables[i]);
                }
            }
        } else {
            uint256[] memory shift = new uint256[](stakablesSize);
            for (uint256 i = 0; i < indexSize; i++) {
                uint256 replace = stakableIndex[i];
                if (stakableIndex[i] > stakablesRef.length - 1) {
                    replace = shift[stakableIndex[i]];
                }
                shift[stakablesRef.length - 1] = replace;
                stakablesRef[replace] = stakablesRef[stakablesRef.length - 1];
                stakablesRef.pop();

                uint256 id = stakables[stakableIndex[i]];
                if (ZERO_ADDRESS == owner) {
                    stakable.burn(id);
                } else {
                    stakable.transferFrom(address(this), owner, id);
                }
            }
        }
    }

    function _barnStakerStorage()
        private
        pure
        returns (_BarnStakerStorage.BarnStakerStorage storage _storage)
    {
        bytes32 position = BARN_STAKER_STORAGE_POSITION;
        assembly {
            _storage.slot := position
        }
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

    function _babyCreatureStorage()
        private
        pure
        returns (_BabyCreatureStorage.BabyCreatureStorage storage _storage)
    {
        bytes32 position = BABY_CREATURE_STORAGE_POSITION;
        assembly {
            _storage.slot := position
        }
    }
}

// File: contracts/BarnStaker.sol



pragma solidity ^0.8.16;





contract BarnStaker is
    IERC721Receiver,
    AccessControl,
    Pausable,
    _Delegator,
    _BarnStakerStorage
{
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint256 public constant DENOMINATOR = 10000;
    uint256 public constant FERTILITY_DENOMINATOR = 10;
    address internal constant ZERO_ADDRESS = address(0);
    _Delegator internal _creatureAttributesDelegator;
    Land internal _land;

    constructor(
        address land,
        address babyWool,
        address creatureAttributesDelegator,
        uint256 shearBase,
        uint256 fee,
        uint256 capacityMultiplier,
        uint256 fertilityMultiplier
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _land = Land(land);
        _creatureAttributesDelegator = _Delegator(creatureAttributesDelegator);

        BarnStakerStorage storage _storage = barnStakerStorage();
        _storage.shearBase = shearBase;
        _storage.fee = fee;
        _storage.babyWool = babyWool;
        _storage.capacityMultiplier = capacityMultiplier;
        _storage.fertilityMultiplier = fertilityMultiplier;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function getAcreData(uint16 farmId)
        external
        view
        returns (uint256, uint256)
    {
        return BarnStakes.getAcreData(farmId);
    }

    function allSheepDelegate(uint256[] calldata creatureId)
        external
        view
        returns (bool)
    {
        return BarnStakes.allSheepDelegate(creatureId);
    }

    function openBarn(uint16 farmId, uint256 interest) external {
        require(interest <= DENOMINATOR, "Incorrect interest.");

        address owner = _land.getOwnedFarm(farmId);
        require(owner == msg.sender, "Incorrect owner.");

        (uint256 capacity, uint256 fertility) = abi.decode(
            _land.delegateCall(address(this), 0, abi.encode(farmId)),
            (uint256, uint256)
        );

        BarnStakerStorage storage _storage = barnStakerStorage();
        _storage.vacantBarns.add(farmId);
        _storage.agreements[farmId] = Agreement(interest, capacity, fertility);
    }

    function closeBarn(uint16 farmId) external {
        address owner = _land.getOwnedFarm(farmId);
        require(owner == msg.sender, "Incorrect owner.");

        BarnStakerStorage storage _storage = barnStakerStorage();

        require(_getStakedSize(farmId) == 0, "Barn is in use.");

        _storage.vacantBarns.remove(farmId);
        delete _storage.agreements[farmId];
    }

    function getOpenBarn(uint16 farmId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        BarnStakerStorage storage _storage = barnStakerStorage();
        return (
            _storage.agreements[farmId].interest,
            _storage.agreements[farmId].capacity,
            _storage.agreements[farmId].fertility,
            _getStakedSize(farmId)
        );
    }

    function getVacantBarns() external view returns (uint256[] memory) {
        BarnStakerStorage storage _storage = barnStakerStorage();
        return _storage.vacantBarns.values();
    }

    function stake(
        uint16 farmId,
        uint256 stakableType,
        uint256[] calldata stakables
    ) external whenNotPaused {
        BarnStakerStorage storage _storage = barnStakerStorage();

        uint256[] memory param = new uint256[](2);
        param[0] =
            _storage.agreements[farmId].capacity *
            _storage.capacityMultiplier;

        param[1] = _getStakedSize(farmId);

        require(
            param[0] > param[1] && (param[0] - param[1]) >= stakables.length,
            "No staking capacity."
        );

        require(
            abi.decode(
                _creatureAttributesDelegator.delegateCall(
                    address(this),
                    0,
                    abi.encode(stakables)
                ),
                (bool)
            ),
            "Only sheep is allowed."
        );

        IERC721 stakable = IERC721(_storage.stakables[stakableType]);
        bool allApproved = stakable.isApprovedForAll(msg.sender, address(this));
        for (uint256 i = 0; i < stakables.length; i++) {
            if (!allApproved) {
                address approved = stakable.getApproved(stakables[i]);
                require(approved == address(this), "Stakable is not approved.");
            }
            stakable.safeTransferFrom(msg.sender, address(this), stakables[i]);
        }

        _storage.stakes[farmId][stakableType].push(
            Stake(
                block.timestamp,
                (_storage.agreements[farmId].fertility *
                    _storage.fertilityMultiplier) / FERTILITY_DENOMINATOR,
                stakables,
                _storage.agreements[farmId].interest,
                msg.sender
            )
        );
        _storage.stakeSize[farmId][stakableType] += stakables.length;
    }

    function getStake(
        uint16 farmId,
        uint256 stakableType,
        uint256 stakeId
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256[] memory,
            address
        )
    {
        BarnStakerStorage storage _storage = barnStakerStorage();
        Stake memory _stake = _storage.stakes[farmId][stakableType][stakeId];
        return (_stake.start, _stake.fertility, _stake.stakable, _stake.owner);
    }

    function getStakeSize(uint16 farmId, uint256 stakableType)
        external
        view
        returns (uint256)
    {
        BarnStakerStorage storage _storage = barnStakerStorage();
        return _storage.stakes[farmId][stakableType].length;
    }

    function estimateShear(
        uint16 farmId,
        uint256 stakableType,
        uint256 stakeId
    ) external view returns (uint256) {
        return BarnStakes.estimateShear(farmId, stakableType, stakeId);
    }

    function shear(
        uint16 farmId,
        uint256 stakableType,
        uint256 stakeId
    ) external {
        BarnStakerStorage storage _storage = barnStakerStorage();
        Stake storage _stake = _storage.stakes[farmId][stakableType][stakeId];
        require(block.timestamp > _stake.start, "Nothing to shear.");
        address owner = _storage.stakes[farmId][stakableType][stakeId].owner;
        require(owner == msg.sender, "Incorrect owner.");
        _shear(farmId, stakableType, stakeId, owner);
    }

    function shearAll(uint16 farmId) external {
        BarnStakerStorage storage _storage = barnStakerStorage();
        uint256 stakables = _storage.stakables.length;
        for (uint256 stakable = 0; stakable < stakables; stakable++) {
            Stake[] memory stakes = _storage.stakes[farmId][stakable];
            for (uint256 _stake = 0; _stake < stakes.length; _stake++) {
                if (
                    stakes[_stake].stakable.length > 0 &&
                    stakes[_stake].owner == msg.sender
                ) {
                    _shear(farmId, stakable, _stake, msg.sender);
                }
            }
        }
    }

    function withdraw(
        uint16 farmId,
        uint256 stakableType,
        uint256 stakeId,
        uint256[] calldata stakableIndex,
        bool andShear
    ) external {
        BarnStakerStorage storage _storage = barnStakerStorage();
        Stake storage _stake = _storage.stakes[farmId][stakableType][stakeId];
        address owner = _storage.stakes[farmId][stakableType][stakeId].owner;
        require(owner == msg.sender, "Incorrect owner.");
        if (andShear && block.timestamp > _stake.start) {
            _shear(farmId, stakableType, stakeId, owner);
        }
        _withdraw(farmId, stakableType, stakeId, stakableIndex, owner);
    }

    function withdrawAll(uint16 farmId, bool andShear) external {
        BarnStakerStorage storage _storage = barnStakerStorage();
        uint256 stakables = _storage.stakables.length;
        for (uint256 stakable = 0; stakable < stakables; stakable++) {
            uint256 length = _storage.stakes[farmId][stakable].length;
            for (uint256 i = 0; i < length; i++) {
                Stake[] memory stakes = _storage.stakes[farmId][stakable];
                for (uint256 _stake = 0; _stake < stakes.length; _stake++) {
                    if (
                        stakes[_stake].stakable.length > 0 &&
                        stakes[_stake].owner == msg.sender
                    ) {
                        if (andShear) {
                            _shear(farmId, stakable, _stake, msg.sender);
                        }
                        _withdraw(
                            farmId,
                            stakable,
                            _stake,
                            stakes[_stake].stakable,
                            msg.sender
                        );
                        break;
                    }
                }
            }
        }
    }

    function addStakable(address source) external onlyRole(DEFAULT_ADMIN_ROLE) {
        BarnStakerStorage storage _storage = barnStakerStorage();
        _storage.stakables.push(source);
    }

    function setStakable(uint256 id, address source)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        BarnStakerStorage storage _storage = barnStakerStorage();
        _storage.stakables[id] = source;
    }

    function deleteStakable(uint256 id) external onlyRole(DEFAULT_ADMIN_ROLE) {
        BarnStakerStorage storage _storage = barnStakerStorage();
        _storage.stakables[id] = _storage.stakables[
            _storage.stakables.length - 1
        ];
        _storage.stakables.pop();
    }

    function getStakable(uint256 id) external view returns (address) {
        BarnStakerStorage storage _storage = barnStakerStorage();
        return _storage.stakables[id];
    }

    function setShearBase(uint256 shearBase)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        BarnStakerStorage storage _storage = barnStakerStorage();
        _storage.shearBase = shearBase;
    }

    function getShearBase() external view returns (uint256) {
        BarnStakerStorage storage _storage = barnStakerStorage();
        return _storage.shearBase;
    }

    function setLand(address land) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _land = Land(land);
    }

    function getLand() external view returns (address) {
        return address(_land);
    }

    function setBabyWool(address babyWool)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        BarnStakerStorage storage _storage = barnStakerStorage();
        _storage.babyWool = babyWool;
    }

    function getBabyWool() external view returns (address) {
        BarnStakerStorage storage _storage = barnStakerStorage();
        return _storage.babyWool;
    }

    function setFee(uint256 fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        BarnStakerStorage storage _storage = barnStakerStorage();
        _storage.fee = fee;
    }

    function setCreatureAttributesDelegator(address creatureAttributesDelegator)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _creatureAttributesDelegator = _Delegator(creatureAttributesDelegator);
    }

    function getCreatureAttributesDelegator() external view returns (address) {
        return address(_creatureAttributesDelegator);
    }

    function getFee() external view returns (uint256) {
        BarnStakerStorage storage _storage = barnStakerStorage();
        return _storage.fee;
    }

    function setCapacityMultiplier(uint256 capacityMultiplier)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        BarnStakerStorage storage _storage = barnStakerStorage();
        _storage.capacityMultiplier = capacityMultiplier;
    }

    function getCapacityMultiplier() external view returns (uint256) {
        BarnStakerStorage storage _storage = barnStakerStorage();
        return _storage.capacityMultiplier;
    }

    function setFertilityMultiplier(uint256 fertilityMultiplier)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        BarnStakerStorage storage _storage = barnStakerStorage();
        _storage.fertilityMultiplier = fertilityMultiplier;
    }

    function getFertilityMultiplier() external view returns (uint256) {
        BarnStakerStorage storage _storage = barnStakerStorage();
        return _storage.fertilityMultiplier;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function addDelegate(
        address delegate,
        string calldata method,
        bytes memory args
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _addDelegate(delegate, method, args);
    }

    function setDelegate(
        address delegate,
        uint256 methodId,
        string calldata method,
        bytes memory args
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDelegate(delegate, methodId, method, args);
    }

    function deleteDelegate(address delegate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _deleteDelegate(delegate);
    }

    function _shear(
        uint16 farmId,
        uint256 stakableType,
        uint256 stakeId,
        address tenant
    ) internal whenNotPaused {
        BarnStakes.shear(
            farmId,
            stakableType,
            stakeId,
            tenant,
            _land.getOwnedFarm(farmId)
        );
    }

    function _withdraw(
        uint16 farmId,
        uint256 stakableType,
        uint256 stakeId,
        uint256[] memory stakableIndex,
        address owner
    ) internal {
        BarnStakes.withdraw(
            farmId,
            stakableType,
            stakeId,
            stakableIndex,
            owner
        );
    }

    function _getStakedSize(uint16 farmId) private view returns (uint256) {
        BarnStakerStorage storage _storage = barnStakerStorage();
        uint256 staked = 0;
        for (uint256 i = 0; i < _storage.stakables.length; i++) {
            staked += _storage.stakeSize[farmId][i];
        }
        return staked;
    }
}

// File: contracts/facades/BarnStakerFacade.sol



pragma solidity ^0.8.16;





contract BarnStakerFacade is _BarnStakerStorage, _LandStorage {
    using EnumerableSet for EnumerableSet.UintSet;

    BarnStaker private immutable _barnStaker;
    Land private immutable _land;
    uint256 private constant OLD = 0;
    uint256 private constant NEW = 1;
    uint256 private constant BARN_PARAM_NUM = 7;
    uint256 public immutable TOKEN_ID_SHIFT;
    _ERC721[2] private _babyCreature;

    constructor(
        address barnStaker,
        address land,
        address babyCreatureOld,
        address babyCreatureNew,
        uint256 tokenIdShift
    ) {
        _barnStaker = BarnStaker(barnStaker);
        _land = Land(land);
        _babyCreature[0] = _ERC721(babyCreatureOld);
        _babyCreature[1] = _ERC721(babyCreatureNew);
        TOKEN_ID_SHIFT = tokenIdShift;
    }

    function getOpenBarnsDelegate(uint256 from, uint256 to, address tenant)
        external
        view
        returns (uint256[BARN_PARAM_NUM][] memory barns, uint256 last)
    {
        BarnStakerStorage storage _storage = barnStakerStorage();
        uint256[] memory vacantBarns = _storage.vacantBarns.values();
        last = vacantBarns.length;
        to = to > last ? last : to;
        if (from < to) {
            barns = new uint256[BARN_PARAM_NUM][](to - from);
            uint256 index = 0;
            for (uint256 i = from; i < to; i++) {
                uint16 farmId = uint16(vacantBarns[i]);
                barns[index][0] = vacantBarns[i];
                barns[index][1] = _storage.agreements[farmId].interest;
                barns[index][2] = _storage.agreements[farmId].capacity * _storage.capacityMultiplier;
                barns[index][3] = _storage.agreements[farmId].fertility * _storage.fertilityMultiplier;

                for (uint256 j = 0; j < _storage.stakables.length; j++) {
                    barns[index][4] += _storage.stakeSize[farmId][j];
                    
                    Stake[] memory _stakes = _storage.stakes[farmId][j];
                    for (uint256 _stake = 0; _stake < _stakes.length; _stake++) {
                        if (
                            _stakes[_stake].stakable.length > 0 &&
                            _stakes[_stake].owner == tenant
                        ) {
                            barns[index][6] = 1;
                        }
                    }
                }
                index++;
            }
        }
    }

    function getBiomeDelegate(uint256[BARN_PARAM_NUM][] memory barns)
        external
        view
        returns (uint256[BARN_PARAM_NUM][] memory _barns)
    {
        _barns = barns;
        
        LandStorage storage ls = landStorage();
        for (uint256 i = 0; i < _barns.length; i++) {
            Farm memory farm = ls.farms[barns[i][0]];
            if (farm.acres.length > 0) {
                uint8[3] memory _acre = farm.acres[farm.hq];
                _barns[i][5] = ls.map[_acre[0]][_acre[1]].biome;
            }
        }
    }

    function getOwnerDelegate(uint256[BARN_PARAM_NUM][] memory barns)
        external
        view
        returns (address[] memory owners)
    {
        owners = new address[](barns.length);
        
        LandStorage storage ls = landStorage();
        for (uint256 i = 0; i < barns.length; i++) {
            owners[i] = ls.ownedFarms[barns[i][0]];
        }
    }

    function getStakesDelegate(address owner, uint16 farmId)
        external
        view
        returns (uint256[4][] memory stakes, uint256[] memory stakables)
    {
        BarnStakerStorage storage _storage = barnStakerStorage();
        uint256 _stakables = _storage.stakables.length;

        uint256 size = 0;
        uint256 staked = 0;
        for (uint256 stakable = 0; stakable < _stakables; stakable++) {
            size += _storage.stakes[farmId][stakable].length;
            staked += _storage.stakeSize[farmId][stakable];
        }

        stakes = new uint256[4][](size);
        stakables = new uint256[](staked);

        uint stakeIndex = 0;
        uint stakableIndex = 0;
        for (uint256 stakable = 0; stakable < _stakables; stakable++) {
            Stake[] memory _stakes = _storage.stakes[farmId][stakable];
            for (uint256 _stake = 0; _stake < _stakes.length; _stake++) {
                if (
                    _stakes[_stake].stakable.length > 0 &&
                    _stakes[_stake].owner == owner
                ) {
                    stakes[stakeIndex][0] = stakable;
                    stakes[stakeIndex][1] = _stake;
                    stakes[stakeIndex][2] = _stakes[_stake].stakable.length;
                    stakes[stakeIndex][3] = BarnStakes.estimateShear(
                        farmId,
                        stakable,
                        _stake
                    );
                    stakeIndex++;

                    for (uint i = 0; i < _stakes[_stake].stakable.length; i++) {
                        stakables[stakableIndex] = _stakes[_stake].stakable[i];
                        stakableIndex++;
                    }
                }
            }
        }
    }

    function getOpenBarns(uint256 from, uint256 to, address tenant)
        external
        returns (uint256[BARN_PARAM_NUM][] memory barns, uint256 last, address[] memory owners)
    {
        (barns, last) = abi.decode(
            _barnStaker.delegateCall(address(this), 0, abi.encode(from, to, tenant)),
            (uint256[7][], uint256)
        );

        barns = abi.decode(
            _land.delegateCall(address(this), 0, abi.encode(barns)),
            (uint256[7][])
        );

        owners = abi.decode(
            _land.delegateCall(address(this), 1, abi.encode(barns)),
            (address[])
        );
    }

    function getStakes(address owner, uint16 farmId)
        external
        returns (uint256[4][] memory stakes, string[] memory uri)
    {
        uint256[] memory stakables;
        (stakes, stakables) = abi.decode(
            _barnStaker.delegateCall(
                address(this),
                1,
                abi.encode(owner, farmId)
            ),
            (uint256[4][], uint256[])
        );
        uri = new string[](stakables.length);
        for (uint256 i = 0; i < stakables.length; i++) {
            uint256 tokenId = stakables[i];
            if (tokenId < TOKEN_ID_SHIFT) {
                uri[i] = _babyCreature[OLD].tokenURI(tokenId);
            } else {
                uri[i] = _babyCreature[NEW].tokenURI(tokenId);
            }
        }
    }
}