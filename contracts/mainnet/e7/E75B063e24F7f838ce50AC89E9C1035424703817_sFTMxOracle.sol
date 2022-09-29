pragma solidity >=0.8.0;

import "./ProviderAwareOracle.sol";
import "../PriceProvider.sol";

interface IFTMStaking {
    function getExchangeRate() external view returns (uint256);
}

/**
 * @author 0xTinder for Revest Finance
 * Simple sFTMx oracle to return the price of sFTMx in terms of WETH. References the
 * exchange rate tracked in the FTMStaking contract found:
 * https://ftmscan.deth.net/address/0xB458BfC855ab504a8a327720FcEF98886065529b#readProxyContract
 */
contract sFTMxOracle is ProviderAwareOracle {
    address wFTM;
    IFTMStaking FTMStaking;
    /**
     * @param _provider address of the Revest PriceProvider
     * @param _wFTM address of WFTM
     * @param _FTMStaking address of the sFTMx staking contract
     */
    constructor(address _provider, address _wFTM, address _FTMStaking)
        ProviderAwareOracle(_provider)
    {
        wFTM = _wFTM;
        FTMStaking = IFTMStaking(_FTMStaking);
    }
    /**
     * @notice get the flashloan resistant price for sFTMx
     * @param "" included for interface compliance
     * @return _amountOut the sFTMx/WETH exchange rate
     */
    function getSafePrice(address) public view returns (uint256 _amountOut) {
        // get the current price of wFTM
        uint256 ftmPrice = provider.getSafePrice(wFTM);

        // get the current xrate
        uint256 xrate = FTMStaking.getExchangeRate();

        return ftmPrice * xrate / 1e18;
    }
    /**
     * @notice get the current price for sFTMx
     * @param "" included for interface compliance
     * @return _amountOut the sFTMx/WETH exchange rate
     * @dev `getSafePrice` and `getCurrentPrice` differ only by their call to priceProvider,
     * however in prod only getSafePrice is used.
     */
    function getCurrentPrice(address)
        public
        view
        returns (uint256 _amountOut)
    {
        // get the current price of wFTM
        uint256 ftmPrice = provider.getCurrentPrice(wFTM);

        // get the current xrate
        uint256 xrate = FTMStaking.getExchangeRate();

        return ftmPrice * xrate / 1e18;
    }

    /// @dev this isn't relevant for chainlink based oracles
    function updateSafePrice(address token)
        external
        returns (uint256 _amountOut)
    {
        return getCurrentPrice(token);
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

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

interface IERC20Detailed {

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);
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