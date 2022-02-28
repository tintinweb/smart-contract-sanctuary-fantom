/**
 *Submitted for verification at FtmScan.com on 2022-02-28
*/

// Sources flattened with hardhat v2.7.0 https://hardhat.org

// File contracts/DiminishesWithTime.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

/**
*   Utilities to aid tracking a property that diminishes at an even rate each day
*/
library DiminishesWithTime {

    struct DiminishingValue {
        uint64 lastValue;
        uint64 maxValue;
        uint64 dailyAtrophy;
        uint64 lastUpdated;
    }

    function addValue(DiminishingValue storage diminishable, uint64 addition) internal {
        uint64 newValue = value(diminishable) + addition > diminishable.maxValue ? diminishable.maxValue : value(diminishable) + addition;
        setValue(diminishable, newValue);
    }

    function reduceValue(DiminishingValue storage diminishable, uint64 reduction) internal {
        uint64 newValue = value(diminishable) > reduction ? value(diminishable) - reduction : 0;
        setValue(diminishable, newValue);
    }

    function setDailyAtrophy(DiminishingValue storage diminishable, uint64 dailyAtrophy) internal {
        diminishable.dailyAtrophy = dailyAtrophy;
    }

    function setValue(DiminishingValue storage diminishable, uint64 newValue) internal {
        diminishable.lastValue = newValue;
        diminishable.lastUpdated = uint64(block.timestamp);
    }

    function value(DiminishingValue storage diminishable) internal view returns (uint64) {
        uint64 daysSinceUpdate = (uint64(block.timestamp) - diminishable.lastUpdated) / 1 days;
        uint64 atrophy = daysSinceUpdate * diminishable.dailyAtrophy;
        return diminishable.lastValue < atrophy ? 0 : diminishable.lastValue - atrophy;
    }
}


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)



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


// File contracts/Allows3rdPartyUpdates.sol

/**
*   A base contract to track a multitude of different 'permissions' in a single uint256, where external contracts/wallets can be given
*   permission to any of the permissions tracked
*/
contract Allows3rdPartyUpdates is Ownable {

    mapping(address => uint256) public externalContractPermissions; // bools indicating what a contract can modify

    mapping(uint8 => string) public permissionNames;
    mapping(string => uint8) public permissionIds;


    /**
    *
    * ----------------------------------- READ --------------------------------------
    *
    */

    /**
    * @dev tests that a contract has a permission at the given index in the permissions array
    */
    function hasPermission(address contractAddress, uint256 permissionId) public view returns (bool) {
        uint256 booleanValue = (externalContractPermissions[contractAddress] >> permissionId) & uint256(1);
        return booleanValue == 1;
    }


    function hasPermission(address contractAddress, string memory permissionName) public view returns (bool) {
        uint256 permissionId = permissionIds[permissionName];
        return hasPermission(contractAddress, permissionId);
    }

    /**
    * @dev confirm the caller has permission to do a thing
    */
    function validatePermission(string memory permissionName) public view {
        require(hasPermission(msg.sender, permissionName), "Allows3rdPartyUpdates: No Permission");
    }

    /**
    * @dev confirm the caller has permission to do a thing
    */
    function validatePermission(string memory permissionName, address caller) public view {
        require(hasPermission(caller, permissionName), "Allows3rdPartyUpdates: No Permission");
    }

    /**
    *
    * ----------------------------------- WRITE --------------------------------------
    *
    */


    /**
    * @dev set our permissions list
    * - we deliberately start from an id of 1, as 0 is the default returned value of permissionIds[unusedKey]
    */
    function setPermissions(string[] calldata permissions) external onlyOwner {
        require(permissions.length < 256, "Only 256 permissions supported");
        for (uint8 i = 0; i < permissions.length; i++) {
            permissionNames[i + 1] = permissions[i];
            permissionIds[permissions[i]] = i + 1;
        }
    }

    /**
    * @dev update the permissions a single contract has
    *  - The uint needs to be computed externally
    */
    function updateContractPermissions(address contractAddress, uint256 permissions) external onlyOwner {
        externalContractPermissions[contractAddress] = permissions;
    }

    /**
    * @dev update a single permission a single contract has (by name)
    */
    function setIsPermittedForSinglePermissionByName(address contractAddress, string calldata permissionName, bool permit) external onlyOwner {
        uint permissionId = permissionIds[permissionName];
        require(permissionId != 0, "Permission not found");
        if (permit) {
            externalContractPermissions[contractAddress] = externalContractPermissions[contractAddress] | uint256(1) << permissionId;
        } else {
            externalContractPermissions[contractAddress] = externalContractPermissions[contractAddress] & ~(uint256(1) << permissionId);
        }
    }

}


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)



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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)



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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)



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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)



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


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)



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


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)









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
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
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
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)



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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721Enumerable.sol)




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


