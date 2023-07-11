// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {UnsafeMath} from '../UnsafeMath.sol';

using UnsafeMath for int256;

type I256 is int256;

using {
    add as +,
    sub as -,
    mul as *,
    div as /,
    mod as %,
    neq as !=,
    eq as ==,
    lt as <,
    lte as <=,
    gt as >,
    gte as >=,
    and as &,
    or as |,
    xor as ^,
    not as ~
} for I256 global;

function add(I256 _i256, I256 _addend) pure returns (I256) {
    return I256.wrap(I256.unwrap(_i256).add(I256.unwrap(_addend)));
}

function sub(I256 _i256, I256 _subtrahend) pure returns (I256) {
    return I256.wrap(I256.unwrap(_i256).sub(I256.unwrap(_subtrahend)));
}

function mul(I256 _i256, I256 _multiplier) pure returns (I256) {
    return I256.wrap(I256.unwrap(_i256).mul(I256.unwrap(_multiplier)));
}

function div(I256 _i256, I256 _divisor) pure returns (I256) {
    return I256.wrap(I256.unwrap(_i256).div(I256.unwrap(_divisor)));
}

function mod(I256 _i256, I256 _divisor) pure returns (I256) {
    return I256.wrap(I256.unwrap(_i256).mod(I256.unwrap(_divisor)));
}

function and(I256 _i256, I256 _mask) pure returns (I256) {
    return I256.wrap(I256.unwrap(_i256) & I256.unwrap(_mask));
}

function or(I256 _i256, I256 _mask) pure returns (I256) {
    return I256.wrap(I256.unwrap(_i256) | I256.unwrap(_mask));
}

function xor(I256 _i256, I256 _mask) pure returns (I256) {
    return I256.wrap(I256.unwrap(_i256) ^ I256.unwrap(_mask));
}

function not(I256 _i256) pure returns (I256) {
    return I256.wrap(~I256.unwrap(_i256));
}

function neq(I256 _i256, I256 _bounds) pure returns (bool) {
    return I256.unwrap(_i256) != I256.unwrap(_bounds);
}

function eq(I256 _i256, I256 _bounds) pure returns (bool) {
    return I256.unwrap(_i256) == I256.unwrap(_bounds);
}

function lt(I256 _i256, I256 _bounds) pure returns (bool) {
    return I256.unwrap(_i256) < I256.unwrap(_bounds);
}

function lte(I256 _i256, I256 _bounds) pure returns (bool) {
    return I256.unwrap(_i256) <= I256.unwrap(_bounds);
}

function gt(I256 _i256, I256 _bounds) pure returns (bool) {
    return I256.unwrap(_i256) > I256.unwrap(_bounds);
}

