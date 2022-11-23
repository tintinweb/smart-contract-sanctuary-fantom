/**
 *Submitted for verification at FtmScan.com on 2022-11-23
*/

// SPDX-License-Identifier: MIT
// solc v0.8.12+commit.f00d7308; optimized YES +200 runs
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

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

/**
* @title Address registry
* @dev Contains addresses of other contracts
*/
interface IAddressRegistry {
    /**
    * @notice Get payment token registry address
    * @return address
    */
    function getPaymentTokenRegistryAddress() external view returns (address);

    /**
    * @notice Update payment token registry address
    * @param paymentTokenRegistryAddress Payment token registry address
    */
    function updatePaymentTokenRegistryAddress(address paymentTokenRegistryAddress) external;

    /**
    * @notice Get royalty registry address
    * @return address
    */
    function getRoyaltyRegistryAddress() external view returns (address);

    /**
    * @notice Update royalty registry address
    * @param royaltyRegistryAddress Royalty registry address
    */
    function updateRoyaltyRegistryAddress(address royaltyRegistryAddress) external;
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
* @title Marketplace base interface
*/
interface IMarketplaceBase {}

/**
* @title ERC1155 Marketplace interface
*/
interface IERC1155Marketplace is IMarketplaceBase {
    event ERC1155AuctionCreated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 auctionId,
        address indexed owner,
        uint256 tokenAmount,
        address payToken
    );

    event ERC1155AuctionCancelled(
        address indexed nftAddress,
        address indexed nftOwner,
        uint256 indexed tokenId,
        uint256 auctionId
    );

    event ERC1155AuctionFinished(
        address oldOwner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 auctionId,
        address indexed winner,
        address payToken,
        uint256 tokenAmount,
        uint256 winningBid
    );

    event ERC1155AuctionReservePriceUpdated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 auctionId,
        address indexed owner,
        uint256 reservePrice
    );

    event ERC1155BidRefunded(
        address indexed nftAddress,
        address nftOwner,
        uint256 indexed tokenId,
        uint256 auctionId,
        address indexed bidder,
        uint256 bid
    );

    event ERC1155BidPlaced(
        address indexed nftAddress,
        address nftOwner,
        uint256 indexed tokenId,
        uint256 auctionId,
        address indexed bidder,
        uint256 bid
    );

    event ERC1155BidWithdrawn(
        address indexed nftAddress,
        address nftOwner,
        uint256 indexed tokenId,
        uint256 auctionId,
        address indexed bidder,
        uint256 bid
    );

    event ERC1155ListingCreated(
        address indexed owner,
        address indexed nft,
        uint256 indexed tokenId,
        uint256 tokenAmount,
        uint256 unitSize,
        uint256 unitPrice,
        uint256 listingId,
        address paymentToken,
        uint256 startingTime
    );

    event ERC1155ListingUpdated(
        address indexed owner,
        address indexed nft,
        uint256 indexed tokenId,
        uint256 listingId,
        address newPaymentToken,
        uint256 newPrice
    );

    event ERC1155ListingCanceled(
        address indexed owner,
        address indexed nft,
        uint256 indexed tokenId,
        uint256 listingId
    );

    event ERC1155ListedItemSold(
        address indexed seller,
        address indexed buyer,
        address indexed nft,
        uint256 tokenId,
        uint256 amount,
        uint256 remainingAmount,
        uint256 price,
        address paymentToken
    );

    event ERC1155OfferCreated(
        address indexed offeror,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 tokenAmount,
        address paymentToken,
        uint256 price,
        uint256 expirationTime,
        bool isPayTokenInEscrow
    );

    event ERC1155OfferCanceled(
        address indexed offeror,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 tokenAmount
    );

    event ERC1155OfferAccepted(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 tokenAmount,
        address indexed buyer,
        address seller,
        uint256 price,
        address paymentToken
    );
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

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

