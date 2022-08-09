// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import './interfaces/IUniswapV2Router.sol';
import './interfaces/IERC20Ext.sol';

interface PriceRouter {
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}

contract Oracle {
    address public wethAddress;
    address public usdcAddress;

    mapping(address => PriceRouter) public routerForFactory;
    PriceRouter public router;

    address ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(
        address _routerAddress,
        address _wethAddress,
        address _usdcAddress
    ) {
        router = PriceRouter(_routerAddress);
        usdcAddress = _usdcAddress;
        wethAddress = _wethAddress;
    }

    function getPriceUsdc(address tokenAddress) public view returns (uint256 price, address[] memory route) {
        if (tokenAddress == usdcAddress) return (1e6, new address[](0));
        return getPriceFromRouterUsdc(tokenAddress);
    }

    function getPriceFromRouterUsdc(address tokenAddress) public view returns (uint256 price, address[] memory route) {
        return getPriceFromRouter(tokenAddress, usdcAddress);
    }

    function getRoute(address token0Address, address token1Address) public view returns (address[] memory route) {
        (,route) = getPriceFromRouter(token0Address, token1Address);
    }

    function getPriceFromRouter(address token0Address, address token1Address)
        public
        view
        returns (uint256 price, address[] memory route)
    {
        // Convert ETH address (0xEeee...) to WETH
        if (token0Address == ethAddress) {
            token0Address = wethAddress;
        }
        if (token1Address == ethAddress) {
            token1Address = wethAddress;
        }

        address[] memory directPath = new address[](2);
        directPath[0] = token0Address;
        directPath[1] = token1Address;

        // Early exit with direct path if [token0, weth] or [weth, token1]
        if (token0Address == wethAddress || token1Address == wethAddress) {
            return (_amountOut(directPath), directPath);
        }

        // path = [token0, weth, token1] or [token0, token1]
        address[] memory throughWethPath = new address[](3);
        throughWethPath[0] = token0Address;
        throughWethPath[1] = wethAddress;
        throughWethPath[2] = token1Address;

        uint256 throughWethOut = _amountOut(throughWethPath);
        uint256 directOut = _amountOut(directPath);
        if (throughWethOut > directOut) {
            return (throughWethOut, throughWethPath);
        } else {
            return (directOut, directPath);
        }
    }

    function _amountOut(address[] memory path) internal view returns (uint256) {
        IERC20Ext token0 = IERC20Ext(path[0]);
        uint256 amountIn = 10**uint256(token0.decimals());
        uint256[] memory amountsOut = router.getAmountsOut(amountIn, path);

        uint256 amountOut = amountsOut[amountsOut.length - 1];
        uint256 feeBips = 20; // .2% per swap
        amountOut = (amountOut * 10000) / (10000 - (feeBips * path.length));
        return amountOut;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function getReserves()
        external
        view
        returns (
            uint112,
            uint112,
            uint32
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Ext is IERC20 {
  function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}