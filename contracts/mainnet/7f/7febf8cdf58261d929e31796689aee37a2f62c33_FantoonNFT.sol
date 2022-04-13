/**
 *Submitted for verification at FtmScan.com on 2022-04-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint a, uint b) internal pure returns (bool, uint) {
    unchecked {
        uint c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint a, uint b) internal pure returns (bool, uint) {
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
    function tryMul(uint a, uint b) internal pure returns (bool, uint) {
    unchecked {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint a, uint b) internal pure returns (bool, uint) {
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
    function tryMod(uint a, uint b) internal pure returns (bool, uint) {
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
    function add(uint a, uint b) internal pure returns (uint) {
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
    function sub(uint a, uint b) internal pure returns (uint) {
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
    function mul(uint a, uint b) internal pure returns (uint) {
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
    function div(uint a, uint b) internal pure returns (uint) {
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
    function mod(uint a, uint b) internal pure returns (uint) {
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
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
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
    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

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
        uint _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint` to its ASCII `string` decimal representation.
     */
    function toString(uint value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint temp = value;
        uint length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint value, uint length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

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

        uint size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
    function onERC721Received(address operator, address from, uint tokenId, bytes calldata data) external returns (bytes4);
}

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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint tokenId) external view returns (address owner);

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
    function safeTransferFrom(address from, address to, uint tokenId) external;

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
    function transferFrom(address from, address to, uint tokenId) external;

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
    function approve(address to, uint tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint tokenId) external view returns (address operator);

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
    function safeTransferFrom(address from, address to, uint tokenId, bytes calldata data) external;
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint index) external view returns (uint tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint index) external view returns (uint);
}


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
    function tokenURI(uint tokenId) external view returns (string memory);
}


