/**
 *Submitted for verification at FtmScan.com on 2022-11-22
*/

// SPDX-License-Identifier: MIT
// solc v0.8.12+commit.f00d7308; optimized YES +200 runs
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

/**
* @title Address registry
* @dev Contains addresses of other contracts
*/
interface IPaymentTokenRegistry {
    /**
    * @notice Method for adding payment token
    * @param token ERC20 token address
    */
    function add(address token) external;

    /**
    * @notice Method for removing payment token
    * @param token ERC20 token address
    */
    function remove(address token) external;

    /**
    * @notice Check token is enabled
    * @param token ERC20 token address
    * @return bool
    */
    function isEnabled(address token) external view returns (bool);
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

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

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
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
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
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
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

/**
* @title ERC-2981 royalty setter interface
* @dev Custom implementation, ERC-2981 does not include royalty settings.
*/
interface IERC2981Settable is IERC2981 {
    /**
    * @notice Set default royalty for whole collection
    * @param recipient The receiver of royalty
    * @param royaltyPercent The royalty percentage (using 2 decimals - 10000 = 100%, 0 = 0%)
    */
    function setDefaultRoyalty(address recipient, uint96 royaltyPercent) external;

    /**
    * @notice Set royalty for a token
    * @param tokenId The token identifier
    * @param recipient The receiver of royalty
    * @param royaltyPercent The royalty percentage (using 2 decimals - 10000 = 100%, 0 = 0%)
    */
    function setTokenRoyalty(uint256 tokenId, address recipient, uint96 royaltyPercent) external;

    /**
    * @notice Update royalty recipient for whole collection
    * @param recipient The receiver of royalty
    */
    function updateDefaultRoyaltyRecipient(address recipient) external;

    /**
    * @notice Update royalty recipient for a token
    * @param tokenId The token identifier
    * @param recipient The receiver of royalty
    */
    function updateTokenRoyaltyRecipient(uint256 tokenId, address recipient) external;
}

// @notice User defined type to unify ERC721 and ERC1155
type NFTAddress is address;

/**
* @title NFT Tradable library
* @notice Set of functions to work with NFTAddress type.
*/
library NFTTradable {
    /**
     * @notice Check NFT address is ERC721
     * @param nft NFT address
     * @return bool
     */
    function isERC721(NFTAddress nft) internal view returns (bool) {
        return IERC165(toAddress(nft)).supportsInterface(type(IERC721).interfaceId);
    }

    /**
     * @notice Check NFT address is ERC1155
     * @param nft NFT address
     * @return bool
     */
    function isERC1155(NFTAddress nft) internal view returns (bool) {
        return IERC165(toAddress(nft)).supportsInterface(type(IERC1155).interfaceId);
    }

    /**
     * @notice Check NFT address is ERC2981
     * @param nft NFT address
     * @return bool
     */
    function isERC2981(NFTAddress nft) internal view returns (bool) {
        return IERC165(toAddress(nft)).supportsInterface(type(IERC2981).interfaceId);
    }

    /**
     * @notice Check NFT address is ERC2981Settable
     * @param nft NFT address
     * @return bool
     */
    function isERC2981Settable(NFTAddress nft) internal view returns (bool) {
        return IERC165(toAddress(nft)).supportsInterface(type(IERC2981Settable).interfaceId);
    }

    /**
     * @notice Convert NFT address into ERC721 instance
     * @param nft NFT address
     * @return IERC721
     */
    function toERC721(NFTAddress nft) internal pure returns (IERC721) {
        return IERC721(toAddress(nft));
    }

    /**
     * @notice Convert NFT address into ERC1155 instance
     * @param nft NFT address
     * @return IERC1155
     */
    function toERC1155(NFTAddress nft) internal pure returns (IERC1155) {
        return IERC1155(toAddress(nft));
    }

    /**
     * @notice Convert NFT address into ERC2981 instance
     * @param nft NFT address
     * @return IERC2981
     */
    function toERC2981(NFTAddress nft) internal pure returns (IERC2981) {
        return IERC2981(toAddress(nft));
    }

    /**
     * @notice Convert NFT address into ERC2981Settable instance
     * @param nft NFT address
     * @return IERC2981Settable
     */
    function toERC2981Settable(NFTAddress nft) internal pure returns (IERC2981Settable) {
        return IERC2981Settable(toAddress(nft));
    }

    /**
     * @notice Convert NFT address into underlying address
     * @param nft NFT address
     * @return address
     */
    function toAddress(NFTAddress nft) internal pure returns (address) {
        return NFTAddress.unwrap(nft);
    }
}

/**
* @title Royalty registry
* @notice Module which provides royalty functionality.
*/
interface IRoyaltyRegistry {
    /**
     * @notice Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit
     * of exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     * @param nft NFT collection
     * @param tokenId Token identifier
     * @param salePrice Sale price
     * @return address, uint256
     */
    function royaltyInfo(NFTAddress nft, uint256 tokenId, uint256 salePrice) external view returns (address, uint256);

