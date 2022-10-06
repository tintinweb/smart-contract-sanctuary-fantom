// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

pragma solidity ^0.8.0;

interface IAnyCall {
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    ) external;

    function executor() external view returns (address executor);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function mint(address to, uint256 amount) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IExecutor {
    function context()
        external
        returns (
            address from,
            uint256 fromChainID,
            uint256 nonce
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFeeDistributor {
    function claim_many(uint256[] memory _tokenIds) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVotingEscrow {
    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    function create_lock_for(
        uint256 _value,
        uint256 _lock_duration,
        address _to
    ) external returns (uint256);

    function locked(uint256 tokenId) external view returns (LockedBalance memory lock);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IFeeDistributor.sol";
import "./interfaces/IAnyCall.sol";
import "./interfaces/IExecutor.sol";
import "./interfaces/IERC20.sol";

struct MigrationLock {
    uint256 amount;
    uint256 duration;
}

contract veMigrationSrc is Ownable, ReentrancyGuard {
    address public immutable anycallExecutor;
    address public immutable anyCall;
    address public immutable veIB;
    address public immutable receiver;
    uint256 public immutable srcChainId;
    uint256 public immutable destChainId;
    address[] public feeDistributors;
    uint256 public constant PAY_FEE_ON_DEST_CHAIN = 0; // PAID_ON_DEST = 0; PAID_ON_SRC = 2;
    address public constant nullAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant WEEK = 1 weeks;

    /// @notice emitted when migration is initiated on source chain
    /// @param user user address
    /// @param tokenIds tokenIds of the user
    event MigrationInitiated(address user, uint256[] tokenIds);

    /// @notice emitted when migration has failed on destination chain
    /// @param user user address
    /// @param oldTokenIds old tokenIds of the user
    event MigrationFailed(address user, uint256[] oldTokenIds);

    modifier onlyExecutor() {
        require(msg.sender == anycallExecutor, "Only executor can call this function");
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this), "Only this contract can call this function");
        _;
    }

    /// @notice Contract constructor, can be deployed on both the source chain and the destination chainz
    /// @param _anyCall anyCall address
    /// @param _veIB veIB address
    /// @param _feeDistributors feeDistributors address, only needed when deployed on source chain, set to [] when deployed on destination chain
    constructor(
        address _anyCall,
        address _veIB,
        address _receiver,
        uint256 _srcChainId,
        uint256 _destChainId,
        address[] memory _feeDistributors
    ) {
        require(_anyCall != address(0), "anyCall address cannot be 0");
        require(_veIB != address(0), "veIB address cannot be 0");
        require(_receiver != address(0), "receiver address cannot be 0");

        anyCall = _anyCall;
        anycallExecutor = IAnyCall(_anyCall).executor();
        veIB = _veIB;
        receiver = _receiver;
        feeDistributors = _feeDistributors;
        srcChainId = _srcChainId;
        destChainId = _destChainId;
    }

    /// @notice function to initiate migration on source chain, it help users claim rewards from fee_distibutors
    ///         and then burn the veIB NFTs before initiating the anyCall to destination chain
    /// @param tokenIds array of tokenIds to migrate
    function migrate(uint256[] calldata tokenIds) external nonReentrant {
        for (uint256 i = 0; i < feeDistributors.length; i++) {
            IFeeDistributor(feeDistributors[i]).claim_many(tokenIds);
        }
        MigrationLock[] memory migrationLocks = new MigrationLock[](tokenIds.length);
        uint256 oneWeekFromNow = block.timestamp + WEEK;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(IVotingEscrow(veIB).ownerOf(tokenIds[i]) == msg.sender, "You are not the owner of this token");
            IVotingEscrow.LockedBalance memory lockBalance = IVotingEscrow(veIB).locked(tokenIds[i]);
            uint256 duration = lockBalance.end >= oneWeekFromNow ? lockBalance.end - block.timestamp : WEEK;
            migrationLocks[i] = MigrationLock(uint256(uint128(lockBalance.amount)), duration);
            IVotingEscrow(veIB).transferFrom(msg.sender, nullAddress, tokenIds[i]);
        }
        bytes memory data = abi.encode(msg.sender, tokenIds, migrationLocks);
        // set fallBack address as the current address to log failures, if any
        IAnyCall(anyCall).anyCall(receiver, data, address(this), destChainId, PAY_FEE_ON_DEST_CHAIN);
        emit MigrationInitiated(msg.sender, tokenIds);
    }

    /// @notice function only callable by anyCall executor, if anyCall fails on OP, this function will be called by anyCall executor to log the failure
    /// @param data abi encoded data of the anyCall
    /// @return success true if migration is successful
    /// @return result return message
    function anyExecute(bytes calldata data) external onlyExecutor nonReentrant returns (bool success, bytes memory result) {
        (address callFrom, uint256 fromChainID, ) = IExecutor(anycallExecutor).context();
        bool isValidSource = callFrom == address(this) && fromChainID == srcChainId;
        bool isValidFunctionSig = bytes4(data[:4]) == this.anyFallback.selector;
        if (!isValidSource || !isValidFunctionSig) {
            return (false, "invalid souce or function selector");
        }
        // when migration fails on destination chain, log failure on source chain
        (address _initialCallTo, bytes memory _initialCallData) = abi.decode(data[4:], (address, bytes));
        this.anyFallback(_initialCallTo, _initialCallData);
        return (true, "");
    }

    /// @notice function to log failure on source chain, when the migration call on the destination chain is unsuccessful
    /// @param _initialCallTo initial call to address on the destination chain
    /// @param _initialCallData initial calldata sent to the destination chain
    function anyFallback(address _initialCallTo, bytes calldata _initialCallData) external onlySelf {
        require(_initialCallTo == receiver, "Incorrect receiver address");
        (address user, uint256[] memory oldTokenIds, ) = abi.decode(_initialCallData, (address, uint256[], IVotingEscrow.LockedBalance[]));
        emit MigrationFailed(user, oldTokenIds);
    }

    function getTokenIds(address user) external view returns (uint256[] memory) {
        uint256 balance = IERC721Enumerable(veIB).balanceOf(user);
        uint256[] memory ids = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            ids[i] = IERC721Enumerable(veIB).tokenOfOwnerByIndex(user, i);
        }
        return ids;
    }
}