// File contracts/PalTokenTracker.sol







struct Stats {
    uint16 meleeDamage;
    uint16 rangedDamage;
    uint16 magicDamage;
    uint16 meleeDefense;
    uint16 rangedDefense;
    uint16 magicDefense;
    uint16 speed;
    uint16 criticalChance;
    uint16 health;
}

struct PalDevelopment {
    uint8 evolution;
    uint16 level;
    uint xp;
}

struct PalStandings {
    uint64 tournamentWins; // int
    uint64 tournamentPlaces; // int
    uint64 battleWinLossRatio; // wins as % of 100 (only from tournaments)
}

struct PalImageData {
    string image;
    string imageDead;
    string inGameImage;
    string inGameImageDead;
}

struct Pal {
    uint8 sprite; // the sprite/character of this Pal
    uint8 series; // the release series (a single release might span more than one mint)
    uint8 class; // ranger, melee.
    uint8 origin; // location the Pal landed
    uint8 personality; // just try and get sassy
    uint16 device; // the base device the Pal lives on
    uint32 nemesis; // tokenId

    uint64 energy; // energy value for in/out movements (current value tracked in diminishables)
    uint64 mood; // mood value for in/out movements (current value tracked in diminishables)

    string name; // the name of the Pal

    PalImageData imageData; // the imageSet we use for marketplaces and in-game
    Stats stats; // the Pals current battle stats block
    PalDevelopment development; // XP, Level, Evolution
    PalStandings standings; // Tournament results
    string[] achievements; // wow! Your Pal did its first solid poo! (parents will get it)
}

contract PalTokenTracker is IERC721Receiver, ERC721Enumerable {
    using Counters for Counters.Counter;

    bytes4 private constant INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint8 public chain;

    constructor() ERC721("PocketPals", "PAL") {
        _tokenIds._value = uint(chain) * 1000000;
    }

    Counters.Counter _tokenIds;
    Counters.Counter _tokensOnThisChain;

    mapping(uint => Pal) public pals; // tokenId: Pal
    mapping(uint => uint8) public palLastChainSeen; // if a Pal left here for another chain, we record where they went


    function _requirePalOnThisChain(uint tokenId) internal view {
        require(palLastChainSeen[tokenId] == chain, "PalTokenTracker: Pal does not exist on this chain");
    }

    function verifyPalIsOnThisChain(uint tokenId) public view returns (bool) {
        _requirePalOnThisChain(tokenId);
        return true;
    }

    function totalSupply() public view override returns (uint256) {
        return _tokensOnThisChain.current();
    }

    function pageOfOwnersTokenIds(address owner, uint page) external view returns (uint[10] memory ownedTokenIds) {

        for (uint i = 0; i < 10; i++) {
            uint ownerIndex = i + (page * 10);
            if (ownerIndex < ERC721.balanceOf(owner)) {
                ownedTokenIds[i] = tokenOfOwnerByIndex(owner, ownerIndex);
            } else {
                ownedTokenIds[i] = 0;
            }
        }
    }

    function royaltyInfo(uint256, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        receiver = address(this);
        royaltyAmount = salePrice / 20;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable) returns (bool) {
        return interfaceId == INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
    }

    function onERC721Received(address, address, uint256, bytes calldata) public view override returns (bytes4) {
        return IERC721Receiver(this).onERC721Received.selector;
    }

}