abstract contract MarketplaceBase is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IMarketplaceBase
{
    using SafeERC20 for IERC20;

    struct Auction {
        address owner;
        address paymentToken;
        uint256 reservePrice;
        bool isMinBidReservePrice;
        uint256 startTime;
        uint256 endTime;
    }

    struct HighestBid {
        address bidder;
        uint256 bidAmount;
        uint256 time;
    }

    struct Listing {
        address owner;
        address paymentToken;
        uint256 price;
        uint256 startingTime;
    }

    struct Offer {
        address paymentToken;
        address offeror;
        uint256 price;
        uint256 expirationTime;
        bool paymentTokensInEscrow;
    }

    /**
    * @notice maximum duration of an auction
    */
    uint256 internal constant MAX_AUCTION_DURATION = 30 days;

    /**
    * @notice minimum duration of an auction
    */
    uint256 internal constant MIN_AUCTION_DURATION = 5 minutes;

    /**
    * @notice bid is withdrawable after specified amount of time
    */
    uint256 internal constant HIGHEST_BID_WITHDRAW_DELAY = 12 hours;

    /**
    * @notice amount by which a bid has to increase
    */
    uint256 internal _minBidIncrementAmount;

    /*
    * @notice auction fee, assumed to be 1 decimal place i.e. 25 = 2,5%
    */
    uint256 internal _auctionFee;

    /*
    * @notice listing fee, assumed to be 1 decimal place i.e. 25 = 2,5%
    */
    uint256 internal _listingFee;

    /*
    * @notice offer fee, assumed to be 1 decimal place i.e. 25 = 2,5%
    */
    uint256 internal _offerFee;

    /**
    * @notice recipient of fees
    */
    address internal _feeRecipient;

    /**
    * @notice recipient of fees
    */
    bool internal _escrowOfferPaymentTokens;

    /**
    * @notice address registry containing addresses of other contracts
    */
    IAddressRegistry internal _addressRegistry;

    /**
     * @notice Initialize marketplace
     * @param addressRegistry Address registry address
     * @param auctionFee Auction fee - assumed to be 1 decimal place i.e. 25 = 2,5%
     * @param listingFee Listing fee - assumed to be 1 decimal place i.e. 25 = 2,5%
     * @param offerFee Offer fee - assumed to be 1 decimal place i.e. 25 = 2,5%
     * @param feeRecipient Address of fee recipient
     * @param escrowOfferPaymentTokens Hold offer payment tokens in escrow flag
     */
    function initialize(
        address addressRegistry,
        uint256 auctionFee,
        uint256 listingFee,
        uint256 offerFee,
        address feeRecipient,
        bool escrowOfferPaymentTokens
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        _minBidIncrementAmount = 1;
        _addressRegistry = IAddressRegistry(addressRegistry);
        _auctionFee = auctionFee;
        _listingFee = listingFee;
        _offerFee = offerFee;
        _feeRecipient = feeRecipient;
        _escrowOfferPaymentTokens = escrowOfferPaymentTokens;
    }

    /**
     * @notice Get minimal increment bid amount
     * @return uint256
     */
    function getMinBidIncrementAmount() public view returns (uint256) {
        return _minBidIncrementAmount;
    }

    /**
     * @notice Update minimal increment bid amount
     * @param amount New amount
     */
    function updateMinBidIncrementAmount(uint256 amount) public onlyOwner {
        _minBidIncrementAmount = amount;
    }

    /**
    * @notice Get auction fee
    * @return uint256
    */
    function getAuctionFee() public view returns (uint256) {
        return _auctionFee;
    }

    /**
     * @notice Update auction fee
     * @param auctionFee Fee amount - assumed to be 1 decimal place i.e. 25 = 2,5%
     */
    function updateAuctionFee(uint256 auctionFee) public onlyOwner {
        _auctionFee = auctionFee;
    }

    /**
    * @notice Get listing fee
    * @return uint256
    */
    function getListingFee() public view returns (uint256) {
        return _listingFee;
    }

    /**
     * @notice Update listing fee
     * @param listingFee Fee amount - assumed to be 1 decimal place i.e. 25 = 2,5%
     */
    function updateListingFee(uint256 listingFee) public onlyOwner {
        _listingFee = listingFee;
    }

    /**
    * @notice Get offer fee
    * @return uint256
    */
    function getOfferFee() public view returns (uint256) {
        return _offerFee;
    }

    /**
     * @notice Update offer fee
     * @param offerFee Fee amount - assumed to be 1 decimal place i.e. 25 = 2,5%
     */
    function updateOfferFee(uint256 offerFee) public onlyOwner {
        _offerFee = offerFee;
    }

    /**
    * @notice Get fee recipient
    * @return address
    */
    function getFeeRecipient() public view returns (address) {
        return _feeRecipient;
    }

    /**
     * @notice Update fee recipient
     * @param feeRecipient Fee recipient
     */
    function updateFeeRecipient(address feeRecipient) public onlyOwner {
        _feeRecipient = feeRecipient;
    }

    /**
    * @notice Get flag if payment tokens from new offers should be stored in escrow
    * @return bool
    */
    function getEscrowOfferPaymentTokens() public view returns (bool) {
        return _escrowOfferPaymentTokens;
    }

    /**
     * @notice Update flag if payment tokens from new offers should be stored in escrow
     * @param escrowOfferPaymentTokens payment tokens should be stored in escrow
     */
    function updateEscrowOfferPaymentTokens(bool escrowOfferPaymentTokens) public onlyOwner {
        _escrowOfferPaymentTokens = escrowOfferPaymentTokens;
    }

    /**
     * @notice Update address registry address
     * @param addressRegistry address registry address
     */
    function updateAddressRegistryAddress(address addressRegistry) public onlyOwner {
        _addressRegistry = IAddressRegistry(addressRegistry);
    }

    /**
     * @notice Get address registry address
     * @return address
     */
    function getAddressRegistryAddress() public view returns (address) {
        return address(_addressRegistry);
    }

    /**
     * @notice Get auction maximum duration
     * @return uint256
     */
    function getMaximumAuctionDuration() public pure returns (uint256) {
        return MAX_AUCTION_DURATION;
    }

    /**
     * @notice Get auction minimum duration
     * @return uint256
     */
    function getMinimumAuctionDuration() public pure returns (uint256) {
        return MIN_AUCTION_DURATION;
    }

    /**
     * @notice Get highest bid withdraw delay
     * @return uint256
     */
    function getHighestBidWithdrawDelay() public pure returns (uint256) {
        return HIGHEST_BID_WITHDRAW_DELAY;
    }

    /**
     * @notice Refund highest bid
     * @param auction Auction related to bid
     * @param highestBid Bid to refund
     */
    function _refundHighestBid(Auction memory auction, HighestBid memory highestBid) internal {
        _sendPayTokenAmount(auction.paymentToken, highestBid.bidder, highestBid.bidAmount);
    }

    /**
    * @notice Calculate and take auction fee
    * @param auction Auction to calculate fee from
    * @param highestBid Highest bid to calculate fee from
    * @return uint256 - taken fee
    */
    function _calculateAndTakeAuctionFee(
        Auction memory auction,
        HighestBid memory highestBid
    ) internal returns (uint256) {
        uint256 fee = highestBid.bidAmount * _auctionFee / 1_000;

        if (fee == 0) {
            return 0;
        }

        _sendPayTokenAmount(auction.paymentToken, _feeRecipient, fee);

        return fee;
    }

    // DISCUSS: Merge fee calculation into one function?
    /**
    * @notice Calculate and take listing fee from address
    * @param price Listing price
    * @param paymentToken Payment token used to take fee from
    * @param from Take fee from
    * @return uint256 - taken fee
    */
    function _calculateAndTakeListingFeeFrom(
        uint256 price,
        address paymentToken,
        address from
    ) internal returns (uint256) {
        uint256 fee = price * _listingFee / 1_000;

        if (fee == 0) {
            return 0;
        }

        _transferPayTokenAmount(paymentToken, from, _feeRecipient, fee);

        return fee;
    }

    /**
    * @notice Calculate and take offer fee
    * @param offer Offer to calculate fee from
    * @return uint256 - taken fee
    */
    function _calculateAndTakeOfferFee(Offer memory offer) internal returns (uint256) {
        uint256 fee = offer.price * _offerFee / 1_000;

        if (fee == 0) {
            return 0;
        }

        // If offer was created when payment tokens were not stored in escrow,
        // transfer payment tokens from offeror to fee recipient
        // otherwise transfer payment tokens from escrow to fee recipient
        if (offer.paymentTokensInEscrow) {
            _sendPayTokenAmount(offer.paymentToken, _feeRecipient, fee);
        } else {
            _transferPayTokenAmount(offer.paymentToken, offer.offeror, _feeRecipient, fee);
        }

        return fee;
    }

    /**
    * @notice Calculate and take royalty fee
    * @param nft NFT address
    * @param tokenId Token identifier
    * @param paymentToken Payment token
    * @param payAmount Payment amount
    * @return uint256
    */
    function _calculateAndTakeRoyaltyFee(
        NFTAddress nft,
        uint256 tokenId,
        address paymentToken,
        uint256 payAmount
    ) internal returns (uint256) {
        (address recipient, uint256 royaltyAmount) = _getRoyaltyRegistry().royaltyInfo(nft, tokenId, payAmount);
        if (recipient != address(0) && royaltyAmount > 0) {
            _sendPayTokenAmount(paymentToken, recipient, royaltyAmount);
            return royaltyAmount;
        }

        return 0;
    }

    /**
    * @notice Calculate and take royalty fee from address
    * @param nft NFT address
    * @param tokenId Token identifier
    * @param paymentToken Payment token
    * @param payAmount Payment amount
    * @param from Take royalty from address
    * @return uint256
    */
    function _calculateAndTakeRoyaltyFeeFrom(
        NFTAddress nft,
        uint256 tokenId,
        address paymentToken,
        uint256 payAmount,
        address from
    ) internal returns (uint256) {
        (address recipient, uint256 royaltyAmount) = _getRoyaltyRegistry().royaltyInfo(nft, tokenId, payAmount);
        if (recipient != address(0) && royaltyAmount > 0) {
            _transferPayTokenAmount(paymentToken, from, recipient, royaltyAmount);
            return royaltyAmount;
        }

        return 0;
    }

    /**`
     * @notice Receive pay token amount
     * @param payToken Address of ERC20
     * @param from Sender address
     * @param amount Amount to transfer
     */
    function _receivePayTokenAmount(address payToken, address from, uint256 amount) internal {
        IERC20(payToken).safeTransferFrom(from, address(this), amount);
    }

    /**
     * @notice Send ERC20 amount
     * @param payToken Address of ERC20
     * @param to Receiver address
     * @param amount Amount to transfer
     */
    function _sendPayTokenAmount(address payToken, address to, uint256 amount) internal {
        IERC20(payToken).safeTransfer(payable(to), amount);
    }

    /**
     * @notice Transfer ERC20 amount
     * @param payToken Address of ERC20
     * @param from Sender address
     * @param to Receiver address
     * @param amount Amount to transfer
     */
    function _transferPayTokenAmount(address payToken, address from, address to, uint256 amount) internal {
        IERC20(payToken).safeTransferFrom(from, payable(to), amount);
    }

    /**
     * @notice Validate if target has enough of payment tokens
     * @param target Target to validate
     * @param paymentToken ERC20 payment token
     * @param amount Total amount of payment tokens
     */
    function _validatePaymentTokenAmount(address target, address paymentToken, uint256 amount) internal {
        require(IERC20(paymentToken).balanceOf(target) >= amount,  "MarketplaceBase: low balance");
    }

    /**
     * @notice Validate payment token is enabled
     * @param paymentToken Payment token address
     */
    function _validatePaymentTokenIsEnabled(address paymentToken) internal {
        require(
            _getPaymentTokenRegistry().isEnabled(paymentToken),
            'MarketplaceBase: payment token not enabled'
        );
    }

    /**
     * @notice Validate new auction time
     * @param startTime Start time as unix time
     * @param endTime End time as unix time
     */
    function _validateNewAuctionTime(uint256 startTime, uint256 endTime) internal pure {
        require(
            endTime <= (startTime + MAX_AUCTION_DURATION),
            'MarketplaceBase: Auction time exceeds maximum duration'
        );
        require(
            endTime >= (startTime + MIN_AUCTION_DURATION),
            "MarketplaceBase: Auction time does not meet minimum duration"
        );
    }

    /**
     * @notice Validate payment token addresses match
     * @param firstAddress First address to compare
     * @param secondAddress Second address to compare
     */
    function _validatePaymentTokenAddressMatch(address firstAddress, address secondAddress) internal pure {
        require(firstAddress == secondAddress, 'MarketplaceBase: payment token mismatch');
    }

    /**
     * @notice Validate prices match
     * @param firstPrice First price to compare
     * @param secondPrice Second price to compare
     */
    function _validatePriceMatch(uint256 firstPrice, uint256 secondPrice) internal pure {
        require(firstPrice == secondPrice, 'MarketplaceBase: price mismatch');
    }

    /**
     * @notice Validate address is auction owner
     * @param auction Auction to validate
     * @param entrant Address to validate
     */
    function _validateAuctionOwner(Auction memory auction, address entrant) internal pure {
        require(auction.owner == entrant, 'MarketplaceBase: not owner');
    }

    /**
     * @notice Validate auction reserve price update
     * @param auction Auction to validate
     * @param reservePrice Reserve price to validate
     */
    function _validateAuctionReservePriceUpdate(Auction memory auction, uint256 reservePrice) internal pure {
        require(auction.reservePrice > reservePrice, 'MarketplaceBase: reserve price can only decrease');
    }

    /**
     * @notice Validate highest bid owner
     * @param highestBid Highest bid to validate
     */
    function _validateAuctionHighestBidOwner(HighestBid memory highestBid, address bidder) internal pure {
        require(highestBid.bidder == bidder, 'MarketplaceBase: not highest bidder');
    }

    /**
     * @notice Validate address is auction or highest bid owner
     * @param auction Auction to validate
     * @param highestBid Highest bid to validate
     * @param entrant Address to validate
     */
    function _validateAuctionOrHighestBidOwner(
        Auction memory auction,
        HighestBid memory highestBid,
        address entrant
    ) internal pure {
        require(
            auction.owner == entrant || highestBid.bidder == entrant,
            'MarketplaceBase: not auction or highest bid owner'
        );
    }

    /**
     * @notice Validate highest bid owner
     * @param auction Auction to validate
     * @param highestBid Highest bid to validate
     */
    function _validateAuctionHighestBidIsWithdrawable(
        Auction memory auction,
        HighestBid memory highestBid
    ) internal {
        // must wait when bid is above or equal reserve price
        if (_auctionHighestBidAboveOrEqualReservePrice(auction, highestBid)) {
            require(
                (HIGHEST_BID_WITHDRAW_DELAY + auction.endTime) <= _getNow(),
                'MarketplaceBase: must wait to withdraw'
            );
        }
    }

    /**
     * @notice Validate highest bid exists
     * @param highestBid Highest bid to validate
     */
    function _validateHighestBidExists(HighestBid memory highestBid) internal pure {
        require(_highestBidExists(highestBid), 'MarketplaceBase: highest bid not exists');
    }

    /**
     * @notice Validate auction highest bid is above or equal reserve price
     * @param auction Auction to validate
     * @param highestBid Highest bid to validate
     */
    function _validateAuctionHighestBidAboveOrEqualReservePrice(
        Auction memory auction,
        HighestBid memory highestBid
    ) internal pure {
        require(
            _auctionHighestBidAboveOrEqualReservePrice(auction, highestBid),
            'MarketplaceBase: highest bid below reserve price'
        );
    }

    /**
     * @notice Validate auction highest bid is not above reserve price
     * @param auction Auction to validate
     * @param highestBid Highest bid to validate
     */
    function _validateAuctionHighestBidBelowReservePrice(
        Auction memory auction,
        HighestBid memory highestBid
    ) internal pure {
        require(
            ! _auctionHighestBidAboveOrEqualReservePrice(auction, highestBid),
            'MarketplaceBase: highest bid above reserve price'
        );
    }

    /**
     * @notice Validate auction exists
     * @param auction Auction to validate
     */
    function _validateAuctionExists(Auction memory auction) internal pure {
        require(_auctionExists(auction), 'MarketplaceBase: auction not exists');
    }

    /**
     * @notice Validate auction does not exist
     * @param auction Auction to validate
     */
    function _validateAuctionNotExists(Auction memory auction) internal pure {
        require(! _auctionExists(auction), 'MarketplaceBase: auction exists');
    }

    /**
     * @notice Validate listing exists
     * @param listing Listing to validate
     */
    function _validateListingExists(Listing memory listing) internal pure {
        require(_listingExists(listing), 'MarketplaceBase: listing not exists');
    }

    /**
     * @notice Validate listing not exists
     * @param listing Listing to validate
     */
    function _validateListingNotExists(Listing memory listing) internal pure {
        require(! _listingExists(listing), 'MarketplaceBase: listing exists');
    }

    /**
     * @notice Validate offer exists
     * @param offer Offer to validate
     */
    function _validateOfferExists(Offer memory offer) internal pure {
        require(_offerExists(offer), 'MarketplaceBase: offer not exists');
    }

    /**
     * @notice Validate offer not exists
     * @param offer Offer to validate
     */
    function _validateOfferNotExists(Offer memory offer) internal pure {
        require(! _offerExists(offer), 'MarketplaceBase: offer exists');
    }

    /**
     * @notice Validate auction has started
     * @param auction Auction to validate
     */
    function _validateAuctionStarted(Auction memory auction) internal {
        require(_auctionStarted(auction), 'MarketplaceBase: auction not started');
    }

    /**
     * @notice Validate listing has started
     * @param listing Listing to validate
     */
    function _validateListingStarted(Listing memory listing) internal {
        require(_listingStarted(listing), 'MarketplaceBase: listing not started');
    }

    /**
     * @notice Validate auction has not started
     * @param auction Auction to validate
     */
    function _validateAuctionNotStarted(Auction memory auction) internal {
        require(! _auctionStarted(auction), 'MarketplaceBase: auction started');
    }

    /**
     * @notice Validate listing has not started
     * @param listing Listing to validate
     */
    function _validateListingNotStarted(Listing memory listing) internal {
        require(! _listingStarted(listing), 'MarketplaceBase: listing started');
    }

    /**
     * @notice Validate auction has ended
     * @param auction Auction to validate
     */
    function _validateAuctionEnded(Auction memory auction) internal {
        require(_auctionEnded(auction), 'MarketplaceBase: auction not ended');
    }

    /**
     * @notice Validate auction has not ended
     * @param auction Auction to validate
     */
    function _validateAuctionNotEnded(Auction memory auction) internal {
        require(! _auctionEnded(auction), 'MarketplaceBase: auction ended');
    }

    /**
     * @notice Validate offer has not expired
     * @param offer Offer to validate
     */
    function _validateOfferNotExpired(Offer memory offer) internal {
        require(offer.expirationTime > _getNow(), 'MarketplaceBase: offer expired');
    }

    /**
     * @notice Validate auction bid amount
     * @param auction Auction to validate
     * @param auction Highest bid to validate
     * @param bidAmount Bid amount to validate
     */
    function _validateAuctionBidAmount(
        Auction memory auction,
        HighestBid memory highestBid,
        uint256 bidAmount
    ) internal view {
        // bid amount must be increased at least by minimal bid increment amount
        uint256 minBidAmount = highestBid.bidAmount + _minBidIncrementAmount;
        require(bidAmount >= minBidAmount, 'MarketplaceBase: low bid amount');

        // if minimal bid is set to reserve price, bid can not be lower than reserve price
        if (auction.isMinBidReservePrice) {
            require(bidAmount >= auction.reservePrice, 'MarketplaceBase: bid lower than reserve price');
        }
    }

    /**
     * @notice Validate auction bidder is not owner
     * @param auction Auction to validate
     * @param bidder Bidder to validate
     */
    function _validateAuctionBidderNotOwner(Auction memory auction, address bidder) internal pure {
        require(auction.owner != bidder, 'MarketplaceBase: bidder auction owner');
    }

    /**
     * @notice Validate new listing time
     * @param startTime Start time as unix time
     */
    function _validateNewListingTime(uint256 startTime) internal {
        require(startTime >= _getNow(), 'MarketplaceBase: invalid start time');
    }

    /**
     * @notice Validate that listing has started already
     * @param startTime Start time as unix time
     */
    function _validateListingStarted(uint256 startTime) internal view {
        require(_getNow() >= startTime, "MarketplaceBase: listing has not started");
    }

    /**
     * @notice Validate offer expiration time
     * @param expirationTime Expiration time as unix time
     */
    function _validateOfferExpirationTime(uint256 expirationTime) internal view {
        require(expirationTime >= _getNow(), 'MarketplaceBase: invalid expiration time');
    }

    /**
     * @notice Validate ownership
     * @param firstAddress Address to validate
     * @param secondAddress Address to validate
     */
    function _validateOwnership(address firstAddress, address secondAddress) internal view {
        require(firstAddress == secondAddress, 'MarketplaceBase: not owner');
    }

    /**
     * @notice Check auction highest bid is above or equal reserve price
     * @param auction Auction to check
     * @param highestBid Highest bid to check
     */
    function _auctionHighestBidAboveOrEqualReservePrice(
        Auction memory auction,
        HighestBid memory highestBid
    ) internal pure returns (bool) {
        return highestBid.bidAmount >= auction.reservePrice;
    }

     /**
     * @notice Check auction exists
     * @param auction Auction to check
     * @return bool
     */
    function _auctionExists(Auction memory auction) internal pure returns (bool) {
        return auction.startTime > 0;
    }

    /**
     * @notice Check highest bid exists
     * @param highestBid Bid to check
     * @return bool
     */
    function _highestBidExists(HighestBid memory highestBid) internal pure returns (bool) {
        return highestBid.bidAmount > 0;
    }

    /**
     * @notice Check listing exists
     * @param listing Listing to check
     * @return bool
     */
    function _listingExists(Listing memory listing) internal pure returns (bool) {
        return listing.startingTime > 0;
    }

    /**
     * @notice Check offer exists
     * @param offer Offer to check
     * @return bool
     */
    function _offerExists(Offer memory offer) internal pure returns (bool) {
        return offer.expirationTime > 0;
    }

    /**
     * @notice Check auction has started
     * @param auction Auction to check
     * @return bool
     */
    function _auctionStarted(Auction memory auction) internal view returns (bool) {
        return auction.startTime <= _getNow();
    }

    /**
     * @notice Check listing has started
     * @param listing Listing to check
     * @return bool
     */
    function _listingStarted(Listing memory listing) internal view returns (bool) {
        return listing.startingTime <= _getNow();
    }

    /**
     * @notice Check auction has ended
     * @param auction Auction to check
     * @return bool
     */
    function _auctionEnded(Auction memory auction) internal view returns (bool) {
        return auction.endTime <= _getNow();
    }

    /**
     * @notice Get payment token registry contract
     * @return IPaymentTokenRegistry
     */
    function _getPaymentTokenRegistry() internal returns (IPaymentTokenRegistry) {
        return IPaymentTokenRegistry(_addressRegistry.getPaymentTokenRegistryAddress());
    }

    /**
     * @notice Get royalty registry contract
     * @return IRoyaltyRegistry
     */
    function _getRoyaltyRegistry() internal returns (IRoyaltyRegistry) {
        return IRoyaltyRegistry(_addressRegistry.getRoyaltyRegistryAddress());
    }

    /**
     * @notice Get current timestamp
     * @return uint256
     */
    function _getNow() internal view returns (uint256) {
        return block.timestamp;
    }
}

