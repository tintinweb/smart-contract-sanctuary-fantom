// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC721.sol";

contract Migrator {
    address public constant LOCK_ADDRESS = 0x0A1C40033987Aa471eE19f5CF503EB2a7Bbc277a;
    mapping (uint256 => uint256) public oldToNewId;
    IERC721 petZoo;
    IERC721 th;
    address public _minter;
    address public _oldContract;
    address public _newContract;


    constructor (address minter, address oldContract, address newContract) {
        oldToNewId[2527] = 1;
        oldToNewId[2577] = 2;
        oldToNewId[2603] = 3;
        oldToNewId[2605] = 4;
        oldToNewId[2628] = 5;
        oldToNewId[2629] = 6;
        oldToNewId[2630] = 7;
        oldToNewId[2632] = 8;
        oldToNewId[2717] = 9;
        oldToNewId[2719] = 10;
        oldToNewId[2721] = 11;
        oldToNewId[2724] = 12;
        oldToNewId[2726] = 13;
        oldToNewId[2815] = 14;
        oldToNewId[2816] = 15;
        oldToNewId[2817] = 16;
        oldToNewId[2818] = 17;
        oldToNewId[2819] = 18;
        oldToNewId[2829] = 19;
        oldToNewId[2830] = 20;
        oldToNewId[2831] = 21;
        oldToNewId[2832] = 22;
        oldToNewId[2833] = 23;
        oldToNewId[2929] = 24;
        oldToNewId[2930] = 25;
        oldToNewId[2955] = 26;
        oldToNewId[2956] = 27;
        oldToNewId[2962] = 29;
        oldToNewId[2963] = 30;
        oldToNewId[2964] = 28;
        oldToNewId[3263] = 31;
        oldToNewId[3264] = 32;
        oldToNewId[3265] = 33;
        oldToNewId[3266] = 34;
        oldToNewId[3267] = 35;
        oldToNewId[3268] = 36;
        oldToNewId[3269] = 37;
        oldToNewId[3878] = 38;
        oldToNewId[3937] = 39;
        oldToNewId[3938] = 40;
        oldToNewId[3940] = 41;
        oldToNewId[3942] = 42;
        oldToNewId[3944] = 43;
        oldToNewId[3945] = 44;
        oldToNewId[3946] = 46;
        oldToNewId[3947] = 47;
        oldToNewId[3948] = 48;
        oldToNewId[3949] = 49;
        oldToNewId[3950] = 50;
        oldToNewId[3954] = 51;
        oldToNewId[3955] = 53;
        oldToNewId[3956] = 54;
        oldToNewId[3957] = 55;
        oldToNewId[3958] = 45;
        oldToNewId[4190] = 56;
        oldToNewId[4239] = 57;
        oldToNewId[4844] = 52;
        oldToNewId[5636] = 58;
        oldToNewId[5637] = 59;
        oldToNewId[6382] = 60;
        oldToNewId[6383] = 61;
        oldToNewId[6384] = 62;
        oldToNewId[7012] = 63;
        oldToNewId[7017] = 64;
        oldToNewId[7019] = 65;
        oldToNewId[7268] = 66;
        oldToNewId[7669] = 67;
        oldToNewId[7678] = 68;
        oldToNewId[7680] = 69;
        oldToNewId[8510] = 70;
        oldToNewId[8512] = 71;
        oldToNewId[8513] = 72;
        oldToNewId[8514] = 73;
        oldToNewId[8516] = 74;
        oldToNewId[8705] = 75;
        oldToNewId[8706] = 76;
        oldToNewId[8707] = 77;
        oldToNewId[8709] = 78;
        oldToNewId[8720] = 79;
        oldToNewId[8764] = 80;
        oldToNewId[8985] = 81;
        oldToNewId[8986] = 82;
        oldToNewId[8987] = 83;
        oldToNewId[9162] = 84;
        oldToNewId[9163] = 85;
        oldToNewId[9308] = 86;
        oldToNewId[9309] = 87;
        oldToNewId[9310] = 88;
        oldToNewId[9311] = 89;
        oldToNewId[9312] = 90;
        oldToNewId[9426] = 91;
        oldToNewId[9427] = 92;




        _oldContract = oldContract;
        _newContract = newContract;
        petZoo = IERC721(_oldContract);
        th = IERC721(_newContract);
        _minter = minter;
    }

    function migrate(uint256 tokenId) external {
        require(oldToNewId[tokenId] > 0, "Migrator: This token is not on the list"); // make sure mapping exists
        th.safeTransferFrom(_minter, msg.sender, oldToNewId[tokenId]);
        petZoo.safeTransferFrom(msg.sender, LOCK_ADDRESS, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC165.sol";

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

// SPDX-License-Identifier: MIT

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