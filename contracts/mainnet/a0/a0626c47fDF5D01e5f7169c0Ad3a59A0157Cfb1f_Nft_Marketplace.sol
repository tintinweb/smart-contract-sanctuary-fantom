pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT


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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
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
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

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


abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

        uint256 size;
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
    function sendValue(address payable recipient, uint256 amount) internal {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

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
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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
    constructor() {
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
}
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
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

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
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

interface INft_Marketplace {

    struct Order {
        // Order ID
        bytes32 id;
        // Owner of the NFT[o]
        address seller;
        // NFT registry address
        address nftAddress;
        // Price for the published item
        uint256 price;
        
        uint256 minBidPrice;
        //address creator;

        //uint256 royalty;
        // // Time when this sale ends
        // uint256 expiresAt;
    }

    struct Bid {
        // Bid Id
        bytes32 id;
        // Bidder address
        address bidder;
        // accepted token
        uint256 price;
        // // Time when this bid ends
        // uint256 expiresAt;
    }

    // ORDER EVENTS
    event OrderCreated(
        bytes32 id,
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed assetId,
        uint256 priceInWei,
        uint256 minBidPriceInWei
        // uint256 expiresAt
    );

    event OrderUpdated(
        bytes32 id,
        uint256 price
        // uint256 expiresAt
    );

    event OrderSuccessful(
        bytes32 id,
        address indexed buyer,
        uint256 price
    );

    event OrderCancelled(bytes32 id);

    // BID EVENTS
    event BidCreated(
      bytes32 id,
      address indexed nftAddress,
      uint256 indexed assetId,
      address indexed bidder,
      uint256 price
    //   uint256 expiresAt
    );

    event BidAccepted(bytes32 id);
    event BidCancelled(bytes32 id);
    event UserReclaim(address indexed seller);
    event NFTMarketPlaceOwnerReclaim(address indexed ContractOwner);
}

contract FeeManager is Ownable {

    event ChangedFeePerMillion(uint256 cutPerMillion);

    // Market fee on sales
    uint256 public cutPerMillion = 50000; //5% cut
    uint256 public constant maxCutPerMillion = 100000; // 10% cut

    /**
     * Sets the share cut for the owner of the contract that's
     * charged to the seller on a successful sale
     * Share amount, from 0 to 99,999
     */
    function setOwnerCutPerMillion(uint256 _cutPerMillion) external onlyOwner {
        require(
            _cutPerMillion < maxCutPerMillion,
            "The owner cut should be between 0 and maxCutPerMillion"
        );

        cutPerMillion = _cutPerMillion;
        emit ChangedFeePerMillion(cutPerMillion);
    }
} 

contract Nft_Marketplace is INft_Marketplace, FeeManager {
  using SafeMath for uint256;

  // From ERC721 registry assetId to Order (to avoid asset collision)
  mapping(address => mapping(uint256 => Order)) public orderByAssetId;

  // From ERC721 registry assetId to Bid (to avoid asset collision)
  mapping(address => mapping(uint256 => Bid)) public bidByOrderId;

  // this mapping to save the BNB amount for the user locked in the contract
  mapping(address => uint256) public userBalances;

  // this mapping will know how many BNBs as Fees required from every user
  // so that when he reclaims his BNB we will cut the fee amount
  mapping(address => uint256) public userFeesBalances;

  // this mapping to save the bidding of users owned BNBs
  mapping(address => uint256) public userBiddingBalance;

  // this mapping to save the Fees collected from the users trarnsactions and saved into the NFTMarketplace owner account
  // so he can withdraw them
  mapping(address => uint256) public NFTMarketplaceOwnerBalance;


  // 721 Interfaces
  bytes4 public constant _INTERFACE_ID_ERC721 = 0x80ac58cd;  
  address public tokenOwner;
  address NFTMarketplaceOwner;

  constructor () {
    NFTMarketplaceOwner = msg.sender;
  }

  /**
   * Creates a new order
   *  _nftAddress - Non fungible contract address
   *  _assetId - ID of the published NFT
   *  _expiresAt - Duration of the order (in hours)
   *  _expiresAt - the amount of days before the order expire
   */
  function createOrder(
    address _nftAddress,
    uint256 _assetId,
    uint256 _price,
    uint256 _minBidPrice
    // uint256 _expiresAt
  ) public {
    _createOrder(_nftAddress, _assetId, _price, _minBidPrice);
  }

  /**
   *  Cancel an already published order
   *  can only be canceled by seller or the contract owner
   *  nftAddress - Address of the NFT registry
   *  assetId - ID of the published NFT
   */
  function cancelOrder(address _nftAddress, uint256 _assetId) public {
    Order memory order = orderByAssetId[_nftAddress][_assetId];

    require(order.seller == msg.sender, "Marketplace: unauthorized sender");

    // Remove pending bid if any
    Bid memory bid = bidByOrderId[_nftAddress][_assetId];
    

    if (bid.id != 0) {
      _cancelBid(bid.id, _nftAddress, _assetId, payable(bid.bidder), bid.price);
    }

    // Cancel order.
    _cancelOrder(order.id, _nftAddress, _assetId, msg.sender);
  }

  /**
   * @dev Update an already published order
   *  can only be updated by seller
   * @param _nftAddress - Address of the NFT registry
   * @param _assetId - ID of the published NFT
   */
  function updateOrder(
    address _nftAddress,
    uint256 _assetId,
    uint256 _price
    // uint256 _expiresAt
  ) public {
    Order memory order = orderByAssetId[_nftAddress][_assetId];

    // Check valid order to update
    require(order.id != 0, "Marketplace: asset not published");
    require(order.seller == msg.sender, "Marketplace: sender not allowed");
    // require(order.expiresAt >= block.timestamp, "Marketplace: order expired");

    // check order updated params
    require(_price > 0, "Marketplace: Price should be bigger than 0");
    // require(
    //   _expiresAt > block.timestamp.add(1 minutes),
    //   "Marketplace: Expire time should be more than 1 minute in the future"
    // );

    order.price = _price;
    // order.expiresAt = _expiresAt;

    emit OrderUpdated(order.id, _price);
  }

  /**
   * Executes the sale for a published NFT
   *  nftAddress - Address of the NFT registry
   *  assetId - ID of the published NFT
   *  priceInAnyOfTheFourCurrencies - Order price
   */

  function safeExecuteOrder(
    address _nftAddress,
    uint256 _assetId,
    uint256 _price
  ) public payable {
    // Get the current valid order for the asset or fail
    Order memory order = _getValidOrder(_nftAddress, _assetId);

    /// Check the execution price matches the order price
    require(order.price == _price, "Marketplace: invalid price");
    require(order.seller != msg.sender, "Marketplace: unauthorized sender");

    // market fee to cut
    uint256 saleShareAmount = 10;

    // Send market fees to owner
    if (FeeManager.cutPerMillion > 0) {
      // Calculate sale share
      saleShareAmount = _price.mul(FeeManager.cutPerMillion).div(1e6);
    }

    /**
     * NOTE: because this function is payable it will be transferring  BNB to the contract address
     *  so when the buyer pays the BNB to the seller, the BNB amount will be transferred  to the contract
     *  and will be stored in the contract and a the amount plus the fees will be saved in mapping
     *  for when the seller reclaims his BNB then the contract will know exactly his BNB amount
     *  and also will know exactly the fee amount that need to be cut
     */

    // save the amount of BNB owned by the seller and locked in the contract
    userBalances[order.seller] = userBalances[order.seller] + _price;

    // saves the amount of Fees on the seller and locked in the contract
    userFeesBalances[order.seller] = userFeesBalances[order.seller] + saleShareAmount;
    payable(order.seller).transfer(msg.value- saleShareAmount);
    // Remove pending bid if any
    Bid memory bid = bidByOrderId[_nftAddress][_assetId];

    if (bid.id != 0) {
      _cancelBid(bid.id, _nftAddress, _assetId, payable(bid.bidder), bid.price);
    }

    _executeOrder(
      order.id,
      msg.sender, // buyer
      _nftAddress,
      _assetId,
      _price
    );
  }

  /**
   *  Places a bid for a published NFT
   *  _nftAddress - Address of the NFT registry
   *  _assetId - ID of the published NFT
   *  _expiresAt - Bid expiration time
   */
  function safePlaceBid(
    address _nftAddress,
    uint256 _assetId
    //uint256 _price
    // uint256 _expiresAt
  ) public payable {
    _createBid(_nftAddress, _assetId);
  }

  /**
   * @dev Cancel an already published bid
   *  can only be canceled by seller or the contract owner
   * @param _nftAddress - Address of the NFT registry
   * @param _assetId - ID of the published NFT
   */
  function cancelBid(
    address _nftAddress,
    uint256 _assetId
  ) public{
    Bid memory bid = bidByOrderId[_nftAddress][_assetId];

    require(
      bid.bidder == msg.sender || msg.sender == owner(),
      "Marketplace: Unauthorized sender"
    );

    _cancelBid(
      bid.id,
      _nftAddress,
      _assetId,
      payable(bid.bidder),
      bid.price
    );
  }

  /**
   * Executes the sale for a published NFT by accepting a current bid
   *  _nftAddress - Address of the NFT registry
   *  _assetId - ID of the published NFT
   *  _priceInAnyOfTheFourCurrencies - price In Any Of The Four Currencies
   */
  function acceptBid(
    address _nftAddress,
    uint256 _assetId
    // uint256 _price
  ) public{
    // check order validity
    Order memory order = _getValidOrder(_nftAddress, _assetId);

    // item seller is the only allowed to accept a bid
    require(order.seller == msg.sender, "Marketplace: unauthorized sender");

    Bid memory bid = bidByOrderId[_nftAddress][_assetId];

    // require(bid.price == _price, "Marketplace: invalid bid price");
    // require(bid.expiresAt >= block.timestamp, "Marketplace: the bid expired");

    // remove bid
    delete bidByOrderId[_nftAddress][_assetId];

    // calc market fees
    uint256 saleShareAmount = bid.price.mul(FeeManager.cutPerMillion).div(1e6);
    uint256 royaltyAmount = 0;//bid.price.mul(order.royalty).div(100);
    //address _creator = order.creator;
    //transfer fee.
    payable(msg.sender).transfer(bid.price- saleShareAmount-royaltyAmount);
    //payable(_creator).transfer(royaltyAmount);
    payable(NFTMarketplaceOwner).transfer(saleShareAmount);
    // remove the bidding balance of the bidder(buyer) from the mapping 
    userBiddingBalance[bid.bidder] = userBiddingBalance[bid.bidder] - bid.price;

    // add the accepted bidding amount to the seller Balances
    userBalances[msg.sender] = userBalances[msg.sender] + bid.price;

    // add the transaction Fee "saleShareAmount" to the mapping
    userFeesBalances[msg.sender] = userFeesBalances[msg.sender] + saleShareAmount;

    _executeOrder(
      order.id,
      bid.bidder,
      _nftAddress,
      _assetId,
      bid.price
    );

    emit BidAccepted(bid.id);
  }

  /**
   * Internal function gets Order by nftRegistry and assetId. Checks for the order validity
   * nftAddress - Address of the NFT registry
   * assetId - ID of the published NFT
   */
  function _getValidOrder(address _nftAddress, uint256 _assetId)
    internal
    view
    returns (Order memory order)
  {
    order = orderByAssetId[_nftAddress][_assetId];

    require(order.id != 0, "Marketplace: asset not published");
    // require(order.expiresAt >= block.timestamp, "Marketplace: order expired");
  }

  /**
   * Executes the sale for a published NFT
   *  orderId - Order Id to execute
   *  buyer - address
   *  nftAddress - Address of the NFT registry
   *  assetId - NFT id
   *  price - Order price
   */
  function _executeOrder(
    bytes32 _orderId,
    address _buyer,
    address _nftAddress,
    uint256 _assetId,
    uint256 _price
  ) internal {
    // remove order
    delete orderByAssetId[_nftAddress][_assetId];

    // Transfer NFT asset
    IERC721(_nftAddress).transferFrom(address(this), _buyer, _assetId);

    // Notify ..
    emit OrderSuccessful(_orderId, _buyer, _price);
  }

  /**
   * Creates a new order
   *  nftAddress - Non fungible contract address
   *  assetId - ID of the published NFT
   *  priceInAnyOfTheFourCurrencies - price In Any Of The Four Currencies
   *  expiresAt - Expiration time for the order
   */
  function _createOrder(
    address _nftAddress,
    uint256 _assetId,
    uint256 _price,
    uint256 _minBidPrice
    // uint256 _expiresAt
  ) internal {
    // Check nft registry
    IERC721 nftRegistry = _requireERC721(_nftAddress);

    // Check order creator is the asset owner
    address assetOwner = nftRegistry.ownerOf(_assetId);
    //address _creator = nftRegistry.getCreator();
    //uint256 _royalty =nftRegistry.getRoyalty(_assetId);
    require(
      assetOwner == msg.sender,
      "Marketplace: Only the asset owner can create orders"
    );

    require(_price > 0, "Marketplace: Price should be bigger than 0");

    // require(
    //   _expiresAt > block.timestamp.add(1 minutes),
    //   "Marketplace: Publication should be more than 1 minute in the future"
    // );

    // get NFT asset from seller
    // nftRegistry.setApprovalForAll(address(this), true);
    // nftRegistry.approve(address(this), _assetId);

   nftRegistry.transferFrom(assetOwner, address(this), _assetId);

    // create the orderId
    bytes32 orderId =
      keccak256(
        abi.encodePacked(
          block.timestamp,
          assetOwner,
          _nftAddress,
          _assetId,
          _price
        )
      );

    // save order
    orderByAssetId[_nftAddress][_assetId] = Order({
      id: orderId,
      seller: assetOwner,
      nftAddress: _nftAddress,
      price: _price,
      minBidPrice: _minBidPrice
    //  creator: _creator,
    //  royalty: _royalty
    //   expiresAt: _expiresAt
    });

    emit OrderCreated(
      orderId,
      assetOwner,
      _nftAddress,
      _assetId,
      _price,
      _minBidPrice
    //   _expiresAt
    );
  }

  /**
   *  Creates a new bid on a existing order
   *  nftAddress - Non fungible contract address
   *  assetId - ID of the published NFT
   *  priceInAnyOfTheFourCurrencies - price In Any Of The Four Currencies
   *  expiresAt - expires time
   */
  function _createBid(
    address _nftAddress,
    uint256 _assetId
    //uint256 _price
    // uint256 _expiresAt
  ) internal{
    // Checks order validity
    Order memory order = _getValidOrder(_nftAddress, _assetId);

    // check on expire time
    // if (_expiresAt > order.expiresAt) {
    //   _expiresAt = order.expiresAt;
    // }

    // Check price if theres previous a bid
    Bid memory bid = bidByOrderId[_nftAddress][_assetId];

    // if theres no previous bid, just check price > minBidPrice
    if (bid.id != 0) {
    //   if (bid.expiresAt >= block.timestamp) {
        require(
          msg.value >= bid.price + order.minBidPrice,
          "Marketplace: bid price should be higher than last bid"
        );
    //   } else {
    //     require(_price > 0, "Marketplace: bid should be > 0");
    //   }

      _cancelBid(bid.id, _nftAddress, _assetId, payable(bid.bidder), bid.price);
    } else {
      require(
          msg.value > order.minBidPrice,
          "Marketplace: bid price should be higher than minimum bid price"
        );
    }


    userBiddingBalance[msg.sender] = userBiddingBalance[msg.sender] + msg.value;

    // Create bid
    bytes32 bidId =
      keccak256(
        abi.encodePacked(
          block.timestamp,
          msg.sender,
          order.id,
          msg.value
        //   _expiresAt
        )
      );

    // Save Bid for this order
    bidByOrderId[_nftAddress][_assetId] = Bid({
      id: bidId,
      bidder: msg.sender,
      price: msg.value
    //   expiresAt: _expiresAt
    });

    emit BidCreated(
      bidId,
      _nftAddress,
      _assetId,
      msg.sender, // bidder
      msg.value
    //   _expiresAt
    );
  }

  /**
   * Cancel an already published order
   *  can only be canceled by seller or the contract owner
   * orderId - Bid identifier
   * nftAddress - Address of the NFT registry
   * assetId - ID of the published NFT
   * seller - Address
   */
  function _cancelOrder(
    bytes32 _orderId,
    address _nftAddress,
    uint256 _assetId,
    address _seller
  ) internal {
    delete orderByAssetId[_nftAddress][_assetId];

    /// send asset back to seller
    IERC721(_nftAddress).transferFrom(address(this), _seller, _assetId);

    emit OrderCancelled(_orderId);
  }

  /**
   * Cancel bid from an already published order
   *  can only be canceled by seller or the contract owner
   * bidId - Bid identifier
   * nftAddress - registry address
   * assetId - ID of the published NFT
   * bidder - Address
   * escrowAmount - in acceptenToken currency
   */
  function _cancelBid(
    bytes32 _bidId,
    address _nftAddress,
    uint256 _assetId,
    address payable _bidder,
    uint256 _escrowAmount
  ) internal {
    delete bidByOrderId[_nftAddress][_assetId];

    _bidder.transfer(_escrowAmount);

    emit BidCancelled(_bidId);
  }

  function _requireERC721(address _nftAddress) public view returns (IERC721) {
    require(
      IERC721(_nftAddress).supportsInterface(_INTERFACE_ID_ERC721),
      "The NFT contract has an invalid ERC721 implementation"
    );
    return IERC721(_nftAddress);
  }

  
  // as a user: reclaim and withdraw BNB from this contract
  function userReclaim() public {
    address payable seller = payable(msg.sender);
    require(seller != address(0), "NFTMarketplace: invalid zero address.");

    uint256 balance = userBalances[seller];
    require(balance > 0, "NFTMarketplace: your balance is 0.");
    uint256 FeeAmount = userFeesBalances[seller];
    require(FeeAmount > 0, "NFTMarketplace: your address Fees is 0.");

    // send the BNB balance while deducting the FeeAmount 
    seller.transfer(balance - FeeAmount);

    // clear the user balance
    userBalances[seller] = 0;

    // clear the user FeeBalance
    userFeesBalances[seller] = 0;

    // move the Fees to the NFTMarketplace owner Balance
    NFTMarketplaceOwnerBalance[NFTMarketplaceOwner] = NFTMarketplaceOwnerBalance[NFTMarketplaceOwner] + FeeAmount;
    
    emit UserReclaim(seller);
  }

  // as an NFTMarketplaceOwner: reclaim and withdraw BNB Fees Collected from this contract
  function NftMarketPlaceOwnerReclaim() public onlyOwner {
    require(NFTMarketplaceOwner == msg.sender);

    address payable ContractOwner = payable(msg.sender);
    require(ContractOwner != address(0), "NFTMarketplace: invalid zezro address.");

    uint256 ownedFeeBalance = NFTMarketplaceOwnerBalance[NFTMarketplaceOwner];
    require(ownedFeeBalance > 0, "NFTMarketplace: your fee balance is 0.");

    // send the BNB balance while deducting the FeeAmount 
    ContractOwner.transfer(ownedFeeBalance);

    // clear the Contract owner balance balance
    NFTMarketplaceOwnerBalance[NFTMarketplaceOwner] = 0;
    
    emit NFTMarketPlaceOwnerReclaim(ContractOwner);
  }
}