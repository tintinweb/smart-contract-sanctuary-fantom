/**
 *
                        ..      s       .                                         s
  x8h.     x8.    x .d88"      :8      @88>                                      :8
:88888> .x8888x.   5888R      .88      %8P      ..    .     :                   .88
 `8888   `8888f    '888R     :888ooo    .     .888: x888  x888.        u       :888ooo      .u
  8888    8888'     888R   -*8888888  [email protected]  ~`8888~'888X`?888f`    us888u.  -*8888888   ud8888.
  8888    8888      888R     8888    ''888E`   X888  888X '888>  [email protected] "8888"   8888    :888'8888.
  8888    8888      888R     8888      888E    X888  888X '888>  9888  9888    8888    d888 '88%"
  8888    8888      888R     8888      888E    X888  888X '888>  9888  9888    8888    8888.+"
  8888    8888      888R    .8888Lu=   888E    X888  888X '888>  9888  9888   .8888Lu= 8888L
-n88888x>"88888x-  .888B .  ^%888*     888&   "*88%""*88" '888!` 9888  9888   ^%888*   '8888c. .+
  `%888"  4888!`   ^*888%     'Y"      R888"    `~    "    `"`   "888*""888"    'Y"     "88888%
    `"      ""       "%                 ""                        ^Y"   ^Y'               "YP'



    .....                                         s                                       .x+=:.
 .H8888888x.  '`+                                :8                                      z`    ^%
:888888888888x.  !                u.    u.      .88           u.      ..    .     :         .   <k
8~    `"*88888888"       u      [email protected] [email protected]   :888ooo  ...ue888b   .888: x888  x888.     [email protected]"
!      .  `f""""      us888u.  ^"8888""8888" -*8888888  888R Y888r ~`8888~'888X`?888f`  [email protected]^%8888"
 ~:...-` :8L <)88: [email protected] "8888"   8888  888R    8888     888R I888>   X888  888X '888>  x88:  `)8b.
    .   :888:>X88! 9888  9888    8888  888R    8888     888R I888>   X888  888X '888>  8888N=*8888
 :~"88x 48888X ^`  9888  9888    8888  888R    8888     888R I888>   X888  888X '888>   %8"    R88
<  :888k'88888X    9888  9888    8888  888R   .8888Lu= u8888cJ888    X888  888X '888>    @8Wou 9%
  d8888f '88888X   9888  9888   "*88*" 8888"  ^%888*    "*888*P"    "*88%""*88" '888!` .888888P`
 :8888!    ?8888>  "888*""888"    ""   'Y"      'Y"       'Y"         `~    "    `"`   `   ^"F
 X888!      8888~   ^Y"   ^Y'
 '888       X88f
  '%8:     .8*"
     ^----~"`
                    Base code was forked from BitDaemons (because i couldn't wrap my head around
                    using ERC2981 lol)

                    BitDaemons credit:

                    Written by MaxFlowO2, Senior Developer and Partner of G&M� Labs
                    Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
                    email: [email protected]

                    Thanks Max! <3
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }

    function percentageAmount(uint256 total_, uint8 percentage_)
        internal
        pure
        returns (uint256 percentAmount_)
    {
        return div(mul(total_, percentage_), 1000);
    }

    function substractPercentage(uint256 total_, uint8 percentageToSub_)
        internal
        pure
        returns (uint256 result_)
    {
        return sub(total_, div(mul(total_, percentageToSub_), 1000));
    }

    function percentageOfTotal(uint256 part_, uint256 total_)
        internal
        pure
        returns (uint256 percent_)
    {
        return div(mul(part_, 100), total_);
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    function quadraticPricing(uint256 payment_, uint256 multiplier_)
        internal
        pure
        returns (uint256)
    {
        return sqrrt(mul(multiplier_, payment_));
    }

    function bondingCurve(uint256 supply_, uint256 multiplier_)
        internal
        pure
        returns (uint256)
    {
        return mul(multiplier_, supply_);
    }
}


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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


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

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


interface IMAX721 is IERC165 {

  // ERC165 data
  // minterStatus() => 0x2ecd28ab
  // minterFees() => 0xd95ae162
  // minterMaximumCapacity() => 0x78c5939b
  // minterMaximumTeamMints() => 0x049157bb
  // minterTeamMintsRemaining() => 0x5c17e370
  // minterTeamMintsCount() => 0xe68b7961
  // totalSupply() => 0x18160ddd
  // IMAX721 => 0x29499a25

  // @notice will return current token count
  // totalSupply() => 0x18160ddd
  function totalSupply() external view returns (uint256);
}

abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

interface IERC2981 is IERC165 {
  // ERC165 bytes to add to interface array - set in parent contract
  // implementing this standard
  //
  // bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
  // bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
  // _registerInterface(_INTERFACE_ID_ERC2981);

  // @notice Called with the sale price to determine how much royalty
  //  is owed and to whom.
  // @param _tokenId - the NFT asset queried for royalty information
  // @param _salePrice - the sale price of the NFT asset specified by _tokenId
  // @return receiver - address of who should be sent the royalty payment
  // @return royaltyAmount - the royalty payment amount for _salePrice

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);

}


abstract contract ERC2981Collection is IERC2981 {

  // Bytes4 Code for EIP-2981
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  // Mappings _tokenID -> values
  address private recieverTemp;
  mapping(uint256 => address) receiverAddresses;
  mapping(uint256 => uint256) royaltyPercentage;

  // Set to be internal function _setReceiver
  function _setReceiver(uint256 _tokenId, address _address) internal {
    receiverAddresses[_tokenId] = _address;
  }

  // Set to be internal function _setRoyaltyPercentage
  function _setRoyaltyPercentage(uint256 _tokenId, uint256 _royaltyPercentage) internal {
    royaltyPercentage[_tokenId] = _royaltyPercentage;
  }

  // Override for royaltyInfo(uint256, uint256)
  // royaltyInfo(uint256,uint256) => 0x2a55205a
  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external view override(IERC2981) returns (
    address receiver,
    uint256 royaltyAmount
  ) {
    receiver = receiverAddresses[_tokenId];

    // This sets percentages by price * percentage / 100
    royaltyAmount = _salePrice * royaltyPercentage[_tokenId] / 100;
  }
}


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

interface IWrappedFantom {
  // deposit wraps received FTM tokens as wFTM in 1:1 ratio by minting
  // the received amount of FTMs in wFTM on the sender's address.
  function deposit() external payable returns (uint256);
}

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

interface IGenericRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IGenericRouter02 is IGenericRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface ISpiritV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;
}

interface IGenericV2Factory {
  function getPair(address token0, address token1) external returns (address);
}

interface IZap {
    function estimateZapInToken(address _from, address _to, address _router, uint _amt) external view returns (uint256, uint256);
    function swapToken(address _from, uint amount, address _to, address routerAddr, address _recipient) external;
    function swapToNative(address _from, uint amount, address routerAddr, address _recipient) external;
    function zapIn(address _to, address routerAddr, address _recipient) external payable;
    function zapInToken(address _from, uint amount, address _to, address routerAddr, address _recipient) external;
    function zapAcross(address _from, uint amount, address _toRouter, address _recipient) external;
    function zapOut(address _from, uint amount, address routerAddr, address _recipient) external;
    function zapOutToken(address _from, uint amount, address _to, address routerAddr, address _recipient) external;
}

contract UltimateFantoms is ERC721, ERC2981Collection, IMAX721, ERC165Storage, Ownable {
  using Counters for Counters.Counter;
  using Address for address;
  // using SafeMath for uint256;
  // we use solidity > 0.8.0, so safemath isnt good

  Counters.Counter private _tokenIdCounter;
  uint256 private mintSize = 3333;
  uint256 private teamMintSize;

  address private ZAPPER_ADDRESS = 0xF0ff07d19f310abab54724a8876Eee71E338c82F;
  IZap private ZAPPER = IZap(ZAPPER_ADDRESS);
  address private SPIRITLP = 0x200a8431906751bf1E8a42bbb60c35Bc6ba9aB89;

  IERC721Enumerable private constant FTMOPRs = IERC721Enumerable(0x6e85F63449F090856ca5850D19611c50488bd7fD);
  IERC721Enumerable private constant CYBERs = IERC721Enumerable(0xCB0fF14CAC96aDd86223C8C7E8A6129CD92919Ab);

  address private constant TREASURY = 0x3e522051A9B1958Aa1e828AC24Afba4a551DF37d;
  address private constant BURN = 0x000000000000000000000000000000000000dEaD;
  address private constant T = 0x20455079b7834CB1a405B622B7E4fB2EFCcaDBdA;
  address private constant xOPR = 0x9E7f8D1E52630d46e8749C8f81e91D4e934f3589;
  address private ROYALTIES;

  IWrappedFantom private constant wFTMc = IWrappedFantom(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
  IERC20 private constant wFTM = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);

  address private SPIRITSWAP_ROUTER = 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52;
  address private constant sPATH1 = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
  address private constant sPATH2 = 0x5Cc61A78F164885776AA610fb0FE1257df78E59B;

  address private PAINTSWAP_ROUTER = 0xfD000ddCEa75a2E23059881c3589F6425bFf1AbB;

  address private constant rPATH1 = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
  address private constant rPATH2 = 0x87d57F92852D7357Cf32Ac4F6952204f2B0c1A27;

  uint256 private _spiritAlloc = 0;
  uint256 private _brushAlloc = 0;
  uint256 private _oprAlloc = 0;
  uint256 private _xoprAlloc = 0;
  uint256 private _rndmAlloc = 0;
  uint256 private _tAlloc = 0;
  uint256 private _sendAlloc = 0;

  uint256 private _toEarn;
  uint256 private _earnTo;
  address private _sendTo;

  mapping(address => uint) rewards;

  string private base;

  event UpdatedBaseURI(string _old, string _new);
  event UpdatedMintFees(uint256 _old, uint256 _new);
  event UpdatedMintSize(uint256 _old, uint256 _new);
  event UpdatedMintStatus(bool _old, bool _new);
  event UpdatedRoyalties(uint256 newPercentage);
  event UpdatedTeamMintSize(uint256 _old, uint256 _new);
  event UpdatedRouter(address _oldRouter, address _newRouter);
  event UpdatedZapper(address _newLp, address _newZapper);

  // bytes4 constants for ERC165
  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
  bytes4 private constant _INTERFACE_ID_IERC2981 = 0x2a55205a;
  bytes4 private constant _INTERFACE_ID_ERC2981Collection = 0x6af56a00;
  bytes4 private constant _INTERFACE_ID_IMAX721 = 0x18160ddd;


  constructor() ERC721("The Ultimate Fantoms", "ULFTM") {
    // ERC165 Interfaces Supported
    _registerInterface(_INTERFACE_ID_ERC721);
    _registerInterface(_INTERFACE_ID_IERC2981);
    _registerInterface(_INTERFACE_ID_ERC2981Collection);
    _registerInterface(_INTERFACE_ID_IMAX721);
  }

  /**
   * Mint fee curve:
   * First 100 => 0.1 FTM each
   * Next 200 => 0.5 FTM each
   * Next 300 => 1 FTM each
   * Next 400 => 2 FTM each
   * Next 500 => 3 FTM each
   * Next 800 => 4 FTM each
   * Next 1000 => 5 FTM each
   * Next 33 => 6 FTM each
   *  === Total: 3333 ===
   *  = HandMade:  33?  =
   *  = Partner tokens? =
   *  - SPIRIT
   *  - RNDM (?)
   *  - BRUSH (?)
   *  - BOO (probably not)
   *  - OPR
   *  ===================
   *
   *  SPIRIT buys:           TOTAL: 10%
   *    ~ 5% to treasury
   *    ~ 5% to 0x000...000
   *  RNDM buys:             TOTAL: 5%
   *    ~ 2.5% to treasury
   *    ~ 2.5% to 0x000...000
   *  BRUSH buys:            TOTAL: 5%
   *    ~ 2.5% to treasury
   *    ~ 2.5% to 0x000...000
   *  BOO buys:              TOTAL: 5%
   *    ~ 2.5% to treasury
   *    ~ 2.5% to 0x000...000
   *  OPR buys:              TOTAL: 10%
   *    ~ 10% to LP
   *  DFY buys:              TOTAL: 5%
   *    ~ 2.5% to treasury
   *    ~ 2.5% to 0x000...000
   *  =====================  TOTAL: 40%
  **/

