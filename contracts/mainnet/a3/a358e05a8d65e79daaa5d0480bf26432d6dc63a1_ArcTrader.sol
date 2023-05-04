/**
 *Submitted for verification at FtmScan.com on 2023-05-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// NOTE: All of the following interfaces are trimmed to only the functions that we need
interface IERC20 {
  function allowance(address owner, address spender) external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function symbol() external pure returns (string memory);
  function transferFrom(address sender, address recipient, uint256 amount)
    external returns (bool);
}

interface IFactory {
  function getPair(address tokenA, address tokenB, bool stable) external returns (address);
}

interface IPair {
  // The amounts of the two tokens in the pair. These are sorted by address,
  // so reserve0 will be for the token with the lower address.
  // NOTE: The Archly source (as well as some other Solidly forks) define the returns types
  // differently, with uint256 everywhere. But this doesn't matter here since all return
  // values are padded to 256 bits anyway.
  function getReserves() external view returns (
    uint112 reserve0,
    uint112 reserve1,
    uint32 blockTimestampLast);

  function swap(
    uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
}

contract ArcTrader {
  // The Arc token address
  address immutable public Arc;

  // Address of the Archly pair factory
  address immutable public PairFactory;

  // The tokens that Arc may have pools with (pools with other tokens will be ignored),
  // set in the constructor. Tokens with transfer tax are not supported.
  address[] public Tokens;

  // The Arc/Token (or Token/Arc) liquidity pools. This is set in the constructor but may
  // be updated to include newly added pools (for existing tokens) by calling the public
  // function updatePools().
  address[] public Pools;

  // The constructor sets the Arc token address, the Archly pair factory and all the tokens
  // with which Arc will (potentially) have pools (only volatile pools are considered).
  constructor(address arc, address pairFactory, address[] memory tokens) {
    // Gas optimization is less important here but errors could be cause headaches (and be
    // costly) so we include some extra checks with descriptive error messages.
    try IERC20(arc).symbol() returns (string memory symbol) {
      require(_isArc(symbol), string.concat(string.concat(
          "ArcTrader: arc token address is the ", symbol), " token"));
    } catch {
      require(false, "ArcTrader: invalid Arc token address.");
    }

    Arc = arc;

    require(tokens.length >= 1, "ArcTrader: Arc must have a pool with at least one token");

    // Verify that the factory is correct and that the pair for the first token exists
    try IFactory(pairFactory).getPair(Arc, tokens[0], false) returns (address pairAddress) {
      require(pairAddress != address(0), "ArcTrader: a pool with the first token must exist");
    } catch {
      require(false, "ArcTrader: invalid pairFactory address.");
    }

    PairFactory = pairFactory;

    for (uint256 i = 0; i < tokens.length; ++i) {
      require(tokens[i] != arc, "ArcTrader: Arc cannot have a pair with itself");

      try IERC20(tokens[i]).balanceOf(address(this)) { }
      catch {
        require(false, "ArcTrader: one or more token addresses are not valid tokens.");
      }

      for (uint256 j = 0; j < i; ++j) {
        require(tokens[i] != tokens[j], "ArcTrader: duplicate token.");
      }

      Tokens.push(tokens[i]);
      Pools.push(address(0));
    }

    // Find and save the pool addresses
    updatePools();
  }

  // This function should be called when one or more new pool (with token we use) have been
  // created.
  function updatePools() public {
    uint256 count = Tokens.length;

    unchecked {
      for (uint256 i = 0; i < count; ++i) {
        if (Pools[i] == address(0)) {
          Pools[i] = IFactory(PairFactory).getPair(Arc, Tokens[i], false);
        }
      }
    }
  }

  // Sells ALL the caller's Arc tokens (for convenience and gas savings).
  function sellAll() external {
    sell(IERC20(Arc).balanceOf(msg.sender));
  }

  // Sells Arc for the other tokens in the right proportions.
  function sell(uint256 arcAmount) public {
    require(_allowance(Arc, msg.sender, address(this)) >= arcAmount,
      "ArcTrader: insufficient Arc allowance");

    require(IERC20(Arc).balanceOf(msg.sender) >= arcAmount,
      "ArcTrader: insufficient Arc balance");

    uint256 count = Tokens.length;

    uint256[] memory arcReserves = new uint256[](count);

    unchecked {
      // Get all the pool reserves and also sum up the total.
      uint256 totalArcReserve = 0;
      for (uint256 i = 0; i < count; ++i) {
        if (Pools[i] != address(0)) {
          uint256 arcReserve;
          if (Arc < Tokens[i]) {
            (arcReserve,) = _getReserves(Pools[i]);
          } else {
            (,arcReserve) = _getReserves(Pools[i]);
          }

          arcReserves[i] = arcReserve;
          totalArcReserve += arcReserve;
        }
      }

      // Compute how many Arc to sell into each pool and perform the swaps.
      // Skip the first (always existing) pool; it will be used last.
      uint256 arcSold = 0;
      uint256 sellAmount;
 
      for (uint256 i = 1; i < count; ++i) {
        if (arcReserves[i] > 0) {
          sellAmount = arcAmount * arcReserves[i] / totalArcReserve;
          _swap(Pools[i], Arc, Tokens[i], sellAmount);
          arcSold += sellAmount;
        }
      }

      // For the remaining pool the amount is simply what's left (this saves gas and makes sure
      // we sell the exact right amount).
      sellAmount = arcAmount - arcSold;
      _swap(Pools[0], Arc, Tokens[0], sellAmount);
    }
  }

  // Buys a specific amount of Arc using the right amount of all the other tokens.
  // Note that spend approvals must have been given to all tokens (that have pools) and the
  // caller must have enough balance of them.
  function buy(uint256 arcAmount) external {
    uint256 count = Tokens.length;

    uint256[] memory arcReserves = new uint256[](count);

    unchecked {
      // Get all the pool reserves and also sum up the total.
      uint256 totalArcReserve = 0;
      for (uint256 i = 0; i < count; ++i) {
        if (Pools[i] != address(0)) {
          uint256 arcReserve;
          if (Arc < Tokens[i]) {
            (arcReserve,) = _getReserves(Pools[i]);
          } else {
            (,arcReserve) = _getReserves(Pools[i]);
          }

          arcReserves[i] = arcReserve;
          totalArcReserve += arcReserve;
        }
      }

      // Compute how many Arc we want to get from each pool and perform the swaps.
      // Skip the first (always existing) pool; it will be used last.
      uint256 arcBought = 0;
      uint256 buyAmount;
 
      for (uint256 i = 1; i < count; ++i) {
        if (arcReserves[i] > 0) {
          buyAmount = arcAmount * arcReserves[i] / totalArcReserve;
          _reverseSwap(Pools[i], Arc, Tokens[i], buyAmount);
          arcBought += buyAmount;
        }
      }

      // For the remaining pool the amount is simply what's left (this saves gas and makes sure
      // we sell the exact right amount).
      buyAmount = arcAmount - arcBought;
      _reverseSwap(Pools[0], Arc, Tokens[0], buyAmount);
    }
  }

  // Helper functions to make the contract smaller and more readable
  function _allowance(address token, address owner, address spender)
    private view returns (uint256) {

    return IERC20(token).allowance(owner, spender);
  }

  function _transferFrom(address token, address from, address to, uint256 amount) private {
    bool success = IERC20(token).transferFrom(from, to, amount);
    require(success, "ArcTrader: unexpected token transfer failure");
  }

  function _getReserves(address lpToken) private view returns (
    uint256 token0Reserve, uint256 token1Reserve) {

    (token0Reserve, token1Reserve, ) = IPair(lpToken).getReserves();
  }

  function _pairSwap(address pair, uint256 outAmount0, uint256 outAmount1, address to)
    private {

    IPair(pair).swap(outAmount0, outAmount1, to, new bytes(0));
  }

  // Check if the token symbol is "Arc"
  function _isArc(string memory symbol) private pure returns (bool) {
    bytes memory b = bytes(symbol);
    if (b.length != 3) {
      return false;
    }

    return b[0] == 'A' && b[1] == 'r' && b[2] == 'c';
  }

  // Swaps a specific amount from one token to the other.
  function _swap(address pair, address fromToken, address toToken, uint256 fromAmount)
    private {

    (uint256 reserve0, uint256 reserve1) = _getReserves(pair);

    bool sorted = fromToken < toToken;

    uint256 fromReserve;
    uint256 toReserve;
    if (sorted) {
      fromReserve = reserve0;
      toReserve = reserve1;
    } else {
      fromReserve = reserve1;
      toReserve = reserve0;
    }

    unchecked {
      // Note that these calculations (originally from UniSwapV2) only work for volatile pairs.
      uint256 fromAmountAfterFee = fromAmount * 9995;  // 0.05% fee
      uint256 numerator = fromAmountAfterFee * toReserve;
      uint256 denominator = (fromReserve * 10000) + fromAmountAfterFee;
      uint256 toAmount = numerator / denominator;

      // This transfer should always succeed since we have already checked the allowance
      // and balance in sell().
      _transferFrom(fromToken, msg.sender, pair, fromAmount);
      if (sorted) {
        _pairSwap(pair, 0, toAmount, msg.sender);
      } else {
        _pairSwap(pair, toAmount, 0, msg.sender);
      }
    }
  }

  // Swaps from one token to a specific amount of the other.
  // Note that no check is made that toAmount is smaller than the reserve in the pair; if not
  // the resulting transaction error may be obscure (this won't happen if the code above is
  // correct).
  function _reverseSwap(address pair, address fromToken, address toToken, uint256 toAmount)
    private {

    (uint256 reserve0, uint256 reserve1) = _getReserves(pair);

    bool sorted = fromToken < toToken;

    uint256 fromReserve;
    uint256 toReserve;
    if (sorted) {
      fromReserve = reserve0;
      toReserve = reserve1;
    } else {
      fromReserve = reserve1;
      toReserve = reserve0;
    }

    unchecked {
      uint256 numerator = fromReserve * toAmount * 10000;
      uint256 denominator = (toReserve - toAmount) * 9995;
      uint256 fromAmount = (numerator / denominator) + 1;

      // Verify the caller's allowance and balance so we can give descriptive error messages
      require(_allowance(fromToken, msg.sender, address(this)) >= fromAmount,
        string.concat(string.concat(
          "ArcTrader: insufficient ", IERC20(fromToken).symbol()), " allowance"));

      require(IERC20(fromToken).balanceOf(msg.sender) >= fromAmount,
        string.concat(string.concat(
          "ArcTrader: insufficient ", IERC20(fromToken).symbol()), " balance"));

      _transferFrom(fromToken, msg.sender, pair, fromAmount);
      if (sorted) {
        _pairSwap(pair, 0, toAmount, msg.sender);
      } else {
        _pairSwap(pair, toAmount, 0, msg.sender);
      }
    }
  }
}