// File contracts/PalRepertoire.sol

struct RepertoireMove {
    uint16 moveId; // the id of the move. Combined with the trainingRoom, we can look up the move and get more details/process it
    uint16 level; // the level to which the move has been learned
    address trainingRoom; // where they learned this move.  The training room will house more information on this move, and the processing functions for it in battle
}

/**
* @dev the list of moves a Pal has learned
*  The moves system comprises a couple of interrelated contracts:
*  1. The Repertoire is simply a list of the moves the Pal knows and at which level
*  2. A TrainingRoom is responsible for a collection of Moves that can be learned there
*    - it determines the rate-of-learn for each move it trains, and tracks each Pals progress
*      toward levelling up each move
*    - Upon levelling up a move, the TrainingRoom updates a Pals Repertoire
*/
contract PalRepertoire is PalTokenTracker, Allows3rdPartyUpdates {

    uint public maxRepertoireLength = 6;

    /**
    *  @dev each Pal's list of known moves
    */
    mapping (uint => RepertoireMove[]) public palRepertoire;



    /**
    *
    * ----------------------------------- READ --------------------------------------
    *
    */

    function moveAtIndexForPal(uint tokenId, uint index) public view returns (RepertoireMove memory move) {
        _requirePalOnThisChain(tokenId);
        require(index < palRepertoire[tokenId].length, "PalRepertoire: Move does not exist");
        move = palRepertoire[tokenId][index];
    }

    function repertoireForPal(uint tokenId) public view returns (RepertoireMove[] memory moves) {
        _requirePalOnThisChain(tokenId);
        moves = palRepertoire[tokenId];
    }

    /**
    *
    * ----------------------------------- WRITE --------------------------------------
    *
    */

    /**
    * @dev learn a new move (optionally replaces a known move)
    *  - we don't do any checks here to make sure the Pal doesn't have this move in another slot, thats up to the UI
    */
    function setMoveAtIndex(uint tokenId, uint index, RepertoireMove memory newMove) public {
        validatePermission('repertoire', msg.sender);
        _requirePalOnThisChain(tokenId);
        RepertoireMove[] storage repertoire = palRepertoire[tokenId];

        require(index <= repertoire.length, "PalRepertoire: Index out of bounds");
        require(index < maxRepertoireLength, "PalRepertoire: Beyond slot limit for repertoire");
        if (index == repertoire.length) {
            repertoire.push(newMove);
        } else {
            repertoire[index] = newMove;
        }
    }

    /**
    * @dev level up an existing move
    *  - we don't do any checks here to make sure the move has enough XP to level up, we defer that test to the Training Room
    *    to give us flexibility (eg weak, fast-to-level-up moves vs strong, slow-to-level-up moves)
    */
    function increaseLevelOfExistingMove(uint tokenId, uint index, RepertoireMove memory move) public {
        validatePermission('repertoire', msg.sender);
        _requirePalOnThisChain(tokenId);
        RepertoireMove[] storage repertoire = palRepertoire[tokenId];
        require(index < repertoire.length, "PalRepertoire: Move does not exist");
        RepertoireMove storage existingMove = repertoire[index];
        require(existingMove.trainingRoom == move.trainingRoom && existingMove.moveId == move.moveId, "PalRepertoire: Attempt to increase level of mismatched move");
        existingMove.level++;
    }


    /**
    *
    * --------------------------------- WRITE [ADMIN] ------------------------------------
    *
    */

    /**
    * @dev increase MaxRepertoireLength for future expansions
    */
    function setMaxRepertoireLength(uint length) external onlyOwner {
        require(length > maxRepertoireLength, "PalRepertoire: Length can only get longer");
        maxRepertoireLength = length;
    }

}


