/**
 *Submitted for verification at FtmScan.com on 2022-06-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract FlashQueryV1 {
    function getReservesByPairs(IUniswapV2Pair[] calldata _pairs) external view  
        returns (uint256[3][] memory reserves) {
        reserves = new uint256[3][](_pairs.length);
        for (uint i = 0; i < _pairs.length; i++) {
            (reserves[i][0], reserves[i][1], reserves[i][2]) = _pairs[i].getReserves();
        }
    }
}