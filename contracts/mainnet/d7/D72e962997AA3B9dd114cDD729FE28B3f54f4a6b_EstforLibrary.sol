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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {UnsafeMath, U256} from "@0xdoublesharp/unsafe-math/contracts/UnsafeMath.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import {IPlayers} from "./interfaces/IPlayers.sol";

// solhint-disable-next-line no-global-import
import "./globals/all.sol";

// This file contains methods for interacting with generic functions like trimming strings, merkle proof whitelisting etc.
library EstforLibrary {
  using UnsafeMath for U256;
  using UnsafeMath for uint;

  function isWhitespace(bytes1 _char) internal pure returns (bool) {
    return
      _char == 0x20 || // Space
      _char == 0x09 || // Tab
      _char == 0x0a || // Line feed
      _char == 0x0D || // Carriage return
      _char == 0x0B || // Vertical tab
      _char == 0x00; // empty byte
  }

  function leftTrim(string memory _str) internal pure returns (string memory) {
    bytes memory b = bytes(_str);
    uint strLen = b.length;
    uint start = type(uint).max;
    // Find the index of the first non-whitespace character
    for (uint i = 0; i < strLen; ++i) {
      bytes1 char = b[i];
      if (!isWhitespace(char)) {
        start = i;
        break;
      }
    }

    if (start == type(uint).max) {
      return "";
    }
    // Copy the remainder to a new string
    bytes memory trimmedBytes = new bytes(strLen - start);
    for (uint i = start; i < strLen; ++i) {
      trimmedBytes[i - start] = b[i];
    }
    return string(trimmedBytes);
  }

  function rightTrim(string calldata _str) internal pure returns (string memory) {
    bytes memory b = bytes(_str);
    uint strLen = b.length;
    if (strLen == 0) {
      return "";
    }
    int end = -1;
    // Find the index of the last non-whitespace character
    for (int i = int(strLen) - 1; i >= 0; --i) {
      bytes1 char = b[uint(i)];
      if (!isWhitespace(char)) {
        end = i;
        break;
      }
    }

    if (end == -1) {
      return "";
    }

    bytes memory trimmedBytes = new bytes(uint(end) + 1);
    for (uint i = 0; i <= uint(end); ++i) {
      trimmedBytes[i] = b[i];
    }
    return string(trimmedBytes);
  }

  function trim(string calldata _str) external pure returns (string memory) {
    return leftTrim(rightTrim(_str));
  }

  // Assumes the string is already trimmed
  function containsValidNameCharacters(string calldata _name) external pure returns (bool) {
    bytes memory b = bytes(_name);
    bool lastCharIsWhitespace;
    U256 iter = b.length.asU256();
    while (iter.neq(0)) {
      iter = iter.dec();
      uint i = iter.asUint256();
      bytes1 char = b[i];

      bool isUpperCaseLetter = (char >= 0x41) && (char <= 0x5A); // A-Z
      bool isLowerCaseLetter = (char >= 0x61) && (char <= 0x7A); // a-z
      bool isDigit = (char >= 0x30) && (char <= 0x39); // 0-9
      bool isSpecialCharacter = (char == 0x2D) || (char == 0x5F) || (char == 0x2E) || (char == 0x20); // "-", "_", ".", and " "
      bool _isWhitespace = isWhitespace(char);
      bool hasMultipleWhitespaceInRow = lastCharIsWhitespace && _isWhitespace;
      lastCharIsWhitespace = _isWhitespace;
      if ((!isUpperCaseLetter && !isLowerCaseLetter && !isDigit && !isSpecialCharacter) || hasMultipleWhitespaceInRow) {
        return false;
      }
    }
    return true;
  }

  function containsValidDiscordCharacters(string calldata _discord) external pure returns (bool) {
    bytes memory discord = bytes(_discord);
    U256 iter = discord.length.asU256();
    while (iter.neq(0)) {
      iter = iter.dec();
      uint i = iter.asUint256();
      bytes1 char = discord[i];

      bool isUpperCaseLetter = (char >= 0x41) && (char <= 0x5A); // A-Z
      bool isLowerCaseLetter = (char >= 0x61) && (char <= 0x7A); // a-z
      bool isDigit = (char >= 0x30) && (char <= 0x39); // 0-9
      if (!isUpperCaseLetter && !isLowerCaseLetter && !isDigit) {
        return false;
      }
    }

    return true;
  }

  function containsValidTelegramCharacters(string calldata _telegram) external pure returns (bool) {
    bytes memory telegram = bytes(_telegram);
    U256 iter = telegram.length.asU256();
    while (iter.neq(0)) {
      iter = iter.dec();
      uint i = iter.asUint256();
      bytes1 char = telegram[i];

      bool isUpperCaseLetter = (char >= 0x41) && (char <= 0x5A); // A-Z
      bool isLowerCaseLetter = (char >= 0x61) && (char <= 0x7A); // a-z
      bool isDigit = (char >= 0x30) && (char <= 0x39); // 0-9
      if (!isUpperCaseLetter && !isLowerCaseLetter && !isDigit) {
        return false;
      }
    }

    return true;
  }

  function toLower(string memory _str) internal pure returns (string memory) {
    bytes memory lowerStr = abi.encodePacked(_str);
    U256 iter = lowerStr.length.asU256();
    while (iter.neq(0)) {
      iter = iter.dec();
      uint i = iter.asUint256();
      if ((uint8(lowerStr[i]) >= 65) && (uint8(lowerStr[i]) <= 90)) {
        // So we add 32 to make it lowercase
        lowerStr[i] = bytes1(uint8(lowerStr[i]) + 32);
      }
    }
    return string(lowerStr);
  }

  function merkleProofVerify(
    bytes32[] calldata _proof,
    bytes32 _merkleRoot,
    bytes32 _leaf
  ) external pure returns (bool) {
    return MerkleProof.verify(_proof, _merkleRoot, _leaf);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Skill, Attire, CombatStyle, CombatStats} from "./misc.sol";
import {GuaranteedReward, RandomReward} from "./rewards.sol";

enum ActionQueueStatus {
  NONE,
  APPEND,
  KEEP_LAST_IN_PROGRESS
}

// The user chooses these
struct QueuedActionInput {
  // Keep this first
  Attire attire;
  uint16 actionId;
  uint16 regenerateId; // Food (combat), maybe something for non-combat later
  uint16 choiceId; // Melee/Arrow/Magic (combat), logs, ore (non-combat)
  uint16 rightHandEquipmentTokenId; // Axe/Sword/bow, can be empty
  uint16 leftHandEquipmentTokenId; // Shield, can be empty
  uint24 timespan; // How long to queue the action for
  CombatStyle combatStyle; // specific style of combat,  can also be used
}

struct QueuedAction {
  uint16 actionId;
  uint16 regenerateId; // Food (combat), maybe something for non-combat later
  uint16 choiceId; // Melee/Arrow/Magic (combat), logs, ore (non-combat)
  uint16 rightHandEquipmentTokenId; // Axe/Sword/bow, can be empty
  uint16 leftHandEquipmentTokenId; // Shield, can be empty
  uint24 timespan; // How long to queue the action for
  CombatStyle combatStyle; // specific style of combat,  can also be used
  uint24 prevProcessedTime; // How long the action has been processed for previously
  uint24 prevProcessedXPTime; // How much XP has been gained for this action so far
  uint64 queueId; // id of this queued action
  bool isValid; // If we still have the item, TODO: Not used yet
}

// This is only used as an input arg
struct Action {
  uint16 actionId;
  ActionInfo info;
  GuaranteedReward[] guaranteedRewards;
  RandomReward[] randomRewards;
  CombatStats combatStats;
}

struct ActionInfo {
  Skill skill;
  bool isAvailable;
  bool isDynamic;
  bool actionChoiceRequired; // If true, then the user must choose an action choice
  uint24 xpPerHour;
  uint32 minXP;
  uint24 numSpawned; // Mostly for combat, capped respawn rate for xp/drops. Per hour, base 10000
  uint16 handItemTokenIdRangeMin; // Inclusive
  uint16 handItemTokenIdRangeMax; // Inclusive
  uint8 successPercent; // 0-100
}

// Allows for 2, 4 or 8 hour respawn time
uint constant SPAWN_MUL = 1000;
uint constant RATE_MUL = 1000;
uint constant GUAR_MUL = 10; // Guaranteeded reward multiplier (1 decimal, allows for 2 hour respawn time)

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./actions.sol";
import "./items.sol";
import "./misc.sol";
import "./players.sol";
import "./rewards.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

uint16 constant NONE = 0;
// 1 - 255 (head)
uint16 constant HEAD_BASE = 1;
uint16 constant BRONZE_HELMET = HEAD_BASE;
uint16 constant IRON_HELMET = HEAD_BASE + 1;
uint16 constant MITHRIL_HELMET = HEAD_BASE + 2;
uint16 constant ADAMANTINE_HELMET = HEAD_BASE + 3;
uint16 constant RUNITE_HELMET = HEAD_BASE + 4;
uint16 constant TITANIUM_HELMET = HEAD_BASE + 5;
uint16 constant ORICHALCUM_HELMET = HEAD_BASE + 6;
uint16 constant NATUOW_HOOD = HEAD_BASE + 7;
uint16 constant BAT_WING_HAT = HEAD_BASE + 8;
uint16 constant NATURE_MASK = HEAD_BASE + 9;
uint16 constant APPRENTICE_HAT = HEAD_BASE + 10;
uint16 constant MAGE_HOOD = HEAD_BASE + 11;
uint16 constant SORCERER_HAT = HEAD_BASE + 12;
uint16 constant SEERS_HOOD = HEAD_BASE + 13;
uint16 constant SHAMAN_HOOD = HEAD_BASE + 14;
uint16 constant MASTER_HAT = HEAD_BASE + 15;
uint16 constant HEAD_MAX = HEAD_BASE + 254; // Inclusive
// 257 - 511 (neck)
uint16 constant NECK_BASE = 257;
uint16 constant SAPPHIRE_AMULET = NECK_BASE;
uint16 constant EMERALD_AMULET = NECK_BASE + 1;
uint16 constant RUBY_AMULET = NECK_BASE + 2;
uint16 constant AMETHYST_AMULET = NECK_BASE + 3;
uint16 constant DIAMOND_AMULET = NECK_BASE + 4;
uint16 constant DRAGONSTONE_AMULET = NECK_BASE + 5;
uint16 constant NECK_MAX = NECK_BASE + 254;

// 513 - 767 (body)
uint16 constant BODY_BASE = 513;
uint16 constant BRONZE_ARMOR = BODY_BASE;
uint16 constant IRON_ARMOR = BODY_BASE + 1;
uint16 constant MITHRIL_ARMOR = BODY_BASE + 2;
uint16 constant ADAMANTINE_ARMOR = BODY_BASE + 3;
uint16 constant RUNITE_ARMOR = BODY_BASE + 4;
uint16 constant TITANIUM_ARMOR = BODY_BASE + 5;
uint16 constant ORICHALCUM_ARMOR = BODY_BASE + 6;
uint16 constant NATUOW_BODY = BODY_BASE + 7;
uint16 constant BAT_WING_BODY = BODY_BASE + 8;
uint16 constant NATURE_BODY = BODY_BASE + 9;
uint16 constant APPRENTICE_BODY = BODY_BASE + 10;
uint16 constant MAGE_BODY = BODY_BASE + 11;
uint16 constant SORCERER_BODY = BODY_BASE + 12;
uint16 constant SEERS_BODY = BODY_BASE + 13;
uint16 constant SHAMAN_BODY = BODY_BASE + 14;
uint16 constant MASTER_BODY = BODY_BASE + 15;
uint16 constant BODY_MAX = BODY_BASE + 254;
// 769 - 1023 (arms)
uint16 constant ARMS_BASE = 769;
uint16 constant BRONZE_GAUNTLETS = ARMS_BASE;
uint16 constant IRON_GAUNTLETS = ARMS_BASE + 1;
uint16 constant MITHRIL_GAUNTLETS = ARMS_BASE + 2;
uint16 constant ADAMANTINE_GAUNTLETS = ARMS_BASE + 3;
uint16 constant RUNITE_GAUNTLETS = ARMS_BASE + 4;
uint16 constant TITANIUM_GAUNTLETS = ARMS_BASE + 5;
uint16 constant ORICHALCUM_GAUNTLETS = ARMS_BASE + 6;
uint16 constant NATUOW_BRACERS = ARMS_BASE + 7;
uint16 constant BAT_WING_BRACERS = ARMS_BASE + 8;
uint16 constant NATURE_BRACERS = ARMS_BASE + 9;
uint16 constant APPRENTICE_GAUNTLETS = ARMS_BASE + 10;
uint16 constant MAGE_BRACERS = ARMS_BASE + 11;
uint16 constant SORCERER_GAUNTLETS = ARMS_BASE + 12;
uint16 constant SEERS_BRACERS = ARMS_BASE + 13;
uint16 constant SHAMAN_GAUNTLETS = ARMS_BASE + 14;
uint16 constant MASTER_BRACERS = ARMS_BASE + 15;
uint16 constant ARMS_MAX = ARMS_BASE + 254;
// 1025 - 1279 (legs)
uint16 constant LEGS_BASE = 1025;
uint16 constant BRONZE_TASSETS = LEGS_BASE;
uint16 constant IRON_TASSETS = LEGS_BASE + 1;
uint16 constant MITHRIL_TASSETS = LEGS_BASE + 2;
uint16 constant ADAMANTINE_TASSETS = LEGS_BASE + 3;
uint16 constant RUNITE_TASSETS = LEGS_BASE + 4;
uint16 constant TITANIUM_TASSETS = LEGS_BASE + 5;
uint16 constant ORICHALCUM_TASSETS = LEGS_BASE + 6;
uint16 constant NATUOW_TASSETS = LEGS_BASE + 7;
uint16 constant BAT_WING_TROUSERS = LEGS_BASE + 8;
uint16 constant NATURE_TROUSERS = LEGS_BASE + 9;
uint16 constant APPRENTICE_TROUSERS = LEGS_BASE + 10;
uint16 constant MAGE_TROUSERS = LEGS_BASE + 11;
uint16 constant SORCERER_TROUSERS = LEGS_BASE + 12;
uint16 constant SEERS_TROUSERS = LEGS_BASE + 13;
uint16 constant SHAMAN_TROUSERS = LEGS_BASE + 14;
uint16 constant MASTER_TROUSERS = LEGS_BASE + 15;
uint16 constant LEGS_MAX = LEGS_BASE + 254;

// 1281 - 1535 (feet)
uint16 constant FEET_BASE = 1281;
uint16 constant BRONZE_BOOTS = FEET_BASE;
uint16 constant IRON_BOOTS = FEET_BASE + 1;
uint16 constant MITHRIL_BOOTS = FEET_BASE + 2;
uint16 constant ADAMANTINE_BOOTS = FEET_BASE + 3;
uint16 constant RUNITE_BOOTS = FEET_BASE + 4;
uint16 constant TITANIUM_BOOTS = FEET_BASE + 5;
uint16 constant ORICHALCUM_BOOTS = FEET_BASE + 6;
uint16 constant NATUOW_BOOTS = FEET_BASE + 7;
uint16 constant BAT_WING_BOOTS = FEET_BASE + 8;
uint16 constant NATURE_BOOTS = FEET_BASE + 9;
uint16 constant APPRENTICE_BOOTS = FEET_BASE + 10;
uint16 constant MAGE_BOOTS = FEET_BASE + 11;
uint16 constant SORCERER_BOOTS = FEET_BASE + 12;
uint16 constant SEERS_BOOTS = FEET_BASE + 13;
uint16 constant SHAMAN_BOOTS = FEET_BASE + 14;
uint16 constant MASTER_BOOTS = FEET_BASE + 15;
uint16 constant BOOTS_MAX = FEET_BASE + 254;

// 1536 - 1791 spare(1)
// 1792 - 2047 spare(2)

// Combat (right arm) (2048 - 2303)
uint16 constant COMBAT_BASE = 2048;
// Melee
uint16 constant SWORD_BASE = COMBAT_BASE;
uint16 constant BRONZE_SWORD = SWORD_BASE;
uint16 constant IRON_SWORD = COMBAT_BASE + 1;
uint16 constant MITHRIL_SWORD = COMBAT_BASE + 2;
uint16 constant ADAMANTINE_SWORD = COMBAT_BASE + 3;
uint16 constant RUNITE_SWORD = COMBAT_BASE + 4;
uint16 constant TITANIUM_SWORD = COMBAT_BASE + 5;
uint16 constant ORICHALCUM_SWORD = COMBAT_BASE + 6;
uint16 constant SWORD_MAX = SWORD_BASE + 49;
// Magic
uint16 constant STAFF_BASE = COMBAT_BASE + 50;
uint16 constant TOTEM_STAFF = STAFF_BASE;
uint16 constant SAPPHIRE_STAFF = STAFF_BASE + 1;
uint16 constant EMERALD_STAFF = STAFF_BASE + 2;
uint16 constant RUBY_STAFF = STAFF_BASE + 3;
uint16 constant AMETHYST_STAFF = STAFF_BASE + 4;
uint16 constant DIAMOND_STAFF = STAFF_BASE + 5;
uint16 constant DRAGONSTONE_STAFF = STAFF_BASE + 6;
uint16 constant STAFF_MAX = STAFF_BASE + 49;
// Ranged
uint16 constant BOW_BASE = COMBAT_BASE + 100;
uint16 constant BOW_MAX = BOW_BASE + 49;
// Shields (left arm)
uint16 constant SHIELD_BASE = COMBAT_BASE + 150;
uint16 constant BRONZE_SHIELD = SHIELD_BASE;
uint16 constant IRON_SHIELD = SHIELD_BASE + 1;
uint16 constant MITHRIL_SHIELD = SHIELD_BASE + 2;
uint16 constant ADAMANTINE_SHIELD = SHIELD_BASE + 3;
uint16 constant RUNITE_SHIELD = SHIELD_BASE + 4;
uint16 constant TITANIUM_SHIELD = SHIELD_BASE + 5;
uint16 constant ORICHALCUM_SHIELD = SHIELD_BASE + 6;
uint16 constant SHIELD_MAX = SHIELD_BASE + 49;

uint16 constant COMBAT_MAX = COMBAT_BASE + 255;

// Mining (2560 - 2815)
uint16 constant MINING_BASE = 2560;
uint16 constant BRONZE_PICKAXE = MINING_BASE;
uint16 constant IRON_PICKAXE = MINING_BASE + 1;
uint16 constant MITHRIL_PICKAXE = MINING_BASE + 2;
uint16 constant ADAMANTINE_PICKAXE = MINING_BASE + 3;
uint16 constant RUNITE_PICKAXE = MINING_BASE + 4;
uint16 constant TITANIUM_PICKAXE = MINING_BASE + 5;
uint16 constant ORICHALCUM_PICKAXE = MINING_BASE + 6;
uint16 constant MINING_MAX = MINING_BASE + 255;

// Woodcutting (2816 - 3071)
uint16 constant WOODCUTTING_BASE = 2816;
uint16 constant BRONZE_AXE = WOODCUTTING_BASE;
uint16 constant IRON_AXE = WOODCUTTING_BASE + 1;
uint16 constant MITHRIL_AXE = WOODCUTTING_BASE + 2;
uint16 constant ADAMANTINE_AXE = WOODCUTTING_BASE + 3;
uint16 constant RUNITE_AXE = WOODCUTTING_BASE + 4;
uint16 constant TITANIUM_AXE = WOODCUTTING_BASE + 5;
uint16 constant ORICHALCUM_AXE = WOODCUTTING_BASE + 6;
uint16 constant WOODCUTTING_MAX = WOODCUTTING_BASE + 255;

// Fishing (3072 - 3327)
uint16 constant FISHING_BASE = 3072;
uint16 constant NET_STICK = FISHING_BASE;
uint16 constant MEDIUM_NET = FISHING_BASE + 1;
uint16 constant WOOD_FISHING_ROD = FISHING_BASE + 2;
uint16 constant TITANIUM_FISHING_ROD = FISHING_BASE + 3;
uint16 constant HARPOON = FISHING_BASE + 4;
uint16 constant LARGE_NET = FISHING_BASE + 5;
uint16 constant MAGIC_NET = FISHING_BASE + 6;
uint16 constant CAGE = FISHING_BASE + 7;
uint16 constant FISHING_MAX = FISHING_BASE + 255;

// Firemaking (3328 - 3583)
uint16 constant FIRE_BASE = 3328;
uint16 constant MAGIC_FIRE_STARTER = FIRE_BASE;
uint16 constant FIRE_MAX = FIRE_BASE + 255;

// Smithing (none needed)
// Crafting (none needed)
// Cooking (none needed)

// 10000+ it'a all other items

// Bars
uint16 constant BAR_BASE = 10240; // (256 * 40)
uint16 constant BRONZE_BAR = BAR_BASE;
uint16 constant IRON_BAR = BAR_BASE + 1;
uint16 constant MITHRIL_BAR = BAR_BASE + 2;
uint16 constant ADAMANTINE_BAR = BAR_BASE + 3;
uint16 constant RUNITE_BAR = BAR_BASE + 4;
uint16 constant TITANIUM_BAR = BAR_BASE + 5;
uint16 constant ORICHALCUM_BAR = BAR_BASE + 6;
uint16 constant BAR_MAX = BAR_BASE + 255;

// Logs
uint16 constant LOG_BASE = 10496;
uint16 constant LOG = LOG_BASE;
uint16 constant OAK_LOG = LOG_BASE + 1;
uint16 constant WILLOW_LOG = LOG_BASE + 2;
uint16 constant MAPLE_LOG = LOG_BASE + 3;
uint16 constant REDWOOD_LOG = LOG_BASE + 4;
uint16 constant MAGICAL_LOG = LOG_BASE + 5;
uint16 constant ASH_LOG = LOG_BASE + 6;
uint16 constant ENCHANTED_LOG = LOG_BASE + 7;
uint16 constant LIVING_LOG = LOG_BASE + 8;
uint16 constant LOG_MAX = LOG_BASE + 255;

// Fish
uint16 constant RAW_FISH_BASE = 10752;
uint16 constant RAW_MINNUS = RAW_FISH_BASE;
uint16 constant RAW_BLEKK = RAW_FISH_BASE + 1;
uint16 constant RAW_SKRIMP = RAW_FISH_BASE + 2;
uint16 constant RAW_FEOLA = RAW_FISH_BASE + 3;
uint16 constant RAW_ANCHO = RAW_FISH_BASE + 4;
uint16 constant RAW_TROUT = RAW_FISH_BASE + 5;
uint16 constant RAW_ROJJA = RAW_FISH_BASE + 6;
uint16 constant RAW_BOWFISH = RAW_FISH_BASE + 7;
uint16 constant RAW_GOLDFISH = RAW_FISH_BASE + 8;
uint16 constant RAW_MYSTY_BLUE = RAW_FISH_BASE + 9;
uint16 constant RAW_FLITFISH = RAW_FISH_BASE + 10;
uint16 constant RAW_RAZORFISH = RAW_FISH_BASE + 11;
uint16 constant RAW_QUAFFER = RAW_FISH_BASE + 12;
uint16 constant RAW_ROXA = RAW_FISH_BASE + 13;
uint16 constant RAW_AZACUDDA = RAW_FISH_BASE + 14;
uint16 constant RAW_STONECLAW = RAW_FISH_BASE + 15;
uint16 constant RAW_CRUSKAN = RAW_FISH_BASE + 16;
uint16 constant RAW_CHODFISH = RAW_FISH_BASE + 17;
uint16 constant RAW_DOUBTFISH = RAW_FISH_BASE + 18;
uint16 constant RAW_ROSEFIN = RAW_FISH_BASE + 19;
uint16 constant RAW_SPHINX_FISH = RAW_FISH_BASE + 20;
uint16 constant RAW_SHAW = RAW_FISH_BASE + 21;
uint16 constant RAW_VANISHING_PERCH = RAW_FISH_BASE + 22;
uint16 constant RAW_VIPER_BASS = RAW_FISH_BASE + 23;
uint16 constant RAW_WATER_SERPENT = RAW_FISH_BASE + 24;
uint16 constant RAW_WHISKFIN = RAW_FISH_BASE + 25;
uint16 constant RAW_MHARA = RAW_FISH_BASE + 26;
uint16 constant RAW_GRAN_SQUIN = RAW_FISH_BASE + 27;
uint16 constant RAW_LANCER = RAW_FISH_BASE + 28;
uint16 constant RAW_OCTACLE = RAW_FISH_BASE + 29;
uint16 constant RAW_DRAGONFISH = RAW_FISH_BASE + 30;
uint16 constant RAW_YERESPATUM = RAW_FISH_BASE + 31;
uint16 constant RAW_FISH_MAX = RAW_FISH_BASE + 255;

// Cooked fish
uint16 constant COOKED_FISH_BASE = 11008;
uint16 constant COOKED_MINNUS = COOKED_FISH_BASE;
uint16 constant COOKED_BLEKK = COOKED_FISH_BASE + 1;
uint16 constant COOKED_SKRIMP = COOKED_FISH_BASE + 2;
uint16 constant COOKED_FEOLA = COOKED_FISH_BASE + 3;
uint16 constant COOKED_ANCHO = COOKED_FISH_BASE + 4;
uint16 constant COOKED_TROUT = COOKED_FISH_BASE + 5;
uint16 constant COOKED_ROJJA = COOKED_FISH_BASE + 6;
uint16 constant COOKED_BOWFISH = COOKED_FISH_BASE + 7;
uint16 constant COOKED_GOLDFISH = COOKED_FISH_BASE + 8;
uint16 constant COOKED_MYSTY_BLUE = COOKED_FISH_BASE + 9;
uint16 constant COOKED_FLITFISH = COOKED_FISH_BASE + 10;
uint16 constant COOKED_RAZORFISH = COOKED_FISH_BASE + 11;
uint16 constant COOKED_QUAFFER = COOKED_FISH_BASE + 12;
uint16 constant COOKED_ROXA = COOKED_FISH_BASE + 13;
uint16 constant COOKED_AZACUDDA = COOKED_FISH_BASE + 14;
uint16 constant COOKED_STONECLAW = COOKED_FISH_BASE + 15;
uint16 constant COOKED_CRUSKAN = COOKED_FISH_BASE + 16;
uint16 constant COOKED_CHODFISH = COOKED_FISH_BASE + 17;
uint16 constant COOKED_DOUBTFISH = COOKED_FISH_BASE + 18;
uint16 constant COOKED_ROSEFIN = COOKED_FISH_BASE + 19;
uint16 constant COOKED_SPHINX_FISH = COOKED_FISH_BASE + 20;
uint16 constant COOKED_SHAW = COOKED_FISH_BASE + 21;
uint16 constant COOKED_VANISHING_PERCH = COOKED_FISH_BASE + 22;
uint16 constant COOKED_VIPER_BASS = COOKED_FISH_BASE + 23;
uint16 constant COOKED_WATER_SERPENT = COOKED_FISH_BASE + 24;
uint16 constant COOKED_WHISKFIN = COOKED_FISH_BASE + 25;
uint16 constant COOKED_MHARA = COOKED_FISH_BASE + 26;
uint16 constant COOKED_GRAN_SQUIN = COOKED_FISH_BASE + 27;
uint16 constant COOKED_LANCER = COOKED_FISH_BASE + 28;
uint16 constant COOKED_OCTACLE = COOKED_FISH_BASE + 29;
uint16 constant COOKED_DRAGONFISH = COOKED_FISH_BASE + 30;
uint16 constant COOKED_YERESPATUM = COOKED_FISH_BASE + 31;
uint16 constant COOKED_FISH_MAX = COOKED_FISH_BASE + 255;

// Farming
uint16 constant FARMING_BASE = 11264;
uint16 constant BONEMEAL = FARMING_BASE;
uint16 constant FARMING_MAX = FARMING_BASE + 255;

// Mining
uint16 constant ORE_BASE = 11520;
uint16 constant COPPER_ORE = ORE_BASE;
uint16 constant TIN_ORE = ORE_BASE + 1;
uint16 constant IRON_ORE = ORE_BASE + 2;
uint16 constant SAPPHIRE = ORE_BASE + 3;
uint16 constant COAL_ORE = ORE_BASE + 4;
uint16 constant EMERALD = ORE_BASE + 5;
uint16 constant MITHRIL_ORE = ORE_BASE + 6;
uint16 constant RUBY = ORE_BASE + 7;
uint16 constant ADAMANTINE_ORE = ORE_BASE + 8;
uint16 constant AMETHYST = ORE_BASE + 9;
uint16 constant DIAMOND = ORE_BASE + 10;
uint16 constant RUNITE_ORE = ORE_BASE + 11;
uint16 constant DRAGONSTONE = ORE_BASE + 12;
uint16 constant TITANIUM_ORE = ORE_BASE + 13;
uint16 constant ORICHALCUM_ORE = ORE_BASE + 14;
uint16 constant ORE_MAX = ORE_BASE + 255;

// Arrows
uint16 constant ARROW_BASE = 11776;
uint16 constant BRONZE_ARROW = ARROW_BASE;
uint16 constant ARROW_MAX = ARROW_BASE + 255;

// Scrolls
uint16 constant SCROLL_BASE = 12032;
uint16 constant SHADOW_SCROLL = SCROLL_BASE;
uint16 constant NATURE_SCROLL = SCROLL_BASE + 1;
uint16 constant AQUA_SCROLL = SCROLL_BASE + 2;
uint16 constant HELL_SCROLL = SCROLL_BASE + 3;
uint16 constant AIR_SCROLL = SCROLL_BASE + 4;
uint16 constant BARRAGE_SCROLL = SCROLL_BASE + 5;
uint16 constant FREEZE_SCROLL = SCROLL_BASE + 6;
uint16 constant ANCIENT_SCROLL = SCROLL_BASE + 7;
uint16 constant SCROLL_MAX = SCROLL_BASE + 255;

// Free interval
uint16 constant NOT_USED_BASE = 12544;
uint16 constant NOT_USED_MAX = 12799;

// Boosts
uint16 constant BOOST_BASE = 12800;
uint16 constant COMBAT_BOOST = BOOST_BASE;
uint16 constant XP_BOOST = BOOST_BASE + 1;
uint16 constant GATHERING_BOOST = BOOST_BASE + 2;
uint16 constant SKILL_BOOST = BOOST_BASE + 3;
uint16 constant ABSENCE_BOOST = BOOST_BASE + 4;
uint16 constant PRAY_TO_THE_BEARDIE = BOOST_BASE + 5;
uint16 constant GO_OUTSIDE = BOOST_BASE + 6;
uint16 constant RAINING_RARES = BOOST_BASE + 7;
uint16 constant BOOST_MAX = 13055;

// MISC
uint16 constant MISC_BASE = 65535;
uint16 constant MYSTERY_BOX = MISC_BASE;
uint16 constant RAID_PASS = MISC_BASE - 1;
uint16 constant NATUOW_HIDE = MISC_BASE - 2;
uint16 constant NATUOW_LEATHER = MISC_BASE - 3;
uint16 constant SMALL_BONE = MISC_BASE - 4;
uint16 constant MEDIUM_BONE = MISC_BASE - 5;
uint16 constant LARGE_BONE = MISC_BASE - 6;
uint16 constant DRAGON_BONE = MISC_BASE - 7;
uint16 constant DRAGON_TEETH = MISC_BASE - 8;
uint16 constant DRAGON_SCALE = MISC_BASE - 9;
uint16 constant POISON = MISC_BASE - 10;
uint16 constant STRING = MISC_BASE - 11;
uint16 constant ROPE = MISC_BASE - 12;
uint16 constant LEAF_FRAGMENTS = MISC_BASE - 13;
uint16 constant VENOM_POUCH = MISC_BASE - 14;
uint16 constant BAT_WING = MISC_BASE - 15;
uint16 constant BAT_WING_PATCH = MISC_BASE - 16;
uint16 constant THREAD_NEEDLE = MISC_BASE - 17;
uint16 constant LOSSUTH_TEETH = MISC_BASE - 18;
uint16 constant LOSSUTH_SCALE = MISC_BASE - 19;
uint16 constant FEATHER = MISC_BASE - 20;
uint16 constant QUARTZ_INFUSED_FEATHER = MISC_BASE - 21;
uint16 constant BARK_CHUNK = MISC_BASE - 22;
uint16 constant APPRENTICE_FABRIC = MISC_BASE - 23;
uint16 constant MAGE_FABRIC = MISC_BASE - 24;
uint16 constant SORCERER_FABRIC = MISC_BASE - 25;
uint16 constant SEERS_FABRIC = MISC_BASE - 26;
uint16 constant SHAMAN_FABRIC = MISC_BASE - 27;
uint16 constant MASTER_FABRIC = MISC_BASE - 28;
uint16 constant DRAGON_KEY = MISC_BASE - 29;
uint16 constant BONE_KEY = MISC_BASE - 30;
uint16 constant NATURE_KEY = MISC_BASE - 31;
uint16 constant AQUA_KEY = MISC_BASE - 32;
uint16 constant BLUECANAR = MISC_BASE - 33;
uint16 constant ANURGAT = MISC_BASE - 34;
uint16 constant RUFARUM = MISC_BASE - 35;
uint16 constant WHITE_DEATH_SPORE = MISC_BASE - 36;
uint16 constant ENCHANTED_ACORN = MISC_BASE - 37;
uint16 constant ACORN_PATCH = MISC_BASE - 38;
uint16 constant MISC_MIN = 32768;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

enum BoostType {
  NONE,
  ANY_XP,
  COMBAT_XP,
  NON_COMBAT_XP,
  GATHERING,
  ABSENCE
}

struct Equipment {
  uint16 itemTokenId;
  uint24 amount;
}

enum Skill {
  NONE,
  COMBAT, // This is a helper which incorporates all combat skills, attack <-> magic, defence, health etc
  MELEE,
  RANGE,
  MAGIC,
  DEFENCE,
  HEALTH,
  RESERVED_COMBAT,
  MINING,
  WOODCUTTING,
  FISHING,
  SMITHING,
  THIEVING,
  CRAFTING,
  COOKING,
  FIREMAKING
}

struct Attire {
  uint16 head;
  uint16 neck;
  uint16 body;
  uint16 arms;
  uint16 legs;
  uint16 feet;
  uint16 ring;
  uint16 reserved1;
}

struct CombatStats {
  // From skill points
  int16 melee;
  int16 magic;
  int16 range;
  int16 health;
  // These include equipment
  int16 meleeDefence;
  int16 magicDefence;
  int16 rangeDefence;
}

enum CombatStyle {
  NONE,
  ATTACK,
  DEFENCE
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {QueuedAction} from "./actions.sol";
import {Skill, BoostType, CombatStats, Equipment} from "./misc.sol";

// 4 bytes for each level. 0x00000000 is the first level, 0x00000054 is the second, etc.
bytes constant XP_BYTES = hex"0000000000000054000000AE0000010E00000176000001E60000025E000002DE00000368000003FD0000049B00000546000005FC000006C000000792000008730000096400000A6600000B7B00000CA400000DE100000F36000010A200001229000013CB0000158B0000176B0000196E00001B9400001DE20000205A000022FF000025D5000028DD00002C1E00002F99000033540000375200003B9A000040300000451900004A5C00004FFF0000560900005C810000637000006ADD000072D100007B570000847900008E42000098BE0000A3F90000B0020000BCE70000CAB80000D9860000E9630000FA6200010C990001201D0001350600014B6F0001637300017D2E000198C10001B64E0001D5F80001F7E600021C430002433B00026CFD000299BE0002C9B30002FD180003342B00036F320003AE730003F23D00043AE3000488BE0004DC2F0005359B000595700005FC2400066A360006E02D00075E990007E6160008774C000912EB0009B9B4000A6C74000B2C06000BF956000CD561000DC134000EBDF3000FCCD40010EF24";

enum EquipPosition {
  NONE,
  HEAD,
  NECK,
  BODY,
  ARMS,
  LEGS,
  FEET,
  SPARE1,
  SPARE2,
  LEFT_HAND,
  RIGHT_HAND,
  BOTH_HANDS,
  ARROW_SATCHEL,
  MAGIC_BAG,
  FOOD,
  AUX, // wood, seeds  etc..
  BOOST_VIAL
}

struct Player {
  uint40 currentActionStartTime; // The start time of the first queued action
  Skill currentActionProcessedSkill1; // The skill that the queued action has already gained XP in
  uint24 currentActionProcessedXPGained1; // The amount of XP that the queued action has already gained
  Skill currentActionProcessedSkill2;
  uint24 currentActionProcessedXPGained2;
  uint16 currentActionProcessedFoodConsumed;
  uint16 currentActionProcessedBaseInputItemsConsumedNum; // e.g scrolls, crafting materials etc
  Skill skillBoosted1; // The skill that is boosted
  Skill skillBoosted2; // The second skill that is boosted
  uint56 totalXP;
  uint8 version; // Not used currently
  // TODO: Can be up to 7
  QueuedAction[] actionQueue;
  string name; // Raw name
}

struct Item {
  EquipPosition equipPosition;
  bool exists;
  // Can it be transferred?
  bool isTransferable;
  // Food
  uint16 healthRestored;
  // Boost vial
  BoostType boostType;
  uint16 boostValue; // Varies, could be the % increase
  uint24 boostDuration; // How long the effect of the boost last
  // Combat stats
  int16 melee;
  int16 magic;
  int16 range;
  int16 meleeDefence;
  int16 magicDefence;
  int16 rangeDefence;
  int16 health;
  // Minimum requirements in this skill to use this item (can be NONE)
  Skill skill;
  uint32 minXP;
}

struct PlayerBoostInfo {
  uint40 startTime;
  uint24 duration;
  uint16 val;
  uint16 itemTokenId; // Get the effect of it
  BoostType boostType;
}

// This is effectively a ratio to produce 1 of outputTokenId.
// Fixed based available actions that can be undertaken for an action
struct ActionChoice {
  Skill skill; // Skill that this action choice is related to
  uint32 minXP; // Min XP in the skill to be able to do this action choice
  int16 skillDiff; // How much the skill is increased/decreased by this action choice
  uint24 rate; // Rate of output produced per hour (base 1000) 3 decimals
  uint24 xpPerHour;
  uint16 inputTokenId1;
  uint8 inputAmount1;
  uint16 inputTokenId2;
  uint8 inputAmount2;
  uint16 inputTokenId3;
  uint8 inputAmount3;
  uint16 outputTokenId;
  uint8 outputAmount;
  uint8 successPercent; // 0-100
}

// Must be in the same order as Skill
struct PackedXP {
  uint40 melee;
  uint40 range;
  uint40 magic;
  uint40 defence;
  uint40 health;
  uint40 reservedCombat;
  // Next slot
  uint40 mining;
  uint40 woodcutting;
  uint40 fishing;
  uint40 smithing;
  uint40 thieving;
  uint40 crafting;
  // Next slot
  uint40 cooking;
  uint40 firemaking;
}

struct AvatarInfo {
  string name;
  string description;
  string imageURI;
  Skill[2] startSkills; // Can be NONE
}

struct PastRandomRewardInfo {
  uint64 queueId;
  uint16 itemTokenId;
  uint24 amount;
  uint numRemoved;
}

struct PendingQueuedActionEquipmentState {
  uint[] consumedItemTokenIds;
  uint[] consumedAmounts;
  uint[] producedItemTokenIds;
  uint[] producedAmounts;
}

struct PendingQueuedActionMetadata {
  uint32 xpGained; // total xp gained
  uint32 rolls;
  bool died;
  uint16 actionId;
  uint64 queueId;
  uint24 elapsedTime;
  uint24 xpElapsedTime;
}

struct PendingQueuedActionData {
  // The amount of XP that the queued action has already gained
  Skill skill1;
  uint24 xpGained1;
  Skill skill2;
  uint24 xpGained2;
  // How much food is consumed in the current action so far
  uint16 foodConsumed;
  // How many base consumables are consumed in the current action so far
  uint16 baseInputItemsConsumedNum;
}

struct PendingQueuedActionProcessed {
  // XP gained during this session
  Skill[] skills;
  uint32[] xpGainedSkills;
  // Data for the current action which has been previously processed
  PendingQueuedActionData currentAction;
}

struct QuestState {
  uint[] consumedItemTokenIds;
  uint[] consumedAmounts;
  uint[] rewardItemTokenIds;
  uint[] rewardAmounts;
  PlayerQuest[] activeQuestInfo;
  uint[] questsCompleted;
  Skill[] skills; // Skills gained XP in
  uint32[] xpGainedSkills; // XP gained in these skills
}

struct PendingQueuedActionState {
  // These 2 are in sync. Separated to reduce gas/deployment costs as these are passed down many layers.
  PendingQueuedActionEquipmentState[] equipmentStates;
  PendingQueuedActionMetadata[] actionMetadatas;
  QueuedAction[] remainingQueuedActions;
  PendingQueuedActionProcessed processedData;
  PastRandomRewardInfo[] producedPastRandomRewards;
  uint[] xpRewardItemTokenIds;
  uint[] xpRewardAmounts;
  uint[] dailyRewardItemTokenIds;
  uint[] dailyRewardAmounts;
  bytes32 dailyRewardMask;
  QuestState quests;
}

struct FullAttireBonusInput {
  Skill skill;
  uint8 bonusXPPercent;
  uint8 bonusRewardsPercent; // 3 = 3%
  uint16[5] itemTokenIds; // 0 = head, 1 = body, 2 arms, 3 body, 4 = feet
}

struct Quest {
  uint16 dependentQuestId; // The quest that must be completed before this one can be started
  uint16 actionId1; // action to do
  uint16 actionNum1; // how many (up to 65535)
  uint16 actionId2; // another action to do
  uint16 actionNum2; // how many (up to 65535)
  uint16 actionChoiceId; // actionChoice to perform
  uint16 actionChoiceNum; // how many to do (base number), (up to 65535)
  Skill skillReward; // The skill to reward XP to
  uint16 skillXPGained; // The amount of XP to give (up to 65535)
  uint16 rewardItemTokenId1; // Reward an item
  uint16 rewardAmount1; // amount of the reward (up to 65535)
  uint16 rewardItemTokenId2; // Reward another item
  uint16 rewardAmount2; // amount of the reward (up to 65535)
  uint16 burnItemTokenId; // Burn an item
  uint16 burnAmount; // amount of the burn (up to 65535)
  uint16 questId; // Unique id for this quest
  bool requireActionsCompletedBeforeBurning; // If true, the player must complete the actions before the item can be burnt
}

struct PlayerQuest {
  uint32 questId;
  uint16 actionCompletedNum1;
  uint16 actionCompletedNum2;
  uint16 actionChoiceCompletedNum;
  uint16 burnCompletedAmount;
  bool isFixed;
}

// Contains everything you need to create an item
struct InputItem {
  CombatStats combatStats;
  uint16 tokenId;
  EquipPosition equipPosition;
  // Can it be transferred?
  bool isTransferable;
  // Minimum requirements in this skill
  Skill skill;
  uint32 minXP;
  // Food
  uint16 healthRestored;
  // Boost
  BoostType boostType;
  uint16 boostValue; // Varies, could be the % increase
  uint24 boostDuration; // How long the effect of the boost vial last
  // uri
  string metadataURI;
  string name;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {BoostType, Equipment} from "./misc.sol";

struct GuaranteedReward {
  uint16 itemTokenId;
  uint16 rate; // num per hour, base 10 (1 decimal)
}

struct RandomReward {
  uint16 itemTokenId;
  uint16 chance; // out of 65535
  uint8 amount; // out of 255
}

struct PendingRandomReward {
  uint16 actionId;
  uint40 startTime;
  uint24 xpElapsedTime;
  uint64 queueId;
  // Boosts active at the time this was generated
  BoostType boostType;
  uint16 boostValue; // Varies, could be the % increase
  //  uint24 boostedTime; // How long the effect of the boost vial lasted during this action
  uint24 boostDuration;
  uint40 boostStartTime; // When the boost was started
  // Full equipment at the time this was generated
  uint8 fullAttireBonusRewardsPercent;
}

struct ActionRewards {
  uint16 guaranteedRewardTokenId1;
  uint16 guaranteedRewardRate1; // Num per hour, base 10 (1 decimal). Max 6553.5 per hour
  uint16 guaranteedRewardTokenId2;
  uint16 guaranteedRewardRate2;
  uint16 guaranteedRewardTokenId3;
  uint16 guaranteedRewardRate3;
  // Random chance rewards
  uint16 randomRewardTokenId1;
  uint16 randomRewardChance1; // out of 65335
  uint8 randomRewardAmount1; // out of 255
  uint16 randomRewardTokenId2;
  uint16 randomRewardChance2;
  uint8 randomRewardAmount2;
  uint16 randomRewardTokenId3;
  uint16 randomRewardChance3;
  uint8 randomRewardAmount3;
  uint16 randomRewardTokenId4;
  uint16 randomRewardChance4;
  uint8 randomRewardAmount4;
  // No more room!
}

struct XPThresholdReward {
  uint32 xpThreshold;
  Equipment[] rewards;
}

uint constant MAX_GUARANTEED_REWARDS_PER_ACTION = 3;
uint constant MAX_RANDOM_REWARDS_PER_ACTION = 4;
uint constant MAX_REWARDS_PER_ACTION = MAX_GUARANTEED_REWARDS_PER_ACTION + MAX_RANDOM_REWARDS_PER_ACTION;
uint constant MAX_CONSUMED_PER_ACTION = 3;
uint constant MAX_QUEST_REWARDS = 2;

// 4 bytes for each threshold, starts at 500 xp in decimal
bytes constant xpRewardBytes = hex"00000000000001F4000003E8000009C40000138800002710000075300000C350000186A00001D4C0000493E0000557300007A120000927C0000B71B0";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../globals/misc.sol";

interface IPlayers {
  function clearEverythingBeforeTokenTransfer(address from, uint tokenId) external;

  function getURI(
    uint playerId,
    string calldata name,
    string calldata avatarName,
    string calldata avatarDescription,
    string calldata imageURI
  ) external view returns (string memory);

  function mintedPlayer(
    address from,
    uint playerId,
    Skill[2] calldata startSkills,
    bool makeActive,
    uint[] calldata startingItemTokenIds,
    uint[] calldata startingAmounts
  ) external;

  function isOwnerOfPlayerAndActive(address from, uint playerId) external view returns (bool);

  function activePlayer(address owner) external view returns (uint playerId);
}