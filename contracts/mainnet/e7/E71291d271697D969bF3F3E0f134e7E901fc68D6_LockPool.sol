/**
 *Submitted for verification at FtmScan.com on 2022-04-27
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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;




contract LockPool is ERC721Holder {
    struct LockingInfo {
        uint256 lockTime;
        uint256 index;
        string username;                //  Username on Discord
        uint256[] tokenIDs;             //  A list of `tokenID` is currently locked
    }

    IEPLManagement public gov;
    IERC721 public token;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    uint256 public start;  
    uint256 public end;    

    mapping(address => LockingInfo) private locked;
    address[] public users;

    event Locked(address indexed user);
    event Released(address indexed user, uint256[] tokenIDs);

    modifier inService() {
        require(address(gov) != address(0), "Out of Service");
        _;
    }

    modifier lockable() {
        require(block.timestamp >= start, "Pool not started yet");
        _;
    }

    modifier claimable() {
         require(block.timestamp >= end, "Not yet ready");
        _;
    }

    modifier onlyManager() {
        require(
            gov.hasRole(MANAGER_ROLE, msg.sender), "Caller is not Manager"
        );
        _;
    }

    constructor(address _gov, address _token, uint256 _start, uint256 _end) {
        require(_gov != address(0), "Set zero address");

        gov = IEPLManagement(_gov);
        token = IERC721(_token);
        start = _start;
        end = _end;
    }

    /**
       	@notice Update Address of EPLManagement contract
       	@dev  Caller must have ADMIN_ROLE
		@param	_gov				Address of EPLManagement contract (or address(0))
		Note: When `_gov = address(0)`, Rental contract is deprecated
    */
	function setGOV(address _gov) external onlyManager {
		gov = IEPLManagement(_gov);
	}

    /**
       	@notice Update Lock Pool information
       	@dev  Caller must have MANAGER_ROLE
		@param	_token				Address of NFT contract
        @param	_start				Starting time that allows Users to lock their tokens
        @param	_end				Ending time that allows Users to claim back their tokens
    */
	function setLockPool(address _token, uint256 _start, uint256 _end) external onlyManager {
        require(_token != address(0), "Set zero address");
        require( 
            block.timestamp <= _start && _start < _end, "Invalid schedule"
        );

		token = IERC721(_token);
        start = _start;
        end = _end;
	}

    /**
       	@notice Request locking tokens
       	@dev  Caller can be ANY
		@param	_username			Username log-in on Discord
        @param	_tokenIDs		    A list of `tokenID` that requests to be locked
        Note: 
            - Once locking, User is unable to alter information. 
            - Tokens are claimable after `end`
    */
    function lock(string calldata _username, uint256[] calldata _tokenIDs) external inService lockable {
        address _owner = msg.sender;
        require(
            locked[_owner].lockTime == 0, "Address already in use"
        );

        uint256 _size = _tokenIDs.length;
        require(
            _size > 0 && _size <= 10, "Invalid locking amount"
        );

        uint256 _id;
        for (uint256 i; i < _size; i++) {
            _id = _tokenIDs[i];
            require(
                token.ownerOf(_id) == _owner, "TokenID not owned"
            );

            token.safeTransferFrom(_owner, address(this), _id);
        }
        locked[_owner] = LockingInfo({
            lockTime: block.timestamp,
            index: users.length,
            username: _username,
            tokenIDs: _tokenIDs
        });
        users.push(_owner);

        emit Locked(_owner);
    }

    /**
       	@notice Request unlocking tokens
       	@dev  Caller can be ANY
        Note: 
            - Users claim back their tokens that have been locked before 
            - Tokens are claimable after `end`
    */
    function claim() external claimable {
        address _owner = msg.sender;
        uint256[] memory _ids = locked[_owner].tokenIDs;
        uint256 _size = _ids.length;
        require(_size != 0, "Not recorded or claimed already");

        for(uint256 i; i < _size; i++)
            token.safeTransferFrom(address(this), _owner, _ids[i]);

        _removeLockingInfo(_owner);

        emit Released(_owner, _ids);
    }

    function _removeLockingInfo(address _owner) private {
        uint256 _currentIdx = locked[_owner].index;
        address _lastUser = users[users.length - 1];

        locked[_lastUser].index = _currentIdx;
        users[_currentIdx] = _lastUser;
        delete locked[_owner];
        users.pop();
    }

    /**
       	@notice Release locking tokens
       	@dev  Caller must have MANAGER_ROLE
        Note: 
            - This method should ONLY be used in the case that a new locking event has been set
            but some `tokenIDs`, from previous locking event, have not yet been claimed by Users
    */
    function release(address _token, address _user) external onlyManager {
        uint256[] memory _ids = locked[_user].tokenIDs;
        uint256 _size = _ids.length;
        require(_size != 0, "Not recorded or claimed already");

        for(uint256 i; i < _size; i++)
            IERC721(_token).safeTransferFrom(address(this), _user, _ids[i]);
        
        _removeLockingInfo(_user);

        emit Released(_user, _ids);
    }

    /**
       	@notice Query locking info of one `_account`
       	@dev  Caller can be ANY
		@param	_account            Address of account that needs to get the info
    */
    function getLockingInfo(address _account) external view returns (LockingInfo memory) {
        return locked[_account];
    }

    /**
       	@notice Query total number of locking users
       	@dev  Caller can be ANY
    */
    function totalLocking() external view returns (uint256) {
        return users.length;
    }
}