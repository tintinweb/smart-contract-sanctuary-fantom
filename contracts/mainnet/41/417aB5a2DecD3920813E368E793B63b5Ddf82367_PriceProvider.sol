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
  function getSafePrice(address token) external view returns (uint256);

  function getCurrentPrice(address token) external view returns (uint256);

  function updateSafePrice(address token) external returns (uint256);

  function BASE_TOKEN() external view returns (address);

  function DECIMALS() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IPriceOracle.sol";
import "./IPriceProvider.sol";

error NoOracle(address _token);

contract PriceProvider is IPriceProvider, Ownable {
  event SetTokenOracle(address token, address oracle);
  address public immutable BASE_TOKEN;
  uint8 public immutable DECIMALS;
  mapping(address => address) public priceOracle;

  event PriceUpdated(address indexed _token, uint256 _price);

  /**
   * @dev sets up the Price Oracle
   */
  constructor(
    address _baseToken,
    uint8 _decimals
  ) {
    DECIMALS = _decimals;
    BASE_TOKEN = _baseToken;
  }
  
  function setTokenOracle(address token, address oracle) external onlyOwner {
    priceOracle[token] = oracle;

    emit SetTokenOracle(token, oracle);
  }

  function getSafePrice(address token) external view override returns (uint256) {
    return _getSafePrice(token);
  }

  function _getSafePrice(address token) internal view returns (uint256) {
    if (token == BASE_TOKEN) {
      return 10**DECIMALS;
    }
    address oracle = priceOracle[token];
    if (oracle == address(0)) {
      revert NoOracle(token);
    }
    return IPriceOracle(priceOracle[token]).getSafePrice(token);
  }

  function getSafePriceDenominatedIn(address token0, address token1) external view returns (uint256) {
    return (_getSafePrice(token0) * 10**DECIMALS) / _getSafePrice(token1);
  }

  function getCurrentPrice(address token) external view override returns (uint256) {
    return _getCurrentPrice(token);
  }

  function _getCurrentPrice(address token) internal view returns (uint256) {
    if (token == BASE_TOKEN) {
      return 10**DECIMALS;
    }
    address oracle = priceOracle[token];
    if (oracle == address(0)) {
      revert NoOracle(token);
    }
    return IPriceOracle(priceOracle[token]).getCurrentPrice(token);
  }

  function getCurrentPriceDenominatedIn(address token0, address token1) external view returns (uint256) {
    return (_getCurrentPrice(token0) * 10**DECIMALS) / _getCurrentPrice(token1);
  }

  function updateSafePrice(address token) external override returns (uint256) {
    if (token == BASE_TOKEN) {
      return 10**DECIMALS;
    }
    address oracle = priceOracle[token];
    if (oracle == address(0)) {
      revert NoOracle(token);
    }
    uint256 price = IPriceOracle(priceOracle[token]).updateSafePrice(token);
    emit PriceUpdated(token, price);
    return price;
  }
  

}