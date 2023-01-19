// SPDX-License-Identifier: MIT



pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Storage.sol";
import "./interfaces/IRegistry.sol";

contract Registry is IRegistry, Storage, Ownable {
    mapping(address => address) public getVaultPipeline;

    mapping(bytes32 => bytes) public getPipelineData;

    mapping(address => bool) public isTokenWhitelisted;

    mapping(address => address) public getPriceFeed;

    address public defaultUniswapV2Router;

    mapping(address => mapping(address => SwapData)) private _swapData;

    mapping(address => bool) public feeExists;

    event VaultPipelineSet(address indexed vault, address indexed pipeline);

    event PipelineDataSet(bytes32 indexed slot, bytes data);

    event TokenWhitelisted(address indexed token, bool indexed whitelisted);

    event FeeWhitelistSet(address[] indexed fees, bool exists);

    event PriceFeedSet(address indexed token, address indexed feed);

    event UniswapDefaultRouterSet(address indexed router);

    event StorageValueSet(
        bytes32 indexed source,
        bytes32 indexed key,
        bytes32 value
    );

    // RESTRICTED FUNCTIONS

    function _setVaultPipeline(address vault, address pipeline) internal {
        getVaultPipeline[vault] = pipeline;
        emit VaultPipelineSet(vault, pipeline);
    }

    function setVaultPipeline(address vault, address pipeline)
        external
        onlyOwner
    {
        _setVaultPipeline(vault, pipeline);
    }

    function setManyVaultPipelines(
        address[] memory vault,
        address[] memory pipeline
    ) external onlyOwner {
        if (pipeline.length == 1) {
            for (uint256 i = 0; i < vault.length; i++) {
                _setVaultPipeline(vault[i], pipeline[0]);
            }
        } else if (vault.length == pipeline.length) {
            for (uint256 i = 0; i < vault.length; i++) {
                _setVaultPipeline(vault[i], pipeline[i]);
            }
        } else {
            revert("incorrect arrays lengths");
        }
    }

    function _setPipelineData(bytes32 slot, bytes memory data) internal {
        getPipelineData[slot] = data;
        emit PipelineDataSet(slot, data);
    }

    function setPipelineData(bytes32 slot, bytes memory data)
        external
        onlyOwner
    {
        _setPipelineData(slot, data);
    }

    function setManyPipelineData(bytes32[] memory slot, bytes[] memory data)
        external
        onlyOwner
    {
        if (data.length == 1) {
            for (uint256 i = 0; i < slot.length; i++) {
                _setPipelineData(slot[i], data[0]);
            }
        } else if (slot.length == data.length) {
            for (uint256 i = 0; i < slot.length; i++) {
                _setPipelineData(slot[i], data[i]);
            }
        } else {
            revert("incorrect arrays lengths");
        }
    }

    function _setTokenWhitelisted(address token, bool whitelisted) internal {
        isTokenWhitelisted[token] = whitelisted;
        emit TokenWhitelisted(token, whitelisted);
    }

    function setTokenWhitelisted(address token, bool whitelisted)
        external
        onlyOwner
    {
        _setTokenWhitelisted(token, whitelisted);
    }

    function setManyTokenWhitelisted(address[] memory token, bool whitelisted)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < token.length; i++) {
            _setTokenWhitelisted(token[i], whitelisted);
        }
    }

    function addFeeWhitelist(address[] memory fees, bool exists)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < fees.length; i++) {
            feeExists[fees[i]] = exists;
        }
    }

    function _setPriceFeed(address token, address feed) internal {
        getPriceFeed[token] = feed;
        emit PriceFeedSet(token, feed);
    }

    function setPriceFeed(address token, address feed) external onlyOwner {
        _setPriceFeed(token, feed);
    }

    function setManyPriceFeeds(address[] memory token, address[] memory feed)
        external
        onlyOwner
    {
        if (feed.length == 1) {
            for (uint256 i = 0; i < token.length; i++) {
                _setPriceFeed(token[i], feed[0]);
            }
        } else if (token.length == feed.length) {
            for (uint256 i = 0; i < token.length; i++) {
                _setPriceFeed(token[i], feed[i]);
            }
        } else {
            revert("incorrect arrays lengths");
        }
    }

    function setDefaultUniswapV2Router(address router) external onlyOwner {
        defaultUniswapV2Router = router;
        emit UniswapDefaultRouterSet(router);
    }

    function _setStorageValue(
        bytes32 source,
        bytes32 key,
        bytes32 value
    ) internal {
        _setDataValue(source, key, value);
        emit StorageValueSet(source, key, value);
    }

    function setStorageValue(
        bytes32 source,
        bytes32 key,
        bytes32 value
    ) external onlyOwner {
        _setStorageValue(source, key, value);
    }

    function setManyStorageValues(
        bytes32[] memory source,
        bytes32[] memory key,
        bytes32[] memory value
    ) external onlyOwner {
        require(
            source.length == key.length && key.length == value.length,
            "incorrect array lengths"
        );
        for (uint256 i = 0; i < source.length; i++) {
            _setStorageValue(source[i], key[i], value[i]);
        }
    }

    // VIEW FUNCTIONS

    function getSwapData(address from, address to)
        external
        view
        returns (SwapData memory)
    {
        if (_swapData[from][to].swapType != SwapType.None) {
            return _swapData[from][to];
        } else {
            return _swapData[to][from];
        }
    }

    function checkFeeExistence(address[] memory fees) external view {
        for (uint256 i = 0; i < fees.length; i++) {
            require(feeExists[fees[i]], "fee is not whitelisted");
        }
    }
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

pragma solidity ^0.8.13;

contract Storage {
    // Type => key => value
    mapping(bytes32 => mapping(bytes32 => bytes32)) public data;

    function _setDataValue(
        bytes32 source,
        bytes32 key,
        bytes32 value
    ) internal {
        data[source][key] = value;
    }

    function getAddrWithAddr(bytes32 source, address addr)
        external
        view
        returns (address)
    {
        bytes32 key = bytes32(uint256(uint160(addr)));
        return getAddrWithKey(source, key);
    }

    function getAddrWithKey(bytes32 source, bytes32 key)
        public
        view
        returns (address)
    {
        return address(uint160(uint256(data[source][key])));
    }

    function getUint256WithAddr(bytes32 source, address addr)
        external
        view
        returns (uint256)
    {
        bytes32 key = bytes32(uint256(uint160(addr)));
        return getUint256WithKey(source, key);
    }

    function getUint256WithKey(bytes32 source, bytes32 key)
        public
        view
        returns (uint256)
    {
        return uint256(data[source][key]);
    }
}

// SPDX-License-Identifier: MIT



pragma solidity ^0.8.13;

interface IRegistry {
    function getVaultPipeline(address vault) external view returns (address);

    function getPipelineData(bytes32 slot) external view returns (bytes memory);

    function isTokenWhitelisted(address token) external view returns (bool);

    function getPriceFeed(address token) external view returns (address);

    function feeExists(address fee) external view returns (bool);

    function checkFeeExistence(address[] memory fees) external view;

    enum SwapType {
        None,
        UniswapV2
    }

    struct SwapData {
        SwapType swapType;
        bytes data;
    }

    function getSwapData(address from, address to)
        external
        view
        returns (SwapData memory);

    function defaultUniswapV2Router() external view returns (address);
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