/***
  ** UTILS
  ***/

	function getPrice() public view returns(uint) {
	  if (_tokenIdCounter.current() <= 100) {
		    return 0.1 ether;
    } else if ((_tokenIdCounter.current() <= 300) && (_tokenIdCounter.current() >= 101)) {
		    return 0.2 ether;
	  } else if ((_tokenIdCounter.current() <= 600) && (_tokenIdCounter.current() >= 301)) {
		    return 1 ether;
	  } else if ((_tokenIdCounter.current() <= 1000) && (_tokenIdCounter.current() >= 601)) {
		    return 2 ether;
	  } else if ((_tokenIdCounter.current() <= 1500) && (_tokenIdCounter.current() >= 1001)) {
		    return 3 ether;
	  } else if ((_tokenIdCounter.current() <= 2300) && (_tokenIdCounter.current() >= 1501)) {
		    return 4 ether;
	  } else if ((_tokenIdCounter.current() <= 3300) && (_tokenIdCounter.current() >= 2301)) {
		    return 5 ether;
	  } else {
		    return 6 ether;
	  }
	}

  function setRoyaltyAddress(address _newAddress) external onlyOwner {
    require(_newAddress.isContract());
    ROYALTIES = _newAddress;
  }

  function updateSpiritRouter(address _newRouter) external onlyOwner {
    address _oldRouter = SPIRITSWAP_ROUTER;
    SPIRITSWAP_ROUTER = _newRouter;
    emit UpdatedRouter(_oldRouter, _newRouter);
  }

  function updateZapInfo(address newLp, address newZapper) external onlyOwner {
    SPIRITLP = newLp;
    ZAPPER_ADDRESS = newZapper;
    ZAPPER = IZap(newZapper);
    emit UpdatedZapper(newLp, newZapper);
  }

  function updatePaintRouter(address _newRouter) external onlyOwner {
    address _oldRouter = PAINTSWAP_ROUTER;
    PAINTSWAP_ROUTER = _newRouter;
    emit UpdatedRouter(_oldRouter, _newRouter);
  }

  function setRewards(address _receiver, uint256 _tokenId) private {
    _setReceiver(_tokenId, _receiver);
    _setRoyaltyPercentage(_tokenId, 5);
  }

  /*
    @dev Pseudo-randomness is fine in this situation because this will only be used in 2 cases:
    @dev  1) Token over ID 0 minted
    @dev  2) Token sold
    @dev
    @dev For #1, if a malicious actor were to trigger the randomness, they would pay more than they get in return.
    @dev so, they pay 0.1 to 6 FTM to mint, and they modify the randomness to land on their tokenId (which would require 2 very specific block.timestamp and block.difficulty levels)
    @dev so, they would get 20% of 0.1 to 6 FTM, not feasable
    @dev
    @dev For #2 the same principle applies, they would always pay more than they get back.
    @dev
    @dev unless its a validator, who can set the block.difficulty and block.timestamp. at which point we're are screwed :)
  */
  function random(uint256 seed) private view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, seed)));
  }

  function getRewards(address user) public view returns (uint) {
    return rewards[user];
  }

  function allowForPull(address creditee, uint amount) private {
    rewards[creditee] += amount;
  }

  function withdrawRewards() external {
    uint amount = rewards[msg.sender];
    uint256 balance = wFTM.balanceOf(address(this));

    require(amount != 0);
    require(balance >= amount);

    rewards[msg.sender] = 0;

    wFTM.transfer(msg.sender, amount);
  }