// File contracts/PalDiminishables.sol

contract PalDiminishables is PalRepertoire {
    using DiminishesWithTime for DiminishesWithTime.DiminishingValue;


    event PalCharged(uint tokenId, uint64 currentEnergy);
    event PalBatteryDepleted(uint tokenId, uint64 currentEnergy);
    event PalPleased(uint tokenId, uint64 currentMood);
    event PalUpset(uint tokenId, uint64 currentMood);

    mapping(uint => DiminishesWithTime.DiminishingValue) palEnergy;
    mapping(uint => DiminishesWithTime.DiminishingValue) palMood;


    /**
    * @dev charge a Pal, increasing its energy
    */
    function charge(uint tokenId, uint64 amount ) external {
        _requirePalOnThisChain(tokenId);
        validatePermission('energy');
        palEnergy[tokenId].addValue(amount);
        emit PalCharged(tokenId, palEnergy[tokenId].value());
    }

    /**
    * @dev expend energy, reducing its value by an amount (it still diminishes at same rate)
    *  - intended for use when we have energy-intensive functionality
    */
    function expendEnergy(uint tokenId, uint64 amount) external {
        _requirePalOnThisChain(tokenId);
        validatePermission('energy');
        palEnergy[tokenId].reduceValue(amount);
        emit PalBatteryDepleted(tokenId, palEnergy[tokenId].value());
    }

    /**
    * @dev improve the mood of a Pal
    */
    function please(uint tokenId, uint64 amount) external {
        _requirePalOnThisChain(tokenId);
        validatePermission('mood');
        palMood[tokenId].addValue(amount);
        emit PalPleased(tokenId, palMood[tokenId].value());
    }
    /**
    * @dev worsen the mood of a Pal
    */
    function upset(uint tokenId, uint64 amount) external {
        _requirePalOnThisChain(tokenId);
        validatePermission('mood');
        palMood[tokenId].reduceValue(amount);
        emit PalUpset(tokenId, palMood[tokenId].value());
    }
}


// File contracts/PalMintAndUpdate.sol

contract PalMintAndUpdate is PalDiminishables {
    using DiminishesWithTime for DiminishesWithTime.DiminishingValue;
    using Counters for Counters.Counter;

    event PalMinted(uint tokenId);
    event PalArrived(uint tokenId);
    event PalLeftForOtherChain(uint tokenId, uint8 otherChainId);

    /**
    * @dev add or update a Pal - internal method used by our mint and arrive functions
    */
    function _createOrUpdatePal(uint tokenId, Pal memory pal) internal {

        pals[tokenId] = pal;

        palEnergy[tokenId] = DiminishesWithTime.DiminishingValue(pal.energy,100,10, uint64(block.timestamp));
        palMood[tokenId] = DiminishesWithTime.DiminishingValue(pal.mood,7,1, uint64(block.timestamp));

        palLastChainSeen[tokenId] = chain;
    }

    /**
    * @dev add or update a Pal that has arrived from another chain
    *  - we may have a record already here that is out of date if the Pal has been on this chain before
    *    but here we replace that record with the latest info coming through the wormhole
    */
    function arrivePalFromOtherChain(uint tokenId, Pal memory pal, RepertoireMove[] calldata repertoire, address owner) external {
        validatePermission('wormhole');
        _tokensOnThisChain.increment();
        _createOrUpdatePal(tokenId, pal);
        for (uint i = 0; i < repertoire.length; i++) {
            palRepertoire[tokenId][i] = repertoire[i];
        }
        if (!_exists(tokenId)) {
            _safeMint(owner, tokenId);
        } else {
            _safeTransfer(address(this), owner, tokenId, "");
        }
        emit PalArrived(tokenId);
    }

    /**
    * @dev update this Pal for having left this chain via a wormhole
    *  - we transfer the token on this chain into this contract
    */
    function sendPalToOtherChain(uint tokenId, uint8 otherChainId) external {
        validatePermission('wormhole');
        _requirePalOnThisChain(tokenId);
        _tokensOnThisChain.decrement();
        _safeTransfer(ownerOf(tokenId), address(this), tokenId, "");
        palLastChainSeen[tokenId] = otherChainId;
        emit PalLeftForOtherChain(tokenId, otherChainId);
    }


    /**
    * @dev mint a pal.
    *  - this function is expected to be called from a PalMinter contract, where that contract will contain
    *    the logic for collecting mint payment and determining the properties of the minted Pal
    */
    function mintPal(address to, Pal memory newPal) external {
        validatePermission('mint');

        uint tokenId = _tokenIds.current() + 1;
        uint32 nemesis = tokenId % 2 == 0 ? uint32(tokenId - 1) : uint32(tokenId + 1);

        newPal.nemesis = nemesis;

        _createOrUpdatePal(tokenId, newPal);

        _safeMint(to, tokenId);
        _tokenIds.increment();
        _tokensOnThisChain.increment();

        emit PalMinted(tokenId);
    }

}


