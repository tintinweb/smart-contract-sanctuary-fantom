// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

library BytesLib {
  function slice(
    bytes memory _bytes,
    uint256 _start,
    uint256 _length
  ) internal pure returns (bytes memory) {
    require(_length + 31 >= _length, 'slice_overflow');
    require(_bytes.length >= _start + _length, 'slice_outOfBounds');
    bytes memory tempBytes;
    assembly {
      switch iszero(_length)
      case 0 {
        tempBytes := mload(0x40)
        let lengthmod := and(_length, 31)
        let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
        let end := add(mc, _length)
        for {
          let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
        } lt(mc, end) {
          mc := add(mc, 0x20)
          cc := add(cc, 0x20)
        } {
          mstore(mc, mload(cc))
        }
        mstore(tempBytes, _length)
        mstore(0x40, and(add(mc, 31), not(31)))
      }
      default {
        tempBytes := mload(0x40)
        mstore(tempBytes, 0)
        mstore(0x40, add(tempBytes, 0x20))
      }
    }
    return tempBytes;
  }

  function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
    require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
    address tempAddress;
    assembly {
      tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
    }
    return tempAddress;
  }

  function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
    require(_bytes.length >= _start + 2, 'toUint16_outOfBounds');
    uint16 tempUint;
    assembly {
      tempUint := mload(add(add(_bytes, 0x2), _start))
    }
    return tempUint;
  }

  function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
    require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
    uint24 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x3), _start))
    }
    return tempUint;
  }
}

library PathHelper {
  using BytesLib for bytes;
  uint256 private constant ADDR_SIZE = 20;
  uint256 private constant FEE_SIZE = 3;
  uint256 private constant TOKEN_AND_POOL_OFFSET = ADDR_SIZE + FEE_SIZE;
  uint256 private constant POOL_DATA_OFFSET = TOKEN_AND_POOL_OFFSET + ADDR_SIZE;
  uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POOL_DATA_OFFSET + TOKEN_AND_POOL_OFFSET;

  function hasMultiplePools(bytes memory path) internal pure returns (bool) {
    return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
  }

  function numPools(bytes memory path) internal pure returns (uint256) {
    return ((path.length - ADDR_SIZE) / TOKEN_AND_POOL_OFFSET);
  }

  function decodeFirstPool(bytes memory path)
    internal
    pure
    returns (
      address tokenA,
      address tokenB,
      uint24 fee
    )
  {
    tokenA = path.toAddress(0);
    fee = path.toUint24(ADDR_SIZE);
    tokenB = path.toAddress(TOKEN_AND_POOL_OFFSET);
  }

  function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
    return path.slice(0, POOL_DATA_OFFSET);
  }

  function skipToken(bytes memory path) internal pure returns (bytes memory) {
    return path.slice(TOKEN_AND_POOL_OFFSET, path.length - TOKEN_AND_POOL_OFFSET);
  }
}

interface INftManager {
  struct IncreaseLiquidityParams {
    uint256 tokenId;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  struct MintParams {
    address token0;
    address token1;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    int24[2] ticksPrevious;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    address recipient;
    uint256 deadline;
  }

  struct RemoveLiquidityParams {
    uint256 tokenId;
    uint128 liquidity;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  function addLiquidity(IncreaseLiquidityParams calldata params)
    external
    payable
    returns (
      uint128 liquidity,
      uint256 amount0,
      uint256 amount1,
      uint256 additionalRTokenOwed
    );
  
  function mint(MintParams calldata params)
    external
    payable
    returns (
      uint256 tokenId,
      uint128 liquidity,
      uint256 amount0,
      uint256 amount1
    );
  
  function removeLiquidity(RemoveLiquidityParams calldata params)
    external
    returns (
      uint256 amount0,
      uint256 amount1,
      uint256 additionalRTokenOwed
    );

  function factory() external view returns (address);
}

interface IFactory {
  function getPool(
    address tokenA,
    address tokenB,
    uint24 swapFeeUnits
  ) external view returns (address pool);
}

interface IPool {
  function mint(
    address recipient,
    int24 tickLower,
    int24 tickUpper,
    int24[2] calldata ticksPrevious,
    uint128 qty,
    bytes calldata data
  )
    external
    returns (
      uint256 qty0,
      uint256 qty1,
      uint256 feeGrowthInside
    );

  function burn(
    int24 tickLower,
    int24 tickUpper,
    uint128 qty
  )
    external
    returns (
      uint256 qty0,
      uint256 qty1,
      uint256 feeGrowthInside
    );

  function swap(
    address recipient,
    int256 swapQty,
    bool isToken0,
    uint160 limitSqrtP,
    bytes calldata data
  ) external returns (int256 qty0, int256 qty1);

  function factory() external view returns (IFactory);

  function token0() external view returns (IERC20);