/***
 *    ????   ???? ??? ????   ??? ?????????
 *    ????? ????? ??? ?????  ??? ?????????
 *    ??????????? ??? ?????? ???   ???
 *    ??????????? ??? ??????????   ???
 *    ??? ??? ??? ??? ??? ??????   ???
 *    ???     ??? ??? ???  ?????   ???
 */

  function publicMint(uint256 amount) external payable {
    require(amount <= 10, "Max. of 10 Fantoms per mint.");
    require(msg.value == (getPrice() * amount), "Wrong amount of FTM");
    require(_tokenIdCounter.current() + amount < mintSize, "Can not mint that many");
    // Partner TOKENS
    _spiritAlloc = msg.value/10.00;       //        10%
    _brushAlloc = msg.value/10.00;        //        10%
    _rndmAlloc = (msg.value*15)/100.00;   //        15%
    // OPR & HOLD2EARN
    _oprAlloc = msg.value/5.00;           //        20%
    _xoprAlloc = msg.value/10.00;
    _sendAlloc = msg.value/5.00;          //        20%
    _tAlloc = msg.value/100.00;           //         1%
    // 70% should be used up             // Total: 76%
    wFTMc.deposit{value: _tAlloc}();
    wFTM.transfer(T, wFTM.balanceOf(address(this)));
    /* SPIRIT BUY AND BURN */
    address[] memory _spiritPath;
    _spiritPath = new address[](2);
    _spiritPath[0] = sPATH1;
    _spiritPath[1] = sPATH2;
    IGenericRouter02(SPIRITSWAP_ROUTER).swapExactETHForTokens{value: _spiritAlloc/2}(0, _spiritPath, TREASURY, block.timestamp);
    IGenericRouter02(SPIRITSWAP_ROUTER).swapExactETHForTokens{value: _spiritAlloc/2}(0, _spiritPath, BURN, block.timestamp);
    /* OPR LIQUIDITY ZAP: SPIRIT */
    ZAPPER.zapIn{value: _oprAlloc}(SPIRITLP,SPIRITSWAP_ROUTER,address(this));
    /* RNDM BUY AND BURN */
    address[] memory _rndmPath;
    _rndmPath = new address[](2);
    _rndmPath[0] = rPATH1;
    _rndmPath[1] = rPATH2;
    IGenericRouter02(PAINTSWAP_ROUTER).swapExactETHForTokens{value: _rndmAlloc/2}(0, _rndmPath, TREASURY, block.timestamp);
    IGenericRouter02(PAINTSWAP_ROUTER).swapExactETHForTokens{value: _rndmAlloc/2}(0, _rndmPath, BURN, block.timestamp);
    /* xOPR staking rewards */
    address[] memory _xoprPath;
    _xoprPath = new address[](2);
    _xoprPath[0] = rPATH1;
    _xoprPath[1] = 0x16dbD24713C1E6209142BCFEED8C170D83f84924;
    IGenericRouter02(SPIRITSWAP_ROUTER).swapExactETHForTokens{value: _xoprAlloc}(0, _xoprPath, address(this), block.timestamp);
    IERC20(0x16dbD24713C1E6209142BCFEED8C170D83f84924).transferFrom(address(this), xOPR, IERC20(0x16dbD24713C1E6209142BCFEED8C170D83f84924).balanceOf(address(this)));
    /* HOLD 2 EARN */
    uint256 random = random(_tokenIdCounter.current());
    _toEarn = random % 2; //random number between 0 to 2
    if (_toEarn == 0) {
      _earnTo = random % FTMOPRs.totalSupply();
      _sendTo = FTMOPRs.ownerOf(_earnTo);
      wFTMc.deposit{value: _sendAlloc}();
      wFTM.transfer(_sendTo, wFTM.balanceOf(address(this)));
    } else if (_toEarn == 1) {
      _earnTo = random % (_tokenIdCounter.current());
      _sendTo = ownerOf(_earnTo);
      wFTMc.deposit{value: _sendAlloc}();
      wFTM.transfer(_sendTo, wFTM.balanceOf(address(this)));
    } else {
      _earnTo = random % CYBERs.totalSupply();
      _sendTo = CYBERs.ownerOf(_earnTo);
      wFTMc.deposit{value: _sendAlloc}();
      wFTM.transfer(_sendTo, wFTM.balanceOf(address(this)));
    }
    // Send payment line
    for (uint i = 0; i < amount; i++) {
      _safeMint(msg.sender, _tokenIdCounter.current());
      setRewards(ROYALTIES, _tokenIdCounter.current());
      _tokenIdCounter.increment();
    }
  }

  function getBalance() external view returns (uint) {
    return address(this).balance;
  }

