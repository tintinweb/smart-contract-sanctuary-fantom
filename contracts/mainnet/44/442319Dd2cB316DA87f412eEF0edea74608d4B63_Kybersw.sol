// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

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
  address public NftManger = 0x2B1c7b41f6A8F2b2bc45C3233a5d5FB3cD6dC9A8;

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

  function swap(address poolAddr, address recipient, int256 swapQty, bool isToken0, uint160 limitSqrtP, bytes calldata data) public returns (int256 qty0, int256 qty1) {
    address token = address(IPool(poolAddr).token0());
    if (isToken0) {
      IPool(poolAddr).token0().transferFrom(msg.sender, address(this), uint256(swapQty));
    }
    else {
      token = address(IPool(poolAddr).token1());
      IPool(poolAddr).token1().transferFrom(msg.sender, address(this), uint256(swapQty));
    }
    _approveTokenIfNeeded(token, poolAddr);
    return IPool(poolAddr).swap(recipient, swapQty, isToken0, limitSqrtP, data);
  }

  function swapCallback(int256 deltaQty0, int256 deltaQty1, bytes calldata data) public {}

  function _approveTokenIfNeeded(address token, address spender) private {
    if (IERC20(token).allowance(address(this), spender) == 0) {
      IERC20(token).approve(spender, type(uint256).max);
    }
  }

  function _removeAllowances(address token, address spender) private {
    if (IERC20(token).allowance(address(this), spender) > 0) {
      IERC20(token).approve(spender, 0);
    }
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