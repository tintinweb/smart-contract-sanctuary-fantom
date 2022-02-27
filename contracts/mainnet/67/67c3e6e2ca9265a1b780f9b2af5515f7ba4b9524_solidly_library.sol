/**
 *Submitted for verification at FtmScan.com on 2022-02-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface solidly_pair {
    function metadata() external view returns (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, address t1);
}

contract solidly_library {

    function _f(uint x0, uint y) internal pure returns (uint) {
        return x0*(y*y/1e18*y/1e18)/1e18+(x0*x0/1e18*x0/1e18)*y/1e18;
    }

    function _d(uint x0, uint y) internal pure returns (uint) {
        return 3*x0*(y*y/1e18)/1e18+(x0*x0/1e18*x0/1e18);
    }

    function _get_y(uint x0, uint xy, uint y) internal pure returns (uint) {
        for (uint i = 0; i < 255; i++) {
            uint y_prev = y;
            uint k = _f(x0, y);
            if (k < xy) {
                uint dy = (xy - k)*1e18/_d(x0, y);
                y = y + dy;
            } else {
                uint dy = (k - xy)*1e18/_d(x0, y);
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

    function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'BaseV1Router: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'BaseV1Router: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address tokenA, address tokenB, bool stable) public pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
            hex'ff',
            0x3fAaB499b519fdC5819e3D7ed0C26111904cbc28,
            keccak256(abi.encodePacked(token0, token1, stable)),
            '0x57ae84018c47ebdaf7ddb2d1216c8c36389d12481309af65428eb6d460f747a4' // init code hash
        )))));
    }

    function getTradeDiff(uint amountIn, address tokenIn, address tokenOut, bool stable) external view returns (uint a, uint b) {
        (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0,) = solidly_pair(pairFor(tokenIn, tokenOut, stable)).metadata();
        uint sample = tokenIn == t0 ? r0/r1 : r1/r0;
        a = _getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / sample;
        b = _getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / amountIn;
    }

    function getTradeDiff(uint amountIn, address tokenIn, address pair) external view returns (uint a, uint b) {
        (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0,) = solidly_pair(pair).metadata();
        uint sample = tokenIn == t0 ? r0/r1 : r1/r0;
        a = _getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / sample;
        b = _getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / amountIn;
    }

    function _getAmountOut(uint amountIn, address tokenIn, uint _reserve0, uint _reserve1, address token0, uint decimals0, uint decimals1, bool stable) internal pure returns (uint) {
        if (stable) {
            uint xy =  _k(_reserve0, _reserve1, stable, decimals0, decimals1);
            _reserve0 = _reserve0 * 1e18 / decimals0;
            _reserve1 = _reserve1 * 1e18 / decimals1;
            (uint reserveA, uint reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
            amountIn = tokenIn == token0 ? amountIn * 1e18 / decimals0 : amountIn * 1e18 / decimals1;
            uint y = reserveB - _get_y(amountIn+reserveA, xy, reserveB);
            return y * (tokenIn == token0 ? decimals1 : decimals0) / 1e18;
        } else {
            (uint reserveA, uint reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
            return amountIn * reserveB / (reserveA + amountIn);
        }
    }

    function _k(uint x, uint y, bool stable, uint decimals0, uint decimals1) internal pure returns (uint) {
        if (stable) {
            uint _x = x * 1e18 / decimals0;
            uint _y = y * 1e18 / decimals1;
            uint _a = (_x * _y) / 1e18;
            uint _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
            return _a * _b / 1e18;  // x3y+y3x >= k
        } else {
            return x * y; // xy >= k
        }
    }
    
}