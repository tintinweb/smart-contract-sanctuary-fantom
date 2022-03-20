/**
 *Submitted for verification at FtmScan.com on 2022-03-20
*/

pragma solidity >=0.8.0;


interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IOracle {
   function getPrice() external view returns (int256);
}

/// @notice Gets price of a token in USD, based on the median of exchanges, balancer-like and not

contract TokenOracle {

  using SafeMath for uint256;

  struct Exchange {
    address _router;
    bool _isBalancerLike;
  }

  IERC20 private token;
  address public token_addr;
  IERC20 private wftm = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
  address public wftm_addr = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
  IERC20 private stable;
  address public stable_addr;

  address public treasury;

  address public monolith_lp;
  address public spLP;

  address public monolith_oracle;
  address public wftm_oracle;
  address public splp_oracle;

  constructor(
    address _token,
    //0x8d11ec38a3eb5e956b052f67da8bdc9bef8abf3e
    address _pair,
    //0x8d11ec38a3eb5e956b052f67da8bdc9bef8abf3e
    address _stable,
    address _treasury,
    address _monolith,
    address _spLP,
    address _monolithOracle,
    address _wftmOracle,
    address _spOracle
  ) {
    token = IERC20(_token);
    token_addr = _token;
    wftm = IERC20(_pair);
    wftm_addr = _pair;
    stable = IERC20(_stable);
    stable_addr = _stable;
    treasury = _treasury;
    monolith_lp = _monolith;
    spLP = _spLP;
    // 0x1d653Aa9E99353B4066B28b48E7732cB4476C457
    monolith_oracle = _monolithOracle;
    // 0xf4766552D15AE4d256Ad41B6cf2933482B0680dc
    wftm_oracle = _wftmOracle;
    // 0x01884c8fba9e2c510093d2af308e7a8ba7060b8f
    splp_oracle = _spOracle;
  }

//62.295876
  function getPrice() public view returns(uint256[] memory) {
    Exchange[] memory exchanges;
    exchanges = new Exchange[](1);
    exchanges[0] = Exchange(
      0xF491e7B69E4244ad4002BC14e878a34207E38c29,
      false
     );
    for (uint64 i = 0; i < exchanges.length; i++) {
      if (exchanges[i]._isBalancerLike) {
        // see what paraswap does
      } else {
        address[] memory _path;
        _path = new address[](2);
        _path[0] = wftm_addr;
        _path[1] = token_addr;
        uint256[] memory _price = IUniswapV2Router02(exchanges[i]._router).getAmountsOut(
            10 ** token.decimals(),
            _path
        );
        return _price;
      }
    }
  }

  function getBacking() public view returns(uint256) {
    // MONOLTIH PRICE CALC
    uint256 monolith_balance = IERC20(monolith_lp).balanceOf(treasury).div(IERC20(monolith_lp).decimals());
    uint256 monolith_price = uint256(IOracle(monolith_oracle).getPrice());
    // DAI PRICE CALC
    uint256 dai_balance = IERC20(stable_addr).balanceOf(treasury).div(IERC20(spLP).decimals());
    // wFTM PRICE CALC
    // Oracle Address: 0xf4766552D15AE4d256Ad41B6cf2933482B0680dc
    uint256 wftm_balance = wftm.balanceOf(treasury).div(IERC20(spLP).decimals());
    uint256 wftm_price = uint256(IOracle(wftm_oracle).getPrice());
    // fBEETS PRICE CALC

    // spLP PRICE CALC
    // Oracle Address: https://ftmscan.com/address/0x01884c8fba9e2c510093d2af308e7a8ba7060b8f
    uint256 sp_balance = IERC20(spLP).balanceOf(treasury).div(IERC20(spLP).decimals());
    uint256 sp_price = uint256(IOracle(splp_oracle).getPrice());

    uint256 balance = (
        (monolith_balance.mul(monolith_price)) +
        dai_balance +
        (wftm_balance.mul(wftm_price)) +
        (sp_balance.mul(sp_price))
      );

    uint256 _backing = (balance.div(token.totalSupply()));
    return _backing;
  }


    function getMono() public view returns(uint256) {
      // MONOLTIH PRICE CALC
      uint256 monolith_balance = IERC20(monolith_lp).balanceOf(treasury).div(IERC20(monolith_lp).decimals());
      uint256 monolith_price = uint256(IOracle(monolith_oracle).getPrice());

      uint256 _balance = (
          (monolith_balance.mul(monolith_price))
        );

      return _balance;
    }

    function getDai() public view returns(uint256) {
      uint256 dai_balance = IERC20(stable_addr).balanceOf(treasury).div(IERC20(spLP).decimals());
      return dai_balance;
    }

    function getWFTM() public view returns(uint256) {
      uint256 wftm_balance = wftm.balanceOf(treasury).div(IERC20(spLP).decimals());
      uint256 wftm_price = uint256(IOracle(wftm_oracle).getPrice());

      uint256 _balance = (
          (wftm_balance.mul(wftm_price))
        );

      return _balance;
    }

    function getSP() public view returns(uint256) {
      uint256 sp_balance = IERC20(spLP).balanceOf(treasury).div(IERC20(spLP).decimals());
      uint256 sp_price = uint256(IOracle(splp_oracle).getPrice());

      uint256 _balance = (
          (sp_balance.mul(sp_price))
        );

      return _balance;
    }
}