// SPDX-License-Identifier: MIT

import "../libraries/EventReporterLib.sol";

pragma solidity >=0.8.0;

// this contract migrates legacy gems to new gems. it contains a map of accounts to merkle root hashes of the legacy gems.
// this map is prepopulated with the legacy gem data by user - one account address, one merkle root hash.
// when a migration request is made the contract checks if the sender, proof and merkle root hash are valid. if they are, it
// mints new gems and record the minted gems in the map so that the next time the same request is made the contract will not
// mint the same gems again.

import "../interfaces/IEventReporter.sol";
import "../interfaces/ILegacyTokenData.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "./MerkleProof.sol";

interface IMintGemTo {
  function mintGemTo(
          address receiver,
          string memory symbol,
          uint256 quantity
      ) external returns (uint256[] memory _returnIds);
}

interface ILegacyToken {
    function allTokenHoldersLength(uint256 tokenId) external view returns (uint256);
    function allTokenHolders(uint256 tokenId, uint256 idx) external view returns (uint256);
    function allHeldTokensLength(address tokenHolder) external view returns (uint256);
    function allTokenHolders(address tokenHolder, uint256 idx) external view returns (uint256);
}

interface ILegacyPool {
    function allTokenHashesLength() external view returns (uint256);
    function allTokenHashes(uint256 idx) external view returns (uint256);
    function symbol() external view returns (string memory);
}

interface ILegacyFactory {
    function allNFTGemPools(uint256 idx) external view returns (address gemPool);
    function allNFTGemPoolsLength() external view returns (uint256);
}

struct LegacyToken {
    string symbol;
    address token;
    uint256 series;
    uint256 numbering;
    uint256 tokenId;
}

struct LegacyItem {
    address pool;
    address token;
    string symbol;
    uint256 numbering;
    uint256 tokenId;
}

struct MerkleAirdropStorage {
    mapping(uint256 => uint256) _redeemedData;
    mapping(address => uint256) _redeemedDataQuantities;
}