// File contracts/PalVariables.sol




/**
* @dev the variables our Pals store as int references.  Functions here aren't optimized for convenience of use in the
*  front-end as they are mostly set & forget
*/
contract PalVariables is Ownable {

    mapping(uint8 => string) public classes;
    mapping(uint8 => string) public origins;
    mapping(uint8 => string) public sprites;
    mapping(uint8 => string) public personalities;
    mapping(uint16 => string) public devices;

    /**
    *
    * ----------------------------------- READ --------------------------------------
    *
    */

    function classesByPage(uint8 page) external view returns (string[10] memory results) {
        for (uint8 i = page * 10; i < (page + 1) * 10; i++) {
            results[i] = classes[(page * 10) + i];
        }
    }

    function originsByPage(uint8 page) external view returns (string[10] memory results) {
        for (uint8 i = page * 10; i < (page + 1) * 10; i++) {
            results[i] = origins[(page * 10) + i];
        }
    }
    function spritesByPage(uint8 page) external view returns (string[10] memory results) {
        for (uint8 i = page * 10; i < (page + 1) * 10; i++) {
            results[i] = sprites[(page * 10) + i];
        }
    }
    function personalitiesByPage(uint8 page) external view returns (string[10] memory results) {
        for (uint8 i = page * 10; i < (page + 1) * 10; i++) {
            results[i] = personalities[(page * 10) + i];
        }
    }
    function devicesByPage(uint8 page) external view returns (string[10] memory results) {
        for (uint8 i = page * 10; i < (page + 1) * 10; i++) {
            results[i] = devices[(page * 10) + i];
        }
    }

    /**
    *
    * -------------------------------- WRITE [ADMIN] --------------------------------------
    *
    */

    /**
    * @dev set a class in our masterList
    */
    function setClass(uint8 id, string calldata class) external onlyOwner {
        classes[id] = class;
    }

    /**
    * @dev set an origin in our masterList
    */
    function setOrigin(uint8 id, string calldata origin) external onlyOwner {
        origins[id] = origin;
    }

    /**
    * @dev set a sprite in our masterList
    */
    function setSprite(uint8 id, string calldata sprite) external onlyOwner {
        sprites[id] = sprite;
    }

    /**
    * @dev set a personality in our masterList
    */
    function setPersonality(uint8 id, string calldata personality) external onlyOwner {
        personalities[id] = personality;
    }

    /**
    * @dev set a device in our masterList
    */
    function setDevice(uint8 id, string calldata device) external onlyOwner {
        devices[id] = device;
    }
}



    struct OwnedTokensData {
        string purpose;
        uint tokenId;
    }
