// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Swapper.sol";

interface IUniRouter {
  function swapTokensForExactETH(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function WETH() external pure returns (address);
}

contract UniswapV2Swapper is Swapper {
  constructor(address _protocol) Swapper(_protocol) {}

  function swap(
    address token1,
    address token2,
    uint256 amountOutMin,
    uint256 amountIn
  ) public override returns (uint256 spent) {
    IERC20(token1).transferFrom(msg.sender, address(this), amountIn);
    IERC20(token1).approve(protocol, amountIn);
    address[] memory path = new address[](2);
    path[0] = token1;
    path[1] = token2;
    uint[] memory amounts = IUniRouter(protocol).swapExactTokensForTokens(
      amountIn,
      amountOutMin,
      path,
      msg.sender,
      block.timestamp
    );
    spent = amounts[0];
  }

  // Must be authorized.
  // Swaps an ERC20 token for the native token and sends it back.
  // amount is in requested tokens.
  // spent is in ERC20 tokens
  function swapToNative(
    address token,
    uint256 requestedAmount,
    uint256 amountInMax
  ) public override returns (uint256 spent) {
    IERC20(token).transferFrom(msg.sender, address(this), amountInMax);
    IERC20(token).approve(protocol, amountInMax);
    address[] memory path = new address[](2);
    path[0] = token;
    path[1] = IUniRouter(protocol).WETH();
    uint[] memory amounts = IUniRouter(protocol).swapTokensForExactETH(
      requestedAmount,
      amountInMax,
      path,
      msg.sender,
      block.timestamp
    );
    spent = amounts[0];
    IERC20(token).transfer(
      msg.sender,
      amountInMax - spent
    );

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
pragma solidity ^0.8.13;

abstract contract Swapper {
  address protocol;

  constructor(address _protocol) {
    protocol = _protocol;
  }

  // Must be authorized.
  // Swaps an ERC20 token for the native token and sends it back.
  // amount is in requested tokens.
  // spent is in ERC20 tokens
  function swapToNative(
    address token,
    uint256 requestedAmount,
    uint256 amountInMax
  ) public virtual returns (uint256 spent) {}

  function swap(
    address token1,
    address token2,
    uint256 amountOutMin,
    uint256 amountIn
  ) public virtual returns (uint256 spent) {}
}