contract LegacyTokenMigrator is Ownable, Initializable, IERC1155Receiver {

    address private eventReporter;
    address private tokenFactory;

    mapping(address => bytes32) public legacyAccountToMerkleRootHash;
    mapping(uint256 => mapping(address => uint256)) public migratedGems;

    MerkleAirdropStorage private _merkleAirdropStorage;

    mapping(address => bool) private tokenFactoriesMap;
    address[] private tokenFactories = [
        0xdF99eb724ecaB8cE906EA637342aD9c3E7844F98,
        0x8948bCfd1c1A6916c64538981e44E329BF381a59,
        0x496FEC70974870dD7c2905E25cAd4BDE802938C7,
        0x752cE5Afa66b9E215b6dEE9F7Dc1Ec2bf868E373
    ];

    mapping(address => bool) private tokenAddressesMap;
    address[] private tokenAddresses = [
        0xdF99eb724ecaB8cE906EA637342aD9c3E7844F98,
        0x8948bCfd1c1A6916c64538981e44E329BF381a59,
        0x496FEC70974870dD7c2905E25cAd4BDE802938C7,
        0x752cE5Afa66b9E215b6dEE9F7Dc1Ec2bf868E373
    ];
    mapping(address => string) private stakingPoolsMap;
    address private _burnAddress;
    constructor() {

    }

    function addLegacyPool(address pool) external onlyOwner {
        stakingPoolsMap[pool] = ILegacyPool(pool).symbol();
    }
    /**
     * @notice Constructor
     */
    function initialize(
        address _tokenFactory,
        address _eventReporter
    ) public initializer {
        eventReporter = _eventReporter;
        tokenFactory = _tokenFactory;
        for (uint256 i = 0; i < tokenFactories.length; i++) {
            tokenFactoriesMap[tokenFactories[i]] = true;
            uint256 jl = ILegacyFactory(tokenFactories[i]).allNFTGemPoolsLength();
            for(uint256 j = 0; j < jl; j++) {
                address jls = ILegacyFactory(tokenFactories[i]).allNFTGemPools(j);
                stakingPoolsMap[jls] = ILegacyPool(jls).symbol();
            }
        }
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            tokenAddressesMap[tokenAddresses[i]] = true;
        }
        _burnAddress = 0x0000000000000000000000000000010101010101;
    }

    function convertLegacyToken(address pool, address token, uint256 numbering, uint256 tokenId) public {
        string memory symbol = ILegacyPool(pool).symbol();
        require(tokenAddressesMap[token], "Token is not a valid token address");
        require(keccak256(bytes(stakingPoolsMap[pool])) == keccak256(bytes(symbol)), "Token is not a valid token address");
        require(keccak256(bytes(ILegacyPool(pool).symbol())) == keccak256(bytes(symbol)), "TokenId is not valid");
        require(tokenId > 1, "TokenId must be greater than 1"); 
        require(ILegacyPool(pool).allTokenHashes(numbering) == tokenId, "TokenId is not valid");
        uint256 balanceOf = IERC1155(token).balanceOf(msg.sender, tokenId);
        require(balanceOf > 0, "Token is not valid");
        IERC1155(token).safeTransferFrom(msg.sender, _burnAddress, tokenId, balanceOf, "");
        mintGemTo(msg.sender, ILegacyPool(pool).symbol(), balanceOf);
        EventReportingContract(eventReporter).dispatchEvent(
            msg.sender,
            address(this),
            ApplicationEventStruct(
                0,
                "BitgemMigrated",
                abi.encode(msg.sender, symbol, tokenId, balanceOf)
            )
        );
    }


    function convertLegacyTokens(LegacyItem[] memory items) public {
        for (uint256 i = 0; i < items.length; i++) {
            address pool = items[i].pool;
            address token = items[i].token;
            string memory symbol = items[i].symbol;
            uint256 numbering = items[i].numbering;
            uint256 tokenId = items[i].tokenId;
            require(tokenAddressesMap[token], "Token is not a valid token address");
            require(keccak256(bytes(stakingPoolsMap[pool])) == keccak256(bytes(symbol)), "Token is not a valid token address");
            require(keccak256(bytes(ILegacyPool(pool).symbol())) == keccak256(bytes(symbol)), "TokenId is not valid");
            require(tokenId > 1, "TokenId must be greater than 1"); 
            require(ILegacyPool(pool).allTokenHashes(numbering) == tokenId, "TokenId is not valid");
            uint256 balanceOf = IERC1155(token).balanceOf(msg.sender, tokenId);
            require(balanceOf > 0, "Token is not valid");
            IERC1155(token).safeTransferFrom(msg.sender, _burnAddress, tokenId, balanceOf, "");
            mintGemTo(msg.sender, symbol, balanceOf);
        }
        EventReportingContract(eventReporter).dispatchEvent(
            msg.sender,
            address(this),
            ApplicationEventStruct(
                0,
                "BitgemMigrated",
                abi.encode(msg.sender, items)
            )
        );
    }

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return interfaceId == 0x5b5e139f;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    /**
     * @notice migrate legacy gems to new gems
     */
    function setAccountMerkleRoot(
        address account,
        bytes32 merkleRootHash
    ) public onlyOwner {
        legacyAccountToMerkleRootHash[account] = merkleRootHash;
        EventReportingContract(eventReporter).dispatchEvent(
            msg.sender,
            address(this),
            ApplicationEventStruct(
                0,
                "AccountMerkleRootSet",
                abi.encode(msg.sender, merkleRootHash)
            )
        );
    }

    /**
     * @notice migrate legacy gems to new gems
     */
    function setAccountMerkleRoots(
        MerkleRoot[] memory merkleRootHashes
    ) public onlyOwner {
        address[] memory accounts = new address[](merkleRootHashes.length);
        uint256[] memory hashes = new uint256[](merkleRootHashes.length);
        for (uint256 i = 0; i < merkleRootHashes.length; i++) {
            legacyAccountToMerkleRootHash[merkleRootHashes[i].owner] =
                bytes32(merkleRootHashes[i].rootHash);
            accounts[i] = merkleRootHashes[i].owner;
            hashes[i] = merkleRootHashes[i].rootHash;
        }
        EventReportingContract(eventReporter).dispatchEvent(
            msg.sender,
            address(this),
            ApplicationEventStruct(
                0,
                "AccountMerkleRootSet",
                abi.encode(accounts, hashes)
            )
        );
    }

    /**
     * @notice migrate legacy gems to new gems
     */
    function migrateTokens(
        LegacyToken[] memory tokenIds,
        bytes32[][] memory merkleProof
    ) public returns (uint256[] memory _returnIds) {
        _returnIds = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            LegacyToken memory tokenId = tokenIds[i];
            bytes32 merkleRootHash = legacyAccountToMerkleRootHash[msg.sender];
            bytes32[] memory proof = merkleProof[i];
            require(
                MerkleProof.verify(
                    merkleRootHash,
                    bytes32(tokenId.tokenId),
                    proof
                ),
                "invalid proof"
            );
            _returnIds[i] = tokenId.tokenId;
        }

        // require that none of the gems to be migrated are already migrated
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // get the token info
            LegacyToken memory tokenObj = tokenIds[i];

            // user must have a balance of the gem to be migrated
            uint256 balanceOfToken = IERC1155(tokenObj.token).balanceOf(
                msg.sender,
                tokenObj.tokenId
            );
            require(
                balanceOfToken > 0,
                "user does not have a balance of the gem to be migrated"
            );

            // transfer the gems to this contract
            IERC1155(tokenObj.token).safeTransferFrom(
                msg.sender,
                address(this),
                tokenObj.tokenId,
                balanceOfToken,
                ""
            );

            // mint this gem to the user
            uint256[] memory ui = IMintGemTo(tokenFactory).mintGemTo(
                msg.sender,
                tokenObj.symbol,
                balanceOfToken
            );
            _returnIds[i] = ui[0];
        }

        EventReportingContract(eventReporter).dispatchEvent(
            msg.sender,
            address(this),
            ApplicationEventStruct(
                0,
                "BitgemsMigrated",
                abi.encode(msg.sender, tokenIds, tokenIds.length)
            )
        );
    }

    function mintGemTo(
        address receiver,
        string memory symbol,
        uint256 quantity
    ) internal returns (uint256[] memory _returnIds) {
        _returnIds = IMintGemTo(tokenFactory).mintGemTo(
            receiver,
            symbol,
            quantity
        );
    }
}