/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint) private _balances;

    // Mapping from token ID to approved address
    mapping (uint => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
        || interfaceId == type(IERC721Metadata).interfaceId
        || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint tokenId) public view virtual override returns (address) {
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
    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
    function transferFrom(address from, address to, uint tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint tokenId, bytes memory _data) internal virtual {
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
    function _exists(uint tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint tokenId) internal view virtual returns (bool) {
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
    function _safeMint(address to, uint tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
    function _mint(address to, uint tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, true);

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
    function _burn(uint tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, true);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _burnSave(address owner, uint tokenId) internal virtual {

        _beforeTokenTransfer(owner, address(0), tokenId, false);

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
    function _transfer(address from, address to, uint tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, true);

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
    function _approve(address to, uint tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint tokenId, bytes memory _data)
    private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint tokenId, bool isDelete) internal virtual { }
}

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint => uint)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint => uint) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint => uint) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId
        || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint index) public view virtual override returns (uint) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint index) public view virtual override returns (uint) {
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
    function _beforeTokenTransfer(address from, address to, uint tokenId, bool isDelete) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, isDelete);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0) && isDelete) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from && isDelete) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint tokenId) private {
        uint length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint lastTokenId = _ownedTokens[from][lastTokenIndex];

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
     * @param tokenId uint ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint lastTokenIndex = _allTokens.length - 1;
        uint tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

interface Diamond {
    function sendDividends(uint _amount, bool nftContract) external;
    function dividendNFTTracker() external returns (address);
    function withdrawableDividendOf(address account, bool nftContract) external view returns(uint);
    function withdrawnDividendOf(address account, bool nftContract) external view returns(uint);
    function claimFromFantoonNFT(address account) external;
}

contract FantoonNFT is ERC721Enumerable, Ownable{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;

    uint public currentPrice;
    uint private previousPrice;
    uint private addPriceIncrease = 0; //0.3 ether;

    uint private max_Kittens = 300;
    uint private max_TokenCountOfAccount = 10;
    
    address private developerWallet;
    bool private enableMintTax = true;
    uint private mintTaxRateForDeveloper = 5000;            // 50%

    bool private enableDistributeShare = false;
    
    struct DistributeShareInfo {
        address _account;
        uint _share;
    }

    DistributeShareInfo[] private _distributeShareInfo;
    
    enum Status {
        Pending,
        Reserved,
        Minted
    }
    
    mapping(uint => Status) private _tokenStatus;
    mapping(uint => uint) private _tokenPrice;
    mapping(address => uint) private _tokenCountOfAccount;
    
    struct ReservedToken {
        uint[] tokenId;
        uint[] price;
    }
    
    mapping (address => ReservedToken) private  _reservedInfo;
    
    uint private currentReservedTokenId = 0;
    uint private reservePrice = 1 ether;
    uint private reservedPeriod = 30 minutes; //24 hours;                 // 24 hours
    uint private mintReservedTokenPeriod = 400 minutes; //24 hours;        // 24 hours
    uint private initialTime;
    uint private initialPrice = 250 ether;

    uint private amountOfOGShareDistribute;
    uint private amountOfOGShareDistributePumpkitten;
    uint private amountOfOGShareDistributeBitkitten;
    uint private amountOfOGShareDistributeSamurai;

    // Info of each reward.
    uint[] public _distributeRewards;

    mapping (address=> mapping(uint=>uint)) public _nextWithdrawRewards;

    bool private enableOGSharedistribute = true;
    mapping (address => bool) private _excludedHolders;

    // NFT contracts in mainnet
    
    address private constant addressOfPumpkitten = address(0xF185cf59c710a0E83362fb7B8813b633Ba073600);
    address private constant addressOfBitkitten = address(0x4a0FBe0Af74Cf38bcd5C68f1D6bf2Cc0899cc0FF);
    address private constant addressOfSamuraikitten = address(0x896D8347652e190f3CdB909938A0e7447aBA8bB5);

    // NFT contracts in testnet
    /*
    address private constant addressOfPumpkitten = address(0x4538d83c2F5df508Da52a5cD283c35d8F598DF59);
    address private constant addressOfBitkitten = address(0xf611BbC09ACA2bb15974F99673951b453Ec269e5);
    address private constant addressOfSamuraikitten = address(0x97683815b36cF9d8ED8Aed50DBC8fAB2C12D2508);
    */

    address private diamond;

    mapping (address => uint) private mapRewardsForAccount;
    mapping (address => uint) private _claimedFTM;
    
    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Fantoon NFT: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(address _diamond) ERC721("MexiTails", "MXT") {
        diamond = _diamond;

        currentPrice = reservePrice;
        initialTime = block.timestamp;
    }
    
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setDeveloperWallet(address _account) public onlyOwner {
        require(_account != address(0), "Cannot be zero address");
        developerWallet = _account;
    }  

    function setMintTaxRateForDeveloper(uint _rate) public onlyOwner {
        require(_rate > 0, "Cannot be zero value");
        mintTaxRateForDeveloper = _rate;
    }
    
    function setEnableMintTax(bool _enable) public onlyOwner {
        enableMintTax = _enable;
    }
    
    function buyKittens() public payable lock {
        require(_tokenIdTracker.current() <= max_Kittens, "Too Many Tokens");
        require(_tokenCountOfAccount[_msgSender()] < max_TokenCountOfAccount, "Too Many Tokens For a Account");

        require(!((block.timestamp - initialTime) < mintReservedTokenPeriod 
                    && !isReservedAddress(_msgSender())), "Not right to mint now");
        
        if ((block.timestamp - initialTime) <= mintReservedTokenPeriod) {
            for (uint i=0; i<max_TokenCountOfAccount; i++) {
                uint tokenId = _reservedInfo[_msgSender()].tokenId[i];

                if (tokenId == 0 || _tokenStatus[tokenId] == Status.Minted)
                    continue;
                
                _tokenIdTracker.increment();
                
                require(msg.value >= _reservedInfo[_msgSender()].price[i]);
                
                _mint(_msgSender(), tokenId);
                
                _tokenCountOfAccount[_msgSender()] ++;
                
                _tokenStatus[tokenId] = Status.Minted;
                _tokenPrice[tokenId] = _reservedInfo[_msgSender()].price[i];
                            
                previousPrice =  _reservedInfo[_msgSender()].price[i];
                _reservedInfo[_msgSender()].price[i] = 0;
                
                break;
            }
        }
        else{
            uint tokenId;

            if (initialPrice > 0) {
                currentPrice = initialPrice;
                initialPrice = 0;
            }

             for (uint i=1; i<= max_Kittens; i++) {
                if (_tokenStatus[i] == Status.Pending) {
                    tokenId = i;
                    break;
                }
            }

            _tokenIdTracker.increment();
            
            require(msg.value >= currentPrice);
            
            _mint(_msgSender(), tokenId);
            
            _tokenStatus[tokenId] = Status.Minted;
            _tokenPrice[tokenId] = currentPrice;
            
            _tokenCountOfAccount[_msgSender()] ++;
                        
            previousPrice = currentPrice;
            currentPrice = previousPrice + addPriceIncrease;
        }
        
        uint mintTaxAmount;
        if (
            enableMintTax 
            && mintTaxRateForDeveloper > 0 
            && developerWallet != address(0)) {
            mintTaxAmount = previousPrice * mintTaxRateForDeveloper / (10000);
            
            require(payable(developerWallet).send(mintTaxAmount));
        }
        
        if (enableOGSharedistribute) {
            uint amount = previousPrice * 4500 / 10000;     // send 45% = 15% * 3 to 3 NFT holders
            sendDividendsforNFTHolders(amount);

            amount = previousPrice - mintTaxAmount - amount; // send 5% ( = 100% - 50% - 15% * 3)to Diamond holders
            sendDividendsforDiamondHolders(amount);
        }

        if (enableDistributeShare) {
            address account;
            uint amount;
            uint nlength = _distributeShareInfo.length;
            for(uint i=0; i<nlength; i++) {
                account = _distributeShareInfo[i]._account;
                amount = previousPrice * _distributeShareInfo[i]._share / (10000);
    
                require(amount < address(this).balance, "Balance is insufficient");
    
                payable(account).transfer(amount);
            }  
        }
    }

    function sendDividendsforNFTHolders(uint _amount) internal {
        uint length = ERC721Enumerable(addressOfPumpkitten).totalSupply();
        length += ERC721Enumerable(addressOfBitkitten).totalSupply();
        length += ERC721Enumerable(addressOfSamuraikitten).totalSupply();

        require(length > 0, "No NFT Hoders.");

        uint share = _amount / length;

        _distributeRewards.push(share);
    }

    /**
     * @notice Send transaction fee to dividend trancer.
     */
    function sendDividendsforDiamondHolders(uint _amount) internal {
        Diamond(diamond).sendDividends(_amount, true);
    }

    function getRewardsOfTokenId(address _nftAddress, uint _tokenId) internal view returns(uint) {
        uint nextWithdrawRewards = _nextWithdrawRewards[_nftAddress][_tokenId];

        uint rewards;
        uint length = _distributeRewards.length;
        for (uint i=nextWithdrawRewards; i<length; i++) {
            rewards += _distributeRewards[i];
        }

        return rewards;
    }

    function getTotalRewardsOfNFT(address _nftAddress, address _account) internal view returns(uint) {
        uint balance = ERC721Enumerable(_nftAddress).balanceOf(_account);

        uint rewards;
        uint tokenId;
        for (uint i=0; i<balance; i++) {
            tokenId = ERC721Enumerable(_nftAddress).tokenOfOwnerByIndex(_account, i);
            rewards += getRewardsOfTokenId(_nftAddress, tokenId);
        }

        return rewards;
    }
    
    function getPendingRewardsFromNFTs(address _account) internal view returns(uint) {
        uint totalRewards;

        totalRewards = getTotalRewardsOfNFT(addressOfPumpkitten, _account);
        totalRewards += getTotalRewardsOfNFT(addressOfBitkitten, _account);
        totalRewards += getTotalRewardsOfNFT(addressOfSamuraikitten, _account);

        return totalRewards;
    }

    function withdrawableFTM(address _account) public view returns (uint){
        require(_account != address(0), "Wrong address");

        if (_excludedHolders[_account] == true )
            return 0;

        uint withdrawableAmountFromDiamond = Diamond(diamond).withdrawableDividendOf(_account, true);
        uint withdrawableAmountFromNFTs = getPendingRewardsFromNFTs(_account);

        return withdrawableAmountFromNFTs + withdrawableAmountFromDiamond;
    }

    function withdrawnFTM(address _account) public view returns (uint){
        require(_account != address(0), "Wrong address");

        return _claimedFTM[_account];
    }
    
    function claimFTM() external lock {
        require(_excludedHolders[msg.sender] == false, 'You are excluded.');

        uint withdrawableAmountFromDiamond = Diamond(diamond).withdrawableDividendOf(msg.sender, true);
        uint withdrawableAmountFromNFTs = getPendingRewardsFromNFTs(msg.sender);
        uint totalRewards = withdrawableAmountFromDiamond + withdrawableAmountFromNFTs;
        
        require(totalRewards <= address(this).balance, "Insufficient balance.");
        
        require(payable(msg.sender).send(totalRewards));

        _claimedFTM[msg.sender] += totalRewards;

        Diamond(diamond).claimFromFantoonNFT(msg.sender);

        updateAllNFTs(msg.sender);
    }

    function updateAllNFTs(address _account) internal {
        uint balance = ERC721Enumerable(addressOfPumpkitten).balanceOf(_account);
        uint tokenId;
        for (uint i=0; i<balance; i++) {
            tokenId = ERC721Enumerable(addressOfPumpkitten).tokenOfOwnerByIndex(_account, i);
            _nextWithdrawRewards[addressOfPumpkitten][tokenId] = _distributeRewards.length;
        }

        balance = ERC721Enumerable(addressOfBitkitten).balanceOf(_account);
        for (uint i=0; i<balance; i++) {
            tokenId = ERC721Enumerable(addressOfBitkitten).tokenOfOwnerByIndex(_account, i);
            _nextWithdrawRewards[addressOfBitkitten][tokenId] = _distributeRewards.length;
        }

        balance = ERC721Enumerable(addressOfSamuraikitten).balanceOf(_account);
        for (uint i=0; i<balance; i++) {
            tokenId = ERC721Enumerable(addressOfSamuraikitten).tokenOfOwnerByIndex(_account, i);
            _nextWithdrawRewards[addressOfSamuraikitten][tokenId] = _distributeRewards.length;
        }
    }
    
    function setOGShareDistribute(bool enable) public onlyOwner {
        enableOGSharedistribute = enable;
    }
    
    function setExcludedListOGShareDistribute(address account) public onlyOwner {
        _excludedHolders[account] = true;
    }
    
    function setExcludedTokenListOGShareDistribute(uint tokenId, address nft) public onlyOwner {
        address account = ERC721Enumerable(nft).ownerOf(tokenId);
        _excludedHolders[account] = true;
    }

    function addReserveToken(address account) public onlyOwner {
        require((block.timestamp - initialTime) < reservedPeriod, "End time");

        uint currentReservedCount = _reservedInfo[account].tokenId.length;
        require(currentReservedCount < max_TokenCountOfAccount, "Too Many Tokens");

        uint addLength = max_TokenCountOfAccount - currentReservedCount;
        uint index;
        for (uint i=1; i<=max_Kittens; i++) {
            if (_tokenStatus[i] != Status.Pending)
                continue;

            _reservedInfo[account].price.push(currentPrice);
            _reservedInfo[account].tokenId.push(i);
            
            _tokenStatus[i] = Status.Reserved;
            
            previousPrice = currentPrice;
            currentPrice = previousPrice + addPriceIncrease;

            index++;
            if (index == addLength)
                break;
        }
    }

    function addReserveRandomTokens(uint[] memory tokenIds, address account) public onlyOwner {
        require((block.timestamp - initialTime) < reservedPeriod, "End Reserve period.");

        uint currentReservedCount = _reservedInfo[account].tokenId.length;

        require(currentReservedCount < max_TokenCountOfAccount, "Too Many Tokens");
        require(currentReservedCount + tokenIds.length <= max_TokenCountOfAccount, "Too Many Tokens");
        
        uint length = tokenIds.length;

        for (uint i=0; i<length; i++) {
            require(_tokenStatus[tokenIds[i]] == Status.Pending, "Token already reserved.");

            _reservedInfo[account].price.push(currentPrice);
            _reservedInfo[account].tokenId.push(tokenIds[i]);
            
            _tokenStatus[tokenIds[i]] = Status.Reserved;
            
            previousPrice = currentPrice;
            currentPrice = previousPrice + addPriceIncrease;
        }
    }
    
    function deleteReserveToken(address account) public onlyOwner {
        uint length = _reservedInfo[account].tokenId.length;

        for (uint i=0; i<length; i++)
        {
            _tokenStatus[ _reservedInfo[account].tokenId[i]] = Status.Pending;
            _reservedInfo[account].tokenId[i] = 0;
            _reservedInfo[account].price[i] = 0;
        }

        delete _reservedInfo[account].tokenId;
        delete _reservedInfo[account].price;
    }
    
    function getReservedTokenPrice(address account) public view returns (uint) {
        uint length = _reservedInfo[account].price.length;
        
        if (length == 0)
            return 0;
        
        uint price;
        for (uint i=0; i<length; i++) {
            price = _reservedInfo[account].price[i];
            if (price > 0)
                break;
        }
        
        return price;
    }
    
    function getReservedTokenInfo(address account) public view returns (ReservedToken memory) {
        return _reservedInfo[account];
    }
    
    function isReservedAddress(address account) public view returns (bool) {
        if (_reservedInfo[account].tokenId.length > 0)
            return true;
        
        return false;
    }
    
    function isReservePeriod() public view returns (bool) {
        if (block.timestamp - initialTime > mintReservedTokenPeriod)
            return false;
        
        return true;
    }

    function setInitialPrice(uint _price) public onlyOwner {
        require(_price > 0, "Price is wrong");
        initialPrice = _price;
    }
    
    function setPrice(uint _price) public onlyOwner {
        currentPrice = _price;
    }
    
    function getPrice() public view returns(uint) {
        if (_tokenIdTracker.current() == max_Kittens)
            return 0;
            
        if (block.timestamp - initialTime > mintReservedTokenPeriod) {
            if (initialPrice > 0)
                return initialPrice;
        }
        else 
            return 0;

        return currentPrice;
    }
    
    function setAddPriceIncrease(uint _increase) public onlyOwner {
        addPriceIncrease = _increase;
    }
    
    function getAddPriceIncrease() public view returns(uint) {
        return addPriceIncrease;
    }
    
    function withdrawAll() public payable onlyOwner {
        require(address(this).balance > 0, "No balance of FTM.");
        require(payable(msg.sender).send(address(this).balance));
    }  
    
    function getTokenCount() public view returns(uint) {
        return _tokenCountOfAccount[address(msg.sender)];
    }
    
    function setMaxKittens(uint amount) public onlyOwner {
        max_Kittens = amount;
    }
    
    function setMaxTokenCountOfAccount(uint amount) public onlyOwner {
        max_TokenCountOfAccount = amount;
    }
    
    function getTokenIdsOfOwner(address account) public view 
        returns(uint[] memory tokenIds, uint[] memory priceOfTokenIds, string[] memory tokenURIs)
    {
        uint balance = balanceOf(account);
        tokenIds = new uint[](balance);
        priceOfTokenIds = new uint[](balance);
        tokenURIs = new string[](balance);
        
        for (uint i=0; i<balance; i++)
        {
            tokenIds[i] = tokenOfOwnerByIndex(account, i);
            priceOfTokenIds[i] = _tokenPrice[tokenIds[i]];
            tokenURIs[i] = tokenURI(tokenIds[i]);
        }
    }
    
    function setDistributeShare(bool enable) public onlyOwner {
        enableDistributeShare = enable;
    }

    function addListForDistributeShare(address _account, uint _share) public onlyOwner {
        require(_account != address(0), "Address is wrong.");

        DistributeShareInfo memory info;
        info._account = _account;
        info._share = _share;
        
        uint nlength = _distributeShareInfo.length;
        address account;
        for(uint i=0; i<nlength; i++) {
            account = _distributeShareInfo[i]._account;

            if (account == _account)
            {
                _distributeShareInfo[i]._share = _share;
                return;
            }
        }

        _distributeShareInfo.push(info);
    }
    
    function setReservePeriod(uint _period) public onlyOwner {
        reservedPeriod = _period;
    }
    
    function setMintReservedTokenPeriod(uint _period) public onlyOwner {
        mintReservedTokenPeriod = _period;
    }
    
    function destroySmartContract(address payable _to) public onlyOwner{
        selfdestruct(_to);
    }
}