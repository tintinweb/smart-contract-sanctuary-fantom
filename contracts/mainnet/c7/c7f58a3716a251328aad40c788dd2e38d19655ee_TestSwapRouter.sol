/**
 *Submitted for verification at FtmScan.com on 2022-02-07
*/

// File: interfaces/ITestSwapRouter.sol


pragma solidity ^0.8.6;

interface ITestSwapRouter {
    function factory() external view returns (address);

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

    function math(
        int256 a,
        int256 b,
        uint256 x,
        uint256 y
    )
        external
        returns (
            int256 a1,
            int256 a2,
            int256 a3,
            int256 a4
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

    function exchange(
        address tokenA,
        address tokenB,
        uint256 amountAIn,
        uint256 amountBIn,
        uint256 amountOutMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amount0Out, uint256 amount1Out);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: @openzeppelin/contracts/utils/math/SignedSafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// File: interfaces/ITestSwapFactory.sol


pragma solidity ^0.8.6;

interface ITestSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function swapFeeBps() external view returns (uint256);

    function protocolFeeBps() external view returns (uint256);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function changeSwapFee(uint256 newFeeBps) external;

    function changeProtocolFee(uint256 newFeeBps) external;
}

// File: @openzeppelin/contracts/utils/math/SafeCast.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// File: interfaces/ITestSwapPair.sol


pragma solidity ^0.8.6;


interface ITestSwapPair is IERC20Upgradeable {
    function blockTimestampLast() external returns (uint256);

    function price0CumulativeLast() external returns (uint256);

    function price1CumulativeLast() external returns (uint256);

    function initialize(address _token0, address _token1) external;

    function calcAddLiquidity(uint256 amount0, uint256 amount1) external view returns (uint256 liquidity);

    function addLiquidity(
        uint256 amount0,
        uint256 amount1,
        uint256 minLiquidity,
        address to
    ) external returns (uint256 liquidity);

    function removeLiquidity(uint256 lp, address to) external returns (uint256 amount0, uint256 amount1);

    function getReserves()
        external
        view
        returns (
            uint256 reserve0,
            uint256 reserve1,
            uint256 blockTimestampLast
        );

    function exchange(
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) external;

    function sync() external;
}

// File: libraries/TestSwapLibrary.sol


pragma solidity ^0.8.6;






library TestSwapLibrary {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    /**
     * @dev sorts the tokens to order the same as the pair
     * @param tokenA The address for tokenA
     * @param tokenB the address for tokenB
     * @return token0 The address for the first token in the pair
     * @return token1 The address for the first token in the pair
     */
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "StableSwapLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "StableSwapLibrary: ZERO_ADDRESS");
    }

    /**
     * @dev A fuction to test the math with the output being every interation of the output to compair.
     * This can be taken out before being deployed
     * @param amountAIn The given amount for tokenA
     * @param amountBIn The given amount for tokenB
     * @param reserve0 The reserve for tokenA
     * @param reserve1 The reserve for tokenB
     * @return next1 Interaction 1
     * @return next2 Interaction 2
     * @return next3 Interaction 3
     * @return next4 Interaction 4
     */
    function testStableMath(
        int256 amountAIn,
        int256 amountBIn,
        uint256 reserve0,
        uint256 reserve1
    )
        internal
        pure
        returns (
            int256 next1,
            int256 next2,
            int256 next3,
            int256 next4
        )
    {
        int256 top;
        int256 bottom;
        (int256 a, int256 x, int256 y) = amountAIn > 0
            ? (amountAIn, SafeCast.toInt256(reserve0), SafeCast.toInt256(reserve1))
            : (amountBIn, SafeCast.toInt256(reserve1), SafeCast.toInt256(reserve0));

        (top, bottom) = stableSwapMath(a, a, x, y);
        next1 = a.sub(top.div(bottom));

        (top, bottom) = stableSwapMath(a, next1, x, y);
        next2 = next1.sub(top.div(bottom));

        (top, bottom) = stableSwapMath(a, next2, x, y);
        next3 = next2.sub(top.div(bottom));

        (top, bottom) = stableSwapMath(a, next3, x, y);
        next4 = next3.sub(top.div(bottom));
    }

