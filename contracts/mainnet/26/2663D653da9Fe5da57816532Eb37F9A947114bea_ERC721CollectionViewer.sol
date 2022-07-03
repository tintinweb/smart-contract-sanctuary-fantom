// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./interfaces/INFTStats.sol";

/**
 * @title ERC721CollectionViewer
 */
contract ERC721CollectionViewer {

    struct Metadata {
        uint256 id;
        string tokenURI;
    }

    struct Stats {
        uint256 id;
        uint256 level;
        uint256 rarity;
        uint256 promotion;
        uint256 awakening;
        uint256 power;
        string tokenURI;
    }

    function getTokenIds(address collection_, address account_) public view returns (uint256[] memory tokenIds) {
        IERC721Enumerable collection = IERC721Enumerable(collection_);
        uint256 balance = IERC721(collection_).balanceOf(account_);
        tokenIds = new uint256[](balance);
        for(uint256 i; i < balance; i++) {
            tokenIds[i] = collection.tokenOfOwnerByIndex(account_, i);
        }
        return tokenIds;
    }

    function getTokenURIs(address collection_, address account_, uint256[] memory tokenIds_) external view returns (string[] memory tokenURIs) {
        uint256[] memory tokenIds;
        if(tokenIds_.length > 0) {
            tokenIds = tokenIds_;
        } else {
            tokenIds = getTokenIds(collection_, account_);
        }
        tokenURIs = new string[](tokenIds.length);
        for(uint256 i; i < tokenIds.length; i++) {
            tokenURIs[i] = IERC721Metadata(collection_).tokenURI(tokenIds[i]);
        }
        return tokenURIs;
    }

    function getMetadatas(address collection_, address account_, uint256[] memory tokenIds_) external view returns(Metadata[] memory metadatas) {
        uint256[] memory tokenIds;
        if(tokenIds_.length > 0) {
            tokenIds = tokenIds_;
        } else {
            tokenIds = getTokenIds(collection_, account_);
        }

        metadatas = new Metadata[](tokenIds.length);
        for(uint256 i; i < tokenIds.length; i++) {
            metadatas[i] = Metadata({
                id: tokenIds[i],
                tokenURI: IERC721Metadata(collection_).tokenURI(tokenIds[i])
            });
        }
        return metadatas;
    }

    function getStats(address collection_, address account_, uint256[] memory tokenIds_) external view returns(Stats[] memory stats) {
        uint256[] memory tokenIds;
        if(tokenIds_.length > 0) {
            tokenIds = tokenIds_;
        } else {
            tokenIds = getTokenIds(collection_, account_);
        }
        stats = new Stats[](tokenIds.length);
        for(uint256 i; i < tokenIds.length; i++) {
            NFTStatsLib.Stats memory nftStats = INFTStats(collection_).getStats(tokenIds[i]);
            stats[i] = Stats({
                id: tokenIds[i],
                level: uint256(nftStats.level),
                rarity: uint256(nftStats.rarity),
                promotion: uint256(nftStats.promotion),
                awakening: uint256(nftStats.awakening),
                power: uint256(nftStats.power),
                tokenURI: IERC721Metadata(collection_).tokenURI(tokenIds[i])
            });
        }
        return stats;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library NFTStatsLib {
    struct Stats {
        uint32 level;
        uint32 rarity;
        uint32 promotion;
        uint32 awakening;
        uint256 power;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../lib/NFTStatsLib.sol";
import "./INFTAwakening.sol";
import "./INFTLevel.sol";
import "./INFTPower.sol";
import "./INFTPromotion.sol";
import "./INFTRarity.sol";

interface INFTStats is INFTAwakening, INFTLevel, INFTPower, INFTPromotion, INFTRarity {
    function getStats(uint256 tokenId) external view returns (NFTStatsLib.Stats memory stats);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface INFTRarity {
    function getRarity(uint256 tokenId) external view returns (uint32 rarity);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface INFTPromotion {
    function getPromotion(uint256 tokenId) external view returns (uint32 promotion);
    function setPromotion(uint256 tokenId, uint32 promotion) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface INFTPower {
    function getPower(uint256 tokenId) external view returns (uint256 power);
    function getUserPower(address account) external view returns (uint256 power);
    function getTotalPower() external view returns (uint256 power);
    function addPower(address account, uint256 tokenId, uint256 power) external;
    function removePower(address account, uint256 tokenId, uint256 power) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface INFTLevel {
    function getLevel(uint256 tokenId) external view returns (uint32 level);
    function setLevel(uint256 tokenId, uint32 level) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface INFTAwakening {
    function getAwakening(uint256 tokenId) external view returns (uint32 awakening);
    function setAwakening(uint256 tokenId, uint32 awakening) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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