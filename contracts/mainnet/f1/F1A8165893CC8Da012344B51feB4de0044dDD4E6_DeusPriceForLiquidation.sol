/**
 *Submitted for verification at FtmScan.com on 2022-04-05
*/

// Be name Khoda
// Bime Abolfazl

// SPDX-License-Identifier: GPL-2.0-or-later

// Authors
// MiKO
// Kazem GH

pragma solidity ^0.8.13;

interface IPair {
    function getAmountOut(uint256 amountIn, address tokenIn) external view returns (uint256 amount);

    function getReserves() external view returns (uint256 res0, uint256 res1, uint256 timestamp);

    function totalSupply() external view returns (uint256);
}

interface ILender {
    function getLiquidationPrice(address user) external view returns (uint256);
}


contract DeusPriceForLiquidation {
    address public lpAddress = 0xF42dBcf004a93ae6D5922282B304E2aEFDd50058;  // DEI-DEUS LP
    // address public lenderAddress = 0x6d9d6A0b927FE954700b29380ae7b1B118f58BF1;
    address public solidlyRouter = 0xa38cd27185a464914D3046f0AB9d43356B34829D;
    address public DEI = 0xDE12c7959E1a72bbe8a5f7A1dc8f8EeF9Ab011B3;
    address public DEUS = 0xDE5ed76E7c05eC5e4572CfC88d1ACEA165109E44;

    constructor () {}

    function getAmountIn(uint256 amountOut, uint256 eps) public view returns (uint256) {
        IPair pair = IPair(lpAddress);
        uint256 upper;
        (, upper,) = pair.getReserves();
        uint256 lower = 0;
        uint256 mid = (upper + lower) / 2;
        uint256 res;
        bool stop = false;

        for (uint i = 0; i < 200; i++) {
            res = pair.getAmountOut(mid, DEUS);
            if (res > amountOut) {
                upper = mid;
                stop = res - amountOut < eps;
            }
            else {
                lower = mid;
                stop = amountOut - res < eps;
            }
            if (stop)
                break;
            mid = (upper + lower) / 2;
        }
        return mid;
    }

    function deusPriceForLiquidation(address lenderAddress, address user, uint256 eps) external view returns (uint256 deusPrice) {
        IPair pair = IPair(lpAddress);
        uint256 reserveDei;
        uint256 reserveDeus;
        uint256 userLiquidationPrice = ILender(lenderAddress).getLiquidationPrice(user);
        (reserveDei, reserveDeus,) = pair.getReserves();
        uint256 rhs = (userLiquidationPrice * pair.totalSupply() / (2 * 1e18));
        if (reserveDei < rhs)
            return type(uint256).max;  // Already can be liquidated
        uint256 deiAmount = reserveDei - rhs;
        uint256 deusAmount = getAmountIn(deiAmount, eps);
        deusPrice = (reserveDei - deiAmount) * 1e3 / (reserveDeus + deusAmount);
    }
}

// Dar panahe Khoda