/**
* @dev functions for handling the other NFT tokens a Pal can own
*  - when a Pal 'owns' another token, that token sits in the main contract, with the tokenId assigned to the Pal.
*    This means, when a pal is sold/transferred so are the things that Pal owns
*/
contract PalOwnedTokens is IERC721Receiver, Ownable {

    event PalOwnedTokenAdded(uint tokenId, uint ownedTokenId, string purpose);
    event PalOwnedTokenRemoved(uint tokenId, uint ownedTokenId, string purpose);
    event ContractForPurposeAdded(string purpose, address contractAddress);

    PocketPals public pocketPals;

    /**
    * @dev this allows us to add an indefinite amount of 'owned token purposes', such as Skin, Background
    *  as well as something like a backpack/inventory with `inventory_1', 'inventory_2', etc
    */
    mapping(uint => mapping(string => uint)) public palOwnedTokens; // palTokenId => purpose => tokenId
    mapping(string => address) public contractAddressesForOwnedTokens; // purpose (eg skin) => contract address for that thing

    /**
    * @dev the set of keys from the above mapping we are interested in
    */
    string[] public palOwnedTokenPurposes;


    constructor(address pocketPalsAddress) {
        pocketPals = PocketPals(pocketPalsAddress);
    }

    /**
    *
    * ----------------------------------- READ --------------------------------------
    *
    */
    function ownedTokensByPage(uint palTokenId, uint page) external view returns (OwnedTokensData[10] memory ownedTokens) {
        pocketPals.verifyPalIsOnThisChain(palTokenId);
        for (uint i = 0; i < 10; i++) {
            uint purposeIndex = (page * 10) + i;
            if (purposeIndex < palOwnedTokenPurposes.length) {
                ownedTokens[i] = OwnedTokensData(palOwnedTokenPurposes[purposeIndex], palOwnedTokens[palTokenId][palOwnedTokenPurposes[purposeIndex]]);
            } else {
                ownedTokens[i] = OwnedTokensData("unused", 0);
            }
        }
    }

    /**
    *
    * ----------------------------------- WRITE [GAMEPLAY] --------------------------------------
    *
    */

    /**
    * @dev set a token as 'owned' for a given purpose.
    *  - we remove any existing owned token and transfer it to the owner of the Pal
    *    then transfer the new token in and assign it to the Pal
    */
    function setOwnedTokenForPurpose(uint palTokenId, uint ownedTokenId, string calldata purpose) external {
        pocketPals.validatePermission('ownedTokens', msg.sender);
        pocketPals.verifyPalIsOnThisChain(palTokenId);
        address contractForPurpose = contractAddressesForOwnedTokens[purpose];
        require(contractForPurpose != address(0), "PalOwnedTokens: Unsupported purpose");
        address owner = pocketPals.ownerOf(palTokenId);
        require(owner == IERC721(contractForPurpose).ownerOf(ownedTokenId), "PalOwnedTokens: Only the owner of both NFTs can do this");
        if (palOwnedTokens[palTokenId][purpose] != 0) {
            uint removedTokenId = palOwnedTokens[palTokenId][purpose];
            IERC721(contractForPurpose).safeTransferFrom(address(this), owner, palOwnedTokens[palTokenId][purpose]);
            emit PalOwnedTokenRemoved(palTokenId, removedTokenId, purpose);
        }

        // requires an approval first!. Will fail if the owner of the pal doesn't also own the other token;
        IERC721(contractForPurpose).safeTransferFrom(owner, address(this), ownedTokenId);
        palOwnedTokens[palTokenId][purpose] = ownedTokenId;
        emit PalOwnedTokenAdded(palTokenId, ownedTokenId, purpose);
    }

    /**
    * @dev remove an owned token, returning it to the wallet of the owner of the Pal
    */
    function removeOwnedToken(uint palTokenId, string calldata purpose) external {
        pocketPals.validatePermission('ownedTokens', msg.sender);
        pocketPals.verifyPalIsOnThisChain(palTokenId);
        address contractForPurpose = contractAddressesForOwnedTokens[purpose];
        require(contractForPurpose != address(0), "PalOwnedTokens: Unsupported purpose");
        require(palOwnedTokens[palTokenId][purpose] != 0, "PalOwnedTokens: Pal has no token for this purpose");
        uint removedTokenId = palOwnedTokens[palTokenId][purpose];
        palOwnedTokens[palTokenId][purpose] = 0;
        IERC721(contractForPurpose).safeTransferFrom(address(this), pocketPals.ownerOf(palTokenId), removedTokenId);
        emit PalOwnedTokenRemoved(palTokenId, removedTokenId, purpose);
    }


    /**
    *
    * --------------------------------- WRITE [ADMIN] ------------------------------------
    *
    */

    function addContractAddressForPurpose(address contractAddress, string calldata purpose) external onlyOwner {
        require(contractAddressesForOwnedTokens[purpose] == address(0), "PalOwnedTokens: Cannot change an existing address");
        contractAddressesForOwnedTokens[purpose] = contractAddress;
        palOwnedTokenPurposes.push(purpose);
        emit ContractForPurposeAdded(purpose, contractAddress);
    }

    /**
    *
    * ------------------------------- MAGIC BEANS ----------------------------------
    *
    */

    function onERC721Received(address, address, uint256, bytes calldata) public view override returns (bytes4) {
        return IERC721Receiver(this).onERC721Received.selector;
    }
}


