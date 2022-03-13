/**
 *Submitted for verification at FtmScan.com on 2022-03-13
*/

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/interfaces/INft.sol

pragma solidity ^0.8.0;



interface INft is IERC721, IERC721Enumerable {
    function setNftMetadata(
        string memory _baseTokenUri,
        uint256 _mintPrice,
        uint256 _maxMintSupply,
        address _paymentSplitterContractAddress,
        address _burnerContractAddress,
        bool _mintingEnabled,
        bool _whitelistMintingEnabled
    ) external;

    function mint(uint256 amount) external;

    function claimFreeMints(uint256 amount) external;

    function mintExtra(address recievingAddress, uint256 tokenId) external;

    function setWhitelistAddress(address userAddress, bool isWhitelisted)
        external;

    function setFreeMintsForAddress(address userAddress, uint256 amount)
        external;
}

// File: contracts/interfaces/IExpansionSetSpookyBears.sol

pragma solidity ^0.8.0;



/// @title Interface for ExpansionSetSpookyBears.
interface IExpansionSetSpookyBears is IERC721, IERC721Enumerable {
    /// @dev Modifies internal data.
    /// @param baseTokenUri the NFT metadata URI.
    function setMetadata(string memory baseTokenUri) external;

    /// @dev Mints an expansion set SpookyBear.
    /// @param userAddress the address to mint for.
    /// @param tokenId the token ID to mint.
    function mint(address userAddress, uint256 tokenId)
        external
        returns (uint256);
}

// File: contracts/interfaces/ISpookyBearsReceipt.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



/// @title Interface for SpookyBearsReceipts.
interface ISpookyBearsReceipt is IERC721, IERC721Enumerable {
    /// @dev Mints a receipt.
    /// @param userAddress the address to mint for.
    function mint(address userAddress) external returns (uint256);

    /// @dev Burns a receipt.
    /// @param tokenId the SpookyBearsReceipt token ID to burn.
    function burn(uint256 tokenId) external;
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/bases/Pausible.sol

pragma solidity ^0.8.0;


/// @title Pusible base contract.
/// @dev Enables a contract's function to be paused.
contract Pausible is Ownable {
    /// @dev If the contract is paused or not.
    bool internal _paused = false;

    /// @dev Modifier that ensures a function is only callable when unpaused.
    modifier onlyUnpaused() {
        require(!_paused, "Error: The contract has been paused.");
        _;
    }

    /// @dev Pauses contract.
    function pause() public onlyOwner {
        _paused = true;
    }

    /// @dev Unpauses contract.
    function unpause() public onlyOwner {
        _paused = false;
    }
}

// File: contracts/applications/Ritual.sol

pragma solidity ^0.8.0;






/// @title The SpookyBearsRitual Contract.
/// @dev Used to manage the staking / unstaking of SBEARS for The Ritual.
/// Contract Address:
contract Ritual is Ownable, Pausible {
    IERC721 public currentGenSbears;
    INft public ench;
    IExpansionSetSpookyBears public nextGenSbears;
    ISpookyBearsReceipt public rsSbears;
    address public burnerAddress;

    /// @dev Map of (rsSBEARS ID => completed at time (seconds since epoch)).
    mapping(uint256 => uint256) public completedAt;

    /// @dev Map of (rsSBEARS ID => list of staked SBEARS IDs).
    mapping(uint256 => uint256) public sbearsIds;

    constructor(
        address _sbearsAddress,
        address _enchAddress,
        address _rsSbearsAddress,
        address _esSbearsAddress,
        address _burnerAddress
    ) {
        setMetadata(
            _sbearsAddress,
            _enchAddress,
            _rsSbearsAddress,
            _esSbearsAddress,
            _burnerAddress
        );
    }

    function setMetadata(
        address _sbearsAddress,
        address _enchAddress,
        address _rsSbearsAddress,
        address _esSbearsAddress,
        address _burnerAddress
    ) public onlyOwner {
        currentGenSbears = IERC721(_sbearsAddress);
        rsSbears = ISpookyBearsReceipt(_rsSbearsAddress);
        nextGenSbears = IExpansionSetSpookyBears(_esSbearsAddress);
        ench = INft(_enchAddress);
        burnerAddress = _burnerAddress;
    }

    function stake(uint256 enchId, uint256 currentGenSbearsId)
        public
        onlyUnpaused
    {
        require(
            currentGenSbearsId > 0 && currentGenSbearsId <= 4002,
            "Invaid SBEARS ID"
        );

        // receive current gen bear
        currentGenSbears.transferFrom(
            msg.sender,
            address(this),
            currentGenSbearsId
        );

        // burn ench
        ench.transferFrom(msg.sender, address(burnerAddress), enchId);

        // send an rsSBEARS as an receipt
        uint256 rsSbearsId = rsSbears.mint(msg.sender);

        // calculate staking time and store info
        completedAt[rsSbearsId] =
            block.timestamp +
            getStakingTime(enchId) *
            1 days;
        sbearsIds[rsSbearsId] = currentGenSbearsId;
    }

    function unstake(uint256 rsSbearsId) public onlyUnpaused {
        // burn rsSbears
        rsSbears.transferFrom(msg.sender, address(this), rsSbearsId);
        rsSbears.burn(rsSbearsId);

        uint256 sbearsId = sbearsIds[rsSbearsId];

        // check if completed
        if (completedAt[rsSbearsId] <= block.timestamp) {
            // burn sbears
            currentGenSbears.transferFrom(
                address(this),
                burnerAddress,
                sbearsId
            );

            // reward
            nextGenSbears.mint(msg.sender, sbearsId);
        } else {
            currentGenSbears.transferFrom(address(this), msg.sender, sbearsId);
        }
    }

    function getStakingTime(uint256 enchId) public pure returns (uint256) {
        uint256 zeroIndexed = enchId - 1;
        uint256 mod = zeroIndexed % 10;
        if (mod == 0) {
            return 3;
        }
        if (mod >= 1 && mod <= 3) {
            return 7;
        }
        return 14;
    }
}