  function token1() external view returns (IERC20);

  function swapFeeUnits() external view returns (uint24);

  function tickDistance() external view returns (int24);

  function maxTickLiquidity() external view returns (uint128);

  function ticks(int24 tick)
    external
    view
    returns (
      uint128 liquidityGross,
      int128 liquidityNet,
      uint256 feeGrowthOutside,
      uint128 secondsPerLiquidityOutside
    );

  function initializedTicks(int24 tick) external view returns (int24 previous, int24 next);

  function getPositions(
    address owner,
    int24 tickLower,
    int24 tickUpper
  ) external view returns (uint128 liquidity, uint256 feeGrowthInsideLast);

  function getPoolState()
    external
    view
    returns (
      uint160 sqrtP,
      int24 currentTick,
      int24 nearestCurrentTick,
      bool locked
    );

  function getLiquidityState()
    external
    view
    returns (
      uint128 baseL,
      uint128 reinvestL,
      uint128 reinvestLLast
    );
}

contract Kybersw {
  using PathHelper for bytes;

  address public NftManger = 0x2B1c7b41f6A8F2b2bc45C3233a5d5FB3cD6dC9A8;

  struct SwapCallbackData {
    bytes path;
    address source;
  }

  function factory() public view returns(address) {
    return INftManager(NftManger).factory();
  }

  function pool(address tokenA, address tokenB, uint24 swapFeeUnits) public view returns(address) {
    return IFactory(INftManager(NftManger).factory()).getPool(tokenA, tokenB, swapFeeUnits);
  }

  function getPositions(address poolAddr, address owner, int24 tickLower, int24 tickUpper) public view returns (uint128 liquidity, uint256 feeGrowthInsideLast) {
    return IPool(poolAddr).getPositions(owner, tickLower, tickUpper);
  }

  function getPoolState(address poolAddr) public view returns (uint160 sqrtP, int24 currentTick, int24 nearestCurrentTick, bool locked) {
    return IPool(poolAddr).getPoolState();
  }

  function getLiquidityState(address poolAddr) public view returns (uint128 baseL, uint128 reinvestL, uint128 reinvestLLast) {
    return IPool(poolAddr).getLiquidityState();
  }

  function tickDistance(address poolAddr) public view returns (int24) {
    return IPool(poolAddr).tickDistance();
  }

  function ticks(address poolAddr, int24 tick) public view returns (uint128 liquidityGross, int128 liquidityNet, uint256 feeGrowthOutside, uint128 secondsPerLiquidityOutside) {
    return IPool(poolAddr).ticks(tick);
  }

  function swap(address poolAddr, address recipient, int256 swapQty, bool isToken0, uint160 limitSqrtP) public returns (int256 qty0, int256 qty1) {
    address token = address(IPool(poolAddr).token0());
    address tokenOut = address(IPool(poolAddr).token1());
    if (isToken0) {
      IPool(poolAddr).token0().transferFrom(msg.sender, address(this), uint256(swapQty));
    }
    else {
      token = address(IPool(poolAddr).token1());
      tokenOut = address(IPool(poolAddr).token0());
      IPool(poolAddr).token1().transferFrom(msg.sender, address(this), uint256(swapQty));
    }
    bytes memory data = _getCallback(token, IPool(poolAddr).swapFeeUnits(), tokenOut);
    return IPool(poolAddr).swap(recipient, swapQty, isToken0, limitSqrtP, data);
  }

  function swapCallback(
    int256 deltaQty0,
    int256 deltaQty1,
    bytes calldata data
  ) external {
    require(deltaQty0 > 0 || deltaQty1 > 0, 'Router: invalid delta qties');
    SwapCallbackData memory swapData = abi.decode(data, (SwapCallbackData));
    (address tokenIn, address tokenOut, uint24 fee) = swapData.path.decodeFirstPool();
    require(msg.sender == pool(tokenIn, tokenOut, fee), 'Router: invalid callback sender');

    (bool isExactInput, uint256 amountToTransfer) = deltaQty0 > 0
      ? (tokenIn < tokenOut, uint256(deltaQty0))
      : (tokenOut < tokenIn, uint256(deltaQty1));
    if (isExactInput) {
      _transferTokens(tokenIn, swapData.source, msg.sender, amountToTransfer);
    } else {
      _transferTokens(tokenOut, swapData.source, msg.sender, amountToTransfer);
    }
  }

  function _getCallback(address tokenOut, uint24 fee, address tokenIn) internal view returns(bytes memory) {
    return abi.encode(SwapCallbackData({
      path: abi.encodePacked(tokenOut, fee, tokenIn),
      source: msg.sender
    }));
  }

  function _transferTokens(address token, address src, address des, uint256 amount) internal {
    IERC20(token).transferFrom(src, des, amount);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";