/***
 *     ???????  ???    ??? ????   ??? ???????????????
 *    ????????? ???    ??? ?????  ??? ????????????????
 *    ???   ??? ??? ?? ??? ?????? ??? ??????  ????????
 *    ???   ??? ?????????? ?????????? ??????  ????????
 *    ????????? ????????? ???? ????? ????????????  ???
 *     ???????  ???????? ???  ??? ?????????????  ???
 * This section will have all the internals set to onlyOwner
 */

  // @notice this will use internal functions to set EIP 2981
  // found in IERC2981.sol and used by ERC2981Collections.sol
  //function setRoyaltyInfo(address _reciever, uint256 _percentage) private {
  //  _setRoyalties(_royaltyAddress, _percentage);
  //  emit UpdatedRoyalties(_royaltyAddress, _percentage);
  //}

  // @notice will update _baseURI() by onlyOwner role
  function setBaseURI(string memory _base) external onlyOwner {
    string memory old = base;
    base = _base;
    emit UpdatedBaseURI(old, base);
  }

  // @notice will set mint size by onlyOwner role
  function setMintSize(uint256 _amount) external onlyOwner {
    uint256 old = mintSize;
    mintSize = _amount;
    emit UpdatedMintSize(old, mintSize);
  }

  // @notice function useful for accidental ETH transfers to contract (to user address)
  // wraps _user in payable to fix address -> address payable
  function sweepEthToAddress(address _user, uint256 _amount) external onlyOwner {
    (bool success, bytes memory data) = _user.call{ value: _amount }("");
  }

  ///
  /// Developer, these are the overrides
  ///

  // @notice solidity required override for _baseURI()
  function _baseURI() internal view override returns (string memory) {
    return base;
  }

  // @notice solidity required override for supportsInterface(bytes4)
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC165Storage, IERC165) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  // @notice will return current token count
  function totalSupply() external view override(IMAX721) returns (uint256) {
    return _tokenIdCounter.current();
  }
}