    /**
     * @notice Sets the royalty information that all ids in this contract will default to.
     * @param nft NFT collection
     * @param recipient Royalty recipient
     * @param royaltyFraction Royalty fraction
     */
    function setDefaultRoyalty(NFTAddress nft, address recipient, uint96 royaltyFraction) external;

    /**
     * @notice Sets the royalty information for a specific token id, overriding the global default.
     * @param nft NFT collection
     * @param tokenId Token identifier
     * @param recipient Royalty recipient
     * @param royaltyFraction Royalty fraction
     */
    function setTokenRoyalty(NFTAddress nft, uint256 tokenId, address recipient, uint96 royaltyFraction) external;

    /**
    * @notice Update default royalty recipient
    * @param nft NFT address
    * @param recipient The receiver of royalty
    */
    function updateDefaultRoyaltyRecipient(NFTAddress nft, address recipient) external;

    /**
    * @notice Update royalty recipient for a token
    * @param nft NFT address
    * @param tokenId The token identifier
    * @param recipient The receiver of royalty
    */
    function updateTokenRoyaltyRecipient(NFTAddress nft, uint256 tokenId, address recipient) external;
}

/**
* @dev see {IRoyaltyRegistry}
*/
contract RoyaltyRegistry is Ownable, IRoyaltyRegistry {
    using NFTTradable for NFTAddress;

    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    /**
    * @notice nft address => token id => royalty info
    */
    mapping(address => mapping(uint256 => RoyaltyInfo)) internal _tokenRoyaltyInfo;

    /**
    * @notice nft address => royalty info
    */
    mapping(address => RoyaltyInfo) internal _defaultRoyaltyInfo;

    /**
    * @notice royalty percent denominator
    */
    uint256 internal constant ROYALTY_PERCENT_DENOMINATOR = 10_000;

    /**
     * @dev see {IRoyaltyRegistry-royaltyInfo}
     */
    function royaltyInfo(NFTAddress nft, uint256 tokenId, uint256 salePrice) public view returns (address, uint256) {
        if (nft.isERC2981()) {
            return nft.toERC2981().royaltyInfo(tokenId, salePrice);
        }

        RoyaltyInfo memory royalty = _getTokenRoyaltyInfo(nft, tokenId);
        if (! _royaltyInfoExists(royalty)) {
            royalty = _getDefaultRoyaltyInfo(nft);
        }

        return (royalty.receiver, (salePrice * royalty.royaltyFraction) / ROYALTY_PERCENT_DENOMINATOR);
    }

    /**
     * @dev see {IRoyaltyRegistry-setDefaultRoyalty}
     */
    function setDefaultRoyalty(NFTAddress nft, address recipient, uint96 royaltyFraction) onlyOwner public {
        require(! nft.isERC2981Settable(), 'RoyaltyRegistry: supports royalty setter');

        require(! _royaltyInfoExists(_getDefaultRoyaltyInfo(nft)), 'RoyaltyRegistry: royalty set');
        require(royaltyFraction <= ROYALTY_PERCENT_DENOMINATOR, 'RoyaltyRegistry: royalty too high');

        _defaultRoyaltyInfo[nft.toAddress()] = RoyaltyInfo(recipient, royaltyFraction);
    }

    /**
     * @dev see {IRoyaltyRegistry-setTokenRoyalty}
     */
    function setTokenRoyalty(NFTAddress nft, uint256 tokenId, address recipient, uint96 royaltyFraction) public {
        require(! nft.isERC2981Settable(), 'RoyaltyRegistry: supports royalty setter');

        _validateTokenOwner(nft, tokenId);

        require(! _royaltyInfoExists(_getTokenRoyaltyInfo(nft, tokenId)), 'RoyaltyRegistry: royalty set');
        require(royaltyFraction <= ROYALTY_PERCENT_DENOMINATOR, 'RoyaltyRegistry: royalty too high');

        _tokenRoyaltyInfo[nft.toAddress()][tokenId] = RoyaltyInfo(recipient, royaltyFraction);
    }

    /**
     * @dev see {IRoyaltyRegistry-updateDefaultRoyaltyRecipient}
     */
    function updateDefaultRoyaltyRecipient(NFTAddress nft, address recipient) public {
        _validateCurrentRoyaltyRecipient(_getDefaultRoyaltyInfo(nft), _msgSender());
        _defaultRoyaltyInfo[nft.toAddress()].receiver = recipient;
    }

    /**
     * @dev see {IRoyaltyRegistry-updateTokenRoyaltyRecipient}
     */
    function updateTokenRoyaltyRecipient(NFTAddress nft, uint256 tokenId, address recipient) public {
        _validateCurrentRoyaltyRecipient(_getTokenRoyaltyInfo(nft, tokenId), _msgSender());
        _tokenRoyaltyInfo[nft.toAddress()][tokenId].receiver = recipient;
    }

    /**
    * @notice Validate token owner
    * @param nft NFT address to validate
    * @param tokenId Token identifier to validate
    */
    function _validateTokenOwner(NFTAddress nft, uint256 tokenId) internal {
        if (nft.isERC721()) {
            require(nft.toERC721().ownerOf(tokenId) == _msgSender(), 'RoyaltyRegistry: not owner');
            return;
        }

        if (nft.isERC1155()) {
            require(nft.toERC1155().balanceOf(_msgSender(), tokenId) > 0, 'RoyaltyRegistry: not owner');
            return;
        }

        revert('RoyaltyRegistry: invalid nft');
    }

    /**
    * @notice Validate current royalty recipient
    * @param royalty Royalty info to validate
    * @param recipient Royalty recipient to validate
    */
    function _validateCurrentRoyaltyRecipient(RoyaltyInfo memory royalty, address recipient) internal pure {
        require(royalty.receiver == recipient, 'RoyaltyRegistry: not current recipient');
    }

    /**
    * @notice Get token royalty info
    * @param nft NFT address
    * @param tokenId Token identifier
    * @return RoyaltyInfo
    */
    function _getTokenRoyaltyInfo(NFTAddress nft, uint256 tokenId) internal view returns (RoyaltyInfo memory) {
        return _tokenRoyaltyInfo[nft.toAddress()][tokenId];
    }

    /**
    * @notice Get default royalty info
    * @param nft NFT address
    * @return RoyaltyInfo
    */
    function _getDefaultRoyaltyInfo(NFTAddress nft) internal view returns (RoyaltyInfo memory) {
        return _defaultRoyaltyInfo[nft.toAddress()];
    }

    /**
    * @notice Check royalty info exists
    * @param royalty Royalty info
    * @return bool
    */
    function _royaltyInfoExists(RoyaltyInfo memory royalty) internal pure returns (bool) {
        return royalty.receiver != address(0);
    }
}