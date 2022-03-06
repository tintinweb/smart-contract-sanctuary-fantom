/**
 *Submitted for verification at FtmScan.com on 2022-03-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC2981 is IERC165 {
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IUniswapV2Router {
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IERC1155 is IERC165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

   
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

  
    event URI(string value, uint256 indexed id);

    
    function balanceOf(address account, uint256 id) external view returns (uint256);

   
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

  
    function setApprovalForAll(address operator, bool approved) external;

    
    function isApprovedForAll(address account, address operator) external view returns (bool);

   
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

  
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}


interface IERC721 is IERC165 {
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

   
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

   
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  
    function balanceOf(address owner) external view returns (uint256 balance);

  
    function ownerOf(uint256 tokenId) external view returns (address owner);

  
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

   
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

   
    function setApprovalForAll(address operator, bool _approved) external;

    
    function isApprovedForAll(address owner, address operator) external view returns (bool);

   
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract ReentrancyGuard {
    
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

  
        _status = _NOT_ENTERED;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
        _transferOwnership(_msgSender());
    }

   
    function owner() public view virtual returns (address) {
        return _owner;
    }

  
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

   
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
}

abstract contract ERC165 is IERC165 {
  
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / 1000;

        return (royalty.receiver, royaltyAmount);
    }

    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }
   
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= 1000, "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
   
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

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

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
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

library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library EnumerableSet {

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

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

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                set._values[toDeleteIndex] = lastvalue;
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }


    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}


library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {

        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract OperaHouseMarketplace is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;
    address adminAddress;
    address WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    bool marketplaceStatus;
    address public swapRouter = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
    EnumerableSet.AddressSet tokenWhiteList;

    uint256 listingFee = 0 ether; // minimum price, change for what you want
    uint256 _serviceFee = 0;  // 0 % with 1000 factor

    struct CollectionRoyalty {
        address recipient;
        uint256 feeFraction;
        address setBy;
    }

    // Who can set: ERC721 owner and admin
    event SetRoyalty(
        address indexed collectionAddress,
        address indexed recipient,
        uint256 feeFraction
    );

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint256 public defaultRoyaltyFraction = 0; // By the factor of 1000, 2%
    uint256 public royaltyUpperLimit = 100; // By the factor of 1000, 10%

    mapping(address => CollectionRoyalty) private _collectionRoyalty;

    struct Bid {
        uint256 tokenId;
        uint256 amount;
        uint256 price;
        address bidder;
        uint256 expireTimestamp;
    }

    struct TokenBids {
        EnumerableSet.AddressSet bidders;
        mapping(address => Bid) bids;
    }

    struct ListItem {
        uint8 contractType;
        uint256 tokenId;
        uint256 amount;
        uint256 price;
        address seller;
        address paymentToken;
        bool listType;
        uint256 expireTimestamp;
        uint256 time;
    }

    struct ListItemInput {
        address nftContract;
        uint8 contractType;
        uint256 tokenId;
        uint256 amount;
        uint256 price;
        address paymentToken;
        bool listType;
        uint256 expireTimestamp;
    }

    struct DelistItemInput {
        address nftContract;
        uint256 tokenId;
        uint256 amount;
    }

    struct TransferItem {
        address nftContract;
        uint8 contractType;
        uint256 tokenId;
        uint256 amount;
        address toAccount;
    }

    struct CollectionMarket {
      EnumerableSet.UintSet tokenIdsListing;
      mapping(uint256 => ListItem) listings;
      EnumerableSet.UintSet tokenIdsWithBid;
      mapping(uint256 => TokenBids) bids;
    }

    mapping(address => CollectionMarket) private _marketplaceSales;

    // declare a event for when a item is created on marketplace
    event TokenListed(
        address indexed nftContract,
        uint256 indexed tokenId,
        uint8 indexed contractType,
        uint256 amount,
        uint256 price,
        address seller,
        address paymentToken,
        bool listType,
        uint256 expireTimestamp,
        uint256 time
    );
    event ListItemUpdated(
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 price,
        address seller,
        address paymentToken,
        bool listType,
        uint256 expireTimestamp,
        uint256 time
    );
    event TokenDelisted(
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 amount
    );
    event TokenBidEntered(
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 price,
        address bidder,
        uint256 expireTimestamp
    );
    event TokenBidWithdrawn(
        address indexed erc721Address,
        uint256 indexed tokenId,
        address bidder
    );
    event TokenBought(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 amount,
        uint256 price,
        address seller,
        address paymentToken,
        bool listType,
        uint256 expireTimestamp,
        uint256 time,
        uint256 serviceFee,
        uint256 royaltyFee
    );
    event TokenBidAccepted(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 amount,
        uint256 price,
        address bidder,
        address paymentToken,
        bool listType,
        uint256 expireTimestamp,
        uint256 time,
        uint256 serviceFee,
        uint256 royaltyFee
    );

    constructor() {
        adminAddress = 0xCc3C8FD424737100557C132e10080226852e40eB;
        marketplaceStatus = true;
        tokenWhiteList.add(address(0));
        tokenWhiteList.add(WFTM);
    }

    modifier onlyMarketplaceOpen() {
        require(marketplaceStatus, "Listing and bid are not enabled");
        _;
    }

    function _isTokenApproved(address nftContract, uint256 tokenId)
        private
        view
        returns (bool)
    {
        IERC721 _erc721 = IERC721(nftContract);
        try _erc721.getApproved(tokenId) returns (address tokenOperator) {
            return tokenOperator == address(this);
        } catch {
            return false;
        }
    }

    function _isAllTokenApproved(address nftContract, address owner)
        private
        view
        returns (bool)
    {
        IERC721 _erc721 = IERC721(nftContract);
        return _erc721.isApprovedForAll(owner, address(this));
    }

    function _isAllTokenApprovedERC1155(address nftContract, address owner)
        private
        view
        returns (bool)
    {
        IERC1155 _erc1155 = IERC1155(nftContract);
        return _erc1155.isApprovedForAll(owner, address(this));
    }

    function _isTokenOwner(
        address nftContract,
        uint256 tokenId,
        address account
    ) private view returns (bool) {
        IERC721 _erc721 = IERC721(nftContract);
        try _erc721.ownerOf(tokenId) returns (address tokenOwner) {
            return tokenOwner == account;
        } catch {
            return false;
        }
    }

    function _isTokenOwnerERC1155(
        address nftContract,
        uint256 tokenId,
        uint256 amount,
        address account
    ) private view returns (bool) {
        IERC1155 _erc1155 = IERC1155(nftContract);
        try _erc1155.balanceOf(account, tokenId) returns (uint256 ownedBalance) {
            return ownedBalance >= amount;
        } catch {
            return false;
        }
    }

    function _isListItemValid(address nftContract, ListItem memory listItem)
        private
        view
        returns (bool isValid)
    {
        if (
            listItem.contractType == 1 &&
            listItem.amount == 1 &&
            _isTokenOwner(nftContract, listItem.tokenId, listItem.seller) &&
            (_isTokenApproved(nftContract, listItem.tokenId) ||
                _isAllTokenApproved(nftContract, listItem.seller)) &&
            listItem.price > 0 &&
            listItem.expireTimestamp > block.timestamp
        ) {
            isValid = true;
        }
    }

    function _isListItemValidERC1155(address nftContract, ListItem memory listItem)
        private
        view
        returns (bool isValid)
    {
        if (
            listItem.contractType == 2 &&
            listItem.amount >= 1 &&
            _isTokenOwnerERC1155(nftContract, listItem.tokenId, listItem.amount, listItem.seller) &&
            (_isAllTokenApprovedERC1155(nftContract, listItem.seller)) &&
            listItem.price > 0 &&
            listItem.expireTimestamp > block.timestamp
        ) {
            isValid = true;
        }
    }

    function _isBidValid(address nftContract, Bid memory bid)
        private
        view
        returns (bool isValid)
    {
        if (
            !_isTokenOwner(nftContract, bid.tokenId, bid.bidder) &&
            bid.amount == 1 &&
            bid.price > 0 &&
            bid.expireTimestamp > block.timestamp
        ) {
            isValid = true;
        }
    }

    function _isBidValidERC1155(Bid memory bid)
        private
        view
        returns (bool isValid)
    {
        if (
            bid.price > 0 &&
            bid.amount > 0 &&
            bid.expireTimestamp > block.timestamp
        ) {
            isValid = true;
        }
    }

    // returns the listing price of the contract
    function getListingPrice() public view returns (uint256) {
        return listingFee;
    }

    function setListingPrice(uint256 price) external onlyOwner {
        require(
            price <= 2 ether,
            "Attempt to set percentage higher than 2 FTM"
        );
        listingFee = price;
    }

    function getServiceFee() public view returns (uint256) {
        return _serviceFee;
    }

    function setServiceFee(uint256 fee) external onlyOwner nonReentrant {
        require(
            fee <= 100,
            "Attempt to set percentage higher than 10 %"
        );
        _serviceFee = fee;
    }

    function changeMarketplaceStatus (bool status) external onlyOwner nonReentrant {
        require(status != marketplaceStatus, "Already set.");
        marketplaceStatus = status;
    }

    function addPaymentToken(address paymentToken) external onlyOwner {
        require(!tokenWhiteList.contains(paymentToken), "Already added");
        tokenWhiteList.add(paymentToken);
    }

    function removePaymentToken(address paymentToken) external onlyOwner {
        require(tokenWhiteList.contains(paymentToken), "Not added");
        tokenWhiteList.remove(paymentToken);
    }

    function paymentTokens() external view returns(address[] memory) {
        return tokenWhiteList.values();
    }

    function _delistToken(address nftContract, uint256 tokenId, uint256 amount) private {
        if (_marketplaceSales[nftContract].tokenIdsListing.contains(tokenId)) {
            if (_marketplaceSales[nftContract].listings[tokenId].amount > amount) {
                _marketplaceSales[nftContract].listings[tokenId].amount -= amount;
            } else {
                delete _marketplaceSales[nftContract].listings[tokenId];
                _marketplaceSales[nftContract].tokenIdsListing.remove(tokenId);
                if (_marketplaceSales[nftContract].tokenIdsWithBid.contains(tokenId)) {
                    delete _marketplaceSales[nftContract].bids[tokenId];
                    _marketplaceSales[nftContract].tokenIdsWithBid.remove(tokenId);
                }
            }
        }
    }

    function _removeBidOfBidder(
        address nftContract,
        uint256 tokenId,
        address bidder
    ) private {
        if (
            _marketplaceSales[nftContract].bids[tokenId].bidders.contains(bidder)
        ) {
            // Step 1: delete the bid and the address
            delete _marketplaceSales[nftContract].bids[tokenId].bids[bidder];
            _marketplaceSales[nftContract].bids[tokenId].bidders.remove(bidder);

            // Step 2: if no bid left
            if (
                _marketplaceSales[nftContract].bids[tokenId].bidders.length() == 0
            ) {
                delete _marketplaceSales[nftContract].bids[tokenId];
                _marketplaceSales[nftContract].tokenIdsWithBid.remove(tokenId);
            }
        }
    }

    function withdrawBidForToken(address nftContract, uint256 tokenId)
        external
    {
        Bid memory bid = _marketplaceSales[nftContract].bids[tokenId].bids[
            msg.sender
        ];
        require(
            bid.bidder == msg.sender,
            "This address doesn't have bid on this token"
        );

        emit TokenBidWithdrawn(nftContract, tokenId, msg.sender);
        _removeBidOfBidder(nftContract, tokenId, msg.sender);
    }

    function _listTokenERC1155(
        address nftContract,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        address paymentToken,
        bool listType,
        uint256 expireTimestamp
    ) internal {
        require(price > 0, "Price must be at least 1 wei");

        require(!_marketplaceSales[nftContract].tokenIdsListing.contains(tokenId), "Already listed");

        require(tokenWhiteList.contains(paymentToken), "Payment token is not allowed");

        ListItem memory listItem = ListItem(
            2,
            tokenId,
            amount,
            price,
            msg.sender,
            paymentToken,
            listType,
            expireTimestamp,
            block.timestamp
        );

        require(
            _isListItemValidERC1155(nftContract, listItem),
            "Listing is not valid"
        );
        
        _marketplaceSales[nftContract].listings[tokenId] = listItem;
        _marketplaceSales[nftContract].tokenIdsListing.add(tokenId);

        if (listingFee > 0) {
            IERC20(paymentToken).transferFrom(msg.sender, adminAddress, listingFee);
        }
        emit TokenListed(
            nftContract,
            tokenId,
            2,
            amount,
            price,
            listItem.seller,
            listItem.paymentToken,
            listItem.listType,
            listItem.expireTimestamp,
            listItem.time
        );
    }

    // places an item for sale on the marketplace
    function listTokenERC1155(
        address nftContract,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        address paymentToken,
        bool listType,
        uint256 expireTimestamp
    ) public payable onlyMarketplaceOpen {
        _listTokenERC1155(nftContract, tokenId, amount, price, paymentToken, listType, expireTimestamp);
    }

    function _listToken(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        address paymentToken,
        bool listType,
        uint256 expireTimestamp
    ) internal {
        require(price > 0, "Price must be at least 1 wei");

        require(!_marketplaceSales[nftContract].tokenIdsListing.contains(tokenId), "Already listed");

        require(tokenWhiteList.contains(paymentToken), "Payment token is not allowed");

        ListItem memory listItem = ListItem(
            1,
            tokenId,
            1,
            price,
            msg.sender,
            paymentToken,
            listType,
            expireTimestamp,
            block.timestamp
        );
        require(
            _isListItemValid(nftContract, listItem),
            "Listing is not valid"
        );

        _marketplaceSales[nftContract].listings[listItem.tokenId] = listItem;
        _marketplaceSales[nftContract].tokenIdsListing.add(listItem.tokenId);

        if (listingFee > 0) {
            payable(adminAddress).transfer(listingFee);
        }
        if (msg.value > listingFee) {
            payable(msg.sender).transfer(msg.value - listingFee);
        }
        emit TokenListed(
            nftContract,
            tokenId,
            1,
            listItem.amount,
            listItem.price,
            listItem.seller,
            listItem.paymentToken,
            listItem.listType,
            listItem.expireTimestamp,
            listItem.time
        );
    }

    function listToken(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        address paymentToken,
        bool listType,
        uint256 expireTimestamp
    ) public payable onlyMarketplaceOpen {
        _listToken(nftContract, tokenId, price, paymentToken, listType, expireTimestamp);
    }

    function updateListedToken(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 amount,
        address paymentToken,
        bool listType,
        uint256 expireTimestamp
    ) public onlyMarketplaceOpen {
        require(price > 0, "Price must be at least 1 wei");

        require(_marketplaceSales[nftContract].tokenIdsListing.contains(tokenId), "Not listed");

        ListItem storage listItem = _marketplaceSales[nftContract].listings[tokenId];

        require(msg.sender == listItem.seller, "Not owner");
        
        listItem.tokenId = tokenId;
        listItem.amount = amount;
        listItem.price = price;
        listItem.listType = listType;
        listItem.paymentToken = paymentToken;
        listItem.expireTimestamp = expireTimestamp;
        listItem.time = block.timestamp;

        if (listItem.contractType == 1) {
            require(
                _isListItemValid(nftContract, listItem),
                "Listing is not valid"
            );
        } else if (listItem.contractType == 2) {
            require(
                _isListItemValidERC1155(nftContract, listItem),
                "Listing is not valid"
            );
        } else {
            revert("Wrong list item");
        }
        emit ListItemUpdated(
            nftContract,
            tokenId,
            amount,
            price,
            msg.sender,
            paymentToken,
            listType,
            expireTimestamp,
            block.timestamp
        );
    }

    function bulkListToken(
        ListItemInput[] memory listItems
    ) external payable onlyMarketplaceOpen {
        for (uint256 i = 0; i < listItems.length; i ++) {
            if (listItems[i].contractType == 1) {
                _listToken(listItems[i].nftContract, listItems[i].tokenId, listItems[i].price, listItems[i].paymentToken, listItems[i].listType, listItems[i].expireTimestamp);
            } else if (listItems[i].contractType == 2) {
                listTokenERC1155(listItems[i].nftContract, listItems[i].tokenId, listItems[i].amount, listItems[i].price, listItems[i].paymentToken, listItems[i].listType, listItems[i].expireTimestamp);
            } else {
                revert("Unsupported contract type");
            }
        }
    }

    function delistToken(address nftContract, uint256 tokenId, uint256 amount)
        external
    {
        require(
            _marketplaceSales[nftContract].listings[tokenId].seller == msg.sender ||
            msg.sender == owner(),
            "Only token seller can delist token"
        );

        emit TokenDelisted(
            nftContract,
            tokenId,
            amount
        );

        _delistToken(nftContract, tokenId, amount);
    }

    function bulkDelistToken(DelistItemInput[] memory items) external onlyOwner {
        for (uint256 index = 0; index < items.length; index ++ ) {
            emit TokenDelisted(
                items[index].nftContract,
                items[index].tokenId,
                items[index].amount
            );
            _delistToken(items[index].nftContract, items[index].tokenId, items[index].amount);
        }
    }

    function _beforeBuyToken(
        address nftContract,
        uint256 tokenId,
        ListItem memory listItem
    )
        private
        view
        returns (uint256 totalPrice, uint256 royaltyPrice, address recipient, uint256 serviceFee) 
    {
        if (listItem.contractType == 1) {
            require(
                _isListItemValid(nftContract, listItem),
                "Not for sale"
            );
        } else if (listItem.contractType == 2) {
            require(
                _isListItemValidERC1155(nftContract, listItem),
                "Not for sale"
            );
        } else {
            revert("contract type error");
        }

        totalPrice = listItem.price.mul(listItem.amount);
        serviceFee = totalPrice.mul(_serviceFee).div(1000);
        if (checkRoyalties(nftContract)) {
            (recipient, royaltyPrice) = royaltyFromERC2981(nftContract, tokenId, totalPrice);
        } else {
            CollectionRoyalty memory collectionRoyalty = royalty(nftContract);
            recipient = collectionRoyalty.recipient;
            if (recipient != address(0)) royaltyPrice = collectionRoyalty.feeFraction.mul(totalPrice).div(1000);
        }
    }

    function _swapTokens(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut) private returns (uint256) {
        address[] memory path;
        if (tokenIn == WFTM || tokenOut == WFTM) {
            path = new address[](2);
            path[0] = tokenIn;
            path[1] = tokenOut;
        } else {
            path = new address[](3);
            path[0] = tokenIn;
            path[1] = WFTM;
            path[2] = tokenOut;
            
        }
        IERC20(tokenIn).safeApprove(swapRouter, amountIn);

        uint[] memory amounts = IUniswapV2Router(swapRouter).swapTokensForExactTokens(
            amountOut,
            amountIn,
            path,
            address(this),
            block.timestamp
        );
        if (amountIn > amounts[0]) return amountIn - amounts[0];
        else return 0;
    }

    function buyTokenWithETH(
        address nftContract,
        uint256 tokenId,
        uint256 amount
    ) external payable onlyMarketplaceOpen {

        ListItem memory listItem = _marketplaceSales[nftContract].listings[tokenId];
        if (listItem.contractType == 1) {
            require(
                !_isTokenOwner(nftContract, tokenId, msg.sender),
                "Token owner can't buy their own token"
            );
        } else if (listItem.contractType == 2) {
            require(
                !_isTokenOwnerERC1155(nftContract, tokenId, amount, msg.sender),
                "Token owner can't buy their own token"
            );
        } else {
            revert("contract type error");
        }
        require(listItem.listType == true, "It is on auction");

        (uint256 totalPrice, uint256 royaltyPrice, address recipient, uint256 serviceFee) = _beforeBuyToken(nftContract, tokenId, listItem);

        require(
            msg.value >= listItem.price,
            "The value send is below sale price"
        );

        // can buy with only FTM
        require(listItem.paymentToken == address(0), "Unable to use token for it");

        // send fees and make payment for seller
        if (royaltyPrice > 0) Address.sendValue(payable(recipient), royaltyPrice);
        Address.sendValue(payable(adminAddress), serviceFee);
        Address.sendValue(payable(listItem.seller), totalPrice - royaltyPrice - serviceFee);

        // refund
        uint256 remainedAmount = msg.value.sub(totalPrice);
        Address.sendValue(payable(msg.sender), remainedAmount);

        // send nft to buyer
        if (listItem.contractType == 1) {
            IERC721(nftContract).safeTransferFrom(listItem.seller, msg.sender, tokenId);
        } else if (listItem.contractType == 2) {
            IERC1155(nftContract).safeTransferFrom(listItem.seller, msg.sender, tokenId, amount, "");
        }

        // emit event

        emit TokenBought(
            nftContract,
            tokenId,
            msg.sender,
            amount,
            listItem.price,
            listItem.seller,
            listItem.paymentToken,
            listItem.listType,
            listItem.expireTimestamp,
            listItem.time,
            serviceFee,
            royaltyPrice
        );

        // delist nft from contract
        _delistToken(nftContract, tokenId, amount);
    }

    function buyTokenWithTokens(
        address nftContract,
        uint256 tokenId,
        uint256 amount,
        address paymentToken,
        uint256 tokenAmount
    ) external onlyMarketplaceOpen {

        ListItem memory listItem = _marketplaceSales[nftContract].listings[tokenId];

        if (listItem.contractType == 1) {
            require(
                !_isTokenOwner(nftContract, tokenId, msg.sender),
                "Token owner can't buy their own token"
            );
        } else if (listItem.contractType == 2) {
            require(
                !_isTokenOwnerERC1155(nftContract, tokenId, amount, msg.sender),
                "Token owner can't buy their own token"
            );
        } else {
            revert("contract type error");
        }

        require(listItem.listType == true, "It is on auction");

        (uint256 totalPrice, uint256 royaltyPrice, address recipient, uint256 serviceFee) = _beforeBuyToken(nftContract, tokenId, listItem);
        address targetPaymentToken = listItem.paymentToken == address(0) ? WFTM : listItem.paymentToken;

        if (targetPaymentToken != paymentToken) { // need to swap
            IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), tokenAmount);
            uint256 remainedAmount = _swapTokens(paymentToken, targetPaymentToken, tokenAmount, totalPrice);

            if (remainedAmount > 0) IERC20(paymentToken).safeTransfer(msg.sender, remainedAmount);

            if (royaltyPrice > 0) IERC20(targetPaymentToken).safeTransfer(recipient, royaltyPrice);
            IERC20(targetPaymentToken).safeTransfer(adminAddress, serviceFee);
            IERC20(targetPaymentToken).safeTransfer(listItem.seller, totalPrice - serviceFee - royaltyPrice);
        } else { // no need to swap
            if (royaltyPrice > 0) IERC20(targetPaymentToken).safeTransferFrom(msg.sender, recipient, royaltyPrice);
            IERC20(targetPaymentToken).safeTransferFrom(msg.sender, adminAddress, serviceFee);
            IERC20(targetPaymentToken).safeTransferFrom(msg.sender, listItem.seller, totalPrice - serviceFee - royaltyPrice);
        }

        // send nft to buyer
        if (listItem.contractType == 1) {
            IERC721(nftContract).safeTransferFrom(listItem.seller, msg.sender, tokenId);
        } else if (listItem.contractType == 2) {
            IERC1155(nftContract).safeTransferFrom(listItem.seller, msg.sender, tokenId, amount, "");
        }

        emit TokenBought(
            nftContract,
            tokenId,
            msg.sender,
            amount,
            listItem.price,
            listItem.seller,
            listItem.paymentToken,
            listItem.listType,
            listItem.expireTimestamp,
            listItem.time,
            serviceFee,
            royaltyPrice
        );

        _delistToken(nftContract, tokenId, amount);
    }

    function enterBid(
        address nftContract,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        uint256 expireTimestamp
    )
        public onlyMarketplaceOpen
    {
        Bid memory bid = Bid(tokenId, amount, price, msg.sender, expireTimestamp);

        require(_marketplaceSales[nftContract].tokenIdsListing.contains(tokenId), "Not for bid");

        ListItem memory listItem = _marketplaceSales[nftContract].listings[tokenId];
        
        if ((listItem.contractType == 1 && !_isBidValid(nftContract, bid)) || (listItem.contractType == 2 && !_isBidValidERC1155(bid))) {
            revert("Bid is not valid");
        }
        require(listItem.listType == false, "It is not on auction");

        address paymentToken = listItem.paymentToken == address(0) ? WFTM : listItem.paymentToken;
        
        require((IERC20(paymentToken).balanceOf(msg.sender) >= price &&
            IERC20(paymentToken).allowance(msg.sender, address(this)) >= price),
            "Insurance money or not approved"
        );

        _marketplaceSales[nftContract].tokenIdsWithBid.add(tokenId);
        _marketplaceSales[nftContract].bids[tokenId].bidders.add(msg.sender);
        _marketplaceSales[nftContract].bids[tokenId].bids[msg.sender] = bid;

        emit TokenBidEntered(
            nftContract,
            tokenId,
            amount,
            price,
            msg.sender,
            expireTimestamp
        );

    }

    function acceptBid(
        address nftContract,
        uint8 contractType,
        uint256 tokenId,
        uint256 amount,
        address payable bidder,
        uint256 price
    ) external {
        if (contractType == 1) {
            require(
                _isTokenOwner(nftContract, tokenId, msg.sender),
                "Only token owner can accept bid of token"
            );
            require(
                _isTokenApproved(nftContract, tokenId) ||
                    _isAllTokenApproved(nftContract, msg.sender),
                "The token is not approved to transfer by the contract"
            );
        } else if (contractType == 2) {
            require(
                _isTokenOwnerERC1155(nftContract, tokenId, amount, msg.sender),
                "Only token owner can accept bid of token"
            );
            require(
                _isAllTokenApprovedERC1155(nftContract, msg.sender),
                "The token is not approved to transfer by the contract"
            );
        }

        Bid memory bid = _marketplaceSales[nftContract].bids[tokenId].bids[
            bidder
        ];
        ListItem memory listItem = _marketplaceSales[nftContract].listings[tokenId];
        require(_isBidValid(nftContract, bid), "Not valid bidder");
        require(
            bid.tokenId == tokenId &&
                bid.amount == amount &&
                bid.price == price &&
                bid.bidder == bidder,
            "This nft doesn't have a matching bid"
        );
        require(
            listItem.tokenId == tokenId &&
                listItem.amount >= amount,
            "Don't match with listing"
        );

        require(listItem.listType == false, "It is on sale");

        (uint256 totalPrice, uint256 royaltyPrice, address recipient, uint256 serviceFee) = _beforeBuyToken(nftContract, tokenId, listItem);

        address paymentToken = listItem.paymentToken;
        if (paymentToken == address(0)) {
            paymentToken = WFTM;
        }

        require(IERC20(paymentToken).allowance(bidder, address(this)) >= bid.price &&
            IERC20(paymentToken).balanceOf(bidder) >= bid.price,
            "Bidder's money is not enough"
        );

        if (royaltyPrice > 0) {
            IERC20(paymentToken).safeTransferFrom({
                from: bidder,
                to: recipient,
                value: royaltyPrice
            });
        }
        if (serviceFee > 0) {
            IERC20(paymentToken).safeTransferFrom({
                from: bidder,
                to: adminAddress,
                value: serviceFee
            });
        }
        IERC20(paymentToken).safeTransferFrom({
            from: bidder,
            to: msg.sender,
            value: totalPrice.sub(serviceFee).sub(royaltyPrice)
        });

        if (listItem.contractType == 1) {
            IERC721(nftContract).safeTransferFrom(listItem.seller, bidder, tokenId);
        } else if (listItem.contractType == 2) {
            IERC1155(nftContract).safeTransferFrom(listItem.seller, bidder, tokenId, amount, "");
        }

        emit TokenBidAccepted(
            nftContract,
            tokenId,
            msg.sender,
            amount,
            price,
            bidder,
            listItem.paymentToken,
            listItem.listType,
            listItem.expireTimestamp,
            listItem.time,
            serviceFee,
            royaltyPrice
        );
        _delistToken(nftContract, tokenId, amount);
    }

    function bulkTransfer(TransferItem[] memory items)
        external
    {
        for (uint256 i = 0; i < items.length; i ++) {
            TransferItem memory item = items[i];
            if (item.contractType == 1) {
                IERC721(item.nftContract).safeTransferFrom(msg.sender, item.toAccount, item.tokenId);
            } else {
                IERC1155(item.nftContract).safeTransferFrom(msg.sender, item.toAccount, item.tokenId, item.amount, "");
            }
        }
    }

    function getTokenListing(address nftContract, uint256 tokenId)
        public
        view
        returns (ListItem memory validListing)
    {
        ListItem memory listing = _marketplaceSales[nftContract].listings[tokenId];
        if ((listing.contractType == 1 && _isListItemValid(nftContract, listing)) || (listing.contractType == 2 && _isListItemValidERC1155(nftContract, listing))) {
            validListing = listing;
        }
    }

    function numOfTokenListings(address nftContract)
        public
        view
        returns (uint256)
    {
        return _marketplaceSales[nftContract].tokenIdsListing.length();
    }

    function getTokenListings(
        address nftContract,
        uint256 from,
        uint256 size
    ) external view returns (ListItem[] memory listings) {
        uint256 listingsCount = numOfTokenListings(nftContract);

        if (from < listingsCount && size > 0) {
            uint256 querySize = size;
            if ((from + size) > listingsCount) {
                querySize = listingsCount - from;
            }
            listings = new ListItem[](querySize);
            for (uint256 i = 0; i < querySize; i++) {
                uint256 tokenId = _marketplaceSales[nftContract]
                    .tokenIdsListing
                    .at(i + from);
                ListItem memory listing = _marketplaceSales[nftContract].listings[
                    tokenId
                ];
                if ((listing.contractType == 1 && _isListItemValid(nftContract, listing)) || (listing.contractType == 2 && _isListItemValidERC1155(nftContract, listing))) {
                    listings[i] = listing;
                }
            }
        }
    }

    function getBidderTokenBid(
        address nftContract,
        uint256 tokenId,
        address bidder
    ) public view returns (Bid memory validBid) {
        ListItem memory listItem = _marketplaceSales[nftContract].listings[tokenId];
        Bid memory bid = _marketplaceSales[nftContract].bids[tokenId].bids[
            bidder
        ];
        if ((listItem.contractType == 1 && _isBidValid(nftContract, bid)) || (listItem.contractType == 2 && _isBidValidERC1155(bid))) {
            validBid = bid;
        }
    }

    function getTokenBids(address nftContract, uint256 tokenId)
        external
        view
        returns (Bid[] memory bids)
    {
        ListItem memory listItem = _marketplaceSales[nftContract].listings[tokenId];

        uint256 bidderCount = _marketplaceSales[nftContract]
            .bids[tokenId]
            .bidders
            .length();

        bids = new Bid[](bidderCount);
        for (uint256 i; i < bidderCount; i++) {
            address bidder = _marketplaceSales[nftContract]
                .bids[tokenId]
                .bidders
                .at(i);
            Bid memory bid = _marketplaceSales[nftContract].bids[tokenId].bids[
                bidder
            ];
            if ((listItem.contractType == 1 && _isBidValid(nftContract, bid)) || (listItem.contractType == 2 && _isBidValidERC1155(bid))) {
                bids[i] = bid;
            }
        }
    }

    function getTokenHighestBid(address nftContract, uint256 tokenId)
        public
        view
        returns (Bid memory highestBid)
    {
        ListItem memory listItem = _marketplaceSales[nftContract].listings[tokenId];
        highestBid = Bid(tokenId, 1, 0, address(0), 0);
        uint256 bidderCount = _marketplaceSales[nftContract]
            .bids[tokenId]
            .bidders
            .length();
        for (uint256 i; i < bidderCount; i++) {
            address bidder = _marketplaceSales[nftContract]
                .bids[tokenId]
                .bidders
                .at(i);
            Bid memory bid = _marketplaceSales[nftContract].bids[tokenId].bids[
                bidder
            ];
            if (listItem.contractType == 1) {
                if (
                    _isBidValid(nftContract, bid) && bid.price > highestBid.price
                ) {
                    highestBid = bid;
                }
            } else if (listItem.contractType == 2) {
                if (
                    _isBidValidERC1155(bid) && bid.price > highestBid.price
                ) {
                    highestBid = bid;
                }
            }
        }
    }

    function checkRoyalties(address _contract) internal view returns (bool) {
        (bool success) = IERC165(_contract).supportsInterface(_INTERFACE_ID_ERC2981);
        return success;
    }

    function _collectionOwner(address collectionAddress)
        private
        view
        returns (address)
    {
        try Ownable(collectionAddress).owner() returns (address _owner) {
            return _owner;
        } catch {
            return address(0);
        }
    }

    function royaltyFromERC2981(
        address collectionAddress,
        uint256 tokenId,
        uint256 salePrice
    ) public view returns (address recipient, uint256 royaltyPrice) {
        (recipient, royaltyPrice) = IERC2981(collectionAddress).royaltyInfo(tokenId, salePrice);
    }

    function royalty(address collectionAddress)
        public
        view
        returns (CollectionRoyalty memory)
    {
        if (_collectionRoyalty[collectionAddress].setBy != address(0)) {
            return _collectionRoyalty[collectionAddress];
        }

        address collectionOwner = _collectionOwner(collectionAddress);
        if (collectionOwner != address(0)) {
            return
                CollectionRoyalty({
                    recipient: collectionOwner,
                    feeFraction: defaultRoyaltyFraction,
                    setBy: address(0)
                });
        }

        return
            CollectionRoyalty({
                recipient: address(0),
                feeFraction: 0,
                setBy: address(0)
            });
    }

    function setRoyalty(
        address collectionAddress,
        address newRecipient,
        uint256 feeFraction
    ) external {
        require(
            feeFraction <= royaltyUpperLimit,
            "Please set the royalty percentange below allowed range"
        );

        require(
            msg.sender == royalty(collectionAddress).recipient,
            "Only royalty recipient is allowed to set Royalty"
        );

        _collectionRoyalty[collectionAddress] = CollectionRoyalty({
            recipient: newRecipient,
            feeFraction: feeFraction,
            setBy: msg.sender
        });

        emit SetRoyalty({
            collectionAddress: collectionAddress,
            recipient: newRecipient,
            feeFraction: feeFraction
        });
    }

    function setRoyaltyByAdmin(
        address collectionAddress,
        address newRecipient,
        uint256 feeFraction
    ) onlyOwner external nonReentrant {
        require(
            feeFraction <= royaltyUpperLimit,
            "Please set the royalty percentange below allowed range"
        );

        _collectionRoyalty[collectionAddress] = CollectionRoyalty({
            recipient: newRecipient,
            feeFraction: feeFraction,
            setBy: msg.sender
        });

        emit SetRoyalty({
            collectionAddress: collectionAddress,
            recipient: newRecipient,
            feeFraction: feeFraction
        });
    }

    function changeSwapRouter(address router) onlyOwner external {
        swapRouter = router;
    }
}