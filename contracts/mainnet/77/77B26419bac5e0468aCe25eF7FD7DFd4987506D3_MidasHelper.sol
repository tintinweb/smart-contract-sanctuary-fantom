/**
 *Submitted for verification at FtmScan.com on 2022-11-15
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

contract MidasHelper {

  struct PairReserves {
    uint112 reserve0;
    uint112 reserve1;
    uint32 blockTimestampLast;
  }

  function getReservesByPairs(
    IUniswapV2Pair[] calldata pairs
  ) external view returns (PairReserves[] memory) {
    PairReserves[] memory result = new PairReserves[](pairs.length);
    for (uint i; i < pairs.length; i++) {
      (result[i].reserve0, result[i].reserve1, result[i].blockTimestampLast) = pairs[i].getReserves();
    }
    return result;
  }

  function getPairsByIndexRange(
    IUniswapV2Factory uniswapFactory,
    uint256 start,
    uint256 stop
  ) external view returns (address[3][] memory)  {
    uint256 allPairsLength = uniswapFactory.allPairsLength();
    if (stop > allPairsLength) stop = allPairsLength;
    require(stop >= start, "start cannot be higher than stop");
    uint256 qty = stop - start;
    address[3][] memory result = new address[3][](qty);
    for (uint i; i < qty; i++) {
      IUniswapV2Pair uniswapPair = IUniswapV2Pair(uniswapFactory.allPairs(start + i));
      result[i][0] = uniswapPair.token0();
      result[i][1] = uniswapPair.token1();
      result[i][2] = address(uniswapPair);
    }
    return result;
  }
}