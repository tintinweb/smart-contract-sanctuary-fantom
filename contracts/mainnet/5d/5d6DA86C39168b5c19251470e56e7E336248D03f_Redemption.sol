/**
 *Submitted for verification at FtmScan.com on 2022-04-05
*/

// File: contracts/interfaces/IEPLManagement.sol


pragma solidity ^0.8.0;

/**
   @title IEPLManagement contract
   @dev Provide interfaces that allow interaction to EPLManagement contract
*/
interface IEPLManagement {
    function treasury() external view returns (address);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function listOfNFTs(address _nftContr) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: contracts/LockPool.sol


pragma solidity ^0.8.0;





contract Redemption is Context {
	IEPLManagement public gov;

	address public constant BLACK_HOLE = 0x000000000000000000000000000000000000dEaD;
	bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

	mapping(uint256 => bytes32) public roots;
	mapping(uint256 => mapping(address => bool)) public claimed;

	event Redeem(
		address indexed fromContr,
		address indexed toContr,
		address nftHolder,
		address indexed receiver,
		uint256[] burnedIDs,
		uint256[] issuedIDs
	);

	event Drop(
		address indexed token,
		address indexed receiver,
		uint256 indexed eventID,
		uint256 tokenID
	);

	modifier onlyManager() {
        require(
            gov.hasRole(MANAGER_ROLE, _msgSender()), "Caller is not Manager"
        );
        _;
    }

	constructor(address _gov) {
		gov = IEPLManagement(_gov);
	}

	/**
       	@notice Update Address of EPLManagement contract
       	@dev  Caller must have ADMIN_ROLE
		@param	_gov				Address of EPLManagement contract (or address(0))
		Note: When `_gov = address(0)`, Redemption contract is deprecated
    */
	function setGOV(address _gov) external onlyManager {
		gov = IEPLManagement(_gov);
	}

	/**
       	@notice Set Root Hash of the Special Event
       	@dev  Caller must have MANAGER_ROLE
		@param	_eventID			ID of Special Event
		@param 	_root				Root Hash
    */
	function setRoot(uint256 _eventID, bytes32 _root) external onlyManager {
		require(roots[_eventID] == "", "EventID recorded");
		require(_root != "", "Empty Hash");
		roots[_eventID] = _root;
	}

	/**
       	@notice Redeem Ticket/Box (ERC-721) and Transfer minted NFTs to `_receiver`
       	@dev  Caller must have MANAGER_ROLE
		@param	_fromContr				Address of Ticket/Box (ERC-721) contract
		@param	_toContr				Address of NFT contract
		@param	_distributor			Wallet's address that holds NFTs/Heroes
		@param	_receiver				Address of Receiver
		@param	_burnIDs				IDs of Ticket/Box that need to be burned
		@param 	_issueIDs				IDs of NFTs/Heroes that need to be transferred to `_receiver`
    */
	function redeem(
		address _fromContr,
		address _toContr,
		address _distributor,
		address _receiver,
		uint256[] calldata _burnIDs,
		uint256[] calldata _issueIDs
	) external onlyManager {
		uint256 _size = _burnIDs.length;
		require(_size == _issueIDs.length, "Size mismatch");

		IERC721 _from = IERC721(_fromContr);
		IERC721 _to = IERC721(_toContr);
		uint256 _burnId;
		for(uint256 i; i < _size; i++) {
			_burnId = _burnIDs[i];
			require(
				_from.ownerOf(_burnId) == _receiver, "Box/Ticket not owned"
			);
			_from.safeTransferFrom(_receiver, BLACK_HOLE, _burnId);
			_to.safeTransferFrom(_distributor, _receiver, _issueIDs[i]);
		}

		emit Redeem(_fromContr, _toContr, _distributor, _receiver, _burnIDs, _issueIDs);
	}

	/**
       	@notice Claim Air Drop/Special Event
       	@dev  Caller can be ANY
		@param	_eventID				ID of Special Event
		@param	_tokenID				TokenID of item about to transfer to `msg.sender`
		@param	_distributor			Wallet's address that holds NFTs/Heroes
		@param	_token					Address of NFT/Token contract
		@param	_proof					An array of proof
    */
	function claim(
		uint256 _eventID,
		uint256 _tokenID,
		address _distributor,
		address _token,
		bytes32[] calldata _proof
	) external {
		require(address(gov) != address(0), "Out of Service");
		
		address _user = _msgSender();
		bytes32 _root = roots[_eventID];
		require(_root != "", "EventID not recorded");
		require(!claimed[_eventID][_user], "Already claimed");

		claimed[_eventID][_user] = true;
		bytes32 _leaf = keccak256(
			abi.encodePacked(_user, _tokenID, _eventID, _token, _distributor)
		);
		require(
			MerkleProof.verify(_proof, _root, _leaf), "Invalid claim"
		);

		IERC721(_token).safeTransferFrom(_distributor, _user, _tokenID);

		emit Drop(_token, _user, _eventID, _tokenID);
	}
}