/**
* @title ERC1155 Marketplace interface
*/
interface IERC721Marketplace is IMarketplaceBase {
    // @notice Events for listing
    event ERC721ListingCreated(
        address indexed nftOwner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address paymentToken,
        uint256 price,
        uint256 startingTime
    );

    event ERC721ListingUpdated(
        address indexed nftOwner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address newPaymentToken,
        uint256 newPrice
    );

    event ERC721ListingCanceled(
        address indexed nftOwner,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event ERC721ListedItemSold(
        address indexed seller,
        address indexed buyer,
        address indexed nftAddress,
        uint256 tokenId,
        uint256 price,
        address paymentToken
    );

    // @notice Events for offers
    event ERC721OfferCreated(
        address indexed offeror,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address paymentToken,
        uint256 price,
        uint256 expirationTime,
        bool isPayTokenInEscrow
    );

    event ERC721OfferCanceled(
        address indexed offeror,
        address indexed nftAddress,
        uint256 tokenId
    );

    event ERC721OfferAccepted(
        address indexed nftAddress,
        uint256 tokenId,
        address indexed buyer,
        address seller,
        uint256 price,
        address paymentToken
    );

    // @notice Events for auctions
    event ERC721AuctionCreated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed owner,
        address payToken
    );

    event ERC721AuctionCancelled(
        address indexed nftAddress,
        address indexed nftOwner,
        uint256 indexed tokenId
    );

