// SPDX-License-Identifier: GNU-GPL
pragma solidity >=0.8.0;

import "./interfaces/IAddressLock.sol";
import "./interfaces/IResonate.sol";
import "./interfaces/IERC4626.sol";
import "./interfaces/IERC20Detailed.sol";


import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/** @title Address Lock Proxy. */
contract AddressLockProxy is Ownable, IAddressLock, ERC165 {

    /// IResonate variable
    IResonate public resonate;


    /// Precision for calculating rates
    uint public constant PRECISION = 1 ether;
    /// Whether Resonate is set or not
    bool private _resonateSet;

    string public constant METADATA = "https://revest.mypinata.cloud/ipfs/QmPaJFBaVc3XF8ox8xegZU6C8borsaJhf9WyEnTppqgEYH";

    
    /**
     * @notice Constructor for AddressLockProxy
     */
    constructor() {}

    function isUnlockable(uint fnftId, uint) external view returns (bool) {
        uint residual = resonate.residuals(fnftId);

        if(residual > 0) {
            return true;
        }

        uint index = resonate.fnftIdToIndex(fnftId);
        (,, uint sharesAtDeposit, bytes32 poolId) = resonate.activated(index);
        (,,address vaultAdapter,,uint128 rate, uint128 addInterestRate, uint256 packetSize)= resonate.pools(poolId);

        uint128 expectedReturn = rate + addInterestRate; //1E18
        uint tokensExpectedPerPacket = packetSize * expectedReturn / PRECISION;

       
        uint previewRedemption = IERC4626(vaultAdapter).previewRedeem(sharesAtDeposit / PRECISION);
        uint tokensAccumulatedPerPacket;
        if (previewRedemption < packetSize) {
            return false;
        }

        else {
            tokensAccumulatedPerPacket =  previewRedemption - packetSize;
        }

        return tokensAccumulatedPerPacket >= tokensExpectedPerPacket;
    }

    function getDisplayValues(uint fnftId, uint) external view returns (bytes memory output) {
        
        uint residual = resonate.residuals(fnftId);
        (,, uint sharesAtDeposit, bytes32 poolId) = resonate.activated(fnftId);
        (,, address vaultAdapter,, uint128 rate, uint128 addInterestRate, uint256 packetSize) = resonate.pools(poolId);

        bool unlocked;
        uint128 expectedReturn = rate + addInterestRate; 
        uint tokensExpectedPerPacket = packetSize * expectedReturn / PRECISION;
        uint tokensAccumulatedPerPacket;
        address asset = IERC4626(vaultAdapter).asset();
        if(residual > 0) {
            unlocked = true;
            tokensAccumulatedPerPacket = IERC4626(vaultAdapter).previewRedeem(sharesAtDeposit / PRECISION) - packetSize;
        } else {
            tokensAccumulatedPerPacket = tokensExpectedPerPacket;
        }        
        output = abi.encode(unlocked, expectedReturn, tokensExpectedPerPacket, tokensAccumulatedPerPacket, IERC20Detailed(asset).decimals());
    }
    
    function getMetadata() external pure returns (string memory) {
        return METADATA;
    }

    function needsUpdate() external pure returns (bool) {
        return false;
    }

    function supportsInterface(bytes4 interfaceId) public view override (ERC165, IERC165) returns (bool) {
        return  interfaceId == type(IAddressLock).interfaceId
                || super.supportsInterface(interfaceId);
    }

    function setResonate(address _resonate) external onlyOwner {
        require(!_resonateSet, 'ER031');
        _resonateSet = true;
        resonate = IResonate(_resonate);
    }

    function getAddressRegistry() external view returns (address) {
        return resonate.REGISTRY_ADDRESS();
    }

    ///
    /// Interface-mandated functions
    ///

    function createLock(uint fnftId, uint lockId, bytes memory arguments) external {}
    function updateLock(uint fnftId, uint lockId, bytes memory arguments) external {}
    function setAddressRegistry(address revest) external {}
    
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IRegistryProvider.sol";
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

/**
 * @title Provider interface for Revest FNFTs
 * @dev Address locks MUST be non-upgradeable to be considered for trusted status
 * @author Revest
 */
interface IAddressLock is IERC165, IRegistryProvider {

    /// Creates a lock to the specified lockID
    /// @param fnftId the fnftId to map this lock to. Not recommended for typical locks, as it will break on splitting
    /// @param lockId the lockId to map this lock to. Recommended uint for storing references to lock configurations
    /// @param arguments an abi.encode() bytes array. Allows frontend to encode and pass in an arbitrary set of parameters
    /// @dev creates a lock for the specified lockId. Will be called during the creation process for address locks when the address
    ///      of a contract implementing this interface is passed in as the "trigger" address for minting an address lock. The bytes
    ///      representing any parameters this lock requires are passed through to this method, where abi.decode must be call on them
    function createLock(uint fnftId, uint lockId, bytes memory arguments) external;

    /// Updates a lock at the specified lockId
    /// @param fnftId the fnftId that can map to a lock config stored in implementing contracts. Not recommended, as it will break on splitting
    /// @param lockId the lockId that maps to the lock config which should be updated. Recommended for retrieving references to lock configurations
    /// @param arguments an abi.encode() bytes array. Allows frontend to encode and pass in an arbitrary set of parameters
    /// @dev updates a lock for the specified lockId. Will be called by the frontend from the information section if an update is requested
    ///      can further accept and decode parameters to use in modifying the lock's config or triggering other actions
    ///      such as triggering an on-chain oracle to update
    function updateLock(uint fnftId, uint lockId, bytes memory arguments) external;

    /// Whether or not the lock can be unlocked
    /// @param fnftId the fnftId that can map to a lock config stored in implementing contracts. Not recommended, as it will break on splitting
    /// @param lockId the lockId that maps to the lock config which should be updated. Recommended for retrieving references to lock configurations
    /// @dev this method is called during the unlocking and withdrawal processes by the Revest contract - it is also used by the frontend
    ///      if this method is returning true and someone attempts to unlock or withdraw from an FNFT attached to the requested lock, the request will succeed
    /// @return whether or not this lock may be unlocked
    function isUnlockable(uint fnftId, uint lockId) external view returns (bool);

    /// Provides an encoded bytes arary that represents values this lock wants to display on the info screen
    /// Info to decode these values is provided in the metadata file
    /// @param fnftId the fnftId that can map to a lock config stored in implementing contracts. Not recommended, as it will break on splitting
    /// @param lockId the lockId that maps to the lock config which should be updated. Recommended for retrieving references to lock configurations
    /// @dev used by the frontend to fetch on-chain data on the state of any given lock
    /// @return a bytes array that represents the result of calling abi.encode on values which the developer wants to appear on the frontend
    function getDisplayValues(uint fnftId, uint lockId) external view returns (bytes memory);

    /// Maps to a URL, typically IPFS-based, that contains information on how to encode and decode paramters sent to and from this lock
    /// Please see additional documentation for JSON config info
    /// @dev this method will be called by the frontend only but is crucial to properly implement for proper minting and information workflows
    /// @return a URL to the JSON file containing this lock's metadata schema
    function getMetadata() external view returns (string memory);

    /// Whether or not this lock will need updates and should display the option for them
    /// @dev this will be called by the frontend to determine if update inputs and buttons should be displayed
    /// @return whether or not the locks created by this contract will need updates
    function needsUpdate() external view returns (bool);
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

library Bytes32Conversion {
    function toAddress(bytes32 b32) internal pure returns (address) {
        return address(uint160(bytes20(b32)));
    }
}

interface IResonate {

        // Uses 3 storage slots
    struct PoolConfig {
        address asset; // 20
        address vault; // 20 
        address adapter; // 20
        uint32  lockupPeriod; // 4
        uint128  rate; // 16
        uint128  addInterestRate; //Amount additional (10% on top of the 30%) - If not a bond then just zero // 16
        uint256 packetSize; // 32
    }

    // Uses 1 storage slot
    struct PoolQueue {
        uint64 providerHead;
        uint64 providerTail;
        uint64 consumerHead;
        uint64 consumerTail;
    }

    // Uses 3 storage slot
    struct Order {
        uint256 packetsRemaining;
        uint256 depositedShares;
        bytes32 owner;
    }

    struct ParamPacker {
        Order consumerOrder;
        Order producerOrder;
        bool isProducerNew;
        bool isCrossAsset;
        uint quantityPackets; 
        uint currentExchangeRate;
        PoolConfig pool;
        address adapter;
        bytes32 poolId;
    }

    /// Uses 4 storage slots
    /// Stores information on activated positions
    struct Active {
        // The ID of the associated Principal FNFT
        // Interest FNFT will be this +1
        uint256 principalId; 
        // Set at the time you last claim interest
        // Current state of interest - current shares per asset
        uint256 sharesPerPacket; 
        // Zero measurement point at pool creation
        // Left as zero if Type0
        uint256 startingSharesPerPacket; 
        bytes32 poolId;
    }

    ///
    /// Events
    ///

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event PoolCreated(bytes32 indexed poolId, address indexed asset, address indexed vault, address payoutAsset, uint128 rate, uint128 addInterestRate, uint32 lockupPeriod, uint256 packetSize, bool isFixedTerm, string poolName, address creator);

    event EnqueueProvider(bytes32 indexed poolId, address indexed addr, uint64 indexed position, bool shouldFarm, Order order);
    event EnqueueConsumer(bytes32 indexed poolId, address indexed addr, uint64 indexed position, Order order);

    event DequeueProvider(bytes32 indexed poolId, address indexed dequeuer, address indexed owner, uint64 position, Order order);
    event DequeueConsumer(bytes32 indexed poolId, address indexed dequeuer, address indexed owner, uint64 position, Order order);

    event OracleRegistered(address indexed vaultAsset, address indexed paymentAsset, address indexed oracleDispatch);

    event VaultAdapterRegistered(address indexed underlyingVault, address indexed vaultAdapter, address indexed vaultAsset);

    event CapitalActivated(bytes32 indexed poolId, uint numPackets, uint indexed principalFNFT);
    
    event OrderWithdrawal(bytes32 indexed poolId, uint amountPackets, bool fullyWithdrawn, address owner);

    event FNFTCreation(bytes32 indexed poolId, bool indexed isPrincipal, uint indexed fnftId, uint quantityFNFTs);
    event FNFTRedeemed(bytes32 indexed poolId, bool indexed isPrincipal, uint indexed fnftId, uint quantityFNFTs);

    event FeeCollection(bytes32 indexed poolId, uint amountTokens);

    event InterestClaimed(bytes32 indexed poolId, uint indexed fnftId, address indexed claimer, uint amount);
    event BatchInterestClaimed(bytes32 indexed poolId, uint[] fnftIds, address indexed claimer, uint amountInterest);
    
    event DepositERC20OutputReceiver(address indexed mintTo, address indexed token, uint amountTokens, uint indexed fnftId, bytes extraData);
    event WithdrawERC20OutputReceiver(address indexed caller, address indexed token, uint amountTokens, uint indexed fnftId, bytes extraData);

    function residuals(uint fnftId) external view returns (uint residual);
    function RESONATE_HELPER() external view returns (address resonateHelper);

    function queueMarkers(bytes32 poolId) external view returns (uint64 a, uint64 b, uint64 c, uint64 d);
    function providerQueue(bytes32 poolId, uint256 providerHead) external view returns (uint packetsRemaining, uint depositedShares, bytes32 owner);
    function consumerQueue(bytes32 poolId, uint256 consumerHead) external view returns (uint packetsRemaining, uint depositedShares, bytes32 owner);
    function activated(uint fnftId) external view returns (uint principalId, uint sharesPerPacket, uint startingSharesPerPacket, bytes32 poolId);
    function pools(bytes32 poolId) external view returns (address asset, address vault, address adapter, uint32 lockupPeriod, uint128 rate, uint128 addInterestRate, uint256 packetSize);
    function vaultAdapters(address vault) external view returns (address vaultAdapter);
    function fnftIdToIndex(uint fnftId) external view returns (uint index);
    function REGISTRY_ADDRESS() external view returns (address registry);

    function receiveRevestOutput(
        uint fnftId,
        address,
        address payable owner,
        uint quantity
    ) external;

    function claimInterest(uint fnftId, address recipient) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC4626 is IERC20 {


    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event Deposit(address indexed caller, address indexed owner, uint256 amountUnderlying, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 amountUnderlying,
        uint256 shares
    );

    /// Transactional Functions

    function deposit(uint amountUnderlying, address receiver) external returns (uint shares);

    function mint(uint shares, address receiver) external returns (uint amountUnderlying);

    function withdraw(uint amountUnderlying, address receiver, address owner) external returns (uint shares);

    function redeem(uint shares, address receiver, address owner) external returns (uint amountUnderlying);


    /// View Functions

    function asset() external view returns (address assetTokenAddress);

    // Total assets held within
    function totalAssets() external view returns (uint totalManagedAssets);

    function convertToShares(uint amountUnderlying) external view returns (uint shares);

    function convertToAssets(uint shares) external view returns (uint amountUnderlying);

    function maxDeposit(address receiver) external view returns (uint maxAssets);

    function previewDeposit(uint amountUnderlying) external view returns (uint shares);

    function maxMint(address receiver) external view returns (uint maxShares);

    function previewMint(uint shares) external view returns (uint amountUnderlying);

    function maxWithdraw(address owner) external view returns (uint maxAssets);

    function previewWithdraw(uint amountUnderlying) external view returns (uint shares);

    function maxRedeem(address owner) external view returns (uint maxShares);

    function previewRedeem(uint shares) external view returns (uint amountUnderlying);

    /// IERC20 View Methods

    /**
     * @dev Returns the amount of shares in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of shares owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the remaining number of shares that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Returns the name of the vault shares.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the vault shares.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the vault shares.
     */
    function decimals() external view returns (uint8);

    
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

interface IERC20Detailed {

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

interface IRegistryProvider {
    function setAddressRegistry(address revest) external;

    function getAddressRegistry() external view returns (address);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IERC4626.sol";
import "./interfaces/ISmartWallet.sol";

pragma solidity ^0.8.0;

/// @author RobAnon
/** @title Resonate Smart Wallet. */
contract ResonateSmartWallet is ISmartWallet, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using ERC165Checker for address;

    /// Address for msg.sender
    address public immutable override MASTER;
    /// Resonate address
    address public immutable override RESONATE;
    /// IERC20 Interface ID
    bytes4 public constant IERC20_INTERFACE = type(IERC20).interfaceId;

    uint private constant PRECISION = 1 ether;


    
    constructor(address _resonate) {
        MASTER = msg.sender;
        RESONATE = _resonate;
    }

    /**
     * @dev Throws if called by any account other than master or resonate.
     */
    modifier onlyMaster() {
        require(msg.sender == MASTER || msg.sender == RESONATE, 'E016');
        _;
    }

    
    function reclaimInterestAndResidual(
        address vaultToken, 
        address vaultAdapter,
        address receiver,
        uint amountUnderlying, 
        uint totalShares,
        uint residual
    ) external override onlyMaster nonReentrant returns (uint interest, uint sharesRedeemed) {
        uint shareSum = totalShares + residual;
        if(IERC20(vaultToken).allowance(address(this), vaultAdapter) < shareSum) {
            IERC20(vaultToken).approve(vaultAdapter, type(uint).max);
        }
        IERC4626 vault = IERC4626(vaultAdapter);

        // NB: Point of caution
        uint underlyingShares = vault.previewWithdraw(amountUnderlying);
        
        if(underlyingShares < shareSum) {
            sharesRedeemed = shareSum - underlyingShares;
            interest = vault.redeem(sharesRedeemed, receiver, address(this));
        }
    }

    
    function reclaimPrincipal(
        address vaultToken, 
        address vaultAdapter,
        address receiver,
        uint amountUnderlying, 
        uint totalShares,
        bool leaveResidual
    ) external onlyMaster nonReentrant returns (uint residualShares) {
        if(IERC20(vaultToken).allowance(address(this), vaultAdapter) < totalShares) {
            IERC20(vaultToken).approve(vaultAdapter, type(uint).max);
        }
        IERC4626 vault = IERC4626(vaultAdapter);
        if(leaveResidual) {
            // Handle edge-case where fees have eaten the residual
            uint sharesWithdrawn;
            if(vault.previewWithdraw(amountUnderlying) <= totalShares) {
                // NB: Point of caution
                sharesWithdrawn = vault.withdraw(amountUnderlying, receiver, address(this));
            } else {
                // NB: Edge-case handling for principal that is worth less than its nominal value
                // Only can occur when vaults charge high fees on withdrawals
                sharesWithdrawn = totalShares;
                vault.redeem(sharesWithdrawn, receiver, address(this));
            }
            residualShares = totalShares - sharesWithdrawn;
        } else {
            // Claim everything we can
            vault.redeem(totalShares, receiver, address(this));
        }
    }

    function calculateAndClaimInterest(
        address vaultToken,
        address vaultAdapter,
        address receiver,
        uint amountUnderlying, // size of initial deposit
        uint totalShares
    ) public override onlyMaster nonReentrant returns (uint interest, uint sharesRedeemed) {
        IERC4626 vault = IERC4626(vaultAdapter);
        if(IERC20(vaultToken).allowance(address(this), vaultAdapter) < totalShares) {
            IERC20(vaultToken).approve(vaultAdapter, 0);
            IERC20(vaultToken).approve(vaultAdapter, type(uint).max);
        }

        // NB: Design decision made to create "grace period" 
        // Purchaser will be unable to claim interest until sufficient interest has accrued
        // To cover the Issuer's debt (withdrawal-fee vaults only)
        uint totalSharesOfUnderlying = vault.previewWithdraw(amountUnderlying);

        if(totalShares > totalSharesOfUnderlying) {
            sharesRedeemed = totalShares - totalSharesOfUnderlying;
            interest = vault.redeem(sharesRedeemed, receiver, address(this));
        }
    }

    function redeemShares(
        address vaultToken,
        address vaultAdapter,
        address receiver,
        uint totalShares
    ) external override onlyMaster nonReentrant returns (uint amountUnderlying) {
        IERC4626 vault = IERC4626(vaultAdapter);
        if(IERC20(vaultToken).allowance(address(this), vaultAdapter) < totalShares) {
            IERC20(vaultToken).approve(vaultAdapter, type(uint).max);
        }
        amountUnderlying = vault.redeem(totalShares, receiver, address(this));
    }

    function proxyCall(address token, address vault, address vaultToken, address[] memory targets, uint256[] memory values, bytes[] memory calldatas) external override onlyMaster nonReentrant {
        uint preBalVaultToken = IERC20(vaultToken).balanceOf(address(this));
        uint preBalToken = IERC20(token).balanceOf(address(this));
        uint preVaultBalToken = IERC20(token).balanceOf(vault);
        uint prePreviewRedeem = IERC4626(vaultToken).previewRedeem(PRECISION);
        for (uint256 i = 0; i < targets.length; i++) {
            (bool success, ) = targets[i].call{value: values[i]}(calldatas[i]);
            require(success, "ER022");
        }
        require(IERC20(vaultToken).balanceOf(address(this)) >= preBalVaultToken, "ER019");
        require(IERC20(token).balanceOf(address(this)) >= preBalToken, "ER019");
        require(IERC20(token).balanceOf(vault) >= preVaultBalToken, "ER019");
        require(IERC4626(vaultToken).previewRedeem(PRECISION) >= prePreviewRedeem, 'ER019');
    }

    function withdrawOrDeposit(address vaultToken, address vaultAdapter, uint amount, bool isWithdrawal) external override onlyMaster nonReentrant {
        if(IERC20(vaultToken).allowance(address(this), vaultAdapter) < amount) {
            IERC20(vaultToken).safeApprove(vaultAdapter, 0);
            IERC20(vaultToken).safeApprove(vaultAdapter, type(uint).max);
        }

        IERC4626 vault = IERC4626(vaultAdapter);
        if (isWithdrawal) {
            vault.redeem(amount, address(this), address(this));
        } else {
            vault.deposit(amount, address(this));
        }
    }
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

/// @author RobAnon

interface ISmartWallet {

    function MASTER() external view returns (address master);

    function RESONATE() external view returns (address resonate);

    function calculateAndClaimInterest(
        address vaultToken,
        address vaultAdapter,
        address receiver,
        uint amountUnderlying,
        uint totalShares
    ) external returns (uint interest, uint sharesRedeemed);

    function reclaimPrincipal(
        address vaultToken, 
        address vaultAdapter, 
        address receiver,
        uint amountUnderlying, 
        uint totalShares,
        bool leaveResidual
    ) external returns (uint residual);

    function reclaimInterestAndResidual(
        address vaultToken, 
        address vaultAdapter, 
        address receiver,
        uint amountUnderlying, 
        uint totalShares,
        uint residual
    ) external returns (uint interest, uint sharesRedeemed);

    function redeemShares(
        address vaultToken,
        address vaultAdapter,
        address receiver,
        uint totalShares
    ) external returns (uint amountUnderlying);

    //Future Proofing to allow for bribe system
    function proxyCall(address token, address vault, address vaultToken, address[] memory targets, uint256[] memory values, bytes[] memory calldatas) external;

    function withdrawOrDeposit(address vaultToken, address vaultAdapter, uint amount, bool isWithdrawal) external;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;
import "../base/PermissionedAdapter.sol";
import "../../lib/ERC4626.sol";
import "../../lib/uniswap/IUniswapV2Router02.sol";
import "../../lib/uniswap/IUniswapV2Pair.sol";
import "../../lib/FixedPointMathLib.sol";
import "../../interfaces/IMasterChefV2.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";


contract MasterChefV2AdapterManual is ERC4626, PermissionedAdapter {
    using SafeMath for uint256;
    using SafeTransferLib for ERC20;
    using SafeERC20 for IERC20;
    using FixedPointMathLib for uint256;
    using Address for address;

    address public wftm = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public rewardToken;
 
    address public uniRouter;
    address public masterChef;

    address public lpPair;
    address public lpToken0;
    address public lpToken1;

    address[] public rewardTokenToLp0Route;
    address[] public rewardTokenToLp1Route;

    uint lastCompound;
    uint256 poolId;

    constructor(
        ERC20 _asset,
        uint256 _poolId,
        address[] memory _rewardTokenToLp0Route,
        address[] memory _rewardTokenToLp1Route,
        address _uniRouter,
        address _masterChef,
        address _rewardToken
    ) ERC4626(_asset, "MasterChefAdapter", "MFA") { //TODO - Change those things
        
        //TODO - Ownership locks on contract

        lpPair = address(_asset);
        poolId = _poolId;

        lpToken0 = IUniswapV2Pair(lpPair).token0();
        lpToken1 = IUniswapV2Pair(lpPair).token1();

        rewardTokenToLp0Route = _rewardTokenToLp0Route;
        rewardTokenToLp1Route = _rewardTokenToLp1Route;

        uniRouter = _uniRouter;
        masterChef = _masterChef;

        rewardToken = _rewardToken;
        giveAllowances();

    }

    
    function harvest() external onlyValidHarvester  {
        IMasterChefV2(masterChef).harvest(poolId, address(this));
        addLiquidity();
        deposit();
    }

        /**
     * @dev Function that puts the funds to work. Can only be called by EOA or whitelisted contracts
     * It gets called whenever someone deposits in the strategy's vault contract.
     * It deposits {lpPair} in the masterChef to farm {rewardToken}
     */
    function deposit() public {
        uint256 pairBal = IERC20(lpPair).balanceOf(address(this));

        if (pairBal > 0) {
            IMasterChefV2(masterChef).deposit(poolId, pairBal, address(this));
        }

       
    }


    function totalAssets() public view virtual override returns (uint256) {
        (uint256 amount, ) = IMasterChefV2(masterChef).userInfo(poolId, address(this));
        return amount;
    }

    function deposit(uint256 assets, address receiver) public virtual override returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function afterDeposit(uint256 assets, uint256) internal virtual override {
        uint256 pairBal = asset.balanceOf(address(this));

        if (pairBal > 0) {
            IMasterChefV2(masterChef).deposit(poolId, pairBal, address(this));
        }

        uint totalBalance;
        try IMasterChefV2(masterChef).pendingSushi(poolId, address(this)) returns (uint256 bal) {
                totalBalance = bal;
            } catch {
                totalBalance = 0;
            }

    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        //the issue is that shares is too high, previewWithdraw is incorrect

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.
            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);
        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

        function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

        /**
     * @dev Withdraws funds and sents them back to the vault.
     * It withdraws {lpPair} from the masterChef.
     * The available {lpPair} minus fees is returned to the vault.
     */
    function beforeWithdraw(uint256 assets, uint256) internal virtual override {
        // require(msg.sender == vault, "!vault");
        //Sometimes masterChef throws an error trying to convert to a uint256 so this just prevents that error from being thrown
        uint totalBalance;
        try IMasterChefV2(masterChef).pendingSushi(poolId, address(this)) returns (uint256 bal) {
            totalBalance = bal;
        } catch {
            totalBalance = 0;
        }

        uint256 pairBal = IERC20(lpPair).balanceOf(address(this));

        if (pairBal < assets) {
            IMasterChefV2(masterChef).withdraw(poolId, assets.sub(pairBal), address(this));

        }

    }

        /**
     * @dev Swaps {rewardToken} for {lpToken0}, {lpToken1} & {wftm} using SpookySwap.
     */
    function addLiquidity() internal {
        uint256 rewardTokenHalf = IERC20(rewardToken).balanceOf(address(this)).div(2);

        if (lpToken0 != rewardToken) {
            try IUniswapV2Router02(uniRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(rewardTokenHalf, 0, rewardTokenToLp0Route, address(this), block.timestamp.add(100)) {
               // Do Nothing
            } catch {
                return;
            }
        }

        if (lpToken1 != rewardToken) {
            try IUniswapV2Router02(uniRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(rewardTokenHalf, 0, rewardTokenToLp1Route, address(this), block.timestamp.add(600)) {
                // Do Nothing
            } catch {
                return;
            }
        }

        uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));

        IUniswapV2Router02(uniRouter).addLiquidity(lpToken0, lpToken1, lp0Bal, lp1Bal, 1, 1, address(this), block.timestamp.add(600));
    }

     function giveAllowances() internal {
        IERC20(lpPair).safeApprove(masterChef, type(uint256).max);

        IERC20(rewardToken).safeApprove(uniRouter, 0);
        IERC20(rewardToken).safeApprove(uniRouter, type(uint256).max);

        IERC20(lpToken0).safeApprove(uniRouter, 0);
        IERC20(lpToken0).safeApprove(uniRouter, type(uint256).max);

        IERC20(lpToken1).safeApprove(uniRouter, 0);
        IERC20(lpToken1).safeApprove(uniRouter, type(uint256).max);
    }


}

// SPDX-License-Identifier: GNU-GPL
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract PermissionedAdapter is AccessControl {

    bytes32 public constant HARVESTER = 'HARVESTER';

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(HARVESTER, msg.sender);
    }

    modifier onlyValidHarvester() {
        require(_validRecipient(), 'ER041');
        _;
    }

    function _validRecipient() internal view returns (bool valid) {
        uint32 size;
        address sender = msg.sender;
        assembly {
            size := extcodesize(sender)
        }
        bool isEOA = size == 0;
        valid = (msg.sender == tx.origin && isEOA) || hasRole(HARVESTER, msg.sender);
    }


}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "./ERC20.sol";
import {SafeTransferLib} from "./SafeTransferLib.sol";
import {FixedPointMathLib} from "./FixedPointMathLib.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol)
/// @dev Do not use in production! ERC-4626 is still in the last call stage and is subject to change.
abstract contract ERC4626 is ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    uint private constant MIN_DEPOSIT = 1E3;

    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, _asset.decimals()) {
        asset = _asset;
    }

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require(assets > MIN_DEPOSIT, 'ER043');

        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.
        require(assets > MIN_DEPOSIT, 'ER043');

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    /*///////////////////////////////////////////////////////////////
                           ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets) public view returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*///////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*///////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

pragma solidity >=0.8.0;

import "./IMasterChef.sol";

interface IMasterChefV2 is IMasterChef {
    function poolLength() external view returns (uint256);
    function setBooPerSecond(uint256 _rewardTokenPerSecond) external;
    function getMultiplier(uint256 _from, uint256 _to)
        external
        view
        returns (uint256);
    function pendingSushi(uint256 _pid, address _user)
        external
        view
        returns (uint256);
    function massUpdatePools() external;
    function updatePool(uint256 _pid) external;
    function deposit(uint256 _pid, uint256 _amount, address to) external;
    function withdraw(uint256 _pid, uint256 _amount, address to) external;
    function harvest(uint256 _pid, address to) external;
    function userInfo(uint256 _pid, address _user)
        external
        view
        returns (uint256, uint256);
    function emergencyWithdraw(uint256 _pid, address to) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
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
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "./ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returndatasize())

                // Revert with the same message.
                revert(0, returndatasize())
            }

            switch returndatasize()
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returndatasize())

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed output.
                success := 0
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external view returns (address);
    function WETH() external view returns (address);
    
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.8.0;

interface IMasterChef {
    function poolLength() external view returns (uint256);
    function setBooPerSecond(uint256 _rewardTokenPerSecond) external;
    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);
    function pendingBOO(uint256 _pid, address _user) external view returns (uint256);
    function massUpdatePools() external;
    function updatePool(uint256 _pid) external;
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function emergencyWithdraw(uint256 _pid) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;
import "../../lib/ERC4626.sol";
import "../../lib/uniswap/IUniswapV2Router02.sol";
import "../../lib/uniswap/IUniswapV2Pair.sol";
import "../../lib/FixedPointMathLib.sol";
import "../../interfaces/IMasterChefV2.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";


contract MasterChefV2Adapter is ERC4626 {
    using SafeMath for uint256;
    using SafeTransferLib for ERC20;
    using SafeERC20 for IERC20;
    using FixedPointMathLib for uint256;
    using Address for address;

    address public wftm = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public rewardToken;
 
    address public uniRouter;
    address public masterChef;

    address public lpPair;
    address public lpToken0;
    address public lpToken1;

    address[] public rewardTokenToLp0Route;
    address[] public rewardTokenToLp1Route;

    uint lastCompound;
    uint256 poolId;

    constructor(
        ERC20 _asset,
        uint256 _poolId,
        address[] memory _rewardTokenToLp0Route,
        address[] memory _rewardTokenToLp1Route,
        address _uniRouter,
        address _masterChef,
        address _rewardToken
    ) ERC4626(_asset, "MasterChefAdapter", "MFA") { //TODO - Change those things
        
        //TODO - Ownership locks on contract

        lpPair = address(_asset);
        poolId = _poolId;

        lpToken0 = IUniswapV2Pair(lpPair).token0();
        lpToken1 = IUniswapV2Pair(lpPair).token1();

        rewardTokenToLp0Route = _rewardTokenToLp0Route;
        rewardTokenToLp1Route = _rewardTokenToLp1Route;

        uniRouter = _uniRouter;
        masterChef = _masterChef;

        rewardToken = _rewardToken;
        giveAllowances();

    }

    
    function harvest() public {
        IMasterChefV2(masterChef).harvest(poolId, address(this));
        addLiquidity();
        deposit();
    }

        /**
     * @dev Function that puts the funds to work.
     * It gets called whenever someone deposits in the strategy's vault contract.
     * It deposits {lpPair} in the masterChef to farm {rewardToken}
     */
    function deposit() public {
        uint256 pairBal = IERC20(lpPair).balanceOf(address(this));

        if (pairBal > 0) {
            IMasterChefV2(masterChef).deposit(poolId, pairBal, address(this));
        }

       
    }

    function valueRewardTokens() public view virtual returns (uint256 lpTokens) {
        uint totalBalance;
        try IMasterChefV2(masterChef).pendingSushi(poolId, address(this)) returns (uint256 bal) {
                totalBalance = bal;
            } catch {
                totalBalance = 0;
            }


        if (totalBalance > 1) {

            uint256 rewardTokenHalf = totalBalance.div(2);

            (uint reserveA, uint reserveB,) = IUniswapV2Pair(lpPair).getReserves();
            
            //if reward token is half of the pair then getAmounts out will just be the same as the input
            uint256 amountToken0Out = lpToken0 == rewardToken ? rewardTokenHalf : IUniswapV2Router02(uniRouter).getAmountsOut(rewardTokenHalf, rewardTokenToLp0Route)[rewardTokenToLp0Route.length.sub(1)];
            uint256 amountToken1Out = lpToken1 == rewardToken ? rewardTokenHalf : IUniswapV2Router02(uniRouter).getAmountsOut(rewardTokenHalf, rewardTokenToLp1Route)[rewardTokenToLp1Route.length.sub(1)];

            uint256 totalSupply = asset.totalSupply();
            uint256 _kLast = IUniswapV2Pair(lpPair).kLast();
            uint256 newSupply;

            if (_kLast != 0) {
                uint rootK = FixedPointMathLib.sqrt(uint(reserveA).mul(reserveB));
                uint rootKLast = FixedPointMathLib.sqrt(_kLast);

                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) newSupply = totalSupply.add(liquidity);
                }
            }

            uint lpTokens0 = amountToken0Out.mulDivDown(newSupply, reserveA);
            uint lpTokens1 = amountToken1Out.mulDivDown(newSupply, reserveB);

            lpTokens = Math.min(lpTokens0, lpTokens1);
        }
    }



    function totalAssets() public view virtual override returns (uint256) {
        (uint256 amount, ) = IMasterChefV2(masterChef).userInfo(poolId, address(this));
        return amount.add(valueRewardTokens());
    }

    function deposit(uint256 assets, address receiver) public virtual override returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function afterDeposit(uint256 assets, uint256) internal virtual override {
        uint256 pairBal = asset.balanceOf(address(this));

        if (pairBal > 0) {
            IMasterChefV2(masterChef).deposit(poolId, pairBal, address(this));
        }

        uint totalBalance;
        try IMasterChefV2(masterChef).pendingSushi(poolId, address(this)) returns (uint256 bal) {
                totalBalance = bal;
            } catch {
                totalBalance = 0;
            }

        if (totalBalance > 1) {
            harvest();
        }

    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        //the issue is that shares is too high, previewWithdraw is incorrect

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.
            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);
        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

        function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

        /**
     * @dev Withdraws funds and sents them back to the vault.
     * It withdraws {lpPair} from the masterChef.
     * The available {lpPair} minus fees is returned to the vault.
     */
    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual override {
        // require(msg.sender == vault, "!vault");
        //Sometimes masterChef throws an error trying to convert to a uint256 so this just prevents that error from being thrown
        uint totalBalance;
        try IMasterChefV2(masterChef).pendingSushi(poolId, address(this)) returns (uint256 bal) {
                totalBalance = bal;
            } catch {
                totalBalance = 0;
            }

        if (totalBalance > 1) {
            harvest();
        }

        uint256 pairBal = IERC20(lpPair).balanceOf(address(this));
        (uint256 maxWithdrawal, ) = IMasterChefV2(masterChef).userInfo(poolId, address(this));

        if (pairBal < assets) {
            // IMasterChefV2(masterChef).withdraw(poolId, assets.sub(pairBal), address(this));
            IMasterChefV2(masterChef).withdraw(poolId, assets.sub(pairBal), address(this));

        }

    }

        /**
     * @dev Swaps {rewardToken} for {lpToken0}, {lpToken1} & {wftm} using SpookySwap.
     */
    function addLiquidity() internal {
        uint256 rewardTokenHalf = IERC20(rewardToken).balanceOf(address(this)).div(2);

        if (lpToken0 != rewardToken) {
            try IUniswapV2Router02(uniRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(rewardTokenHalf, 0, rewardTokenToLp0Route, address(this), block.timestamp.add(100)) {
               // Do Nothing
            } catch {
                return;
            }
        }

        if (lpToken1 != rewardToken) {
            try IUniswapV2Router02(uniRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(rewardTokenHalf, 0, rewardTokenToLp1Route, address(this), block.timestamp.add(600)) {
                // Do Nothing
            } catch {
                return;
            }
        }

        uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));

        IUniswapV2Router02(uniRouter).addLiquidity(lpToken0, lpToken1, lp0Bal, lp1Bal, 1, 1, address(this), block.timestamp.add(600));
    }

     function giveAllowances() internal {
        IERC20(lpPair).safeApprove(masterChef, type(uint256).max);

        IERC20(rewardToken).safeApprove(uniRouter, 0);
        IERC20(rewardToken).safeApprove(uniRouter, type(uint256).max);

        IERC20(lpToken0).safeApprove(uniRouter, 0);
        IERC20(lpToken0).safeApprove(uniRouter, type(uint256).max);

        IERC20(lpToken1).safeApprove(uniRouter, 0);
        IERC20(lpToken1).safeApprove(uniRouter, type(uint256).max);
    }


}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import "../../interfaces/adapters/yearn/IVaultWrapper.sol";
import {VaultAPI} from "../../interfaces/adapters/yearn/VaultAPI.sol";
import "../../interfaces/IERC4626.sol";
import {FixedPointMathLib} from "../../lib/FixedPointMathLib.sol";

import "hardhat/console.sol";


interface IYearnRegistry {
    function latestVault(address asset) external returns (address); 
}

// Needs to extract VaultAPI interface out of BaseStrategy to avoid collision
contract YearnWrapper_usdt is ERC20, IVaultWrapper, IERC4626, Ownable {
    VaultAPI public yVault;
    address public immutable token;
    IYearnRegistry public registry = IYearnRegistry(0x50c1a2eA0a861A967D9d0FFE2AE4012c2E053804);
    uint256 public immutable _decimals;
    
    using FixedPointMathLib for uint;
    using SafeERC20 for IERC20;

    constructor(VaultAPI _vault)
        ERC20(
            string(abi.encodePacked(_vault.name(), "-4646-Adapter")),
            string(abi.encodePacked(_vault.symbol(), "-4646"))
        )
    {
        yVault = _vault;
        token = yVault.token();
        _decimals = uint8(_vault.decimals());
    }

    function vault() external view returns (address) {
        return address(yVault);
    }

    /// @dev Verifies that the yearn registry has "_target" recorded as the asset's latest vault
    function migrate(address _target) external onlyOwner returns (address) {
        // verify _target is a valid address
        require(registry.latestVault(token) == _target, "Invalid migration target");

        // withdraw all shares, returns amount of want withdrawn
        uint assets = yVault.withdraw(type(uint).max);
        // migrate vault
        yVault = VaultAPI(_target);

        // Redeposit want into target vault
        yVault.deposit(assets);

        return _target;
    }

    // NOTE: this number will be different from this token's totalSupply
    function vaultTotalSupply() external view returns (uint256) {
        return yVault.totalSupply();
    }

    /*//////////////////////////////////////////////////////////////
                      ERC20 compatibility
   //////////////////////////////////////////////////////////////*/

    function decimals() public view override(ERC20,IERC4626) returns (uint8) {
        return uint8(_decimals);
    }

    function asset() external view override returns (address) {
        return token;
    }

    /*//////////////////////////////////////////////////////////////
                      DEPOSIT/WITHDRAWAL LOGIC
  //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver)
        public
        override
        returns (uint256 shares)
    {
        (assets, shares) = _deposit(assets, receiver, msg.sender);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function mint(uint256 shares, address receiver)
        public
        override
        returns (uint256 assets)
    {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        (assets, shares) = _deposit(assets, receiver, msg.sender);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    // TODO: add allowance check to use owner argument
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override returns (uint256 shares) {
        (uint256 _withdrawn, uint256 _burntShares) = _withdraw(
            assets,
            receiver,
            msg.sender
        );

        emit Withdraw(msg.sender, receiver, owner, _withdrawn, _burntShares);
        return _burntShares;
    }

    // TODO: add allowance check to use owner argument
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override returns (uint256 assets) {
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");
        (uint256 _withdrawn, uint256 _burntShares) = _withdraw(
            assets,
            receiver,
            msg.sender
        );

        emit Withdraw(msg.sender, receiver, owner, _withdrawn, _burntShares);
        return _withdrawn;
    }

    /*//////////////////////////////////////////////////////////////
                          ACCOUNTING LOGIC
  //////////////////////////////////////////////////////////////*/

    function totalAssets() public view override returns (uint256) {
        return convertYearnSharesToAssets(yVault.balanceOf(address(this)));
    }

    function convertToShares(uint256 assets)
        public
        view
        override
        returns (uint256)
    {
        uint supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.
        uint localAssets = convertYearnSharesToAssets(yVault.balanceOf(address(this)));
        return supply == 0 ? assets : assets.mulDivDown(supply, localAssets); 
    }

    function convertToAssets(uint256 shares)
        public
        view
        override
        returns (uint assets)
    {
        uint supply = totalSupply();
        uint localAssets = convertYearnSharesToAssets(yVault.balanceOf(address(this)));
        return supply == 0 ? shares : shares.mulDivDown(localAssets, supply);
    }

    function getFreeFunds() public view returns (uint256) {
        uint256 lockedFundsRatio = (block.timestamp - yVault.lastReport()) * yVault.lockedProfitDegration();
        uint256 _lockedProfit = yVault.lockedProfit();

        uint256 DEGRADATION_COEFFICIENT = 10 ** 18;
        uint256 lockedProfit = lockedFundsRatio < DEGRADATION_COEFFICIENT ? 
            _lockedProfit - (lockedFundsRatio * _lockedProfit / DEGRADATION_COEFFICIENT)
            : 0; // hardcoded DEGRADATION_COEFFICIENT        
        return yVault.totalAssets() - lockedProfit;
    }

    
    function previewDeposit(uint256 assets)
        public
        view
        override
        returns (uint256)
    {
        return convertToShares(assets);
    }

    function previewWithdraw(uint256 assets)
        public
        view
        override
        returns (uint256)
    {
        uint supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.
        uint localAssets = convertYearnSharesToAssets(yVault.balanceOf(address(this)));
        return supply == 0 ? assets : assets.mulDivUp(supply, localAssets); 
    }

    function previewMint(uint256 shares)
        public
        view
        override
        returns (uint256)
    {
        uint supply = totalSupply();
        uint localAssets = convertYearnSharesToAssets(yVault.balanceOf(address(this)));
        return supply == 0 ? shares : shares.mulDivUp(localAssets, supply);
    }

    function previewRedeem(uint256 shares)
        public
        view
        override
        returns (uint256)
    {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                    DEPOSIT/WITHDRAWAL LIMIT LOGIC
  //////////////////////////////////////////////////////////////*/

    function maxDeposit(address _account)
        public
        view
        override
        returns (uint256)
    {
        _account; // TODO can acc custom logic per depositor
        VaultAPI _bestVault = yVault;
        uint256 _totalAssets = _bestVault.totalAssets();
        uint256 _depositLimit = _bestVault.depositLimit();
        if (_totalAssets >= _depositLimit) return 0;
        return _depositLimit - _totalAssets;
    }

    function maxMint(address _account)
        external
        view
        override
        returns (uint256)
    {
        return convertToShares(maxDeposit(_account));
    }

    function maxWithdraw(address owner)
        external
        view
        override
        returns (uint256)
    {
        return convertToAssets(this.balanceOf(owner));
    }

    function maxRedeem(address owner) external view override returns (uint256) {
        return this.balanceOf(owner);
    }

     function _deposit(
        uint256 amount, // if `MAX_UINT256`, just deposit everything
        address receiver,
        address depositor
    ) internal returns (uint256 deposited, uint256 mintedShares) {
        VaultAPI _vault = yVault;
        IERC20 _token = IERC20(token);

        if (amount == type(uint256).max) {
            amount = Math.min(
                _token.balanceOf(depositor),
                _token.allowance(depositor, address(this))
            );
        }

        _token.safeTransferFrom(depositor, address(this), amount);

        uint _allowance = _token.allowance(address(this), address(_vault));
        if (_allowance < amount) {
            if (_allowance > 0) {
                _token.safeApprove(address(_vault), 0);
            }
            _token.safeApprove(address(_vault), type(uint256).max);
        }
        // beforeDeposit custom logic

        // Depositing returns number of shares deposited
        uint256 beforeBal = _token.balanceOf(address(this));

        mintedShares = previewDeposit(amount);

        _vault.deposit(amount, address(this));
        uint256 afterBal = _token.balanceOf(address(this));
        deposited = beforeBal - afterBal;

        // afterDeposit custom logic
        _mint(receiver, mintedShares);

    }

    function _withdraw(
        uint256 amount, // if `MAX_UINT256`, just withdraw everything
        address receiver,
        address sender
    ) internal returns (uint256 assets, uint256 shares) {
        VaultAPI _vault = yVault;
        shares = convertToShares(amount);
        // console.log("Withdrawing shares: %s",shares);
        // console.log("Total supply of shares: %s", totalSupply());
        uint yearnShares = convertAssetsToYearnShares(amount);
        // console.log("Attempting to redeem yearn shares: %s",yearnShares);
        // console.log("Current balance of Yearn shares: %s", yVault.balanceOf(address(this)));
        // console.log("Total supply of Yearn shares: %s", yVault.totalSupply());
        if (shares > totalSupply()) {
            revert NotEnoughAvailableSharesForAmount();
        }
        _burn(sender, shares);
        // withdraw from vault and get total used shares
        assets = _vault.withdraw(yearnShares, receiver, 0);
        
    }


    ///
    /// VIEW METHODS
    ///

    function convertAssetsToYearnShares(uint assets) internal view returns (uint yShares) {
        uint256 supply = yVault.totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.
        return supply == 0 ? assets : assets * supply / getFreeFunds();
    }

    function convertYearnSharesToAssets(uint yearnShares) internal view returns (uint assets) {
        uint supply = yVault.totalSupply();
        return supply == 0 ? yearnShares : yearnShares * getFreeFunds() / supply;
    }

    function allowance(address owner, address spender) public view virtual override(ERC20,IERC4626) returns (uint256) {
        return super.allowance(owner,spender);
    }

    function balanceOf(address account) public view virtual override(ERC20,IERC4626) returns (uint256) {
        return super.balanceOf(account);
    }

    function name() public view virtual override(ERC20,IERC4626) returns (string memory) {
        return super.name();
    }

    function symbol() public view virtual override(ERC20,IERC4626) returns (string memory) {
        return super.symbol();
    }

    function totalSupply() public view virtual override(ERC20,IERC4626) returns (uint256) {
        return super.totalSupply();
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

interface IVaultWrapper {
    
    error NoAvailableShares();
    error NotEnoughAvailableSharesForAmount();

    function vault() external view returns (address);

    function vaultTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8;

import "../../IERC20.sol";

struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}


interface VaultAPI is IERC20 {

    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function decimals() external view returns (uint256);

    function apiVersion() external pure returns (string memory);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function deposit() external returns (uint256);

    function deposit(uint256 amount) external returns (uint256);

    function deposit(uint256 amount, address recipient) external returns (uint256);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient, uint maxLoss) external returns (uint256);

    function token() external view returns (address);

    function strategies(address _strategy) external view returns (StrategyParams memory);

    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function depositLimit() external view returns (uint256);

    function maxAvailableShares() external view returns (uint256);

    /**
     * View how much the Vault would increase this Strategy's borrow limit,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function creditAvailable() external view returns (uint256);

    /**
     * View how much the Vault would like to pull back from the Strategy,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function debtOutstanding() external view returns (uint256);

    /**
     * View how much the Vault expect this Strategy to return at the current
     * block, based on its present performance (since its last report). Can be
     * used to determine expectedReturn in your Strategy.
     */
    function expectedReturn() external view returns (uint256);

    /**
     * This is the main contact point where the Strategy interacts with the
     * Vault. It is critical that this call is handled as intended by the
     * Strategy. Therefore, this function will be called by BaseStrategy to
     * make sure the integration is correct.
     */
    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256);

    /**
     * This function should only be used in the scenario where the Strategy is
     * being retired but no migration of the positions are possible, or in the
     * extreme scenario that the Strategy needs to be put into "Emergency Exit"
     * mode in order for it to exit as quickly as possible. The latter scenario
     * could be for any reason that is considered "critical" that the Strategy
     * exits its position as fast as possible, such as a sudden change in
     * market conditions leading to losses, or an imminent failure in an
     * external dependency.
     */
    function revokeStrategy() external;

    /**
     * View the governance address of the Vault to assert privileged functions
     * can only be called by governance. The Strategy serves the Vault, so it
     * is subject to governance defined by the Vault.
     */
    function governance() external view returns (address);

    /**
     * View the management address of the Vault to assert privileged functions
     * can only be called by management. The Strategy serves the Vault, so it
     * is subject to management defined by the Vault.
     */
    function management() external view returns (address);

    /**
     * View the guardian address of the Vault to assert privileged functions
     * can only be called by guardian. The Strategy serves the Vault, so it
     * is subject to guardian defined by the Vault.
     */
    function guardian() external view returns (address);

    function lockedProfitDegradation() external view returns (uint256);
    function lockedProfitDegration() external view returns (uint256);
    function lastReport() external view returns (uint256);
    function lockedProfit() external view returns (uint256);
    function totalDebt() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBVaultV2 {
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@prb/math/contracts/PRBMathSD59x18.sol";

import "../ProviderAwareOracle.sol";
import "../../interfaces/IBPoolV2.sol";
import "../../interfaces/IBVaultV2.sol";

contract BalancerV2WeightedPoolPriceOracle is ProviderAwareOracle {

    using PRBMathSD59x18 for *;

    address public immutable WETH;

    IBVaultV2 public vault;
    uint256 public ratioDiffLimitNumerator;
    uint256 public ratioDiffLimitDenominator;

    event SetRatioDiffLimit(
        uint256 ratioDiffLimitNumerator,
        uint256 ratioDiffLimitDenominator
    );

    /**
     * @dev sets up the Price Oracle
     * @param _provider price provider
     * @param _vault balancer vault address
     */
    constructor(
        address _provider,
        address _vault,
        address _weth
    ) ProviderAwareOracle(_provider)  {
        require(_vault != address(0), "vault cannot be null address");
        vault = IBVaultV2(_vault);
        WETH = _weth;
    }

    /**
     * @dev set ratio difference limit
     */
    function setRatioDiffLimit(
        uint256 _ratioDiffLimitNumerator,
        uint256 _ratioDiffLimitDenominator
    ) external onlyOwner {
        require(
            _ratioDiffLimitNumerator <= _ratioDiffLimitDenominator,
            "INVALID RATIO DIFF LIMIT"
        );

        ratioDiffLimitNumerator = _ratioDiffLimitNumerator;
        ratioDiffLimitDenominator = _ratioDiffLimitDenominator;

        emit SetRatioDiffLimit(_ratioDiffLimitNumerator, _ratioDiffLimitDenominator);
    }

    /****** OPERATIONAL METHODS ******/

    /**
     * @dev returns the TWAP for the provided pair as of the last update
     */
    function getSafePrice(address _bpt) public view returns (uint256) {
        return _getLPPrice(_bpt, true);
    }

    /**
     * @dev returns the current "unsafe" price that can be easily manipulated
     */
    function getCurrentPrice(address _bpt) external view returns (uint256) {
        return _getLPPrice(_bpt, false);
    }

    /**
     * @dev updates the TWAP (if enough time has lapsed) and returns the current safe price
     */
    function updateSafePrice(address _bpt) external returns (uint256) {
        return getSafePrice(_bpt);
    }

    // internal functions

    function _getTokenSafePrice(address token) internal view returns (uint256 price) {       
        if (token != WETH) {
            price = provider.getSafePrice(token);
        } else {
            price = PRECISION;
        }
    }

    function _getTokenCurrentPrice(address token) internal view returns (uint256 price) {
        if (token != WETH) {
            price = provider.getCurrentPrice(token);
        } else {
            price = PRECISION;
        }
    }

    function _getLPPrice(address _bpt, bool isSafePrice)
        internal
        view
        returns (uint256 price)
    {
        bytes32 poolId = IBPoolV2(_bpt).getPoolId();
        uint256[] memory weights = IBPoolV2(_bpt).getNormalizedWeights();
        int256 totalSupply = int256(IBPoolV2(_bpt).totalSupply());
        (IERC20[] memory tokens, uint256[] memory balances, ) = vault.getPoolTokens(
            poolId
        );

        // console.logInt(totalSupply);

        // int256 invariant = PRBMathSD59x18.toInt(1e18);
        int256 totalPi = PRBMathSD59x18.fromInt(1e18);

        uint256 totalFTM;
        uint256[] memory prices = new uint256[](tokens.length);
        // update balances in 18 decimals
        for (uint256 i = 0; i < tokens.length; i++) {
            balances[i] =
                (balances[i] * (10**18)) /
                (10**ERC20(address(tokens[i])).decimals());
            prices[i] = isSafePrice
                ? _getTokenSafePrice(address(tokens[i]))
                : _getTokenCurrentPrice(address(tokens[i]));

            int256 val = int256(prices[i]).div(int256(weights[i]));
            int256 indivPi = val.pow(int256(weights[i]));

            totalPi = totalPi.mul(indivPi);
           
        }

        int256 invariant = int256(IBPoolV2(_bpt).getLastInvariant());
        int256 numerator = totalPi.mul(invariant);

        price = uint256((numerator.toInt().div(totalSupply)));
        // price = totalFTM / totalSupply;
    }

    function _checkRatio(
        uint256 reserve0,
        uint256 reserve1,
        uint256 price0,
        uint256 price1
    ) internal view {
        uint256 value0 = reserve0 * price0;
        uint256 value1 = reserve1 * price1;
        uint256 diffLimit = (value0 * ratioDiffLimitNumerator) /
            ratioDiffLimitDenominator;

        require(
            value1 < value0 + diffLimit && value0 < value1 + diffLimit,
            "INVALID RATIO"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IPriceOracle.sol";
import "../../interfaces/IPriceProvider.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ProviderAwareOracle is IPriceOracle, Ownable {

    uint internal constant PRECISION = 1 ether;

    IPriceProvider public provider;

    event ProviderTransfer(address _newProvider, address _oldProvider);

    constructor(address _provider) {
        provider = IPriceProvider(_provider);
    }

    function setPriceProvider(address _newProvider) external onlyOwner {
        address oldProvider = address(provider);
        provider = IPriceProvider(_newProvider);
        emit ProviderTransfer(_newProvider, oldProvider);
    }


}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

interface IBPoolV2 {
    function getNormalizedWeights() external view returns (uint256[] memory);

    function totalSupply() external view returns (uint256);

    function getPoolId() external view returns (bytes32);

    function getLastInvariant() external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathSD59x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with int256 numbers considered to have 18
/// trailing decimals. We call this number representation signed 59.18-decimal fixed-point, since the numbers can have
/// a sign and there can be up to 59 digits in the integer part and up to 18 decimals in the fractional part. The numbers
/// are bound by the minimum and the maximum values permitted by the Solidity type int256.
library PRBMathSD59x18 {
    /// @dev log2(e) as a signed 59.18-decimal fixed-point number.
    int256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev Half the SCALE number.
    int256 internal constant HALF_SCALE = 5e17;

    /// @dev The maximum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728_792003956564819967;

    /// @dev The maximum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_WHOLE_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728_000000000000000000;

    /// @dev The minimum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728_792003956564819968;

    /// @dev The minimum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_WHOLE_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    int256 internal constant SCALE = 1e18;

    /// INTERNAL FUNCTIONS ///

    /// @notice Calculate the absolute value of x.
    ///
    /// @dev Requirements:
    /// - x must be greater than MIN_SD59x18.
    ///
    /// @param x The number to calculate the absolute value for.
    /// @param result The absolute value of x.
    function abs(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x == MIN_SD59x18) {
                revert PRBMathSD59x18__AbsInputTooSmall();
            }
            result = x < 0 ? -x : x;
        }
    }

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The arithmetic average as a signed 59.18-decimal fixed-point number.
    function avg(int256 x, int256 y) internal pure returns (int256 result) {
        // The operations can never overflow.
        unchecked {
            int256 sum = (x >> 1) + (y >> 1);
            if (sum < 0) {
                // If at least one of x and y is odd, we add 1 to the result. This is because shifting negative numbers to the
                // right rounds down to infinity.
                assembly {
                    result := add(sum, and(or(x, y), 1))
                }
            } else {
                // If both x and y are odd, we add 1 to the result. This is because if both numbers are odd, the 0.5
                // remainder gets truncated twice.
                result = sum + (x & y & 1);
            }
        }
    }

    /// @notice Yields the least greatest signed 59.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as a signed 58.18-decimal fixed-point number.
    function ceil(int256 x) internal pure returns (int256 result) {
        if (x > MAX_WHOLE_SD59x18) {
            revert PRBMathSD59x18__CeilOverflow(x);
        }
        unchecked {
            int256 remainder = x % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                result = x - remainder;
                if (x > 0) {
                    result += SCALE;
                }
            }
        }
    }

    /// @notice Divides two signed 59.18-decimal fixed-point numbers, returning a new signed 59.18-decimal fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDiv".
    /// - None of the inputs can be MIN_SD59x18.
    /// - The denominator cannot be zero.
    /// - The result must fit within int256.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDiv".
    ///
    /// @param x The numerator as a signed 59.18-decimal fixed-point number.
    /// @param y The denominator as a signed 59.18-decimal fixed-point number.
    /// @param result The quotient as a signed 59.18-decimal fixed-point number.
    function div(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == MIN_SD59x18 || y == MIN_SD59x18) {
            revert PRBMathSD59x18__DivInputTooSmall();
        }

        // Get hold of the absolute values of x and y.
        uint256 ax;
        uint256 ay;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
        }

        // Compute the absolute value of (x*SCALE)÷y. The result must fit within int256.
        uint256 rAbs = PRBMath.mulDiv(ax, uint256(SCALE), ay);
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__DivOverflow(rAbs);
        }

        // Get the signs of x and y.
        uint256 sx;
        uint256 sy;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
        }

        // XOR over sx and sy. This is basically checking whether the inputs have the same sign. If yes, the result
        // should be positive. Otherwise, it should be negative.
        result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Returns Euler's number as a signed 59.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (int256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// Caveats:
    /// - All from "exp2".
    /// - For any x less than -41.446531673892822322, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp(int256 x) internal pure returns (int256 result) {
        // Without this check, the value passed to "exp2" would be less than -59.794705707972522261.
        if (x < -41_446531673892822322) {
            return 0;
        }

        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathSD59x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            int256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - For any x less than -59.794705707972522261, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp2(int256 x) internal pure returns (int256 result) {
        // This works because 2^(-x) = 1/2^x.
        if (x < 0) {
            // 2^59.794705707972522262 is the maximum number whose inverse does not truncate down to zero.
            if (x < -59_794705707972522261) {
                return 0;
            }

            // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
            unchecked {
                result = 1e36 / exp2(-x);
            }
        } else {
            // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
            if (x >= 192e18) {
                revert PRBMathSD59x18__Exp2InputTooBig(x);
            }

            unchecked {
                // Convert x to the 192.64-bit fixed-point format.
                uint256 x192x64 = (uint256(x) << 64) / uint256(SCALE);

                // Safe to convert the result to int256 directly because the maximum input allowed is 192.
                result = int256(PRBMath.exp2(x192x64));
            }
        }
    }

    /// @notice Yields the greatest signed 59.18 decimal fixed-point number less than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be greater than or equal to MIN_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as a signed 58.18-decimal fixed-point number.
    function floor(int256 x) internal pure returns (int256 result) {
        if (x < MIN_WHOLE_SD59x18) {
            revert PRBMathSD59x18__FloorUnderflow(x);
        }
        unchecked {
            int256 remainder = x % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                result = x - remainder;
                if (x < 0) {
                    result -= SCALE;
                }
            }
        }
    }

    /// @notice Yields the excess beyond the floor of x for positive numbers and the part of the number to the right
    /// of the radix point for negative numbers.
    /// @dev Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part
    /// @param x The signed 59.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as a signed 59.18-decimal fixed-point number.
    function frac(int256 x) internal pure returns (int256 result) {
        unchecked {
            result = x % SCALE;
        }
    }

    /// @notice Converts a number from basic integer form to signed 59.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be greater than or equal to MIN_SD59x18 divided by SCALE.
    /// - x must be less than or equal to MAX_SD59x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in signed 59.18-decimal fixed-point representation.
    function fromInt(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x < MIN_SD59x18 / SCALE) {
                revert PRBMathSD59x18__FromIntUnderflow(x);
            }
            if (x > MAX_SD59x18 / SCALE) {
                revert PRBMathSD59x18__FromIntOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_SD59x18, lest it overflows.
    /// - x * y cannot be negative.
    ///
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function gm(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            int256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathSD59x18__GmOverflow(x, y);
            }

            // The product cannot be negative.
            if (xy < 0) {
                revert PRBMathSD59x18__GmNegativeProduct(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = int256(PRBMath.sqrt(uint256(xy)));
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as a signed 59.18-decimal fixed-point number.
    function inv(int256 x) internal pure returns (int256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as a signed 59.18-decimal fixed-point number.
    function ln(int256 x) internal pure returns (int256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 195205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as a signed 59.18-decimal fixed-point number.
    function log10(int256 x) internal pure returns (int256 result) {
        if (x <= 0) {
            revert PRBMathSD59x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly mul operation, not the "mul" function defined in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            default {
                result := MAX_SD59x18
            }
        }

        if (result == MAX_SD59x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than zero.
    ///
    /// Caveats:
    /// - The results are not perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as a signed 59.18-decimal fixed-point number.
    function log2(int256 x) internal pure returns (int256 result) {
        if (x <= 0) {
            revert PRBMathSD59x18__LogInputTooSmall(x);
        }
        unchecked {
            // This works because log2(x) = -log2(1/x).
            int256 sign;
            if (x >= SCALE) {
                sign = 1;
            } else {
                sign = -1;
                // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
                assembly {
                    x := div(1000000000000000000000000000000000000, x)
                }
            }

            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(uint256(x / SCALE));

            // The integer part of the logarithm as a signed 59.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255, SCALE is 1e18 and sign is either 1 or -1.
            result = int256(n) * SCALE;

            // This is y = x * 2^(-n).
            int256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result * sign;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (int256 delta = int256(HALF_SCALE); delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
            result *= sign;
        }
    }

    /// @notice Multiplies two signed 59.18-decimal fixed-point numbers together, returning a new signed 59.18-decimal
    /// fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers and employs constant folding, i.e. the denominator is
    /// always 1e18.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - None of the inputs can be MIN_SD59x18
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    ///
    /// @param x The multiplicand as a signed 59.18-decimal fixed-point number.
    /// @param y The multiplier as a signed 59.18-decimal fixed-point number.
    /// @return result The product as a signed 59.18-decimal fixed-point number.
    function mul(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == MIN_SD59x18 || y == MIN_SD59x18) {
            revert PRBMathSD59x18__MulInputTooSmall();
        }

        unchecked {
            uint256 ax;
            uint256 ay;
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);

            uint256 rAbs = PRBMath.mulDivFixedPoint(ax, ay);
            if (rAbs > uint256(MAX_SD59x18)) {
                revert PRBMathSD59x18__MulOverflow(rAbs);
            }

            uint256 sx;
            uint256 sy;
            assembly {
                sx := sgt(x, sub(0, 1))
                sy := sgt(y, sub(0, 1))
            }
            result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
        }
    }

    /// @notice Returns PI as a signed 59.18-decimal fixed-point number.
    function pi() internal pure returns (int256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    /// - z cannot be zero.
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as a signed 59.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as a signed 59.18-decimal fixed-point number.
    /// @return result x raised to power y, as a signed 59.18-decimal fixed-point number.
    function pow(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : int256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (signed 59.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - All from "abs" and "PRBMath.mulDivFixedPoint".
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as a signed 59.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function powu(int256 x, uint256 y) internal pure returns (int256 result) {
        uint256 xAbs = uint256(abs(x));

        // Calculate the first iteration of the loop in advance.
        uint256 rAbs = y & 1 > 0 ? xAbs : uint256(SCALE);

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        uint256 yAux = y;
        for (yAux >>= 1; yAux > 0; yAux >>= 1) {
            xAbs = PRBMath.mulDivFixedPoint(xAbs, xAbs);

            // Equivalent to "y % 2 == 1" but faster.
            if (yAux & 1 > 0) {
                rAbs = PRBMath.mulDivFixedPoint(rAbs, xAbs);
            }
        }

        // The result must fit within the 59.18-decimal fixed-point representation.
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__PowuOverflow(rAbs);
        }

        // Is the base negative and the exponent an odd number?
        bool isNegative = x < 0 && y & 1 == 1;
        result = isNegative ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Returns 1 as a signed 59.18-decimal fixed-point number.
    function scale() internal pure returns (int256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x cannot be negative.
    /// - x must be less than MAX_SD59x18 / SCALE.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as a signed 59.18-decimal fixed-point .
    function sqrt(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x < 0) {
                revert PRBMathSD59x18__SqrtNegativeInput(x);
            }
            if (x > MAX_SD59x18 / SCALE) {
                revert PRBMathSD59x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two signed
            // 59.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = int256(PRBMath.sqrt(uint256(x * SCALE)));
        }
    }

    /// @notice Converts a signed 59.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The signed 59.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toInt(int256 x) internal pure returns (int256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @dev Oracles should always return un the price in FTM with 18 decimals
interface IPriceOracle {
    /// @dev This method returns a flashloan resistant price.
    function getSafePrice(address token) external view returns (uint256 _amountOut);

    /// @dev This method has no guarantee on the safety of the price returned. It should only be
    //used if the price returned does not expose the caller contract to flashloan attacks.
    function getCurrentPrice(address token) external view returns (uint256 _amountOut);

    /// @dev This method returns a flashloan resistant price, but doesn't
    //have the view modifier which makes it convenient to update
    //a uniswap oracle which needs to maintain the TWAP regularly.
    //You can use this function while doing other state changing tx and
    //make the callers maintain the oracle.
    function updateSafePrice(address token) external returns (uint256 _amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPriceProvider {

    event SetTokenOracle(address token, address oracle);

    function getSafePrice(address token) external view returns (uint256);

    function getCurrentPrice(address token) external view returns (uint256);

    function updateSafePrice(address token) external returns (uint256);

    /// Get value of an asset in units of quote
    function getValueOfAsset(address asset, address quote) external view returns (uint safePrice);

    function tokenHasOracle(address token) external view returns (bool hasOracle);

    function pairHasOracle(address token, address quote) external view returns (bool hasOracle);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division.
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
            // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number.
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathUD60x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with uint256 numbers considered to have 18
/// trailing decimals. We call this number representation unsigned 60.18-decimal fixed-point, since there can be up to 60
/// digits in the integer part and up to 18 decimals in the fractional part. The numbers are bound by the minimum and the
/// maximum values permitted by the Solidity type uint256.
library PRBMathUD60x18 {
    /// @dev Half the SCALE number.
    uint256 internal constant HALF_SCALE = 5e17;

    /// @dev log2(e) as an unsigned 60.18-decimal fixed-point number.
    uint256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev The maximum value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_584007913129639935;

    /// @dev The maximum whole value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_WHOLE_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The arithmetic average as an unsigned 60.18-decimal fixed-point number.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            result = (x >> 1) + (y >> 1) + (x & y & 1);
        }
    }

    /// @notice Yields the least unsigned 60.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_UD60x18.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function ceil(uint256 x) internal pure returns (uint256 result) {
        if (x > MAX_WHOLE_UD60x18) {
            revert PRBMathUD60x18__CeilOverflow(x);
        }
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "SCALE - remainder" but faster.
            let delta := sub(SCALE, remainder)

            // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
            result := add(x, mul(delta, gt(remainder, 0)))
        }
    }

    /// @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
    ///
    /// @dev Uses mulDiv to enable overflow-safe multiplication and division.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    ///
    /// @param x The numerator as an unsigned 60.18-decimal fixed-point number.
    /// @param y The denominator as an unsigned 60.18-decimal fixed-point number.
    /// @param result The quotient as an unsigned 60.18-decimal fixed-point number.
    function div(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(x, SCALE, y);
    }

    /// @notice Returns Euler's number as an unsigned 60.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (uint256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp(uint256 x) internal pure returns (uint256 result) {
        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathUD60x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            uint256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_UD60x18.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
        if (x >= 192e18) {
            revert PRBMathUD60x18__Exp2InputTooBig(x);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x192x64 = (x << 64) / SCALE;

            // Pass x to the PRBMath.exp2 function, which uses the 192.64-bit fixed-point number representation.
            result = PRBMath.exp2(x192x64);
        }
    }

    /// @notice Yields the greatest unsigned 60.18 decimal fixed-point number less than or equal to x.
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    /// @param x The unsigned 60.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function floor(uint256 x) internal pure returns (uint256 result) {
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
            result := sub(x, mul(remainder, gt(remainder, 0)))
        }
    }

    /// @notice Yields the excess beyond the floor of x.
    /// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
    /// @param x The unsigned 60.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as an unsigned 60.18-decimal fixed-point number.
    function frac(uint256 x) internal pure returns (uint256 result) {
        assembly {
            result := mod(x, SCALE)
        }
    }

    /// @notice Converts a number from basic integer form to unsigned 60.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be less than or equal to MAX_UD60x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in unsigned 60.18-decimal fixed-point representation.
    function fromUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__FromUintOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_UD60x18, lest it overflows.
    ///
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function gm(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            uint256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathUD60x18__GmOverflow(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = PRBMath.sqrt(xy);
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as an unsigned 60.18-decimal fixed-point number.
    function inv(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2.718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as an unsigned 60.18-decimal fixed-point number.
    function ln(uint256 x) internal pure returns (uint256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 196205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as an unsigned 60.18-decimal fixed-point number.
    function log10(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly multiplication operation, not the "mul" function defined
        // in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 59) }
            default {
                result := MAX_UD60x18
            }
        }

        if (result == MAX_UD60x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than or equal to SCALE, otherwise the result would be negative.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }
        unchecked {
            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(x / SCALE);

            // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255 and SCALE is 1e18.
            result = n * SCALE;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
        }
    }

    /// @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @dev See the documentation for the "PRBMath.mulDivFixedPoint" function.
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The product as an unsigned 60.18-decimal fixed-point number.
    function mul(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDivFixedPoint(x, y);
    }

    /// @notice Returns PI as an unsigned 60.18-decimal fixed-point number.
    function pi() internal pure returns (uint256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as an unsigned 60.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as an unsigned 60.18-decimal fixed-point number.
    /// @return result x raised to power y, as an unsigned 60.18-decimal fixed-point number.
    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - The result must fit within MAX_UD60x18.
    ///
    /// Caveats:
    /// - All from "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as an unsigned 60.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function powu(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // Calculate the first iteration of the loop in advance.
        result = y & 1 > 0 ? x : SCALE;

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            x = PRBMath.mulDivFixedPoint(x, x);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                result = PRBMath.mulDivFixedPoint(result, x);
            }
        }
    }

    /// @notice Returns 1 as an unsigned 60.18-decimal fixed-point number.
    function scale() internal pure returns (uint256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x must be less than MAX_UD60x18 / SCALE.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as an unsigned 60.18-decimal fixed-point .
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two unsigned
            // 60.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = PRBMath.sqrt(x * SCALE);
        }
    }

    /// @notice Converts a unsigned 60.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The unsigned 60.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "@prb/math/contracts/PRBMathUD60x18.sol";

import "../../interfaces/adapters/yearn/IVaultWrapper.sol";
import {ReaperAPI, IReaperStrategy} from "../../interfaces/adapters/yearn/ReaperAPI.sol";

import "../../interfaces/IERC4626.sol";
import {FixedPointMathLib} from "../../lib/FixedPointMathLib.sol";
import "../../lib/ABDKMathQuad.sol";

import "../../lib/FullMath.sol";


import "hardhat/console.sol";

// ReaperWrapper is identical to the existing YearnWrapper, but since the Reaper contracts
// are written is solidity they don't get to take advantage of default params.
contract ReaperWrapper is ERC20, IVaultWrapper, IERC4626 {

    using SafeERC20 for IERC20;
    using FixedPointMathLib for uint;
    using PRBMathUD60x18 for uint;
    using ABDKMathQuad for *;

    ReaperAPI public immutable yVault;
    address public immutable token;
    uint256 public immutable _decimals;

    uint private constant PRECISION = 1E27;
    uint private constant HALF_PRECISION = 5E26;

    constructor(address _vault)
        ERC20(
            "Reaper-4646-Adapter",
            "Reaper-4646"
        )
    {
        yVault = ReaperAPI(_vault);
        token = yVault.token();
        _decimals = uint8(yVault.decimals());
        IERC20(token).approve(address(yVault), type(uint).max);
    }

    function vault() external view returns (address) {
        return address(yVault);
    }

    // NOTE: this number will be different from this token's totalSupply
    function vaultTotalSupply() external view returns (uint256) {
        return yVault.totalSupply();
    }

    /*//////////////////////////////////////////////////////////////
                      ERC20 compatibility
   //////////////////////////////////////////////////////////////*/

    function decimals() public view override(ERC20,IERC4626) returns (uint8) {
        return uint8(_decimals);
    }

    function asset() external view override returns (address) {
        return token;
    }

    /*//////////////////////////////////////////////////////////////
                      DEPOSIT/WITHDRAWAL LOGIC
  //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver)
        public
        override
        returns (uint256 shares)
    {
        (assets, shares) = _deposit(assets, receiver, msg.sender);
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function mint(uint256 shares, address receiver)
        public
        override
        returns (uint256 assets)
    {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        (assets, shares) = _deposit(assets, receiver, msg.sender);


        emit Deposit(msg.sender, receiver, assets, shares);
    }

    // TODO: add allowance check to use owner argument
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override returns (uint256 shares) {
        (uint256 _withdrawn, uint256 _burntShares) = _withdraw(
            assets,
            receiver,
            msg.sender
        );

        emit Withdraw(msg.sender, receiver, owner, _withdrawn, _burntShares);
        return _burntShares;
    }

    // TODO: add allowance check to use owner argument
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override returns (uint256 assets) {
        require(shares != 0, "ZERO_SHARES");

        (uint256 _withdrawn, uint256 _burntShares) = _redeem(
            shares,
            receiver,
            msg.sender
        );

        emit Withdraw(msg.sender, receiver, owner, _withdrawn, _burntShares);
        assets = _withdrawn;
    }

    /*//////////////////////////////////////////////////////////////
                          ACCOUNTING LOGIC
  //////////////////////////////////////////////////////////////*/

    function totalAssets() public view override returns (uint256) {
        return yVault.totalAssets();
    }

    function convertToShares(uint256 assets)
        public
        view
        override
        returns (uint256)
    {
        uint supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.
        uint localAssets = convertYearnSharesToAssets(yVault.balanceOf(address(this)));
        return supply == 0 ? assets : assets.mulDivDown(supply, localAssets); 
    }

    function convertToAssets(uint256 shares) public view override returns (uint assets) {
        uint supply = totalSupply();
        uint localAssets = convertYearnSharesToAssets(yVault.balanceOf(address(this)));
        return supply == 0 ? shares : shares.mulDivDown(localAssets, supply);
    }


    // Each pair is functionally the same?? Just intented for different contexts?
    function previewDeposit(uint256 assets)
        public
        view
        override
        returns (uint256 shares)
    {
        return convertToShares(assets);
    }

    function previewWithdraw(uint256 assets)
        public
        view
        override
        returns (uint256 shares)
    {       
        ReaperAPI _vault = yVault;
        uint adjustedAmount;
        {
            IReaperStrategy strat = IReaperStrategy(_vault.strategy());
            uint securityFee = strat.securityFee();
            uint DIVISOR = strat.PERCENT_DIVISOR();
            adjustedAmount = assets.mulDivUp(DIVISOR, DIVISOR - securityFee);
        }

        uint yearnShares = _vault.balanceOf(address(this)).fromUint();
        uint yearnSupply = _vault.totalSupply().fromUint(); 
        uint localAssets = yearnSupply == 0 ? yearnShares : yearnShares.mul(_vault.balance().fromUint().div(yearnSupply));   
        localAssets = localAssets.toUint();     
        
        // Actual division result: 137162292780573749444.22899888592124765312 (preferred to round down here actually)
        uint supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.

        // Order matters a lot HERE
        shares = localAssets == 0 ? adjustedAmount : adjustedAmount.mulDivUp(supply, localAssets);
    }

    //takes shares you want to mint and returns number of assets needed to mint it
    function previewMint(uint256 shares)
        public
        view
        override
        returns (uint256 assets)
    {
        uint supply = totalSupply();
        uint localAssets = convertYearnSharesToAssets(yVault.balanceOf(address(this)));
        return supply == 0 ? shares : shares.mulDivUp(localAssets, supply);
    }

    function previewRedeem(uint256 shares)
        public
        view
        override
        returns (uint256 assets)
    {
        ReaperAPI _vault = yVault;
        uint ySupply = _vault.balanceOf(address(this)); 
        uint yearnShares = ySupply == 0 ? shares : shares.mulDivDown(ySupply, totalSupply());
        yearnShares = Math.min(_vault.balanceOf(address(this)), yearnShares);
        assets = convertYearnSharesToAssets(yearnShares);
        IReaperStrategy strat = IReaperStrategy(yVault.strategy());
        uint securityFee = strat.securityFee();
        uint DIVISOR = strat.PERCENT_DIVISOR();
        assets -= assets.mulDivUp(securityFee, DIVISOR);
    }

    /*//////////////////////////////////////////////////////////////
                    DEPOSIT/WITHDRAWAL LIMIT LOGIC
  //////////////////////////////////////////////////////////////*/
    
    /// TODO: REVISIT THESE DEPOSIT METHODS

    function maxDeposit(address _account)
        public
        view
        override
        returns (uint256)
    {
        ReaperAPI _bestVault = yVault;
        uint256 _totalAssets = _bestVault.balance();
        uint256 _depositLimit = _bestVault.tvlCap();
        if (_totalAssets >= _depositLimit) return 0;
        return _depositLimit - _totalAssets;
    }

    
    function maxMint(address _account)
        external
        view
        override
        returns (uint256)
    {
        return convertToShares(maxDeposit(_account));
    }

   
    function maxWithdraw(address owner)
        external
        view
        override
        returns (uint256)
    {
        return convertToAssets(this.balanceOf(owner));
    }

    
    function maxRedeem(address owner) external view override returns (uint256) {
        return this.balanceOf(owner);
    }

    function _deposit(
        uint256 amount, // if `MAX_UINT256`, just deposit everything
        address receiver,
        address depositor
    ) internal returns (uint256 deposited, uint256 mintedShares) {
        IERC20 _token = IERC20(token);

        if (amount == type(uint256).max) {
            amount = Math.min(
                _token.balanceOf(depositor),
                _token.allowance(depositor, address(this))
            );
        }

        _token.safeTransferFrom(depositor, address(this), amount);

        uint _allowance = _token.allowance(address(this), address(yVault));
        if (_allowance < amount) {
            if (_allowance > 0) {
                _token.safeApprove(address(yVault), 0);
            }
            _token.safeApprove(address(yVault), type(uint256).max);
        }
        // beforeDeposit custom logic

        uint256 beforeTokenBal = _token.balanceOf(address(this));
        mintedShares = previewDeposit(amount);
        yVault.deposit(amount);

        uint256 afterBal = _token.balanceOf(address(this));
        deposited = beforeTokenBal - afterBal;

        require(deposited >= amount, "All assets not deposited");
        // afterDeposit custom logic
        _mint(receiver, mintedShares);
    }

    function _withdraw(
        uint256 amount, // if `MAX_UINT256`, just withdraw everything
        address receiver,
        address sender
    ) internal returns (uint256 assets, uint256 shares) {
        IERC20 _token = IERC20(token);
        ReaperAPI _vault = yVault;
        uint adjustedAmount;
        {
            IReaperStrategy strat = IReaperStrategy(_vault.strategy());
            uint securityFee = strat.securityFee();
            uint DIVISOR = strat.PERCENT_DIVISOR();
            console.log('securityFee: ', securityFee);
            console.log('securityFee: ', DIVISOR);
            adjustedAmount = amount.mulDivUp(DIVISOR, DIVISOR - securityFee);
            console.log('adjustedAmount: ', adjustedAmount); //1000000000000937125
        }
        
        // In some cases, this still underreports - WHY??
        shares = upConvertToShares(adjustedAmount); 
        console.log("Shares to be burnt: ", shares);
        
        uint yearnShares = convertAssetsToYearnShares(adjustedAmount);

        
        console.log("Balance of yearn shares: ", _vault.balanceOf(address(this)));
        console.log("Yearn shares to be burnt: ", yearnShares);

        uint senderBal = balanceOf(sender);
        console.log("Sender shares balance: ", senderBal);
        console.log("Adapter shares: ", shares);
        // This really should be part of it, but for some reason, math checks out

        if (shares > senderBal) {
            revert NotEnoughAvailableSharesForAmount();
        }
                
        if(yearnShares == 0 || shares == 0) {
            revert NoAvailableShares();
        }

        uint beforeYearnBal = _vault.balanceOf(address(this));

        _burn(sender, shares);

        // withdraw from vault and get total used shares
        _vault.withdraw(yearnShares);
        assets = _token.balanceOf(address(this));

        console.log("sender bal was: ", senderBal);
        console.log("assets are: ", assets);
        console.log("amount is: ", amount);
        console.log("shares are: ", shares);
        console.log("Predicted Yearn shares: ", yearnShares);
        console.log("Before yearn bal", beforeYearnBal);
        console.log("Burned Yearn shares: ", beforeYearnBal - _vault.balanceOf(address(this)));

        if(assets < amount) {
            revert NotEnoughAvailableSharesForAmount();
        }
        _token.safeTransfer(receiver, assets);
    }

    // TODO: FIX
    function _redeem(
        uint256 shares, 
        address receiver,
        address sender
    ) internal returns (uint256 assets, uint256 sharesBurnt) {
        IERC20 _token = IERC20(token);
        ReaperAPI _vault = yVault;
        uint yearnShares = convertSharesToYearnShares(shares);

        yearnShares = Math.min(_vault.balanceOf(address(this)), yearnShares);

        if(yearnShares == 0 || shares == 0) {
            revert NoAvailableShares();
        }

        _burn(sender, shares);
        sharesBurnt = shares;

        // withdraw from vault and get total used shares
        uint beforeTokenBal = _token.balanceOf(address(this));
        _vault.withdraw(yearnShares);
        assets = _token.balanceOf(address(this)) - beforeTokenBal;
        _token.safeTransfer(receiver, assets);
    }


    ///
    /// VIEW METHODS
    ///


    function convertAssetsToYearnShares(uint assets) internal view returns (uint yShares) {
        ReaperAPI _vault = yVault;
        uint256 totalYearnShares = _vault.totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.
        uint totalYearnAssets = _vault.balance();
        return totalYearnAssets == 0 ? assets : assets.mulDivUp(totalYearnShares, totalYearnAssets);
    }

    function convertYearnSharesToAssets(uint yearnShares) internal view returns (uint assets) {
        ReaperAPI _vault = yVault;
        uint supply = _vault.totalSupply();
        return supply == 0 ? yearnShares : yearnShares * _vault.balance() / supply;
    }

    function convertSharesToYearnShares(uint shares) internal view returns (uint yShares) {
        ReaperAPI _vault = yVault;
        uint supply = totalSupply(); 
        return supply == 0 ? shares : shares.mulDivUp(_vault.balanceOf(address(this)), totalSupply());
    }

    //1000000000000004711
    function upConvertToShares(uint256 assets) internal view returns (uint shares)
    {
        ReaperAPI _vault = yVault;
        uint yearnShares = _vault.balanceOf(address(this)).fromUint();
        uint yearnSupply = _vault.totalSupply().fromUint(); 
        uint localAssets = yearnSupply == 0 ? yearnShares : yearnShares.mul(_vault.balance().fromUint().div(yearnSupply));        
        
        // Actual division result: 137162292780573749444.22899888592124765312 (preferred to round down here actually)
        uint supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.

        // Order matters a lot HERE
        shares = supply == 0 ? assets : assets.mulDivUp(supply, localAssets.toUint());

        console.log("yearn shares: ", yearnShares); //131342545369752666136
        console.log("yearn supply: ", yearnSupply); //618232536613632826746679 
        console.log("Local assets: ", localAssets); //137162292780573749444 (good agreement) 
        console.log("Share supply: ", supply); // 137199085241083560000
        console.log("Shares are: ", shares);
    }

    function allowance(address owner, address spender) public view virtual override(ERC20,IERC4626) returns (uint256) {
        return super.allowance(owner,spender);
    }

    function balanceOf(address account) public view virtual override(ERC20,IERC4626) returns (uint256) {
        return super.balanceOf(account);
    }

    function name() public view virtual override(ERC20,IERC4626) returns (string memory) {
        return super.name();
    }

    function symbol() public view virtual override(ERC20,IERC4626) returns (string memory) {
        return super.symbol();
    }

    function totalSupply() public view virtual override(ERC20,IERC4626) returns (uint256) {
        return super.totalSupply();
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}


interface ReaperAPI is IERC20 {

    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function decimals() external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);

    function deposit(uint256 amount) external;
    function depositLimit() external view returns (uint256);

    function withdraw(uint256 maxShares) external;

    function token() external view returns (address);

    function pricePerShare() external view returns (uint256);
    function getPricePerFullShare() external view returns (uint256);
    function balance() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function strategy() external view returns (address);
    
    function tvlCap() external view returns (uint256);


}

interface IReaperStrategy {

    function securityFee() external view returns (uint fee);
    function PERCENT_DIVISOR() external view returns (uint);

}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math Quad Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with IEEE 754
 * quadruple-precision binary floating-point numbers (quadruple precision
 * numbers).  As long as quadruple precision numbers are 16-bytes long, they are
 * represented by bytes16 type.
 */
library ABDKMathQuad {
  /*
   * 0.
   */
  bytes16 private constant POSITIVE_ZERO = 0x00000000000000000000000000000000;

  /*
   * -0.
   */
  bytes16 private constant NEGATIVE_ZERO = 0x80000000000000000000000000000000;

  /*
   * +Infinity.
   */
  bytes16 private constant POSITIVE_INFINITY = 0x7FFF0000000000000000000000000000;

  /*
   * -Infinity.
   */
  bytes16 private constant NEGATIVE_INFINITY = 0xFFFF0000000000000000000000000000;

  /*
   * Canonical NaN value.
   */
  bytes16 private constant NaN = 0x7FFF8000000000000000000000000000;

  /**
   * Convert signed 256-bit integer number into quadruple precision number.
   *
   * @param x signed 256-bit integer number
   * @return quadruple precision number
   */
  function fromInt (int256 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        // We rely on overflow behavior here
        uint256 result = uint256 (x > 0 ? x : -x);

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;
        if (x < 0) result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into signed 256-bit integer number
   * rounding towards zero.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 256-bit integer number
   */
  function toInt (bytes16 x) internal pure returns (int256) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      require (exponent <= 16638); // Overflow
      if (exponent < 16383) return 0; // Underflow

      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16495) result >>= 16495 - exponent;
      else if (exponent > 16495) result <<= exponent - 16495;

      if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
        require (result <= 0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (result); // We rely on overflow behavior here
      } else {
        require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (result);
      }
    }
  }

  /**
   * Convert unsigned 256-bit integer number into quadruple precision number.
   *
   * @param x unsigned 256-bit integer number
   * @return quadruple precision number
   */
  function fromUInt (uint256 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        uint256 result = x;

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into unsigned 256-bit integer number
   * rounding towards zero.  Revert on underflow.  Note, that negative floating
   * point numbers in range (-1.0 .. 0.0) may be converted to unsigned integer
   * without error, because they are rounded to zero.
   *
   * @param x quadruple precision number
   * @return unsigned 256-bit integer number
   */
  function toUInt (bytes16 x) internal pure returns (uint256) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      if (exponent < 16383) return 0; // Underflow

      require (uint128 (x) < 0x80000000000000000000000000000000); // Negative

      require (exponent <= 16638); // Overflow
      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16495) result >>= 16495 - exponent;
      else if (exponent > 16495) result <<= exponent - 16495;

      return result;
    }
  }

  /**
   * Convert signed 128.128 bit fixed point number into quadruple precision
   * number.
   *
   * @param x signed 128.128 bit fixed point number
   * @return quadruple precision number
   */
  function from128x128 (int256 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        // We rely on overflow behavior here
        uint256 result = uint256 (x > 0 ? x : -x);

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16255 + msb << 112;
        if (x < 0) result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into signed 128.128 bit fixed point
   * number.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 128.128 bit fixed point number
   */
  function to128x128 (bytes16 x) internal pure returns (int256) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      require (exponent <= 16510); // Overflow
      if (exponent < 16255) return 0; // Underflow

      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16367) result >>= 16367 - exponent;
      else if (exponent > 16367) result <<= exponent - 16367;

      if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
        require (result <= 0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (result); // We rely on overflow behavior here
      } else {
        require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (result);
      }
    }
  }

  /**
   * Convert signed 64.64 bit fixed point number into quadruple precision
   * number.
   *
   * @param x signed 64.64 bit fixed point number
   * @return quadruple precision number
   */
  function from64x64 (int128 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        // We rely on overflow behavior here
        uint256 result = uint128 (x > 0 ? x : -x);

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16319 + msb << 112;
        if (x < 0) result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into signed 64.64 bit fixed point
   * number.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 64.64 bit fixed point number
   */
  function to64x64 (bytes16 x) internal pure returns (int128) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      require (exponent <= 16446); // Overflow
      if (exponent < 16319) return 0; // Underflow

      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16431) result >>= 16431 - exponent;
      else if (exponent > 16431) result <<= exponent - 16431;

      if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
        require (result <= 0x80000000000000000000000000000000);
        return -int128 (int256 (result)); // We rely on overflow behavior here
      } else {
        require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (int256 (result));
      }
    }
  }

  /**
   * Convert octuple precision number into quadruple precision number.
   *
   * @param x octuple precision number
   * @return quadruple precision number
   */
  function fromOctuple (bytes32 x) internal pure returns (bytes16) {
    unchecked {
      bool negative = x & 0x8000000000000000000000000000000000000000000000000000000000000000 > 0;

      uint256 exponent = uint256 (x) >> 236 & 0x7FFFF;
      uint256 significand = uint256 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (exponent == 0x7FFFF) {
        if (significand > 0) return NaN;
        else return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
      }

      if (exponent > 278526)
        return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
      else if (exponent < 245649)
        return negative ? NEGATIVE_ZERO : POSITIVE_ZERO;
      else if (exponent < 245761) {
        significand = (significand | 0x100000000000000000000000000000000000000000000000000000000000) >> 245885 - exponent;
        exponent = 0;
      } else {
        significand >>= 124;
        exponent -= 245760;
      }

      uint128 result = uint128 (significand | exponent << 112);
      if (negative) result |= 0x80000000000000000000000000000000;

      return bytes16 (result);
    }
  }

  /**
   * Convert quadruple precision number into octuple precision number.
   *
   * @param x quadruple precision number
   * @return octuple precision number
   */
  function toOctuple (bytes16 x) internal pure returns (bytes32) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      uint256 result = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (exponent == 0x7FFF) exponent = 0x7FFFF; // Infinity or NaN
      else if (exponent == 0) {
        if (result > 0) {
          uint256 msb = mostSignificantBit (result);
          result = result << 236 - msb & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          exponent = 245649 + msb;
        }
      } else {
        result <<= 124;
        exponent += 245760;
      }

      result |= exponent << 236;
      if (uint128 (x) >= 0x80000000000000000000000000000000)
        result |= 0x8000000000000000000000000000000000000000000000000000000000000000;

      return bytes32 (result);
    }
  }

  /**
   * Convert double precision number into quadruple precision number.
   *
   * @param x double precision number
   * @return quadruple precision number
   */
  function fromDouble (bytes8 x) internal pure returns (bytes16) {
    unchecked {
      uint256 exponent = uint64 (x) >> 52 & 0x7FF;

      uint256 result = uint64 (x) & 0xFFFFFFFFFFFFF;

      if (exponent == 0x7FF) exponent = 0x7FFF; // Infinity or NaN
      else if (exponent == 0) {
        if (result > 0) {
          uint256 msb = mostSignificantBit (result);
          result = result << 112 - msb & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          exponent = 15309 + msb;
        }
      } else {
        result <<= 60;
        exponent += 15360;
      }

      result |= exponent << 112;
      if (x & 0x8000000000000000 > 0)
        result |= 0x80000000000000000000000000000000;

      return bytes16 (uint128 (result));
    }
  }

  /**
   * Convert quadruple precision number into double precision number.
   *
   * @param x quadruple precision number
   * @return double precision number
   */
  function toDouble (bytes16 x) internal pure returns (bytes8) {
    unchecked {
      bool negative = uint128 (x) >= 0x80000000000000000000000000000000;

      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 significand = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (exponent == 0x7FFF) {
        if (significand > 0) return 0x7FF8000000000000; // NaN
        else return negative ?
            bytes8 (0xFFF0000000000000) : // -Infinity
            bytes8 (0x7FF0000000000000); // Infinity
      }

      if (exponent > 17406)
        return negative ?
            bytes8 (0xFFF0000000000000) : // -Infinity
            bytes8 (0x7FF0000000000000); // Infinity
      else if (exponent < 15309)
        return negative ?
            bytes8 (0x8000000000000000) : // -0
            bytes8 (0x0000000000000000); // 0
      else if (exponent < 15361) {
        significand = (significand | 0x10000000000000000000000000000) >> 15421 - exponent;
        exponent = 0;
      } else {
        significand >>= 60;
        exponent -= 15360;
      }

      uint64 result = uint64 (significand | exponent << 52);
      if (negative) result |= 0x8000000000000000;

      return bytes8 (result);
    }
  }

  /**
   * Test whether given quadruple precision number is NaN.
   *
   * @param x quadruple precision number
   * @return true if x is NaN, false otherwise
   */
  function isNaN (bytes16 x) internal pure returns (bool) {
    unchecked {
      return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF >
        0x7FFF0000000000000000000000000000;
    }
  }

  /**
   * Test whether given quadruple precision number is positive or negative
   * infinity.
   *
   * @param x quadruple precision number
   * @return true if x is positive or negative infinity, false otherwise
   */
  function isInfinity (bytes16 x) internal pure returns (bool) {
    unchecked {
      return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF ==
        0x7FFF0000000000000000000000000000;
    }
  }

  /**
   * Calculate sign of x, i.e. -1 if x is negative, 0 if x if zero, and 1 if x
   * is positive.  Note that sign (-0) is zero.  Revert if x is NaN. 
   *
   * @param x quadruple precision number
   * @return sign of x
   */
  function sign (bytes16 x) internal pure returns (int8) {
    unchecked {
      uint128 absoluteX = uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      require (absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

      if (absoluteX == 0) return 0;
      else if (uint128 (x) >= 0x80000000000000000000000000000000) return -1;
      else return 1;
    }
  }

  /**
   * Calculate sign (x - y).  Revert if either argument is NaN, or both
   * arguments are infinities of the same sign. 
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return sign (x - y)
   */
  function cmp (bytes16 x, bytes16 y) internal pure returns (int8) {
    unchecked {
      uint128 absoluteX = uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      require (absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

      uint128 absoluteY = uint128 (y) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      require (absoluteY <= 0x7FFF0000000000000000000000000000); // Not NaN

      // Not infinities of the same sign
      require (x != y || absoluteX < 0x7FFF0000000000000000000000000000);

      if (x == y) return 0;
      else {
        bool negativeX = uint128 (x) >= 0x80000000000000000000000000000000;
        bool negativeY = uint128 (y) >= 0x80000000000000000000000000000000;

        if (negativeX) {
          if (negativeY) return absoluteX > absoluteY ? -1 : int8 (1);
          else return -1; 
        } else {
          if (negativeY) return 1;
          else return absoluteX > absoluteY ? int8 (1) : -1;
        }
      }
    }
  }

  /**
   * Test whether x equals y.  NaN, infinity, and -infinity are not equal to
   * anything. 
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return true if x equals to y, false otherwise
   */
  function eq (bytes16 x, bytes16 y) internal pure returns (bool) {
    unchecked {
      if (x == y) {
        return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF <
          0x7FFF0000000000000000000000000000;
      } else return false;
    }
  }

  /**
   * Calculate x + y.  Special values behave in the following way:
   *
   * NaN + x = NaN for any x.
   * Infinity + x = Infinity for any finite x.
   * -Infinity + x = -Infinity for any finite x.
   * Infinity + Infinity = Infinity.
   * -Infinity + -Infinity = -Infinity.
   * Infinity + -Infinity = -Infinity + Infinity = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function add (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

      if (xExponent == 0x7FFF) {
        if (yExponent == 0x7FFF) { 
          if (x == y) return x;
          else return NaN;
        } else return x; 
      } else if (yExponent == 0x7FFF) return y;
      else {
        bool xSign = uint128 (x) >= 0x80000000000000000000000000000000;
        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        bool ySign = uint128 (y) >= 0x80000000000000000000000000000000;
        uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (yExponent == 0) yExponent = 1;
        else ySignifier |= 0x10000000000000000000000000000;

        if (xSignifier == 0) return y == NEGATIVE_ZERO ? POSITIVE_ZERO : y;
        else if (ySignifier == 0) return x == NEGATIVE_ZERO ? POSITIVE_ZERO : x;
        else {
          int256 delta = int256 (xExponent) - int256 (yExponent);
  
          if (xSign == ySign) {
            if (delta > 112) return x;
            else if (delta > 0) ySignifier >>= uint256 (delta);
            else if (delta < -112) return y;
            else if (delta < 0) {
              xSignifier >>= uint256 (-delta);
              xExponent = yExponent;
            }
  
            xSignifier += ySignifier;
  
            if (xSignifier >= 0x20000000000000000000000000000) {
              xSignifier >>= 1;
              xExponent += 1;
            }
  
            if (xExponent == 0x7FFF)
              return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
            else {
              if (xSignifier < 0x10000000000000000000000000000) xExponent = 0;
              else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  
              return bytes16 (uint128 (
                  (xSign ? 0x80000000000000000000000000000000 : 0) |
                  (xExponent << 112) |
                  xSignifier)); 
            }
          } else {
            if (delta > 0) {
              xSignifier <<= 1;
              xExponent -= 1;
            } else if (delta < 0) {
              ySignifier <<= 1;
              xExponent = yExponent - 1;
            }

            if (delta > 112) ySignifier = 1;
            else if (delta > 1) ySignifier = (ySignifier - 1 >> uint256 (delta - 1)) + 1;
            else if (delta < -112) xSignifier = 1;
            else if (delta < -1) xSignifier = (xSignifier - 1 >> uint256 (-delta - 1)) + 1;

            if (xSignifier >= ySignifier) xSignifier -= ySignifier;
            else {
              xSignifier = ySignifier - xSignifier;
              xSign = ySign;
            }

            if (xSignifier == 0)
              return POSITIVE_ZERO;

            uint256 msb = mostSignificantBit (xSignifier);

            if (msb == 113) {
              xSignifier = xSignifier >> 1 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
              xExponent += 1;
            } else if (msb < 112) {
              uint256 shift = 112 - msb;
              if (xExponent > shift) {
                xSignifier = xSignifier << shift & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                xExponent -= shift;
              } else {
                xSignifier <<= xExponent - 1;
                xExponent = 0;
              }
            } else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            if (xExponent == 0x7FFF)
              return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
            else return bytes16 (uint128 (
                (xSign ? 0x80000000000000000000000000000000 : 0) |
                (xExponent << 112) |
                xSignifier));
          }
        }
      }
    }
  }

  /**
   * Calculate x - y.  Special values behave in the following way:
   *
   * NaN - x = NaN for any x.
   * Infinity - x = Infinity for any finite x.
   * -Infinity - x = -Infinity for any finite x.
   * Infinity - -Infinity = Infinity.
   * -Infinity - Infinity = -Infinity.
   * Infinity - Infinity = -Infinity - -Infinity = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function sub (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      return add (x, y ^ 0x80000000000000000000000000000000);
    }
  }

  /**
   * Calculate x * y.  Special values behave in the following way:
   *
   * NaN * x = NaN for any x.
   * Infinity * x = Infinity for any finite positive x.
   * Infinity * x = -Infinity for any finite negative x.
   * -Infinity * x = -Infinity for any finite positive x.
   * -Infinity * x = Infinity for any finite negative x.
   * Infinity * 0 = NaN.
   * -Infinity * 0 = NaN.
   * Infinity * Infinity = Infinity.
   * Infinity * -Infinity = -Infinity.
   * -Infinity * Infinity = -Infinity.
   * -Infinity * -Infinity = Infinity.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function mul (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

      if (xExponent == 0x7FFF) {
        if (yExponent == 0x7FFF) {
          if (x == y) return x ^ y & 0x80000000000000000000000000000000;
          else if (x ^ y == 0x80000000000000000000000000000000) return x | y;
          else return NaN;
        } else {
          if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
          else return x ^ y & 0x80000000000000000000000000000000;
        }
      } else if (yExponent == 0x7FFF) {
          if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
          else return y ^ x & 0x80000000000000000000000000000000;
      } else {
        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (yExponent == 0) yExponent = 1;
        else ySignifier |= 0x10000000000000000000000000000;

        xSignifier *= ySignifier;
        if (xSignifier == 0)
          return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
              NEGATIVE_ZERO : POSITIVE_ZERO;

        xExponent += yExponent;

        uint256 msb =
          xSignifier >= 0x200000000000000000000000000000000000000000000000000000000 ? 225 :
          xSignifier >= 0x100000000000000000000000000000000000000000000000000000000 ? 224 :
          mostSignificantBit (xSignifier);

        if (xExponent + msb < 16496) { // Underflow
          xExponent = 0;
          xSignifier = 0;
        } else if (xExponent + msb < 16608) { // Subnormal
          if (xExponent < 16496)
            xSignifier >>= 16496 - xExponent;
          else if (xExponent > 16496)
            xSignifier <<= xExponent - 16496;
          xExponent = 0;
        } else if (xExponent + msb > 49373) {
          xExponent = 0x7FFF;
          xSignifier = 0;
        } else {
          if (msb > 112)
            xSignifier >>= msb - 112;
          else if (msb < 112)
            xSignifier <<= 112 - msb;

          xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

          xExponent = xExponent + msb - 16607;
        }

        return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
            xExponent << 112 | xSignifier));
      }
    }
  }

  /**
   * Calculate x / y.  Special values behave in the following way:
   *
   * NaN / x = NaN for any x.
   * x / NaN = NaN for any x.
   * Infinity / x = Infinity for any finite non-negative x.
   * Infinity / x = -Infinity for any finite negative x including -0.
   * -Infinity / x = -Infinity for any finite non-negative x.
   * -Infinity / x = Infinity for any finite negative x including -0.
   * x / Infinity = 0 for any finite non-negative x.
   * x / -Infinity = -0 for any finite non-negative x.
   * x / Infinity = -0 for any finite non-negative x including -0.
   * x / -Infinity = 0 for any finite non-negative x including -0.
   * 
   * Infinity / Infinity = NaN.
   * Infinity / -Infinity = -NaN.
   * -Infinity / Infinity = -NaN.
   * -Infinity / -Infinity = NaN.
   *
   * Division by zero behaves in the following way:
   *
   * x / 0 = Infinity for any finite positive x.
   * x / -0 = -Infinity for any finite positive x.
   * x / 0 = -Infinity for any finite negative x.
   * x / -0 = Infinity for any finite negative x.
   * 0 / 0 = NaN.
   * 0 / -0 = NaN.
   * -0 / 0 = NaN.
   * -0 / -0 = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function div (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

      if (xExponent == 0x7FFF) {
        if (yExponent == 0x7FFF) return NaN;
        else return x ^ y & 0x80000000000000000000000000000000;
      } else if (yExponent == 0x7FFF) {
        if (y & 0x0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF != 0) return NaN;
        else return POSITIVE_ZERO | (x ^ y) & 0x80000000000000000000000000000000;
      } else if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) {
        if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
        else return POSITIVE_INFINITY | (x ^ y) & 0x80000000000000000000000000000000;
      } else {
        uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (yExponent == 0) yExponent = 1;
        else ySignifier |= 0x10000000000000000000000000000;

        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) {
          if (xSignifier != 0) {
            uint shift = 226 - mostSignificantBit (xSignifier);

            xSignifier <<= shift;

            xExponent = 1;
            yExponent += shift - 114;
          }
        }
        else {
          xSignifier = (xSignifier | 0x10000000000000000000000000000) << 114;
        }

        xSignifier = xSignifier / ySignifier;
        if (xSignifier == 0)
          return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
              NEGATIVE_ZERO : POSITIVE_ZERO;

        assert (xSignifier >= 0x1000000000000000000000000000);

        uint256 msb =
          xSignifier >= 0x80000000000000000000000000000 ? mostSignificantBit (xSignifier) :
          xSignifier >= 0x40000000000000000000000000000 ? 114 :
          xSignifier >= 0x20000000000000000000000000000 ? 113 : 112;

        if (xExponent + msb > yExponent + 16497) { // Overflow
          xExponent = 0x7FFF;
          xSignifier = 0;
        } else if (xExponent + msb + 16380  < yExponent) { // Underflow
          xExponent = 0;
          xSignifier = 0;
        } else if (xExponent + msb + 16268  < yExponent) { // Subnormal
          if (xExponent + 16380 > yExponent)
            xSignifier <<= xExponent + 16380 - yExponent;
          else if (xExponent + 16380 < yExponent)
            xSignifier >>= yExponent - xExponent - 16380;

          xExponent = 0;
        } else { // Normal
          if (msb > 112)
            xSignifier >>= msb - 112;

          xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

          xExponent = xExponent + msb + 16269 - yExponent;
        }

        return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
            xExponent << 112 | xSignifier));
      }
    }
  }

  /**
   * Calculate -x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function neg (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return x ^ 0x80000000000000000000000000000000;
    }
  }

  /**
   * Calculate |x|.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function abs (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    }
  }

  /**
   * Calculate square root of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function sqrt (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      if (uint128 (x) >  0x80000000000000000000000000000000) return NaN;
      else {
        uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
        if (xExponent == 0x7FFF) return x;
        else {
          uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          if (xExponent == 0) xExponent = 1;
          else xSignifier |= 0x10000000000000000000000000000;

          if (xSignifier == 0) return POSITIVE_ZERO;

          bool oddExponent = xExponent & 0x1 == 0;
          xExponent = xExponent + 16383 >> 1;

          if (oddExponent) {
            if (xSignifier >= 0x10000000000000000000000000000)
              xSignifier <<= 113;
            else {
              uint256 msb = mostSignificantBit (xSignifier);
              uint256 shift = (226 - msb) & 0xFE;
              xSignifier <<= shift;
              xExponent -= shift - 112 >> 1;
            }
          } else {
            if (xSignifier >= 0x10000000000000000000000000000)
              xSignifier <<= 112;
            else {
              uint256 msb = mostSignificantBit (xSignifier);
              uint256 shift = (225 - msb) & 0xFE;
              xSignifier <<= shift;
              xExponent -= shift - 112 >> 1;
            }
          }

          uint256 r = 0x10000000000000000000000000000;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1; // Seven iterations should be enough
          uint256 r1 = xSignifier / r;
          if (r1 < r) r = r1;

          return bytes16 (uint128 (xExponent << 112 | r & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
        }
      }
    }
  }

  /**
   * Calculate binary logarithm of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function log_2 (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      if (uint128 (x) > 0x80000000000000000000000000000000) return NaN;
      else if (x == 0x3FFF0000000000000000000000000000) return POSITIVE_ZERO; 
      else {
        uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
        if (xExponent == 0x7FFF) return x;
        else {
          uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          if (xExponent == 0) xExponent = 1;
          else xSignifier |= 0x10000000000000000000000000000;

          if (xSignifier == 0) return NEGATIVE_INFINITY;

          bool resultNegative;
          uint256 resultExponent = 16495;
          uint256 resultSignifier;

          if (xExponent >= 0x3FFF) {
            resultNegative = false;
            resultSignifier = xExponent - 0x3FFF;
            xSignifier <<= 15;
          } else {
            resultNegative = true;
            if (xSignifier >= 0x10000000000000000000000000000) {
              resultSignifier = 0x3FFE - xExponent;
              xSignifier <<= 15;
            } else {
              uint256 msb = mostSignificantBit (xSignifier);
              resultSignifier = 16493 - msb;
              xSignifier <<= 127 - msb;
            }
          }

          if (xSignifier == 0x80000000000000000000000000000000) {
            if (resultNegative) resultSignifier += 1;
            uint256 shift = 112 - mostSignificantBit (resultSignifier);
            resultSignifier <<= shift;
            resultExponent -= shift;
          } else {
            uint256 bb = resultNegative ? 1 : 0;
            while (resultSignifier < 0x10000000000000000000000000000) {
              resultSignifier <<= 1;
              resultExponent -= 1;
  
              xSignifier *= xSignifier;
              uint256 b = xSignifier >> 255;
              resultSignifier += b ^ bb;
              xSignifier >>= 127 + b;
            }
          }

          return bytes16 (uint128 ((resultNegative ? 0x80000000000000000000000000000000 : 0) |
              resultExponent << 112 | resultSignifier & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
        }
      }
    }
  }

  /**
   * Calculate natural logarithm of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function ln (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return mul (log_2 (x), 0x3FFE62E42FEFA39EF35793C7673007E5);
    }
  }

  /**
   * Calculate 2^x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function pow_2 (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      bool xNegative = uint128 (x) > 0x80000000000000000000000000000000;
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (xExponent == 0x7FFF && xSignifier != 0) return NaN;
      else if (xExponent > 16397)
        return xNegative ? POSITIVE_ZERO : POSITIVE_INFINITY;
      else if (xExponent < 16255)
        return 0x3FFF0000000000000000000000000000;
      else {
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        if (xExponent > 16367)
          xSignifier <<= xExponent - 16367;
        else if (xExponent < 16367)
          xSignifier >>= 16367 - xExponent;

        if (xNegative && xSignifier > 0x406E00000000000000000000000000000000)
          return POSITIVE_ZERO;

        if (!xNegative && xSignifier > 0x3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
          return POSITIVE_INFINITY;

        uint256 resultExponent = xSignifier >> 128;
        xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xNegative && xSignifier != 0) {
          xSignifier = ~xSignifier;
          resultExponent += 1;
        }

        uint256 resultSignifier = 0x80000000000000000000000000000000;
        if (xSignifier & 0x80000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
        if (xSignifier & 0x40000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
        if (xSignifier & 0x20000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
        if (xSignifier & 0x10000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
        if (xSignifier & 0x8000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
        if (xSignifier & 0x4000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
        if (xSignifier & 0x2000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
        if (xSignifier & 0x1000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
        if (xSignifier & 0x800000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
        if (xSignifier & 0x400000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
        if (xSignifier & 0x200000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
        if (xSignifier & 0x100000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
        if (xSignifier & 0x80000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
        if (xSignifier & 0x40000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
        if (xSignifier & 0x20000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000162E525EE054754457D5995292026 >> 128;
        if (xSignifier & 0x10000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
        if (xSignifier & 0x8000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
        if (xSignifier & 0x4000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
        if (xSignifier & 0x2000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000162E43F4F831060E02D839A9D16D >> 128;
        if (xSignifier & 0x1000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
        if (xSignifier & 0x800000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
        if (xSignifier & 0x400000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
        if (xSignifier & 0x200000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
        if (xSignifier & 0x100000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
        if (xSignifier & 0x80000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
        if (xSignifier & 0x40000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
        if (xSignifier & 0x20000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
        if (xSignifier & 0x10000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
        if (xSignifier & 0x8000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
        if (xSignifier & 0x4000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
        if (xSignifier & 0x2000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
        if (xSignifier & 0x1000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
        if (xSignifier & 0x800000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
        if (xSignifier & 0x400000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
        if (xSignifier & 0x200000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000162E42FEFB2FED257559BDAA >> 128;
        if (xSignifier & 0x100000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
        if (xSignifier & 0x80000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
        if (xSignifier & 0x40000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
        if (xSignifier & 0x20000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
        if (xSignifier & 0x10000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000B17217F7D20CF927C8E94C >> 128;
        if (xSignifier & 0x8000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
        if (xSignifier & 0x4000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000002C5C85FDF477B662B26945 >> 128;
        if (xSignifier & 0x2000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000162E42FEFA3AE53369388C >> 128;
        if (xSignifier & 0x1000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000B17217F7D1D351A389D40 >> 128;
        if (xSignifier & 0x800000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
        if (xSignifier & 0x400000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
        if (xSignifier & 0x200000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000162E42FEFA39FE95583C2 >> 128;
        if (xSignifier & 0x100000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
        if (xSignifier & 0x80000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
        if (xSignifier & 0x40000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000002C5C85FDF473E242EA38 >> 128;
        if (xSignifier & 0x20000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000162E42FEFA39F02B772C >> 128;
        if (xSignifier & 0x10000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
        if (xSignifier & 0x8000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
        if (xSignifier & 0x4000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000002C5C85FDF473DEA871F >> 128;
        if (xSignifier & 0x2000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000162E42FEFA39EF44D91 >> 128;
        if (xSignifier & 0x1000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000B17217F7D1CF79E949 >> 128;
        if (xSignifier & 0x800000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
        if (xSignifier & 0x400000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
        if (xSignifier & 0x200000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000162E42FEFA39EF366F >> 128;
        if (xSignifier & 0x100000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000B17217F7D1CF79AFA >> 128;
        if (xSignifier & 0x80000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
        if (xSignifier & 0x40000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
        if (xSignifier & 0x20000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000162E42FEFA39EF358 >> 128;
        if (xSignifier & 0x10000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000B17217F7D1CF79AB >> 128;
        if (xSignifier & 0x8000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000058B90BFBE8E7BCD5 >> 128;
        if (xSignifier & 0x4000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000002C5C85FDF473DE6A >> 128;
        if (xSignifier & 0x2000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000162E42FEFA39EF34 >> 128;
        if (xSignifier & 0x1000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000B17217F7D1CF799 >> 128;
        if (xSignifier & 0x800000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000058B90BFBE8E7BCC >> 128;
        if (xSignifier & 0x400000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000002C5C85FDF473DE5 >> 128;
        if (xSignifier & 0x200000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000162E42FEFA39EF2 >> 128;
        if (xSignifier & 0x100000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000B17217F7D1CF78 >> 128;
        if (xSignifier & 0x80000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000058B90BFBE8E7BB >> 128;
        if (xSignifier & 0x40000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000002C5C85FDF473DD >> 128;
        if (xSignifier & 0x20000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000162E42FEFA39EE >> 128;
        if (xSignifier & 0x10000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000B17217F7D1CF6 >> 128;
        if (xSignifier & 0x8000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000058B90BFBE8E7A >> 128;
        if (xSignifier & 0x4000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000002C5C85FDF473C >> 128;
        if (xSignifier & 0x2000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000162E42FEFA39D >> 128;
        if (xSignifier & 0x1000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000B17217F7D1CE >> 128;
        if (xSignifier & 0x800000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000058B90BFBE8E6 >> 128;
        if (xSignifier & 0x400000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000002C5C85FDF472 >> 128;
        if (xSignifier & 0x200000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000162E42FEFA38 >> 128;
        if (xSignifier & 0x100000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000B17217F7D1B >> 128;
        if (xSignifier & 0x80000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000058B90BFBE8D >> 128;
        if (xSignifier & 0x40000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000002C5C85FDF46 >> 128;
        if (xSignifier & 0x20000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000162E42FEFA2 >> 128;
        if (xSignifier & 0x10000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000B17217F7D0 >> 128;
        if (xSignifier & 0x8000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000058B90BFBE7 >> 128;
        if (xSignifier & 0x4000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000002C5C85FDF3 >> 128;
        if (xSignifier & 0x2000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000162E42FEF9 >> 128;
        if (xSignifier & 0x1000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000B17217F7C >> 128;
        if (xSignifier & 0x800000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000058B90BFBD >> 128;
        if (xSignifier & 0x400000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000002C5C85FDE >> 128;
        if (xSignifier & 0x200000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000162E42FEE >> 128;
        if (xSignifier & 0x100000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000B17217F6 >> 128;
        if (xSignifier & 0x80000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000058B90BFA >> 128;
        if (xSignifier & 0x40000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000002C5C85FC >> 128;
        if (xSignifier & 0x20000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000162E42FD >> 128;
        if (xSignifier & 0x10000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000B17217E >> 128;
        if (xSignifier & 0x8000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000058B90BE >> 128;
        if (xSignifier & 0x4000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000002C5C85E >> 128;
        if (xSignifier & 0x2000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000162E42E >> 128;
        if (xSignifier & 0x1000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000B17216 >> 128;
        if (xSignifier & 0x800000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000058B90A >> 128;
        if (xSignifier & 0x400000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000002C5C84 >> 128;
        if (xSignifier & 0x200000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000162E41 >> 128;
        if (xSignifier & 0x100000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000B1720 >> 128;
        if (xSignifier & 0x80000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000058B8F >> 128;
        if (xSignifier & 0x40000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000002C5C7 >> 128;
        if (xSignifier & 0x20000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000162E3 >> 128;
        if (xSignifier & 0x10000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000B171 >> 128;
        if (xSignifier & 0x8000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000058B8 >> 128;
        if (xSignifier & 0x4000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000002C5B >> 128;
        if (xSignifier & 0x2000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000162D >> 128;
        if (xSignifier & 0x1000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000B16 >> 128;
        if (xSignifier & 0x800 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000058A >> 128;
        if (xSignifier & 0x400 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000002C4 >> 128;
        if (xSignifier & 0x200 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000161 >> 128;
        if (xSignifier & 0x100 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000000B0 >> 128;
        if (xSignifier & 0x80 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000057 >> 128;
        if (xSignifier & 0x40 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000002B >> 128;
        if (xSignifier & 0x20 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000015 >> 128;
        if (xSignifier & 0x10 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000000A >> 128;
        if (xSignifier & 0x8 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000004 >> 128;
        if (xSignifier & 0x4 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000001 >> 128;

        if (!xNegative) {
          resultSignifier = resultSignifier >> 15 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          resultExponent += 0x3FFF;
        } else if (resultExponent <= 0x3FFE) {
          resultSignifier = resultSignifier >> 15 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          resultExponent = 0x3FFF - resultExponent;
        } else {
          resultSignifier = resultSignifier >> resultExponent - 16367;
          resultExponent = 0;
        }

        return bytes16 (uint128 (resultExponent << 112 | resultSignifier));
      }
    }
  }

  /**
   * Calculate e^x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function exp (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return pow_2 (mul (x, 0x3FFF71547652B82FE1777D0FFDA0D23A));
    }
  }

  /**
   * Get index of the most significant non-zero bit in binary representation of
   * x.  Reverts if x is zero.
   *
   * @return index of the most significant non-zero bit in binary representation
   *         of x
   */
  function mostSignificantBit (uint256 x) private pure returns (uint256) {
    unchecked {
      require (x > 0);

      uint256 result = 0;

      if (x >= 0x100000000000000000000000000000000) { x >>= 128; result += 128; }
      if (x >= 0x10000000000000000) { x >>= 64; result += 64; }
      if (x >= 0x100000000) { x >>= 32; result += 32; }
      if (x >= 0x10000) { x >>= 16; result += 16; }
      if (x >= 0x100) { x >>= 8; result += 8; }
      if (x >= 0x10) { x >>= 4; result += 4; }
      if (x >= 0x4) { x >>= 2; result += 2; }
      if (x >= 0x2) result += 1; // No need to shift x anymore

      return result;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import "../../interfaces/adapters/yearn/IVaultWrapper.sol";
import {VaultAPI} from "../../interfaces/adapters/yearn/VaultAPI.sol";
import "../../interfaces/IERC4626.sol";
import {FixedPointMathLib} from "../../lib/FixedPointMathLib.sol";

import "hardhat/console.sol";

interface YearnGoviTest {
    function setDepositLimit(uint limit) external;
}

interface IYearnRegistry {
    function latestVault(address asset) external returns (address); 
}

// Needs to extract VaultAPI interface out of BaseStrategy to avoid collision
contract YearnWrapper is ERC20, IVaultWrapper, IERC4626, Ownable {
    VaultAPI public yVault;
    address public immutable token;
    IYearnRegistry public registry = IYearnRegistry(0x50c1a2eA0a861A967D9d0FFE2AE4012c2E053804);
    uint256 public immutable _decimals;
    
    using FixedPointMathLib for uint;
    using SafeERC20 for IERC20;

    constructor(VaultAPI _vault)
        ERC20(
            string(abi.encodePacked(_vault.name(), "-4646-Adapter")),
            string(abi.encodePacked(_vault.symbol(), "-4646"))
        )
    {
        yVault = _vault;
        token = yVault.token();
        _decimals = uint8(_vault.decimals());
    }

    function vault() external view returns (address) {
        return address(yVault);
    }

    /// @dev Verifies that the yearn registry has "_target" recorded as the asset's latest vault
    function migrate(address _target) external onlyOwner returns (address) {
        // verify _target is a valid address
        require(registry.latestVault(token) == _target, "Invalid migration target");

        // withdraw all shares, returns amount of want withdrawn
        uint assets = yVault.withdraw(type(uint).max);
        // migrate vault
        yVault = VaultAPI(_target);

        // Redeposit want into target vault
        yVault.deposit(assets);

        return _target;
    }

    // NOTE: this number will be different from this token's totalSupply
    function vaultTotalSupply() external view returns (uint256) {
        return yVault.totalSupply();
    }

    /*//////////////////////////////////////////////////////////////
                      ERC20 compatibility
   //////////////////////////////////////////////////////////////*/

    function decimals() public view override(ERC20,IERC4626) returns (uint8) {
        return uint8(_decimals);
    }

    function asset() external view override returns (address) {
        return token;
    }

    /*//////////////////////////////////////////////////////////////
                      DEPOSIT/WITHDRAWAL LOGIC
  //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver)
        public
        override
        returns (uint256 shares)
    {
        (assets, shares) = _deposit(assets, receiver, msg.sender);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function mint(uint256 shares, address receiver)
        public
        override
        returns (uint256 assets)
    {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        (assets, shares) = _deposit(assets, receiver, msg.sender);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    // TODO: add allowance check to use owner argument
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override returns (uint256 shares) {
        (uint256 _withdrawn, uint256 _burntShares) = _withdraw(
            assets,
            receiver,
            msg.sender
        );

        emit Withdraw(msg.sender, receiver, owner, _withdrawn, _burntShares);
        return _burntShares;
    }

    // TODO: add allowance check to use owner argument
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override returns (uint256 assets) {
        require(shares != 0, "ZERO_ASSETS");

        (uint256 _withdrawn, uint256 _burntShares) = _redeem(
            shares,
            receiver,
            msg.sender
        );

        emit Withdraw(msg.sender, receiver, owner, _withdrawn, _burntShares);
        return _withdrawn;
    }

    /*//////////////////////////////////////////////////////////////
                          ACCOUNTING LOGIC
  //////////////////////////////////////////////////////////////*/

    function totalAssets() public view override returns (uint256) {
        return convertYearnSharesToAssets(yVault.balanceOf(address(this)));
    }

    function convertToShares(uint256 assets)
        public
        view
        override
        returns (uint256)
    {
        uint supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.
        uint localAssets = convertYearnSharesToAssets(yVault.balanceOf(address(this)));
        return supply == 0 ? assets : assets.mulDivDown(supply, localAssets); 
    }

    function convertToAssets(uint256 shares)
        public
        view
        override
        returns (uint assets)
    {
        uint supply = totalSupply();
        uint localAssets = convertYearnSharesToAssets(yVault.balanceOf(address(this)));
        return supply == 0 ? shares : shares.mulDivDown(localAssets, supply);
    }

    function getFreeFunds() public view returns (uint256) {
        uint256 lockedFundsRatio = (block.timestamp - yVault.lastReport()) * yVault.lockedProfitDegradation();
        uint256 _lockedProfit = yVault.lockedProfit();

        uint256 DEGRADATION_COEFFICIENT = 10 ** 18;
        uint256 lockedProfit = lockedFundsRatio < DEGRADATION_COEFFICIENT ? 
            _lockedProfit - (lockedFundsRatio * _lockedProfit / DEGRADATION_COEFFICIENT)
            : 0; // hardcoded DEGRADATION_COEFFICIENT        
        return yVault.totalAssets() - lockedProfit;
    }

    
    function previewDeposit(uint256 assets)
        public
        view
        override
        returns (uint256)
    {
        return convertToShares(assets);
    }

    function previewWithdraw(uint256 assets)
        public
        view
        override
        returns (uint256)
    {
        uint supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.
        uint localAssets = convertYearnSharesToAssets(yVault.balanceOf(address(this)));
        return supply == 0 ? assets : assets.mulDivUp(supply, localAssets); 
    }

    function previewMint(uint256 shares)
        public
        view
        override
        returns (uint256)
    {
        uint supply = totalSupply();
        uint localAssets = convertYearnSharesToAssets(yVault.balanceOf(address(this)));
        return supply == 0 ? shares : shares.mulDivUp(localAssets, supply);
    }

    function previewRedeem(uint256 shares)
        public
        view
        override
        returns (uint256)
    {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                    DEPOSIT/WITHDRAWAL LIMIT LOGIC
  //////////////////////////////////////////////////////////////*/

    function maxDeposit(address _account)
        public
        view
        override
        returns (uint256)
    {
        _account; // TODO can acc custom logic per depositor
        VaultAPI _bestVault = yVault;
        uint256 _totalAssets = _bestVault.totalAssets();
        uint256 _depositLimit = _bestVault.depositLimit();
        if (_totalAssets >= _depositLimit) return 0;
        return _depositLimit - _totalAssets;
    }

    function maxMint(address _account)
        external
        view
        override
        returns (uint256)
    {
        return convertToShares(maxDeposit(_account));
    }

    function maxWithdraw(address owner)
        external
        view
        override
        returns (uint256)
    {
        return convertToAssets(this.balanceOf(owner));
    }

    function maxRedeem(address owner) external view override returns (uint256) {
        return this.balanceOf(owner);
    }

     function _deposit(
        uint256 amount, // if `MAX_UINT256`, just deposit everything
        address receiver,
        address depositor
    ) internal returns (uint256 deposited, uint256 mintedShares) {
        VaultAPI _vault = yVault;
        IERC20 _token = IERC20(token);

        if (amount == type(uint256).max) {
            amount = Math.min(
                _token.balanceOf(depositor),
                _token.allowance(depositor, address(this))
            );
        }

        _token.safeTransferFrom(depositor, address(this), amount);

        console.log("passed token transfer");

        uint _allowance = _token.allowance(address(this), address(_vault));
        if (_allowance < amount) {
            if (_allowance > 0) {
                _token.safeApprove(address(_vault), 0);
            }
            _token.safeApprove(address(_vault), type(uint256).max);
        }

        // beforeDeposit custom logic

        // Depositing returns number of shares deposited
        uint256 beforeBal = _token.balanceOf(address(this));

        mintedShares = previewDeposit(amount);

        console.log("previewed: ", mintedShares);
        console.log("Deposit limit: ", _vault.depositLimit());
        _vault.deposit(amount, address(this));

        console.log("minted shares: ", mintedShares);

        uint256 afterBal = _token.balanceOf(address(this));
        deposited = beforeBal - afterBal;

        // afterDeposit custom logic
        _mint(receiver, mintedShares);

    }

    function _withdraw(
        uint256 amount, // if `MAX_UINT256`, just withdraw everything
        address receiver,
        address sender
    ) internal returns (uint256 assets, uint256 shares) {
        VaultAPI _vault = yVault;
        shares = convertToShares(amount);
        uint yearnShares = convertAssetsToYearnShares(amount);
        if (shares > totalSupply()) {
            revert NotEnoughAvailableSharesForAmount();
        }

        shares = Math.min(balanceOf(sender), shares);
        
        if(yearnShares == 0 || shares == 0) {
            revert NoAvailableShares();
        }

        if (shares > totalSupply()) {
            revert NotEnoughAvailableSharesForAmount();
        }
        _burn(sender, shares);
        // withdraw from vault and get total used shares
        assets = _vault.withdraw(yearnShares, receiver, 0);
        require(assets == amount, "FAIL");
    }

    function _redeem(
        uint256 shares, 
        address receiver,
        address sender
    ) internal returns (uint256 assets, uint256 sharesBurnt) {
        VaultAPI _vault = yVault;
        uint yearnShares = convertSharesToYearnShares(shares);
        yearnShares = Math.min(_vault.balanceOf(address(this)), yearnShares);
        if(yearnShares == 0 || shares == 0) {
            revert NoAvailableShares();
        }
        _burn(sender, shares);
        sharesBurnt = shares;
        assets = _vault.withdraw(yearnShares, receiver, 0);
    }


    ///
    /// VIEW METHODS
    ///

    function convertAssetsToYearnShares(uint assets) internal view returns (uint yShares) {
        uint256 supply = yVault.totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.
        return supply == 0 ? assets : assets * supply / getFreeFunds();
    }

    function convertYearnSharesToAssets(uint yearnShares) internal view returns (uint assets) {
        uint supply = yVault.totalSupply();
        return supply == 0 ? yearnShares : yearnShares * getFreeFunds() / supply;
    }

    function convertSharesToYearnShares(uint shares) internal view returns (uint yShares) {
        uint supply = totalSupply(); 
        return supply == 0 ? shares : shares.mulDivUp(yVault.balanceOf(address(this)), totalSupply());
    }

    function allowance(address owner, address spender) public view virtual override(ERC20,IERC4626) returns (uint256) {
        return super.allowance(owner,spender);
    }

    function balanceOf(address account) public view virtual override(ERC20,IERC4626) returns (uint256) {
        return super.balanceOf(account);
    }

    function name() public view virtual override(ERC20,IERC4626) returns (string memory) {
        return super.name();
    }

    function symbol() public view virtual override(ERC20,IERC4626) returns (string memory) {
        return super.symbol();
    }

    function totalSupply() public view virtual override(ERC20,IERC4626) returns (uint256) {
        return super.totalSupply();
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;
import "../base/PermissionedAdapter.sol";
import "../../lib/ERC4626.sol";
import "../../lib/uniswap/IUniswapV2Router02.sol";
import "../../lib/uniswap/IUniswapV2Pair.sol";
import "../../lib/FixedPointMathLib.sol";
import "../../interfaces/IMasterChef.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract MasterChefAdapterManual is ERC4626, PermissionedAdapter {
    using SafeMath for uint256;
    using SafeTransferLib for ERC20;
    using SafeERC20 for IERC20;
    using FixedPointMathLib for uint256;
    using Address for address;

    address public wftm = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public rewardToken;
 
    address public uniRouter;
    address public masterChef;

    address public lpPair;
    address public lpToken0;
    address public lpToken1;

    address[] public rewardTokenToLp0Route;
    address[] public rewardTokenToLp1Route;

    uint lastCompound;
    uint256 poolId;

    constructor(
        ERC20 _asset,
        uint256 _poolId,
        address[] memory _rewardTokenToLp0Route,
        address[] memory _rewardTokenToLp1Route,
        address _uniRouter,
        address _masterChef,
        address _rewardToken
    ) ERC4626(_asset, "MasterChefAdapter", "MFA") { //TODO - Change those things
        
        //TODO - Ownership locks on contract

        lpPair = address(_asset);
        poolId = _poolId;

        lpToken0 = IUniswapV2Pair(lpPair).token0();
        lpToken1 = IUniswapV2Pair(lpPair).token1();

        rewardTokenToLp0Route = _rewardTokenToLp0Route;
        rewardTokenToLp1Route = _rewardTokenToLp1Route;

        uniRouter = _uniRouter;
        masterChef = _masterChef;

        rewardToken = _rewardToken;
        giveAllowances();

    }

    
    function harvest() external onlyValidHarvester {
        // require(!Address.isContract(msg.sender), "ER029");
        IMasterChef(masterChef).deposit(poolId, 0);
        addLiquidity();
        deposit();
    }

        /**
     * @dev Function that puts the funds to work. Can only be called by EOA or whitelisted contracts
     * It gets called whenever someone deposits in the strategy's vault contract.
     * It deposits {lpPair} in the masterChef to farm {rewardToken}
     */
    function deposit() public {
        uint256 pairBal = IERC20(lpPair).balanceOf(address(this));

        if (pairBal > 0) {
            IMasterChef(masterChef).deposit(poolId, pairBal);
        }

     
    }

    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function totalAssets() public view virtual override returns (uint256) {
        (uint256 amount, ) = IMasterChef(masterChef).userInfo(poolId, address(this));
        return amount;
    }

    function deposit(uint256 assets, address receiver) public virtual override returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function afterDeposit(uint256 assets, uint256) internal virtual override {
        uint256 pairBal = asset.balanceOf(address(this));

        if (pairBal > 0) {
            IMasterChef(masterChef).deposit(poolId, pairBal);
        }

    }

        /**
     * @dev Withdraws funds and sents them back to the vault.
     * It withdraws {lpPair} from the masterChef.
     * The available {lpPair} minus fees is returned to the vault.
     */
    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual override {
        // require(msg.sender == vault, "!vault");
        
        uint256 pairBal = IERC20(lpPair).balanceOf(address(this));

        if (pairBal < assets) {
            IMasterChef(masterChef).withdraw(poolId, assets.sub(pairBal));
        }

    }

        /**
     * @dev Swaps {rewardToken} for {lpToken0}, {lpToken1} & {wftm} using SpookySwap.
     */
    function addLiquidity() internal {
        uint256 rewardTokenHalf = IERC20(rewardToken).balanceOf(address(this)).div(2);

        if (lpToken0 != rewardToken) {
            IUniswapV2Router02(uniRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(rewardTokenHalf, 0, rewardTokenToLp0Route, address(this), block.timestamp.add(100));
        }

        if (lpToken1 != rewardToken) {
            IUniswapV2Router02(uniRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(rewardTokenHalf, 0, rewardTokenToLp1Route, address(this), block.timestamp.add(600));
        }

        uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));

        IUniswapV2Router02(uniRouter).addLiquidity(lpToken0, lpToken1, lp0Bal, lp1Bal, 1, 1, address(this), block.timestamp.add(600));
    
    }

     function giveAllowances() internal {
        IERC20(lpPair).safeApprove(masterChef, type(uint256).max);

        IERC20(rewardToken).safeApprove(uniRouter, 0);
        IERC20(rewardToken).safeApprove(uniRouter, type(uint256).max);

        IERC20(lpToken0).safeApprove(uniRouter, 0);
        IERC20(lpToken0).safeApprove(uniRouter, type(uint256).max);

        IERC20(lpToken1).safeApprove(uniRouter, 0);
        IERC20(lpToken1).safeApprove(uniRouter, type(uint256).max);
    }


}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;
import "../../lib/ERC4626.sol";
import "../../lib/uniswap/IUniswapV2Router02.sol";
import "../../lib/uniswap/IUniswapV2Pair.sol";
import "../../lib/FixedPointMathLib.sol";
import "../../interfaces/IMasterChef.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract MasterChefAdapter is ERC4626 {
    using SafeMath for uint256;
    using SafeTransferLib for ERC20;
    using SafeERC20 for IERC20;
    using FixedPointMathLib for uint256;
    using Address for address;

    address public wftm = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public rewardToken;
 
    address public uniRouter;
    address public masterChef;

    address public lpPair;
    address public lpToken0;
    address public lpToken1;

    address[] public rewardTokenToLp0Route;
    address[] public rewardTokenToLp1Route;

    uint lastCompound;
    uint256 poolId;

    constructor(
        ERC20 _asset,
        uint256 _poolId,
        address[] memory _rewardTokenToLp0Route,
        address[] memory _rewardTokenToLp1Route,
        address _uniRouter,
        address _masterChef,
        address _rewardToken
    ) ERC4626(_asset, "MasterChefAdapter", "MFA") { //TODO - Change those things
        
        //TODO - Ownership locks on contract

        lpPair = address(_asset);
        poolId = _poolId;

        lpToken0 = IUniswapV2Pair(lpPair).token0();
        lpToken1 = IUniswapV2Pair(lpPair).token1();

        rewardTokenToLp0Route = _rewardTokenToLp0Route;
        rewardTokenToLp1Route = _rewardTokenToLp1Route;

        uniRouter = _uniRouter;
        masterChef = _masterChef;

        rewardToken = _rewardToken;
        giveAllowances();

    }

    
    function harvest() public {
        // require(!Address.isContract(msg.sender), "ER029");
        IMasterChef(masterChef).deposit(poolId, 0);
        addLiquidity();
        deposit();
    }

        /**
     * @dev Function that puts the funds to work.
     * It gets called whenever someone deposits in the strategy's vault contract.
     * It deposits {lpPair} in the masterChef to farm {rewardToken}
     */
    function deposit() public {
        uint256 pairBal = IERC20(lpPair).balanceOf(address(this));

        if (pairBal > 0) {
            IMasterChef(masterChef).deposit(poolId, pairBal);
        }

     
    }

    function valueRewardTokens() public view virtual returns (uint256 lpTokens) {
        if (IERC20(rewardToken).balanceOf(address(this)) > 1) {
            uint256 rewardTokenHalf = IERC20(rewardToken).balanceOf(address(this)).div(2);

            (uint reserveA, uint reserveB,) = IUniswapV2Pair(lpPair).getReserves();

            //if reward token is half of the pair then getAmounts out will just be the same as the input
            uint256 amountToken0Out = lpToken0 == rewardToken ? rewardTokenHalf : IUniswapV2Router02(uniRouter).getAmountsOut(rewardTokenHalf, rewardTokenToLp0Route)[rewardTokenToLp0Route.length.sub(1)];
            uint256 amountToken1Out = lpToken1 == rewardToken ? rewardTokenHalf : IUniswapV2Router02(uniRouter).getAmountsOut(rewardTokenHalf, rewardTokenToLp1Route)[rewardTokenToLp1Route.length.sub(1)];

            uint256 totalSupply = asset.totalSupply();
            uint256 _kLast = IUniswapV2Pair(lpPair).kLast();
            uint256 newSupply;

            if (_kLast != 0) {
                uint rootK = FixedPointMathLib.sqrt(uint(reserveA).mul(reserveB));
                uint rootKLast = FixedPointMathLib.sqrt(_kLast);

                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) newSupply = totalSupply.add(liquidity);
                }
            }

            uint lpTokens0 = amountToken0Out.mulDivDown(newSupply, reserveA);
            uint lpTokens1 = amountToken1Out.mulDivDown(newSupply, reserveB);

            lpTokens = Math.min(lpTokens0, lpTokens1);
        }

        else return lpTokens = 0;
    }

    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function totalAssets() public view virtual override returns (uint256) {
        (uint256 amount, ) = IMasterChef(masterChef).userInfo(poolId, address(this));
        return amount + valueRewardTokens();
    }

    function deposit(uint256 assets, address receiver) public virtual override returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function afterDeposit(uint256 assets, uint256) internal virtual override {
        uint256 pairBal = asset.balanceOf(address(this));

        if (pairBal > 0) {
            IMasterChef(masterChef).deposit(poolId, pairBal);
        }

        if (IERC20(rewardToken).balanceOf(address(this)) > 1) {
            harvest();    
        }      

    }

        /**
     * @dev Withdraws funds and sents them back to the vault.
     * It withdraws {lpPair} from the masterChef.
     * The available {lpPair} minus fees is returned to the vault.
     */
    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual override {
        // require(msg.sender == vault, "!vault");
        if (IERC20(rewardToken).balanceOf(address(this)) > 1) {
            harvest();
        }

        uint256 pairBal = IERC20(lpPair).balanceOf(address(this));

        if (pairBal < assets) {
            IMasterChef(masterChef).withdraw(poolId, assets.sub(pairBal));
        }

    }

        /**
     * @dev Swaps {rewardToken} for {lpToken0}, {lpToken1} & {wftm} using SpookySwap.
     */
    function addLiquidity() internal {
        uint256 rewardTokenHalf = IERC20(rewardToken).balanceOf(address(this)).div(2);

        if (lpToken0 != rewardToken) {
            IUniswapV2Router02(uniRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(rewardTokenHalf, 0, rewardTokenToLp0Route, address(this), block.timestamp.add(100));
        }

        if (lpToken1 != rewardToken) {
            IUniswapV2Router02(uniRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(rewardTokenHalf, 0, rewardTokenToLp1Route, address(this), block.timestamp.add(600));
        }

        uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));

        IUniswapV2Router02(uniRouter).addLiquidity(lpToken0, lpToken1, lp0Bal, lp1Bal, 1, 1, address(this), block.timestamp.add(600));
    
    }

     function giveAllowances() internal {
        IERC20(lpPair).safeApprove(masterChef, type(uint256).max);

        IERC20(rewardToken).safeApprove(uniRouter, 0);
        IERC20(rewardToken).safeApprove(uniRouter, type(uint256).max);

        IERC20(lpToken0).safeApprove(uniRouter, 0);
        IERC20(lpToken0).safeApprove(uniRouter, type(uint256).max);

        IERC20(lpToken1).safeApprove(uniRouter, 0);
        IERC20(lpToken1).safeApprove(uniRouter, type(uint256).max);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "../ProviderAwareOracle.sol";
import "../../../lib/FixedPointMathLib.sol";


contract UniswapV2LPPriceOracle is ProviderAwareOracle {
    
    using FixedPointMathLib for uint;

    address public immutable WETH;

    /**
     * @dev sets up the Price Oracle
     * @param _weth wrapped mainnet token
     */
    constructor(address _weth, address _provider) ProviderAwareOracle(_provider) {
        WETH = _weth;
    }

    
    /****** OPERATIONAL METHODS ******/

    /**
     * @dev returns the TWAP for the provided pair as of the last update
     */
    function getSafePrice(address _lpToken) public view returns (uint) {
        return _getLPPrice(_lpToken, true);
    }

    /**
     * @dev returns the current "unsafe" price that can be easily manipulated
     */
    function getCurrentPrice(address _lpToken) external view returns (uint) {
        return _getLPPrice(_lpToken, false);
    }

    /**
     * @dev updates the TWAP (if enough time has lapsed) and returns the current safe price
     */
    function updateSafePrice(address _lpToken) external view returns (uint) {
        return getSafePrice(_lpToken);
    }

    // internal functions

    function _getLPPrice(address pair, bool isSafePrice) internal view returns (uint price) {
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint totalSupply = IUniswapV2Pair(pair).totalSupply();
        (uint r0, uint r1, ) = IUniswapV2Pair(pair).getReserves();
        uint8 dec0 = IERC20Metadata(token0).decimals();
        uint8 dec1 = IERC20Metadata(token1).decimals();
        uint sqrtR = (r0*r1 * (10 ** (36-dec0-dec1))).sqrt();
        
        uint p0 = isSafePrice ? provider.getSafePrice(token0) : provider.getCurrentPrice(token0);
        uint p1 = isSafePrice ? provider.getSafePrice(token1) : provider.getCurrentPrice(token1);
        uint sqrtP = (p0*p1).sqrt();
        price =(2*sqrtR*sqrtP) / totalSupply; // in 1E18 precision
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../../lib/FixedPoint.sol";
import "../../../lib/uniswap/IUniswapV2Factory.sol";
import "../../../interfaces/IERC20Detailed.sol";

import "../ProviderAwareOracle.sol";

/**
See https://github.com/Uniswap/v2-periphery/blob/master/contracts/examples/ExampleOracleSimple.sol
for the basis for the below contract. ExampleOracleSimple contract has been extended to support tracking multiple
pairs within the same contract.
*/

contract UniswapV2TWAPOracle is ProviderAwareOracle {
    using FixedPoint for *;

    struct TwapConfig {
        uint lastUpdateCumulativePrice;
        uint32 timestampLatest; // 4 bytes
        FixedPoint.uq112x112 lastUpdateTwapPrice; // 28 bytes
        // Should conform to IUniswapV2Pair interface
        address pairAddress; // 20 bytes
        bool isToken0; // 1 byte
        uint8 decimals; // 1 byte
    }

    /// The commonly-used asset tokens on this TWAP are paired with
    /// May be token0 or token1 depending on sort order
    address public immutable TOKEN;

    address public immutable WETH;

    // Maps token0 to it's latest readings
    mapping(address => TwapConfig) public twaps;

    // 5 minutes
    uint32 public constant MIN_UPDATE_DEFAULT = 5 minutes;
    uint32 public constant MAX_UPDATE = 60 minutes;

    uint32 public immutable MIN_UPDATE;

    address public uniswap;

    /**
     * @dev sets up the Price Oracle
     *
     * @param _inToken the "target" token that is paired with FTM/wFTM
     * @param _weth the WETH address for the given chain
     * @param _minimumUpdateInterval how often to permit updates to the TWAP (seconds)
     *                               If set to 0, will use the default of 5 minutes
     */
    constructor(address _provider, address _inToken, address _weth, uint32 _minimumUpdateInterval) ProviderAwareOracle(_provider) {
        require(_inToken != address(0) && _weth != address(0), "ER003");
        MIN_UPDATE = _minimumUpdateInterval == 0 ? MIN_UPDATE_DEFAULT : _minimumUpdateInterval;
        TOKEN = _inToken;
        WETH = _weth;
    }

    /****** OPERATIONAL METHODS ******/

    /**
     * @dev returns the TWAP for the provided pair as of the last update
     */
    function getSafePrice(address asset) public view returns (uint256 amountOut) {
        require(block.timestamp - twaps[asset].timestampLatest <= MAX_UPDATE, 'ER037');
        TwapConfig memory twap = twaps[asset];
        amountOut = _convertPrice(asset, twap.lastUpdateTwapPrice);
    }

    /**
     * @dev returns the current "unsafe" price that can be easily manipulated
     */
    function getCurrentPrice(address asset) public view returns (uint256 amountOut) {
        TwapConfig memory twap = twaps[asset];
        IUniswapV2Pair pair = IUniswapV2Pair(twap.pairAddress);

        uint8 decimals;

        try IERC20Detailed(asset).decimals() returns (uint8 numDecimals) {
            decimals = numDecimals;
        } catch {
            decimals = 18;
        }

        (uint reserve0, uint reserve1, ) = pair.getReserves();
      
        uint8 _token1MissingDecimals;
        if (twap.isToken0) {
                 if (decimals > IERC20Detailed(TOKEN).decimals()) {
                _token1MissingDecimals = decimals - (IERC20Detailed(TOKEN).decimals());
                amountOut = (reserve1 * (10**_token1MissingDecimals) * PRECISION) / reserve0;
            } else {

                _token1MissingDecimals = (IERC20Detailed(TOKEN).decimals()) - decimals;
                amountOut = (reserve1 * PRECISION) / (reserve0 * (10**_token1MissingDecimals));
            }    
        } else {
            if (decimals > IERC20Detailed(TOKEN).decimals()) {
                _token1MissingDecimals = decimals - (IERC20Detailed(TOKEN).decimals());
                amountOut = (reserve0 * (10**_token1MissingDecimals) * PRECISION) / reserve1;

            } else {
                _token1MissingDecimals = (IERC20Detailed(TOKEN).decimals()) - decimals;
                        // amountOut = (reserve0 * (10**_token1MissingDecimals) * PRECISION) / reserve1;
                amountOut = (reserve0 * PRECISION) / (reserve1 * (10**_token1MissingDecimals));

            }    
        }
        
        if(TOKEN != WETH) {
            amountOut = amountOut * provider.getSafePrice(TOKEN) / PRECISION;
        }
    }

    /**
     * @dev updates the TWAP (if enough time has lapsed) and returns the current safe price
     */
    function updateSafePrice(address asset) public returns (uint256 amountOut) {
        // This method will fail if the TWAP has not been initialized on this contract
        // This action must be performed externally
        (uint cumulativeLast, uint lastCumPrice, uint32 lastTimeSync, uint32 lastTimeUpdate) = _fetchParameters(asset);
        TwapConfig storage twap = twaps[asset];
        FixedPoint.uq112x112 memory lastAverage;
        lastAverage = FixedPoint.uq112x112(uint224((cumulativeLast - lastCumPrice) / (lastTimeSync - lastTimeUpdate)));
        twap.lastUpdateTwapPrice = lastAverage;
        twap.lastUpdateCumulativePrice = cumulativeLast;
        twap.timestampLatest = lastTimeSync;

        // Call sub method HERE to same thing getSafePrice uses to avoid extra SLOAD
        amountOut = _convertPrice(asset, lastAverage);
    }

    /****** INTERNAL METHODS ******/

    function _convertPrice(address asset, FixedPoint.uq112x112 memory lastUpdatePrice) private view returns (uint amountOut) {
        uint112 nativeDecimals = uint112(10**IERC20Metadata(asset).decimals());
        
        // calculate the value based upon the average cumulative prices
        // over the time period (TWAP)
        if (TOKEN == WETH) {
            // No need to convert the asset
            amountOut = FixedPoint.uq112x112(uint112(lastUpdatePrice.mul(nativeDecimals).decode144())).decode();
        } else {
            // Need to convert the feed to be in terms of ETH
            uint8 tokenDecimals = IERC20Metadata(TOKEN).decimals();
            uint conversion = provider.getSafePrice(TOKEN);
            // amountOut = FixedPoint.uq112x112(uint112(lastUpdatePrice.mul(uint144(10**tokenDecimals)).decode144())).div(nativeDecimals).decode();
            amountOut = FixedPoint.uq112x112(uint112(lastUpdatePrice.mul(nativeDecimals).decode144())).div(uint112(10**tokenDecimals)).decode();
            
            amountOut = amountOut * conversion;
        }
    }

    function _fetchParameters(
        address asset
    ) private view returns (
        uint cumulativeLast, 
        uint lastCumPrice, 
        uint32 lastTimeSync, 
        uint32 lastTimeUpdate
    ) {    
        TwapConfig memory twap = twaps[asset];
        require(twap.decimals > 0, 'ER035');
        // Enforce passage of a safe amount of time
        lastTimeUpdate = twap.timestampLatest;
        require(block.timestamp > lastTimeUpdate + MIN_UPDATE, 'ER036');
        IUniswapV2Pair pair = IUniswapV2Pair(twap.pairAddress);
        cumulativeLast = twap.isToken0 ? pair.price0CumulativeLast() : pair.price1CumulativeLast();
        lastCumPrice = twap.lastUpdateCumulativePrice;
        (, , lastTimeSync) = pair.getReserves();
    }

    function initializeOracle(address asset) external {
        require(asset != address(0), 'ER003');
        require(twaps[asset].decimals == 0, 'ER038');

        // Resolve Uniswap pair sorting order
        address token1 = asset < TOKEN ? TOKEN : asset;
        bool isToken0 = token1 != asset;
        address token0 = isToken0 ? asset : TOKEN;

        address pair = IUniswapV2Factory(uniswap).getPair(token0, token1);
        require(pair != address(0), 'ER003');
        IUniswapV2Pair uni_pair = IUniswapV2Pair(pair);        
        TwapConfig memory twap = TwapConfig(
            isToken0 ? uni_pair.price0CumulativeLast() : uni_pair.price1CumulativeLast(), 
            0,
            FixedPoint.uq112x112(0),
            pair, 
            isToken0, 
            IERC20Detailed(asset).decimals()
        );
        (, , twap.timestampLatest) = uni_pair.getReserves();
        twaps[asset] = twap;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x)
        internal
        pure
        returns (uq112x112 memory)
    {
        require(x != 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y)
        internal
        pure
        returns (uq144x112 memory)
    {
        uint256 z;
        require(
            y == 0 || (z = uint256(self._x) * y) / y == uint256(self._x),
            "FixedPoint: MULTIPLICATION_OVERFLOW"
        );
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator)
        internal
        pure
        returns (uq112x112 memory)
    {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../ProviderAwareOracle.sol";
import "../../interfaces/CurveTokenInterface.sol";
import "../../../lib/FixedPointMathLib.sol";

contract CurveLPOracle is ProviderAwareOracle {

    using FixedPointMathLib for uint;

    /// @notice Curve token version, currently support v1, v2 and v3
    enum CurveTokenVersion {
        V1,
        V2,
        V3
    }

    /// @notice Curve pool type, currently support ETH and USD base
    enum CurvePoolType {
        ETH,
        USD
    }

    struct CrvTokenInfo {
        /// @notice Check if this token is a curve pool token
        bool isCrvToken;
        /// @notice The curve pool type
        CurvePoolType poolType;
        /// @notice The curve swap contract address
        address curveSwap;
        uint nCoins;
    }

    event SetCurveToken(address token, CurvePoolType poolType, address swap, uint numberTokens);

    /// @notice Curve pool token data
    mapping(address => CrvTokenInfo) public crvTokens;

    address private immutable USDC;

    constructor(address _provider, address _usdc) ProviderAwareOracle(_provider) {
        USDC = _usdc;
    }

    function getSafePrice(address token) external view override returns (uint256 _amountOut) {
        _amountOut = getCrvTokenPrice(token);
    }

    /// @dev This method has no guarantee on the safety of the price returned. It should only be
    //used if the price returned does not expose the caller contract to flashloan attacks.
    function getCurrentPrice(address token) external view override returns (uint256 _amountOut) {
        _amountOut = getCrvTokenPrice(token);
    }

    /// @dev Gets the safe price, no updates necessary
    function updateSafePrice(address token) external view override returns (uint256 _amountOut) {
        _amountOut = getCrvTokenPrice(token);
    }

    /**
     * @notice Get price for curve pool tokens
     * @param token The curve pool token
     * @return The price
     */
    function getCrvTokenPrice(address token) internal view returns (uint256) {
        CrvTokenInfo memory crvTokenInfo = crvTokens[token];
        require(crvTokenInfo.isCrvToken, "not a curve pool token");

        uint256 virtualPrice = CurveSwapInterface(crvTokenInfo.curveSwap).get_virtual_price();

        if (crvTokenInfo.poolType == CurvePoolType.ETH) {
            return virtualPrice;
        }

        // We treat USDC as USD and convert the price to ETH base.
        return  provider.getSafePrice(USDC) * virtualPrice / PRECISION;
    }

    /**
     * @notice See assets as curve pool tokens for multiple tokens
     * @param tokenAddresses The list of tokens
     * @param poolType The list of curve pool type (ETH or USD base only)
     * @param swap The list of curve swap address
     */
    function setCurveTokens(
        address[] calldata tokenAddresses,
        CurveTokenVersion[] calldata version,
        CurvePoolType[] calldata poolType,
        address[] calldata swap,
        uint[] calldata nTokens
    ) external onlyOwner {
        require(
            tokenAddresses.length == version.length &&
                tokenAddresses.length == poolType.length &&
                tokenAddresses.length == swap.length,
            "mismatched data"
        );
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            if (version[i] == CurveTokenVersion.V3) {
                // Sanity check to make sure the token minter is right.
                require(CurveTokenV3Interface(tokenAddresses[i]).minter() == swap[i], "incorrect pool");
            }

            crvTokens[tokenAddresses[i]] = CrvTokenInfo({isCrvToken: true, poolType: poolType[i], curveSwap: swap[i],  nCoins: nTokens[i]});
            emit SetCurveToken(tokenAddresses[i], poolType[i], swap[i], nTokens[i]);
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface CurveTokenV3Interface {
    function minter() external view returns (address);
}

interface CurveSwapInterface {
    function get_virtual_price() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../ProviderAwareOracle.sol";

contract ChainlinkPriceOracle is ProviderAwareOracle {

    uint private constant MIN_TIME = 60 minutes;
    
    // If comparing to WETH, will be left as address(0)
    address public BASE_PRICE_FEED;

    uint8 public decimals = 18;

    mapping(address => address) public priceFeed; // token => chainlink price feed

    event UpdateValues(address indexed feed);
    event OutputDecimalsUpdated(uint8 _old, uint8 _new);
    event SetPriceFeed(address indexed token, address indexed feed);

    constructor(address _provider, address _base_price_feed) ProviderAwareOracle(_provider) {
        BASE_PRICE_FEED = _base_price_feed;
    }

    function setPriceFeed(address _token, address _feed) external onlyOwner {
        priceFeed[_token] = _feed;

        emit SetPriceFeed(_token, _feed);
    }

    function getSafePrice(address _token) public view returns (uint256 _amountOut) {
        return getCurrentPrice(_token);
    }

    function getCurrentPrice(address _token) public view returns (uint256 _amountOut) {
        require(priceFeed[_token] != address(0), "UNSUPPORTED");

        _amountOut = _divide(
            _feedPrice(priceFeed[_token]),
            _feedPrice(BASE_PRICE_FEED),
            decimals
        );
    }

    function setOutputDecimals(uint8 _decimals) public onlyOwner {
        uint8 _old = _decimals;
        decimals = _decimals;
        emit OutputDecimalsUpdated(_old, _decimals);
    }

    function updateSafePrice(address _feed) public returns (uint256 _amountOut) {
        emit UpdateValues(_feed); // keeps this mutable so it matches the interface

        return getCurrentPrice(_feed);
    }

    /****** INTERNAL METHODS ******/

    /**
     * @dev internal method that does quick division using the set precision
     */
    function _divide(
        uint256 a,
        uint256 b,
        uint8 precision
    ) internal pure returns (uint256) {
        return (a * (10**precision)) / b;
    }

    function _feedPrice(address _feed) internal view returns (uint256 latestUSD) {

        /// To allow for TOKEN-ETH feeds on one oracle, TOKEN-USD feeds on another
        if(_feed == address(0)) {
            return PRECISION;
        }

        (uint80 roundID, int256 answer, uint256 startedAt, uint256 timestamp, uint80 answeredInRound) = AggregatorV3Interface(_feed).latestRoundData();

        require(answer > 0, "E112"); 
        require(answeredInRound >= roundID, "E113a");
        require(timestamp != 0, "E113b");


        // difference between when started and returned needs to be less than 60-minutes
        // require(block.timestamp - timestamp < MIN_TIME, "E113c");
        // require(timestamp - startedAt < MIN_TIME, "E113d");
        // require(block.timestamp - startedAt < MIN_TIME, "E113d");
        require(block.timestamp - timestamp < MIN_TIME, "E113d");

        return uint256(answer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../ProviderAwareOracle.sol";
import "../../interfaces/IBalV2PriceOracle.sol";
import "../../interfaces/IBPoolV2.sol";
import "../../interfaces/IBVaultV2.sol";

contract BalancerV2PriceOracle is ProviderAwareOracle {

    address public immutable WETH;

    address public vault;
    uint256 public minimumUpdateInterval = 5 minutes;
    mapping(address => IPriceOracle) public denominatedOracles; // token => denominated oracle
    mapping(address => address) public tokenPools; // token => balancer pool

    event SetTokenOracle(
        address indexed token,
        address indexed tokenPool,
        address indexed denominatedOracle
    );

    /**
     * @dev sets up the Price Oracle
     * @param _provider Price provider
     * @param _vault balancer vault address
     * @param _minimumUpdateInterval how often to permit updates to the TWAP (seconds)
     *                               If set to 0, will use the default of 5 minutes
     */
    constructor(
        address _provider,
        address _vault,
        address _baseToken,
        uint256 _minimumUpdateInterval
    ) ProviderAwareOracle(_provider) {
        require(_vault != address(0), "vault cannot be null address");
        vault = _vault;
        if (_minimumUpdateInterval != 0) {
            minimumUpdateInterval = _minimumUpdateInterval;
        }
        WETH = _baseToken;
    }

    /**
     * @dev add/update token oracle setting
     */
    function setTokenOracle(
        address _token,
        address _tokenPool,
        address _denominatedOracle
    ) external onlyOwner {
        bytes32 poolId = IBPoolV2(_tokenPool).getPoolId();
        (IERC20[] memory tokens, , ) = IBVaultV2(vault).getPoolTokens(poolId);

        require(tokens.length == 2, "INVALID POOL");
        require(
            _token != WETH &&
                (_token == address(tokens[0]) || _token == address(tokens[1])),
            "INVALID TOKENS"
        );
        require(
            _denominatedOracle != address(0) ||
                WETH == address(tokens[0]) ||
                WETH == address(tokens[1])
        );

        denominatedOracles[_token] = IPriceOracle(_denominatedOracle);
        tokenPools[_token] = _tokenPool;

        emit SetTokenOracle(_token, _tokenPool, _denominatedOracle);
    }

    /****** OPERATIONAL METHODS ******/

    /**
     * @dev returns the TWAP for the provided pair as of the last update
     */
    function getSafePrice(address _token) public view returns (uint256 price) {
        require(tokenPools[_token] != address(0), "UNSUPPORTED");

        IBalV2PriceOracle.OracleAverageQuery[]
            memory query = new IBalV2PriceOracle.OracleAverageQuery[](1);
        query[0] = IBalV2PriceOracle.OracleAverageQuery(
            IBalV2PriceOracle.TWAP_VALUE.PAIR_PRICE,
            minimumUpdateInterval,
            10
        );
        uint256[] memory prices = IBalV2PriceOracle(tokenPools[_token])
            .getTimeWeightedAverage(query);
        uint256 tokenPairPrice = prices[0];

        bytes32 poolId = IBPoolV2(tokenPools[_token]).getPoolId();
        (IERC20[] memory tokens, , ) = IBVaultV2(vault).getPoolTokens(poolId);

        if (_token == address(tokens[0])) {
            price =
                (_getTokenSafePrice(denominatedOracles[_token], tokens[1]) * (10**18)) /
                tokenPairPrice;
        } else if (_token == address(tokens[1])) {
            price =
                (_getTokenSafePrice(denominatedOracles[_token], tokens[0]) *
                    tokenPairPrice) /
                (10**18);
        }
    }

    /**
     * @dev returns the current "unsafe" price that can be easily manipulated
     */
    function getCurrentPrice(address _token) external view returns (uint256 price) {
        require(tokenPools[_token] != address(0), "UNSUPPORTED");

        bytes32 poolId = IBPoolV2(tokenPools[_token]).getPoolId();
        uint256[] memory weights = IBPoolV2(tokenPools[_token]).getNormalizedWeights();
        (IERC20[] memory tokens, uint256[] memory balances, ) = IBVaultV2(vault)
            .getPoolTokens(poolId);

        if (_token == address(tokens[0])) {
            price = _tokenPriceFromWeights(
                tokens[0],
                tokens[1],
                balances[0],
                balances[1],
                weights[0],
                weights[1]
            );
        } else if (_token == address(tokens[1])) {
            price = _tokenPriceFromWeights(
                tokens[1],
                tokens[0],
                balances[1],
                balances[0],
                weights[1],
                weights[0]
            );
        }
    }

    /**
     * @dev updates the TWAP (if enough time has lapsed) and returns the current safe price
     */
    function updateSafePrice(address _token) external view returns (uint256) {
        return getSafePrice(_token);
    }

    // internal functions

    function _getTokenSafePrice(IPriceOracle oracle, IERC20 token)
        internal
        view
        returns (uint256 price)
    {
        if (WETH != address(token)) {
            price = IPriceOracle(oracle).getSafePrice(address(token));
        } else {
            price = PRECISION;
        }
    }

    function _getTokenCurrentPrice(IPriceOracle oracle, IERC20 token)
        internal
        view
        returns (uint256 price)
    {
        if (WETH != address(token)) {
            price = IPriceOracle(oracle).getCurrentPrice(address(token));
        } else {
            price = PRECISION;
        }
    }

    /**
     * @dev return token price (token0/token1)
     */
    function _tokenPriceFromWeights(
        IERC20 token0,
        IERC20 token1,
        uint256 balance0,
        uint256 balance1,
        uint256 weight0,
        uint256 weight1
    ) internal view returns (uint256) {
        uint256 pairTokenPrice = _getTokenCurrentPrice(
            IPriceOracle(denominatedOracles[address(token0)]),
            token1
        );

        // price = balance1 / balance0 * weight0 / weight1 * usdPrice1

        // in denominated token price decimals
        uint256 assetValue = (balance1 * pairTokenPrice) /
            (10**ERC20(address(token1)).decimals());
        // in denominated token price decimals
        // Division via multiplication rather than consecutive division
        return
            (assetValue * weight0 * (10**ERC20(address(token0)).decimals())) /
            (weight1 * balance0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;

interface IBalV2PriceOracle {
    // The three values that can be queried:
    //
    // - PAIR_PRICE: the price of the tokens in the Pool, expressed as the price of the second token in units of the
    //   first token. For example, if token A is worth $2, and token B is worth $4, the pair price will be 2.0.
    //   Note that the price is computed *including* the tokens decimals. This means that the pair price of a Pool with
    //   DAI and USDC will be close to 1.0, despite DAI having 18 decimals and USDC 6.
    //
    // - BPT_PRICE: the price of the Pool share token (BPT), in units of the first token.
    //   Note that the price is computed *including* the tokens decimals. This means that the BPT price of a Pool with
    //   USDC in which BPT is worth $5 will be 5.0, despite the BPT having 18 decimals and USDC 6.
    //
    // - INVARIANT: the value of the Pool's invariant, which serves as a measure of its liquidity.
    enum TWAP_VALUE {
        PAIR_PRICE,
        BPT_PRICE,
        INVARIANT
    }

    struct OracleAverageQuery {
        TWAP_VALUE variable;
        uint256 secs;
        uint256 ago;
    }

    /**
     * @dev Returns the time average weighted price corresponding to each of `queries`. Prices are represented as 18
     * decimal fixed point values.
     */
    function getTimeWeightedAverage(OracleAverageQuery[] memory queries)
        external
        view
        returns (uint256[] memory results);

    /**
     * @dev Returns latest sample of `variable`. Prices are represented as 18 decimal fixed point values.
     */
    function getLatest(TWAP_VALUE variable) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProviderAwareOracle.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleOracle is ProviderAwareOracle {

    mapping(address => mapping(address => bool)) public tokenAdmins;

    mapping(address => uint) private _currentPrices;

    event PriceUpdated(address indexed token, uint indexed price);
    event AdminStatusApproved(address indexed token, address indexed admin, bool indexed isApproved);

    modifier onlyAdmin(address token) {
        require(msg.sender == owner() || tokenAdmins[token][msg.sender], 'Unauthorized!');
        _;
    }

    constructor(address _provider) ProviderAwareOracle(_provider) {}

    function getSafePrice(address token) external view returns (uint256 _amountOut) {
        return _currentPrices[token];
    }

    /// @dev This method has no guarantee on the safety of the price returned. It should only be
    //used if the price returned does not expose the caller contract to flashloan attacks.
    function getCurrentPrice(address token) external view returns (uint256 _amountOut) {
        return _currentPrices[token];
    }

    /// @dev This method returns a flashloan resistant price, but doesn't
    //have the view modifier which makes it convenient to update
    //a uniswap oracle which needs to maintain the TWAP regularly.
    //You can use this function while doing other state changing tx and
    //make the callers maintain the oracle.
    function updateSafePrice(address token) external view returns (uint256 _amountOut) {
        return _currentPrices[token];
    }

    function updatePrice(address token, uint price) external onlyAdmin(token) {
        _currentPrices[token] = price;
        emit PriceUpdated(token, price);
    }

    function setAdminStatus(address token, address admin, bool isApproved) external onlyOwner {
        tokenAdmins[token][admin] = isApproved;
        emit AdminStatusApproved(token, admin, isApproved);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IPriceOracle.sol";
import "../interfaces/IPriceProvider.sol";
import "../interfaces/IERC20Detailed.sol";

contract PriceProvider is IPriceProvider, Ownable {

    uint private constant PRECISION = 1 ether;

    /// Maps a token address to an oracle
    mapping(address => address) public priceOracle;

    /**
     * @dev Constructor for the price oracle
     */
    constructor() {}

    function setTokenOracle(address token, address oracle) external onlyOwner {
        priceOracle[token] = oracle;

        emit SetTokenOracle(token, oracle);
    }

    function getSafePrice(address token) external view override returns (uint256) {
        require(priceOracle[token] != address(0), "UNSUPPORTED");

        return IPriceOracle(priceOracle[token]).getSafePrice(token);
    }

    function getCurrentPrice(address token) external view override returns (uint256) {
        require(priceOracle[token] != address(0), "UNSUPPORTED");

        return IPriceOracle(priceOracle[token]).getCurrentPrice(token);
    }

    function updateSafePrice(address token) external override returns (uint256) {
        require(priceOracle[token] != address(0), "UNSUPPORTED");

        return IPriceOracle(priceOracle[token]).updateSafePrice(token);
    }

    //get the value of token based on the price of quote
    function getValueOfAsset(address token, address quote) external view override returns (uint safePrice) {
        // Both token and quote must have oracles
        address tokenOracle = priceOracle[token];
        address quoteOracle = priceOracle[quote];
        require(tokenOracle != address(0), "UNSUPPORTED");
        require(quoteOracle != address(0), "UNSUPPORTED");

        uint tokenPriceToEth = IPriceOracle(tokenOracle).getSafePrice(token);
        uint quotePriceToEth = IPriceOracle(quoteOracle).getSafePrice(quote);
        // Prices should always be in 1E18 precision
        safePrice = PRECISION * tokenPriceToEth / quotePriceToEth;

        uint tokenDecimals = IERC20Detailed(token).decimals();
        uint quoteDecimals = IERC20Detailed(quote).decimals();
        if(tokenDecimals == quoteDecimals) {
            return safePrice;
        } 
        if(tokenDecimals > quoteDecimals) {
            // Adjust down by tokenDecimals - quoteDecimals
            safePrice /= (10 ** (tokenDecimals - quoteDecimals));
        } else {
            safePrice *= (10 ** (quoteDecimals - tokenDecimals));
        }
    }

    function tokenHasOracle(address token) public view override returns (bool hasOracle) {
        hasOracle = priceOracle[token] != address(0);
    }

    function pairHasOracle(address token, address quote) external view override returns (bool hasOracle) {
        hasOracle = tokenHasOracle(token) && tokenHasOracle(quote);
    }

}

// SPDX-License-Identifier: GNU-GPL

pragma solidity >=0.8.0;

import "./interfaces/IERC4626.sol";
import "./interfaces/IRevest.sol";
import "./interfaces/IFNFTHandler.sol";
import "./interfaces/IAddressRegistry.sol";
import "./interfaces/IPriceProvider.sol";
import "./interfaces/IERC20Detailed.sol";
import "./interfaces/IResonate.sol";
import "./interfaces/ISmartWalletWhitelistV2.sol";

import "./interfaces/ISmartWallet.sol";
import "./interfaces/IPoolWallet.sol";
import "./interfaces/IResonateHelper.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@rari-capital/solmate/src/utils/Bytes32AddressLib.sol";



/** @title Resonate. */
contract Resonate is IResonate, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using Bytes32AddressLib for address;
    using Bytes32Conversion for bytes32;

    ///
    /// Coefficients and Variable Declarations
    ///

    /// Precision for calculating rates
    uint private constant PRECISION = 1 ether;

    /// Denominator for fee calculations
    uint private constant DENOM = 100;

    /// Minimum deposit
    uint private constant MIN_DEPOSIT = 1E3;

    // uint32, address, address, address pack together to 64 bytes

    /// Minimum lockup period
    uint32 private constant MIN_LOCKUP = 1 days;

    /// The address to which fees are paid
    address private immutable DEV_ADDRESS;

    /// The Revest Address Registry
    address public immutable REGISTRY_ADDRESS;

    /// The OutputReceiver Proxy Address
    address public immutable PROXY_OUTPUT_RECEIVER;

    /// The fee numerator 
    uint32 private constant FEE = 5;

    /// The AddressLock Proxy Address
    address public immutable PROXY_ADDRESS_LOCK;

    /// The ResonateHelper address
    address public immutable override RESONATE_HELPER;

    /// The owner
    address public owner;

    /// Maps yield-farm address to adapter address
    mapping(address => address) public override vaultAdapters;

    /// Maps fnftIds to their relevant index
    mapping(uint => uint) public fnftIdToIndex;

    /// Contains all activated orders 
    mapping (uint => Active) public override activated;

    /// Mapping to residual interest for an interest-bearing FNFT
    mapping(uint => uint) public override residuals;

    /// Map poolIds to their respective configs
    mapping(bytes32 => PoolConfig) public override pools;

    /// Provider queue
    mapping(bytes32 => mapping(uint => Order)) public override providerQueue;

    /// Consumer queue
    mapping(bytes32 => mapping(uint => Order)) public override consumerQueue;

    /// Queue tracker mapping
    mapping(bytes32 => PoolQueue) public override queueMarkers;

    /// Maps contract address to assets it has approval to spend from this contract
    mapping (address => mapping (address => bool)) private _approvedContracts;

    /// The FNFTHandler address, immutable for increased decentralization
    IFNFTHandler private immutable FNFT_HANDLER;

    /// The SmartWalletWhitelist contract to control access
    ISmartWalletWhitelistV2 private immutable SMART_WALLET_WHITELIST;

    /// Oracle Tracker
    IPriceProvider private immutable PRICE_PROVIDER;

    /**
     * @notice the constructor for Resonate
     * @param _router the Revest AddressRegistry contract address
     * @param _proxyOutputReceiver the OutputReceiver proxy address to use for Resonate. 
     * @param _proxyAddressLock the AddressLock proxy address to use for Resonate. 
     * @param _resonateHelper the ResonateHelper address
     * @dev This should be called after the above three contracts have been deployed
     */
    constructor(
        address _router, 
        address _proxyOutputReceiver, 
        address _proxyAddressLock, 
        address _resonateHelper,
        address _smartWalletWhitelist,
        address _priceProvider,
        address _dev_address
    ) {
        require(
            _router != address(0) && 
            _proxyOutputReceiver != address(0) && 
            _proxyAddressLock != address(0) && 
            _resonateHelper != address(0) && 
            _smartWalletWhitelist != address(0) &&
            _priceProvider != address(0) &&
            _dev_address != address(0),
        'ER003');

        REGISTRY_ADDRESS = _router;

        PROXY_OUTPUT_RECEIVER = _proxyOutputReceiver;
        PROXY_ADDRESS_LOCK = _proxyAddressLock;
        RESONATE_HELPER = _resonateHelper;
        DEV_ADDRESS = _dev_address;
        FNFT_HANDLER = IFNFTHandler(IAddressRegistry(_router).getRevestFNFT());
        SMART_WALLET_WHITELIST = ISmartWalletWhitelistV2(_smartWalletWhitelist);
        PRICE_PROVIDER = IPriceProvider(_priceProvider);  

        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "ER024");
        _;
    }

    ///
    /// Transactional Functions
    ///

    /** 
     * @notice Creates a pool, only if it does not already exist
     * @param asset The payment asset for this pool. An oracle must exist if it is different than vaultAsset
     * @param vault The Vault to use. Should be the raw vault, not the adapter. If 4626, use the 4626 here
     * @param rate The upfront payout rate, in 1E18 precision
     * @param additionalRate The amount to add to the upfront rate to get the expected interest if fixed-income. Zero otherwise
     * @param lockupPeriod The amount of time the principal will be locked for if fixed-term. Zero otherwise
     * @param packetSize The standardized size of a single packet. Often measured in thousandths of a token
     * @param poolName The name of the pool. Will not be stored, only needed for Frontend display
     * @return poolId The poolId that the above parameters result in
     * @dev Cross-asset pools have more pre-conditions than others. This function will not deposit anything and follow-up operations are needed
     */
    function createPool(
        address asset,
        address vault, 
        uint128 rate,
        uint128 additionalRate,
        uint32 lockupPeriod, 
        uint packetSize,
        string calldata poolName
    ) external nonReentrant returns (bytes32 poolId) {
        address vaultAsset;
        {
            address adapter = vaultAdapters[vault];
            require(adapter != address(0), 'ER001');
            require(asset != address(0), 'ER001');
            require(packetSize > 0, 'ER023');
            require((lockupPeriod >= MIN_LOCKUP && additionalRate == 0) || (additionalRate > 0 && lockupPeriod == 0), 'ER008');
            vaultAsset = IERC4626(adapter).asset();
        }
        require(asset == vaultAsset || PRICE_PROVIDER.pairHasOracle(vaultAsset, asset), 'ER033');
        poolId = _initPool(asset, vault, rate, additionalRate, lockupPeriod, packetSize);
        _getWalletForPool(poolId);
        _getWalletForFNFT(poolId);
        emit PoolCreated(poolId, asset, vault, vaultAsset, rate, additionalRate, lockupPeriod, packetSize, lockupPeriod > 0 && additionalRate == 0, poolName, msg.sender);
    }

    /**
     * @notice This function allows a participant to enter a pool on the Issuer side
     * @param poolId the pool in which to enter
     * @param amount the amount of tokens to deposit to that side of the pool – will be rounded down to nearest packet
     * @dev Gas prices will be highly dependent on the presence of counter-parties on the opposite side of the pool 
     */
    function submitConsumer(bytes32 poolId, uint amount) external nonReentrant {
        // Common code
        PoolConfig memory pool = pools[poolId];
        require(amount > MIN_DEPOSIT, 'ER043');
        require(amount % pool.packetSize <= 5, 'ER005'); //be within 10 gwei to handle round-offs
        require(_validRecipient(), 'ER034');
        
        bool hasCounterparty = !_isQueueEmpty(poolId, true); // 2506 gas operation
        address vaultAsset;
        address adapter = pool.adapter;
        {
            IERC4626 vault = IERC4626(adapter);
            vaultAsset = vault.asset();
        }
        Order memory consumerOrder = Order(amount / pool.packetSize, 0, msg.sender.fillLast12Bytes());
        // return; // 42406
        if(hasCounterparty) {
            IPoolWallet wallet = _getWalletForPool(poolId); 
            uint currentExchange;
            if (pool.asset != vaultAsset) {
                currentExchange = PRICE_PROVIDER.getValueOfAsset(vaultAsset, pool.asset);
            }
            while(hasCounterparty && consumerOrder.packetsRemaining > 0) {
                // Pull object for counterparty at head of queue
                Order storage producerOrder = _peek(poolId, true); // Not sure if I can make this memory because of Reentrancy concerns
                if(pool.asset != vaultAsset) {
                    uint previousExchange = producerOrder.depositedShares;
                    if(currentExchange != previousExchange) { // This will almost always be true
                        uint maxPacketNumber = producerOrder.packetsRemaining * previousExchange / currentExchange; // 5
                        uint amountToRefund;
                        if(consumerOrder.packetsRemaining >= maxPacketNumber) {
                            if(currentExchange > previousExchange) {
                                // Position is partially or fully insolvent
                                amountToRefund = pool.rate * pool.packetSize / PRECISION * ((producerOrder.packetsRemaining  * currentExchange) - (maxPacketNumber * previousExchange)) / PRECISION;
                                amountToRefund /= consumerOrder.packetsRemaining;
                            } else {
                                // There will be a surplus in the position
                                amountToRefund = pool.rate * pool.packetSize / PRECISION * ((maxPacketNumber * previousExchange) - (producerOrder.packetsRemaining  * currentExchange)) / PRECISION;
                            }
                        }
                        
                        if(maxPacketNumber == 0) {
                            // Need to cancel the order because it is totally insolvent
                            // No storage update

                            amountToRefund = pool.rate * pool.packetSize * producerOrder.packetsRemaining / PRECISION * previousExchange / PRECISION;

                            address orderOwner = producerOrder.owner.toAddress();
                            _dequeue(poolId, true);
                            wallet.withdraw(amountToRefund, 0, pool.asset, orderOwner, address(0));

                            hasCounterparty = !_isQueueEmpty(poolId, true);
                            continue;
                        }
                        // Storage update
                        producerOrder.depositedShares = currentExchange;
                        producerOrder.packetsRemaining = maxPacketNumber;

                        if(amountToRefund > 0) {
                            wallet.withdraw(amountToRefund, 0, pool.asset, DEV_ADDRESS, address(0));
                            emit FeeCollection(poolId, amountToRefund);
                        }
                    }
                }
                if(producerOrder.owner.toAddress() == address(0)) {
                    // Order has previously been cancelled
                    // Dequeue and move on to next iteration
                    // No storage update
                    _dequeue(poolId, true);
                } else {
                    uint digestAmt;
                    {
                        uint consumerAmt = consumerOrder.packetsRemaining;
                        uint producerAmt = producerOrder.packetsRemaining;
                        digestAmt = producerAmt >= consumerAmt ? consumerAmt : producerAmt;
                    }
                    _activateCapital(ParamPacker(consumerOrder, producerOrder, false, pool.asset != vaultAsset, digestAmt, currentExchange, pool, adapter, poolId));
                    
                    consumerOrder.packetsRemaining -= digestAmt;
                    producerOrder.packetsRemaining -= digestAmt; // NB: Consider modification not via multiple storage methods, gas optimziation

                    amount -= (digestAmt * pool.packetSize);

                    // Handle _dequeue as needed 
                    if (producerOrder.packetsRemaining == 0) {
                        _dequeue(poolId, true);
                    }
                }
                // Check if queue is empty
                hasCounterparty = !_isQueueEmpty(poolId, true);
            }
        } 

        
        if(!hasCounterparty && consumerOrder.packetsRemaining > 0) {
            // No currently available trade, add this order to consumer queue
            _enqueue(poolId, false, true, consumerOrder, amount, vaultAsset, adapter);
        }
    }

    /**
     * @notice Allows a participant to enter a pool on the Purchaser side
     * @param poolId The ID of the pool in which to enter
     * @param amount The amount of tokens to deposit into the pool – will be rounded down to nearest packet
     * @param shouldFarm Whether or not to deposit the asset into a farm while it is queued. Not relevant if counter-party present or cross-asset pool
     * @dev shouldFarm is included to allow protocols to choose not to dilute their own yield farms while utilizing Resonate. It does not work for cross-assets
     */
    function submitProducer(bytes32 poolId, uint amount, bool shouldFarm) external nonReentrant {
        // Common code
        PoolConfig memory pool = pools[poolId];
        require(amount > MIN_DEPOSIT, 'ER043');
        require(_validRecipient(), 'ER034');
        
        Order memory producerOrder;

        bool hasCounterparty = !_isQueueEmpty(poolId, false);
        address vaultAsset;
        address adapter = pool.adapter;
        uint producerPacket;
        uint sharesPerPacket;
        // return; // 33635
        {
            IERC4626 vault = IERC4626(adapter);
            vaultAsset = vault.asset();
            if (vaultAsset == pool.asset) {
                sharesPerPacket = shouldFarm ? 1 : 0;
                producerPacket = pool.packetSize * pool.rate / PRECISION;
                // return; //39533
                require(amount % producerPacket < 5, 'ER006'); //This should fail, but it's not because amount is already 0
            } else { 
                shouldFarm = false;
                sharesPerPacket = PRICE_PROVIDER.getValueOfAsset(vaultAsset, pool.asset);
                producerPacket = pool.rate * pool.packetSize / PRECISION * sharesPerPacket / PRECISION; 
                amount = amount / producerPacket * producerPacket; // Is this a rounding operation?, would be safer to use modulo subtraction
                require(amount > 0, "ER003");
            }
            // Have relocated where deposits are made, are now towards end of workflow
            producerOrder = Order(uint112(amount/ producerPacket), sharesPerPacket, msg.sender.fillLast12Bytes());
        }
        // return; // 39809
        //Clone the smartWallet for the pool
        if (hasCounterparty) {
            while(hasCounterparty && producerOrder.packetsRemaining > 0) {
                // Pull object for counterparty at head of queue
                Order storage consumerOrder = _peek(poolId, false);
                // Check edge-case
                if(consumerOrder.owner.toAddress() == address(0)) {
                    // Order has previously been cancelled
                    // Dequeue and move on to next iteration
                    _dequeue(poolId, false);
                } else {
                    // Perform calculations in terms of number of packets
                    uint digestAmt;
                    {
                        uint producerAmt = producerOrder.packetsRemaining;
                        uint consumerAmt = consumerOrder.packetsRemaining;
                        digestAmt = producerAmt >= consumerAmt ? consumerAmt : producerAmt;
                    }
                    _activateCapital(
                        ParamPacker(
                            consumerOrder, 
                            producerOrder, 
                            true, 
                            vaultAsset != pool.asset, 
                            digestAmt, 
                            producerOrder.depositedShares, 
                            pool, 
                            adapter, 
                            poolId
                        )
                    );

                    consumerOrder.packetsRemaining -= digestAmt;
                    producerOrder.packetsRemaining -= digestAmt;
                    amount -= (digestAmt * producerPacket);

                    // Handle _dequeue as needed
                    if(consumerOrder.packetsRemaining == 0) {
                        _dequeue(poolId, false);
                    }
                }
                // Check if queue is empty
                hasCounterparty = !_isQueueEmpty(poolId, false);
            }
        }


        if(!hasCounterparty && producerOrder.packetsRemaining > 0) {
            // If farming is desired, deposit remaining funds to farm
            // No currently available trade, add this order to producer queue
            _enqueue(poolId, true, shouldFarm, producerOrder, amount, pool.asset, adapter);
        }
    } 

    /** 
     * @notice Allows a participant to modify an existing order in-queue. User must own the position they are attempting to modify
     * @param poolId the ID of the pool in which the order exists
     * @param amount the amount of packets to withdraw from the order - will be rounded down to nearest packet
     * @param position the position of the order within the queue
     * @param isProvider on which side of the queue the order exists --- CAN LIKELY DEPRECATE
     * @dev Allows for orders to be withdrawn early. All revenue generated if the order was farming will be passed along to Resonate
     */
    function modifyExistingOrder(bytes32 poolId, uint112 amount, uint64 position, bool isProvider) external nonReentrant {
        // This function can withdraw tokens from an existing queued order and remove that order entirely if needed
        // amount = number of packets for order
        // if amount == packets remaining then just go and null out the rest of the order
        // delete sets the owner address to zero which is an edge case handled elsewhere

        Order memory order = isProvider ? providerQueue[poolId][position] : consumerQueue[poolId][position];
        require(msg.sender == order.owner.toAddress(), "ER007");

        //State changes
        if (order.packetsRemaining == amount) {
            PoolQueue storage qm = queueMarkers[poolId]; 
            emit OrderWithdrawal(poolId, amount, true, msg.sender);

            if (isProvider) {
                if (position == qm.providerHead) {
                    qm.providerHead++;
                }
                else if (position == qm.providerTail) {
                    qm.providerTail--;
                }
                delete providerQueue[poolId][position];
            } else {
                if (position == qm.consumerHead) {
                    qm.consumerHead++;
                } else if (position == qm.consumerTail) { 
                    qm.consumerTail--;
                }
                delete consumerQueue[poolId][position];
            }
        } else {
            if (isProvider) {
                providerQueue[poolId][position].packetsRemaining -= amount;
            } else {
                consumerQueue[poolId][position].packetsRemaining -= amount;
            }
            emit OrderWithdrawal(poolId, amount, false, msg.sender);
        }

        PoolConfig memory pool = pools[poolId];

        address asset = IERC4626(pool.adapter).asset();
        
        uint amountTokens = isProvider ? amount * pool.packetSize * pool.rate / PRECISION : amount * pool.packetSize;
        bool isCrossAsset = asset != pool.asset;

        if(!isProvider || (order.depositedShares > 0 && !isCrossAsset)) {
            uint tokensReceived = _getWalletForPool(poolId).withdrawFromVault(
                order.depositedShares * amount / PRECISION, // Recover extra PRECISION
                address(this), 
                pool.adapter
            );
            uint fee;
            if(tokensReceived > amountTokens) {
                fee = tokensReceived - amountTokens;
                IERC20(asset).safeTransfer(DEV_ADDRESS, fee);
            }
            IERC20(asset).safeTransfer(msg.sender, tokensReceived - fee);
        } else {
            if(isCrossAsset) {
                // Was farming, cross-asset
                uint producerPacket = pool.rate * pool.packetSize / PRECISION * order.depositedShares / PRECISION;

                _getWalletForPool(poolId).withdraw(producerPacket * amount, 0, pool.asset, msg.sender, address(0));
               
            } else {
                // Provider side, just withdraw
                _getWalletForPool(poolId).withdraw(amountTokens, 0, pool.asset, msg.sender, address(0));
            }
        }
    }

    /**
     * @notice Allows for the batch-claiming of interest from interest-bearing FNFTs
     * @param fnftIds A 2D array of FNFT Ids to be claimed. Should be formatted as arrays of FNFT Ids specific to pools for greater gas efficiency.
     * @param recipient The address to which the interest will be sent
     * @dev This function will revert if an inner array of FNFTs contains an ID with a poolID different from the first element in that array
     */
    function batchClaimInterest(uint[][] calldata fnftIds, address recipient) external nonReentrant {
        // Outer array is an array of all FNFTs segregated by pool
        // Inner array is array of FNFTs to claim interest on
        uint numberPools = fnftIds.length;
        require(numberPools > 0, 'ER003');

        // for each pool
        for(uint i; i < numberPools; ++i) {
            // save the list of ids for the pool
            uint[] calldata fnftsByPool = fnftIds[i];
            require(fnftsByPool.length > 0, 'ER003');

            // get the first order, we commit one SLOAD here
            bytes32 poolId = activated[fnftIdToIndex[fnftsByPool[0]]].poolId;
            PoolConfig memory pool = pools[poolId];
            IERC4626 vault = IERC4626(pool.adapter);
            address asset = vault.asset();
            
            // NB: Point of caution
            uint newSharesPerPacket = vault.previewWithdraw(pool.packetSize) * PRECISION; 

            // set up global to track total shares
            uint totalSharesToRedeem;
            // for each id, should be for loop
            for(uint j; j < fnftsByPool.length; ++j) {
                {
                    Active memory active = activated[fnftIdToIndex[fnftsByPool[j]]];
                    require(active.poolId == poolId, 'ER039');
                    require(active.sharesPerPacket > newSharesPerPacket, 'ER040'); // Shouldn't pass FNFTs into this method that aren't owed interest
                    // save the individual id
                    uint fnftId = fnftsByPool[j];
                    require(FNFT_HANDLER.getBalance(msg.sender, fnftId) > 0, 'ER010');
                    require(fnftId == active.principalId + 1, 'ER009');
                    uint prinPackets = FNFT_HANDLER.getSupply(active.principalId);
                    require(prinPackets > 0, 'ER016');
                    {
                        // Calculate the maximum number of shares that will be redeemed
                        uint sharesRedeemed = prinPackets * (active.sharesPerPacket - newSharesPerPacket); 
                        // add to cumulative total
                        totalSharesToRedeem += sharesRedeemed;
                        // Update existing sharesPerPacket
                        activated[fnftIdToIndex[fnftId]].sharesPerPacket = newSharesPerPacket;
                    }
                }
            }
            uint interest = _getWalletForFNFT(poolId).redeemShares(
                pool.vault, 
                pool.adapter, 
                address(this), 
                totalSharesToRedeem / PRECISION // recover extra precision
            );
            uint fee = interest * FEE / DENOM;
            IERC20(asset).transfer(DEV_ADDRESS, fee);
            // Forward to recipient
            IERC20(asset).transfer(recipient, interest-fee);
            emit FeeCollection(poolId, fee); 
            emit BatchInterestClaimed(poolId, fnftsByPool, recipient, interest);
        }
    }

    /**
     * @notice Claims the interest for a given position
     * @param fnftId the ID of the FNFT to claim interest on
     * @param recipient where that interest should be sent
     * @dev this function can either be called directly by the FNFT holder or through the OutputReceiver Proxy using the update method
     */
    function claimInterest(uint fnftId, address recipient) public override nonReentrant {
        require(msg.sender == PROXY_OUTPUT_RECEIVER || FNFT_HANDLER.getBalance(msg.sender, fnftId) > 0, 'ER010');
        Active memory active = activated[fnftIdToIndex[fnftId]];
        require(fnftId == active.principalId + 1, 'ER009');
        uint prinPackets = FNFT_HANDLER.getSupply(active.principalId);
        require(prinPackets > 0, 'ER016');
        PoolConfig memory pool = pools[active.poolId];
        // Withdraw to this contract
        // NB: Violation of checks-effects-interaction. Acceptable with nonReentrant
        (uint interest, uint claimPerPacket) = _getWalletForFNFT(active.poolId).calculateAndClaimInterest(
            pool.vault, 
            pool.adapter, 
            address(this), 
            prinPackets * pool.packetSize, 
            active.sharesPerPacket * prinPackets / PRECISION // Recover our extra PRECISION
        );
        claimPerPacket = claimPerPacket * PRECISION / prinPackets; // Add our extra PRECISION
        require(claimPerPacket > 0, 'ER003'); // Prevent abuse
        if(claimPerPacket <= active.sharesPerPacket) {
            activated[fnftIdToIndex[fnftId]].sharesPerPacket = active.sharesPerPacket - claimPerPacket;
        } else {
            activated[fnftIdToIndex[fnftId]].sharesPerPacket = 0;
        } 

        
        // Claim fee on interest
        address asset = IERC4626(pool.adapter).asset();
        uint fee = interest * FEE / DENOM; // round the feed
        IERC20(asset).transfer(DEV_ADDRESS, fee);
        // Forward to recipient
        IERC20(asset).transfer(recipient, interest-fee);
        
        emit FeeCollection(active.poolId, fee);
        emit InterestClaimed(active.poolId, fnftId, recipient, interest);
    }
    
    ///
    /// Revest OutputReceiver functions
    /// 

    /**
     * @notice Handles the withdrawal behavior for both interest- and principal-bearing FNFTs
     * @param fnftId the ID of the FNFT being withdrawn 
     * @param tokenHolder The address to whom the principal or interest should be sent, as they owned the FNFT
     * @param quantity How many FNFTs are being withdrawn within the series. Will always be 1 for interest-bearing FNFTs
     * @dev Can only be called by the OutputReceiver Proxy contract. The FNFT associated with the ID will have been burned at the point this is called
     */
    function receiveRevestOutput(
        uint fnftId,
        address,
        address payable tokenHolder,
        uint quantity
    ) external override nonReentrant {
        require(msg.sender == PROXY_OUTPUT_RECEIVER, "ER017");
        Active memory active = activated[fnftIdToIndex[fnftId]];
        PoolConfig memory pool = pools[active.poolId];
        uint prinPackets = FNFT_HANDLER.getSupply(active.principalId);        

        if(fnftId == active.principalId) {
            // This FNFT represents the principal
            // quantity = principalPackets
            // Need to withdraw principal, then record the residual interest owed
            uint amountUnderlying = quantity * pool.packetSize;
            bool leaveResidual = FNFT_HANDLER.getSupply(active.principalId + 1) > 0;
            address vaultToken = pool.adapter;
            
            // NB: Violation of checks-effects-interaction. Acceptable with nonReentrant
            uint residual = _getWalletForFNFT(active.poolId).reclaimPrincipal(
                pool.vault, 
                vaultToken,
                tokenHolder, 
                amountUnderlying, 
                active.sharesPerPacket * quantity / PRECISION, // Recover our extra PRECISION here 
                leaveResidual
            );
            if(residual > 0) {
                residuals[fnftId + 1] += residual;
            }
            emit FNFTRedeemed(active.poolId, true, fnftId, quantity);
            emit InterestClaimed(active.poolId, fnftId, tokenHolder, residual);
            emit WithdrawERC20OutputReceiver(tokenHolder, IERC4626(vaultToken).asset(), amountUnderlying, fnftId, '0x0');
        } else {
            // This FNFT represents the interest
            require(quantity == 1, 'ER013');
            
            // Pass in totalShares, totalAmountPrincipal, derive interest and pull to this contract
            // Pull in any existing residuals within the same call – using residuals mapping?
            // Tell the vault to TRANSFER the residual (interest left when principal was pulled) 
            // plus WITHDRAW additional interest that has accrued
            // based on whatever principal remains within the vault 
            // 
            uint claimPerPacket;
            uint interest;
            
            {
                uint residual = residuals[fnftId];
                if(residual > 0) {
                    residuals[fnftId] = 0;
                }
                uint amountUnderlying = prinPackets * pool.packetSize;
                
                uint totalShares = active.sharesPerPacket * prinPackets / PRECISION; // Recover our extra PRECISION here

                // NB: Violation of checks-effects-interaction. Acceptable with nonReentrant
                (interest,claimPerPacket) = _getWalletForFNFT(active.poolId).reclaimInterestAndResidual(
                    pool.vault, 
                    pool.adapter, 
                    address(this), 
                    amountUnderlying, 
                    totalShares, 
                    residual
                );
            }

            if(prinPackets > 0) {
                // Add an extra PRECISION to avoid losing info
                claimPerPacket = claimPerPacket * PRECISION / prinPackets; 
                if(claimPerPacket <= active.sharesPerPacket) {
                    activated[fnftIdToIndex[fnftId]].sharesPerPacket = active.sharesPerPacket - claimPerPacket;
                } else {
                    activated[fnftIdToIndex[fnftId]].sharesPerPacket = 0;
                }
            }

            uint fee = interest * FEE / DENOM;
            address asset = IERC4626(pool.adapter).asset();

            IERC20(asset).safeTransfer(DEV_ADDRESS, fee);
            IERC20(asset).safeTransfer(tokenHolder, interest - fee);
            
            emit FNFTRedeemed(active.poolId, false, fnftId, 1);
            emit FeeCollection(active.poolId, fee);
            emit InterestClaimed(active.poolId, fnftId, tokenHolder, interest);
            // Remaining orphaned residual automatically goes to the principal FNFT holders
        }
        // Clean up mappings
        uint index = fnftIdToIndex[active.principalId];
        if(prinPackets == 0) {
            delete fnftIdToIndex[active.principalId];
        }
        if(FNFT_HANDLER.getSupply(active.principalId + 1) == 0) {
            delete fnftIdToIndex[active.principalId+1];
        }
        if(prinPackets == 0 && FNFT_HANDLER.getSupply(active.principalId + 1) == 0) { 
            delete activated[index];
        }
    }
        

    ///
    /// Utility Functions
    ///

    /**
     * @notice Takes two positions and matches them accordingly, creates FNFTs as-needed
     * @param packer Contains all the parameters needed for this operation
     * @dev If there was a deposit into the vault prior to capital activation for either order, claim that now and distribute
     */
    function _activateCapital(
        ParamPacker memory packer
    ) private returns (uint principalId) {
        // Double check in the future on the vaultAdapters
        IERC4626 vault = IERC4626(packer.adapter);
        address vaultAsset = vault.asset(); // The native asset
        // Fetch curPrice if necessary
        // State where it would be zero is when producer order is being submitted for non-farming position
        // Needs to come before FNFT creation, since curPrice is saved within that storage        

        // Need to withdraw from the vault for this operation if value was previously stored in it
        // Utilize this opportunity to charge fee on interest that has accumulated during dwell time
        uint amountFromConsumer = packer.quantityPackets * packer.pool.packetSize;
        uint amountToConsumer = packer.isCrossAsset ? amountFromConsumer * packer.pool.rate / PRECISION * packer.currentExchangeRate / PRECISION : amountFromConsumer * packer.pool.rate / PRECISION; //upfront?

        if(packer.isProducerNew) {
            {
                address consumerOwner = packer.consumerOrder.owner.toAddress();
                // The producer position is the new one, take value from them and transfer to consumer
                // Charge our fee on the upfront payment here
                uint fee = amountToConsumer * FEE / DENOM;
                IERC20(packer.pool.asset).safeTransferFrom(msg.sender, DEV_ADDRESS, fee);
                IERC20(packer.pool.asset).safeTransferFrom(msg.sender, consumerOwner, amountToConsumer-fee);
                emit FeeCollection(packer.poolId, fee);

                // Prepare the desired FNFTs
                principalId = _createFNFTs(packer.quantityPackets, packer.poolId, consumerOwner, packer.producerOrder.owner.toAddress());
            }
            {
                // Claim interest on the farming of the consumer's capital
                (uint shares, uint interest) = IPoolWallet(_getAddressForPool(packer.poolId)).activateExistingConsumerPosition(
                    amountFromConsumer, 
                    packer.quantityPackets * packer.consumerOrder.depositedShares / PRECISION, // Recover our extra precision
                    _getAddressForFNFT(packer.poolId), 
                    DEV_ADDRESS, 
                    packer.pool.vault, 
                    packer.adapter
                );

                // We want to avoid loss of information, so we multiply by 1E18 (PRECISION)
                shares = shares * PRECISION / packer.quantityPackets;

                Active storage active = activated[principalId];
                active.sharesPerPacket = shares;
                if(packer.pool.addInterestRate != 0) {
                    active.startingSharesPerPacket = shares;
                }

                emit FeeCollection(packer.poolId, interest);
            }
        } else {
            // The consumer position is the new one, take stored producer value and transfer to them
            // If the producer was farming, we can detect this and charge our fee on interest

            address producerOwner = packer.producerOrder.owner.toAddress();

            // Need to deposit to vault from consumer and store in FNFT
            IERC20(vaultAsset).safeTransferFrom(msg.sender, address(this), amountFromConsumer);

            // Prepare the desired FNFTs
            principalId = _createFNFTs(packer.quantityPackets, packer.poolId, packer.consumerOrder.owner.toAddress(), producerOwner);
            {   
                Active storage active = activated[principalId];
                // We add an extra PRECISION to this to avoid losing data
                uint shares = vault.deposit(amountFromConsumer, _getAddressForFNFT(packer.poolId)) * PRECISION / packer.quantityPackets;
                active.sharesPerPacket = shares;
                if(packer.pool.addInterestRate != 0) {
                    active.startingSharesPerPacket = shares;
                }

            }
            

            // Need to then pay out to consumer from producer position
            if(packer.producerOrder.depositedShares > 0 && !packer.isCrossAsset) {
                
                uint interest = IPoolWallet(_getAddressForPool(packer.poolId)).activateExistingProducerPosition(
                    amountToConsumer, 
                    packer.quantityPackets * packer.producerOrder.depositedShares / PRECISION, // Recover our extra PRECISION here 
                    amountToConsumer * FEE / DENOM,
                    msg.sender, 
                    DEV_ADDRESS, 
                    packer.pool.vault, 
                    packer.adapter
                );
                emit FeeCollection(packer.poolId, amountToConsumer * FEE / DENOM + interest);

            } else {
                uint fee = amountToConsumer * FEE / DENOM;
                IPoolWallet(_getAddressForPool(packer.poolId)).withdraw(amountToConsumer, fee, packer.pool.asset, msg.sender, DEV_ADDRESS);
            }
        } 
        emit CapitalActivated(packer.poolId, packer.quantityPackets, principalId);
        // Included to comply with IOutputReceiverV3 standard
        emit DepositERC20OutputReceiver(packer.consumerOrder.owner.toAddress(), vaultAsset, amountFromConsumer, principalId, '0x0');
    }

    /**
     * @notice Mints and distributes FNFTs, sends to each involved party
     * @param quantityPackets The number of packets being consumed by this order is the number of principal FNFTs to create
     * @param poolId The ID for the pool associated with these FNFTs
     * @param consumerOwner The owner of the Issuer's order, to whom the principal FNFTs will be minted
     * @param producerOwner The owner of the Purchaser's order, to whom the interest FNFT will be minted
     * @return principalId The ID of the principal-bearing FNFTs
     * @dev This function may be called multiple times for the creation of a single order with multiple counter-parties
     */
    function _createFNFTs(
        uint quantityPackets,
        bytes32 poolId,
        address consumerOwner, 
        address producerOwner
    ) private returns (uint principalId) {
        
        PoolConfig memory pool = pools[poolId];

        // We should know current deposit mul from previous work
        // Should have already deposited value by this point in workflow

        // Initialize base FNFT config
        IRevest.FNFTConfig memory fnftConfig;
        // Common method, both will reference this contract
        fnftConfig.pipeToContract = PROXY_OUTPUT_RECEIVER;
        // Further common components
        address[] memory recipients = new address[](1);
        uint[] memory quantities = new uint[](1);

        // Begin minting principal FNFTs

        // How many principal FNFTs are we creating?
        quantities[0] = quantityPackets;
        // Who should get the principal FNFTs?
        recipients[0] = consumerOwner;

        if (pool.addInterestRate != 0) {
            // Mint Type 1 
            principalId = _getRevest().mintAddressLock(PROXY_ADDRESS_LOCK, "", recipients, quantities, fnftConfig);
        } else {
            // Mint Type 0
            principalId = _getRevest().mintTimeLock(block.timestamp + pool.lockupPeriod, recipients, quantities, fnftConfig);
        }

        // Begin minting interest FNFT

        // Interest FNFTs will always be singular
        // NB: Interest ID will always be +1 of principal ID
        quantities[0] = 1;
        recipients[0] = producerOwner;
        uint interestId;
        
        if (pool.addInterestRate != 0) {
            // Mint Type 1 
            interestId = _getRevest().mintAddressLock(PROXY_ADDRESS_LOCK, "", recipients, quantities, fnftConfig);  
        }  else {
            // Mint Type 0
            interestId = _getRevest().mintTimeLock(block.timestamp + pool.lockupPeriod, recipients, quantities, fnftConfig);
        }

        {

            // GAS: Four SSTORE operations // Uses currPricePerShare twice for current and starting value
            activated[principalId] = Active(principalId, 1, 0, poolId);

            // GAS: Two SSTORE operations
            fnftIdToIndex[principalId] = principalId;
            fnftIdToIndex[interestId] = principalId;
        }

        emit FNFTCreation(poolId, true, principalId, quantityPackets);
        emit FNFTCreation(poolId, false, interestId, 1);
    }


    /**
     * @notice Add an order to the appropriate queue
     * @param poolId The ID of the pool to which this order should be added
     * @param isProvider Whether the order should be added to Purchaser queue (true) or Issuer queue (false)
     * @param shouldFarm Whether the user's tokens should be deposited into the underlying vault to farm in-queue
     * @param order The Order structure to add to the respective queue
     * @param amount The amount of tokens being deposited
     * @param asset The asset to deposit
     * @param vaultAdapter the ERC-4626 vault (adapter) to deposit into
     * @dev This should only be called once during either submitConsumer or submitProducer
     */
    function _enqueue(
        bytes32 poolId, 
        bool isProvider, 
        bool shouldFarm, 
        Order memory order, 
        uint amount, 
        address asset, 
        address vaultAdapter
    ) private {
        if(shouldFarm) {
            // Store in pool smart wallet as vault deposit
            IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);

            order.depositedShares = IERC4626(vaultAdapter).deposit(amount, _getAddressForPool(poolId)) * PRECISION / order.packetsRemaining;
            require(order.depositedShares > 0, 'ER003'); 
        } else {

            // Leaving depositedShares as zero signifies non-farming nature of order
            // Similarly stores value in pool smart wallet
            IERC20(asset).safeTransferFrom(msg.sender, _getAddressForPool(poolId), amount);
        }

        PoolQueue storage qm = queueMarkers[poolId]; //cold sload
        // Allow overflow to reuse indices 
        unchecked {
            uint64 tail;
            if(isProvider) {
                tail = qm.providerTail;
                providerQueue[poolId][qm.providerTail++] = order; //cold? sstore
                emit EnqueueProvider(poolId, msg.sender, tail, shouldFarm, order);
                
            } else {
                tail = qm.consumerTail;
                consumerQueue[poolId][qm.consumerTail++] = order;
                emit EnqueueConsumer(poolId, msg.sender, tail, order);
            }
        }
    }   

    /**
     * @notice Remove an order from the appropriate queue 
     * @param poolId The ID of the pool which the order should be dequeued from
     * @param isProvider Whether the order should be removed from the Purchaser queue (true) or the Issuer queue (false)
     * @dev This can be called multiple times during the matching of counterparties
     */ 
    function _dequeue(bytes32 poolId, bool isProvider) private {
        PoolQueue storage qm = queueMarkers[poolId];
        Order memory order = providerQueue[poolId][isProvider ? qm.providerHead : qm.consumerHead];
        unchecked{
            uint64 head;
            if(isProvider) {
                head = qm.providerHead;
                delete providerQueue[poolId][qm.providerHead++];
                emit DequeueProvider(poolId, msg.sender, order.owner.toAddress(), head, order);
            } else {
                head = qm.consumerHead;
                delete consumerQueue[poolId][qm.consumerHead++];
                emit DequeueConsumer(poolId, msg.sender, order.owner.toAddress(), head, order);
            }
        }
    }

    /// Use to initialize necessary values for a pool
    /**
     * @notice Helper method to initialize the necessary values for a pool
     * @param asset the payment asset for the pool
     * @param vault the raw vault address for the pool - if non-4626 will have an adapter in vaultAdapters
     * @param rate the upfront payout rate for the pool
     * @param _additional_rate the value to be added to the rate to get the interest needed for unlock. Zero if fixed-term
     * @param lockupPeriod the amount of time in seconds that the principal FNFT will be locked for. Zero if fixed-income
     * @param packetSize the standard packet size for the pool
     * @return poolId the resulting poolId from the given parameters
     */
    function _initPool(
        address asset,
        address vault, 
        uint128 rate, 
        uint128 _additional_rate,
        uint32 lockupPeriod, 
        uint packetSize
    ) private returns (bytes32 poolId) {
        address adapter = vaultAdapters[vault];
        poolId = _getPoolId(asset, vault, adapter, rate, _additional_rate, lockupPeriod, packetSize);
        require(pools[poolId].lockupPeriod == 0 && pools[poolId].addInterestRate == 0, 'ER002');
        queueMarkers[poolId] = PoolQueue(1, 1, 1, 1);
        pools[poolId] = PoolConfig(asset, vault, adapter, lockupPeriod, rate, _additional_rate, packetSize);
    }

    /**
     * @notice Fetches an instance of IPoolWallet, either by deploying or by instantiating an existing deployment
     * @param poolId The poolID to which this IPoolWallet is bound
     * @return wallet The instance of IPoolWallet associated with the passed-in poolId
     */
    function _getWalletForPool(bytes32 poolId) private returns (IPoolWallet wallet) {
        wallet = IPoolWallet(IResonateHelper(RESONATE_HELPER).getWalletForPool(poolId));
    }

    /**
     * @notice Fetches an instance of ISmartWallet, either by deploying or by instantiating an existing deployment
     * @param poolId The poolID to which this ISmartWallet is bound
     * @return wallet The instance of ISmartWallet associated with the passed-in poolId
     */
    function _getWalletForFNFT(bytes32 poolId) private returns (ISmartWallet wallet) {
        wallet = ISmartWallet(IResonateHelper(RESONATE_HELPER).getWalletForFNFT(poolId));
    }

    /**
     * @notice Checks whether a contract has approval to spend tokens from Resonate, approves if not so
     * @param spender The spender address to check, typically a smart wallet
     * @param asset The asset which will be spent
     */
    function _checkApproval(address spender, address asset) private {
        if(!_approvedContracts[spender][asset]) {
            IERC20(asset).safeApprove(spender, type(uint).max);
            _approvedContracts[spender][asset] = true;
        }
    }

    function _validRecipient() private view returns (bool canReceive) {
        uint size = msg.sender.code.length;
        bool isEOA = size == 0;
        canReceive = (msg.sender == tx.origin && isEOA) || SMART_WALLET_WHITELIST.check(msg.sender);
    }
     
    ///
    /// Admin Functions
    ///

    /**
     * @notice Used to match a vault with its adapter – can also be utilized for zero-ing out a vault
     * @param vault The raw vault which needs to be mapped to its adapter. If 4626, will be identical to adapter
     * @param adapter The ERC-4626 adapter or vault to map to the baseline vault
     * @dev Protected function
     */
    function modifyVaultAdapter(address vault, address adapter) external onlyOwner {
        vaultAdapters[vault] = adapter;
        if(adapter != address(0)) {
            _checkApproval(adapter, IERC4626(adapter).asset());
            emit VaultAdapterRegistered(vault, adapter, IERC4626(adapter).asset());
        } else {
            emit VaultAdapterRegistered(vault, adapter, address(0));
        }
    }

    /**
     * @notice Transfer ownership to a new owner
     * @param newOwner The new owner to transfer control of admin functions to
     * @dev Protected function
     */
    function transferOwnership(address newOwner) external onlyOwner {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    ///
    /// View Functions
    ///

    /**
     * @notice Indicates whether a queue is empty on one side and therefore whether a counter-party is present
     * @param poolId The ID of the pool to check queues within
     * @param isProvider Whether to check the Purchaser queue (true) or the Issuer queue (false)
     * @return isEmpty Whether the queue being checked is empty or not
     */
    function _isQueueEmpty(bytes32 poolId, bool isProvider) private view returns (bool isEmpty) {
        PoolQueue memory qm = queueMarkers[poolId];
        isEmpty = isProvider ? qm.providerHead == qm.providerTail : qm.consumerHead == qm.consumerTail;
    }

    /**
     * @notice Retreive the poolId that a specified combination of inputs will produce
     * @param asset the payment asset for the pool
     * @param vault the raw vault address for the pool - if non-4626 will have an adapter in vaultAdapters
     * @param rate the upfront payout rate for the pool
     * @param _additional_rate the value to be added to the rate to get the interest needed for unlock. Zero if fixed-term
     * @param lockupPeriod the amount of time in seconds that the principal FNFT will be locked for. Zero if fixed-income
     * @param packetSize the standard packet size for the pool
     * @return poolId the result of applying keccak256 to the abi-encoded arguments passed in
     */
    function _getPoolId(
        address asset, 
        address vault, 
        address adapter,
        uint128 rate,
        uint128 _additional_rate,   
        uint32 lockupPeriod, 
        uint packetSize
    ) private pure returns (bytes32 poolId) {
        poolId = keccak256(abi.encodePacked(asset, vault, adapter, rate, _additional_rate, lockupPeriod, packetSize));
    }

    

    /**
     * @notice Returns the order at the head of the specified queue without removing it
     * @param poolId The poolId of the pool in which the queue exists
     * @param isProvider Whether to check the Purchaser queue (true) or the Issuer queue (false)
     * @return order The Order struct which is at the head of the specified queue
     */
    function _peek(bytes32 poolId, bool isProvider) private view returns (Order storage order) {
        if(isProvider) {
            order = providerQueue[poolId][queueMarkers[poolId].providerHead];
        } else {
            order = consumerQueue[poolId][queueMarkers[poolId].consumerHead];
        }
    }

    /**
     * @notice Returns the address of a pool smart wallet 
     */
    function _getAddressForPool(bytes32 poolId) private view returns (address smartWallet) {
        smartWallet = IResonateHelper(RESONATE_HELPER).getAddressForPool(poolId);
    }

    /**
     * @notice Returns the address of an FNFT pool smart wallet 
     */
    function _getAddressForFNFT(bytes32 poolId) private view returns (address smartWallet) {
        smartWallet = IResonateHelper(RESONATE_HELPER).getAddressForFNFT(poolId);
    }

    /// @notice Returns the IRevest entry point dictated by the Revest Address Registry
    function _getRevest() private view returns (IRevest) {
        return IRevest(IAddressRegistry(REGISTRY_ADDRESS).getRevest());
    }

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

interface IRevest {
    event FNFTTimeLockMinted(
        address indexed asset,
        address indexed from,
        uint indexed fnftId,
        uint endTime,
        uint[] quantities,
        FNFTConfig fnftConfig
    );

    event FNFTValueLockMinted(
        address indexed asset,
        address indexed from,
        uint indexed fnftId,
        address compareTo,
        address oracleDispatch,
        uint[] quantities,
        FNFTConfig fnftConfig
    );

    event FNFTAddressLockMinted(
        address indexed asset,
        address indexed from,
        uint indexed fnftId,
        address trigger,
        uint[] quantities,
        FNFTConfig fnftConfig
    );

    event FNFTWithdrawn(
        address indexed from,
        uint indexed fnftId,
        uint indexed quantity
    );

    event FNFTSplit(
        address indexed from,
        uint[] indexed newFNFTId,
        uint[] indexed proportions,
        uint quantity
    );

    event FNFTUnlocked(
        address indexed from,
        uint indexed fnftId
    );

    event FNFTMaturityExtended(
        address indexed from,
        uint indexed fnftId,
        uint indexed newExtendedTime
    );

    event FNFTAddionalDeposited(
        address indexed from,
        uint indexed newFNFTId,
        uint indexed quantity,
        uint amount
    );

    struct FNFTConfig {
        address asset; // The token being stored
        address pipeToContract; // Indicates if FNFT will pipe to another contract
        uint depositAmount; // How many tokens
        uint depositMul; // Deposit multiplier
        uint split; // Number of splits remaining
        uint depositStopTime; //
        bool maturityExtension; // Maturity extensions remaining
        bool isMulti; //
        bool nontransferrable; // False by default (transferrable) //
    }

    // Refers to the global balance for an ERC20, encompassing possibly many FNFTs
    struct TokenTracker {
        uint lastBalance;
        uint lastMul;
    }

    enum LockType {
        DoesNotExist,
        TimeLock,
        ValueLock,
        AddressLock
    }

    struct LockParam {
        address addressLock;
        uint timeLockExpiry;
        LockType lockType;
        ValueLock valueLock;
    }

    struct Lock {
        address addressLock;
        LockType lockType;
        ValueLock valueLock;
        uint timeLockExpiry;
        uint creationTime;
        bool unlocked;
    }

    struct ValueLock {
        address asset;
        address compareTo;
        address oracle;
        uint unlockValue;
        bool unlockRisingEdge;
    }

    function mintTimeLock(
        uint endTime,
        address[] memory recipients,
        uint[] memory quantities,
        IRevest.FNFTConfig memory fnftConfig
    ) external payable returns (uint);

    function mintValueLock(
        address primaryAsset,
        address compareTo,
        uint unlockValue,
        bool unlockRisingEdge,
        address oracleDispatch,
        address[] memory recipients,
        uint[] memory quantities,
        IRevest.FNFTConfig memory fnftConfig
    ) external payable returns (uint);

    function mintAddressLock(
        address trigger,
        bytes memory arguments,
        address[] memory recipients,
        uint[] memory quantities,
        IRevest.FNFTConfig memory fnftConfig
    ) external payable returns (uint);

    function withdrawFNFT(uint tokenUID, uint quantity) external;

    function unlockFNFT(uint tokenUID) external;

    function splitFNFT(
        uint fnftId,
        uint[] memory proportions,
        uint quantity
    ) external returns (uint[] memory newFNFTIds);

    function depositAdditionalToFNFT(
        uint fnftId,
        uint amount,
        uint quantity
    ) external returns (uint);

    function extendFNFTMaturity(
        uint fnftId,
        uint endTime
    ) external returns (uint);

    function setFlatWeiFee(uint wethFee) external;

    function setERC20Fee(uint erc20) external;

    function getFlatWeiFee() external view returns (uint);

    function getERC20Fee() external view returns (uint);


}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;


interface IFNFTHandler  {
    function mint(address account, uint id, uint amount, bytes memory data) external;

    function mintBatchRec(address[] memory recipients, uint[] memory quantities, uint id, uint newSupply, bytes memory data) external;

    function mintBatch(address to, uint[] memory ids, uint[] memory amounts, bytes memory data) external;

    function setURI(string memory newuri) external;

    function burn(address account, uint id, uint amount) external;

    function burnBatch(address account, uint[] memory ids, uint[] memory amounts) external;

    function getBalance(address tokenHolder, uint id) external view returns (uint);

    function getSupply(uint fnftId) external view returns (uint);

    function getNextId() external view returns (uint);
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

/**
 * @title Provider interface for Revest FNFTs
 * @dev
 *
 */
interface IAddressRegistry {

    function initialize(
        address lock_manager_,
        address liquidity_,
        address revest_token_,
        address token_vault_,
        address revest_,
        address fnft_,
        address metadata_,
        address admin_,
        address rewards_
    ) external;

    function getAdmin() external view returns (address);

    function setAdmin(address admin) external;

    function getLockManager() external view returns (address);

    function setLockManager(address manager) external;

    function getTokenVault() external view returns (address);

    function setTokenVault(address vault) external;

    function getRevestFNFT() external view returns (address);

    function setRevestFNFT(address fnft) external;

    function getMetadataHandler() external view returns (address);

    function setMetadataHandler(address metadata) external;

    function getRevest() external view returns (address);

    function setRevest(address revest) external;

    function getDEX(uint index) external view returns (address);

    function setDex(address dex) external;

    function getRevestToken() external view returns (address);

    function setRevestToken(address token) external;

    function getRewardsHandler() external view returns(address);

    function setRewardsHandler(address esc) external;

    function getAddress(bytes32 id) external view returns (address);

    function getLPs() external view returns (address);

    function setLPs(address liquidToken) external;

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

interface ISmartWalletWhitelistV2 {
    function check(address) external view returns (bool);
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

/// @author RobAnon

interface IPoolWallet {

    function MASTER() external view returns (address master);

    function RESONATE() external view returns (address resonate);


    function withdraw(uint value, uint fee, address token, address recipient, address devWallet) external;

    function withdrawFromVault(uint amount, address receiver, address vault) external returns (uint tokens);

    function activateExistingConsumerPosition(
        uint amountUnderlying, 
        uint totalShares, 
        address fnftWallet,
        address devWallet,
        address vaultToken,
        address vaultAdapter
    ) external returns (uint shares, uint interest);

    function activateExistingProducerPosition(
        uint amountUnderlying, 
        uint totalShares, 
        uint fee,
        address consumer,
        address devWallet,
        address vaultToken,
        address vaultAdapter
    ) external returns (uint interest);
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "./IResonate.sol";

/// @author RobAnon

interface IResonateHelper {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address owner);

    function POOL_TEMPLATE() external view returns (address template);

    function FNFT_TEMPLATE() external view returns (address template);

    function SANDWICH_BOT_ADDRESS() external view returns (address bot);

    function getAddressForPool(bytes32 poolId) external view returns (address smartWallet);

    function getAddressForFNFT(bytes32 fnftId) external view returns (address smartWallet);

    function getWalletForPool(bytes32 poolId) external returns (address smartWallet);

    function getWalletForFNFT(bytes32 fnftId) external returns (address wallet);


    function setResonate(address resonate) external;

    function blackListFunction(uint32 selector) external;
    function whiteListFunction(uint32 selector, bool isWhitelisted) external;

    /// To be used by the sandwich bot for bribe system. Can only withdraw assets back to vault not externally
    function sandwichSnapshot(bytes32 poolId, address vault, address vaultAdapter ,uint amount, bool isWithdrawal) external;
    function proxyCall(bytes32 poolId, address[] memory targets, uint[] memory values, bytes[] memory calldatas) external;
    ///
    /// VIEW METHODS
    ///

    function getPoolId(
        address asset, 
        address vault,
        address adapter, 
        uint128 rate,
        uint128 _additional_rate,
        uint32 lockupPeriod, 
        uint packetSize
    ) external pure returns (bytes32 poolId);

    function nextInQueue(bytes32 poolId, bool isProvider) external view returns (IResonate.Order memory order);

    function isQueueEmpty(bytes32 poolId, bool isProvider) external view returns (bool isEmpty);

    function calculateInterest(uint fnftId) external view returns (uint256 interest, uint256 interestAfterFee);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Library for converting between addresses and bytes32 values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/Bytes32AddressLib.sol)
library Bytes32AddressLib {
    function fromLast20Bytes(bytes32 bytesValue) internal pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    function fillLast12Bytes(address addressValue) internal pure returns (bytes32) {
        return bytes32(bytes20(addressValue));
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;
import {ERC20} from "../../lib/ERC20.sol";
import {ERC4626} from "../../lib/ERC4626.sol";
import {Bytes32AddressLib} from "@rari-capital/solmate/src/utils/Bytes32AddressLib.sol";


/// @title ERC4626Factory
/// @author zefram.eth
/// @notice Abstract base contract for deploying ERC4626 wrappers
/// @dev Uses CREATE2 deterministic deployment, so there can only be a single
/// vault for each asset.
abstract contract ERC4626Factory {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using Bytes32AddressLib for bytes32;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @notice Emitted when a new ERC4626 vault has been created
    /// @param asset The base asset used by the vault
    /// @param vault The vault that was created
    event CreateERC4626(ERC20 indexed asset, ERC4626 vault);

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    /// @notice Creates an ERC4626 vault for an asset
    /// @dev Uses CREATE2 deterministic deployment, so there can only be a single
    /// vault for each asset. Will revert if a vault has already been deployed for the asset.
    /// @param asset The base asset used by the vault
    /// @return vault The vault that was created
    function createERC4626(ERC20 asset)
        external
        virtual
        returns (ERC4626 vault);

    /// @notice Computes the address of the ERC4626 vault corresponding to an asset. Returns
    /// a valid result regardless of whether the vault has already been deployed.
    /// @param asset The base asset used by the vault
    /// @return vault The vault corresponding to the asset
    function computeERC4626Address(ERC20 asset)
        external
        view
        virtual
        returns (ERC4626 vault);

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    /// @notice Computes the address of a contract deployed by this factory using CREATE2, given
    /// the bytecode hash of the contract. Can also be used to predict addresses of contracts yet to
    /// be deployed.
    /// @dev Always uses bytes32(0) as the salt
    /// @param bytecodeHash The keccak256 hash of the creation code of the contract being deployed concatenated
    /// with the ABI-encoded constructor arguments.
    /// @return The address of the deployed contract
    function _computeCreate2Address(bytes32 bytecodeHash)
        internal
        view
        virtual
        returns (address)
    {
        return keccak256(
            abi.encodePacked(bytes1(0xFF), address(this), bytes32(0), bytecodeHash)
        )
            // Prefix:
            // Creator:
            // Salt:
            // Bytecode hash:
            .fromLast20Bytes(); // Convert the CREATE2 hash into an address.
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;
import "../lib/ERC4626.sol";

contract RariVault is ERC4626 {
    constructor(
        ERC20 _asset
    ) ERC4626(_asset, "RariVault", "RV") {}

    function totalAssets() public view virtual override returns (uint256) {
        return asset.balanceOf(address(this));
    }
}

pragma solidity >= 0.8.0;

import "../lib/ERC20.sol";

contract Mock20 is ERC20 {
    constructor() ERC20("Mock20", "M20", 18) {}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {ERC20} from "../../lib/ERC20.sol";
import {ERC4626} from "../../lib/ERC4626.sol";

import {AaveV2ERC4626} from "./AaveV2ERC4626.sol";
import {IAaveMining} from "./external/IAaveMining.sol";
import {ILendingPool} from "./external/ILendingPool.sol";
import {ERC4626Factory} from "../base/ERC4626Factory.sol";

/// @title AaveV2ERC4626Factory
/// @author zefram.eth
/// @notice Factory for creating AaveV2ERC4626 contracts
contract AaveV2ERC4626Factory is ERC4626Factory {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    /// @notice Thrown when trying to deploy an AaveV3ERC4626 vault using an asset without an aToken
    error AaveV2ERC4626Factory__ATokenNonexistent();

    /// -----------------------------------------------------------------------
    /// Immutable params
    /// -----------------------------------------------------------------------

    /// @notice The Aave liquidity mining contract
    IAaveMining public immutable aaveMining;

    /// @notice The address that will receive the liquidity mining rewards (if any)
    address public immutable rewardRecipient;

    /// @notice The Aave LendingPool contract
    ILendingPool public immutable lendingPool;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(
        IAaveMining aaveMining_,
        address rewardRecipient_,
        ILendingPool lendingPool_
    ) {
        aaveMining = aaveMining_;
        lendingPool = lendingPool_;
        rewardRecipient = rewardRecipient_;
    }

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    /// @inheritdoc ERC4626Factory
    function createERC4626(ERC20 asset)
        external
        virtual
        override
        returns (ERC4626 vault)
    {
        ILendingPool.ReserveData memory reserveData =
            lendingPool.getReserveData(address(asset));
        address aTokenAddress = reserveData.aTokenAddress;
        if (aTokenAddress == address(0)) {
            revert AaveV2ERC4626Factory__ATokenNonexistent();
        }

        vault =
        new AaveV2ERC4626{salt: bytes32(0)}(asset, ERC20(aTokenAddress), aaveMining, rewardRecipient, lendingPool);

        emit CreateERC4626(asset, vault);
    }

    /// @inheritdoc ERC4626Factory
    function computeERC4626Address(ERC20 asset)
        external
        view
        virtual
        override
        returns (ERC4626 vault)
    {
        ILendingPool.ReserveData memory reserveData =
            lendingPool.getReserveData(address(asset));
        address aTokenAddress = reserveData.aTokenAddress;

        vault = ERC4626(
            _computeCreate2Address(
                keccak256(
                    abi.encodePacked(
                        // Deployment bytecode:
                        type(AaveV2ERC4626).creationCode,
                        // Constructor arguments:
                        abi.encode(
                            asset, ERC20(aTokenAddress), aaveMining, rewardRecipient, lendingPool
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {ERC20} from "../../lib/ERC20.sol";
import {ERC4626} from "../../lib/ERC4626.sol";
import {SafeTransferLib} from "../../lib/SafeTransferLib.sol";

import {IAaveMining} from "./external/IAaveMining.sol";
import {ILendingPool} from "./external/ILendingPool.sol";

/// @title AaveV2ERC4626
/// @author zefram.eth
/// @notice ERC4626 wrapper for Aave V2
/// @dev Important security note: due to Aave using a rebasing model for aTokens,
/// this contract cannot independently keep track of the deposited funds, so it is possible
/// for an attacker to directly transfer aTokens to this contract, increase the vault share
/// price atomically, and then exploit an external lending market that uses this contract
/// as collateral.
contract AaveV2ERC4626 is ERC4626 {
    /// -----------------------------------------------------------------------
    /// Libraries usage
    /// -----------------------------------------------------------------------

    using SafeTransferLib for ERC20;

    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    uint256 internal constant ACTIVE_MASK =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF;
    uint256 internal constant FROZEN_MASK =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF;

    /// -----------------------------------------------------------------------
    /// Immutable params
    /// -----------------------------------------------------------------------

    /// @notice The Aave aToken contract
    ERC20 public immutable aToken;

    /// @notice The Aave liquidity mining contract
    IAaveMining public immutable aaveMining;

    /// @notice The address that will receive the liquidity mining rewards (if any)
    address public immutable rewardRecipient;

    /// @notice The Aave LendingPool contract
    ILendingPool public immutable lendingPool;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(
        ERC20 asset_,
        ERC20 aToken_,
        IAaveMining aaveMining_,
        address rewardRecipient_,
        ILendingPool lendingPool_
    )
        ERC4626(asset_, _vaultName(asset_), _vaultSymbol(asset_))
    {
        aToken = aToken_;
        aaveMining = aaveMining_;
        lendingPool = lendingPool_;
        rewardRecipient = rewardRecipient_;
    }

    /// -----------------------------------------------------------------------
    /// Aave liquidity mining
    /// -----------------------------------------------------------------------

    /// @notice Claims liquidity mining rewards from Aave and sends it to rewardRecipient
    function claimRewards() external {
        address[] memory assets = new address[](1);
        assets[0] = address(aToken);
        aaveMining.claimRewards(assets, type(uint256).max, rewardRecipient);
    }

    /// -----------------------------------------------------------------------
    /// ERC4626 overrides
    /// -----------------------------------------------------------------------

    function withdraw(uint256 assets, address receiver, address owner)
        public
        virtual
        override
        returns (uint256 shares)
    {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] =
                allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        // withdraw assets directly from Aave
        lendingPool.withdraw(address(asset), assets, receiver);
    }

    function redeem(uint256 shares, address receiver, address owner)
        public
        virtual
        override
        returns (uint256 assets)
    {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] =
                allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        // withdraw assets directly from Aave
        lendingPool.withdraw(address(asset), assets, receiver);
    }

    function totalAssets() public view virtual override returns (uint256) {
        // aTokens use rebasing to accrue interest, so the total assets is just the aToken balance
        return aToken.balanceOf(address(this));
    }

    function afterDeposit(uint256 assets, uint256 /*shares*/ )
        internal
        virtual
        override
    {
        /// -----------------------------------------------------------------------
        /// Deposit assets into Aave
        /// -----------------------------------------------------------------------


        // approve to lendingPool
        asset.safeApprove(address(lendingPool), assets);

        // deposit into lendingPool
        lendingPool.deposit(address(asset), assets, address(this), 0);
    }

    function maxDeposit(address)
        public
        view
        virtual
        override
        returns (uint256)
    {
        // check if pool is paused
        if (lendingPool.paused()) {
            return 0;
        }

        // check if asset is paused
        uint256 configData =
            lendingPool.getReserveData(address(asset)).configuration.data;
        if (!(_getActive(configData) && !_getFrozen(configData))) {
            return 0;
        }

        return type(uint256).max;
    }

    function maxMint(address)
        public
        view
        virtual
        override
        returns (uint256)
    {
        // check if pool is paused
        if (lendingPool.paused()) {
            return 0;
        }

        // check if asset is paused
        uint256 configData =
            lendingPool.getReserveData(address(asset)).configuration.data;
        if (!(_getActive(configData) && !_getFrozen(configData))) {
            return 0;
        }

        return type(uint256).max;
    }

    function maxWithdraw(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        // check if pool is paused
        if (lendingPool.paused()) {
            return 0;
        }

        // check if asset is paused
        uint256 configData =
            lendingPool.getReserveData(address(asset)).configuration.data;
        if (!_getActive(configData)) {
            return 0;
        }

        uint256 cash = asset.balanceOf(address(aToken));
        uint256 assetsBalance = convertToAssets(balanceOf[owner]);
        return cash < assetsBalance ? cash : assetsBalance;
    }

    function maxRedeem(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        // check if pool is paused
        if (lendingPool.paused()) {
            return 0;
        }

        // check if asset is paused
        uint256 configData =
            lendingPool.getReserveData(address(asset)).configuration.data;
        if (!_getActive(configData)) {
            return 0;
        }

        uint256 cash = asset.balanceOf(address(aToken));
        uint256 cashInShares = convertToShares(cash);
        uint256 shareBalance = balanceOf[owner];
        return cashInShares < shareBalance ? cashInShares : shareBalance;
    }

    /// -----------------------------------------------------------------------
    /// ERC20 metadata generation
    /// -----------------------------------------------------------------------

    function _vaultName(ERC20 asset_)
        internal
        view
        virtual
        returns (string memory vaultName)
    {
        vaultName = string.concat("ERC4626-Wrapped Aave v2 ", asset_.symbol());
    }

    function _vaultSymbol(ERC20 asset_)
        internal
        view
        virtual
        returns (string memory vaultSymbol)
    {
        vaultSymbol = string.concat("wa", asset_.symbol());
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    function _getActive(uint256 configData) internal pure returns (bool) {
        return configData & ~ACTIVE_MASK != 0;
    }

    function _getFrozen(uint256 configData) internal pure returns (bool) {
        return configData & ~FROZEN_MASK != 0;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

interface IAaveMining {
    function claimRewards(address[] calldata assets, uint256 amount, address to)
        external
        returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

// Aave lending pool interface
// Documentation: https://docs.aave.com/developers/the-core-protocol/lendingpool/ilendingpool
// refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
interface ILendingPool {
    struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
        uint256 data;
    }

    struct ReserveData {
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     *
     */
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    )
        external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     *
     */
    function withdraw(address asset, uint256 amount, address to)
        external
        returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     *
     */
    function getReserveData(address asset)
        external
        view
        returns (ReserveData memory);

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: GNU-GPL

pragma solidity >=0.8.0;

import "./interfaces/IResonate.sol";
import "./interfaces/IResonateHelper.sol";
import "./interfaces/ISmartWallet.sol";
import "./interfaces/IFNFTHandler.sol";
import "./interfaces/IAddressRegistry.sol";
import "./utils/BytesLib.sol";

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./SmartWallet.sol";
import "./PoolSmartWallet.sol";

contract ResonateHelper is IResonateHelper, AccessControl {

    using BytesLib for bytes;

    /// The address of the PoolSmartWallet template contract for queued orders
    address public override POOL_TEMPLATE;

    /// The address of the SmartWallet template contract for active FNFTs
    address public override FNFT_TEMPLATE;

    /// The 'SandwichBot' which may trigger privileged actions
    address public immutable override SANDWICH_BOT_ADDRESS;

    /// The role which may invoke the break-glass functionality and disable Resonate
    bytes32 public constant BREAKER = 'BREAKER';    

    /// The role which may unbreak the glass and reenable Resonate
    bytes32 public constant ADMIN = 'ADMIN';

    /// owner will be set to deployer at creation, then immediately to Resonate
    address public override owner;
    
    /// Whether Resonate is in a disabled state
    bool public isPaused;

    uint private constant PRECISION = 1 ether;

    uint public constant FEE = 5;
    uint public constant DENOM = 100;

    /// Function selectors that are illegal to use. This is a one-way mapping and once blacklisted something cannot be un-blacklisted
    /// Blocks any attempts to whitelist function selectors on the blacklist
    mapping(uint32 => bool) blackListedFunctionSignatures;

    /// Function selectors that are allowed for arbitrary call execution
    mapping(uint32 => bool) whiteListedFunctionSignatures;

    /**
     * @notice The constructor called when ResonateHelper is deployed
     * @param _sandwichBot The address that is allowed to make arbitrary calls for passthrough governance
     * @dev Recommended to use a contract for sandwichBot with access control on it, rather than an EOA
     */
    constructor(address _sandwichBot) {
        SANDWICH_BOT_ADDRESS = _sandwichBot;
        owner = msg.sender;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(BREAKER, msg.sender);
        _setupRole(ADMIN, msg.sender);
        _setRoleAdmin(BREAKER, ADMIN);

        // Hardcoded blacklist entries
        blackListFunction(0x095ea7b3); // "approve(address,uint256)"
        blackListFunction(0x39509351); // "increaseAllowance(address,uint256)"
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyResonate() {
        require(msg.sender == owner, "ER024");
        _;
    }
    
    /**
     * @dev Throws if called by any account other than the sandwich bot
     */
    modifier onlySandwichBot() {
        require(msg.sender == SANDWICH_BOT_ADDRESS, "ER020");
        _;
    }

    /**
     * @dev Throws if the contract's operation has been paused
     */
    modifier glassUnbroken {
        require(!isPaused, "ER027");
        _;
    }



    ///
    /// Transactional Functions
    ///

     /// To be used by the sandwich bot for bribe system. Can only withdraw assets back to vault not externally
    /**
     * @notice Triggers the withdrawal or deposit of vault-bound assets for purposes of metagovernance to/from their enclosing ISmartWallet instance
     * @param poolId The ID for the pool whose ISmartWallet instance should be targeted
     * @param vault The underlying vaultToken if adapter, ERC-4626 vault if not
     * @param vaultAdapter The ERC-4626 vault adapter or the ERC-4626-compliant vault
     * @param amount The amount of tokens to withdraw/deposit to/from the ISmartWallet depository
     * @param isWithdrawal Whether these tokens are being removed for use in a vote (true) or being put back after a vote has been effected (false)
     * @dev This can only move tokens in and out of their associated vaults into and out of their associated depositories. It cannot transfer them elsewhere
     * @dev Requires correct MEV flashbots config to function as intended, withdrawal, vote, and deposit should occur within a single transaction
     */
    function sandwichSnapshot(
        bytes32 poolId, 
        address vault, 
        address vaultAdapter,
        uint amount, 
        bool isWithdrawal
    ) external override onlySandwichBot glassUnbroken {
        ISmartWallet(_getWalletForFNFT(poolId)).withdrawOrDeposit(vault, vaultAdapter, amount, isWithdrawal);
    }

    /**
     * @notice Allows for arbitrary calls to be made via ISmartWallet depository contracts – intended to allow voting and bribes to function normally
     * @param poolId The poolId which the ISmartWallet contract is associated with
     * @param targets the contract(s) to target for the list of calls
     * @param values The Ether values to transfer (typically zero)
     * @param calldatas Encoded calldata for each function
     * @dev Calldata must be properly encoded and function selectors must be on the whitelist for this method to function. Functions cannot transfer tokens out
     */
    function proxyCall(bytes32 poolId, address[] memory targets, uint[] memory values, bytes[] memory calldatas) external onlySandwichBot glassUnbroken {
        for (uint256 i = 0; i < targets.length; i++) {
            require(calldatas[i].length >= 4, "ER028"); //Prevent calling fallback function for re-entry attack
            bytes memory selector = BytesLib.slice(calldatas[i], 0, 4);
            uint32 fxSelector = BytesLib.toUint32(selector, 0);
            require(whiteListedFunctionSignatures[fxSelector], "ER025");
        }
        (,address vault,address vaultAdapter,,,,) = IResonate(owner).pools(poolId);
        address asset = IERC4626(vaultAdapter).asset();
        ISmartWallet(_getWalletForFNFT(poolId)).proxyCall(asset, vault, vaultAdapter, targets, values, calldatas);
    }

    /**
     * 
     */
    function getWalletForPool(bytes32 poolId) external override onlyResonate glassUnbroken returns (address smartWallet) {
        address wallet = getAddressForPool(poolId);
        if(_isContractDeployed(wallet)) {
            smartWallet = wallet;
        } else {
            smartWallet = Clones.cloneDeterministic(POOL_TEMPLATE, poolId);
        }
    }

    function getWalletForFNFT(bytes32 fnftId) external override onlyResonate glassUnbroken returns (address wallet) {
        wallet = _getWalletForFNFT(fnftId);
    }


    ///
    /// Utility Functions
    ///

    function _getWalletForFNFT(bytes32 fnftId) private glassUnbroken returns (address wallet) {
        wallet = getAddressForFNFT(fnftId);
        if(!_isContractDeployed(wallet)) {
            wallet = Clones.cloneDeterministic(FNFT_TEMPLATE, keccak256(abi.encode(fnftId)));
        } 
    }

    ///
    /// Admin Functions
    ///

    function setResonate(address resonate) external override onlyResonate {
        require(FNFT_TEMPLATE == address(0));

        ResonateSmartWallet wallet = new ResonateSmartWallet(resonate);
        PoolSmartWallet poolWallet = new PoolSmartWallet(resonate);

        FNFT_TEMPLATE = address(wallet);
        POOL_TEMPLATE = address(poolWallet);

        address oldOwner = owner;
        owner = resonate;

        emit OwnershipTransferred(oldOwner, resonate);
    }

    function blackListFunction(uint32 selector) public onlyRole(ADMIN) {
        blackListedFunctionSignatures[selector] = true;
        if(whiteListedFunctionSignatures[selector]) {
            whiteListedFunctionSignatures[selector] = false;
        }
    }

    function whiteListFunction(uint32 selector, bool isWhitelisted) external onlyRole(ADMIN) {
        require(!blackListedFunctionSignatures[selector], "ER030");
        whiteListedFunctionSignatures[selector] = isWhitelisted;
    }

    ///
    /// EMERGENCY FUNCTIONS
    ///

    /// This function breaks the Revest Protocol, temporarily
    /// For use in emergency situations to offline deposits and withdrawals
    /// While making all value stored within totally inaccessible 
    /// Only requires one person to 'throw the switch' to disable entire protocol
    function breakGlass() external onlyRole(BREAKER) {
        isPaused = true;
    }


    /// Unpauses the token when the danger has passed
    /// Requires multisig governance system to agree to unpause
    function repairGlass() external onlyRole(ADMIN) {
        isPaused = false;
    }

    ///
    /// View Functions
    ///

    function getPoolId(
        address asset, 
        address vault,
        address adapter,
        uint128 rate,
        uint128 _additional_rate,
        uint32 lockupPeriod, 
        uint packetSize
    ) external pure override returns (bytes32 poolId) {
        poolId = keccak256(abi.encodePacked(asset, vault, adapter, rate, _additional_rate, lockupPeriod, packetSize));
    }

    /**
     * @notice Calculates the interest owed on an FNFT, excluding any residuals stored within that will require a withdrawal to retreive
     * @param fnftId the ID of the interest-bearing FNFT to check the interest on
     * @return interest A lower-bound estimate of the interest that making a claim will return
     * @return interestAfterFee A lower-bound estimate of the interest that the user will receive after fees are charged
     * @dev This will typically return lower-bound values because of the design of ERC-4626 preview functions to use lower-bounds 
     */
    function calculateInterest(uint fnftId) external view override returns (uint256 interest, uint256 interestAfterFee) {
        IResonate resonate = IResonate(owner);
        uint index = resonate.fnftIdToIndex(fnftId);

        (uint principalId, uint sharesPerPacket,, bytes32 poolId) = resonate.activated(index);
        (,, address vaultAdapter,,,, uint256 packetSize) = resonate.pools(poolId);
        IERC4626 vault = IERC4626(vaultAdapter);
        uint prinPackets = IFNFTHandler(IAddressRegistry(resonate.REGISTRY_ADDRESS()).getRevestFNFT()).getSupply(principalId);
        {
            uint assetShares = vault.previewWithdraw(prinPackets * packetSize); // shares for current principal
            uint totalShares = sharesPerPacket * prinPackets / PRECISION; // Shares you own, with recovered PRECISION

            if(totalShares < assetShares) {
                interest = 0;
            } else {
                // interest = delta of what you got at deposit and what they're worth now
                interest = vault.previewRedeem(totalShares - assetShares);
            }
        }
        
        uint residual = resonate.residuals(fnftId);
        if (residual > 0) {
            interest += vault.previewRedeem(residual);
        }

        interestAfterFee = interest- (interest * FEE / DENOM);
    } 

    /**
     * 
     */
    function getAddressForPool(bytes32 poolId) public view override glassUnbroken returns (address smartWallet) {
        smartWallet = Clones.predictDeterministicAddress(POOL_TEMPLATE, poolId);
    }

    function getAddressForFNFT(bytes32 fnftId) public view override glassUnbroken returns (address smartWallet) {
        smartWallet = Clones.predictDeterministicAddress(FNFT_TEMPLATE, keccak256(abi.encode(fnftId)));
    }

    function nextInQueue(bytes32 poolId, bool isProvider) external view override returns (IResonate.Order memory order) {
        IResonate resonate = IResonate(owner);
        IResonate.PoolQueue memory queue;
        {
            (uint64 a, uint64 b, uint64 c, uint64 d) = resonate.queueMarkers(poolId);
            queue = IResonate.PoolQueue(a,b,c,d);
        }
        if(isProvider) { 
            (uint a,uint b,bytes32 c) = resonate.providerQueue(poolId, queue.providerHead);
            order = IResonate.Order(a,b,c);
        } else {
           (uint a,uint b,bytes32 c) = resonate.consumerQueue(poolId, queue.consumerHead);
            order = IResonate.Order(a,b,c);
        }
    }

    function isQueueEmpty(bytes32 poolId, bool isProvider) external view override returns (bool isEmpty) {
        IResonate resonate = IResonate(owner);
        IResonate.PoolQueue memory qm;
        {
            (uint64 a, uint64 b, uint64 c, uint64 d) = resonate.queueMarkers(poolId);
            qm = IResonate.PoolQueue(a,b,c,d);
        }
        isEmpty = isProvider ? qm.providerHead == qm.providerTail : qm.consumerHead == qm.consumerTail;
    }

    function _isContractDeployed(address checkAdd) private view returns (bool isDeployed) {
        uint32 size;
        assembly {
            size := extcodesize(checkAdd)
        }
        isDeployed = size > 0;
    }

}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: GNU-GPL v3.0 or later

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IERC4626.sol";
import "./interfaces/IPoolWallet.sol";



/// @author RobAnon
/** @title Pool Smart Wallet. */
contract PoolSmartWallet is IPoolWallet, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using ERC165Checker for address;

    /// Address for msg.sender
    address public immutable override MASTER;
    /// Resonate address
    address public immutable override RESONATE;

    /// IERC20 Interface ID
    bytes4 public constant IERC20_INTERFACE = type(IERC20).interfaceId;

    constructor(address _resonate) {
        MASTER = msg.sender;
        RESONATE = _resonate;
    }

    /**
     * @dev Throws if called by any account other than master or resonate.
     */
    modifier onlyMaster() {
        require(msg.sender == MASTER || msg.sender == RESONATE, 'E016');
        _;
    }

    /// @dev value is inclusive of fee
    function withdraw(uint value, uint fee, address token, address recipient, address devWallet) external override onlyMaster nonReentrant {
        IERC20(token).safeTransfer(recipient, value - fee);
        if(fee > 0 && devWallet != address(0)) {
            IERC20(token).safeTransfer(devWallet, fee);
        }
    }

    function withdrawFromVault(uint shares, address receiver, address vault) external override onlyMaster nonReentrant returns (uint tokens) {
        tokens = IERC4626(vault).redeem(shares, receiver, address(this));
    }

    function activateExistingConsumerPosition(
        uint amountUnderlying, 
        uint totalShares, 
        address fnftWallet,
        address devWallet,
        address vaultToken,
        address vaultAdapter
    ) external override onlyMaster nonReentrant returns (uint shares, uint interest) {
        IERC4626 vault = IERC4626(vaultAdapter);
        _checkApproval(amountUnderlying, vaultToken, vaultAdapter);
        uint totalValueOfShares = vault.previewRedeem(totalShares);
        if(totalValueOfShares > amountUnderlying) {
            interest = totalValueOfShares - amountUnderlying;
        }

        // Where devs take profits         
        // Withdraw is acceptable here since it is proceeded by previewRedeem
        shares = interest > 0 ? totalShares - vault.withdraw(interest, devWallet, address(this)) : totalShares;
        IERC20(vaultAdapter).safeTransfer(fnftWallet, shares);
    }

    /// @dev Amount underlying is inclusive of fee
    function activateExistingProducerPosition(
        uint amountUnderlying, 
        uint totalShares, 
        uint fee,
        address consumer,
        address devWallet,
        address vaultToken,
        address vaultAdapter
    ) external override onlyMaster nonReentrant returns (uint interest) {
        _checkApproval(amountUnderlying, vaultToken, vaultAdapter);
        IERC4626 vault = IERC4626(vaultAdapter);
        IERC20 asset = IERC20(vault.asset());

        // Edge-case handling for withdrawal fees
        uint assets = vault.redeem(totalShares, address(this), address(this));
        if(assets > amountUnderlying) {
            interest = assets - amountUnderlying;
        } else {
            // Recalculate fee to avoid over-charging percentagewise
            fee = assets * fee / amountUnderlying;
        }
        
        asset.safeTransfer(consumer, amountUnderlying-fee);
        asset.safeTransfer(devWallet, interest + fee);
    }

    function _checkApproval(uint amountUnderlying, address vaultToken, address vaultAdapter) private {
        if(IERC20(vaultToken).allowance(address(this), vaultAdapter) < amountUnderlying) {
            IERC20(vaultToken).safeApprove(vaultAdapter, 0);
            IERC20(vaultToken).safeApprove(vaultAdapter, type(uint).max);
        }
    }

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import "../../interfaces/adapters/yearn/IVaultWrapper.sol";
import {BeefyAPI, IBeefyStrat} from "../../interfaces/adapters/yearn/BeefyAPI.sol";

import "../../interfaces/IERC4626.sol";
import {FixedPointMathLib} from "../../lib/FixedPointMathLib.sol";
import "@prb/math/contracts/PRBMathUD60x18.sol";

import "hardhat/console.sol";

contract BeefyWrapper is ERC20, IVaultWrapper, IERC4626, Ownable {

    using SafeERC20 for IERC20;
    using FixedPointMathLib for uint;
    using PRBMathUD60x18 for uint;


    BeefyAPI public immutable yVault;
    address public immutable token;
    uint256 public immutable _decimals;

    constructor(address _vault)
        ERC20(
            "Beefy-4646-Adapter",
            "Beefy-4646"
        )
    {
        yVault = BeefyAPI(_vault);
        token = address(yVault.want());
        _decimals = uint8(yVault.decimals());

        IERC20(token).approve(address(yVault), type(uint).max);
    }

    function vault() external view returns (address) {
        return address(yVault);
    }

    // NOTE: this number will be different from this token's totalSupply
    function vaultTotalSupply() external view returns (uint256) {
        return yVault.totalSupply();
    }

    /*//////////////////////////////////////////////////////////////
                      ERC20 compatibility
   //////////////////////////////////////////////////////////////*/

    function decimals() public view override(ERC20,IERC4626) returns (uint8) {
        return uint8(_decimals);
    }

    function asset() external view override returns (address) {
        return token;
    }

    /*//////////////////////////////////////////////////////////////
                      DEPOSIT/WITHDRAWAL LOGIC
  //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver)
        public
        override
        returns (uint256 shares)
    {
        (assets, shares) = _deposit(assets, receiver, msg.sender);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function mint(uint256 shares, address receiver)
        public
        override
        returns (uint256 assets)
    {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        uint256 expectedMint = shares;
        (assets, shares) = _deposit(assets, receiver, msg.sender);

        require(shares == expectedMint, "Amount of shares minted does not match requested amount");

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    // TODO: add allowance check to use owner argument
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override returns (uint256 shares) {

        (uint256 _withdrawn, uint256 _burntShares) = _withdraw(
            assets,
            receiver,
            msg.sender
        );

        if (owner != msg.sender) {
            require(allowance(owner, msg.sender) >= shares, "Cannot burn shares you are not permissioned to burn");
            
            uint256 currentAllowance = allowance(owner, msg.sender);
            _approve(owner, msg.sender, currentAllowance - shares);
        }

        emit Withdraw(msg.sender, receiver, owner, _withdrawn, _burntShares);
        return _burntShares;
    }

    // TODO: add allowance check to use owner argument
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override returns (uint256 assets) {
        require(shares != 0, "ZERO_SHARES");


        if (owner != msg.sender) {
            require(allowance(owner, msg.sender) >= shares, "Cannot burn shares you are not permissioned to burn");
            
            uint256 currentAllowance = allowance(owner, msg.sender);
            _approve(owner, msg.sender, currentAllowance - shares);
        }

        (uint256 _withdrawn, uint256 _burntShares) = _redeem(
            shares,
            receiver,
            msg.sender
        );

        require(_burntShares == shares, "must burn exactly the same number of shares");
        

        emit Withdraw(msg.sender, receiver, owner, _withdrawn, _burntShares);
        assets = _withdrawn;

    }

    /*//////////////////////////////////////////////////////////////
                          ACCOUNTING LOGIC
  //////////////////////////////////////////////////////////////*/

    function totalAssets() public view override returns (uint256) {
        return convertYearnSharesToAssets(yVault.balanceOf(address(this)));
    }

    function convertToShares(uint assets)
        public
        view
        override
        returns (uint shares)
    {
        uint supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.
        uint localAssets = convertYearnSharesToAssets(yVault.balanceOf(address(this)));
        return supply == 0 ? assets : assets.mulDivDown(supply, localAssets); 
    }

    function convertToAssets(uint shares)
        public
        view
        override
        returns (uint assets)
    {
        uint supply = totalSupply();
        uint localAssets = convertYearnSharesToAssets(yVault.balanceOf(address(this)));
        return supply == 0 ? shares : shares.mulDivDown(localAssets, supply);
    }

    // Each pair is functionally the same?? Just intented for different contexts?
    function previewDeposit(uint assets)
        public
        view
        override
        returns (uint shares)
    {
        return convertToShares(assets);
    }

    function previewWithdraw(uint256 assets)
        public
        view
        override
        returns (uint shares)
    {
        BeefyAPI _vault = yVault;
        IBeefyStrat strat = IBeefyStrat(_vault.strategy());
        uint fee = strat.withdrawalFee();
        uint DIVISOR = strat.WITHDRAWAL_MAX();

        uint adjustedAmount;
        adjustedAmount = assets.mulDivUp(DIVISOR, DIVISOR - fee);

        uint yearnShares = _vault.balanceOf(address(this)).fromUint();
        uint yearnSupply = _vault.totalSupply().fromUint();
        uint localAssets = yearnSupply == 0 ? yearnShares : yearnShares.mul(_vault.balance().fromUint().div(yearnSupply));
        localAssets = localAssets.toUint();     
        
        uint supply = totalSupply();
        shares = localAssets == 0 ? adjustedAmount : adjustedAmount.mulDivUp(supply, localAssets);
          
    }

    function previewMint(uint256 shares)
        public
        view
        override
        returns (uint assets)
    {
        uint supply = totalSupply();
        uint localAssets = convertYearnSharesToAssets(yVault.balanceOf(address(this)));
        assets = supply == 0 ? shares : shares.mulDivUp(localAssets, supply);
    }

    function previewRedeem(uint256 shares)
        public
        view
        override
        returns (uint assets)
    {
        BeefyAPI _vault = yVault;
        uint ySupply = _vault.balanceOf(address(this)); 
        uint yearnShares = ySupply == 0 ? shares : shares.mulDivDown(ySupply, totalSupply());
        yearnShares = Math.min(_vault.balanceOf(address(this)), yearnShares);
        assets = convertYearnSharesToAssets(yearnShares);
        IBeefyStrat strat = IBeefyStrat(yVault.strategy());
        uint fee = strat.withdrawalFee();
        uint DIVISOR = strat.WITHDRAWAL_MAX();
        assets -= assets * fee / DIVISOR;
    }

    /*//////////////////////////////////////////////////////////////
                    DEPOSIT/WITHDRAWAL LIMIT LOGIC
  //////////////////////////////////////////////////////////////*/

    function maxDeposit(address _account)
        public
        view
        override
        returns (uint256)
    {
        return 2 ** 256 - 1;
    }

    function maxMint(address _account)
        external
        view
        override
        returns (uint256)
    {
        return convertToShares(maxDeposit(_account));
    }

    function maxWithdraw(address owner)
        external
        view
        override
        returns (uint256)
    {
        return convertToAssets(this.balanceOf(owner));
    }

    function maxRedeem(address owner) external view override returns (uint256) {
        return this.balanceOf(owner);
    }

     function _deposit(
        uint256 amount, // if `MAX_UINT256`, just deposit everything
        address receiver,
        address depositor
    ) internal returns (uint256 deposited, uint256 mintedShares) {
        BeefyAPI _vault = yVault;
        IERC20 _token = IERC20(token);

        if (amount == type(uint256).max) {
            amount = Math.min(
                _token.balanceOf(depositor),
                _token.allowance(depositor, address(this))
            );
        }

        _token.safeTransferFrom(depositor, address(this), amount);

        uint _allowance = _token.allowance(address(this), address(_vault));
        if (_allowance < amount) {
            if (_allowance > 0) {
                _token.safeApprove(address(_vault), 0);
            }
            _token.safeApprove(address(_vault), type(uint256).max);
        }
        // beforeDeposit custom logic

        // Depositing returns number of shares deposited
        uint256 beforeBal = _token.balanceOf(address(this));

        mintedShares = previewDeposit(amount);

        _vault.deposit(amount);
        uint256 afterBal = _token.balanceOf(address(this));
        deposited = beforeBal - afterBal;
        require(deposited >= amount, "All assets not deposited");

        // afterDeposit custom logic
        _mint(receiver, mintedShares);
    }

    function _withdraw(
        uint256 amount, // if `MAX_UINT256`, just withdraw everything
        address receiver,
        address sender
    ) internal returns (uint256 assets, uint256 shares) {
        
        IERC20 _token = IERC20(token);
        BeefyAPI _vault = yVault;
        IBeefyStrat strat = IBeefyStrat(_vault.strategy());
        console.log(address(strat));

        uint fee = strat.withdrawalFee();
        uint DIVISOR = strat.WITHDRAWAL_MAX();

        uint adjustedAmount;
        adjustedAmount = amount.mulDivUp(DIVISOR, DIVISOR - fee);

        console.log("adjusted amount: ", adjustedAmount);


        shares = upConvertToShares(adjustedAmount); 
        uint yearnShares = convertAssetsToYearnShares(adjustedAmount);
        uint senderBal = balanceOf(sender);

         if (shares > senderBal) {
            revert NotEnoughAvailableSharesForAmount();
        }

        if(yearnShares == 0 || shares == 0) {
            revert NoAvailableShares();
        }

        uint beforeYearnBal = _vault.balanceOf(address(this));

        _burn(sender, shares);

        _vault.withdraw(yearnShares);
        assets = _token.balanceOf(address(this));

        console.log("assets: ", assets);
        console.log("amount: ", amount);

        if(assets < amount) {
            revert NotEnoughAvailableSharesForAmount();
        }

        _token.safeTransfer(receiver, assets);
    }

    function _redeem(
        uint256 shares, 
        address receiver,
        address sender
    ) internal returns (uint256 assets, uint256 sharesBurnt) {
        IERC20 _token = IERC20(token);
        
        BeefyAPI _vault = yVault;
        uint yearnShares = convertSharesToYearnShares(shares);
        yearnShares = Math.min(_vault.balanceOf(address(this)), yearnShares);
        if(yearnShares == 0 || shares == 0) {
            revert NoAvailableShares();
        }
        _burn(sender, shares);
        sharesBurnt = shares;

        uint preBalance = _token.balanceOf(address(this));
        _vault.withdraw(yearnShares);

        assets = _token.balanceOf(address(this)) - preBalance;
        _token.safeTransfer(receiver, assets);
    }


    ///
    /// VIEW METHODS
    ///

    function convertAssetsToYearnShares(uint assets) internal view returns (uint yShares) {
        BeefyAPI _vault = yVault;
        uint256 totalYearnShares = _vault.totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.
        uint totalYearnAssets = _vault.balance();
        return totalYearnAssets == 0 ? assets : assets.mulDivUp(totalYearnShares, totalYearnAssets);
    }

    function convertYearnSharesToAssets(uint yearnShares) internal view returns (uint assets) {
        BeefyAPI _vault = yVault;
        uint supply = _vault.totalSupply();
        return supply == 0 ? yearnShares : yearnShares * _vault.balance() / supply;
    }

    function convertSharesToYearnShares(uint shares) internal view returns (uint yShares) {
        uint supply = totalSupply(); 
        return supply == 0 ? shares : shares.mulDivUp(yVault.balanceOf(address(this)), totalSupply());
    }

        //1000000000000004711
    function upConvertToShares(uint256 assets) internal view returns (uint shares)
    {
        BeefyAPI _vault = yVault;
        uint yearnShares = _vault.balanceOf(address(this)).fromUint();
        uint yearnSupply = _vault.totalSupply().fromUint(); 
        uint localAssets = yearnSupply == 0 ? yearnShares : yearnShares.mul(_vault.balance().fromUint().div(yearnSupply));        
        
        // Actual division result: 137162292780573749444.22899888592124765312 (preferred to round down here actually)
        uint supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.

        // Order matters a lot HERE
        shares = supply == 0 ? assets : assets.mulDivUp(supply, localAssets.toUint());

        // console.log("yearn shares: ", yearnShares); //131342545369752666136
        // console.log("yearn supply: ", yearnSupply); //618232536613632826746679 
        // console.log("Local assets: ", localAssets); //137162292780573749444 (good agreement) 
        // console.log("Share supply: ", supply); // 137199085241083560000
        // console.log("Shares are: ", shares);
    }

    function allowance(address owner, address spender) public view virtual override(ERC20,IERC4626) returns (uint256) {
        return super.allowance(owner,spender);
    }

    function balanceOf(address account) public view virtual override(ERC20,IERC4626) returns (uint256) {
        return super.balanceOf(account);
    }

    function name() public view virtual override(ERC20,IERC4626) returns (string memory) {
        return super.name();
    }

    function symbol() public view virtual override(ERC20,IERC4626) returns (string memory) {
        return super.symbol();
    }

    function totalSupply() public view virtual override(ERC20,IERC4626) returns (uint256) {
        return super.totalSupply();
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}


interface BeefyAPI is IERC20 {

    function strategy() external view returns (IBeefyStrat strat);

    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function decimals() external view returns (uint256);

    function want() external view returns (IERC20);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);

    function deposit(uint256 amount) external;
    function depositLimit() external view returns (uint256);

    function withdraw(uint256 maxShares) external;

    function token() external view returns (address);

    function pricePerShare() external view returns (uint256);
    function getPricePerFullShare() external view returns (uint256);
    function balance() external view returns (uint256);

    function totalAssets() external view returns (uint256);

}

interface IBeefyStrat {
    function withdrawalFee() external view returns (uint fee);
    function WITHDRAWAL_MAX() external view returns (uint divisor);
}

// SPDX-License-Identifier: GNU-GPL
pragma solidity >=0.8.0;

import "./interfaces/IAddressRegistry.sol";
import "./interfaces/IOutputReceiverV3.sol";
import "./interfaces/IFNFTHandler.sol";
import "./interfaces/IResonate.sol";
import "./interfaces/IERC20Detailed.sol";
import "./interfaces/IResonateHelper.sol";
import "./interfaces/IERC4626.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/** @title Output Receiver Proxy. */
contract OutputReceiverProxy is Ownable, IOutputReceiverV3, ERC165 {

    /// Resonate address
    address public resonate;
    /// Address registry
    address public immutable ADDRESS_REGISTRY;

    /// Vault for tokens
    address public TOKEN_VAULT;

    /// Whether or not Resonate is set
    bool private _resonateSet;

    /// FNFT Handler address, immutable for increased decentralization
    IFNFTHandler private immutable FNFT_HANDLER;

    address public REVEST;

    string public constant METADATA = "https://revest.mypinata.cloud/ipfs/QmVH3yBXGdY7etrJhHtGQjvwHpkmHfWZbB1vxDaGGGr3jz";

    constructor(address _addressRegistry) {
        ADDRESS_REGISTRY = _addressRegistry;
        TOKEN_VAULT = IAddressRegistry(_addressRegistry).getTokenVault();
        FNFT_HANDLER = IFNFTHandler(IAddressRegistry(_addressRegistry).getRevestFNFT());
        REVEST = IAddressRegistry(ADDRESS_REGISTRY).getRevest();
    }

    function receiveRevestOutput(
        uint fnftId,
        address asset,
        address payable owner,
        uint quantity
    ) external override {
        require(msg.sender == TOKEN_VAULT, 'ER012');
        require(IAddressRegistry(ADDRESS_REGISTRY).getRevest() == REVEST, 'ER042');
        require(IAddressRegistry(ADDRESS_REGISTRY).getRevestFNFT() == address(FNFT_HANDLER), 'ER042');
        IResonate(resonate).receiveRevestOutput(fnftId, asset, owner, quantity);
    }

    function receiveSecondaryCallback(
        uint fnftId,
        address payable owner,
        uint quantity,
        IRevest.FNFTConfig memory config,
        bytes memory args
    ) external payable override {}

    function triggerOutputReceiverUpdate(
        uint fnftId,
        bytes memory
    ) external override {
        require(FNFT_HANDLER.getBalance(msg.sender, fnftId) > 0, 'ER010');
        IResonate(resonate).claimInterest(fnftId, msg.sender);
    }

    function handleFNFTRemaps(uint fnftId, uint[] memory newFNFTIds, address caller, bool cleanup) external {}
    function handleTimelockExtensions(uint fnftId, uint expiration, address caller) external override {}
    function handleAdditionalDeposit(uint fnftId, uint amountToDeposit, uint quantity, address caller) external override {}
    function handleSplitOperation(uint fnftId, uint[] memory proportions, uint quantity, address caller) external override {}

    ///
    /// View Functions
    ///

    function supportsInterface(bytes4 interfaceId) public view override (ERC165, IERC165) returns (bool) {
        return  interfaceId == type(IOutputReceiver).interfaceId
        || interfaceId == type(IOutputReceiverV2).interfaceId
        || interfaceId == type(IOutputReceiverV3).interfaceId
        || super.supportsInterface(interfaceId);
    }

    function getAddressRegistry() external view returns (address) {
        return ADDRESS_REGISTRY;
    }

    function getCustomMetadata(uint) external pure override returns (string memory) {
        return METADATA;
    }

    function getValue(uint fnftId) external view override returns (uint) {
        IResonate resonateContract = IResonate(resonate);
        uint index = resonateContract.fnftIdToIndex(fnftId);
        (uint principalId,,,bytes32 poolId) = resonateContract.activated(index);
        if(fnftId == principalId) {
            (,,,,,, uint256 packetSize) = resonateContract.pools(poolId);
            return packetSize;
        } else {
            uint residual = resonateContract.residuals(fnftId);
            return residual;
        }
    }

    function getAsset(uint fnftId) external view override returns (address asset) {
        IResonate resonateContract = IResonate(resonate);
        uint index = resonateContract.fnftIdToIndex(fnftId);
        (,,,bytes32 poolId) = resonateContract.activated(index);
        (,,address vaultAdapter,,,,) = resonateContract.pools(poolId);
        asset = IERC4626(vaultAdapter).asset();
    }

    function getOutputDisplayValues(uint fnftId) external view override returns (bytes memory output) {
        IResonate instance = IResonate(resonate);
        uint256 principalId;
        bytes32 poolId;
        {
            uint index = instance.fnftIdToIndex(fnftId);
            // Can get interestId from principalId++
            (principalId, ,, poolId) = instance.activated(index);
        }

        (address paymentAsset, address vault, address vaultAdapter,, uint128 rate,, uint packetSize) = instance.pools(poolId);
        address farmedAsset = IERC4626(vaultAdapter).asset();
        uint accruedInterest;
        uint residual;
        if(fnftId > principalId) {
            (accruedInterest,) = IResonateHelper(instance.RESONATE_HELPER()).calculateInterest(fnftId);
            residual = instance.residuals(fnftId);
            if(residual > 0) {
                accruedInterest -= residual;
            }
        } 

        address wallet = IResonateHelper(instance.RESONATE_HELPER()).getAddressForFNFT(poolId);
        // Stack-too-deep always looks terrible
        output = bytes.concat(
            abi.encode(
                accruedInterest, 
                poolId, 
                _formatAsset(farmedAsset), 
                _formatAsset(paymentAsset), 
                vault, vaultAdapter, wallet
            ), 
            abi.encode(
                packetSize, 
                rate, 
                principalId, 
                principalId+1, 
                IERC20Detailed(farmedAsset).decimals()
            )
        );
    }

    function _formatAsset(address asset) private view returns (string memory formatted) {
        formatted = string(abi.encodePacked("[",IERC20Detailed(asset).symbol(),"] ", asset));
    } 

    /// Doesn't do anything, immutable variable
    function setAddressRegistry(address revest) external override {}

    /// Allow for semi-upgradeable Revest contracts, requires Resonate DAO to sign-off on changes
    function updateRevestVariables() external onlyOwner {
        IAddressRegistry registry = IAddressRegistry(ADDRESS_REGISTRY);
        REVEST = registry.getRevest();
        TOKEN_VAULT = registry.getTokenVault();
    }

    function setResonate(address _resonate) external onlyOwner {
        require(!_resonateSet, 'ER031');
        _resonateSet = true;
        resonate = _resonate;
    }

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IOutputReceiverV2.sol";


/**
 * @title Provider interface for Revest FNFTs
 */
interface IOutputReceiverV3 is IOutputReceiverV2 {

    event DepositERC20OutputReceiver(address indexed mintTo, address indexed token, uint amountTokens, uint indexed fnftId, bytes extraData);

    event DepositERC721OutputReceiver(address indexed mintTo, address indexed token, uint[] tokenIds, uint indexed fnftId, bytes extraData);

    event DepositERC1155OutputReceiver(address indexed mintTo, address indexed token, uint tokenId, uint amountTokens, uint indexed fnftId, bytes extraData);

    event WithdrawERC20OutputReceiver(address indexed caller, address indexed token, uint amountTokens, uint indexed fnftId, bytes extraData);

    event WithdrawERC721OutputReceiver(address indexed caller, address indexed token, uint[] tokenIds, uint indexed fnftId, bytes extraData);

    event WithdrawERC1155OutputReceiver(address indexed caller, address indexed token, uint tokenId, uint amountTokens, uint indexed fnftId, bytes extraData);

    function handleTimelockExtensions(uint fnftId, uint expiration, address caller) external;

    function handleAdditionalDeposit(uint fnftId, uint amountToDeposit, uint quantity, address caller) external;

    function handleSplitOperation(uint fnftId, uint[] memory proportions, uint quantity, address caller) external;

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IOutputReceiver.sol";
import "./IRevest.sol";
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';


/**
 * @title Provider interface for Revest FNFTs
 */
interface IOutputReceiverV2 is IOutputReceiver {

    // Future proofing for secondary callbacks during withdrawal
    // Could just use triggerOutputReceiverUpdate and call withdrawal function
    // But deliberately using reentry is poor form and reminds me too much of OAuth 2.0 
    function receiveSecondaryCallback(
        uint fnftId,
        address payable owner,
        uint quantity,
        IRevest.FNFTConfig memory config,
        bytes memory args
    ) external payable;

    // Allows for similar function to address lock, updating state while still locked
    // Called by the user directly
    function triggerOutputReceiverUpdate(
        uint fnftId,
        bytes memory args
    ) external;

    // This function should only ever be called when a split or additional deposit has occurred 
    function handleFNFTRemaps(uint fnftId, uint[] memory newFNFTIds, address caller, bool cleanup) external;

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IRegistryProvider.sol";
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

/**
 * @title Provider interface for Revest FNFTs
 */
interface IOutputReceiver is IERC165, IRegistryProvider {

    function receiveRevestOutput(
        uint fnftId,
        address asset,
        address payable owner,
        uint quantity
    ) external;

    function getCustomMetadata(uint fnftId) external view returns (string memory);

    function getValue(uint fnftId) external view returns (uint);

    function getAsset(uint fnftId) external view returns (address);

    function getOutputDisplayValues(uint fnftId) external view returns (bytes memory);

}

// SPDX-License-Identifier: GNU-GPL
pragma solidity >=0.8.0;

import "./interfaces/IResonateHelper.sol";
import "./interfaces/ISandwichBotProxy.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


/** @title Sandwich Bot Proxy. */
contract SandwichBotProxy is ISandwichBotProxy, AccessControl {

    /// Resonate Helper address
    address public RESONATE_HELPER;

    /// Declares CALLER, VOTER, ADMIN
    bytes32 public constant CALLER = 'CALLER';
    bytes32 public constant VOTER = 'VOTER';
    bytes32 public constant ADMIN = 'ADMIN';

    /**
     * @notice 
     * @dev 
     */
    constructor() {
        // RESONATE_HELPER = _resonateHelper;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN, msg.sender);
        _setupRole(CALLER, msg.sender);
        _setupRole(VOTER, msg.sender);
        _setRoleAdmin(CALLER, ADMIN);
        _setRoleAdmin(VOTER, ADMIN);
    }

    function proxyCall(bytes32 poolId, address[] memory targets, uint[] memory values, bytes[] memory calldatas) external override onlyRole(VOTER) {
        IResonateHelper(RESONATE_HELPER).proxyCall(poolId, targets, values, calldatas);
    }

    function setResonateHelper(address _resonateHelper) external onlyRole(ADMIN) {
        RESONATE_HELPER = _resonateHelper;
    }

    function sandwichSnapshot(
        bytes32 poolId, 
        address vault, 
        address vaultAdapter,
        uint amount, 
        bool isWithdrawal
    ) external override onlyRole(CALLER) {
        IResonateHelper(RESONATE_HELPER).sandwichSnapshot(poolId, vault, vaultAdapter, amount, isWithdrawal);
    }

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;


interface ISandwichBotProxy {
// SPDX-License-Identifier: GNU-GPL


    function proxyCall(bytes32 poolId, address[] memory targets, uint[] memory values, bytes[] memory calldatas) external;

    function setResonateHelper(address _resonateHelper) external;

    function sandwichSnapshot(
        bytes32 poolId, 
        address vault, 
        address vaultAdapter,
        uint amount, 
        bool isWithdrawal
    ) external;

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IRevest.sol";

interface ITokenVault {

    function createFNFT(
        uint fnftId,
        IRevest.FNFTConfig memory fnftConfig,
        uint quantity,
        address from
    ) external;

    function withdrawToken(
        uint fnftId,
        uint quantity,
        address user
    ) external;

    function depositToken(
        uint fnftId,
        uint amount,
        uint quantity
    ) external;

    function cloneFNFTConfig(IRevest.FNFTConfig memory old) external returns (IRevest.FNFTConfig memory);

    function mapFNFTToToken(
        uint fnftId,
        IRevest.FNFTConfig memory fnftConfig
    ) external;

    function handleMultipleDeposits(
        uint fnftId,
        uint newFNFTId,
        uint amount
    ) external;

    function splitFNFT(
        uint fnftId,
        uint[] memory newFNFTIds,
        uint[] memory proportions,
        uint quantity
    ) external;

    function getFNFT(uint fnftId) external view returns (IRevest.FNFTConfig memory);
    function getFNFTCurrentValue(uint fnftId) external view returns (uint);
    function getNontransferable(uint fnftId) external view returns (bool);
    function getSplitsRemaining(uint fnftId) external view returns (uint);
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IRevest.sol";

interface ILockManager {

    function createLock(uint fnftId, IRevest.LockParam memory lock) external returns (uint);

    function getLock(uint lockId) external view returns (IRevest.Lock memory);

    function fnftIdToLockId(uint fnftId) external view returns (uint);

    function fnftIdToLock(uint fnftId) external view returns (IRevest.Lock memory);

    function pointFNFTToLock(uint fnftId, uint lockId) external;

    function lockTypes(uint tokenId) external view returns (IRevest.LockType);

    function unlockFNFT(uint fnftId, address sender) external returns (bool);

    function getLockMaturity(uint fnftId) external view returns (bool);
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "../interfaces/IAddressLock.sol";
import "../interfaces/IAddressRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract SecuredAddressLock is IAddressLock, Ownable {

    IAddressRegistry public addressesProvider;

    constructor(address provider) Ownable() {
        addressesProvider = IAddressRegistry(provider);
    }

    function setAddressRegistry(address registry) external override onlyOwner {
        addressesProvider = IAddressRegistry(registry);
    }

    function getAddressRegistry() external view override returns (address) {
        return address(addressesProvider);
    }

    function createLock(uint fnftId, uint lockId, bytes memory arguments) external virtual {}


    modifier onlyLockManager() virtual {
        require(_msgSender() != address(0), "E004");
        require(_msgSender() == addressesProvider.getLockManager(), 'E074');
        _;
    }

    modifier onlyRevestController() virtual {
        require(_msgSender() != address(0), "E004");
        require(_msgSender() == addressesProvider.getRevest(), "E017");
        _;
    }

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "./utils/BytesLib.sol";
import "@openzeppelin/contracts/utils/Context.sol";


contract GovernanceController is Context {
   
    event FunctionOwnershipTransferred(address indexed previousOwner, address indexed newOwner, uint indexed functionSelector);
    event AdminTransferred(address indexed previousOwner, address indexed newOwner);

    /// Map contract address to map of function identifiers to owners
    mapping(address => mapping(uint => address)) public functionOwner;

    address public admin;

    constructor(address _admin) {
        admin = _admin;
    }

    function batchFunctionCall(address[] memory targets, uint256[] memory values, bytes[] calldata calldatas) external {
        uint tarLength = targets.length;
        require(tarLength == values.length, "ER044");
        require(tarLength == calldatas.length, 'ER044');
        for (uint256 i = 0; i < tarLength; ++i) {
            functionCall(targets[i], values[i], calldatas[i]);
        }
    }

    /**
     * @notice calls a function which the msg.sender has permissions to access on a contract that is owned by this contract
     */
    function functionCall(address target, uint value, bytes calldata data) public {
        require(data.length >= 4, "ER028"); //Prevent calling fallback function for re-entry attack
        bytes memory selector = BytesLib.slice(data, 0, 4);
        uint32 functionSelector = BytesLib.toUint32(selector, 0);
        require(_msgSender() == functionOwner[target][functionSelector], 'ER024');
        (bool success, ) = target.call{value: value}(data);
        require(success, "ER022");
    } 


    /// @dev this should be called during set-up to register all functions and contracts
    function batchRegisterFunctions(address[] memory contracts, address[] memory owners, uint[] memory functionSelectors) external {
        require(_msgSender() == admin, 'ER024');
        uint contractsLength = contracts.length;
        require(contractsLength == owners.length, 'ER044');
        require(contractsLength == functionSelectors.length);
        for(uint i; i < contractsLength; ++i) {
            address contractAddress = contracts[i];
            uint functionSelector = functionSelectors[i];
            address newOwner = owners[i];
            require(functionOwner[contractAddress][functionSelector] == address(0), 'Cannot initialize an existing function');
            functionOwner[contractAddress][functionSelector] = newOwner;
        }
    }

    /**
     * @notice batch transfer ownership of functions to new owners
     */
    function batchTransferOwnership(address[] memory contracts, address[] memory owners, uint[] memory functionSelectors) external {
        uint contractsLength = contracts.length;
        require(contractsLength == owners.length, 'ER044');
        require(contractsLength == functionSelectors.length);
        for(uint i; i < contractsLength; ++i) {
            transferOwnership(contracts[i], owners[i], functionSelectors[i]);
        }
    }

    /**
     * @notice transfer the ownership of a function for a specific contract
     * @dev the contractAddress must be a contract with "owner" set to this contract
     */
    function transferOwnership(address contractAddress, address newOwner, uint functionSelector) public {
        address oldOwner = functionOwner[contractAddress][functionSelector];
        require(_msgSender() == oldOwner, 'ER024');
        functionOwner[contractAddress][functionSelector] = newOwner;
        emit FunctionOwnershipTransferred(oldOwner, newOwner, functionSelector);
    }

    /**
     * @notice allows the admin who can designate the owner for new functions to be transferred
     * @dev the admin can only register new functions and designate their owner once
     */
    function transferAdmin(address newAdmin) external {
        address oldAdmin = admin;
        require(_msgSender() == oldAdmin, 'ER024');
        admin = newAdmin;
        emit AdminTransferred(oldAdmin, newAdmin);
    }

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "../interfaces/IPriceOracle.sol";


/**
 * @title Provider interface for Revest FNFTs
 * @dev Address locks MUST be non-upgradeable to be considered for trusted status
 *
 */
contract mockOracleDispatch is IPriceOracle {

    uint private constant MIN_TIME = 45 minutes;
    
    constructor() {

    }
    
    mapping(address => uint) prices;

    function setPrice(address asset, uint price) external {
        prices[asset] = price;
    }

    
    function getSafePrice(address token) external view returns (uint256 _amountOut) {
        return prices[token];
    }

    /// @dev This method has no guarantee on the safety of the price returned. It should only be
    //used if the price returned does not expose the caller contract to flashloan attacks.
    function getCurrentPrice(address token) external view returns (uint256 _amountOut) {
        return prices[token];
    }

    /// @dev This method returns a flashloan resistant price, but doesn't
    //have the view modifier which makes it convenient to update
    //a uniswap oracle which needs to maintain the TWAP regularly.
    //You can use this function while doing other state changing tx and
    //make the callers maintain the oracle.
    function updateSafePrice(address token) external returns (uint256 _amountOut) {
        return prices[token];
    }

  
}

// SPDX-License-Identifier: GNU-GPL
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


/** 
 * @title DevWallet 
 * @author RobAnon
 */
contract DevWallet is Ownable {

    using SafeERC20 for IERC20;

    /**
     * @notice handle the forwarding of all contained ERC-20s to the recipient address
     * @param tokens the list of tokens to be forwarded
     * @param recipient the address to send those tokens to
     */
    function forwardERC20s(address[] memory tokens, address recipient) external onlyOwner {
        uint length = tokens.length;
        for(uint i = 0; i < length; ++i) {
            address token = tokens[i];
            uint balance = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransfer(recipient, balance);
        }
    }

    /**
     * @notice handles the withdrawal of any ether that has wandered into this contract
     * @param recipient the address to send the Ether to
     */
    function withdrawBalance(address payable recipient) external onlyOwner {
        uint balance = address(this).balance;
        recipient.transfer(balance);
    }

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.13;

import {IERC20} from '../../IERC20.sol';
import {IScaledBalanceToken} from './IScaledBalanceToken.sol';

interface IAToken is IERC20, IScaledBalanceToken {
  /**
   * @dev Emitted after the mint action
   * @param from The address performing the mint
   * @param value The amount being
   * @param index The new liquidity index of the reserve
   **/
  event Mint(address indexed from, uint256 value, uint256 index);

  /**
   * @dev Mints `amount` aTokens to `user`
   * @param user The address receiving the minted tokens
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   * @return `true` if the the previous balance of the user was 0
   */
  function mint(
    address user,
    uint256 amount,
    uint256 index
  ) external returns (bool);

  /**
   * @dev Emitted after aTokens are burned
   * @param from The owner of the aTokens, getting them burned
   * @param target The address that will receive the underlying
   * @param value The amount being burned
   * @param index The new liquidity index of the reserve
   **/
  event Burn(address indexed from, address indexed target, uint256 value, uint256 index);

  /**
   * @dev Emitted during the transfer action
   * @param from The user whose tokens are being transferred
   * @param to The recipient
   * @param value The amount being transferred
   * @param index The new liquidity index of the reserve
   **/
  event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

  /**
   * @dev Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * @param user The owner of the aTokens, getting them burned
   * @param receiverOfUnderlying The address that will receive the underlying
   * @param amount The amount being burned
   * @param index The new liquidity index of the reserve
   **/
  function burn(
    address user,
    address receiverOfUnderlying,
    uint256 amount,
    uint256 index
  ) external;

  /**
   * @dev Mints aTokens to the reserve treasury
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   */
  function mintToTreasury(uint256 amount, uint256 index) external;

  /**
   * @dev Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
   * @param from The address getting liquidated, current owner of the aTokens
   * @param to The recipient
   * @param value The amount of tokens getting transferred
   **/
  function transferOnLiquidation(
    address from,
    address to,
    uint256 value
  ) external;

  /**
   * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
   * assets in borrow(), withdraw() and flashLoan()
   * @param user The recipient of the aTokens
   * @param amount The amount getting transferred
   * @return The amount transferred
   **/
  function transferUnderlyingTo(address user, uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.13;

interface IScaledBalanceToken {
  /**
   * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
   * updated stored balance divided by the reserve's liquidity index at the moment of the update
   * @param user The user whose balance is calculated
   * @return The scaled balance of the user
   **/
  function scaledBalanceOf(address user) external view returns (uint256);

  /**
   * @dev Returns the scaled balance of the user and the scaled total supply.
   * @param user The address of the user
   * @return The scaled balance of the user
   * @return The scaled balance and the scaled total supply
   **/
  function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

  /**
   * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
   * @return The scaled total supply
   **/
  function scaledTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "./interfaces/ISmartWalletChecker.sol";

/// @author RobAnon
contract SmartWalletWhitelistV2 {
    
    mapping(address => bool) public wallets;
    
    bytes32 public constant ADMIN = "ADMIN";

    bytes32 public constant SUPER_ADMIN = "SUPER_ADMIN";

    mapping(address => bytes32) public roles;
    
    address public checker;
    address public future_checker;
    
    event ApproveWallet(address);
    event RevokeWallet(address);
    
    constructor(address _admin) {
        roles[_admin] = ADMIN;
        roles[msg.sender] = SUPER_ADMIN;
    }
    
    function commitSetChecker(address _checker) external {
        require(isAdmin(msg.sender), "!admin");
        future_checker = _checker;
    }

    function changeAdmin(address _admin, bool validAdmin) external {
        require(isAdmin(msg.sender), "!admin");
        require(!isSuperAdmin(_admin), "!auth"); // Overwrite protection
        if(validAdmin) {
            roles[_admin] = ADMIN;
        } else {
            roles[_admin] = 0x0;
        }
    }

    function transferSuperAdmin(address _newAdmin) external {
        require(isSuperAdmin(msg.sender),'!sAdmin');
        roles[msg.sender] = 0x0;
        roles[_newAdmin] = SUPER_ADMIN;
    }
    
    function applySetChecker() external {
        require(isAdmin(msg.sender), "!admin");
        checker = future_checker;
    }
    
    function approveWallet(address _wallet) public {
        require(isAdmin(msg.sender), "!admin");
        wallets[_wallet] = true;
        
        emit ApproveWallet(_wallet);
    }

    function batchApproveWallets(address[] memory _wallets) public {
        require(isAdmin(msg.sender), "!admin");
        for(uint i = 0; i < _wallets.length; i++) {
            wallets[_wallets[i]] = true;
            emit ApproveWallet(_wallets[i]);
        }
    }

    function revokeWallet(address _wallet) external {
        require(isAdmin(msg.sender), "!admin");
        wallets[_wallet] = false;
        
        emit RevokeWallet(_wallet);
    }
    
    function check(address _wallet) external view returns (bool) {
        bool _check = wallets[_wallet];
        if (_check) {
            return _check;
        } else {
            if (checker != address(0)) {
                return ISmartWalletChecker(checker).check(_wallet);
            }
        }
        return false;
    }

    function isAdmin(address checkAdd) internal view returns (bool valid) {
        valid = roles[checkAdd] == ADMIN || roles[checkAdd] == SUPER_ADMIN;
    }

    function isSuperAdmin(address checkAdd) internal view returns (bool valid) {
        valid = roles[checkAdd] == SUPER_ADMIN;
    }
   
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

interface ISmartWalletChecker {
    function check(address) external view returns (bool);
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

interface IOracleDispatch {

    // Attempts to update oracle and returns true if successful. Returns true if update unnecessary
    function updateOracle(address asset, address compareTo) external returns (bool);

    // Will return true if oracle does not need to be poked or if poke was successful
    function pokeOracle(address asset, address compareTo) external returns (bool);

    // Will return true if oracle already initialized, if oracle has successfully been initialized by this call,
    // or if oracle does not need to be initialized
    function initializeOracle(address asset, address compareTo) external returns (bool);

    // Gets the value of the asset
    // Oracle = the oracle address in specific. Optional parameter
    // Inverted pair = whether or not this call represents an inversion of typical type (ERC20 underlying, USDC compareTo) to (USDC underlying, ERC20 compareTo)
    // Must take inverse of value in this case to get REAL value
    function getValueOfAsset(
        address asset,
        address compareTo,
        bool risingEdge
    )  external view returns (uint);

    // Does this oracle need to be updated prior to our reading the price?
    // Return false if we are within desired time period
    // Or if this type of oracle does not require updates
    function oracleNeedsUpdates(address asset, address compareTo) external view returns (bool);

    // Does this oracle need to be poked prior to update and withdrawal?
    function oracleNeedsPoking(address asset, address compareTo) external view returns (bool);

    function oracleNeedsInitialization(address asset, address compareTo) external view returns (bool);

    //Only ever called if oracle needs initialization
    function canOracleBeCreatedForRoute(address asset, address compareTo) external view returns (bool);

    // How long to wait after poking the oracle before you can update it again and withdraw
    function getTimePeriodAfterPoke(address asset, address compareTo) external view returns (uint);

    // Returns a direct reference to the address that the specific contract for this pair is registered at
    function getOracleForPair(address asset, address compareTo) external view returns (address);

    // Returns a boolean if this oracle can provide data for the requested pair, used during FNFT creation
    function getPairHasOracle(address asset, address compareTo) external view returns (bool);

    //Returns the instantaneous price of asset and the decimals for that price
    function getInstantPrice(address asset, address compareTo) external view returns (uint);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division.
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
            // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number.
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x4) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathSD59x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with int256 numbers considered to have 18
/// trailing decimals. We call this number representation signed 59.18-decimal fixed-point, since the numbers can have
/// a sign and there can be up to 59 digits in the integer part and up to 18 decimals in the fractional part. The numbers
/// are bound by the minimum and the maximum values permitted by the Solidity type int256.
library PRBMathSD59x18 {
    /// @dev log2(e) as a signed 59.18-decimal fixed-point number.
    int256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev Half the SCALE number.
    int256 internal constant HALF_SCALE = 5e17;

    /// @dev The maximum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728_792003956564819967;

    /// @dev The maximum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_WHOLE_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728_000000000000000000;

    /// @dev The minimum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728_792003956564819968;

    /// @dev The minimum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_WHOLE_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    int256 internal constant SCALE = 1e18;

    /// INTERNAL FUNCTIONS ///

    /// @notice Calculate the absolute value of x.
    ///
    /// @dev Requirements:
    /// - x must be greater than MIN_SD59x18.
    ///
    /// @param x The number to calculate the absolute value for.
    /// @param result The absolute value of x.
    function abs(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x == MIN_SD59x18) {
                revert PRBMathSD59x18__AbsInputTooSmall();
            }
            result = x < 0 ? -x : x;
        }
    }

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The arithmetic average as a signed 59.18-decimal fixed-point number.
    function avg(int256 x, int256 y) internal pure returns (int256 result) {
        // The operations can never overflow.
        unchecked {
            int256 sum = (x >> 1) + (y >> 1);
            if (sum < 0) {
                // If at least one of x and y is odd, we add 1 to the result. This is because shifting negative numbers to the
                // right rounds down to infinity.
                assembly {
                    result := add(sum, and(or(x, y), 1))
                }
            } else {
                // If both x and y are odd, we add 1 to the result. This is because if both numbers are odd, the 0.5
                // remainder gets truncated twice.
                result = sum + (x & y & 1);
            }
        }
    }

    /// @notice Yields the least greatest signed 59.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as a signed 58.18-decimal fixed-point number.
    function ceil(int256 x) internal pure returns (int256 result) {
        if (x > MAX_WHOLE_SD59x18) {
            revert PRBMathSD59x18__CeilOverflow(x);
        }
        unchecked {
            int256 remainder = x % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                result = x - remainder;
                if (x > 0) {
                    result += SCALE;
                }
            }
        }
    }

    /// @notice Divides two signed 59.18-decimal fixed-point numbers, returning a new signed 59.18-decimal fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDiv".
    /// - None of the inputs can be MIN_SD59x18.
    /// - The denominator cannot be zero.
    /// - The result must fit within int256.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDiv".
    ///
    /// @param x The numerator as a signed 59.18-decimal fixed-point number.
    /// @param y The denominator as a signed 59.18-decimal fixed-point number.
    /// @param result The quotient as a signed 59.18-decimal fixed-point number.
    function div(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == MIN_SD59x18 || y == MIN_SD59x18) {
            revert PRBMathSD59x18__DivInputTooSmall();
        }

        // Get hold of the absolute values of x and y.
        uint256 ax;
        uint256 ay;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
        }

        // Compute the absolute value of (x*SCALE)÷y. The result must fit within int256.
        uint256 rAbs = PRBMath.mulDiv(ax, uint256(SCALE), ay);
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__DivOverflow(rAbs);
        }

        // Get the signs of x and y.
        uint256 sx;
        uint256 sy;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
        }

        // XOR over sx and sy. This is basically checking whether the inputs have the same sign. If yes, the result
        // should be positive. Otherwise, it should be negative.
        result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Returns Euler's number as a signed 59.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (int256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// Caveats:
    /// - All from "exp2".
    /// - For any x less than -41.446531673892822322, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp(int256 x) internal pure returns (int256 result) {
        // Without this check, the value passed to "exp2" would be less than -59.794705707972522261.
        if (x < -41_446531673892822322) {
            return 0;
        }

        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathSD59x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            int256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - For any x less than -59.794705707972522261, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp2(int256 x) internal pure returns (int256 result) {
        // This works because 2^(-x) = 1/2^x.
        if (x < 0) {
            // 2^59.794705707972522262 is the maximum number whose inverse does not truncate down to zero.
            if (x < -59_794705707972522261) {
                return 0;
            }

            // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
            unchecked {
                result = 1e36 / exp2(-x);
            }
        } else {
            // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
            if (x >= 192e18) {
                revert PRBMathSD59x18__Exp2InputTooBig(x);
            }

            unchecked {
                // Convert x to the 192.64-bit fixed-point format.
                uint256 x192x64 = (uint256(x) << 64) / uint256(SCALE);

                // Safe to convert the result to int256 directly because the maximum input allowed is 192.
                result = int256(PRBMath.exp2(x192x64));
            }
        }
    }

    /// @notice Yields the greatest signed 59.18 decimal fixed-point number less than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be greater than or equal to MIN_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as a signed 58.18-decimal fixed-point number.
    function floor(int256 x) internal pure returns (int256 result) {
        if (x < MIN_WHOLE_SD59x18) {
            revert PRBMathSD59x18__FloorUnderflow(x);
        }
        unchecked {
            int256 remainder = x % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                result = x - remainder;
                if (x < 0) {
                    result -= SCALE;
                }
            }
        }
    }

    /// @notice Yields the excess beyond the floor of x for positive numbers and the part of the number to the right
    /// of the radix point for negative numbers.
    /// @dev Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part
    /// @param x The signed 59.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as a signed 59.18-decimal fixed-point number.
    function frac(int256 x) internal pure returns (int256 result) {
        unchecked {
            result = x % SCALE;
        }
    }

    /// @notice Converts a number from basic integer form to signed 59.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be greater than or equal to MIN_SD59x18 divided by SCALE.
    /// - x must be less than or equal to MAX_SD59x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in signed 59.18-decimal fixed-point representation.
    function fromInt(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x < MIN_SD59x18 / SCALE) {
                revert PRBMathSD59x18__FromIntUnderflow(x);
            }
            if (x > MAX_SD59x18 / SCALE) {
                revert PRBMathSD59x18__FromIntOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_SD59x18, lest it overflows.
    /// - x * y cannot be negative.
    ///
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function gm(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            int256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathSD59x18__GmOverflow(x, y);
            }

            // The product cannot be negative.
            if (xy < 0) {
                revert PRBMathSD59x18__GmNegativeProduct(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = int256(PRBMath.sqrt(uint256(xy)));
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as a signed 59.18-decimal fixed-point number.
    function inv(int256 x) internal pure returns (int256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as a signed 59.18-decimal fixed-point number.
    function ln(int256 x) internal pure returns (int256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 195205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as a signed 59.18-decimal fixed-point number.
    function log10(int256 x) internal pure returns (int256 result) {
        if (x <= 0) {
            revert PRBMathSD59x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly mul operation, not the "mul" function defined in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            default {
                result := MAX_SD59x18
            }
        }

        if (result == MAX_SD59x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than zero.
    ///
    /// Caveats:
    /// - The results are not perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as a signed 59.18-decimal fixed-point number.
    function log2(int256 x) internal pure returns (int256 result) {
        if (x <= 0) {
            revert PRBMathSD59x18__LogInputTooSmall(x);
        }
        unchecked {
            // This works because log2(x) = -log2(1/x).
            int256 sign;
            if (x >= SCALE) {
                sign = 1;
            } else {
                sign = -1;
                // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
                assembly {
                    x := div(1000000000000000000000000000000000000, x)
                }
            }

            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(uint256(x / SCALE));

            // The integer part of the logarithm as a signed 59.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255, SCALE is 1e18 and sign is either 1 or -1.
            result = int256(n) * SCALE;

            // This is y = x * 2^(-n).
            int256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result * sign;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (int256 delta = int256(HALF_SCALE); delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
            result *= sign;
        }
    }

    /// @notice Multiplies two signed 59.18-decimal fixed-point numbers together, returning a new signed 59.18-decimal
    /// fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers and employs constant folding, i.e. the denominator is
    /// always 1e18.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - None of the inputs can be MIN_SD59x18
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    ///
    /// @param x The multiplicand as a signed 59.18-decimal fixed-point number.
    /// @param y The multiplier as a signed 59.18-decimal fixed-point number.
    /// @return result The product as a signed 59.18-decimal fixed-point number.
    function mul(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == MIN_SD59x18 || y == MIN_SD59x18) {
            revert PRBMathSD59x18__MulInputTooSmall();
        }

        unchecked {
            uint256 ax;
            uint256 ay;
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);

            uint256 rAbs = PRBMath.mulDivFixedPoint(ax, ay);
            if (rAbs > uint256(MAX_SD59x18)) {
                revert PRBMathSD59x18__MulOverflow(rAbs);
            }

            uint256 sx;
            uint256 sy;
            assembly {
                sx := sgt(x, sub(0, 1))
                sy := sgt(y, sub(0, 1))
            }
            result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
        }
    }

    /// @notice Returns PI as a signed 59.18-decimal fixed-point number.
    function pi() internal pure returns (int256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    /// - z cannot be zero.
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as a signed 59.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as a signed 59.18-decimal fixed-point number.
    /// @return result x raised to power y, as a signed 59.18-decimal fixed-point number.
    function pow(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : int256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (signed 59.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - All from "abs" and "PRBMath.mulDivFixedPoint".
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as a signed 59.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function powu(int256 x, uint256 y) internal pure returns (int256 result) {
        uint256 xAbs = uint256(abs(x));

        // Calculate the first iteration of the loop in advance.
        uint256 rAbs = y & 1 > 0 ? xAbs : uint256(SCALE);

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        uint256 yAux = y;
        for (yAux >>= 1; yAux > 0; yAux >>= 1) {
            xAbs = PRBMath.mulDivFixedPoint(xAbs, xAbs);

            // Equivalent to "y % 2 == 1" but faster.
            if (yAux & 1 > 0) {
                rAbs = PRBMath.mulDivFixedPoint(rAbs, xAbs);
            }
        }

        // The result must fit within the 59.18-decimal fixed-point representation.
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__PowuOverflow(rAbs);
        }

        // Is the base negative and the exponent an odd number?
        bool isNegative = x < 0 && y & 1 == 1;
        result = isNegative ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Returns 1 as a signed 59.18-decimal fixed-point number.
    function scale() internal pure returns (int256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x cannot be negative.
    /// - x must be less than MAX_SD59x18 / SCALE.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as a signed 59.18-decimal fixed-point .
    function sqrt(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x < 0) {
                revert PRBMathSD59x18__SqrtNegativeInput(x);
            }
            if (x > MAX_SD59x18 / SCALE) {
                revert PRBMathSD59x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two signed
            // 59.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = int256(PRBMath.sqrt(uint256(x * SCALE)));
        }
    }

    /// @notice Converts a signed 59.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The signed 59.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toInt(int256 x) internal pure returns (int256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathSD59x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with int256 numbers considered to have 18
/// trailing decimals. We call this number representation signed 59.18-decimal fixed-point, since the numbers can have
/// a sign and there can be up to 59 digits in the integer part and up to 18 decimals in the fractional part. The numbers
/// are bound by the minimum and the maximum values permitted by the Solidity type int256.
library PRBMathSD59x18 {
    /// @dev log2(e) as a signed 59.18-decimal fixed-point number.
    int256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev Half the SCALE number.
    int256 internal constant HALF_SCALE = 5e17;

    /// @dev The maximum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728_792003956564819967;

    /// @dev The maximum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_WHOLE_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728_000000000000000000;

    /// @dev The minimum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728_792003956564819968;

    /// @dev The minimum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_WHOLE_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    int256 internal constant SCALE = 1e18;

    /// INTERNAL FUNCTIONS ///

    /// @notice Calculate the absolute value of x.
    ///
    /// @dev Requirements:
    /// - x must be greater than MIN_SD59x18.
    ///
    /// @param x The number to calculate the absolute value for.
    /// @param result The absolute value of x.
    function abs(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x == MIN_SD59x18) {
                revert PRBMathSD59x18__AbsInputTooSmall();
            }
            result = x < 0 ? -x : x;
        }
    }

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The arithmetic average as a signed 59.18-decimal fixed-point number.
    function avg(int256 x, int256 y) internal pure returns (int256 result) {
        // The operations can never overflow.
        unchecked {
            int256 sum = (x >> 1) + (y >> 1);
            if (sum < 0) {
                // If at least one of x and y is odd, we add 1 to the result. This is because shifting negative numbers to the
                // right rounds down to infinity.
                assembly {
                    result := add(sum, and(or(x, y), 1))
                }
            } else {
                // If both x and y are odd, we add 1 to the result. This is because if both numbers are odd, the 0.5
                // remainder gets truncated twice.
                result = sum + (x & y & 1);
            }
        }
    }

    /// @notice Yields the least greatest signed 59.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as a signed 58.18-decimal fixed-point number.
    function ceil(int256 x) internal pure returns (int256 result) {
        if (x > MAX_WHOLE_SD59x18) {
            revert PRBMathSD59x18__CeilOverflow(x);
        }
        unchecked {
            int256 remainder = x % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                result = x - remainder;
                if (x > 0) {
                    result += SCALE;
                }
            }
        }
    }

    /// @notice Divides two signed 59.18-decimal fixed-point numbers, returning a new signed 59.18-decimal fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDiv".
    /// - None of the inputs can be MIN_SD59x18.
    /// - The denominator cannot be zero.
    /// - The result must fit within int256.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDiv".
    ///
    /// @param x The numerator as a signed 59.18-decimal fixed-point number.
    /// @param y The denominator as a signed 59.18-decimal fixed-point number.
    /// @param result The quotient as a signed 59.18-decimal fixed-point number.
    function div(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == MIN_SD59x18 || y == MIN_SD59x18) {
            revert PRBMathSD59x18__DivInputTooSmall();
        }

        // Get hold of the absolute values of x and y.
        uint256 ax;
        uint256 ay;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
        }

        // Compute the absolute value of (x*SCALE)÷y. The result must fit within int256.
        uint256 rAbs = PRBMath.mulDiv(ax, uint256(SCALE), ay);
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__DivOverflow(rAbs);
        }

        // Get the signs of x and y.
        uint256 sx;
        uint256 sy;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
        }

        // XOR over sx and sy. This is basically checking whether the inputs have the same sign. If yes, the result
        // should be positive. Otherwise, it should be negative.
        result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Returns Euler's number as a signed 59.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (int256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// Caveats:
    /// - All from "exp2".
    /// - For any x less than -41.446531673892822322, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp(int256 x) internal pure returns (int256 result) {
        // Without this check, the value passed to "exp2" would be less than -59.794705707972522261.
        if (x < -41_446531673892822322) {
            return 0;
        }

        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathSD59x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            int256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - For any x less than -59.794705707972522261, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp2(int256 x) internal pure returns (int256 result) {
        // This works because 2^(-x) = 1/2^x.
        if (x < 0) {
            // 2^59.794705707972522262 is the maximum number whose inverse does not truncate down to zero.
            if (x < -59_794705707972522261) {
                return 0;
            }

            // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
            unchecked {
                result = 1e36 / exp2(-x);
            }
        } else {
            // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
            if (x >= 192e18) {
                revert PRBMathSD59x18__Exp2InputTooBig(x);
            }

            unchecked {
                // Convert x to the 192.64-bit fixed-point format.
                uint256 x192x64 = (uint256(x) << 64) / uint256(SCALE);

                // Safe to convert the result to int256 directly because the maximum input allowed is 192.
                result = int256(PRBMath.exp2(x192x64));
            }
        }
    }

    /// @notice Yields the greatest signed 59.18 decimal fixed-point number less than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be greater than or equal to MIN_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as a signed 58.18-decimal fixed-point number.
    function floor(int256 x) internal pure returns (int256 result) {
        if (x < MIN_WHOLE_SD59x18) {
            revert PRBMathSD59x18__FloorUnderflow(x);
        }
        unchecked {
            int256 remainder = x % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                result = x - remainder;
                if (x < 0) {
                    result -= SCALE;
                }
            }
        }
    }

    /// @notice Yields the excess beyond the floor of x for positive numbers and the part of the number to the right
    /// of the radix point for negative numbers.
    /// @dev Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part
    /// @param x The signed 59.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as a signed 59.18-decimal fixed-point number.
    function frac(int256 x) internal pure returns (int256 result) {
        unchecked {
            result = x % SCALE;
        }
    }

    /// @notice Converts a number from basic integer form to signed 59.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be greater than or equal to MIN_SD59x18 divided by SCALE.
    /// - x must be less than or equal to MAX_SD59x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in signed 59.18-decimal fixed-point representation.
    function fromInt(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x < MIN_SD59x18 / SCALE) {
                revert PRBMathSD59x18__FromIntUnderflow(x);
            }
            if (x > MAX_SD59x18 / SCALE) {
                revert PRBMathSD59x18__FromIntOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_SD59x18, lest it overflows.
    /// - x * y cannot be negative.
    ///
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function gm(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            int256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathSD59x18__GmOverflow(x, y);
            }

            // The product cannot be negative.
            if (xy < 0) {
                revert PRBMathSD59x18__GmNegativeProduct(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = int256(PRBMath.sqrt(uint256(xy)));
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as a signed 59.18-decimal fixed-point number.
    function inv(int256 x) internal pure returns (int256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as a signed 59.18-decimal fixed-point number.
    function ln(int256 x) internal pure returns (int256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 195205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as a signed 59.18-decimal fixed-point number.
    function log10(int256 x) internal pure returns (int256 result) {
        if (x <= 0) {
            revert PRBMathSD59x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly mul operation, not the "mul" function defined in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            default {
                result := MAX_SD59x18
            }
        }

        if (result == MAX_SD59x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than zero.
    ///
    /// Caveats:
    /// - The results are not perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as a signed 59.18-decimal fixed-point number.
    function log2(int256 x) internal pure returns (int256 result) {
        if (x <= 0) {
            revert PRBMathSD59x18__LogInputTooSmall(x);
        }
        unchecked {
            // This works because log2(x) = -log2(1/x).
            int256 sign;
            if (x >= SCALE) {
                sign = 1;
            } else {
                sign = -1;
                // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
                assembly {
                    x := div(1000000000000000000000000000000000000, x)
                }
            }

            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(uint256(x / SCALE));

            // The integer part of the logarithm as a signed 59.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255, SCALE is 1e18 and sign is either 1 or -1.
            result = int256(n) * SCALE;

            // This is y = x * 2^(-n).
            int256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result * sign;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (int256 delta = int256(HALF_SCALE); delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
            result *= sign;
        }
    }

    /// @notice Multiplies two signed 59.18-decimal fixed-point numbers together, returning a new signed 59.18-decimal
    /// fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers and employs constant folding, i.e. the denominator is
    /// always 1e18.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - None of the inputs can be MIN_SD59x18
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    ///
    /// @param x The multiplicand as a signed 59.18-decimal fixed-point number.
    /// @param y The multiplier as a signed 59.18-decimal fixed-point number.
    /// @return result The product as a signed 59.18-decimal fixed-point number.
    function mul(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == MIN_SD59x18 || y == MIN_SD59x18) {
            revert PRBMathSD59x18__MulInputTooSmall();
        }

        unchecked {
            uint256 ax;
            uint256 ay;
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);

            uint256 rAbs = PRBMath.mulDivFixedPoint(ax, ay);
            if (rAbs > uint256(MAX_SD59x18)) {
                revert PRBMathSD59x18__MulOverflow(rAbs);
            }

            uint256 sx;
            uint256 sy;
            assembly {
                sx := sgt(x, sub(0, 1))
                sy := sgt(y, sub(0, 1))
            }
            result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
        }
    }

    /// @notice Returns PI as a signed 59.18-decimal fixed-point number.
    function pi() internal pure returns (int256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    /// - z cannot be zero.
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as a signed 59.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as a signed 59.18-decimal fixed-point number.
    /// @return result x raised to power y, as a signed 59.18-decimal fixed-point number.
    function pow(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : int256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (signed 59.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - All from "abs" and "PRBMath.mulDivFixedPoint".
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as a signed 59.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function powu(int256 x, uint256 y) internal pure returns (int256 result) {
        uint256 xAbs = uint256(abs(x));

        // Calculate the first iteration of the loop in advance.
        uint256 rAbs = y & 1 > 0 ? xAbs : uint256(SCALE);

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        uint256 yAux = y;
        for (yAux >>= 1; yAux > 0; yAux >>= 1) {
            xAbs = PRBMath.mulDivFixedPoint(xAbs, xAbs);

            // Equivalent to "y % 2 == 1" but faster.
            if (yAux & 1 > 0) {
                rAbs = PRBMath.mulDivFixedPoint(rAbs, xAbs);
            }
        }

        // The result must fit within the 59.18-decimal fixed-point representation.
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__PowuOverflow(rAbs);
        }

        // Is the base negative and the exponent an odd number?
        bool isNegative = x < 0 && y & 1 == 1;
        result = isNegative ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Returns 1 as a signed 59.18-decimal fixed-point number.
    function scale() internal pure returns (int256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x cannot be negative.
    /// - x must be less than MAX_SD59x18 / SCALE.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as a signed 59.18-decimal fixed-point .
    function sqrt(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x < 0) {
                revert PRBMathSD59x18__SqrtNegativeInput(x);
            }
            if (x > MAX_SD59x18 / SCALE) {
                revert PRBMathSD59x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two signed
            // 59.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = int256(PRBMath.sqrt(uint256(x * SCALE)));
        }
    }

    /// @notice Converts a signed 59.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The signed 59.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toInt(int256 x) internal pure returns (int256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface IVault {
    function token() external view returns (address);

    function underlying() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function controller() external view returns (address);

    function governance() external view returns (address);

    function getPricePerFullShare() external view returns (uint256);

    function deposit(uint256) external;

    function depositAll() external;

    function withdraw(uint256) external;

    function withdrawAll() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestAnswer() external view returns (int256);
}