contract RoyaltySplitter is Ownable {

  event RecievedFTM(uint256 amount);

  IERC721Enumerable private constant FTMOPRs = IERC721Enumerable(0x6e85F63449F090856ca5850D19611c50488bd7fD);
  IERC721Enumerable private constant CYBERs = IERC721Enumerable(0xCB0fF14CAC96aDd86223C8C7E8A6129CD92919Ab);
  IERC721Enumerable private ICollection;
  IWrappedFantom private constant wFTMc = IWrappedFantom(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
  IERC20 private constant wFTM = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
  address private SPIRITSWAP_ROUTER = 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52;
  address private constant rPATH1 = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
  address private constant xOPR = 0x9E7f8D1E52630d46e8749C8f81e91D4e934f3589;

  event UpdatedRouter(address _oldRouter, address _newRouter);
  event UpdatedZapper(address _newLp, address _newZapper);

  address COLLECTION;
  uint256 private _toEarn;
  uint256 private _earnTo;
  address private _sendTo;

  mapping(address => uint) rewards;

  constructor(address _collection) {
    COLLECTION = _collection;
    ICollection = IERC721Enumerable(_collection);
  }

  function updateSpiritRouter(address _newRouter) external onlyOwner {
    address _oldRouter = SPIRITSWAP_ROUTER;
    SPIRITSWAP_ROUTER = _newRouter;
    emit UpdatedRouter(_oldRouter, _newRouter);
  }

  function getRewards(address user) public view returns (uint) {
    return rewards[user];
  }

  function allowForPull(address creditee, uint amount) private {
    rewards[creditee] += amount;
  }

  function withdrawRewards() public {
    uint amount = rewards[msg.sender];
    uint256 balance = wFTM.balanceOf(address(this));

    require(amount != 0);
    require(balance >= amount);

    rewards[msg.sender] = 0;

    wFTM.transfer(msg.sender, amount);
  }

  function random() private view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
  }

  receive() external payable {
    emit RecievedFTM(msg.value);
    uint256 _sendAlloc = msg.value/2.00;
    uint256 _xoprAlloc = msg.value/2.00;
    uint256 random = random();
    _toEarn = random % 2; //random number between 0 to 4
    if (_toEarn == 0) {
      _earnTo = random % FTMOPRs.totalSupply();
      _sendTo = FTMOPRs.ownerOf(_earnTo);
      wFTMc.deposit{value: _sendAlloc}();
      wFTM.transfer(_sendTo, wFTM.balanceOf(address(this)));
    } else if (_toEarn == 1) {
      _earnTo = random % ICollection.totalSupply();
      _sendTo = ICollection.ownerOf(_earnTo);
      wFTMc.deposit{value: _sendAlloc}();
      wFTM.transfer(_sendTo, wFTM.balanceOf(address(this)));
    } else {
      _earnTo = random % CYBERs.totalSupply();
      _sendTo = CYBERs.ownerOf(_earnTo);
      wFTMc.deposit{value: _sendAlloc}();
      wFTM.transfer(_sendTo, wFTM.balanceOf(address(this)));
    }
    /* xOPR staking rewards */
    address[] memory _xoprPath;
    _xoprPath = new address[](2);
    _xoprPath[0] = rPATH1;
    _xoprPath[1] = 0x16dbD24713C1E6209142BCFEED8C170D83f84924;
    IGenericRouter02(SPIRITSWAP_ROUTER).swapExactETHForTokens{value: _xoprAlloc}(0, _xoprPath, xOPR, block.timestamp);
  }

  fallback() external payable {
    emit RecievedFTM(msg.value);
    uint256 _sendAlloc = msg.value/2.00;
    uint256 _xoprAlloc = msg.value/2.00;
    uint256 random = random();
    _toEarn = random % 2; //random number between 0 to 4
    if (_toEarn == 0) {
      _earnTo = random % FTMOPRs.totalSupply();
      _sendTo = FTMOPRs.ownerOf(_earnTo);
      wFTMc.deposit{value: _sendAlloc}();
      wFTM.transfer(_sendTo, wFTM.balanceOf(address(this)));
    } else if (_toEarn == 1) {
      _earnTo = random % ICollection.totalSupply();
      _sendTo = ICollection.ownerOf(_earnTo);
      wFTMc.deposit{value: _sendAlloc}();
      wFTM.transfer(_sendTo, wFTM.balanceOf(address(this)));
    } else {
      _earnTo = random % CYBERs.totalSupply();
      _sendTo = CYBERs.ownerOf(_earnTo);
      wFTMc.deposit{value: _sendAlloc}();
      wFTM.transfer(_sendTo, wFTM.balanceOf(address(this)));
    }
    /* xOPR staking rewards */
    address[] memory _xoprPath;
    _xoprPath = new address[](2);
    _xoprPath[0] = rPATH1;
    _xoprPath[1] = 0x16dbD24713C1E6209142BCFEED8C170D83f84924;
    IGenericRouter02(SPIRITSWAP_ROUTER).swapExactETHForTokens{value: _xoprAlloc}(0, _xoprPath, xOPR, block.timestamp);
  }
}