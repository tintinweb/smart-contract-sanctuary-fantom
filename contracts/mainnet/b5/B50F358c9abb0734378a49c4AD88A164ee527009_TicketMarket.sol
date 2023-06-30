// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITicketMarket {
	function createListing(address nftAddress, uint256 tokenId, uint256 price) external;

	function createListingForSeller(address seller, address nftAddress, uint256 tokenId, uint256 price) external;

	function isNftListed(address nftAddress, uint256 tokenId) external view returns (bool);
}

contract TicketMarket is ITicketMarket {
	struct Listing {
		uint256 price;
		address seller;
	}

	mapping(address => mapping(uint256 => Listing)) public listings;

	modifier isNFTOwner(address nftAddress, uint256 tokenId) {
		require(IERC721(nftAddress).ownerOf(tokenId) == msg.sender, "TicketMarket: Not the owner");
		_;
	}

	modifier isAddressNFTOwner(
		address owner,
		address nftAddress,
		uint256 tokenId
	) {
		require(IERC721(nftAddress).ownerOf(tokenId) == owner, "TicketMarket: Not the owner");
		_;
	}

	modifier isNotListed(address nftAddress, uint256 tokenId) {
		require(listings[nftAddress][tokenId].price == 0, "TicketMarket: Already listed");
		_;
	}

	modifier isListed(address nftAddress, uint256 tokenId) {
		require(listings[nftAddress][tokenId].price > 0, "TicketMarket: Not listed");
		_;
	}

	event ListingCreated(address nftAddress, uint256 tokenId, uint256 price, address seller);

	event ListingCanceled(address nftAddress, uint256 tokenId, address seller);

	event ListingUpdated(address nftAddress, uint256 tokenId, uint256 newPrice, address seller);

	event ListingPurchased(address nftAddress, uint256 tokenId, address seller, address buyer);

	function createListing(
		address nftAddress,
		uint256 tokenId,
		uint256 price
	) external isNotListed(nftAddress, tokenId) isNFTOwner(nftAddress, tokenId) {
		require(price > 0, "TicketMarket: Price must be > 0");
		IERC721 nftContract = IERC721(nftAddress);
		require(
			nftContract.isApprovedForAll(msg.sender, address(this)) ||
				nftContract.getApproved(tokenId) == address(this),
			"TicketMarket: No approval for NFT"
		);
		listings[nftAddress][tokenId] = Listing({price: price, seller: msg.sender});

		emit ListingCreated(nftAddress, tokenId, price, msg.sender);
	}

	function createListingForSeller(
		address seller,
		address nftAddress,
		uint256 tokenId,
		uint256 price
	) public isNotListed(nftAddress, tokenId) isAddressNFTOwner(seller, nftAddress, tokenId) {
		require(price > 0, "TicketMarket: Price must be > 0");
		IERC721 nftContract = IERC721(nftAddress);
		require(
			nftContract.isApprovedForAll(seller, address(this)) || nftContract.getApproved(tokenId) == address(this),
			"TicketMarket: No approval for NFT"
		);
		listings[nftAddress][tokenId] = Listing({price: price, seller: seller});

		emit ListingCreated(nftAddress, tokenId, price, seller);
	}

	function cancelListing(
		address nftAddress,
		uint256 tokenId
	) external isListed(nftAddress, tokenId) isNFTOwner(nftAddress, tokenId) {
		delete listings[nftAddress][tokenId];
		emit ListingCanceled(nftAddress, tokenId, msg.sender);
	}

	function updateListing(
		address nftAddress,
		uint256 tokenId,
		uint256 newPrice
	) external isListed(nftAddress, tokenId) isNFTOwner(nftAddress, tokenId) {
		require(newPrice > 0, "TicketMarket: Price must be > 0");
		listings[nftAddress][tokenId].price = newPrice;
		emit ListingUpdated(nftAddress, tokenId, newPrice, msg.sender);
	}

	function purchaseListing(address nftAddress, uint256 tokenId) external payable isListed(nftAddress, tokenId) {
		Listing memory listing = listings[nftAddress][tokenId];
		require(msg.value == listing.price, "TicketMarket: Incorrect ETH supplied");

		delete listings[nftAddress][tokenId];

		IERC721(nftAddress).safeTransferFrom(listing.seller, msg.sender, tokenId);
		(bool sent, ) = payable(listing.seller).call{value: msg.value}("");
		require(sent, "Failed to transfer eth");

		emit ListingPurchased(nftAddress, tokenId, listing.seller, msg.sender);
	}

	function isNftListed(address nftAddress, uint256 tokenId) public view returns (bool) {
		return listings[nftAddress][tokenId].price > 0;
	}
}