    event ERC721AuctionFinished(
        address oldOwner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed winner,
        address payToken,
        uint256 winningBid
    );

    event ERC721AuctionReservePriceUpdated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed owner,
        uint256 reservePrice
    );

    event ERC721BidRefunded(
        address indexed nftAddress,
        address nftOwner,
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 bid
    );

    event ERC721BidPlaced(
        address indexed nftAddress,
        address nftOwner,
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 bid
    );

    event ERC721BidWithdrawn(
        address indexed nftAddress,
        address nftOwner,
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 bid
    );
}

contract ERC721Marketplace is ERC721Holder, MarketplaceBase, IERC721Marketplace {
    using NFTTradable for NFTAddress;

    // @notice NftAddress -> Token ID -> Listed item
    mapping(address => mapping(uint256 => Listing)) internal _listings;

    // @notice NftAddress -> Token ID -> Offeror -> Offer
    mapping(address => mapping(uint256 =>  mapping(address => Offer))) internal _offers;

    // @notice NftAddress -> Token ID -> auction
    mapping(address => mapping(uint256 => Auction)) internal _auctions;

    // @notice NftAddress -> Token ID -> highest bid
    mapping(address => mapping(uint256 => HighestBid)) internal _highestBids;

    /// @notice Method for listing an NFT
    /// @param nftAddress Address of NFT contract
    /// @param tokenId Token ID of NFT
    /// @param paymentToken Payment token
    /// @param price Sale price for token
    /// @param startingTime Scheduling for a future sale
    function createListing(
        NFTAddress nftAddress,
        uint256 tokenId,
        address paymentToken,
        uint256 price,
        uint256 startingTime
    ) public whenNotPaused {
        _validateTokenInterface(nftAddress);
        _validateListingNotExists(getListing(nftAddress, tokenId));
        _validateNewListingTime(startingTime);
        _validatePaymentTokenIsEnabled(paymentToken);

        // transfer token to be held in escrow
        nftAddress.toERC721().safeTransferFrom(_msgSender(), address(this), tokenId, new bytes(0));

        _listings[nftAddress.toAddress()][tokenId] = Listing(
            payable(_msgSender()),
            paymentToken,
            price,
            startingTime
        );

        emit ERC721ListingCreated(
            _msgSender(),
            nftAddress.toAddress(),
            tokenId,
            paymentToken,
            price,
            startingTime
        );
    }

    /// @notice Method for updating listed NFT
    /// @param nftAddress Address of NFT contract
    /// @param tokenId Token ID of NFT
    /// @param newPaymentToken Payment token
    /// @param newPrice New sale price for token
    function updateListing(
        NFTAddress nftAddress,
        uint256 tokenId,
        address newPaymentToken,
        uint256 newPrice
    ) public {
        _validateListingExists(getListing(nftAddress, tokenId));
        _validatePaymentTokenIsEnabled(newPaymentToken);

        Listing storage listedItem = _listings[nftAddress.toAddress()][tokenId];
        _validateOwnership(listedItem.owner, _msgSender());

        listedItem.paymentToken = newPaymentToken;
        listedItem.price = newPrice;

        emit ERC721ListingUpdated(
            _msgSender(),
            nftAddress.toAddress(),
            tokenId,
            newPaymentToken,
            newPrice
        );
    }

    /// @notice Method for canceling listed NFT
    /// @param nftAddress Address of NFT contract
    /// @param tokenId Token ID of NFT
    function cancelListing(
        NFTAddress nftAddress,
        uint256 tokenId
    ) public nonReentrant {
        Listing memory listing = getListing(nftAddress, tokenId);

        _validateListingExists(listing);
        _validateOwnership(listing.owner, _msgSender());

        _deleteListing(nftAddress, tokenId);

        // transfer token from escrow back to original owner
        nftAddress.toERC721().safeTransferFrom(address(this), listing.owner, tokenId, new bytes(0));

        emit ERC721ListingCanceled(_msgSender(), nftAddress.toAddress(), tokenId);
    }

    /// @notice Method for buying listed NFT
    /// @param nftAddress NFT contract address
    /// @param tokenId TokenId
    /// @param requestedPaymentToken Payment token
    function buyListedItem(
        NFTAddress nftAddress,
        uint256 tokenId,
        uint256 requestedUnitPrice,
        address requestedPaymentToken
    ) public nonReentrant whenNotPaused {
        Listing memory listing = getListing(nftAddress, tokenId);

        _validateListingExists(listing);
        _validateListingStarted(listing.startingTime);
        // validate price and payment token in case of listing update
        _validatePriceMatch(listing.price, requestedUnitPrice);
        _validatePaymentTokenAddressMatch(listing.paymentToken, requestedPaymentToken);

        _deleteListing(nftAddress, tokenId);

        // Calculate and transfer platform fee and royalty
        uint256 finalAmount = listing.price - _calculateAndTakeListingFeeFrom(
            listing.price, listing.paymentToken, _msgSender()
        );
        finalAmount -= _calculateAndTakeRoyaltyFeeFrom(
            nftAddress, tokenId, listing.paymentToken, finalAmount, _msgSender()
        );

        // Transfer payment tokens from buyer to owner of NFT
        _transferPayTokenAmount(listing.paymentToken, _msgSender(), listing.owner, finalAmount);

        // Transfer NFT to buyer
        nftAddress.toERC721().safeTransferFrom(address(this), _msgSender(), tokenId, new bytes(0));

        emit ERC721ListedItemSold(
            listing.owner,
            _msgSender(),
            nftAddress.toAddress(),
            tokenId,
            listing.price,
            listing.paymentToken
        );
    }

    /// @notice Method for creating an offer on NFT
    /// @param nftAddress NFT contract address
    /// @param tokenId TokenId
    /// @param paymentToken Payment token
    /// @param price Offered price
    /// @param expirationTime Offer expiration
    function createOffer(
        NFTAddress nftAddress,
        uint256 tokenId,
        address paymentToken,
        uint256 price,
        uint256 expirationTime
    ) public whenNotPaused {
        _validateTokenInterface(nftAddress);
        _validatePaymentTokenIsEnabled(paymentToken);
        _validateOfferExpirationTime(expirationTime);
        _validateOfferNotExists(getOffer(nftAddress, tokenId, _msgSender()));

        // Lock payment token amount in marketplace
        if (_escrowOfferPaymentTokens) {
            _receivePayTokenAmount(paymentToken, _msgSender(), price);
        }

        _offers[nftAddress.toAddress()][tokenId][_msgSender()] = Offer(
            paymentToken,
            _msgSender(),
            price,
            expirationTime,
            _escrowOfferPaymentTokens
        );

        emit ERC721OfferCreated(
            _msgSender(),
            nftAddress.toAddress(),
            tokenId,
            paymentToken,
            price,
            expirationTime,
            _escrowOfferPaymentTokens
        );
    }

    /// @notice Method for canceling the offer
    /// @param nftAddress NFT contract address
    /// @param tokenId TokenId
    function cancelOffer(NFTAddress nftAddress, uint256 tokenId) public nonReentrant {
        Offer memory offer = getOffer(nftAddress, tokenId, _msgSender());

        _validateOfferExists(offer);

        _deleteOffer(nftAddress, tokenId, _msgSender());

        // Return locked payment tokens to offeror
        if (offer.paymentTokensInEscrow) {
            _sendPayTokenAmount(offer.paymentToken, offer.offeror, offer.price);
        }

        emit ERC721OfferCanceled(_msgSender(), nftAddress.toAddress(), tokenId);
    }

    /// @notice Method for accepting the offer
    /// @param nftAddress NFT contract address
    /// @param tokenId TokenId
    function acceptOffer(NFTAddress nftAddress, uint256 tokenId, address offeror) public nonReentrant whenNotPaused {
        Offer memory offer = getOffer(nftAddress, tokenId, offeror);

        _validateOfferExists(offer);
        _validateOfferNotExpired(offer);

        _deleteOffer(nftAddress, tokenId, offeror);

        // Calculate and transfer platform fee
        uint256 finalAmount = offer.price - _calculateAndTakeOfferFee(offer);

        // Calculate royalty and transfer payment tokens
        // If offer was created when payment tokens were not stored in escrow,
        // transfer payment tokens from escrow to owner of NF,
        // transfer payment tokens from offeror to owner of NFT otherwise
        if (offer.paymentTokensInEscrow) {
            finalAmount -= _calculateAndTakeRoyaltyFee(nftAddress, tokenId, offer.paymentToken, finalAmount);
            _sendPayTokenAmount(offer.paymentToken, _msgSender(), finalAmount);
        } else {
            finalAmount -= _calculateAndTakeRoyaltyFeeFrom(
                nftAddress, tokenId, offer.paymentToken, finalAmount, offer.offeror
            );
            _transferPayTokenAmount(offer.paymentToken, offeror, _msgSender(), finalAmount);
        }

        // Transfer NFT to offeror
        nftAddress.toERC721().safeTransferFrom(_msgSender(), offeror, tokenId, new bytes(0));

        emit ERC721OfferAccepted(
            nftAddress.toAddress(),
            tokenId,
            offeror,
            _msgSender(),
            offer.price,
            offer.paymentToken
        );
    }

    /**
     * @notice Create new auction
     * @param nftAddress NFT address
     * @param tokenId Token identifier
     * @param paymentToken Payment token that will be used for auction
     * @param reservePrice NFT address
     * @param startTime NFT address
     * @param endTime NFT address
     * @param isMinBidReservePrice NFT address
     */
    function createAuction(
        NFTAddress nftAddress,
        uint256 tokenId,
        address paymentToken,
        uint256 reservePrice,
        uint256 startTime,
        uint256 endTime,
        bool isMinBidReservePrice
    ) public whenNotPaused {
        _validateTokenInterface(nftAddress);
        _validatePaymentTokenIsEnabled(paymentToken);
        _validateAuctionNotExists(getAuction(nftAddress, tokenId));
        _validateNewAuctionTime(startTime, endTime);

        _createAuctionAndTransferToken(
            nftAddress, tokenId, _msgSender(), paymentToken, reservePrice, startTime, endTime, isMinBidReservePrice
        );

        emit ERC721AuctionCreated(nftAddress.toAddress(), tokenId, _msgSender(), paymentToken);
    }

    /**
     * @notice Cancel auction
     * @param nftAddress NFT address
     * @param tokenId Token identifier
     */
    function cancelAuction(NFTAddress nftAddress, uint256 tokenId) public nonReentrant {
        Auction memory auction = getAuction(nftAddress, tokenId);

        _validateAuctionExists(auction);
        _validateOwnership(auction.owner, _msgSender());

        HighestBid memory highestBid = getHighestBid(nftAddress, tokenId);

        _validateAuctionHighestBidBelowReservePrice(auction, highestBid);

        _deleteAuctionAndTransferToken(nftAddress, auction, tokenId);

        emit ERC721AuctionCancelled(nftAddress.toAddress(), _msgSender(), tokenId);

        if (_highestBidExists(highestBid)) {
            _refundHighestBid(auction, highestBid);
            _deleteHighestBid(nftAddress, tokenId);
            emit ERC721BidRefunded(
                nftAddress.toAddress(), auction.owner, tokenId, highestBid.bidder, highestBid.bidAmount
            );
        }
    }

    /**
     * @notice Finish auction successfully
     * @dev Successfully finish auction, to unsuccessfully finish auction call `cancelAuction`
     * @param nftAddress NFT address
     * @param tokenId Token identifier
     */
    function finishAuction(NFTAddress nftAddress, uint256 tokenId) public nonReentrant {
        (Auction memory auction, HighestBid memory highestBid) =
            _getValidatedFinishedAuctionAndHighestBid(nftAddress, tokenId);

        _validateAuctionOrHighestBidOwner(auction, highestBid, _msgSender());
        _validateAuctionHighestBidAboveOrEqualReservePrice(auction, highestBid);

        _finishAuctionSuccessFully(nftAddress, tokenId, auction, highestBid);
    }

    /**
     * @notice Finish auction successfully with bid below reserve price
     * @dev Successfully finish auction, to unsuccessfully finish auction call `cancelAuction`
     * @param nftAddress NFT address
     * @param tokenId Token identifier
     */
    function finishAuctionBelowReservePrice(NFTAddress nftAddress, uint256 tokenId) public nonReentrant {
        (Auction memory auction, HighestBid memory highestBid) =
            _getValidatedFinishedAuctionAndHighestBid(nftAddress, tokenId);

        _validateAuctionOwner(auction, _msgSender());
        _validateAuctionHighestBidBelowReservePrice(auction, highestBid);

        _finishAuctionSuccessFully(nftAddress, tokenId, auction, highestBid);
    }

    /**
     * @notice Update auction reserve price
     * @param nftAddress NFT address
     * @param tokenId Token identifier
     * @param reservePrice New reserve price
     */
    function updateAuctionReservePrice(
        NFTAddress nftAddress,
        uint256 tokenId,
        uint256 reservePrice
    ) public {
        Auction memory auction = getAuction(nftAddress, tokenId);

        _validateAuctionExists(auction);
        _validateAuctionOwner(auction, _msgSender());
        _validateAuctionReservePriceUpdate(auction, reservePrice);

        _auctions[nftAddress.toAddress()][tokenId].reservePrice = reservePrice;

        emit ERC721AuctionReservePriceUpdated(
            nftAddress.toAddress(),
            tokenId,
            _msgSender(),
            reservePrice
        );
    }

    /**
     * @notice Place bid
     * @param nftAddress NFT address
     * @param tokenId Token identifier
     * @param bidAmount Bid amount
     */
    function placeBid(NFTAddress nftAddress, uint256 tokenId, uint256 bidAmount) public nonReentrant whenNotPaused {
        Auction memory auction = getAuction(nftAddress, tokenId);

        _validateAuctionExists(auction);
        _validateAuctionStarted(auction);
        _validateAuctionNotEnded(auction);
        _validateAuctionBidderNotOwner(auction, _msgSender());

        HighestBid memory highestBid = getHighestBid(nftAddress, tokenId);

        _validateAuctionBidAmount(auction, highestBid, bidAmount);

        _createBidAndTransferPayTokenAmount(
            nftAddress, auction.paymentToken, tokenId, _msgSender(), bidAmount
        );

        emit ERC721BidPlaced(nftAddress.toAddress(), auction.owner, tokenId, _msgSender(), bidAmount);

        if (_highestBidExists(highestBid)) {
            _refundHighestBid(auction, highestBid);
            emit ERC721BidRefunded(
                nftAddress.toAddress(),
                auction.owner,
                tokenId,
                highestBid.bidder,
                highestBid.bidAmount
            );
        }
    }

    /**
     * @notice Withdraw bid
     * @param nftAddress NFT address
     * @param tokenId Token identifier
     */
    function withdrawBid(NFTAddress nftAddress, uint256 tokenId) public nonReentrant whenNotPaused {
        HighestBid memory highestBid = getHighestBid(nftAddress, tokenId);

        _validateHighestBidExists(highestBid);
        _validateAuctionHighestBidOwner(highestBid, _msgSender());

        Auction memory auction = getAuction(nftAddress, tokenId);

        _validateAuctionEnded(auction);
        _validateAuctionHighestBidIsWithdrawable(auction, highestBid);

        _deleteHighestBid(nftAddress, tokenId);

        _refundHighestBid(auction, highestBid);

        emit ERC721BidWithdrawn(
            nftAddress.toAddress(), auction.owner, tokenId, _msgSender(), highestBid.bidAmount
        );
    }

    ////////////////////////////
    /// Setters and Getters ///
    ///////////////////////////

    /**
     * @notice Get listing
     * @param nftAddress NFT address
     * @param tokenId Token identifier
     * @return Listing
     */
    function getListing(NFTAddress nftAddress, uint256 tokenId) public view returns (Listing memory) {
        return _listings[nftAddress.toAddress()][tokenId];
    }

    /**
     * @notice Get offer
     * @param nftAddress NFT address
     * @param tokenId Token identifier
     * @return Offer
     */
    function getOffer(NFTAddress nftAddress, uint256 tokenId, address offeror) public view returns (Offer memory) {
        return _offers[nftAddress.toAddress()][tokenId][offeror];
    }

    /**
     * @notice Get auction for given token and owner
     * @param nftAddress NFT address
     * @param tokenId Token identifier
     * @return ERC1155Auction
     */
    function getAuction(NFTAddress nftAddress, uint256 tokenId) public view returns (Auction memory) {
        return _auctions[nftAddress.toAddress()][tokenId];
    }

    /**
     * @notice Get highest bid for given token and owner
     * @param nftAddress NFT address
     * @param tokenId Token identifier
     * @return HighestBid
     */
    function getHighestBid(NFTAddress nftAddress, uint256 tokenId) public view returns (HighestBid memory) {
        return _highestBids[nftAddress.toAddress()][tokenId];
    }

    /**
     * @notice Check given token and owner have any auction
     * @param nftAddress NFT address
     * @param tokenId Token identifier
     * @return bool
     */
    function hasAuction(NFTAddress nftAddress, uint256 tokenId) public view returns (bool) {
        return _auctionExists(getAuction(nftAddress, tokenId));
    }

    /**
     * @notice Check given token and owner have any bid
     * @param nftAddress NFT address
     * @param tokenId Token identifier
     * @return bool
     */
    function hasHighestBid(NFTAddress nftAddress, uint256 tokenId) public view returns (bool) {
        return _highestBidExists(getHighestBid(nftAddress, tokenId));
    }

    /**
     * @notice Check given token and owner have any listing
     * @param nftAddress NFT address
     * @param tokenId Token identifier
     * @return bool
     */
    function hasListing(NFTAddress nftAddress, uint256 tokenId) public view returns (bool) {
        return _listingExists(getListing(nftAddress, tokenId));
    }

    /**
     * @notice Check given token and offeror have any offer
     * @param nftAddress NFT address
     * @param tokenId Token identifier
     * @param offeror offeror address
     * @return bool
     */
    function hasOffer(NFTAddress nftAddress, uint256 tokenId, address offeror) public view returns (bool) {
        return _offerExists(getOffer(nftAddress, tokenId, offeror));
    }

    ////////////////////////////
    /// Internal and Private ///
    ////////////////////////////

    /**
     * @notice Validate nft token interface
     * @param nftAddress NFT instance
     */
    function _validateTokenInterface(NFTAddress nftAddress) internal {
        require(nftAddress.isERC721(), 'ERC721Marketplace: NFT not ERC721');
    }

    /**
     * @notice Successfully finish an auction
     * @param nftAddress NFT address
     * @param tokenId Token identifier
     * @param auction Auction to finish
     * @param highestBid Auction highest bid
     */
    function _finishAuctionSuccessFully(
        NFTAddress nftAddress,
        uint256 tokenId,
        Auction memory auction,
        HighestBid memory highestBid
    ) internal {
        _deleteAuction(nftAddress, tokenId);
        _deleteHighestBid(nftAddress, tokenId);

        uint256 finalAmount = highestBid.bidAmount - _calculateAndTakeAuctionFee(auction, highestBid);
        finalAmount -= _calculateAndTakeRoyaltyFee(nftAddress, tokenId, auction.paymentToken, finalAmount);

        if (finalAmount > 0) {
            _sendPayTokenAmount(auction.paymentToken, auction.owner, finalAmount);
        }

        nftAddress.toERC721().safeTransferFrom(
            address(this), highestBid.bidder, tokenId, new bytes(0)
        );

        emit ERC721AuctionFinished(
            auction.owner,
            nftAddress.toAddress(),
            tokenId,
            highestBid.bidder,
            auction.paymentToken,
            highestBid.bidAmount
        );
    }

    /**
     * @notice Create new auction and transfer token
     * @param nftAddress NFT address
     * @param tokenId Token identifier
     * @param owner Token owner
     * @param paymentToken Payment token that will be used for auction
     * @param reservePrice NFT address
     * @param startTime NFT address
     * @param endTime NFT address
     * @param isMinBidReservePrice NFT address
     */
    function _createAuctionAndTransferToken(
        NFTAddress nftAddress,
        uint256 tokenId,
        address owner,
        address paymentToken,
        uint256 reservePrice,
        uint256 startTime,
        uint256 endTime,
        bool isMinBidReservePrice
    ) internal {
        _auctions[nftAddress.toAddress()][tokenId] = Auction({
            owner: owner,
            paymentToken: paymentToken,
            isMinBidReservePrice: isMinBidReservePrice,
            reservePrice: reservePrice,
            startTime: startTime,
            endTime: endTime
        });

        // transfer token to be held in escrow
        nftAddress.toERC721().safeTransferFrom(owner, address(this), tokenId, new bytes(0));
    }

    /**
     * @notice Delete auction and transfer token
     * @param nftAddress NFT address
     * @param auction Auction to delete
     * @param tokenId Token identifier
     */
    function _deleteAuctionAndTransferToken(NFTAddress nftAddress, Auction memory auction, uint256 tokenId) internal {
        address owner = auction.owner;

        _deleteAuction(nftAddress, tokenId);

        // transfer token back to owner
        nftAddress.toERC721().safeTransferFrom(address(this), owner, tokenId, new bytes(0));
    }

    /**
     * @notice Delete auction
     * @param nftAddress NFT address
     * @param tokenId Token identifier
     */
    function _deleteAuction(NFTAddress nftAddress, uint256 tokenId) internal {
        delete _auctions[nftAddress.toAddress()][tokenId];
    }

    /**
     * @notice Delete listing
     * @param nftAddress NFT address
     * @param tokenId Token identifier
     */
    function _deleteListing(NFTAddress nftAddress, uint256 tokenId) internal {
        delete _listings[nftAddress.toAddress()][tokenId];
    }

    /**
     * @notice Delete highest bid
     * @param nftAddress NFT address
     * @param tokenId Token identifier
     */
    function _deleteHighestBid(NFTAddress nftAddress, uint256 tokenId) internal {
        delete _highestBids[nftAddress.toAddress()][tokenId];
    }

    /**
     * @notice Delete offer
     * @param nftAddress NFT address
     * @param tokenId Token identifier
     * @param offeror Offeror address
     */
    function _deleteOffer(NFTAddress nftAddress, uint256 tokenId, address offeror) internal {
        delete _offers[nftAddress.toAddress()][tokenId][offeror];
    }

    /**
     * @notice Get validated finished auction and highest bid
     * @param nftAddress NFT address
     * @param tokenId Token identifier
     */
    function _getValidatedFinishedAuctionAndHighestBid(
        NFTAddress nftAddress,
        uint256 tokenId
    ) internal returns (Auction memory, HighestBid memory) {
        Auction memory auction = getAuction(nftAddress, tokenId);

        _validateAuctionExists(auction);

        _validateAuctionEnded(auction);

        HighestBid memory highestBid = getHighestBid(nftAddress, tokenId);

        _validateHighestBidExists(highestBid);

        return (auction, highestBid);
    }

    /**
     * @notice Create bid and transfer pay token amount
     * @param nftAddress NFT address
     * @param paymentToken Payment token
     * @param tokenId Token identifier
     * @param bidder Bid owner
     * @param bidAmount Bid amount
     */
    function _createBidAndTransferPayTokenAmount(
        NFTAddress nftAddress,
        address paymentToken,
        uint256 tokenId,
        address bidder,
        uint256 bidAmount
    ) internal {
        _highestBids[nftAddress.toAddress()][tokenId] = HighestBid({
            bidder: bidder,
            bidAmount: bidAmount,
            time: _getNow()
        });

        _receivePayTokenAmount(paymentToken, bidder, bidAmount);
    }
}