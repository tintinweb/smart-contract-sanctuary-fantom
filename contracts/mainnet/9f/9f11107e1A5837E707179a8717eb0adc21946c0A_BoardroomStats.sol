// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../Interfaces/IBoardroom02.sol';
import '../util/PriceCalculator.sol';
import '../Interfaces/ITreasury.sol';
import '../Interfaces/IBoardroomStats.sol';

/*
 * @notice Contract to compute TVL and APR of boardrooms
 * @dev This assumes only two types of boardrooms - share & cash-stable boardroom.
 * Anything else will need a new contract.
 */
contract BoardroomStats is IBoardroomStats, PriceCalculator {
	using SafeMath for uint256;

	ITreasury public treasury;
	IPancakeRouter02 public router;

	address[] public cashToStablePath;
	address[] public shareToStablePath;
	address[] public cashLP0ToStable;
	address[] public cashLP1ToStable;

	constructor(
		ITreasury _treasury,
		IPancakeRouter02 _router,
		address[] memory _cashToStablePath,
		address[] memory _shareToStablePath,
		address[] memory _cashLP0ToStable,
		address[] memory _cashLP1ToStable
	) {
		treasury = _treasury;
		router = _router;
		cashToStablePath = _cashToStablePath;
		shareToStablePath = _shareToStablePath;
		cashLP0ToStable = _cashLP0ToStable;
		cashLP1ToStable = _cashLP1ToStable;
	}

	function APR(IBoardroom02 _boardroom)
		external
		view
		override
		returns (uint256)
	{
		(bool success, uint256 latestSnapshotIndex) = _tryLatestSnapshotIndex(
			_boardroom
		);
		if (!success) return 0;

		uint256 prevCRPS = 0;
		uint256 prevSRPS = 0;

		if (latestSnapshotIndex >= 1) {
			prevCRPS = _boardroom
				.boardHistory(latestSnapshotIndex - 1)
				.cashRewardPerShare;
			prevSRPS = _boardroom
				.boardHistory(latestSnapshotIndex - 1)
				.shareRewardPerShare;
		}

		uint256 epochCRPS = _boardroom
			.boardHistory(latestSnapshotIndex)
			.cashRewardPerShare
			.sub(prevCRPS);

		uint256 epochSRPS = _boardroom
			.boardHistory(latestSnapshotIndex)
			.shareRewardPerShare
			.sub(prevSRPS);

		// 31536000 = seconds in a year
		return
			(epochCRPS.mul(_getTokenPrice(router, cashToStablePath)) +
				epochSRPS.mul(_getTokenPrice(router, shareToStablePath)))
				.mul(31536000)
				.div(treasury.PERIOD())
				.div(stakedTokenPrice(_boardroom));
	}

	function TVL(IBoardroom02 _boardroom)
		external
		view
		override
		returns (uint256)
	{
		return
			_boardroom.totalSupply().mul(stakedTokenPrice(_boardroom)).div(
				1e18
			);
	}

	function stakedTokenPrice(IBoardroom02 _boardroom)
		public
		view
		override
		returns (uint256)
	{
		if (address(_boardroom.wantToken()) == address(_boardroom.share()))
			return _getTokenPrice(router, shareToStablePath);
		else
			return
				_getLPTokenPrice(
					router,
					cashLP0ToStable,
					cashLP1ToStable,
					_boardroom.wantToken()
				);
	}

	function _tryLatestSnapshotIndex(IBoardroom02 _boardroom)
		internal
		view
		returns (bool, uint256)
	{
		(bool success, bytes memory returnData) = address(_boardroom)
			.staticcall(
				abi.encodeWithSelector(_boardroom.latestSnapshotIndex.selector)
			);
		if (success) {
			return (true, abi.decode(returnData, (uint256)));
		} else {
			return (false, 0);
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../Interfaces/IPancakeRouter02.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

abstract contract PriceCalculator {
	function _getTokenPrice(
		IPancakeRouter02 router,
		address[] memory tokenToStable
	) internal view virtual returns (uint256) {
		//special case where token is stable
		if (tokenToStable.length == 1) {
			return 1e18;
		}

		uint256[] memory amounts = router.getAmountsOut(1e14, tokenToStable);
		uint256 priceMultiplier = uint256(
			10 **
				(uint256(18) -
					(
						IERC20Metadata(tokenToStable[tokenToStable.length - 1])
							.decimals()
					))
		);
		return amounts[amounts.length - 1] * 1e4 * priceMultiplier;
	}

	function _getLPTokenPrice(
		IPancakeRouter02 router,
		address[] memory token0ToStable,
		address[] memory token1ToStable,
		IERC20 lpToken
	) internal view virtual returns (uint256) {
		uint256 token0InPool = IERC20(token0ToStable[0]).balanceOf(
			address(lpToken)
		);
		uint256 token1InPool = IERC20(token1ToStable[0]).balanceOf(
			address(lpToken)
		);

		uint256 token0BalanceMultiplier = uint256(
			10**(uint256(18) - (IERC20Metadata(token0ToStable[0]).decimals()))
		);

		uint256 token1BalanceMultiplier = uint256(
			10**(uint256(18) - (IERC20Metadata(token1ToStable[0]).decimals()))
		);

		uint256 totalPriceOfPool = token0InPool *
			token0BalanceMultiplier *
			(_getTokenPrice(router, token0ToStable)) +
			token1InPool *
			token1BalanceMultiplier *
			(_getTokenPrice(router, token1ToStable));

		return totalPriceOfPool / (lpToken.totalSupply());
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ITreasury {
	function PERIOD() external view returns (uint256);

	function epoch() external view returns (uint256);

	function nextEpochPoint() external view returns (uint256);

	function getDollarPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {
	function removeLiquidityETHSupportingFeeOnTransferTokens(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountETH);

	function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountETH);

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;

	function swapExactETHForTokensSupportingFeeOnTransferTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable;

	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IPancakeRouter01 {
	function factory() external pure returns (address);

	function WETH() external pure returns (address);

	function addLiquidity(
		address tokenA,
		address tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	)
		external
		returns (
			uint256 amountA,
			uint256 amountB,
			uint256 liquidity
		);

	function addLiquidityETH(
		address token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	)
		external
		payable
		returns (
			uint256 amountToken,
			uint256 amountETH,
			uint256 liquidity
		);

	function removeLiquidity(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB);

	function removeLiquidityETH(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountToken, uint256 amountETH);

	function removeLiquidityWithPermit(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountA, uint256 amountB);

	function removeLiquidityETHWithPermit(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountToken, uint256 amountETH);

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapTokensForExactTokens(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactETHForTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function swapTokensForExactETH(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactTokensForETH(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapETHForExactTokens(
		uint256 amountOut,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function quote(
		uint256 amountA,
		uint256 reserveA,
		uint256 reserveB
	) external pure returns (uint256 amountB);

	function getAmountOut(
		uint256 amountIn,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountOut);

	function getAmountIn(
		uint256 amountOut,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountIn);

	function getAmountsOut(uint256 amountIn, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);

	function getAmountsIn(uint256 amountOut, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);
}

pragma solidity 0.8.4;

import './IBoardroom02.sol';

interface IBoardroomStats {
	function APR(IBoardroom02 _boardroom) external view returns (uint256);

	function TVL(IBoardroom02 _boardroom) external view returns (uint256);

	function stakedTokenPrice(IBoardroom02 _boardroom)
		external
		view
		returns (uint256);
}

pragma solidity 0.8.4;

import './IBoardroom.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IBoardroom02 is IBoardroom {
	struct BoardSnapshot {
		uint256 time;
		uint256 cashRewardReceived;
		uint256 cashRewardPerShare;
		uint256 shareRewardReceived;
		uint256 shareRewardPerShare;
	}

	function wantToken() external view returns (IERC20);

	function cash() external view returns (IERC20);

	function share() external view returns (IERC20);

	function totalSupply() external view returns (uint256);

	function latestSnapshotIndex() external view returns (uint256);

	function boardHistory(uint256 _index)
		external
		view
		returns (BoardSnapshot memory);
}

pragma solidity 0.8.4;

interface IBoardroom {
	function balanceOf(address _director) external view returns (uint256);

	function earned(address _director) external view returns (uint256, uint256);

	function canWithdraw(address _director) external view returns (bool);

	function canClaimReward(address _director) external view returns (bool);

	function setOperator(address _operator) external;

	function setLockUp(
		uint256 _withdrawLockupEpochs,
		uint256 _rewardLockupEpochs
	) external;

	function stake(uint256 _amount) external;

	function withdraw(uint256 _amount) external;

	function exit() external;

	function claimReward() external;

	function allocateSeigniorage(uint256 _cashReward, uint256 _shareReward)
		external;

	function governanceRecoverUnsupported(
		address _token,
		uint256 _amount,
		address _to
	) external;

	function APR() external pure returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}