    /**
     * @dev Outputs the top and bottom
     * @param a The current interaction of the output
     * @param a1 The first interaction of the output
     * @param x The reserve for a
     * @param y the reserve for b
     * @return top The output for the numerator
     * @return bottom The output for the denominator
     */
    function stableSwapMath(
        int256 a,
        int256 a1,
        int256 x,
        int256 y
    ) internal pure returns (int256 top, int256 bottom) {
        top =
            (-y - a) *
            a1**3 +
            (3 * x * y + 3 * a * x) *
            a1**2 +
            (-3 * x**2 * y - 3 * a**2 * y - 3 * a * y**2 - y**3 - 3 * a * x**2 - a**3) *
            a1 +
            (x**3 * y + 3 * a**2 * x * y + 3 * a * x * y**2 + x * y**3 + a * x**3 + a**3 * x - (x * y * (x**2 + y**2)));

        bottom =
            3 *
            (-y - a) *
            a1**2 +
            2 *
            (3 * x * y + 3 * a * x) *
            a1 +
            (-3 * x**2 * y - 3 * a**2 * y - 3 * a * y**2 - y**3 - 3 * a * x**2 - a**3);
    }

    /**
     * @dev To find the pair address for a pair
     * @param factory The Address of the factory
     * @param tokenA The address of tokenA
     * @param tokenB The address of tokenB
     * @return pair The address of the pair
     */
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        pair = ITestSwapFactory(factory).getPair(tokenA, tokenB);
    }

    /**
     * @dev This function will get the reserves for the tokens given
     * @param factory The Address of the factory
     * @param tokenA The address of tokenA
     * @param tokenB The address of tokenB
     * @return reserveA The reserve for tokenA
     * @return reserveB The reserve for tokenB
     */
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = ITestSwapPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        int256 amountA,
        int256 reserveA,
        int256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "StableSwapLibrary: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "StableSwapLibrary: INSUFFICIENT_LIQUIDITY");
        int256 top;
        int256 bottom;
        int256 next = amountA;

        for (uint256 c = 0; c < 4; c++) {
            (top, bottom) = stableSwapMath(amountA, next, reserveA, reserveB);
            next = next.sub(top.div(bottom));
        }
        amountB = SafeCast.toUint256(next);
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: TestSwapRouter.sol


pragma solidity ^0.8.6;








