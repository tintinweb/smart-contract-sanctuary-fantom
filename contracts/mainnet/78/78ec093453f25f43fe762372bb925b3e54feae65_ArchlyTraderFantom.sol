/**
 *Submitted for verification at FtmScan.com on 2023-05-03
*/

// SPDX-License-Identifier: MIT
// Deployed at: 0x78EC093453F25F43Fe762372BB925B3E54feae65 (Fantom)
pragma solidity ^0.8.19;

// NOTE: All of the following interfaces are trimmed to only the functions that we need
interface IERC20 {
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 value) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function symbol() external pure returns (string memory);
  function transfer(address to, uint256 value) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount)
    external returns (bool);
}

interface IPair {
  // The amounts of the two tokens in the pair. These are sorted by address,
  // so reserve0 will be for the token with the lower address.
  // NOTE: The Archly source (as well as some other Solidly forks) define the returns types
  // differently, with uint256 everywhere. But this doesn't actually matter since all return
  // values are padded to 256 bits anyway.
  function getReserves() external view returns (
    uint112 reserve0,
    uint112 reserve1,
    uint32 blockTimestampLast);

  function swap(
    uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
}

contract ArchlyTraderFantom {
  // Hardcoded addresses for the tokens and LPs that we need to interact with.
  // NOTE: The tokens are sorted in address order to help us remember the correct order
  // for pairs. Pairs are sorted in alphabetical order.
  address constant private USDC = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
  address constant private fUSDT = 0x049d68029688eAbF473097a2fC38ef61633A3C7A;
  address constant private WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
  address constant private BTC = 0x321162Cd933E2Be498Cd2267a90534A804051b11;
  address constant private Arc = 0x684802262D614D0Cd0C9571672F03Dd9e85D7824;
  address constant private ETH = 0x74b23882a30290451A17c44f4F05243b6b58C76d;

  // Liquidity pool tokens, named after the tokens in the correct order
  address constant private Arc_ETH = 0xEe1e73CdFDf0ABF6cF9DF62cd294bFFfE2CC7b99;
  address constant private BTC_Arc = 0x7A08972cbF0fdC1b9C80B13E3B12bC1bC313e9a2;
  address constant private fUSDT_Arc = 0x4097fa95665E490C11F301aB5a241e9f31B7C81e;
  address constant private USDC_Arc = 0x1C518e41846C237440dDaa73c69751117feD787E;
  address constant private WFTM_Arc = 0xe962fEF0e7cE6D666359Dab6127f6f8d814aC1a9;

  address[] private pools = new address[](5);

  address[] private arcFirst = new address[](1);
  address[] private arcSecond = new address[](4);

  constructor() {
    pools[0] = Arc_ETH;
    pools[1] = BTC_Arc;
    pools[2] = fUSDT_Arc;
    pools[3] = USDC_Arc;
    pools[4] = WFTM_Arc;

    // NOTE: The code below assumes that there are at least one pool where Arc is the first
    // and one where Arc is the second token. If there are zero pools of one type we need to
    // adjust the code in buy() and sell() below!
    arcFirst[0] = ETH;
    arcSecond[0] = BTC;
    arcSecond[1] = fUSDT;
    arcSecond[2] = USDC;
    arcSecond[3] = WFTM;
  }

  // Buy a specific amount of Arc with other tokens (ETH, BTC, fUSDT, USDC and WFTM)
  // Note that due to roundoff errors the amount of Arc gotten may not be exactly the
  // specified amount.
  function buy(uint256 arcAmount) external {
    // Get all the pool reserves
    uint256[] memory arcReserves = new uint256[](5);
    uint256[] memory otherReserves = new uint256[](5);

    uint256 firstCount = arcFirst.length;
    uint256 secondCount = arcSecond.length;
    uint256 totalArcReserve = 0;
    for (uint256 i = 0; i < firstCount; ++i) {
      (uint256 arcReserve, uint otherReserve) = _getReserves(pools[i]);
      totalArcReserve += arcReserve;
      arcReserves[i] = arcReserve;
      otherReserves[i] = otherReserve;
    }

    for (uint256 ii = 0; ii < secondCount; ++ii) {
      uint256 i = firstCount + ii;
      (uint256 otherReserve, uint256 arcReserve) = _getReserves(pools[i]);
      totalArcReserve += arcReserve;
      arcReserves[i] = arcReserve;
      otherReserves[i] = otherReserve;
    }

    // Compute how many to spend on buying from each pool, perform checks to give
    // descriptive error messages and make the swaps.
    uint256 divisor = totalArcReserve * totalArcReserve;
    uint256 sellAmount;

    for (uint256 i = 0; i < firstCount; ++i) {
      sellAmount = arcAmount * arcReserves[i] * otherReserves[i] / divisor;
      require(_allowance(arcFirst[i], msg.sender, address(this)) >= sellAmount,
        string.concat(string.concat("ArchlyTrader: insufficient ",
          IERC20(arcFirst[0]).symbol()),
          " allowance"));

      require(IERC20(ETH).balanceOf(msg.sender) >= sellAmount,
        string.concat(string.concat("ArchlyTrader: insufficient ",
          IERC20(arcFirst[0]).symbol()),
          " balance"));

      if (sellAmount > 0) {
        _swapSecondToFirst(pools[i], arcFirst[i], sellAmount);
      }
    }

    for (uint256 ii = 0; ii < secondCount; ++ii) {
      uint256 i = firstCount + secondCount;
      sellAmount = arcAmount * arcReserves[i] * otherReserves[i] / divisor;

      require(_allowance(arcSecond[ii], msg.sender, address(this)) >= sellAmount,
        string.concat(string.concat("ArchlyTrader: insufficient ",
          IERC20(arcSecond[ii]).symbol()),
          " allowance"));

      require(IERC20(ETH).balanceOf(msg.sender) >= sellAmount,
        string.concat(string.concat("ArchlyTrader: insufficient ",
          IERC20(arcSecond[ii]).symbol()),
          " balance"));

      if (sellAmount > 0) {
        _swapFirstToSecond(pools[i], arcSecond[ii], sellAmount);
      }
    }
  }

  // Sell Arc for other tokens (ETH, BTC, fUSDT, USDC and WFTM)
  function sell(uint256 arcAmount) external {
    require(_allowance(Arc, msg.sender, address(this)) >= arcAmount,
      "ArchlyTrader: insufficient Arc allowance");

    require(IERC20(Arc).balanceOf(msg.sender) >= arcAmount,
      "ArchlyTrader: insufficient Arc balance");

    // Get all the pool reserves
    uint256[] memory arcReserves = new uint256[](5);

    uint256 firstCount = arcFirst.length;
    uint256 secondCount = arcSecond.length;
    uint256 totalArcReserve = 0;
    for (uint256 i = 0; i < firstCount; ++i) {
      (uint256 reserve,) = _getReserves(pools[i]);
      totalArcReserve += reserve;
      arcReserves[i] = reserve;
    }

    for (uint256 ii = 0; ii < secondCount; ++ii) {
      uint256 i = firstCount + ii;
      (,uint256 reserve) = _getReserves(pools[i]);
      totalArcReserve += reserve;
      arcReserves[i] = reserve;
    }

    // Compute how many Arc to sell into each pool and perform the swaps
    uint256 sellAmount;
    uint256 arcSold = 0;
    for (uint256 i = 0; i < firstCount; ++i) {
      sellAmount = arcAmount * arcReserves[i] / totalArcReserve;
      if (sellAmount > 0) {
        _swapFirstToSecond(pools[i], Arc, sellAmount);
      }

      arcSold += sellAmount;
    }

    for (uint256 ii = 0; ii < secondCount - 1; ++ii) {
      uint256 i = firstCount + ii;
      sellAmount = arcAmount * arcReserves[i] / totalArcReserve;

      if (sellAmount > 0) {
        _swapSecondToFirst(pools[i], Arc, sellAmount);
      }

      arcSold += sellAmount;
    }

    // For the last pool the amount is simply what's left (this avoids roundoff errors)
    sellAmount = arcAmount - arcSold;
    if (sellAmount > 0) {
      _swapSecondToFirst(pools[firstCount + secondCount - 1], Arc, sellAmount);
    }
  }

  // Helper functions to make the contract smaller and more readable
  function _allowance(address token, address owner, address spender)
    private view returns (uint256) {

    return IERC20(token).allowance(owner, spender);
  }

  function _transferFrom(address token, address from, address to, uint256 amount) private {
    bool success = IERC20(token).transferFrom(from, to, amount);
    require(success, "ArchlyTrader: transferring token from caller failed");
  }

  function _getReserves(address lpToken) private view returns (
    uint256 token0Reserve, uint256 token1Reserve) {

    (token0Reserve, token1Reserve, ) = IPair(lpToken).getReserves();
  }

  function _pairSwap(address pair, uint256 outAmount0, uint256 outAmount1, address to) private {
    IPair(pair).swap(outAmount0, outAmount1, to, new bytes(0));
  }

  // Swap the first token in the pair for the second.
  // Note that fromToken must be the same as pair.token0 (not checked).
  function _swapFirstToSecond(address pair, address fromToken, uint256 fromAmount) private {
    (uint256 reserveFirst, uint256 reserveSecond) = _getReserves(pair);

    uint256 secondOut;
    unchecked {
      // Note that these calculations only work for volatile pairs
      uint256 amountInAfterFee = fromAmount * 9995;  // 0.05% fee
      uint256 numerator = amountInAfterFee * reserveSecond;
      uint256 denominator = (reserveFirst * 10000) + amountInAfterFee;
      secondOut = numerator / denominator;
    }

    _transferFrom(fromToken, msg.sender, pair, fromAmount);
    _pairSwap(pair, 0, secondOut, msg.sender);
  }

  // Swap the second token in the pair for the first.
  // fromToken must be the same as pair.token1 (not checked).
  function _swapSecondToFirst(address pair, address fromToken, uint256 fromAmount) private {
    (uint256 reserveFirst, uint256 reserveSecond) = _getReserves(pair);

    uint256 firstOut;
    unchecked {
      uint256 amountInAfterFee = fromAmount * 9995;
      uint256 numerator = amountInAfterFee * reserveFirst;
      uint256 denominator = (reserveSecond * 10000) + amountInAfterFee;
      firstOut = numerator / denominator;
    }

    _transferFrom(fromToken, msg.sender, pair, fromAmount);
    _pairSwap(pair, firstOut, 0, msg.sender);
  }
}