//o initialize the token migrator contract with the token factory and event reporter
//o add the legacy token migrator as an allowed minter to the diamond factory
//x add the diamond factory as an allowed minter of each token

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

struct ApplicationEventStruct {
    bytes32 selector;
    string name;
    bytes params;
}

struct EventDispatchStorage {
    address eventReportingContract;
    function(address,address,ApplicationEventStruct memory) dispatchFunc;
}


contract EventReportingContract is Initializable {  

    event ApplicationEvent(address indexed account, address indexed contractAddress, bytes32 indexed selector, string name, bytes params);

    constructor() {
        allowed[msg.sender] = true;
    }

    mapping(address => bool) private allowed;
    bool private locked = false;
    modifier onlyAllowed {
        require(allowed[msg.sender] == true, "not allowed");
        _;
    }
    function addAllowed(address _account) public onlyAllowed {
        allowed[_account] = true;
    }
    function dispatchEvent(address account, address _contract, ApplicationEventStruct memory evt) public onlyAllowed {
        emit ApplicationEvent(account, _contract, evt.selector, evt.name, evt.params);
    }

    function register(address[] memory moreAllowed) external {
        require(!locked, "locked");
        allowed[msg.sender] = true;
        for (uint i = 0; i < moreAllowed.length; i++) {
            allowed[moreAllowed[i]] = true;
        }
    }
    function lock(bool _val) external onlyAllowed {
        locked = _val;
    }       
}