// File contracts/PalMetadata.sol

/**
* @dev a standalone contract that provides the functions required to serve our on-chain metadata to marketplaces:
- we have a server running that will call `tokenMetadata` to get metadata for a given token when requested
- our tokenURI function in the main PocketPals contract will return [metadataReaderURL]/tokenId, where metadataReaderURL
  is the address of the server, so marketplaces can hit that to get our full metadata
*/
contract PalMetadata is PalVariables {

    PocketPals public pocketPals; // the main PocketPals contract
    PalOwnedTokens public palOwnedTokens; // the PalOwnedTokens contract

    string public deadImageURL = "https://cdn.eteknix.com/wp-content/uploads/2014/07/ios-flat-battery.jpg";
    string public metadataReaderURL = "https://pocketpals.io/metadata/read/";

    /**
    * @dev the ones that we want to appear in our metadata:
    */
    string[] public palOwnedTokenPurposesToDisplayInMetadata;

    /**
    * @dev the data we display in marketplaces
    * - this struct is returned to our metadata server so marketplaces can display it
    */
    struct Metadata { // TODO: should most of these be in an attributes array??
        uint8 series; // 0 = classic, non-zero = specials with certain restrictions
        uint64 mood;
        uint64 energy;
        uint nemesis; // tokenId
        uint tokenId;
        string device;
        string name; // the name of the Pal
        string sprite;
        string class; // ranger, melee
        string origin; // country
        string personality;
        string image;
        address owner;
        PalImageData imageData;
        PalDevelopment development;
        Stats stats;
        OwnedTokensData[10] ownedTokens;
        RepertoireMove[] repertoire;
    }

    constructor(address pocketPalsAddress, address palOwnedTokensAddress) {
        pocketPals = PocketPals(pocketPalsAddress);
        palOwnedTokens = PalOwnedTokens(palOwnedTokensAddress);
    }

    /**
    *
    * ----------------------------------- READ --------------------------------------
    *
    */

    /**
    * @dev returns metadata to our metadataReader API, so metadata can display in marketplaces
    */
    function tokenMetadata(uint tokenId) public view returns (Metadata memory metadata) {
        Pal memory pal = pocketPals.getPal(tokenId);

        metadata.series = pal.series;
        metadata.device = devices[pal.device];
        metadata.mood = pal.mood;
        metadata.energy = pal.energy;
        metadata.nemesis = pal.nemesis;
        metadata.tokenId = tokenId;
        metadata.name = pal.name;
        metadata.sprite = sprites[pal.sprite];
        metadata.class = classes[pal.class];
        metadata.origin = origins[pal.origin];
        metadata.personality = personalities[pal.personality];
        metadata.image = pal.energy == 0 ? pal.imageData.imageDead : pal.imageData.image;

        metadata.owner = pocketPals.ownerOf(tokenId);

        metadata.imageData = pal.imageData;

        metadata.development = pal.development;
        metadata.stats = pal.stats;

        // NOTE: we only return the first 10 owned tokens in metadata.  We don't expect to have more than 10
        metadata.ownedTokens = palOwnedTokens.ownedTokensByPage(tokenId, 0);

        metadata.repertoire = pocketPals.repertoireForPal(tokenId);
    }


    /**
    *
    * -------------------------------- WRITE [ADMIN] --------------------------------------
    *
    */

    /**
    * @dev set the url of the image that displays when the Pal's battery is flat
    */
    function setDeadImageURL(string calldata url) external onlyOwner {
        deadImageURL = url;
    }

    /**
    * @dev set the url of our metadata reader
    */
    function setMetadataReaderURL(string calldata url) external onlyOwner {
        metadataReaderURL = url;
    }

    /**
    * @dev Caution! this overwrites our existing list!
    */
    function setMetadataRequiredPalOwnedTokenPurposes(string[] memory purposes) external onlyOwner {
        palOwnedTokenPurposesToDisplayInMetadata = purposes;
    }

}