contract TestSwapRouter is ITestSwapRouter {
    address public immutable override factory;

    modifier expirey(uint256 deadline) {
        require(deadline >= block.timestamp, "StableSwapRouter: EXPIRED");
        _;
    }

    constructor(address _factory) {
        factory = _factory;
    }

    /**
     * @dev Calculate liquidity to be added to the user
     * @param tokenA tokenA address to get pair from the factory
     * @param tokenB tokenB address to get pair from the factory
     * @param amountADesired Amount desired for tokenA
     * @param amountBDesired Amount desired for tokenB
     * @param amountAMin Min return amount for tokenA
     * @param amountBMin Min return amount for tokenB
     * @return amountA Amount used of tokenA
     * @return amountB Amount used of tokenB
     */
    function calcLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) private returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        if (ITestSwapFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            ITestSwapFactory(factory).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = TestSwapLibrary.getReserves(factory, tokenA, tokenB);

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "StableSwapRouter: INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "StableSwapRouter: INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    /**
     * @dev passes values to the functions for add liquidity
     * @param tokenA tokenA address to get pair from the factory
     * @param tokenB tokenB address to get pair from the factory
     * @param amountADesired Amount desired for tokenA
     * @param amountBDesired Amount desired for tokenB
     * @param amountAMin Min return amount for tokenA
     * @param amountBMin Min return amount for tokenB
     * @param to The address to send the liquidity to
     * @param deadline The expire time
     * @return amountA Amount used of tokenA
     * @return amountB Amount used of tokenB
     * @return liquidity Amount of liquidity added to the to address
     */
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
        override
        expirey(deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB) = calcLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = TestSwapLibrary.pairFor(factory, tokenA, tokenB);

        uint256 minL = ITestSwapPair(pair).calcAddLiquidity(amountA, amountB);
        liquidity = ITestSwapPair(pair).addLiquidity(amountA, amountB, minL, to);
    }

    /**
     * @dev test function to test the math
     * @param a amount a test value
     * @param b amount b test value
     * @param x amount x test value
     * @param y amount y test value
     * @return a1 Interaction 1
     * @return a2 Interaction 2
     * @return a3 Interaction 3
     * @return a4 Interaction 4
     */
    function math(
        int256 a,
        int256 b,
        uint256 x,
        uint256 y
    )
        public
        pure
        override
        returns (
            int256 a1,
            int256 a2,
            int256 a3,
            int256 a4
        )
    {
        (a1, a2, a3, a4) = TestSwapLibrary.testStableMath(a, b, x, y);
    }

    /**
     * @dev Remove liquidity from the pool
     * @param tokenA tokenA address to get pair from the factory
     * @param tokenB tokenB address to get pair from the factory
     * @param liquidity Liquidity passed to the router
     * @param amountAMin Min return amount for tokenA
     * @param amountBMin Min return amount for tokenB
     * @param to The address to send the tokens to
     * @param deadline The expire time
     * @return amountA Amount of tokenA returned
     * @return amountB Amount of tokenB returned
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public override expirey(deadline) returns (uint256 amountA, uint256 amountB) {
        address pair = TestSwapLibrary.pairFor(factory, tokenA, tokenB);
        IERC20Upgradeable(pair).transferFrom(msg.sender, address(this), liquidity);

        (uint256 amount0, uint256 amount1) = ITestSwapPair(pair).removeLiquidity(liquidity, to);
        (address token0, ) = TestSwapLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, "StableSwapRouter: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "StableSwapRouter: INSUFFICIENT_B_AMOUNT");
    }

    /**
     * @dev
     * @param tokenA tokenA address to get pair from the factory
     * @param tokenB tokenB address to get pair from the factory
     * @param amountAIn Amount in to tokenA
     * @param amountBIn Amount in of tokenB
     * @param amountOutMin Min return amount
     * @param to The address to send the exchanged tokens to
     * @param deadline The expire time
     * @return amount0Out The exchange return of tokenA
     * @return amount1Out The exchange return of tokenB
     */
    function exchange(
        address tokenA,
        address tokenB,
        uint256 amountAIn,
        uint256 amountBIn,
        uint256 amountOutMin,
        address to,
        uint256 deadline
    ) external override expirey(deadline) returns (uint256 amount0Out, uint256 amount1Out) {
        (address token0, address token1) = TestSwapLibrary.sortTokens(tokenA, tokenB);
        (uint256 reserveA, uint256 reserveB) = TestSwapLibrary.getReserves(factory, token0, token1);
        (amountAIn, amountBIn) = tokenA == token0 ? (amountAIn, amountBIn) : (amountBIn, amountAIn);

        if (amountAIn > 0) {
            amount1Out = 0;
            amount0Out = quote(
                amountAIn - ((amountAIn * ITestSwapFactory(factory).swapFeeBps()) / 10000),
                reserveA,
                reserveB
            );
        } else {
            amount0Out = 0;
            amount1Out = quote(
                amountBIn - ((amountBIn * ITestSwapFactory(factory).swapFeeBps()) / 10000),
                reserveB,
                reserveA
            );
        }

        require((amount0Out + amount1Out) >= amountOutMin, "StableSwapRouter: INSUFFICIENT_AMOUNT_OUT");
        IERC20Upgradeable(token0).transferFrom(msg.sender, address(this), amountAIn);
        IERC20Upgradeable(token1).transferFrom(msg.sender, address(this), amountBIn);

        IERC20Upgradeable(token0).approve(TestSwapLibrary.pairFor(factory, token0, token1), amountAIn);
        IERC20Upgradeable(token1).approve(TestSwapLibrary.pairFor(factory, token0, token1), amountBIn);

        ITestSwapPair(TestSwapLibrary.pairFor(factory, token0, token1)).exchange(
            amountAIn,
            amountBIn,
            amount0Out,
            amount1Out,
            to
        );
    }

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) public pure override returns (uint256 amountB) {
        return
            TestSwapLibrary.quote(
                SafeCast.toInt256(amountA),
                SafeCast.toInt256(reserveA),
                SafeCast.toInt256(reserveB)
            );
    }
}