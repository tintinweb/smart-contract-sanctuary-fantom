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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

interface IEtfiOracleProvider {
    function getUpdatedPrice(address _token, uint256 _amountIn)
        external
        returns (uint256);

    function getLastPrice(address _token, uint256 _amountIn)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IEtfiOracleProvider.sol";

contract EtfiOmniOracle is Ownable {
    struct Provider {
        address implementation;
        string name;
    }

    Provider[] public providers;

    event ProviderCreated(
        address indexed implementation,
        uint256 indexed providerId,
        string name
    );
    event ProviderUpdated(
        address indexed implementation,
        uint256 indexed providerId,
        string name
    );
    event ProviderForTokenUpdated(address indexed token, string name);

    mapping(address => uint256) public tokenToProvider;

    function getProviderForToken(address _token)
        external
        view
        returns (Provider memory)
    {
        require(
            providers[tokenToProvider[_token]].implementation != address(0),
            "provider-not-set"
        );
        return providers[tokenToProvider[_token]];
    }

    function setProviderForToken(address _token, uint256 _providerId)
        external
        onlyOwner
    {
        require(
            providers[_providerId].implementation != address(0),
            "provider-not-set"
        );
        tokenToProvider[_token] = _providerId;
    }

    function createProvider(address _implementation, string memory _name)
        external
        onlyOwner
        returns (uint256)
    {
        require(_implementation != address(0), "invalid-implementation");
        providers.push(Provider(_implementation, _name));
        emit ProviderCreated(_implementation, providers.length - 1, _name);
        return providers.length - 1;
    }

    function updateProviderImplementation(
        uint256 _providerId,
        address _implementation
    ) external onlyOwner {
        require(_implementation != address(0), "invalid-implementation");
        providers[_providerId].implementation = _implementation;
        emit ProviderUpdated(
            _implementation,
            _providerId,
            providers[_providerId].name
        );
    }

    /// @notice will revert if the oracle is stale
    /// @notice also updates prices if the underlying provider supports it
    function getUpdatedPrice(address _token, uint256 _amountIn)
        public
        returns (uint256)
    {
        Provider memory provider = providers[tokenToProvider[_token]];
        require(provider.implementation != address(0), "provider-not-set");
        return
            IEtfiOracleProvider(provider.implementation).getUpdatedPrice(
                _token,
                _amountIn
            );
    }

    /// @notice will revert if the oracle is stale
    /// @notice view function to get the price of a token from users/test scripts
    function getLastPrice(address _token, uint256 _amountIn)
        external
        view
        returns (uint256)
    {
        Provider memory provider = providers[tokenToProvider[_token]];
        require(provider.implementation != address(0), "provider-not-set");
        return
            IEtfiOracleProvider(provider.implementation).getLastPrice(
                _token,
                _amountIn
            );
    }
}