// File contracts/PocketPals.sol


contract PocketPals is PalMintAndUpdate  {
    using DiminishesWithTime for DiminishesWithTime.DiminishingValue;
    using Strings for uint256;

    PalMetadata public palMetadata; // the contract for pulling metadata for marketplaces

    constructor(uint8 _chain)  {
        chain = _chain;
        _tokenIds._value = uint(_chain) * 1000000;
    }

    /**
    *
    * ----------------------------------- READ --------------------------------------
    *
    */

    function getPal(uint tokenId) external view returns (Pal memory pal) {
        require(tokenId != 0, "PocketPals: No token at 0!");
        _requirePalOnThisChain(tokenId);

        pal = pals[tokenId];
        pal.energy = palEnergy[tokenId].value();
        pal.mood = palMood[tokenId].value();
    }

    /**
    * @dev returns a tokenUri pointing at our metadataReader (see PalMetadata base contract for more)
    */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requirePalOnThisChain(tokenId);
        return string(abi.encodePacked(palMetadata.metadataReaderURL(), tokenId.toString()));
    }


    /**
    *
    * ----------------------------------- WRITE --------------------------------------
    *
    */


    function updateStats(uint tokenId, Stats memory stats) external {
        _requirePalOnThisChain(tokenId);
        validatePermission('stats');
        pals[tokenId].stats = stats;
    }

    function updateDevelopment(uint tokenId, PalDevelopment memory development) external {
        _requirePalOnThisChain(tokenId);
        validatePermission('development');
        pals[tokenId].development = development;
    }

    function updateStandings(uint tokenId, PalStandings memory standings) external {
        _requirePalOnThisChain(tokenId);
        validatePermission('standings');
        pals[tokenId].standings = standings;
    }

    function addAchievement(uint tokenId, string calldata achievement) external {
        _requirePalOnThisChain(tokenId);
        validatePermission('achievements');
        pals[tokenId].achievements.push(achievement);
    }

    function changeName(uint tokenId, string calldata name) external {
        _requirePalOnThisChain(tokenId);
        require(ownerOf(tokenId) == msg.sender, "PocketPals: Only the owner can change the name!");
        pals[tokenId].name = name;
    }

    function setImage(uint tokenId, PalImageData calldata imageData) external {
        _requirePalOnThisChain(tokenId);
        validatePermission('image');
        pals[tokenId].imageData = imageData;
    }



    /**
    *
    * -------------------------------- WRITE [ADMIN] --------------------------------------
    *
    */
    function setPalMetadata(address contractAddress) external onlyOwner {
        palMetadata = PalMetadata(contractAddress);
    }

}