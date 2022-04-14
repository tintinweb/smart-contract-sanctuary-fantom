// SPDX-License-Identifier: MIT

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ============================= Oracle =============================
// ==================================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Vahid: https://github.com/vahid-dev
// Sina: https://github.com/spsina

import "./interfaces/IBaseV1Pair.sol";
import "./interfaces/IERC20.sol";

pragma solidity 0.8.13;

/// @title Oracle
/// @author DEUS Finance
/// @notice calculate twap price of solidly pair token0/token1
contract Oracle {
    address public baseV1Pair;
    address public token0;
    address public token1;
    uint256 public decimals0;
    uint256 public decimals1;
    bool public stable;

    constructor(address baseV1Pair_) {
        baseV1Pair = baseV1Pair_;
        token0 = IBaseV1Pair(baseV1Pair).token0();
        token1 = IBaseV1Pair(baseV1Pair).token1();
        decimals0 = IERC20(token0).decimals();
        decimals1 = IERC20(token1).decimals();
        stable = IBaseV1Pair(baseV1Pair).stable();
    }

    /**
     * @notice calculates the maximum points needed to get back to the specified timestamp
     * @param timestamp specific timestamp
     * @return searchIndex the index of the observation that is closest to the specified timestamp
     */
    function getFirstSearchIndex(uint256 timestamp)
        public
        view
        returns (uint256 searchIndex)
    {
        uint256 length = IBaseV1Pair(baseV1Pair).observationLength();
        uint256 delta = block.timestamp - timestamp;
        uint256 maxPointsNeeded = delta / 30 minutes;
        searchIndex = length - (maxPointsNeeded + 1);
    }

    /**
     * @notice calculates the exact index of the observation that is closest to the specified timestamp
     * @param timestamp specific timestamp
     * @return fromIndex the index of the observation that is closest to the specified timestamp
     */
    function getIndexAt(uint256 timestamp) public view returns (uint256) {
        uint256 index = getFirstSearchIndex(timestamp);
        uint256 _timestamp = IBaseV1Pair(baseV1Pair)
            .observations(index)
            .timestamp;

        while (_timestamp < timestamp) {
            index++;
            _timestamp = IBaseV1Pair(baseV1Pair).observations(index).timestamp;
        }
        return index - 1;
    }

    /**
     * @notice calculates the twap range
     * @param timestamp specific timestamp
     * @param duration duration of twap
     * @return from the index of the observation that is closest to the specified timestamp
     * @return to the index of the observation that is closest to the specified timestamp + duration
     */
    function getRange(uint256 timestamp, uint256 duration)
        public
        view
        returns (uint256 from, uint256 to)
    {
        from = getIndexAt(timestamp);
        to = getIndexAt(timestamp + duration);
    }

    /**
     * @notice calculates the twap price of token0/token1
     * @param timestamp specific timestamp
     * @return _twap the twap price of token0/token1
     */
    function twap(
        address tokenIn,
        uint256 amountIn,
        uint256 timestamp,
        uint256 duration
    ) external view returns (uint256 _twap) {
        uint256[] memory prices = price(tokenIn, amountIn, timestamp, duration);
        uint256 sum = 0;
        for (uint256 index = 0; index < prices.length; index++) {
            sum += prices[index];
        }
        _twap = sum / prices.length;
    }

    /**
     * @notice returns the price sample from timestamp to timestamp + duration for tokenIn
     * @param tokenIn token to get price sample
     * @param amountIn amount of token to get price sample
     * @param timestamp specific timestamp
     * @param duration duration of twap
     * @return prices the price sample from timestamp to timestamp + duration for tokenIn
     */
    function price(
        address tokenIn,
        uint256 amountIn,
        uint256 timestamp,
        uint256 duration
    ) public view returns (uint256[] memory prices) {
        (uint256 fromIndex, uint256 toIndex) = getRange(timestamp, duration);
        prices = sample(tokenIn, amountIn, fromIndex, toIndex);
    }

    /**
     * @notice returns price samples from fromIndex to toIndex for tokenIn
     * @param tokenIn token to get price sample
     * @param amountIn amount of token to get price sample
     * @param fromIndex the index of the observation that is closest to the specified timestamp
     * @param toIndex the index of the observation that is closest to the specified timestamp + duration
     * @return _prices the price samples from fromIndex to toIndex for tokenIn
     */
    function sample(
        address tokenIn,
        uint256 amountIn,
        uint256 fromIndex,
        uint256 toIndex
    ) public view returns (uint256[] memory) {
        uint256[] memory _prices = new uint256[](toIndex - fromIndex + 1);

        uint256 nextIndex;
        uint256 index;
        for (uint256 i = fromIndex; i <= toIndex; i++) {
            nextIndex = i + 1;
            uint256 timeElapsed = IBaseV1Pair(baseV1Pair)
                .observations(nextIndex)
                .timestamp - IBaseV1Pair(baseV1Pair).observations(i).timestamp;
            uint256 _reserve0 = (IBaseV1Pair(baseV1Pair)
                .observations(nextIndex)
                .reserve0Cumulative -
                IBaseV1Pair(baseV1Pair).observations(i).reserve0Cumulative) /
                timeElapsed;
            uint256 _reserve1 = (IBaseV1Pair(baseV1Pair)
                .observations(nextIndex)
                .reserve1Cumulative -
                IBaseV1Pair(baseV1Pair).observations(i).reserve1Cumulative) /
                timeElapsed;
            _prices[index] = _getAmountOut(
                amountIn,
                tokenIn,
                _reserve0,
                _reserve1
            );
            index++;
        }
        return _prices;
    }

    /**
     * @dev This is an identical function to the one in the baseV1Pair contract.
     */
    function _getAmountOut(
        uint256 amountIn,
        address tokenIn,
        uint256 _reserve0,
        uint256 _reserve1
    ) internal view returns (uint256) {
        if (stable) {
            uint256 xy = _k(_reserve0, _reserve1);
            _reserve0 = (_reserve0 * 1e18) / decimals0;
            _reserve1 = (_reserve1 * 1e18) / decimals1;
            (uint256 reserveA, uint256 reserveB) = tokenIn == token0
                ? (_reserve0, _reserve1)
                : (_reserve1, _reserve0);
            amountIn = tokenIn == token0
                ? (amountIn * 1e18) / decimals0
                : (amountIn * 1e18) / decimals1;
            uint256 y = reserveB - _get_y(amountIn + reserveA, xy, reserveB);
            return (y * (tokenIn == token0 ? decimals1 : decimals0)) / 1e18;
        } else {
            (uint256 reserveA, uint256 reserveB) = tokenIn == token0
                ? (_reserve0, _reserve1)
                : (_reserve1, _reserve0);
            return (amountIn * reserveB) / (reserveA + amountIn);
        }
    }

    /**
     * @dev This is an identical function to the one in the baseV1Pair contract.
     */
    function _k(uint256 x, uint256 y) internal view returns (uint256) {
        if (stable) {
            uint256 _x = (x * 1e18) / decimals0;
            uint256 _y = (y * 1e18) / decimals1;
            uint256 _a = (_x * _y) / 1e18;
            uint256 _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
            return (_a * _b) / 1e18; // x3y+y3x >= k
        } else {
            return x * y; // xy >= k
        }
    }

    /**
     * @dev This is an identical function to the one in the baseV1Pair contract.
     */
    function _get_y(
        uint256 x0,
        uint256 xy,
        uint256 y
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < 255; i++) {
            uint256 y_prev = y;
            uint256 k = _f(x0, y);
            if (k < xy) {
                uint256 dy = ((xy - k) * 1e18) / _d(x0, y);
                y = y + dy;
            } else {
                uint256 dy = ((k - xy) * 1e18) / _d(x0, y);
                y = y - dy;
            }
            if (y > y_prev) {
                if (y - y_prev <= 1) {
                    return y;
                }
            } else {
                if (y_prev - y <= 1) {
                    return y;
                }
            }
        }
        return y;
    }

    /**
     * @dev This is an identical function to the one in the baseV1Pair contract.
     */
    function _f(uint256 x0, uint256 y) internal pure returns (uint256) {
        return
            (x0 * ((((y * y) / 1e18) * y) / 1e18)) /
            1e18 +
            (((((x0 * x0) / 1e18) * x0) / 1e18) * y) /
            1e18;
    }

    /**
     * @dev This is an identical function to the one in the baseV1Pair contract.
     */
    function _d(uint256 x0, uint256 y) internal pure returns (uint256) {
        return
            (3 * x0 * ((y * y) / 1e18)) /
            1e18 +
            ((((x0 * x0) / 1e18) * x0) / 1e18);
    }
}

// SPDX-License-Identifier: MIT

struct Observation {
    uint256 timestamp;
    uint256 reserve0Cumulative;
    uint256 reserve1Cumulative;
}

interface IBaseV1Pair {
    function observations(uint256 index)
        external
        view
        returns (Observation calldata);

    function observationLength() external view returns (uint256);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function stable() external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function decimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}