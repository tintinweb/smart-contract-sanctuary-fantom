// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "IERC20.sol";
import "IPriceFeed.sol";
import "IBaseV1Router01.sol";
import "IUniv2LikeRouter01.sol";
import "ICurveRouter.sol";

/// @title Onchain pricer for calculating the price onchain of a token by taking the best from multipler routers
/// @author Modified from the work already done by @GalloDaSballo & @jack-the-pug
contract OnChainPriceFetcher is IPriceFeed {
    // Assumption #1 Most tokens liquid pair is WETH (WETH is tokenized ETH for that chain)
    // e.g on Fantom, WETH would be wFTM
    address public immutable WETH; // WFTM

    // Curve / Doesn't revert on failure
    address public immutable CURVE_ROUTER;
    address public immutable SOLIDLY_ROUTER;

    /// == Uni V2 Like Routers || These revert on non-existent pair == //
    address public immutable UNIV2_ROUTER_1; // Spookyswap
    address public immutable UNIV2_ROUTER_2; // Sushiswap

    // USD  (USDC / USDT / MIM / 3CRV)
    address public immutable QUOTE_USD_TOKEN;
    uint256 public immutable QUOTE_USD_DECIMAL;

    constructor(
        address _quote_usd_token,
        address _weth,
        address _curveRouter,
        address _solidlyRouter,
        address _uniRouter1,
        address _uniRouter2
    ) public {
        QUOTE_USD_TOKEN = _quote_usd_token;
        QUOTE_USD_DECIMAL = IERC20(_quote_usd_token).decimals();

        WETH = _weth;
        CURVE_ROUTER = _curveRouter;
        SOLIDLY_ROUTER = _solidlyRouter;
        UNIV2_ROUTER_1 = _uniRouter1;
        UNIV2_ROUTER_2 = _uniRouter2;
    }

    /// @notice public method to get the best onchain price of a token in terms of the quote_usd_token
    /// @param _token contract address of the token for which the price is to be calculated
    /// @return priceInUSD price of the _token in `QUOTE_USD_TOKEN` terms
    function getData(address _token)
        public
        view
        override
        returns (uint256 priceInUSD)
    {
        uint256 amount = 10**uint256(IERC20(_token).decimals()); // 1 unit of the token
        uint256 quote;

        // Check Solidly
        quote = getSolidlyQuote(_token, amount, QUOTE_USD_TOKEN);
        if (quote > priceInUSD) priceInUSD = quote;
        // Check Curve
        quote = getCurveQuote(_token, amount, QUOTE_USD_TOKEN);
        if (quote > priceInUSD) priceInUSD = quote;

        // uniswapv2s
        quote = getUniV2Quote(UNIV2_ROUTER_1, _token, QUOTE_USD_TOKEN, amount);
        if (quote > priceInUSD) priceInUSD = quote;

        quote = getUniV2Quote(UNIV2_ROUTER_2, _token, QUOTE_USD_TOKEN, amount);
        if (quote > priceInUSD) priceInUSD = quote;
    }

    /// @dev Given the address of the UniV2Like Router, the input amount, and the path, returns the quote for it
    function getUniV2Quote(
        address router,
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) public view returns (uint256) {
        address[] memory path = new address[](3);
        path[0] = address(tokenIn);
        path[1] = WETH;
        path[2] = address(tokenOut);

        uint256 quote; //0

        // TODO: Consider doing check before revert to avoid paying extra gas
        // Specifically, test gas if we get revert vs if we check to avoid it
        try IUniv2LikeRouter01(router).getAmountsOut(amountIn, path) returns (
            uint256[] memory amounts
        ) {
            quote = amounts[amounts.length - 1]; // Last one is the outToken
        } catch (bytes memory) {
            // We ignore as it means it's zero
        }

        return _scalePriceTo1e18(quote);
    }

    /// @notice returns the solidly quote of fromToken in terms of toToken for given amount
    function getSolidlyQuote(
        address fromToken,
        uint256 amount,
        address toToken
    ) public view returns (uint256) {
        if (SOLIDLY_ROUTER == address(0)) return 0;

        (uint256 solidlyQuote, ) = IBaseV1Router01(SOLIDLY_ROUTER).getAmountOut(
            amount,
            fromToken,
            toToken
        );

        return _scalePriceTo1e18(solidlyQuote);
    }

    /// @notice returns the curve quote of fromToken in terms of toToken for given amount
    function getCurveQuote(
        address fromToken,
        uint256 amount,
        address toToken
    ) public view returns (uint256) {
        if (CURVE_ROUTER == address(0)) return 0;

        (, uint256 curveQuote) = ICurveRouter(CURVE_ROUTER).get_best_rate(
            fromToken,
            toToken,
            amount
        );

        return _scalePriceTo1e18(curveQuote);
    }

    /// @notice scales the given quote to 18 decimals
    function _scalePriceTo1e18(uint256 rawPrice)
        internal
        view
        returns (uint256)
    {
        if (QUOTE_USD_DECIMAL <= 18) {
            return rawPrice * (10**(18 - QUOTE_USD_DECIMAL));
        } else {
            return rawPrice / (10**(QUOTE_USD_DECIMAL - 18));
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IPriceFeed {
    function getData(address tokenAddress) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;
struct route {
    address from;
    address to;
    bool stable;
}

interface IBaseV1Router01 {
    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amount, bool stable);

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        route[] calldata routes,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IUniv2LikeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface ICurveRouter {
    function get_best_rate(
        address from,
        address to,
        uint256 _amount
    ) external view returns (address, uint256);

    function exchange_with_best_rate(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _expected
    ) external returns (uint256);
}