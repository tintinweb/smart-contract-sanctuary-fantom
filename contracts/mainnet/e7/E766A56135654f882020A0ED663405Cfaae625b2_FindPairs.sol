/**
 *Submitted for verification at FtmScan.com on 2023-02-12
*/

pragma solidity ^0.8.0;

interface UniswapV2Factory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface UniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function balanceOf(address token) external view returns (uint256);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1);
}

contract FindPairs {
  struct Pair {
    address token0;          
    address token1;         
  }

  struct PairInfo {
    address pairAddress;
    uint112 reserve0;
    uint112 reserve1;
  }

  function findPairReserves(UniswapV2Factory _uniswapFactory,Pair[] calldata pairs) public view returns (PairInfo[] memory) {
    PairInfo[] memory result = new PairInfo[](pairs.length);
    uint256 index = 0;
    for (uint256 i = 0; i < pairs.length; i++) {
      address pairAddress = _uniswapFactory.getPair(pairs[i].token0, pairs[i].token1);
      if (pairAddress == address(0)) {
        continue;
      }
      UniswapV2Pair pair = UniswapV2Pair(pairAddress);
      (uint112 reserve0, uint112 reserve1) = pair.getReserves();
      result[index] = PairInfo(
        pairAddress,
        reserve0,
        reserve1
      );
      index++;
    }
    return result;
  }
}