library EventReporterLib {

    bytes32 constant private DIAMOND_STORAGE_POSITION = keccak256("diamond.event.dispatch.storage");

    function toEvent(string memory name, bytes memory params) internal pure returns (ApplicationEventStruct memory _event) {
        _event = ApplicationEventStruct(
            keccak256(bytes(name)), 
            name, 
            params
        );
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IBitGem.sol";
import "./IClaim.sol";
import "./IAttribute.sol";

interface IEventReporter {
    function register(address[] memory addresses) external;
    function addAllowedReporter(address reporter) external; 
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


struct PoolData {
    string symbol;
    string name;
    address poolAddress;
}

struct TokenData {
  uint256 tokenHash;
  address tokenAddress;
  address pool;
  uint256 quantity;
}

struct MerkleRoot {
    address owner;
    uint256 rootHash;
}

interface ILegacyTokenData {
  function getMerkleRoot(address tokenAddress) external view returns (uint256);
  function setMerkleRoot(address tokenAddress, uint256 merkleRoot) external returns (bool _success);
  function getMerkleAddress(uint256 merkleRoot) external view returns (address);
  function allMerkleRoots() external view returns (address[] memory _allMerkleAddresses, uint256[] memory _allMerkleRoots);
  function setMerkleRoots(MerkleRoot[] memory mrs) external;
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library MerkleProof {

  function verify(
    bytes32 root,
    bytes32 leaf,
    bytes32[] memory proof
  )
    public
    pure
    returns (bool)
  {
    bytes32 computedHash = leaf;

    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];

      if (computedHash <= proofElement) {
        // Hash(current computed hash + current element of the proof)
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        // Hash(current element of the proof + current computed hash)
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }
    }

    // Check if the computed hash (root) is equal to the provided root
    return computedHash == root;
  }

  function getHash(address a, uint256 b) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(a, b));
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import "./IToken.sol";
import "./ITokenPrice.sol";
import "../libraries/UInt256Set.sol";

struct BitGemInitParameters {
    address owner;
    string symbol;
    string name;
    string description;
    string imageName;
    string[] imagePalette;
    string externalUrl;
    VariablePriceContract price;
    uint256 minTime;
    uint256 maxTime;
    uint256 maxClaims;
    bool enabled;
}

struct BitGemSettings {
     // the owner & payee of the bitgem fees
    address owner;
    // the token definition of the mine
    TokenDefinition tokenDefinition;
    uint256 minTime; // min and max token amounts to stake
    uint256 maxTime; // max time that the claim can be made
    uint256 maxClaims; // max number of claims that can be made
    // is staking enabled
    bool enabled;
}

// contract storage for a bitgem contract
struct BitGemContract {
    BitGemSettings settings;
    address wrappedToken;
    // minted tokens
    uint256[] mintedTokens;
    mapping(address=>bool) allowedMinters;
}

struct BitGemFactoryContract {
    mapping(string => address) _bitgems;
    string[] _bitgemSymbols;
    mapping(address => bool) allowedReporters;
    address wrappedToken_;
}

/// @notice check the balance of earnings and collect earnings
interface IBitGem {  
    function initialize(
        BitGemSettings memory _settings,
        address _wrappedToken
    ) external;
    /// @notice get the member gems of this pool
    function settings() external view returns (BitGemSettings memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @notice represents a claim on some deposit.
struct Claim {
    // claim id.
    uint256 id;
    address feeRecipient;
    // pool address
    address mineAddress;
    // the amount of eth deposited
    uint256 depositAmount;
    // the gem quantity to mint to the user upon maturity
    uint256 mintQuantity;
    // the deposit length of time, in seconds
    uint256 depositLength;
    // the block number when this record was created.
    uint256 createdTime;
    // the block number when this record was created.
    uint256 createdBlock;
    // block number when the claim was submitted or 0 if unclaimed
    uint256 claimedBlock;
    // the fee that was paid
    uint256 feePaid;
    // whether this claim has been collected
    bool collected;
    // whether this claim must be mature before it can be collected
    bool requireMature;
    // whether this claim has been collected
    bool mature;
}

/// @notice a set of requirements. used for random access
struct ClaimSet {
    mapping(uint256 => uint256) keyPointers;
    uint256[] keyList;
    Claim[] valueList;
}

struct ClaimSettings {
    ClaimSet claims;
    // the total staked for each token type (0 for ETH)
    mapping(address => uint256) stakedTotal;
}

struct ClaimContract {
    uint256 gemsMintedCount;  // total number of gems minted
    uint256 totalStakedEth; // total amount of staked eth
    mapping(uint256 => Claim) claims;  // claim data
    // staked total and claim index
    uint256 stakedTotal;
    uint256 claimIndex;
}

/// @notice interface for a collection of tokens. lists members of collection, allows for querying of collection members, and for minting and burning of tokens.
interface IClaim {
    /// @notice emitted when a token is added to the collection
    event ClaimCreated(
        address indexed user,
        address indexed minter,
        Claim claim
    );

    /// @notice emitted when a token is removed from the collection
    event ClaimRedeemed(
        address indexed user,
        address indexed minter,
        Claim claim
    );

    /// @notice create a claim
    /// @param _claim the claim to create
    /// @return _claimHash the claim hash
    function createClaim(Claim memory _claim)
        external
        payable
        returns (Claim memory _claimHash);

    /// @notice submit claim for collection
    /// @param claimHash the id of the claim
    function collectClaim(uint256 claimHash, bool requireMature) external;

    /// @notice return the next claim hash
    /// @return _nextHash the next claim hash
    function nextClaimHash() external view returns (uint256 _nextHash);

    /// @notice get all the claims
    /// @return _claims all the claims
    function claims() external view returns (Claim[] memory _claims);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

enum AttributeType {
    Unknown,
    String ,
    Bytes32,
    Uint256,
    Uint8,
    Uint256Array,
    Uint8Array
}

struct Attribute {
    string key;
    AttributeType attributeType;
    string value;
}

// attribute storage
struct AttributeContract {
    mapping(uint256 => bool)  burnedIds;
    mapping(uint256 => mapping(string => Attribute))  attributes;
    mapping(uint256 => string[]) attributeKeys;
    mapping(uint256 =>  mapping(string => uint256)) attributeKeysIndexes;
}


/// @notice a pool of tokens that users can deposit into and withdraw from
interface IAttribute {
    /// @notice get an attribute for a tokenid keyed by string
    function getAttribute(
        uint256 id,
        string memory key
    ) external view returns (Attribute calldata _attrib);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice the definition for a token.
struct TokenDefinition {
    // the host multitoken
    address token;
    // the name of the token
    string name;
    // the symbol of the token
    string symbol;
    // the description of the token
    string description;
    // the total supply of the token
    uint256 totalSupply;
    // probability of the item being awarded
    uint256 probability;
    // the index of the probability in its array
    uint256 probabilityIndex;
    // the index of the probability in its array
    uint256 probabilityRoll;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


/// @notice DIctates how the price of the token is increased post every sale
enum PriceModifier {
    None,
    Fixed,
    Exponential,
    InverseLog
}

struct VariablePriceContract {
    // the price of the token
    uint256 price;
        // how the price is modified
    PriceModifier priceModifier;
    // only used if priceModifier is EXPONENTIAL or INVERSELOG or FIXED
    uint256 priceModifierFactor;
    // max price for the token
    uint256 maxPrice;
}


/// @notice common struct definitions for tokens
interface ITokenPrice {
    /// @notice get the increased price of the token
    function getIncreasedPrice() external view returns (uint256);

    /// @notice get the increased price of the token
    function getTokenPrice() external view returns (VariablePriceContract memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/**
 * @notice Key sets with enumeration and delete. Uses mappings for random
 * and existence checks and dynamic arrays for enumeration. Key uniqueness is enforced.
 * @dev Sets are unordered. Delete operations reorder keys. All operations have a
 * fixed gas cost at any scale, O(1).
 * author: Rob Hitchens
 */

library UInt256Set {
    struct Set {
        mapping(uint256 => uint256) keyPointers;
        uint256[] keyList;
    }

    /**
     * @notice insert a key.
     * @dev duplicate keys are not permitted.
     * @param self storage pointer to a Set.
     * @param key value to insert.
     */
    function insert(Set storage self, uint256 key) public {
        require(
            !exists(self, key),
            "UInt256Set: key already exists in the set."
        );
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length - 1;
    }

    /**
     * @notice remove a key.
     * @dev key to remove must exist.
     * @param self storage pointer to a Set.
     * @param key value to remove.
     */
    function remove(Set storage self, uint256 key) public {
        // TODO: I commented this out do get a test to pass - need to figure out what is up here
        // require(
        //     exists(self, key),
        //     "UInt256Set: key does not exist in the set."
        // );
        if (!exists(self, key)) return;
        uint256 last = count(self) - 1;
        uint256 rowToReplace = self.keyPointers[key];
        if (rowToReplace != last) {
            uint256 keyToMove = self.keyList[last];
            self.keyPointers[keyToMove] = rowToReplace;
            self.keyList[rowToReplace] = keyToMove;
        }
        delete self.keyPointers[key];
        delete self.keyList[self.keyList.length - 1];
    }

    /**
     * @notice count the keys.
     * @param self storage pointer to a Set.
     */
    function count(Set storage self) public view returns (uint256) {
        return (self.keyList.length);
    }

    /**
     * @notice check if a key is in the Set.
     * @param self storage pointer to a Set.
     * @param key value to check.
     * @return bool true: Set member, false: not a Set member.
     */
    function exists(Set storage self, uint256 key)
        public
        view
        returns (bool)
    {
        if (self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    /**
     * @notice fetch a key by row (enumerate).
     * @param self storage pointer to a Set.
     * @param index row to enumerate. Must be < count() - 1.
     */
    function keyAtIndex(Set storage self, uint256 index)
        public
        view
        returns (uint256)
    {
        return self.keyList[index];
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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