function gte(I256 _i256, I256 _bounds) pure returns (bool) {
    return I256.unwrap(_i256) >= I256.unwrap(_bounds);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {UnsafeMath} from '../UnsafeMath.sol';

using UnsafeMath for uint256;

type U256 is uint256;

using {
    add as +,
    sub as -,
    mul as *,
    div as /,
    mod as %,
    neq as !=,
    eq as ==,
    lt as <,
    lte as <=,
    gt as >,
    gte as >=,
    and as &,
    or as |,
    xor as ^,
    not as ~
} for U256 global;

function add(U256 _u256, U256 _addend) pure returns (U256) {
    return U256.wrap(U256.unwrap(_u256).add(U256.unwrap(_addend)));
}

function sub(U256 _u256, U256 _subtrahend) pure returns (U256) {
    return U256.wrap(U256.unwrap(_u256).sub(U256.unwrap(_subtrahend)));
}

function mul(U256 _u256, U256 _multiplier) pure returns (U256) {
    return U256.wrap(U256.unwrap(_u256).mul(U256.unwrap(_multiplier)));
}

function div(U256 _u256, U256 _divisor) pure returns (U256) {
    return U256.wrap(U256.unwrap(_u256).div(U256.unwrap(_divisor)));
}

function mod(U256 _u256, U256 _divisor) pure returns (U256) {
    return U256.wrap(U256.unwrap(_u256).mod(U256.unwrap(_divisor)));
}

function and(U256 _u256, U256 _mask) pure returns (U256) {
    return U256.wrap(U256.unwrap(_u256) & U256.unwrap(_mask));
}

function or(U256 _u256, U256 _mask) pure returns (U256) {
    return U256.wrap(U256.unwrap(_u256) | U256.unwrap(_mask));
}

function xor(U256 _u256, U256 _mask) pure returns (U256) {
    return U256.wrap(U256.unwrap(_u256) ^ U256.unwrap(_mask));
}

function not(U256 _u256) pure returns (U256) {
    return U256.wrap(~U256.unwrap(_u256));
}

function neq(U256 _u256, U256 _bounds) pure returns (bool) {
    return U256.unwrap(_u256) != U256.unwrap(_bounds);
}

function eq(U256 _u256, U256 _bounds) pure returns (bool) {
    return U256.unwrap(_u256) == U256.unwrap(_bounds);
}

function lt(U256 _u256, U256 _bounds) pure returns (bool) {
    return U256.unwrap(_u256) < U256.unwrap(_bounds);
}

function lte(U256 _u256, U256 _bounds) pure returns (bool) {
    return U256.unwrap(_u256) <= U256.unwrap(_bounds);
}

function gt(U256 _u256, U256 _bounds) pure returns (bool) {
    return U256.unwrap(_u256) > U256.unwrap(_bounds);
}

function gte(U256 _u256, U256 _bounds) pure returns (bool) {
    return U256.unwrap(_u256) >= U256.unwrap(_bounds);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable func-name-mixedcase

import {I256} from './types/I256.sol';
import {U256} from './types/U256.sol';

library UnsafeMath {
    /*********************
     * uint256 ->
     *********************/

    /// @dev Returns the addition of two unsigned integers
    /// @param _uint256 The first unsigned integer
    /// @param _addend The second unsigned integer
    /// @return The addition of the two unsigned integers
    function add(uint256 _uint256, uint256 _addend) internal pure returns (uint256) {
        unchecked {
            return _uint256 + _addend;
        }
    }

    /// @dev Returns the subtraction of two unsigned integers
    /// @param _uint256 The first unsigned integer
    /// @param _subtrahend The second unsigned integer
    /// @return The subtraction of the two unsigned integers
    function sub(uint256 _uint256, uint256 _subtrahend) internal pure returns (uint256) {
        unchecked {
            return _uint256 - _subtrahend;
        }
    }

    /// @dev Increments an unsigned integer by one
    /// @param _uint256 The unsigned integer
    /// @return The incremented unsigned integer
    function inc(uint256 _uint256) internal pure returns (uint256) {
        unchecked {
            return ++_uint256;
        }
    }

    /// @dev Decrements an unsigned integer by one
    /// @param _uint256 The unsigned integer
    /// @return The decremented unsigned integer
    function dec(uint256 _uint256) internal pure returns (uint256) {
        unchecked {
            return --_uint256;
        }
    }

    /// @dev Returns the multiplication of two unsigned integers
    /// @param _uint256 The first unsigned integer
    /// @param _multiplier The second unsigned integer
    /// @return The multiplication of the two unsigned integers
    function mul(uint256 _uint256, uint256 _multiplier) internal pure returns (uint256) {
        unchecked {
            return _uint256 * _multiplier;
        }
    }

    /// @dev Returns the exponentiation of two unsigned integers
    /// @param _uint256 The first unsigned integer
    /// @param _exponent The second unsigned integer
    /// @return The exponentiation of the two unsigned integers
    function exp(uint256 _uint256, uint256 _exponent) internal pure returns (uint256) {
        uint256 result;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := exp(_uint256, _exponent)
        }
        return result;
    }

    /// @dev Returns the division of two unsigned integers
    /// @param _uint256 The first unsigned integer
    /// @param _divisor The second unsigned integer
    /// @return The division of the two unsigned integers
    function div(uint256 _uint256, uint256 _divisor) internal pure returns (uint256) {
        uint256 result;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := div(_uint256, _divisor)
        }
        return result;
    }

    /// @dev Returns the remainder of the division of two unsigned integers
    /// @param _uint256 The first unsigned integer
    /// @param _divisor The second unsigned integer
    /// @return The remainder of the division of the two unsigned integers
    function mod(uint256 _uint256, uint256 _divisor) internal pure returns (uint256) {
        uint256 result;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := mod(_uint256, _divisor)
        }
        return result;
    }

    /*********************
     * int256 ->
     *********************/

    /// @dev Returns the addition of two signed integers
    /// @param _int256 The first signed integer
    /// @param _addend The second signed integer
    /// @return The addition of the two signed integers
    function add(int256 _int256, int256 _addend) internal pure returns (int256) {
        unchecked {
            return _int256 + _addend;
        }
    }

    /// @dev Returns the subtraction of two signed integers
    /// @param _int256 The first signed integer
    /// @param _subtrahend The second signed integer
    /// @return The subtraction of the two signed integers
    function sub(int256 _int256, int256 _subtrahend) internal pure returns (int256) {
        unchecked {
            return _int256 - _subtrahend;
        }
    }

    /// @dev Increments a signed integer by one
    /// @param _int256 The signed integer
    /// @return The incremented signed integer
    function inc(int256 _int256) internal pure returns (int256) {
        unchecked {
            return ++_int256;
        }
    }

    /// @dev Decrements a signed integer by one
    /// @param _int256 The signed integer
    /// @return The decremented signed integer
    function dec(int256 _int256) internal pure returns (int256) {
        unchecked {
            return --_int256;
        }
    }

    /// @dev Returns the multiplication of two signed integers
    /// @param _int256 The first signed integer
    /// @param _multiplier The second signed integer
    /// @return The multiplication of the two signed integers
    function mul(int256 _int256, int256 _multiplier) internal pure returns (int256) {
        unchecked {
            return _int256 * _multiplier;
        }
    }

    /// @dev Returns the division of two signed integers
    /// @param _int256 The first signed integer
    /// @param _divisor The second signed integer
    /// @return The division of the two signed integers
    function div(int256 _int256, int256 _divisor) internal pure returns (int256) {
        int256 result;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := sdiv(_int256, _divisor)
        }
        return result;
    }

    /// @dev Returns the remainder of the division of two signed integers
    /// @param _int256 The first signed integer
    /// @param _divisor The second signed integer
    /// @return The remainder of the division of the two signed integers
    function mod(int256 _int256, int256 _divisor) internal pure returns (int256) {
        int256 result;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := smod(_int256, _divisor)
        }
        return result;
    }

    /*********************
     * I256 ->
     *********************/

    /// @dev Wraps an int256 into an I256
    /// @param _i256 The int256 to wrap
    /// @return i256 The wrapped I256
    function asI256(int256 _i256) internal pure returns (I256 i256) {
        return I256.wrap(_i256);
    }

    /// @dev Wraps a uint256 into an I256
    /// @param _i256 The uint256 to wrap
    /// @return i256 The wrapped I256
    function asI256(uint256 _i256) internal pure returns (I256 i256) {
        return I256.wrap(int256(_i256));
    }

    /// @dev Converts an I256 to a signed int256
    /// @param _i256 The I256 to convert
    /// @return signed The signed int256
    function asInt256(I256 _i256) internal pure returns (int256 signed) {
        return I256.unwrap(_i256);
    }

    /// @dev Converts an I256 to a signed int248
    /// @param _i256 The I256 to convert
    /// @return signed The signed int248
    function asInt248(I256 _i256) internal pure returns (int248 signed) {
        return int248(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int240
    /// @param _i256 The I256 to convert
    /// @return signed The signed int240
    function asInt240(I256 _i256) internal pure returns (int240 signed) {
        return int240(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int232
    /// @param _i256 The I256 to convert
    /// @return signed The signed int232
    function asInt232(I256 _i256) internal pure returns (int232 signed) {
        return int232(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int224
    /// @param _i256 The I256 to convert
    /// @return signed The signed int224
    function asInt224(I256 _i256) internal pure returns (int224 signed) {
        return int224(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int216
    /// @param _i256 The I256 to convert
    /// @return signed The signed int216
    function asInt216(I256 _i256) internal pure returns (int216 signed) {
        return int216(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int208
    /// @param _i256 The I256 to convert
    /// @return signed The signed int208
    function asInt208(I256 _i256) internal pure returns (int208 signed) {
        return int208(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int200
    /// @param _i256 The I256 to convert
    /// @return signed The signed int200
    function asInt200(I256 _i256) internal pure returns (int200 signed) {
        return int200(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int192
    /// @param _i256 The I256 to convert
    /// @return signed The signed int192
    function asInt192(I256 _i256) internal pure returns (int192 signed) {
        return int192(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int184
    /// @param _i256 The I256 to convert
    /// @return signed The signed int184
    function asInt184(I256 _i256) internal pure returns (int184 signed) {
        return int184(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int176
    /// @param _i256 The I256 to convert
    /// @return signed The signed int176
    function asInt176(I256 _i256) internal pure returns (int176 signed) {
        return int176(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int168
    /// @param _i256 The I256 to convert
    /// @return signed The signed int168
    function asInt168(I256 _i256) internal pure returns (int168 signed) {
        return int168(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int160
    /// @param _i256 The I256 to convert
    /// @return signed The signed int160
    function asInt160(I256 _i256) internal pure returns (int160 signed) {
        return int160(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int152
    /// @param _i256 The I256 to convert
    /// @return signed The signed int152
    function asInt152(I256 _i256) internal pure returns (int152 signed) {
        return int152(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int144
    /// @param _i256 The I256 to convert
    /// @return signed The signed int144
    function asInt144(I256 _i256) internal pure returns (int144 signed) {
        return int144(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int136
    /// @param _i256 The I256 to convert
    /// @return signed The signed int136
    function asInt136(I256 _i256) internal pure returns (int136 signed) {
        return int136(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int128
    /// @param _i256 The I256 to convert
    /// @return signed The signed int128
    function asInt128(I256 _i256) internal pure returns (int128 signed) {
        return int128(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int120
    /// @param _i256 The I256 to convert
    /// @return signed The signed int120
    function asInt120(I256 _i256) internal pure returns (int120 signed) {
        return int120(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int112
    /// @param _i256 The I256 to convert
    /// @return signed The signed int112
    function asInt112(I256 _i256) internal pure returns (int112 signed) {
        return int112(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int104
    /// @param _i256 The I256 to convert
    /// @return signed The signed int104
    function asInt104(I256 _i256) internal pure returns (int104 signed) {
        return int104(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int96
    /// @param _i256 The I256 to convert
    /// @return signed The signed int96
    function asInt96(I256 _i256) internal pure returns (int96 signed) {
        return int96(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int88
    /// @param _i256 The I256 to convert
    /// @return signed The signed int88
    function asInt88(I256 _i256) internal pure returns (int88 signed) {
        return int88(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int80
    /// @param _i256 The I256 to convert
    /// @return signed The signed int80
    function asInt80(I256 _i256) internal pure returns (int80 signed) {
        return int80(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int72
    /// @param _i256 The I256 to convert
    /// @return signed The signed int72
    function asInt72(I256 _i256) internal pure returns (int72 signed) {
        return int72(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int64
    /// @param _i256 The I256 to convert
    /// @return signed The signed int64
    function asInt64(I256 _i256) internal pure returns (int64 signed) {
        return int64(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int56
    /// @param _i256 The I256 to convert
    /// @return signed The signed int56
    function asInt56(I256 _i256) internal pure returns (int56 signed) {
        return int56(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int48
    /// @param _i256 The I256 to convert
    /// @return signed The signed int48
    function asInt48(I256 _i256) internal pure returns (int48 signed) {
        return int48(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int40
    /// @param _i256 The I256 to convert
    /// @return signed The signed int40
    function asInt40(I256 _i256) internal pure returns (int40 signed) {
        return int40(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int32
    /// @param _i256 The I256 to convert
    /// @return signed The signed int32
    function asInt32(I256 _i256) internal pure returns (int32 signed) {
        return int32(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int24
    /// @param _i256 The I256 to convert
    /// @return signed The signed int24
    function asInt24(I256 _i256) internal pure returns (int24 signed) {
        return int24(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int16
    /// @param _i256 The I256 to convert
    /// @return signed The signed int16
    function asInt16(I256 _i256) internal pure returns (int16 signed) {
        return int16(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to a signed int8
    /// @param _i256 The I256 to convert
    /// @return signed The signed int8
    function asInt8(I256 _i256) internal pure returns (int8 signed) {
        return int8(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to an unsigned uint256
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint256
    function asUint256(I256 _i256) internal pure returns (uint256 unsigned) {
        return uint256(I256.unwrap(_i256));
    }

    /// @dev Converts an I256 to an unsigned uint248
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint248
    function asUint248(I256 _i256) internal pure returns (uint248 unsigned) {
        return uint248(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint240
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint240
    function asUint240(I256 _i256) internal pure returns (uint240 unsigned) {
        return uint240(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint232
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint232
    function asUint232(I256 _i256) internal pure returns (uint232 unsigned) {
        return uint232(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint224
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint224
    function asUint224(I256 _i256) internal pure returns (uint224 unsigned) {
        return uint224(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint216
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint216
    function asUint216(I256 _i256) internal pure returns (uint216 unsigned) {
        return uint216(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint208
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint208
    function asUint208(I256 _i256) internal pure returns (uint208 unsigned) {
        return uint208(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint200
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint200
    function asUint200(I256 _i256) internal pure returns (uint200 unsigned) {
        return uint200(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint192
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint192
    function asUint192(I256 _i256) internal pure returns (uint192 unsigned) {
        return uint192(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint184
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint184
    function asUint184(I256 _i256) internal pure returns (uint184 unsigned) {
        return uint184(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint176
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint176
    function asUint176(I256 _i256) internal pure returns (uint176 unsigned) {
        return uint176(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint168
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint168
    function asUint168(I256 _i256) internal pure returns (uint168 unsigned) {
        return uint168(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint160
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint160
    function asUint160(I256 _i256) internal pure returns (uint160 unsigned) {
        return uint160(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint152
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint152
    function asUint152(I256 _i256) internal pure returns (uint152 unsigned) {
        return uint152(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint144
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint144
    function asUint144(I256 _i256) internal pure returns (uint144 unsigned) {
        return uint144(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint136
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint136
    function asUint136(I256 _i256) internal pure returns (uint136 unsigned) {
        return uint136(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint128
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint128
    function asUint128(I256 _i256) internal pure returns (uint128 unsigned) {
        return uint128(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint120
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint120
    function asUint120(I256 _i256) internal pure returns (uint120 unsigned) {
        return uint120(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint112
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint112
    function asUint112(I256 _i256) internal pure returns (uint112 unsigned) {
        return uint112(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint104
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint104
    function asUint104(I256 _i256) internal pure returns (uint104 unsigned) {
        return uint104(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint96
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint96
    function asUint96(I256 _i256) internal pure returns (uint96 unsigned) {
        return uint96(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint88
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint88
    function asUint88(I256 _i256) internal pure returns (uint88 unsigned) {
        return uint88(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint80
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint80
    function asUint80(I256 _i256) internal pure returns (uint80 unsigned) {
        return uint80(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint72
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint72
    function asUint72(I256 _i256) internal pure returns (uint72 unsigned) {
        return uint72(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint64
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint64
    function asUint64(I256 _i256) internal pure returns (uint64 unsigned) {
        return uint64(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint56
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint56
    function asUint56(I256 _i256) internal pure returns (uint56 unsigned) {
        return uint56(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint48
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint48
    function asUint48(I256 _i256) internal pure returns (uint48 unsigned) {
        return uint48(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint40
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint40
    function asUint40(I256 _i256) internal pure returns (uint40 unsigned) {
        return uint40(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint32
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint32
    function asUint32(I256 _i256) internal pure returns (uint32 unsigned) {
        return uint32(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint24
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint24
    function asUint24(I256 _i256) internal pure returns (uint24 unsigned) {
        return uint24(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint16
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint16
    function asUint16(I256 _i256) internal pure returns (uint16 unsigned) {
        return uint16(uint256(I256.unwrap(_i256)));
    }

    /// @dev Converts an I256 to an unsigned uint8
    /// @param _i256 The I256 to convert
    /// @return unsigned The unsigned uint8
    function asUint8(I256 _i256) internal pure returns (uint8 unsigned) {
        return uint8(uint256(I256.unwrap(_i256)));
    }

    /// @dev Adds an int256 to an I256
    /// @param _i256 The I256 to add to
    /// @param _addend The int256 to add
    /// @return i256 The result of the addition
    function add(I256 _i256, int256 _addend) internal pure returns (I256 i256) {
        return I256.wrap(add(I256.unwrap(_i256), _addend));
    }

    /// @dev Subtracts an int256 from an I256
    /// @param _i256 The I256 to subtract from
    /// @param _subtrahend The int256 to subtract
    /// @return i256 The result of the subtraction
    function sub(I256 _i256, int256 _subtrahend) internal pure returns (I256 i256) {
        return I256.wrap(sub(I256.unwrap(_i256), _subtrahend));
    }

    /// @dev Increments an I256
    /// @param _i256 The I256 to increment
    /// @return i256 The result of the increment
    function inc(I256 _i256) internal pure returns (I256 i256) {
        return I256.wrap(inc(I256.unwrap(_i256)));
    }

    /// @dev Decrements an I256
    /// @param _i256 The I256 to decrement
    /// @return i256 The result of the decrement
    function dec(I256 _i256) internal pure returns (I256 i256) {
        return I256.wrap(dec(I256.unwrap(_i256)));
    }

    /// @dev Multiplies an I256 by an int256
    /// @param _i256 The I256 to multiply
    /// @param _multiplier The int256 to multiply by
    /// @return i256 The result of the multiplication
    function mul(I256 _i256, int256 _multiplier) internal pure returns (I256 i256) {
        return I256.wrap(mul(I256.unwrap(_i256), _multiplier));
    }

    /// @dev Divides an I256 by an int256
    /// @param _i256 The I256 to divide
    /// @param _divisor The int256 to divide by
    /// @return i256 The result of the division
    function div(I256 _i256, int256 _divisor) internal pure returns (I256 i256) {
        return I256.wrap(div(I256.unwrap(_i256), _divisor));
    }

    /// @dev Divides an I256 by an int256 and returns the remainder
    /// @param _i256 The I256 to divide
    /// @param _divisor The int256 to divide by
    /// @return i256 The remainder of the division
    function mod(I256 _i256, int256 _divisor) internal pure returns (I256 i256) {
        return I256.wrap(mod(I256.unwrap(_i256), _divisor));
    }

    /// @dev Logical and of an I256 and an int256
    /// @param _i256 The I256 to and
    /// @param _value The int256 to and with
    /// @return i256 The result of the and
    function and(I256 _i256, int256 _value) internal pure returns (I256 i256) {
        return I256.wrap(I256.unwrap(_i256) & _value);
    }

    /// @dev Logical or of an I256 and an int256
    /// @param _i256 The I256 to or
    /// @param _value The int256 to or with
    /// @return i256 The result of the or
    function or(I256 _i256, int256 _value) internal pure returns (I256 i256) {
        return I256.wrap(I256.unwrap(_i256) | _value);
    }

    /// @dev Logical xor of an I256 and an int256
    /// @param _i256 The I256 to xor
    /// @param _value The int256 to xor with
    /// @return i256 The result of the xor
    function xor(I256 _i256, int256 _value) internal pure returns (I256 i256) {
        return I256.wrap(I256.unwrap(_i256) ^ _value);
    }

    /// @dev Logical not of an I256
    /// @param _i256 The I256 to not
    /// @return i256 The result of the not
    function not(I256 _i256) internal pure returns (I256 i256) {
        return I256.wrap(~I256.unwrap(_i256));
    }

    /// @dev Compares an I256 to an int256 for equality
    /// @param _i256 The I256 to compare
    /// @param _value The int256 to compare to
    /// @return equal True if the I256 and int256 are equal
    function eq(I256 _i256, int256 _value) internal pure returns (bool) {
        return I256.unwrap(_i256) == _value;
    }

    /// @dev Compares an I256 to an int256 for inequality
    /// @param _i256 The I256 to compare
    /// @param _value The int256 to compare to
    /// @return equal True if the I256 and int256 are not equal
    function neq(I256 _i256, int256 _value) internal pure returns (bool) {
        return I256.unwrap(_i256) != _value;
    }

    /// @dev Compares an I256 to an int256 for greater than
    /// @param _i256 The I256 to compare
    /// @param _value The int256 to compare to
    /// @return equal True if the I256 is greater than the int256
    function gt(I256 _i256, int256 _value) internal pure returns (bool) {
        return I256.unwrap(_i256) > _value;
    }

    /// @dev Compares an I256 to an int256 for greater than or equal to
    /// @param _i256 The I256 to compare
    /// @param _value The int256 to compare to
    /// @return equal True if the I256 is greater than or equal to the int256
    function gte(I256 _i256, int256 _value) internal pure returns (bool) {
        return I256.unwrap(_i256) >= _value;
    }

    /// @dev Compares an I256 to an int256 for less than
    /// @param _i256 The I256 to compare
    /// @param _value The int256 to compare to
    /// @return equal True if the I256 is less than the int256
    function lt(I256 _i256, int256 _value) internal pure returns (bool) {
        return I256.unwrap(_i256) < _value;
    }

    /// @dev Compares an I256 to an int256 for less than or equal to
    /// @param _i256 The I256 to compare
    /// @param _value The int256 to compare to
    /// @return equal True if the I256 is less than or equal to the int256
    function lte(I256 _i256, int256 _value) internal pure returns (bool) {
        return I256.unwrap(_i256) <= _value;
    }

    /*********************
     * U256 ->
     *********************/

    /// @dev Wraps an int256 into a U256.
    /// @param _i256 The int256 to wrap.
    /// @return u256 The wrapped U256.
    function asU256(int256 _i256) internal pure returns (U256 u256) {
        u256 = U256.wrap(uint256(_i256));
    }

    /// @dev Wraps a uint256 into a U256.
    /// @param _u256 The uint256 to wrap.
    /// @return u256 The wrapped U256.
    function asU256(uint256 _u256) internal pure returns (U256 u256) {
        u256 = U256.wrap(_u256);
    }

    /// @dev Converts a U256 to a uint256.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint256 representation of the U256.
    function asUint256(U256 _u256) internal pure returns (uint256 unsigned) {
        return U256.unwrap(_u256);
    }

    /// @dev Converts a U256 to a uint224.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint224 representation of the U256.
    function asUint224(U256 _u256) internal pure returns (uint224 unsigned) {
        return uint224(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint216.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint216 representation of the U256.
    function asUint216(U256 _u256) internal pure returns (uint216 unsigned) {
        return uint216(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint208.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint208 representation of the U256.
    function asUint208(U256 _u256) internal pure returns (uint208 unsigned) {
        return uint208(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint200.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint200 representation of the U256.
    function asUint200(U256 _u256) internal pure returns (uint200 unsigned) {
        return uint200(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint192.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint192 representation of the U256.
    function asUint192(U256 _u256) internal pure returns (uint192 unsigned) {
        return uint192(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint184.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint184 representation of the U256.
    function asUint184(U256 _u256) internal pure returns (uint184 unsigned) {
        return uint184(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint176.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint176 representation of the U256.
    function asUint176(U256 _u256) internal pure returns (uint176 unsigned) {
        return uint176(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint168.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint168 representation of the U256.
    function asUint168(U256 _u256) internal pure returns (uint168 unsigned) {
        return uint168(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint160.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint160 representation of the U256.
    function asUint160(U256 _u256) internal pure returns (uint160 unsigned) {
        return uint160(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint152.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint152 representation of the U256.
    function asUint152(U256 _u256) internal pure returns (uint152 unsigned) {
        return uint152(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint144.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint144 representation of the U256.
    function asUint144(U256 _u256) internal pure returns (uint144 unsigned) {
        return uint144(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint136.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint136 representation of the U256.
    function asUint136(U256 _u256) internal pure returns (uint136 unsigned) {
        return uint136(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint128.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint128 representation of the U256.
    function asUint128(U256 _u256) internal pure returns (uint128 unsigned) {
        return uint128(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint120.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint120 representation of the U256.
    function asUint120(U256 _u256) internal pure returns (uint120 unsigned) {
        return uint120(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint112.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint112 representation of the U256.
    function asUint112(U256 _u256) internal pure returns (uint112 unsigned) {
        return uint112(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint104.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint104 representation of the U256.
    function asUint104(U256 _u256) internal pure returns (uint104 unsigned) {
        return uint104(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint96.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint96 representation of the U256.
    function asUint96(U256 _u256) internal pure returns (uint96 unsigned) {
        return uint96(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint88.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint88 representation of the U256.
    function asUint88(U256 _u256) internal pure returns (uint88 unsigned) {
        return uint88(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint80.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint80 representation of the U256.
    function asUint80(U256 _u256) internal pure returns (uint80 unsigned) {
        return uint80(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint72.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint72 representation of the U256.
    function asUint72(U256 _u256) internal pure returns (uint72 unsigned) {
        return uint72(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint64.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint64 representation of the U256.
    function asUint64(U256 _u256) internal pure returns (uint64 unsigned) {
        return uint64(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint56.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint56 representation of the U256.
    function asUint56(U256 _u256) internal pure returns (uint56 unsigned) {
        return uint56(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint48.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint48 representation of the U256.
    function asUint48(U256 _u256) internal pure returns (uint48 unsigned) {
        return uint48(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint40.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint40 representation of the U256.
    function asUint40(U256 _u256) internal pure returns (uint40 unsigned) {
        return uint40(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint32.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint32 representation of the U256.
    function asUint32(U256 _u256) internal pure returns (uint32 unsigned) {
        return uint32(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint24.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint24 representation of the U256.
    function asUint24(U256 _u256) internal pure returns (uint24 unsigned) {
        return uint24(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint16.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint16 representation of the U256.
    function asUint16(U256 _u256) internal pure returns (uint16 unsigned) {
        return uint16(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to a uint8.
    /// @param _u256 The U256 to unwrap.
    /// @return unsigned The uint8 representation of the U256.
    function asUint8(U256 _u256) internal pure returns (uint8 unsigned) {
        return uint8(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to an int256.
    /// @param _u256 The U256 to convert.
    /// @return signed The int256 representation of the U256.
    function asInt256(U256 _u256) internal pure returns (int256 signed) {
        return int256(U256.unwrap(_u256));
    }

    /// @dev Converts a U256 to an int248.
    /// @param _u256 The U256 to convert.
    /// @return signed The int248 representation of the U256.
    function asInt248(U256 _u256) internal pure returns (int248 signed) {
        return int248(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int240.
    /// @param _u256 The U256 to convert.
    /// @return signed The int240 representation of the U256.
    function asInt240(U256 _u256) internal pure returns (int240 signed) {
        return int240(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int232.
    /// @param _u256 The U256 to convert.
    /// @return signed The int232 representation of the U256.
    function asInt232(U256 _u256) internal pure returns (int232 signed) {
        return int232(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int224.
    /// @param _u256 The U256 to convert.
    /// @return signed The int224 representation of the U256.
    function asInt224(U256 _u256) internal pure returns (int224 signed) {
        return int224(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int216.
    /// @param _u256 The U256 to convert.
    /// @return signed The int216 representation of the U256.
    function asInt216(U256 _u256) internal pure returns (int216 signed) {
        return int216(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int208.
    /// @param _u256 The U256 to convert.
    /// @return signed The int208 representation of the U256.
    function asInt208(U256 _u256) internal pure returns (int208 signed) {
        return int208(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int200.
    /// @param _u256 The U256 to convert.
    /// @return signed The int200 representation of the U256.
    function asInt200(U256 _u256) internal pure returns (int200 signed) {
        return int200(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int192.
    /// @param _u256 The U256 to convert.
    /// @return signed The int192 representation of the U256.
    function asInt192(U256 _u256) internal pure returns (int192 signed) {
        return int192(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int184.
    /// @param _u256 The U256 to convert.
    /// @return signed The int184 representation of the U256.
    function asInt184(U256 _u256) internal pure returns (int184 signed) {
        return int184(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int176.
    /// @param _u256 The U256 to convert.
    /// @return signed The int176 representation of the U256.
    function asInt176(U256 _u256) internal pure returns (int176 signed) {
        return int176(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int168.
    /// @param _u256 The U256 to convert.
    /// @return signed The int168 representation of the U256.
    function asInt168(U256 _u256) internal pure returns (int168 signed) {
        return int168(int256(U256.unwrap(_u256)));
    }
    
    /// @dev Converts a U256 to an int160.
    /// @param _u256 The U256 to convert.
    /// @return signed The int160 representation of the U256.
    function asInt160(U256 _u256) internal pure returns (int160 signed) {
        return int160(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int152.
    /// @param _u256 The U256 to convert.
    /// @return signed The int152 representation of the U256.
    function asInt152(U256 _u256) internal pure returns (int152 signed) {
        return int152(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int144.
    /// @param _u256 The U256 to convert.
    /// @return signed The int144 representation of the U256.
    function asInt144(U256 _u256) internal pure returns (int144 signed) {
        return int144(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int136.
    /// @param _u256 The U256 to convert.
    /// @return signed The int136 representation of the U256.
    function asInt136(U256 _u256) internal pure returns (int136 signed) {
        return int136(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int128.
    /// @param _u256 The U256 to convert.
    /// @return signed The int128 representation of the U256.
    function asInt128(U256 _u256) internal pure returns (int128 signed) {
        return int128(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int120.
    /// @param _u256 The U256 to convert.
    /// @return signed The int120 representation of the U256.
    function asInt120(U256 _u256) internal pure returns (int120 signed) {
        return int120(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int112.
    /// @param _u256 The U256 to convert.
    /// @return signed The int112 representation of the U256.
    function asInt112(U256 _u256) internal pure returns (int112 signed) {
        return int112(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int104.
    /// @param _u256 The U256 to convert.
    /// @return signed The int104 representation of the U256.
    function asInt104(U256 _u256) internal pure returns (int104 signed) {
        return int104(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int96.
    /// @param _u256 The U256 to convert.
    /// @return signed The int96 representation of the U256.
    function asInt96(U256 _u256) internal pure returns (int96 signed) {
        return int96(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int88.
    /// @param _u256 The U256 to convert.
    /// @return signed The int88 representation of the U256.
    function asInt88(U256 _u256) internal pure returns (int88 signed) {
        return int88(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int80.
    /// @param _u256 The U256 to convert.
    /// @return signed The int80 representation of the U256.
    function asInt80(U256 _u256) internal pure returns (int80 signed) {
        return int80(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int72.
    /// @param _u256 The U256 to convert.
    /// @return signed The int72 representation of the U256.
    function asInt72(U256 _u256) internal pure returns (int72 signed) {
        return int72(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int64.
    /// @param _u256 The U256 to convert.
    /// @return signed The int64 representation of the U256.
    function asInt64(U256 _u256) internal pure returns (int64 signed) {
        return int64(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int56.
    /// @param _u256 The U256 to convert.
    /// @return signed The int56 representation of the U256.
    function asInt56(U256 _u256) internal pure returns (int56 signed) {
        return int56(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int48.
    /// @param _u256 The U256 to convert.
    /// @return signed The int48 representation of the U256.
    function asInt48(U256 _u256) internal pure returns (int48 signed) {
        return int48(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int40.
    /// @param _u256 The U256 to convert.
    /// @return signed The int40 representation of the U256.
    function asInt40(U256 _u256) internal pure returns (int40 signed) {
        return int40(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int32.
    /// @param _u256 The U256 to convert.
    /// @return signed The int32 representation of the U256.
    function asInt32(U256 _u256) internal pure returns (int32 signed) {
        return int32(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int24.
    /// @param _u256 The U256 to convert.
    /// @return signed The int24 representation of the U256.
    function asInt24(U256 _u256) internal pure returns (int24 signed) {
        return int24(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int16.
    /// @param _u256 The U256 to convert.
    /// @return signed The int16 representation of the U256.
    function asInt16(U256 _u256) internal pure returns (int16 signed) {
        return int16(int256(U256.unwrap(_u256)));
    }

    /// @dev Converts a U256 to an int8.
    /// @param _u256 The U256 to convert.
    /// @return signed The int8 representation of the U256.
    function asInt8(U256 _u256) internal pure returns (int8 signed) {
        return int8(int256(U256.unwrap(_u256)));
    }

    /// @dev Adds a uint256 to a U256.
    /// @param _u256 The U256 to add to.
    /// @param _addend The uint256 to add.
    /// @return u256 The U256 result of the addition.
    function add(U256 _u256, uint256 _addend) internal pure returns (U256 u256) {
        u256 = U256.wrap(add(U256.unwrap(_u256), _addend));
    }

    /// @dev Subtracts a uint256 from a U256.
    /// @param _u256 The U256 to subtract from.
    /// @param _subtrahend The uint256 to subtract.
    /// @return u256 The U256 result of the subtraction.
    function sub(U256 _u256, uint256 _subtrahend) internal pure returns (U256 u256) {
        return U256.wrap(sub(U256.unwrap(_u256), _subtrahend));
    }

    /// @dev Increments a U256.
    /// @param _u256 The U256 to increment.
    /// @return u256 The U256 result of the increment.
    function inc(U256 _u256) internal pure returns (U256 u256) {
        return U256.wrap(inc(U256.unwrap(_u256)));
    }

    /// @dev Decrements a U256.
    /// @param _u256 The U256 to decrement.
    /// @return u256 The U256 result of the decrement.
    function dec(U256 _u256) internal pure returns (U256 u256) {
        return U256.wrap(dec(U256.unwrap(_u256)));
    }

    /// @notice Calculate the product of a U256 and a uint256
    /// @param _u256 The U256
    /// @param _multiplier The uint256
    /// @return u256 The product of _u256 and _multiplier
    function mul(U256 _u256, uint256 _multiplier) internal pure returns (U256 u256) {
        return U256.wrap(mul(U256.unwrap(_u256), _multiplier));
    }

    /**
     * @dev Divide a U256 number by a uint256 number.
     * @param _u256 The U256 number to divide.
     * @param _divisor The uint256 number to divide by.
     * @return u256 The result of dividing _u256 by _divisor.
     */
    function div(U256 _u256, uint256 _divisor) internal pure returns (U256 u256) {
        return U256.wrap(div(U256.unwrap(_u256), _divisor));
    }

    /// @dev Get the modulus of a U256 and a uint256
    /// @param _u256 The U256 to be divided
    /// @param _divisor The divisor
    /// @return u256 The result of the modulo operation
    function mod(U256 _u256, uint256 _divisor) internal pure returns (U256 u256) {
        return U256.wrap(mod(U256.unwrap(_u256), _divisor));
    }

    /// @notice Raise a U256 to the power of a uint256
    /// @param _u256 The base
    /// @param _exponent The exponent
    /// @return u256 The result of raising `_u256` to the power of `_exponent`
    function exp(U256 _u256, uint256 _exponent) internal pure returns (U256 u256) {
        return U256.wrap(exp(U256.unwrap(_u256), _exponent));
    }

    /// @dev Right shift a uint256 by a uint256.
    /// @param _u256 uint256 to right shift
    /// @param _shift uint256 to shift by
    /// @return u256 uint256 result of right shift
    function rshift(U256 _u256, U256 _shift) internal pure returns (U256 u256) {
        return U256.wrap(U256.unwrap(_u256) >> U256.unwrap(_shift));
    }

    /// @dev Left shift a U256 by a U256.
    /// @param _u256 U256 to left shift
    /// @param _shift U256 to shift by
    /// @return u256 U256 result of left shift
    function lshift(U256 _u256, U256 _shift) internal pure returns (U256 u256) {
        return U256.wrap(U256.unwrap(_u256) << U256.unwrap(_shift));
    }

    /// @dev Right shift a U256 by a uint256.
    /// @param _u256 U256 to right shift
    /// @param _shift uint256 to shift by
    /// @return u256 U256 result of right shift
    function rshift(U256 _u256, uint256 _shift) internal pure returns (U256 u256) {
        return U256.wrap(U256.unwrap(_u256) >> _shift);
    }

    /// @dev Left shift a U256 by a uint256.
    /// @param _u256 U256 to left shift
    /// @param _shift uint256 to shift by
    /// @return u256 U256 result of left shift
    function lshift(U256 _u256, uint256 _shift) internal pure returns (U256 u256) {
        return U256.wrap(U256.unwrap(_u256) << _shift);
    }

    /// @dev logical and between the input and the value
    /// @param _u256 input
    /// @param _value value
    /// @return u256 the result of the logical and
    function and(U256 _u256, uint256 _value) internal pure returns (U256 u256) {
        return _u256 & U256.wrap(_value);
    }

    /// @dev logical or between the input and the value
    /// @param _u256 input
    /// @param _value value
    /// @return u256 the result of the logical or
    function or(U256 _u256, uint256 _value) internal pure returns (U256 u256) {
        return _u256 | U256.wrap(_value);
    }

    /// @dev logical xor between the input and the value
    /// @param _u256 input
    /// @param _value value
    /// @return u256 the result of the logical xor
    function xor(U256 _u256, uint256 _value) internal pure returns (U256 u256) {
        return _u256 ^ U256.wrap(_value);
    }

    /// @dev logical not of the input
    /// @param _u256 input
    /// @return u256 the result of the logical not
    function not(U256 _u256) internal pure returns (U256 u256) {
        return ~_u256;
    }

    /// @dev Compare a U256 to a uint256 for equality
    /// @param _u256 The U256 to compare
    /// @param _value The uint256 to compare
    /// @return result True if the U256 is equal to the uint256
    function eq(U256 _u256, uint256 _value) internal pure returns (bool result) {
        return U256.unwrap(_u256) == _value;
    }

    /// @dev Compare a U256 to a uint256 for inequality
    /// @param _u256 The U256 to compare
    /// @param _value The uint256 to compare
    /// @return result True if the U256 is not equal to the uint256
    function neq(U256 _u256, uint256 _value) internal pure returns (bool result) {
        return U256.unwrap(_u256) != _value;
    }

    /// @dev Compare a U256 to a uint256 for greater than
    /// @param _u256 The U256 to compare
    /// @param _value The uint256 to compare
    /// @return result True if the U256 is greater than the uint256
    function gt(U256 _u256, uint256 _value) internal pure returns (bool result) {
        return U256.unwrap(_u256) > _value;
    }

    /// @dev Compare a U256 to a uint256 for greater than or equal to
    /// @param _u256 The U256 to compare
    /// @param _value The uint256 to compare
    /// @return result True if the U256 is greater than or equal to the uint256
    function gte(U256 _u256, uint256 _value) internal pure returns (bool result) {
        return U256.unwrap(_u256) >= _value;
    }

    /// @dev Compare a U256 to a uint256 for less than
    /// @param _u256 The U256 to compare
    /// @param _value The uint256 to compare
    /// @return result True if the U256 is less than the uint256
    function lt(U256 _u256, uint256 _value) internal pure returns (bool result) {
        return U256.unwrap(_u256) < _value;
    }

    /// @dev Compare a U256 to a uint256 for less than or equal to
    /// @param _u256 The U256 to compare
    /// @param _value The uint256 to compare
    /// @return result True if the U256 is less than or equal to the uint256
    function lte(U256 _u256, uint256 _value) internal pure returns (bool result) {
        return U256.unwrap(_u256) <= _value;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UUPSUpgradeable} from "./ozUpgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "./ozUpgradeable/access/OwnableUpgradeable.sol";

import {UnsafeMath, U256} from "@0xdoublesharp/unsafe-math/contracts/UnsafeMath.sol";

contract AdminAccess is UUPSUpgradeable, OwnableUpgradeable {
  using UnsafeMath for U256;
  using UnsafeMath for uint256;

  mapping(address admin => bool isAdmin) private admins;
  mapping(address admin => bool isAdmin) private promotionalAdmins;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address[] calldata _admins, address[] calldata _promotionalAdmins) public initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
    _updateAdmins(_admins, true);
    _updatePromotionalAdmins(_promotionalAdmins, true);
  }

  function addAdmins(address[] calldata _admins) external onlyOwner {
    _updateAdmins(_admins, true);
  }

  function addAdmin(address _admin) external onlyOwner {
    _updateAdmin(_admin, true);
  }

  function removeAdmin(address _admin) external onlyOwner {
    _updateAdmin(_admin, false);
  }

  function addPromotionalAdmins(address[] calldata _admins) external onlyOwner {
    _updatePromotionalAdmins(_admins, true);
  }

  function _updateAdmins(address[] calldata _admins, bool _isAdmin) internal {
    U256 bounds = _admins.length.asU256();
    for (U256 iter; iter < bounds; iter = iter.inc()) {
      admins[_admins[iter.asUint256()]] = _isAdmin;
    }
  }

  function _updatePromotionalAdmins(address[] calldata _promotionalAdmins, bool _isAdmin) internal {
    U256 bounds = _promotionalAdmins.length.asU256();
    for (U256 iter; iter < bounds; iter = iter.inc()) {
      promotionalAdmins[_promotionalAdmins[iter.asUint256()]] = _isAdmin;
    }
  }

  function _updateAdmin(address _admin, bool _isAdmin) internal {
    admins[_admin] = _isAdmin;
  }

  function isAdmin(address _admin) external view returns (bool) {
    return admins[_admin];
  }

  function isPromotionalAdmin(address _admin) external view returns (bool) {
    return promotionalAdmins[_admin];
  }

  // solhint-disable-next-line no-empty-blocks
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  error CallerIsNotOwner();
  error NewOwnerIsZeroAddress();

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  function __Ownable_init() internal onlyInitializing {
    __Ownable_init_unchained();
  }

  function __Ownable_init_unchained() internal onlyInitializing {
    _transferOwnership(_msgSender());
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    _checkOwner();
    _;
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if the sender is not the owner.
   */
  function _checkOwner() internal view virtual {
    if (owner() != _msgSender()) {
      revert CallerIsNotOwner();
    }
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    if (newOwner == address(0)) {
      revert NewOwnerIsZeroAddress();
    }
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Internal function without access restriction.
   */
  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/beacon/IBeaconUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
  error NewImplementationIsNotAContract();
  error NewImplementationNotUUPS();
  error UnsupportedProxiableUUID();
  error NewAdminIsZeroAddress();
  error NewBeaconIsNotAContract();
  error BeaconImplementationIsNotAContract();
  error AddressIsNotContract();

  function __ERC1967Upgrade_init() internal onlyInitializing {}

  function __ERC1967Upgrade_init_unchained() internal onlyInitializing {}

  // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
  bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Emitted when the implementation is upgraded.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Returns the current implementation address.
   */
  function _getImplementation() internal view returns (address) {
    return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
  }

  /**
   * @dev Stores a new address in the EIP1967 implementation slot.
   */
  function _setImplementation(address newImplementation) private {
    if (!AddressUpgradeable.isContract(newImplementation)) {
      revert NewImplementationIsNotAContract();
    }
    StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
  }

  /**
   * @dev Perform implementation upgrade
   *
   * Emits an {Upgraded} event.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Perform implementation upgrade with additional setup call.
   *
   * Emits an {Upgraded} event.
   */
  function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
    _upgradeTo(newImplementation);
    if (data.length > 0 || forceCall) {
      _functionDelegateCall(newImplementation, data);
    }
  }

  /**
   * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
   *
   * Emits an {Upgraded} event.
   */
  function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
    // Upgrades from old implementations will perform a rollback test. This test requires the new
    // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
    // this special case will break upgrade paths from old UUPS implementation to new ones.
    if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
      _setImplementation(newImplementation);
    } else {
      try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
        if (slot != _IMPLEMENTATION_SLOT) {
          revert UnsupportedProxiableUUID();
        }
      } catch {
        revert NewImplementationNotUUPS();
      }
      _upgradeToAndCall(newImplementation, data, forceCall);
    }
  }

  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  /**
   * @dev Emitted when the admin account has changed.
   */
  event AdminChanged(address previousAdmin, address newAdmin);

  /**
   * @dev Returns the current admin.
   */
  function _getAdmin() internal view returns (address) {
    return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
  }

  /**
   * @dev Stores a new address in the EIP1967 admin slot.
   */
  function _setAdmin(address newAdmin) private {
    if (newAdmin == address(0)) {
      revert NewAdminIsZeroAddress();
    }
    StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
  }

  /**
   * @dev Changes the admin of the proxy.
   *
   * Emits an {AdminChanged} event.
   */
  function _changeAdmin(address newAdmin) internal {
    emit AdminChanged(_getAdmin(), newAdmin);
    _setAdmin(newAdmin);
  }

  /**
   * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
   * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
   */
  bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

  /**
   * @dev Emitted when the beacon is upgraded.
   */
  event BeaconUpgraded(address indexed beacon);

  /**
   * @dev Returns the current beacon.
   */
  function _getBeacon() internal view returns (address) {
    return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
  }

  /**
   * @dev Stores a new beacon in the EIP1967 beacon slot.
   */
  function _setBeacon(address newBeacon) private {
    if (!AddressUpgradeable.isContract(newBeacon)) {
      revert NewBeaconIsNotAContract();
    }
    if (!AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation())) {
      revert BeaconImplementationIsNotAContract();
    }
    StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
  }

  /**
   * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
   * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
   *
   * Emits a {BeaconUpgraded} event.
   */
  function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
    _setBeacon(newBeacon);
    emit BeaconUpgraded(newBeacon);
    if (data.length > 0 || forceCall) {
      _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
    }
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
    if (!AddressUpgradeable.isContract(target)) {
      revert AddressIsNotContract();
    }

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
  error NotInitializing();
  error IsInitializing();
  error AlreadyInitialized();

  /**
   * @dev Indicates that the contract has been initialized.
   * @custom:oz-retyped-from bool
   */
  uint8 private _initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private _initializing;

  /**
   * @dev Triggered when the contract has been initialized or reinitialized.
   */
  event Initialized(uint8 version);

  /**
   * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
   * `onlyInitializing` functions can be used to initialize parent contracts.
   *
   * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
   * constructor.
   *
   * Emits an {Initialized} event.
   */
  modifier initializer() {
    bool isTopLevelCall = !_initializing;

    if (
      !((isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1))
    ) {
      revert AlreadyInitialized();
    }
    _initialized = 1;
    if (isTopLevelCall) {
      _initializing = true;
    }
    _;
    if (isTopLevelCall) {
      _initializing = false;
      emit Initialized(1);
    }
  }

  /**
   * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
   * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
   * used to initialize parent contracts.
   *
   * A reinitializer may be used after the original initialization step. This is essential to configure modules that
   * are added through upgrades and that require initialization.
   *
   * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
   * cannot be nested. If one is invoked in the context of another, execution will revert.
   *
   * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
   * a contract, executing them in the right order is up to the developer or operator.
   *
   * WARNING: setting the version to 255 will prevent any future reinitialization.
   *
   * Emits an {Initialized} event.
   */
  modifier reinitializer(uint8 version) {
    if (!(!_initializing && _initialized < version)) {
      revert AlreadyInitialized();
    }
    _initialized = version;
    _initializing = true;
    _;
    _initializing = false;
    emit Initialized(version);
  }

  /**
   * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
   * {initializer} and {reinitializer} modifiers, directly or indirectly.
   */
  modifier onlyInitializing() {
    if (!_initializing) {
      revert NotInitializing();
    }
    _;
  }

  /**
   * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
   * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
   * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
   * through proxies.
   *
   * Emits an {Initialized} event the first time it is successfully executed.
   */
  function _disableInitializers() internal virtual {
    if (_initializing) {
      revert IsInitializing();
    }
    if (_initialized < type(uint8).max) {
      _initialized = type(uint8).max;
      emit Initialized(type(uint8).max);
    }
  }

  /**
   * @dev Returns the highest version that has been initialized. See {reinitializer}.
   */
  function _getInitializedVersion() internal view returns (uint8) {
    return _initialized;
  }

  /**
   * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
   */
  function _isInitializing() internal view returns (bool) {
    return _initializing;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.20;

import {IERC1822ProxiableUpgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/draft-IERC1822Upgradeable.sol";
import {ERC1967UpgradeUpgradeable} from "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
  error FunctionMustBeCalledThroughDelegateCall();
  error FunctionMustBeCalledThroughActiveProxy();
  error FunctionMustNotBeCalledThroughDelegateCall();

  function __UUPSUpgradeable_init() internal onlyInitializing {}

  function __UUPSUpgradeable_init_unchained() internal onlyInitializing {}

  /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
  address private immutable __self = address(this);

  /**
   * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
   * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
   * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
   * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
   * fail.
   */
  modifier onlyProxy() {
    if (address(this) == __self) {
      revert FunctionMustBeCalledThroughDelegateCall();
    }
    if (_getImplementation() != __self) {
      revert FunctionMustBeCalledThroughActiveProxy();
    }
    _;
  }

  /**
   * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
   * callable on the implementing contract but not through proxies.
   */
  modifier notDelegated() {
    if (address(this) != __self) {
      revert FunctionMustNotBeCalledThroughDelegateCall();
    }
    _;
  }

  /**
   * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
   * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
   *
   * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
   * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
   * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
   */
  function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
    return _IMPLEMENTATION_SLOT;
  }

  /**
   * @dev Upgrade the implementation of the proxy to `newImplementation`.
   *
   * Calls {_authorizeUpgrade}.
   *
   * Emits an {Upgraded} event.
   */
  function upgradeTo(address newImplementation) external virtual onlyProxy {
    _authorizeUpgrade(newImplementation);
    _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
  }

  /**
   * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
   * encoded in `data`.
   *
   * Calls {_authorizeUpgrade}.
   *
   * Emits an {Upgraded} event.
   */
  function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
    _authorizeUpgrade(newImplementation);
    _upgradeToAndCallUUPS(newImplementation, data, true);
  }

  /**
   * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
   * {upgradeTo} and {upgradeToAndCall}.
   *
   * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
   *
   * ```solidity
   * function _authorizeUpgrade(address) internal override onlyOwner {}
   * ```
   */
  function _authorizeUpgrade(address newImplementation) internal virtual;

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
  error RecipientMayHaveReverted();
  error CallToNonContract();
  error InsufficientAllowance();
  error InsufficientBalance();

  /**
   * @dev Returns true if `account` is a contract.
   *
   * [IMPORTANT]
   * ====
   * It is unsafe to assume that an address for which this function returns
   * false is an externally-owned account (EOA) and not a contract.
   *
   * Among others, `isContract` will return false for the following
   * types of addresses:
   *
   *  - an externally-owned account
   *  - a contract in construction
   *  - an address where a contract will be created
   *  - an address where a contract lived, but was destroyed
   * ====
   *
   * [IMPORTANT]
   * ====
   * You shouldn't rely on `isContract` to protect against flash loan attacks!
   *
   * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
   * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
   * constructor.
   * ====
   */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize/address.code.length, which returns 0
    // for contracts in construction, since the code is only stored at the end
    // of the constructor execution.

    return account.code.length > 0;
  }

  /**
   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
   * `recipient`, forwarding all available gas and reverting on errors.
   *
   * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
   * of certain opcodes, possibly making contracts go over the 2300 gas limit
   * imposed by `transfer`, making them unable to receive funds via
   * `transfer`. {sendValue} removes this limitation.
   *
   * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
   *
   * IMPORTANT: because control is transferred to `recipient`, care must be
   * taken to not create reentrancy vulnerabilities. Consider using
   * {ReentrancyGuard} or the
   * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
   */
  function sendValue(address payable recipient, uint256 amount) internal {
    if (address(this).balance < amount) {
      revert InsufficientBalance();
    }

    (bool success, ) = recipient.call{value: amount}("");
    if (!success) {
      revert RecipientMayHaveReverted();
    }
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain `call` is an unsafe replacement for a function call: use this
   * function instead.
   *
   * If `target` reverts with a revert reason, it is bubbled up by this
   * function (like regular Solidity function calls).
   *
   * Returns the raw returned data. To convert to the expected return value,
   * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
   *
   * Requirements:
   *
   * - `target` must be a contract.
   * - calling `target` with `data` must not revert.
   *
   * _Available since v3.1._
   */
  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, "Address: low-level call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
   * `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but also transferring `value` wei to `target`.
   *
   * Requirements:
   *
   * - the calling contract must have an ETH balance of at least `value`.
   * - the called Solidity function must be `payable`.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
   * with `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    if (address(this).balance < value) {
      revert InsufficientAllowance();
    }
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, "Address: low-level static call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
   * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
   *
   * _Available since v4.8._
   */
  function verifyCallResultFromTarget(
    address target,
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    if (success) {
      if (returndata.length == 0) {
        // only check isContract if the call was successful and the return data is empty
        // otherwise we already know that it was a contract
        if (!isContract(target)) {
          revert CallToNonContract();
        }
      }
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  /**
   * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
   * revert reason or using the provided one.
   *
   * _Available since v4.3._
   */
  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  function _revert(bytes memory returndata, string memory errorMessage) private pure {
    // Look for revert reason and bubble it up if present
    if (returndata.length > 0) {
      // The easiest way to bubble the revert reason is using memory via assembly
      /// @solidity memory-safe-assembly
      assembly {
        let returndata_size := mload(returndata)
        revert(add(32, returndata), returndata_size)
      }
    } else {
      revert(errorMessage);
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.20;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
  function __Context_init() internal onlyInitializing {}

  function __Context_init_unchained() internal onlyInitializing {}

  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}