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
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
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
pragma solidity ^0.8.20;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {UUPSUpgradeable} from "../ozUpgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "../ozUpgradeable/access/OwnableUpgradeable.sol";

import {UnsafeMath, U256} from "@0xdoublesharp/unsafe-math/contracts/UnsafeMath.sol";

import {IBrushToken} from "../interfaces/IBrushToken.sol";
import {IPlayers} from "../interfaces/IPlayers.sol";
import {IClans} from "../interfaces/IClans.sol";
import {IBankFactory} from "../interfaces/IBankFactory.sol";
import {EstforLibrary} from "../EstforLibrary.sol";

contract Clans is UUPSUpgradeable, OwnableUpgradeable, IClans {
  using UnsafeMath for U256;
  using UnsafeMath for uint16;
  using UnsafeMath for uint80;
  using UnsafeMath for uint256;

  event ClanCreated(uint clanId, uint playerId, string[] clanInfo, uint imageId, uint tierId);
  event SetClanRank(uint clanId, uint playerId, ClanRank clan);
  event InviteSent(uint clanId, uint playerId, uint fromPlayerId);
  event InvitesSent(uint clanId, uint[] playerIds, uint fromPlayerId);
  event InviteAccepted(uint clanId, uint playerId);
  event MemberLeft(uint clanId, uint playerId);
  event JoinRequestSent(uint clanId, uint playerId);
  event JoinRequestAccepted(uint clanId, uint playerId, uint acceptedByPlayerId);
  event JoinRequestsAccepted(uint clanId, uint[] playerIds, uint acceptedByPlayerId);
  event JoinRequestRemoved(uint clanId, uint playerId);
  event ClanOwnershipTransferred(uint clanId, uint playerId);
  event AddTiers(Tier[] tiers);
  event EditTiers(Tier[] tiers);
  event ClanOwnerLeft(uint clanId, uint playerId);
  event ClanEdited(uint clanId, uint playerId, string[] clanInfo, uint imageId);
  event ClanUpgraded(uint clanId, uint playerId, uint tierId);
  event ClanDestroyed(uint clanId);
  event PlayerRankUpdated(uint clanId, uint memberId, ClanRank rank, uint playerId);
  event InvitesDeletedByPlayer(uint[] clanIds, uint playerId);
  event InvitesDeletedByClan(uint clanId, uint[] invitedPlayerIds, uint deletedInvitesPlayerId);
  event EditNameCost(uint newCost);

  error AlreadyInClan();
  error NotOwnerOfPlayer();
  error NotOwnerOfPlayerAndActive();
  error NotMemberOfClan();
  error ClanIsFull();
  error OwnerExists();
  error InvalidImageId();
  error NameTooShort();
  error NameTooLong();
  error NameInvalidCharacters();
  error DiscordTooLong();
  error DiscordTooShort();
  error DiscordInvalidCharacters();
  error TelegramTooLong();
  error TelegramInvalidCharacters();
  error ClanDoesNotExist();
  error TierDoesNotExist();
  error CannotDowngradeTier();
  error TierAlreadyExists();
  error NameAlreadyExists();
  error ClanDestroyFailedHasMembers();
  error PriceTooLow();
  error MemberCapacityTooLow();
  error BankCapacityTooLow();
  error ImageIdTooLow();
  error AlreadySentInvite();
  error AlreadySentJoinRequest();
  error NoJoinRequest();
  error RankMustBeLowerRenounce();
  error RankNotHighEnough();
  error CannotSetSameRank();
  error ChangingRankEqualOrHigherThanSelf();
  error ChangingRankOfPlayerHigherThanSelf();
  error ChangingRankOfPlayerEqualOrHigherThanSelf();
  error CannotRenounceToSelf();
  error InviteDoesNotExist();
  error NoInvitesToDelete();

  enum ClanRank {
    NONE, // Not in a clan
    COMMONER, // Member of the clan
    SCOUT, // Invite and kick commoners
    TREASURER, // Can withdraw from bank
    LEADER // Can edit clan details
  }

  struct Clan {
    uint80 owner;
    uint16 imageId;
    uint16 memberCount;
    uint40 createdTimestamp;
    uint8 tierId;
    string name;
    mapping(uint playerId => bool invited) inviteRequests;
  }

  struct PlayerInfo {
    uint32 clanId; // What clan they are in
    ClanRank rank; // Current clan rank
    uint32 requestedClanId; // What clan they have requested to join
  }

  struct Tier {
    uint8 id;
    uint16 maxMemberCapacity;
    uint16 maxBankCapacity;
    uint24 maxImageId;
    uint40 minimumAge; // How old the clan must be before it can be upgraded to this tier
    uint80 price;
  }

  modifier isOwnerOfPlayer(uint _playerId) {
    if (playerNFT.balanceOf(msg.sender, _playerId) == 0) {
      revert NotOwnerOfPlayer();
    }
    _;
  }

  modifier isOwnerOfPlayerAndActive(uint _playerId) {
    if (!players.isOwnerOfPlayerAndActive(msg.sender, _playerId)) {
      revert NotOwnerOfPlayerAndActive();
    }
    _;
  }

  modifier isMinimumRank(
    uint _clanId,
    uint _playerId,
    ClanRank _rank
  ) {
    PlayerInfo storage player = playerInfo[_playerId];
    if (player.clanId != _clanId) {
      revert NotMemberOfClan();
    } else if (playerInfo[_playerId].rank < _rank) {
      revert RankNotHighEnough();
    }
    _;
  }

  modifier isMemberOfClan(uint _clanId, uint _playerId) {
    if (playerInfo[_playerId].clanId != _clanId) {
      revert NotMemberOfClan();
    }
    _;
  }

  IBrushToken private brush;
  IPlayers private players;
  IBankFactory public bankFactory;
  IERC1155 private playerNFT;
  uint80 public nextClanId;
  address private pool;
  uint80 public editNameCost;
  address private dev;
  mapping(uint clanId => Clan clan) public clans;
  mapping(uint playerId => PlayerInfo) public playerInfo;
  mapping(uint id => Tier tier) public tiers;
  mapping(string name => bool exists) public lowercaseNames;
  mapping(uint clanId => uint40 timestampLeft) public ownerlessClanTimestamps; // timestamp

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    IBrushToken _brush,
    IERC1155 _playerNFT,
    address _pool,
    address _dev,
    uint80 _editNameCost
  ) external initializer {
    __UUPSUpgradeable_init();
    __Ownable_init();
    brush = _brush;
    playerNFT = _playerNFT;
    pool = _pool;
    dev = _dev;
    nextClanId = 1;
    editNameCost = _editNameCost;
    emit EditNameCost(_editNameCost);
  }

  function _checkTierExists(uint _tierId) private view {
    Tier storage tier = tiers[_tierId];
    if (tier.id == 0) {
      revert TierDoesNotExist();
    }
  }

  function createClan(
    uint _playerId,
    string calldata _name,
    string calldata _discord,
    string calldata _telegram,
    uint16 _imageId,
    uint8 _tierId
  ) external isOwnerOfPlayerAndActive(_playerId) {
    PlayerInfo storage player = playerInfo[_playerId];
    if (isMemberOfAnyClan(_playerId)) {
      revert AlreadyInClan();
    }

    Tier storage tier = tiers[_tierId];
    _checkTierExists(_tierId);
    _checkClanImage(_imageId, tier.maxImageId);

    uint clanId = nextClanId;
    nextClanId = uint80(nextClanId.inc());
    Clan storage clan = clans[clanId];
    clan.owner = uint80(_playerId);
    clan.tierId = 1; // Updated later in _upgradeClan if it's > 1
    clan.imageId = _imageId;
    clan.memberCount = 1;
    clan.createdTimestamp = uint40(block.timestamp);

    player.clanId = uint32(clanId);
    player.rank = ClanRank.LEADER;
    if (player.requestedClanId != 0) {
      removeJoinRequest(clanId, _playerId);
    }

    (string memory trimmedName, ) = _setName(clanId, _name);
    _checkSocials(_discord, _telegram);
    string[] memory clanInfo = _createClanInfo(trimmedName, _discord, _telegram);
    emit ClanCreated(clanId, _playerId, clanInfo, _imageId, _tierId);
    if (_tierId != 1) {
      _upgradeClan(clanId, _playerId, _tierId);
    }

    bankFactory.createBank(msg.sender, clanId);
  }

  function editClan(
    uint _clanId,
    string calldata _name,
    string calldata _discord,
    string calldata _telegram,
    uint _imageId
  ) external isOwnerOfPlayer(clans[_clanId].owner) {
    Clan storage clan = clans[_clanId];
    Tier storage tier = tiers[clan.tierId];
    _checkClanImage(_imageId, tier.maxImageId);
    (string memory trimmedName, bool nameChanged) = _setName(_clanId, _name);
    if (nameChanged) {
      _pay(editNameCost);
    }

    _checkSocials(_discord, _telegram);
    string[] memory clanInfo = _createClanInfo(trimmedName, _discord, _telegram);
    emit ClanEdited(_clanId, clans[_clanId].owner, clanInfo, _imageId);
  }

  function deleteInvitesAsPlayer(uint[] calldata _clanIds, uint _playerId) external isOwnerOfPlayer(_playerId) {
    if (_clanIds.length == 0) {
      revert NoInvitesToDelete();
    }

    for (uint i = 0; i < _clanIds.length; ++i) {
      uint clanId = _clanIds[i];
      if (!clans[clanId].inviteRequests[_playerId]) {
        revert InviteDoesNotExist();
      }
      delete clans[clanId].inviteRequests[_playerId];
    }
    emit InvitesDeletedByPlayer(_clanIds, _playerId);
  }

  function deleteInvitesAsClan(
    uint _clanId,
    uint[] calldata _invitedPlayerIds,
    uint _playerId
  ) external isOwnerOfPlayer(_playerId) isMinimumRank(_clanId, _playerId, ClanRank.SCOUT) {
    Clan storage clan = clans[_clanId];
    if (_invitedPlayerIds.length == 0) {
      revert NoInvitesToDelete();
    }

    for (uint i = 0; i < _invitedPlayerIds.length; ++i) {
      uint invitedPlayerId = _invitedPlayerIds[i];
      if (!clan.inviteRequests[invitedPlayerId]) {
        revert InviteDoesNotExist();
      }
      clan.inviteRequests[invitedPlayerId] = false;
    }

    emit InvitesDeletedByClan(_clanId, _invitedPlayerIds, _playerId);
  }

  function _inviteMember(uint _clanId, uint _member) private {
    Clan storage clan = clans[_clanId];
    if (clan.inviteRequests[_member]) {
      revert AlreadySentInvite();
    }

    clan.inviteRequests[_member] = true;
  }

  function inviteMember(
    uint _clanId,
    uint _member,
    uint _playerId
  ) external isOwnerOfPlayer(_playerId) isMinimumRank(_clanId, _playerId, ClanRank.SCOUT) {
    Clan storage clan = clans[_clanId];
    Tier storage tier = tiers[clan.tierId];
    if (clan.memberCount >= tier.maxMemberCapacity) {
      revert ClanIsFull();
    }

    _inviteMember(_clanId, _member);

    emit InviteSent(_clanId, _member, _playerId);
  }

  function inviteMembers(
    uint _clanId,
    uint[] calldata _memberPlayerIds,
    uint _playerId
  ) external isOwnerOfPlayer(_playerId) isMinimumRank(_clanId, _playerId, ClanRank.SCOUT) {
    Clan storage clan = clans[_clanId];
    Tier storage tier = tiers[clan.tierId];
    if (clan.memberCount + _memberPlayerIds.length > tier.maxMemberCapacity) {
      revert ClanIsFull();
    }

    for (uint i = 0; i < _memberPlayerIds.length; ++i) {
      _inviteMember(_clanId, _memberPlayerIds[i]);
    }
    emit InvitesSent(_clanId, _memberPlayerIds, _playerId);
  }

  function acceptInvite(uint _clanId, uint _playerId) external isOwnerOfPlayerAndActive(_playerId) {
    Clan storage clan = clans[_clanId];
    PlayerInfo storage player = playerInfo[_playerId];

    if (!clan.inviteRequests[_playerId]) {
      revert InviteDoesNotExist();
    }

    Tier storage tier = tiers[clan.tierId];
    if (clan.memberCount >= tier.maxMemberCapacity) {
      revert ClanIsFull();
    }

    clan.inviteRequests[_playerId] = false;
    clan.memberCount = uint16(clan.memberCount.inc());

    player.clanId = uint32(_clanId);
    player.rank = ClanRank.COMMONER;
    player.requestedClanId = 0;

    emit InviteAccepted(_clanId, _playerId);
  }

  function requestToJoin(uint _clanId, uint _playerId) external isOwnerOfPlayerAndActive(_playerId) {
    Clan storage clan = clans[_clanId];
    if (clan.createdTimestamp == 0) {
      revert ClanDoesNotExist();
    }

    PlayerInfo storage player = playerInfo[_playerId];

    if (isMemberOfAnyClan(_playerId)) {
      revert AlreadyInClan();
    }

    uint playerRequestedClanId = player.requestedClanId;
    if (playerRequestedClanId != 0) {
      if (playerRequestedClanId == _clanId) {
        revert AlreadySentJoinRequest();
      }
      emit JoinRequestRemoved(playerRequestedClanId, _playerId);
    }

    player.requestedClanId = uint32(_clanId);

    emit JoinRequestSent(_clanId, _playerId);
  }

  function removeJoinRequest(uint _clanId, uint _playerId) public isOwnerOfPlayer(_playerId) {
    playerInfo[_playerId].requestedClanId = 0;
    emit JoinRequestRemoved(_clanId, _playerId);
  }

  function _acceptJoinRequest(uint _clanId, uint _newMemberPlayedId) private {
    Clan storage clan = clans[_clanId];
    clan.inviteRequests[_newMemberPlayedId] = false;
    clan.memberCount = uint16(clan.memberCount.inc());

    PlayerInfo storage player = playerInfo[_newMemberPlayedId];
    if (player.requestedClanId != _clanId) {
      revert NoJoinRequest();
    }
    player.clanId = uint32(_clanId);
    player.requestedClanId = 0;
    player.rank = ClanRank.COMMONER;
  }

  function acceptJoinRequest(
    uint _clanId,
    uint _newMemberPlayedId,
    uint _playerId
  ) public isOwnerOfPlayerAndActive(_playerId) isMinimumRank(_clanId, _playerId, ClanRank.SCOUT) {
    Clan storage clan = clans[_clanId];
    Tier storage tier = tiers[clan.tierId];
    if (clan.memberCount >= tier.maxMemberCapacity) {
      revert ClanIsFull();
    }

    _acceptJoinRequest(_clanId, _newMemberPlayedId);

    emit JoinRequestAccepted(_clanId, _newMemberPlayedId, _playerId);
  }

  function acceptJoinRequests(
    uint _clanId,
    uint[] calldata _newMemberPlayedIds,
    uint _playerId
  ) public isOwnerOfPlayerAndActive(_playerId) isMinimumRank(_clanId, _playerId, ClanRank.SCOUT) {
    Clan storage clan = clans[_clanId];
    Tier storage tier = tiers[clan.tierId];
    if (clan.memberCount + _newMemberPlayedIds.length > tier.maxMemberCapacity) {
      revert ClanIsFull();
    }

    for (uint i = 0; i < _newMemberPlayedIds.length; ++i) {
      _acceptJoinRequest(_clanId, _newMemberPlayedIds[i]);
    }

    emit JoinRequestsAccepted(_clanId, _newMemberPlayedIds, _playerId);
  }

  function changeRank(
    uint _clanId,
    uint _memberId,
    ClanRank _rank,
    uint _playerId
  ) public isOwnerOfPlayer(_playerId) isMemberOfClan(_clanId, _memberId) {
    ClanRank currentMemberRank = playerInfo[_memberId].rank;
    ClanRank callerRank = playerInfo[_playerId].rank;
    bool changingSelf = _memberId == _playerId;

    if (callerRank <= _rank) {
      revert ChangingRankEqualOrHigherThanSelf();
    }

    // Cannot change Rank of someone higher or equal yourself
    if (changingSelf) {
      if (callerRank < currentMemberRank) {
        revert ChangingRankOfPlayerHigherThanSelf();
      }
    } else {
      if (callerRank <= currentMemberRank) {
        revert ChangingRankOfPlayerEqualOrHigherThanSelf();
      }
    }

    if (currentMemberRank == _rank) {
      revert CannotSetSameRank();
    }

    bool isDemoting = currentMemberRank > _rank;
    if (isDemoting) {
      // Are they leaving?
      if (_rank == ClanRank.NONE) {
        _removeFromClan(_clanId, _memberId);
      } else {
        // If owner is leaving their post then we need to update the owned state
        if (currentMemberRank == ClanRank.LEADER) {
          _ownerCleared(_clanId);
        }
        _updateRank(_clanId, _memberId, _rank, _playerId);
      }
    } else {
      // Promoting
      _updateRank(_clanId, _memberId, _rank, _playerId);
    }
  }

  function changeRanks(
    uint _clanId,
    uint[] calldata _memberIds,
    ClanRank[] calldata _ranks,
    uint _playerId
  ) external isOwnerOfPlayer(_playerId) {
    for (uint i = 0; i < _memberIds.length; ++i) {
      changeRank(_clanId, _memberIds[i], _ranks[i], _playerId);
    }
  }

  function renounceOwnershipTo(
    uint _clanId,
    uint _newOwner,
    ClanRank _newRank
  ) external isOwnerOfPlayer(clans[_clanId].owner) isMemberOfClan(_clanId, _newOwner) {
    Clan storage clan = clans[_clanId];
    uint oldOwnerId = clan.owner;

    if (_newOwner == oldOwnerId) {
      revert CannotRenounceToSelf();
    }

    if (_newRank != ClanRank.NONE) {
      if (_newRank >= ClanRank.LEADER) {
        revert RankMustBeLowerRenounce();
      }
      // Change old owner to new rank
      _updateRank(_clanId, oldOwnerId, _newRank, oldOwnerId);
    } else {
      _removeFromClan(_clanId, oldOwnerId);
    }
    _claimOwnership(_clanId, _newOwner);
  }

  // Can claim a clan if there is no owner
  function claimOwnership(
    uint _clanId,
    uint _playerId
  ) external isOwnerOfPlayer(_playerId) isMemberOfClan(_clanId, _playerId) {
    Clan storage clan = clans[_clanId];
    if (clan.owner != 0) {
      revert OwnerExists();
    }

    _claimOwnership(_clanId, _playerId);
  }

  function upgradeClan(uint _clanId, uint _playerId, uint8 _newTierId) public isOwnerOfPlayer(_playerId) {
    _upgradeClan(_clanId, _playerId, _newTierId);
  }

  function getClanNameOfPlayer(uint _playerId) external view returns (string memory) {
    uint clanId = playerInfo[_playerId].clanId;
    return clans[clanId].name;
  }

  function canWithdraw(uint _clanId, uint _playerId) external view override returns (bool) {
    return playerInfo[_playerId].clanId == _clanId && playerInfo[_playerId].rank >= ClanRank.TREASURER;
  }

  function isClanMember(uint _clanId, uint _playerId) external view returns (bool) {
    return playerInfo[_playerId].clanId == _clanId;
  }

  function isMemberOfAnyClan(uint _playerId) public view returns (bool) {
    return playerInfo[_playerId].clanId != 0;
  }

  function getClanTierMembership(uint _playerId) external view returns (uint8) {
    return clans[playerInfo[_playerId].clanId].tierId;
  }

  function hasInviteRequest(uint _clanId, uint _playerId) external view returns (bool) {
    return clans[_clanId].inviteRequests[_playerId];
  }

  function maxBankCapacity(uint _clanId) external view override returns (uint16) {
    Tier storage tier = tiers[clans[_clanId].tierId];
    return tier.maxBankCapacity;
  }

  function maxMemberCapacity(uint _clanId) external view override returns (uint16) {
    Tier storage tier = tiers[clans[_clanId].tierId];
    return tier.maxMemberCapacity;
  }

  function _checkClanImage(uint _imageId, uint _maxImageId) private pure {
    if (_imageId == 0 || _imageId > _maxImageId) {
      revert InvalidImageId();
    }
  }

  function _setName(uint _clanId, string calldata _name) private returns (string memory trimmedName, bool nameChanged) {
    // Trimmed name cannot be empty
    trimmedName = EstforLibrary.trim(_name);
    if (bytes(trimmedName).length < 3) {
      revert NameTooShort();
    }
    if (bytes(trimmedName).length > 20) {
      revert NameTooLong();
    }

    if (!EstforLibrary.containsValidNameCharacters(trimmedName)) {
      revert NameInvalidCharacters();
    }

    string memory trimmedAndLowercaseName = EstforLibrary.toLower(trimmedName);
    string memory oldName = EstforLibrary.toLower(clans[_clanId].name);
    nameChanged = keccak256(abi.encodePacked(oldName)) != keccak256(abi.encodePacked(trimmedAndLowercaseName));
    if (nameChanged) {
      if (lowercaseNames[trimmedAndLowercaseName]) {
        revert NameAlreadyExists();
      }
      if (bytes(oldName).length != 0) {
        delete lowercaseNames[oldName];
      }
      lowercaseNames[trimmedAndLowercaseName] = true;
      clans[_clanId].name = trimmedName;
    }
  }

  function _checkSocials(string calldata _discord, string calldata _telegram) private pure {
    uint discordLength = bytes(_discord).length;
    if (discordLength > 25) {
      revert DiscordTooLong();
    }

    if (discordLength != 0 && discordLength < 4) {
      revert DiscordTooShort();
    }

    if (!EstforLibrary.containsValidDiscordCharacters(_discord)) {
      revert DiscordInvalidCharacters();
    }

    uint telegramLength = bytes(_telegram).length;
    if (telegramLength > 25) {
      revert TelegramTooLong();
    }

    if (!EstforLibrary.containsValidTelegramCharacters(_telegram)) {
      revert TelegramInvalidCharacters();
    }
  }

  function _createClanInfo(
    string memory _trimmedName,
    string calldata _discord,
    string calldata _telegram
  ) private pure returns (string[] memory clanInfo) {
    clanInfo = new string[](3);
    clanInfo[0] = _trimmedName;
    clanInfo[1] = _discord;
    clanInfo[2] = _telegram;
  }

  function _ownerCleared(uint _clanId) private {
    uint oldOwnerId = clans[_clanId].owner;
    clans[_clanId].owner = 0;
    ownerlessClanTimestamps[_clanId] = uint40(block.timestamp);
    emit ClanOwnerLeft(_clanId, oldOwnerId);
  }

  function _updateRank(uint _clanId, uint _memberId, ClanRank _rank, uint _playerId) private {
    PlayerInfo storage player = playerInfo[_memberId];
    player.rank = _rank;
    emit PlayerRankUpdated(_clanId, _memberId, _rank, _playerId);
  }

  function _destroyClan(uint _clanId) private {
    if (clans[_clanId].memberCount != 0) {
      // Defensive check
      revert ClanDestroyFailedHasMembers();
    }
    lowercaseNames[EstforLibrary.toLower(clans[_clanId].name)] = false; // Name can be used again
    delete clans[_clanId]; // Delete the clan
    emit ClanDestroyed(_clanId);
  }

  function _removeFromClan(uint _clanId, uint _playerId) private {
    Clan storage clan = clans[_clanId];

    if (clan.owner == _playerId) {
      _ownerCleared(_clanId);
    }

    --clan.memberCount;
    if (clan.memberCount == 0) {
      _destroyClan(_clanId);
    } else {
      emit MemberLeft(_clanId, _playerId);
    }
    PlayerInfo storage player = playerInfo[_playerId];
    player.clanId = 0;
    player.rank = ClanRank.NONE;
  }

  function _claimOwnership(uint _clanId, uint _playerId) private {
    Clan storage clan = clans[_clanId];
    clan.owner = uint80(_playerId);
    delete ownerlessClanTimestamps[_clanId];
    playerInfo[_playerId].rank = ClanRank.LEADER;
    emit ClanOwnershipTransferred(_clanId, _playerId);
  }

  function _pay(uint _brushCost) private {
    // Pay
    brush.transferFrom(msg.sender, address(this), _brushCost);
    uint quarterCost = _brushCost / 4;
    // Send half to the pool (currently shop)
    brush.transfer(pool, _brushCost - quarterCost * 2);
    // Send 1 quarter to the dev address
    brush.transfer(dev, quarterCost);
    // Burn 1 quarter
    brush.burn(quarterCost);
  }

  function _upgradeClan(uint _clanId, uint _playerId, uint8 _newTierId) private {
    Tier storage oldTier = tiers[clans[_clanId].tierId];
    if (oldTier.id == 0) {
      revert ClanDoesNotExist();
    }

    if (_newTierId <= oldTier.id) {
      revert CannotDowngradeTier();
    }

    _checkTierExists(_newTierId);

    Tier storage newTier = tiers[_newTierId];
    uint priceDifference = newTier.price - oldTier.price;
    _pay(priceDifference);

    clans[_clanId].tierId = _newTierId; // Increase the tier
    emit ClanUpgraded(_clanId, _playerId, _newTierId);
  }

  function _setTier(Tier calldata _tier) private {
    uint tierId = _tier.id;
    // TODO: Some other checks

    // Price should be higher than the one prior
    if (tierId > 1) {
      if (_tier.price < tiers[tierId - 1].price) {
        revert PriceTooLow();
      }
      if (_tier.maxMemberCapacity < tiers[tierId - 1].maxMemberCapacity) {
        revert MemberCapacityTooLow();
      }
      if (_tier.maxBankCapacity < tiers[tierId - 1].maxBankCapacity) {
        revert BankCapacityTooLow();
      }
      if (_tier.maxImageId < tiers[tierId - 1].maxImageId) {
        revert ImageIdTooLow();
      }
    }
    tiers[tierId] = _tier;
  }

  function addTiers(Tier[] calldata _tiers) external onlyOwner {
    U256 bounds = _tiers.length.asU256();
    for (U256 iter; iter < bounds; iter = iter.inc()) {
      uint i = iter.asUint256();
      if (tiers[_tiers[i].id].id != 0 || _tiers[i].id == 0) {
        revert TierAlreadyExists();
      }
      _setTier(_tiers[i]);
    }
    emit AddTiers(_tiers);
  }

  function editTiers(Tier[] calldata _tiers) external onlyOwner {
    U256 bounds = _tiers.length.asU256();
    for (U256 iter; iter < bounds; iter = iter.inc()) {
      uint i = iter.asUint256();
      _checkTierExists(_tiers[i].id);
      _setTier(_tiers[i]);
    }
    emit EditTiers(_tiers);
  }

  function setBankFactory(IBankFactory _bankFactory) external onlyOwner {
    bankFactory = _bankFactory;
  }

  function setPlayers(IPlayers _players) external onlyOwner {
    players = _players;
  }

  function setEditNameCost(uint72 _editNameCost) external onlyOwner {
    editNameCost = _editNameCost;
    emit EditNameCost(_editNameCost);
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {UnsafeMath, U256} from "@0xdoublesharp/unsafe-math/contracts/UnsafeMath.sol";

import {IPlayers} from "./interfaces/IPlayers.sol";

// solhint-disable-next-line no-global-import
import "./globals/all.sol";

// This file contains methods for interacting with generic functions like trimming strings, lowercase etc.
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
      bool isPlus = char == 0x2B; // "+"
      if (!isUpperCaseLetter && !isLowerCaseLetter && !isDigit && !isPlus) {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Skill, Attire, CombatStyle, CombatStats} from "./misc.sol";
import {GuaranteedReward, RandomReward} from "./rewards.sol";

enum ActionQueueStatus {
  NONE,
  APPEND,
  KEEP_LAST_IN_PROGRESS
}

struct QueuedActionInput {
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

// This is only used as an input arg (and events)
struct Action {
  uint16 actionId;
  ActionInfo info;
  GuaranteedReward[] guaranteedRewards;
  RandomReward[] randomRewards;
  CombatStats combatStats;
}

struct ActionV1 {
  uint16 actionId;
  ActionInfoV1 info;
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
  uint8 worldLocation; // 0 is the main starting world
}

struct ActionInfoV1 {
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
pragma solidity ^0.8.20;

import "./actions.sol";
import "./items.sol";
import "./misc.sol";
import "./players.sol";
import "./rewards.sol";
import "./quests.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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

// Eggs
uint16 constant EGG_BASE = 12544;
uint16 constant SECRET_EGG_1 = EGG_BASE;
uint16 constant SECRET_EGG_2 = EGG_BASE + 1;
uint16 constant EGG_MAX = 12799;

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
pragma solidity ^0.8.20;

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
  FIREMAKING,
  AGILITY,
  ALCHEMY,
  RESERVED0,
  RESERVED1,
  RESERVED2,
  RESERVED3,
  RESERVED4,
  RESERVED5,
  RESERVED6,
  RESERVED7,
  RESERVED8,
  RESERVED9,
  RESERVED10,
  RESERVED11,
  RESERVED12,
  RESERVED13,
  RESERVED14,
  RESERVED15,
  RESERVED16,
  RESERVED17,
  RESERVED18,
  RESERVED19,
  RESERVED20,
  TRAVELLING // Helper Skill for travelling
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
pragma solidity ^0.8.20;

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
  Skill currentActionProcessedSkill3;
  uint24 currentActionProcessedXPGained3;
  uint8 worldLocation; // 0 is the main starting world
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
  uint16 value;
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
  uint40 agility;
  uint40 alchemy;
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
  Skill skill2; // Most likely health
  uint24 xpGained2;
  Skill skill3; // Could come
  uint24 xpGained3;
  // How much food is consumed in the current action so far
  uint16 foodConsumed;
  // How many base consumables are consumed in the current action so far
  uint16 baseInputItemsConsumedNum;
}

struct PendingQueuedActionProcessed {
  // XP gained during this session
  Skill[] skills;
  uint32[] xpGainedSkills;
  // Data for the current action which has been previously processed, this is used to store on the Player
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
  PastRandomRewardInfo[] producedPastRandomRewards;
  uint[] xpRewardItemTokenIds;
  uint[] xpRewardAmounts;
  uint[] dailyRewardItemTokenIds;
  uint[] dailyRewardAmounts;
  PendingQueuedActionProcessed processedData;
  bytes32 dailyRewardMask;
  QuestState quests;
  uint numPastRandomRewardInstancesToRemove;
  uint8 worldLocation;
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
pragma solidity ^0.8.20;

uint constant QUEST_PURSE_STRINGS = 5; // MAKE SURE THIS MATCHES definitions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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
  BoostType boostType; // Could be removed if necessary, just used as an optimization
  uint16 boostItemTokenId;
  uint24 elapsedTime;
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
bytes constant xpRewardBytes = hex"00000000000001F4000003E8000009C40000138800002710000075300000C350000186A00001D4C0000493E0000557300007A120000927C0000B71B0000DBBA0000F424000124F800016E360001B7740001E8480002625A0002932E0002DC6C0";

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBankFactory {
  function bankAddress(uint clanId) external view returns (address);

  function createdHere(address bank) external view returns (bool);

  function createBank(address from, uint clanId) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBrushToken is IERC20 {
  function burn(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IClans {
  function canWithdraw(uint _clanId, uint _playerId) external view returns (bool);

  function isClanMember(uint clanId, uint playerId) external view returns (bool);

  function maxBankCapacity(uint clanId) external view returns (uint16);

  function maxMemberCapacity(uint clanId) external view returns (uint16);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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

  function xp(uint playerId, Skill skill) external view returns (uint xp);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../globals/all.sol";

interface IPlayersMiscDelegateView {
  function claimableXPThresholdRewardsImpl(
    uint oldTotalXP,
    uint newTotalXP
  ) external view returns (uint[] memory itemTokenIds, uint[] memory amounts);

  function dailyClaimedRewardsImpl(uint playerId) external view returns (bool[7] memory claimed);

  function dailyRewardsViewImpl(
    uint _playerId
  ) external view returns (uint[] memory itemTokenIds, uint[] memory amounts, bytes32 dailyRewardMask);

  function processConsumablesView(
    address from,
    uint playerId,
    QueuedAction calldata queuedAction,
    ActionChoice calldata actionChoice,
    CombatStats memory combatStats,
    uint elapsedTime,
    uint startTime,
    PendingQueuedActionEquipmentState[] calldata pendingQueuedActionEquipmentStates,
    PendingQueuedActionProcessed calldata pendingQueuedActionProcessed
  )
    external
    view
    returns (
      Equipment[] memory consumedEquipments,
      Equipment memory producedEquipment,
      uint xpElapsedTime,
      bool died,
      uint16 foodConsumed,
      uint16 baseInputItemsConsumedNum
    );

  function getRandomRewards(
    uint playerId,
    uint40 skillStartTime,
    uint elapsedTime,
    uint numTickets,
    ActionRewards memory actionRewards,
    uint8 successPercent,
    uint8 fullAttireBonusRewardsPercent
  ) external view returns (uint[] memory ids, uint[] memory amounts, bool hasRandomWord);
}

interface IPlayersMiscDelegate {
  function handleDailyRewards(address from, uint playerId) external;
}

interface IPlayersProcessActionsDelegate {
  function processActions(address from, uint playerId) external;

  function processActionsAndSetState(uint playerId) external;
}

interface IPlayersRewardsDelegate {
  function claimRandomRewards(uint playerId, PendingQueuedActionProcessed memory pendingQueuedActionProcessed) external;
}

// External view functions that are in other implementation files
interface IPlayersRewardsDelegateView {
  function pendingQueuedActionStateImpl(
    address owner,
    uint playerId
  ) external view returns (PendingQueuedActionState memory pendingQueuedActionState);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IQuests {
  function newOracleRandomWords(uint[3] calldata randomWords) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC1155Upgradeable} from "./ozUpgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {UUPSUpgradeable} from "./ozUpgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "./ozUpgradeable/access/OwnableUpgradeable.sol";
import {IERC2981, IERC165} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

import {UnsafeMath, U256} from "@0xdoublesharp/unsafe-math/contracts/UnsafeMath.sol";
import {ItemNFTLibrary} from "./ItemNFTLibrary.sol";
import {IBrushToken} from "./interfaces/IBrushToken.sol";
import {IBankFactory} from "./interfaces/IBankFactory.sol";
import {World} from "./World.sol";
import {AdminAccess} from "./AdminAccess.sol";

// solhint-disable-next-line no-global-import
import "./globals/all.sol";

// The NFT contract contains data related to the items and who owns them
contract ItemNFT is ERC1155Upgradeable, UUPSUpgradeable, OwnableUpgradeable, IERC2981 {
  using UnsafeMath for U256;
  using UnsafeMath for uint256;
  using UnsafeMath for uint16;

  event AddItem(Item item, uint16 tokenId, string name);
  event AddItems(Item[] items, uint16[] tokenIds, string[] names);
  event EditItem(Item item, uint16 tokenId, string name);
  event EditItems(Item[] items, uint16[] tokenIds, string[] names);

  error IdTooHigh();
  error ItemNotTransferable();
  error InvalidChainId();
  error InvalidTokenId();
  error ItemAlreadyExists();
  error ItemDoesNotExist(uint16);
  error EquipmentPositionShouldNotChange();
  error OnlyForHardhat();
  error NotAllowedHardhat();
  error ERC1155ReceiverNotApproved();
  error NotPlayersOrShop();
  error NotAdminAndBeta();
  error LengthMismatch();

  World private world;
  bool private isBeta;
  string private baseURI;

  // How many of this item exist
  mapping(uint itemId => uint amount) public itemBalances;
  mapping(uint itemId => uint timestamp) public timestampFirstMint;

  address private players;
  address private shop;
  uint16 public numUniqueItems;

  // Royalties
  address private royaltyReceiver;
  uint8 private royaltyFee; // base 1000, highest is 25.5

  mapping(uint itemId => string tokenURI) private tokenURIs;
  mapping(uint itemId => CombatStats combatStats) private combatStats;
  mapping(uint itemId => Item item) private items;

  AdminAccess private adminAccess;
  IBankFactory private bankFactory;
  address private promotions;

  modifier onlyPlayersOrShopOrPromotions() {
    if (_msgSender() != players && _msgSender() != shop && _msgSender() != promotions) {
      revert NotPlayersOrShop();
    }
    _;
  }

  modifier isAdminAndBeta() {
    if (!(adminAccess.isAdmin(_msgSender()) && isBeta)) {
      revert NotAdminAndBeta();
    }
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    World _world,
    address _shop,
    address _royaltyReceiver,
    AdminAccess _adminAccess,
    string calldata _baseURI,
    bool _isBeta
  ) public initializer {
    __ERC1155_init("");
    __Ownable_init();
    __UUPSUpgradeable_init();
    world = _world;
    shop = _shop;
    baseURI = _baseURI;
    royaltyFee = 30; // 3%
    royaltyReceiver = _royaltyReceiver;
    adminAccess = _adminAccess;
    isBeta = _isBeta;
  }

  // Can't use Item[] array unfortunately as they don't support array casts
  function mintBatch(
    address _to,
    uint[] calldata _ids,
    uint[] calldata _amounts
  ) external onlyPlayersOrShopOrPromotions {
    _mintBatchItems(_to, _ids, _amounts);
  }

  function uri(uint _tokenId) public view virtual override returns (string memory) {
    if (!exists(_tokenId)) {
      revert ItemDoesNotExist(uint16(_tokenId));
    }
    return string(abi.encodePacked(baseURI, tokenURIs[_tokenId]));
  }

  function exists(uint _tokenId) public view returns (bool) {
    return items[_tokenId].exists;
  }

  function getItem(uint16 _tokenId) external view returns (Item memory) {
    return _getItem(_tokenId);
  }

  function getEquipPositionAndMinRequirement(
    uint16 _item
  ) external view returns (Skill skill, uint32 minXP, EquipPosition equipPosition) {
    (skill, minXP) = _getMinRequirement(_item);
    equipPosition = _getEquipPosition(_item);
  }

  function getMinRequirements(
    uint16[] calldata _tokenIds
  ) external view returns (Skill[] memory skills, uint32[] memory minXPs) {
    skills = new Skill[](_tokenIds.length);
    minXPs = new uint32[](_tokenIds.length);
    U256 tokenIdsLength = _tokenIds.length.asU256();
    for (U256 iter; iter < tokenIdsLength; iter = iter.inc()) {
      uint i = iter.asUint256();
      (skills[i], minXPs[i]) = _getMinRequirement(_tokenIds[i]);
    }
  }

  function getItems(uint16[] calldata _tokenIds) external view returns (Item[] memory _items) {
    U256 tokenIdsLength = _tokenIds.length.asU256();
    _items = new Item[](tokenIdsLength.asUint256());
    for (U256 iter; iter < tokenIdsLength; iter = iter.inc()) {
      uint i = iter.asUint256();
      _items[i] = _getItem(_tokenIds[i]);
    }
  }

  function getEquipPositions(
    uint16[] calldata _tokenIds
  ) external view returns (EquipPosition[] memory equipPositions) {
    U256 tokenIdsLength = _tokenIds.length.asU256();
    equipPositions = new EquipPosition[](tokenIdsLength.asUint256());
    for (U256 iter; iter < tokenIdsLength; iter = iter.inc()) {
      uint i = iter.asUint256();
      equipPositions[i] = _getEquipPosition(_tokenIds[i]);
    }
  }

  function _getMinRequirement(uint16 _tokenId) private view returns (Skill, uint32) {
    return (items[_tokenId].skill, items[_tokenId].minXP);
  }

  function _getEquipPosition(uint16 _tokenId) private view returns (EquipPosition) {
    if (!exists(_tokenId)) {
      revert ItemDoesNotExist(_tokenId);
    }
    return items[_tokenId].equipPosition;
  }

  function _premint(uint _tokenId, uint _amount) private returns (uint numNewUniqueItems) {
    if (_tokenId >= type(uint16).max) {
      revert IdTooHigh();
    }
    uint existingBalance = itemBalances[_tokenId];
    if (existingBalance == 0) {
      // Brand new item
      timestampFirstMint[_tokenId] = block.timestamp;
      numNewUniqueItems = numNewUniqueItems.inc();
    }
    itemBalances[_tokenId] = existingBalance + _amount;
  }

  function _mintItem(address _to, uint _tokenId, uint _amount) internal {
    uint newlyMintedItems = _premint(_tokenId, _amount);
    if (newlyMintedItems != 0) {
      numUniqueItems = uint16(numUniqueItems.inc());
    }
    _mint(_to, uint(_tokenId), _amount, "");
  }

  function _mintBatchItems(address _to, uint[] memory _tokenIds, uint[] memory _amounts) internal {
    U256 numNewItems;
    U256 tokenIdsLength = _tokenIds.length.asU256();
    for (U256 iter; iter < tokenIdsLength; iter = iter.inc()) {
      uint i = iter.asUint256();
      numNewItems = numNewItems.add(_premint(_tokenIds[i], _amounts[i]));
    }
    if (numNewItems.neq(0)) {
      numUniqueItems = uint16(numUniqueItems.add(numNewItems.asUint16()));
    }
    _mintBatch(_to, _tokenIds, _amounts, "");
  }

  function mint(address _to, uint _tokenId, uint _amount) external onlyPlayersOrShopOrPromotions {
    _mintItem(_to, _tokenId, _amount);
  }

  /**
   * @dev See {IERC1155-balanceOfBatch}. This implementation is not standard ERC1155, it's optimized for the single account case
   */
  function balanceOfs(address _account, uint16[] memory _ids) external view returns (uint[] memory batchBalances) {
    U256 iter = _ids.length.asU256();
    batchBalances = new uint[](iter.asUint256());
    while (iter.neq(0)) {
      iter = iter.dec();
      uint i = iter.asUint256();
      batchBalances[i] = balanceOf(_account, _ids[i]);
    }
  }

  function burnBatch(address _from, uint[] calldata _tokenIds, uint[] calldata _amounts) external {
    _checkBurn(_from);
    _burnBatch(_from, _tokenIds, _amounts);
  }

  function burn(address _from, uint _tokenId, uint _amount) external {
    _checkBurn(_from);
    _burn(_from, _tokenId, _amount);
  }

  function royaltyInfo(
    uint /*_tokenId*/,
    uint _salePrice
  ) external view override returns (address receiver, uint royaltyAmount) {
    uint amount = (_salePrice * royaltyFee) / 1000;
    return (royaltyReceiver, amount);
  }

  function _getItem(uint16 _tokenId) private view returns (Item storage) {
    if (!exists(_tokenId)) {
      revert ItemDoesNotExist(_tokenId);
    }
    return items[_tokenId];
  }

  // If an item is burnt, remove it from the total
  function _removeAnyBurntFromTotal(uint[] memory _ids, uint[] memory _amounts) private {
    U256 iter = _ids.length.asU256();
    while (iter.neq(0)) {
      iter = iter.dec();
      uint i = iter.asUint256();
      uint newBalance = itemBalances[_ids[i]] - _amounts[i];
      if (newBalance == 0) {
        numUniqueItems = uint16(numUniqueItems.dec());
      }
      itemBalances[_ids[i]] = newBalance;
    }
  }

  function _checkIsTransferable(address _from, uint[] memory _ids) private view {
    U256 iter = _ids.length.asU256();
    bool anyNonTransferable;
    while (iter.neq(0)) {
      iter = iter.dec();
      uint i = iter.asUint256();
      if (exists(_ids[i]) && !items[_ids[i]].isTransferable) {
        anyNonTransferable = true;
      }
    }

    if (anyNonTransferable && (address(bankFactory) == address(0) || !bankFactory.createdHere(_from))) {
      // Check if this is from a bank, that's the only place it's allowed to withdraw non-transferable items
      revert ItemNotTransferable();
    }
  }

  function _beforeTokenTransfer(
    address /*_operator*/,
    address _from,
    address _to,
    uint[] memory _ids,
    uint[] memory _amounts,
    bytes memory /*_data*/
  ) internal virtual override {
    if (_from == address(0) || _amounts.length == 0 || _from == _to) {
      // When minting or self sending, then no further processing is required
      return;
    }

    bool isBurnt = _to == address(0) || _to == 0x000000000000000000000000000000000000dEaD;
    if (isBurnt) {
      _removeAnyBurntFromTotal(_ids, _amounts);
    } else {
      _checkIsTransferable(_from, _ids);
    }
    if (players == address(0)) {
      if (block.chainid != 31337) {
        revert InvalidChainId();
      }
    }
  }

  function _setItem(InputItem calldata _item) private returns (Item storage item) {
    if (_item.tokenId == 0) {
      revert InvalidTokenId();
    }
    ItemNFTLibrary.setItem(_item, items[_item.tokenId]);
    item = items[_item.tokenId];
    tokenURIs[_item.tokenId] = _item.metadataURI;
  }

  function _checkBurn(address _from) private view {
    if (
      _from != _msgSender() && !isApprovedForAll(_from, _msgSender()) && players != _msgSender() && shop != _msgSender()
    ) {
      revert ERC1155ReceiverNotApproved();
    }
  }

  function getBoostInfo(uint16 _tokenId) external view returns (uint16 boostValue, uint24 boostDuration) {
    Item storage item = _getItem(_tokenId);
    return (item.boostValue, item.boostDuration);
  }

  function supportsInterface(bytes4 interfaceId) public view override(IERC165, ERC1155Upgradeable) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  function name() external view returns (string memory) {
    return string(abi.encodePacked("Estfor Items", isBeta ? " (Beta)" : ""));
  }

  function symbol() external view returns (string memory) {
    return string(abi.encodePacked("EK_I", isBeta ? "B" : ""));
  }

  // Or make it constants and redeploy the contracts
  function addItem(InputItem calldata _inputItem) external onlyOwner {
    if (exists(_inputItem.tokenId)) {
      revert ItemAlreadyExists();
    }
    Item storage item = _setItem(_inputItem);
    emit AddItem(item, _inputItem.tokenId, _inputItem.name);
  }

  function addItems(InputItem[] calldata _inputItems) external onlyOwner {
    U256 iter = _inputItems.length.asU256();
    Item[] memory _items = new Item[](iter.asUint256());
    uint16[] memory tokenIds = new uint16[](iter.asUint256());
    string[] memory names = new string[](iter.asUint256());
    while (iter.neq(0)) {
      iter = iter.dec();
      uint i = iter.asUint256();
      if (exists(_inputItems[i].tokenId)) {
        revert ItemAlreadyExists();
      }
      _items[i] = _setItem(_inputItems[i]);
      tokenIds[i] = _inputItems[i].tokenId;
      names[i] = _inputItems[i].name;
    }
    emit AddItems(_items, tokenIds, names);
  }

  function _editItem(InputItem calldata _inputItem) private returns (Item storage item) {
    if (!exists(_inputItem.tokenId)) {
      revert ItemDoesNotExist(_inputItem.tokenId);
    }
    if (
      items[_inputItem.tokenId].equipPosition != _inputItem.equipPosition &&
      items[_inputItem.tokenId].equipPosition != EquipPosition.NONE
    ) {
      revert EquipmentPositionShouldNotChange();
    }
    item = _setItem(_inputItem);
  }

  function editItem(InputItem calldata _inputItem) external onlyOwner {
    Item storage item = _editItem(_inputItem);
    emit EditItem(item, _inputItem.tokenId, _inputItem.name);
  }

  function editItems(InputItem[] calldata _inputItems) external onlyOwner {
    Item[] memory _items = new Item[](_inputItems.length);
    uint16[] memory tokenIds = new uint16[](_inputItems.length);
    string[] memory names = new string[](_inputItems.length);

    for (uint i = 0; i < _inputItems.length; ++i) {
      _items[i] = _editItem(_inputItems[i]);
      tokenIds[i] = _inputItems[i].tokenId;
      names[i] = _inputItems[i].name;
    }

    emit EditItems(_items, tokenIds, names);
  }

  function setPlayers(address _players) external onlyOwner {
    players = _players;
  }

  function setBankFactory(IBankFactory _bankFactory) external onlyOwner {
    bankFactory = _bankFactory;
  }

  function setPromotions(address _promotions) external onlyOwner {
    promotions = _promotions;
  }

  function setBaseURI(string calldata _baseURI) external onlyOwner {
    baseURI = _baseURI;
  }

  // solhint-disable-next-line no-empty-blocks
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  function testMint(address _to, uint _tokenId, uint _amount) external isAdminAndBeta {
    _mintItem(_to, _tokenId, _amount);
  }

  function testMints(address _to, uint[] calldata _tokenIds, uint[] calldata _amounts) external isAdminAndBeta {
    _mintBatchItems(_to, _tokenIds, _amounts);
  }

  function airdrop(address[] calldata _tos, uint _tokenId, uint[] calldata _amounts) external onlyOwner {
    if (_tos.length != _amounts.length) {
      revert LengthMismatch();
    }
    for (uint i = 0; i < _tos.length; ++i) {
      _mintItem(_tos[i], _tokenId, _amounts[i]);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// solhint-disable-next-line no-global-import
import "./globals/players.sol";

// This file contains methods for interacting with the item NFT, used to decrease implementation deployment bytecode code.
library ItemNFTLibrary {
  function setItem(InputItem calldata _inputItem, Item storage _item) external {
    bool hasCombat;
    CombatStats calldata _combatStats = _inputItem.combatStats;
    assembly ("memory-safe") {
      hasCombat := not(iszero(_combatStats))
    }
    _item.equipPosition = _inputItem.equipPosition;
    _item.isTransferable = _inputItem.isTransferable;
    _item.exists = true;

    if (hasCombat) {
      // Combat stats
      _item.melee = _inputItem.combatStats.melee;
      _item.magic = _inputItem.combatStats.magic;
      _item.range = _inputItem.combatStats.range;
      _item.meleeDefence = _inputItem.combatStats.meleeDefence;
      _item.magicDefence = _inputItem.combatStats.magicDefence;
      _item.rangeDefence = _inputItem.combatStats.rangeDefence;
      _item.health = _inputItem.combatStats.health;
    }

    if (_inputItem.healthRestored != 0) {
      _item.healthRestored = _inputItem.healthRestored;
    }

    if (_inputItem.boostType != BoostType.NONE) {
      _item.boostType = _inputItem.boostType;
      _item.boostValue = _inputItem.boostValue;
      _item.boostDuration = _inputItem.boostDuration;
    }

    _item.minXP = _inputItem.minXP;
    _item.skill = _inputItem.skill;
  }
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.20;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
  // Booleans are more expensive than uint256 or any type that takes up a full
  // word because each write operation emits an extra SLOAD to first read the
  // slot's contents, replace the bits taken up by the boolean, and then write
  // back. This is the compiler's defense against contract upgrades and
  // pointer aliasing, and it cannot be disabled.

  // The values being non-zero value makes deployment a bit more expensive,
  // but in exchange the refund on every call to nonReentrant will be lower in
  // amount. Since refunds are capped to a percentage of the total
  // transaction's gas, it is best to keep them low in cases like this one, to
  // increase the likelihood of the full refund coming into effect.
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  error ReentrantCall();

  function __ReentrancyGuard_init() internal onlyInitializing {
    __ReentrancyGuard_init_unchained();
  }

  function __ReentrancyGuard_init_unchained() internal onlyInitializing {
    _status = _NOT_ENTERED;
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and making it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant() {
    _nonReentrantBefore();
    _;
    _nonReentrantAfter();
  }

  function _nonReentrantBefore() private {
    // On the first call to nonReentrant, _status will be _NOT_ENTERED
    if (_status == _ENTERED) {
      revert ReentrantCall();
    }

    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;
  }

  function _nonReentrantAfter() private {
    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is
  Initializable,
  ContextUpgradeable,
  ERC165Upgradeable,
  IERC1155Upgradeable,
  IERC1155MetadataURIUpgradeable
{
  using AddressUpgradeable for address;

  error ERC1155TransferToNonERC1155Receiver();
  error ERC1155ReceiverRejectedTokens();
  error ERC1155SettingApprovalStatusForSelf();
  error ERC115BurnFromZeroAddress();
  error ERC1155LengthMismatch();
  error ERC115BurnAmountExceedsBalance();
  error ERC1155MintToZeroAddress();
  error ERC1155TransferToZeroAddress();
  error ERC1155InsufficientBalance();
  error ERC1155TransferFromNotApproved();
  error ERC1155ZeroAddressNotValidOwner();

  // Mapping from token ID to account balances
  mapping(uint256 => mapping(address => uint256)) private _balances;

  // Mapping from account to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
  string private _uri;

  /**
   * @dev See {_setURI}.
   */
  function __ERC1155_init(string memory uri_) internal onlyInitializing {
    __ERC1155_init_unchained(uri_);
  }

  function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
    _setURI(uri_);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
    return
      interfaceId == type(IERC1155Upgradeable).interfaceId ||
      interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC1155MetadataURI-uri}.
   *
   * This implementation returns the same URI for *all* token types. It relies
   * on the token type ID substitution mechanism
   * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
   *
   * Clients calling this function must replace the `\{id\}` substring with the
   * actual token type ID.
   */
  function uri(uint256) public view virtual override returns (string memory) {
    return _uri;
  }

  /**
   * @dev See {IERC1155-balanceOf}.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
    if (account == address(0)) {
      revert ERC1155ZeroAddressNotValidOwner();
    }
    return _balances[id][account];
  }

  /**
   * @dev See {IERC1155-balanceOfBatch}.
   *
   * Requirements:
   *
   * - `accounts` and `ids` must have the same length.
   */
  function balanceOfBatch(
    address[] memory accounts,
    uint256[] memory ids
  ) public view virtual override returns (uint256[] memory) {
    if (accounts.length != ids.length) {
      revert ERC1155LengthMismatch();
    }

    uint256[] memory batchBalances = new uint256[](accounts.length);

    for (uint256 i = 0; i < accounts.length; ++i) {
      batchBalances[i] = balanceOf(accounts[i], ids[i]);
    }

    return batchBalances;
  }

  /**
   * @dev See {IERC1155-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public virtual override {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC1155-isApprovedForAll}.
   */
  function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
    return _operatorApprovals[account][operator];
  }

  /**
   * @dev See {IERC1155-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual override {
    if (from != _msgSender() && !isApprovedForAll(from, _msgSender())) {
      revert ERC1155TransferFromNotApproved();
    }
    _safeTransferFrom(from, to, id, amount, data);
  }

  /**
   * @dev See {IERC1155-safeBatchTransferFrom}.
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual override {
    if (from != _msgSender() && !isApprovedForAll(from, _msgSender())) {
      revert ERC1155TransferFromNotApproved();
    }
    _safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  /**
   * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
   *
   * Emits a {TransferSingle} event.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `from` must have a balance of tokens of type `id` of at least `amount`.
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
   * acceptance magic value.
   */
  function _safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
    if (to == address(0)) {
      revert ERC1155TransferToZeroAddress();
    }

    address operator = _msgSender();
    uint256[] memory ids = _asSingletonArray(id);
    uint256[] memory amounts = _asSingletonArray(amount);

    _beforeTokenTransfer(operator, from, to, ids, amounts, data);

    uint256 fromBalance = _balances[id][from];
    if (fromBalance < amount) {
      revert ERC1155InsufficientBalance();
    }
    unchecked {
      _balances[id][from] = fromBalance - amount;
    }
    _balances[id][to] += amount;

    emit TransferSingle(operator, from, to, id, amount);

    _afterTokenTransfer(operator, from, to, ids, amounts, data);

    _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
  }

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
   *
   * Emits a {TransferBatch} event.
   *
   * Requirements:
   *
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
   * acceptance magic value.
   */
  function _safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {
    if (ids.length != amounts.length) {
      revert ERC1155LengthMismatch();
    }
    if (to == address(0)) {
      revert ERC1155TransferToZeroAddress();
    }

    address operator = _msgSender();

    _beforeTokenTransfer(operator, from, to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; ++i) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      uint256 fromBalance = _balances[id][from];
      if (fromBalance < amount) {
        revert ERC1155InsufficientBalance();
      }
      unchecked {
        _balances[id][from] = fromBalance - amount;
      }
      _balances[id][to] += amount;
    }

    emit TransferBatch(operator, from, to, ids, amounts);

    _afterTokenTransfer(operator, from, to, ids, amounts, data);

    _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
  }

  /**
   * @dev Sets a new URI for all token types, by relying on the token type ID
   * substitution mechanism
   * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
   *
   * By this mechanism, any occurrence of the `\{id\}` substring in either the
   * URI or any of the amounts in the JSON file at said URI will be replaced by
   * clients with the token type ID.
   *
   * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
   * interpreted by clients as
   * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
   * for token type ID 0x4cce0.
   *
   * See {uri}.
   *
   * Because these URIs cannot be meaningfully represented by the {URI} event,
   * this function emits no events.
   */
  function _setURI(string memory newuri) internal virtual {
    _uri = newuri;
  }

  /**
   * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
   *
   * Emits a {TransferSingle} event.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
   * acceptance magic value.
   */
  function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
    if (to == address(0)) {
      revert ERC1155MintToZeroAddress();
    }

    address operator = _msgSender();
    uint256[] memory ids = _asSingletonArray(id);
    uint256[] memory amounts = _asSingletonArray(amount);

    _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

    _balances[id][to] += amount;
    emit TransferSingle(operator, address(0), to, id, amount);

    _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

    _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
  }

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
   *
   * Emits a {TransferBatch} event.
   *
   * Requirements:
   *
   * - `ids` and `amounts` must have the same length.
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
   * acceptance magic value.
   */
  function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
    if (to == address(0)) {
      revert ERC1155MintToZeroAddress();
    }
    if (ids.length != amounts.length) {
      revert ERC1155LengthMismatch();
    }

    address operator = _msgSender();

    _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; i++) {
      _balances[ids[i]][to] += amounts[i];
    }

    emit TransferBatch(operator, address(0), to, ids, amounts);

    _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

    _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
  }

  /**
   * @dev Destroys `amount` tokens of token type `id` from `from`
   *
   * Emits a {TransferSingle} event.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `from` must have at least `amount` tokens of token type `id`.
   */
  function _burn(address from, uint256 id, uint256 amount) internal virtual {
    if (from == address(0)) {
      revert ERC115BurnFromZeroAddress();
    }

    address operator = _msgSender();
    uint256[] memory ids = _asSingletonArray(id);
    uint256[] memory amounts = _asSingletonArray(amount);

    _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

    uint256 fromBalance = _balances[id][from];
    if (fromBalance < amount) {
      revert ERC115BurnAmountExceedsBalance();
    }
    unchecked {
      _balances[id][from] = fromBalance - amount;
    }

    emit TransferSingle(operator, from, address(0), id, amount);

    _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
  }

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
   *
   * Emits a {TransferBatch} event.
   *
   * Requirements:
   *
   * - `ids` and `amounts` must have the same length.
   */
  function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal virtual {
    if (from == address(0)) {
      revert ERC115BurnFromZeroAddress();
    }
    if (ids.length != amounts.length) {
      revert ERC1155LengthMismatch();
    }

    address operator = _msgSender();

    _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

    for (uint256 i = 0; i < ids.length; i++) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      uint256 fromBalance = _balances[id][from];
      if (fromBalance < amount) {
        revert ERC115BurnAmountExceedsBalance();
      }
      unchecked {
        _balances[id][from] = fromBalance - amount;
      }
    }

    emit TransferBatch(operator, from, address(0), ids, amounts);

    _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
  }

  /**
   * @dev Approve `operator` to operate on all of `owner` tokens
   *
   * Emits an {ApprovalForAll} event.
   */
  function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
    if (owner == operator) {
      revert ERC1155SettingApprovalStatusForSelf();
    }
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning, as well as batched variants.
   *
   * The same hook is called on both single and batched variants. For single
   * transfers, the length of the `ids` and `amounts` arrays will be 1.
   *
   * Calling conditions (for each `id` and `amount` pair):
   *
   * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * of token type `id` will be  transferred to `to`.
   * - When `from` is zero, `amount` tokens of token type `id` will be minted
   * for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
   * will be burned.
   * - `from` and `to` are never both zero.
   * - `ids` and `amounts` have the same, non-zero length.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {}

  /**
   * @dev Hook that is called after any token transfer. This includes minting
   * and burning, as well as batched variants.
   *
   * The same hook is called on both single and batched variants. For single
   * transfers, the length of the `id` and `amount` arrays will be 1.
   *
   * Calling conditions (for each `id` and `amount` pair):
   *
   * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * of token type `id` will be  transferred to `to`.
   * - When `from` is zero, `amount` tokens of token type `id` will be minted
   * for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
   * will be burned.
   * - `from` and `to` are never both zero.
   * - `ids` and `amounts` have the same, non-zero length.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _afterTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {}

  function _doSafeTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) private {
    if (to.isContract()) {
      try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (
        bytes4 response
      ) {
        if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
          revert ERC1155ReceiverRejectedTokens();
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert ERC1155TransferToNonERC1155Receiver();
      }
    }
  }

  function _doSafeBatchTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) private {
    if (to.isContract()) {
      try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
        bytes4 response
      ) {
        if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
          revert ERC1155ReceiverRejectedTokens();
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert ERC1155TransferToNonERC1155Receiver();
      }
    }
  }

  function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = element;

    return array;
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[47] private __gap;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
  function __ERC165_init() internal onlyInitializing {}

  function __ERC165_init_unchained() internal onlyInitializing {}

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC165Upgradeable).interfaceId;
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC1155Upgradeable} from "./ozUpgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {UUPSUpgradeable} from "./ozUpgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "./ozUpgradeable/access/OwnableUpgradeable.sol";
import {IERC2981, IERC165} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

import {UnsafeMath, U256} from "@0xdoublesharp/unsafe-math/contracts/UnsafeMath.sol";

import {EstforLibrary} from "./EstforLibrary.sol";
import {IBrushToken} from "./interfaces/IBrushToken.sol";
import {IPlayers} from "./interfaces/IPlayers.sol";
import {AdminAccess} from "./AdminAccess.sol";

// solhint-disable-next-line no-global-import
import "./globals/all.sol";

// Each NFT represents a player. This contract deals with the NFTs, and the Players contract deals with the player data
contract PlayerNFT is ERC1155Upgradeable, UUPSUpgradeable, OwnableUpgradeable, IERC2981 {
  using UnsafeMath for U256;
  using UnsafeMath for uint256;

  event NewPlayer(uint playerId, uint avatarId, string name);
  event EditPlayer(uint playerId, string newName);
  event EditNameCost(uint newCost);
  event SetAvatars(uint startAvatarId, AvatarInfo[] avatarInfos);

  error NotOwnerOfPlayer();
  error NotAdmin();
  error NotAdminOrLive();
  error NotPlayers();
  error AvatarNotExists();
  error NameTooShort();
  error NameTooLong(uint length, string name, string name1);
  error NameAlreadyExists();
  error NameInvalidCharacters();
  error MintedMoreThanAllowed();
  error NotInWhitelist();
  error ERC1155Metadata_URIQueryForNonexistentToken();
  error ERC1155BurnForbidden();

  uint private nextPlayerId;

  mapping(uint avatarId => AvatarInfo avatarInfo) public avatars;
  string public imageBaseUri;
  mapping(uint playerId => uint avatar) public playerIdToAvatar;
  mapping(uint playerId => string name) public names;
  mapping(string name => bool exists) public lowercaseNames;

  IBrushToken private brush;
  IPlayers private players;
  address private pool;

  address private royaltyReceiver;
  uint8 private royaltyFee; // base 1000, highest is 25.5
  uint72 public editNameCost; // Max is 4700 BRUSH
  bool public isBeta;

  address private dev;

  bytes32 private merkleRoot; // Unused now (was for alpha/beta whitelisting)
  mapping(address whitelistedUser => uint amount) public numMintedFromWhitelist; // Unused now
  AdminAccess private adminAccess;

  modifier isOwnerOfPlayer(uint playerId) {
    if (balanceOf(_msgSender(), playerId) != 1) {
      revert NotOwnerOfPlayer();
    }
    _;
  }

  modifier onlyPlayers() {
    if (_msgSender() != address(players)) {
      revert NotPlayers();
    }
    _;
  }

  modifier isAdmin() {
    if (!adminAccess.isAdmin(_msgSender())) {
      revert NotAdmin();
    }
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    IBrushToken _brush,
    address _pool,
    address _dev,
    address _royaltyReceiver,
    AdminAccess _adminAccess,
    uint72 _editNameCost,
    string calldata _imageBaseUri,
    bool _isBeta
  ) public initializer {
    __ERC1155_init("");
    __Ownable_init();
    __UUPSUpgradeable_init();
    brush = _brush;
    nextPlayerId = 1;
    imageBaseUri = _imageBaseUri;
    pool = _pool;
    dev = _dev;
    editNameCost = _editNameCost;
    royaltyFee = 30; // 3%
    royaltyReceiver = _royaltyReceiver;
    adminAccess = _adminAccess;
    isBeta = _isBeta;

    emit EditNameCost(_editNameCost);
  }

  function _mintStartingItems(address _from, uint _playerId, uint _avatarId, bool _makeActive) private {
    // Give the player some starting items
    uint[] memory itemTokenIds = new uint[](6);
    itemTokenIds[0] = BRONZE_SWORD;
    itemTokenIds[1] = BRONZE_AXE;
    itemTokenIds[2] = MAGIC_FIRE_STARTER;
    itemTokenIds[3] = NET_STICK;
    itemTokenIds[4] = BRONZE_PICKAXE;
    itemTokenIds[5] = TOTEM_STAFF;

    uint[] memory amounts = new uint[](6);
    amounts[0] = 1;
    amounts[1] = 1;
    amounts[2] = 1;
    amounts[3] = 1;
    amounts[4] = 1;
    amounts[5] = 1;
    players.mintedPlayer(_from, _playerId, avatars[_avatarId].startSkills, _makeActive, itemTokenIds, amounts);
  }

  function _setName(uint _playerId, string calldata _name) private returns (string memory trimmedName) {
    // Trimmed name cannot be empty
    trimmedName = EstforLibrary.trim(_name);
    if (bytes(trimmedName).length < 3) {
      revert NameTooShort();
    }
    if (bytes(trimmedName).length > 20) {
      revert NameTooLong(bytes(trimmedName).length, _name, trimmedName);
    }

    if (!EstforLibrary.containsValidNameCharacters(trimmedName)) {
      revert NameInvalidCharacters();
    }

    string memory trimmedAndLowercaseName = EstforLibrary.toLower(trimmedName);
    string memory oldName = EstforLibrary.toLower(names[_playerId]);
    bool nameChanged = keccak256(abi.encodePacked(oldName)) != keccak256(abi.encodePacked(trimmedAndLowercaseName));
    if (nameChanged) {
      if (lowercaseNames[trimmedAndLowercaseName]) {
        revert NameAlreadyExists();
      }
      if (bytes(oldName).length != 0) {
        delete lowercaseNames[oldName];
      }
      lowercaseNames[trimmedAndLowercaseName] = true;
      names[_playerId] = trimmedName;
    }
  }

  function _mintPlayer(uint _avatarId, string calldata _name, bool _makeActive) private {
    address from = _msgSender();
    uint playerId = nextPlayerId;
    nextPlayerId = nextPlayerId.inc();
    string memory trimmedName = _setName(playerId, _name);
    emit NewPlayer(playerId, _avatarId, trimmedName);
    _mint(from, playerId, 1, "");
    _mintStartingItems(from, playerId, _avatarId, _makeActive);
    _setTokenIdToAvatar(playerId, _avatarId);
  }

  function mint(uint _avatarId, string calldata _name, bool _makeActive) external {
    _mintPlayer(_avatarId, _name, _makeActive);
  }

  function _setTokenIdToAvatar(uint _playerId, uint _avatarId) private {
    if (bytes(avatars[_avatarId].description).length == 0) {
      revert AvatarNotExists();
    }
    playerIdToAvatar[_playerId] = _avatarId;
  }

  function uri(uint256 _playerId) public view virtual override returns (string memory) {
    if (!_exists(_playerId)) {
      revert ERC1155Metadata_URIQueryForNonexistentToken();
    }
    AvatarInfo storage avatarInfo = avatars[playerIdToAvatar[_playerId]];
    string memory imageURI = string(abi.encodePacked(imageBaseUri, avatarInfo.imageURI));
    return players.getURI(_playerId, names[_playerId], avatarInfo.name, avatarInfo.description, imageURI);
  }

  function _beforeTokenTransfer(
    address /*operator*/,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory /*data*/
  ) internal virtual override {
    if (from == address(0) || amounts.length == 0 || from == to) {
      return;
    }
    U256 iter = ids.length.asU256();
    while (iter.neq(0)) {
      iter = iter.dec();
      uint i = iter.asUint256();
      uint playerId = ids[i];
      players.clearEverythingBeforeTokenTransfer(from, playerId);
      if (to == address(0) || to == 0x000000000000000000000000000000000000dEaD) {
        // Burning
        string memory oldName = EstforLibrary.toLower(names[playerId]);
        delete lowercaseNames[oldName];
      }
    }
  }

  /**
   * @dev Returns whether `playerId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {setApprovalForAll}.
   *
   */
  function _exists(uint256 _playerId) private view returns (bool) {
    return playerIdToAvatar[_playerId] != 0;
  }

  function editName(uint _playerId, string calldata _newName) external isOwnerOfPlayer(_playerId) {
    uint brushCost = editNameCost;
    // Pay
    brush.transferFrom(_msgSender(), address(this), brushCost);
    uint quarterCost = brushCost / 4;
    // Send half to the pool (currently shop)
    brush.transfer(pool, brushCost - quarterCost * 2);
    // Send 1 quarter to the dev address
    brush.transfer(dev, quarterCost);
    // Burn 1 quarter
    brush.burn(quarterCost);

    string memory trimmedName = _setName(_playerId, _newName);
    emit EditPlayer(_playerId, trimmedName);
  }

  /**
   * @dev See {IERC1155-balanceOfBatch}. This implementation is not standard ERC1155, it's optimized for the single account case
   */
  function balanceOfs(address _account, uint16[] memory _ids) external view returns (uint256[] memory batchBalances) {
    U256 iter = _ids.length.asU256();
    batchBalances = new uint256[](iter.asUint256());
    while (iter.neq(0)) {
      iter = iter.dec();
      uint i = iter.asUint256();
      batchBalances[i] = balanceOf(_account, _ids[i]);
    }
  }

  function burn(address _from, uint _playerId) external {
    if (_from != _msgSender() && !isApprovedForAll(_from, _msgSender())) {
      revert ERC1155BurnForbidden();
    }
    _burn(_from, _playerId, 1);
  }

  function royaltyInfo(
    uint256 /*_tokenId*/,
    uint256 _salePrice
  ) external view override returns (address receiver, uint256 royaltyAmount) {
    uint256 amount = (_salePrice * royaltyFee) / 1000;
    return (royaltyReceiver, amount);
  }

  function supportsInterface(bytes4 interfaceId) public view override(IERC165, ERC1155Upgradeable) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  function name() external view returns (string memory) {
    return string(abi.encodePacked("Estfor Players", isBeta ? " (Beta)" : ""));
  }

  function symbol() external view returns (string memory) {
    return string(abi.encodePacked("EK_P", isBeta ? "B" : ""));
  }

  function setAvatars(uint _startAvatarId, AvatarInfo[] calldata _avatarInfos) external onlyOwner {
    U256 iter = _avatarInfos.length.asU256();
    while (iter.neq(0)) {
      iter = iter.dec();
      uint i = iter.asUint256();
      avatars[_startAvatarId.add(i)] = _avatarInfos[i];
    }
    emit SetAvatars(_startAvatarId, _avatarInfos);
  }

  function setImageBaseUri(string calldata _imageBaseUri) external onlyOwner {
    imageBaseUri = _imageBaseUri;
  }

  function setPlayers(IPlayers _players) external onlyOwner {
    players = _players;
  }

  function setEditNameCost(uint72 _editNameCost) external onlyOwner {
    editNameCost = _editNameCost;
    emit EditNameCost(_editNameCost);
  }

  // solhint-disable-next-line no-empty-blocks
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UUPSUpgradeable} from "../ozUpgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "../ozUpgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "../ozUpgradeable/security/ReentrancyGuardUpgradeable.sol";

import {UnsafeMath, U256} from "@0xdoublesharp/unsafe-math/contracts/UnsafeMath.sol";

import {World} from "../World.sol";
import {ItemNFT} from "../ItemNFT.sol";
import {AdminAccess} from "../AdminAccess.sol";
import {Quests} from "../Quests.sol";
import {Clans} from "../Clans/Clans.sol";
import {PlayerNFT} from "../PlayerNFT.sol";
import {PlayersBase} from "./PlayersBase.sol";
import {PlayersLibrary} from "./PlayersLibrary.sol";
import {IPlayers} from "../interfaces/IPlayers.sol";
import {IPlayersMiscDelegateView, IPlayersRewardsDelegateView, IPlayersProcessActionsDelegate} from "../interfaces/IPlayersDelegates.sol";

// solhint-disable-next-line no-global-import
import "../globals/all.sol";

// Functions to help with delegatecall selectors
interface IPlayerDelegate {
  function startActions(
    uint playerId,
    QueuedActionInput[] calldata queuedActions,
    uint16 boostItemTokenId,
    uint40 boostStartTime,
    uint questId,
    ActionQueueStatus queueStatus
  ) external;

  function addXPThresholdRewards(XPThresholdReward[] calldata xpThresholdReward) external;

  function addFullAttireBonuses(FullAttireBonusInput[] calldata fullAttireBonuses) external;

  function mintedPlayer(
    address from,
    uint playerId,
    Skill[2] calldata startSkills,
    uint[] calldata startingItemTokenIds,
    uint[] calldata startingAmounts
  ) external;

  function clearEverything(address from, uint playerId, bool processTheTransactions) external;

  function setActivePlayer(address from, uint playerId) external;

  function unequipBoostVial(uint playerId) external;

  function testModifyXP(address from, uint playerId, Skill skill, uint56 xp, bool force) external;

  function buyBrushQuest(address to, uint playerId, uint questId, bool useExactETH) external;

  function initialize(
    ItemNFT itemNFT,
    PlayerNFT playerNFT,
    World world,
    AdminAccess adminAccess,
    Quests quests,
    Clans clans,
    address implQueueActions,
    address implProcessActions,
    address implRewards,
    address implMisc,
    bool isBeta
  ) external;
}

contract Players is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable, PlayersBase, IPlayers {
  using UnsafeMath for U256;

  event GamePaused(bool gamePaused);

  error InvalidSelector();
  error GameIsPaused();
  error NotBeta();

  modifier isOwnerOfPlayerAndActiveMod(uint _playerId) {
    if (!isOwnerOfPlayerAndActive(msg.sender, _playerId)) {
      revert NotOwnerOfPlayerAndActive();
    }
    _;
  }

  modifier isOwnerOfPlayerMod(uint playerId) {
    if (playerNFT.balanceOf(msg.sender, playerId) != 1) {
      revert NotOwnerOfPlayer();
    }
    _;
  }

  modifier isBetaMod() {
    if (!isBeta) {
      revert NotBeta();
    }
    _;
  }

  modifier gameNotPaused() {
    if (gamePaused) {
      revert GameIsPaused();
    }
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
    _checkStartSlot();
  }

  function initialize(
    ItemNFT _itemNFT,
    PlayerNFT _playerNFT,
    World _world,
    AdminAccess _adminAccess,
    Quests _quests,
    Clans _clans,
    address _implQueueActions,
    address _implProcessActions,
    address _implRewards,
    address _implMisc,
    bool _isBeta
  ) public initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
    __ReentrancyGuard_init();

    _delegatecall(
      _implMisc,
      abi.encodeWithSelector(
        IPlayerDelegate.initialize.selector,
        _itemNFT,
        _playerNFT,
        _world,
        _adminAccess,
        _quests,
        _clans,
        _implQueueActions,
        _implProcessActions,
        _implRewards,
        _implMisc,
        _isBeta
      )
    );
  }

  /// @notice Start actions for a player
  /// @param _playerId Id for the player
  /// @param _queuedActions Actions to queue
  /// @param _queueStatus Can be either `ActionQueueStatus.NONE` for overwriting all actions,
  ///                     `ActionQueueStatus.KEEP_LAST_IN_PROGRESS` or `ActionQueueStatus.APPEND`
  function startActions(
    uint _playerId,
    QueuedActionInput[] calldata _queuedActions,
    ActionQueueStatus _queueStatus
  ) external isOwnerOfPlayerAndActiveMod(_playerId) nonReentrant gameNotPaused {
    _startActions(_playerId, _queuedActions, NONE, uint40(block.timestamp), 0, _queueStatus);
  }

  /// @notice Start actions for a player
  /// @param _playerId Id for the player
  /// @param _queuedActions Actions to queue
  /// @param _boostItemTokenId Which boost to consume, can be NONE
  /// @param _boostStartTime (Not used yet)
  /// @param _queueStatus Can be either `ActionQueueStatus.NONE` for overwriting all actions,
  ///                     `ActionQueueStatus.KEEP_LAST_IN_PROGRESS` or `ActionQueueStatus.APPEND`
  function startActionsExtra(
    uint _playerId,
    QueuedActionInput[] calldata _queuedActions,
    uint16 _boostItemTokenId,
    uint40 _boostStartTime, // Not used yet (always current time)
    uint _questId,
    ActionQueueStatus _queueStatus
  ) external isOwnerOfPlayerAndActiveMod(_playerId) nonReentrant gameNotPaused {
    _startActions(_playerId, _queuedActions, _boostItemTokenId, uint40(block.timestamp), _questId, _queueStatus);
  }

  /// @notice Process actions for a player up to the current block timestamp
  function processActions(uint _playerId) external isOwnerOfPlayerAndActiveMod(_playerId) nonReentrant gameNotPaused {
    _processActionsAndSetState(_playerId);
  }

  // Callback after minting a player
  function mintedPlayer(
    address _from,
    uint _playerId,
    Skill[2] calldata _startSkills,
    bool _makeActive,
    uint[] calldata _startingItemTokenIds,
    uint[] calldata _startingAmounts
  ) external override onlyPlayerNFT {
    if (_makeActive) {
      _setActivePlayer(_from, _playerId);
    }

    _delegatecall(
      implMisc,
      abi.encodeWithSelector(
        IPlayerDelegate.mintedPlayer.selector,
        _from,
        _playerId,
        _startSkills,
        _startingItemTokenIds,
        _startingAmounts
      )
    );
  }

  // This is a special type of quest.
  function buyBrushQuest(
    address _to,
    uint _playerId,
    uint _questId,
    bool _useExactETH
  ) external payable isOwnerOfPlayerAndActiveMod(_playerId) nonReentrant gameNotPaused {
    _delegatecall(
      implMisc,
      abi.encodeWithSelector(IPlayerDelegate.buyBrushQuest.selector, _to, _playerId, _questId, _useExactETH)
    );
  }

  function activateQuest(
    uint _playerId,
    uint questId
  ) external isOwnerOfPlayerAndActiveMod(_playerId) nonReentrant gameNotPaused {
    if (players_[_playerId].actionQueue.length != 0) {
      _processActionsAndSetState(_playerId);
    }
    quests.activateQuest(_playerId, questId);
  }

  function deactivateQuest(uint _playerId) external isOwnerOfPlayerAndActiveMod(_playerId) nonReentrant gameNotPaused {
    if (players_[_playerId].actionQueue.length != 0) {
      _processActionsAndSetState(_playerId);
    }
    // Quest may hve been completed as a result of this so don't bother trying to deactivate it
    if (quests.getActiveQuestId(_playerId) != 0) {
      quests.deactivateQuest(_playerId);
    }
  }

  /// @notice Called by the PlayerNFT contract before a player is transferred
  /// @param _from The owner of the player being transferred
  /// @param _playerId The id of the player being transferred
  function clearEverythingBeforeTokenTransfer(address _from, uint _playerId) external override onlyPlayerNFT {
    _clearEverything(_from, _playerId, true);
    // If it was the active player, then clear it
    uint existingActivePlayerId = activePlayer_[_from];
    if (existingActivePlayerId == _playerId) {
      delete activePlayer_[_from];
      emit SetActivePlayer(_from, existingActivePlayerId, 0);
    }
  }

  function clearEverything(uint _playerId) external isOwnerOfPlayerAndActiveMod(_playerId) isBetaMod {
    address from = msg.sender;
    bool isEmergency = true;
    _clearEverything(from, _playerId, !isEmergency);
  }

  function _clearEverything(address _from, uint _playerId, bool _processTheActions) private {
    _delegatecall(
      implQueueActions,
      abi.encodeWithSelector(IPlayerDelegate.clearEverything.selector, _from, _playerId, _processTheActions)
    );
  }

  function _startActions(
    uint _playerId,
    QueuedActionInput[] memory _queuedActions,
    uint16 _boostItemTokenId,
    uint40 _boostStartTime,
    uint _questId,
    ActionQueueStatus _queueStatus
  ) private {
    _delegatecall(
      implQueueActions,
      abi.encodeWithSelector(
        IPlayerDelegate.startActions.selector,
        _playerId,
        _queuedActions,
        _boostItemTokenId,
        _boostStartTime,
        _questId,
        _queueStatus
      )
    );
  }

  function _processActionsAndSetState(uint _playerId) private {
    _delegatecall(
      implProcessActions,
      abi.encodeWithSelector(IPlayersProcessActionsDelegate.processActionsAndSetState.selector, _playerId)
    );
  }

  function _setActivePlayer(address _from, uint _playerId) private {
    _delegatecall(implQueueActions, abi.encodeWithSelector(IPlayerDelegate.setActivePlayer.selector, _from, _playerId));
  }

  function setActivePlayer(uint _playerId) external isOwnerOfPlayerMod(_playerId) {
    _setActivePlayer(msg.sender, _playerId);
  }

  function dailyClaimedRewards(uint _playerId) external view returns (bool[7] memory claimed) {
    bytes memory data = _staticcall(
      address(this),
      abi.encodeWithSelector(IPlayersMiscDelegateView.dailyClaimedRewardsImpl.selector, _playerId)
    );
    return abi.decode(data, (bool[7]));
  }

  function isOwnerOfPlayerAndActive(address _from, uint _playerId) public view override returns (bool) {
    return playerNFT.balanceOf(_from, _playerId) == 1 && activePlayer_[_from] == _playerId;
  }

  function getPendingRandomRewards(uint _playerId) external view returns (PendingRandomReward[] memory) {
    return pendingRandomRewards[_playerId];
  }

  function getActionQueue(uint _playerId) external view returns (QueuedAction[] memory) {
    return players_[_playerId].actionQueue;
  }

  function getURI(
    uint _playerId,
    string calldata _name,
    string calldata _avatarName,
    string calldata _avatarDescription,
    string calldata imageURI
  ) external view override returns (string memory) {
    return
      PlayersLibrary.uri(
        _name,
        xp_[_playerId],
        _avatarName,
        _avatarDescription,
        imageURI,
        isBeta,
        _playerId,
        clans.getClanNameOfPlayer(_playerId)
      );
  }

  // Staticcall into ourselves and hit the fallback. This is done so that pendingQueuedActionState/dailyClaimedRewards can be exposed on the json abi.
  function pendingQueuedActionState(
    address _owner,
    uint _playerId
  ) public view returns (PendingQueuedActionState memory) {
    bytes memory data = _staticcall(
      address(this),
      abi.encodeWithSelector(IPlayersRewardsDelegateView.pendingQueuedActionStateImpl.selector, _owner, _playerId)
    );
    return abi.decode(data, (PendingQueuedActionState));
  }

  function activePlayer(address _owner) external view override returns (uint playerId) {
    return activePlayer_[_owner];
  }

  function xp(uint _playerId, Skill _skill) external view returns (uint) {
    return PlayersLibrary.readXP(_skill, xp_[_playerId]);
  }

  function players(uint _playerId) external view returns (Player memory) {
    return players_[_playerId];
  }

  function RANDOM_REWARD_CHANCE_MULTIPLIER_CUTOFF() external pure returns (uint) {
    return RANDOM_REWARD_CHANCE_MULTIPLIER_CUTOFF_;
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  function setImpls(
    address _implQueueActions,
    address _implProcessActions,
    address _implRewards,
    address _implMisc
  ) external onlyOwner {
    implQueueActions = _implQueueActions;
    implProcessActions = _implProcessActions;
    implRewards = _implRewards;
    implMisc = _implMisc;
  }

  function addXPThresholdRewards(XPThresholdReward[] calldata _xpThresholdRewards) external onlyOwner {
    _delegatecall(
      implMisc,
      abi.encodeWithSelector(IPlayerDelegate.addXPThresholdRewards.selector, _xpThresholdRewards)
    );
  }

  function setDailyRewardsEnabled(bool _dailyRewardsEnabled) external onlyOwner {
    dailyRewardsEnabled = _dailyRewardsEnabled;
  }

  function pauseGame(bool _gamePaused) external onlyOwner {
    gamePaused = _gamePaused;
    emit GamePaused(_gamePaused);
  }

  function addFullAttireBonuses(FullAttireBonusInput[] calldata _fullAttireBonuses) external onlyOwner {
    _delegatecall(implMisc, abi.encodeWithSelector(IPlayerDelegate.addFullAttireBonuses.selector, _fullAttireBonuses));
  }

  function testModifyXP(address _from, uint _playerId, Skill _skill, uint56 _xp, bool _force) external isAdminAndBeta {
    _delegatecall(
      implProcessActions,
      abi.encodeWithSelector(IPlayerDelegate.testModifyXP.selector, _from, _playerId, _skill, _xp, _force)
    );
  }

  // For the various view functions that require delegatecall
  fallback() external {
    bytes4 selector = bytes4(msg.data);

    address implementation;
    if (selector == IPlayersRewardsDelegateView.pendingQueuedActionStateImpl.selector) {
      implementation = implRewards;
    } else if (
      selector == IPlayersMiscDelegateView.claimableXPThresholdRewardsImpl.selector ||
      selector == IPlayersMiscDelegateView.dailyClaimedRewardsImpl.selector ||
      selector == IPlayersMiscDelegateView.dailyRewardsViewImpl.selector ||
      selector == IPlayersMiscDelegateView.processConsumablesView.selector ||
      selector == IPlayersMiscDelegateView.getRandomRewards.selector
    ) {
      implementation = implMisc;
    } else {
      revert InvalidSelector();
    }

    assembly ("memory-safe") {
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UnsafeMath, U256} from "@0xdoublesharp/unsafe-math/contracts/UnsafeMath.sol";
import {World} from "../World.sol";
import {ItemNFT} from "../ItemNFT.sol";
import {PlayerNFT} from "../PlayerNFT.sol";
import {AdminAccess} from "../AdminAccess.sol";
import {Quests} from "../Quests.sol";
import {Clans} from "../Clans/Clans.sol";
import {PlayersLibrary} from "./PlayersLibrary.sol";
import "../interfaces/IPlayersDelegates.sol";

// solhint-disable-next-line no-global-import
import "../globals/all.sol";

abstract contract PlayersBase {
  using UnsafeMath for U256;
  using UnsafeMath for uint256;

  event ClearAll(address from, uint playerId);
  event AddXP(address from, uint playerId, Skill skill, uint points);
  event SetActionQueue(address from, uint playerId, QueuedAction[] queuedActions, Attire[] attire, uint startTime);
  event ConsumeBoostVial(address from, uint playerId, PlayerBoostInfo playerBoostInfo);
  event UnconsumeBoostVial(address from, uint playerId);
  event SetActivePlayer(address account, uint oldPlayerId, uint newPlayerId);
  event AddPendingRandomReward(address from, uint playerId, uint queueId, uint startTime, uint elapsed);
  event PendingRandomRewardsClaimed(
    address from,
    uint playerId,
    uint numRemoved,
    uint[] itemTokenIds,
    uint[] amounts,
    uint[] queueIds
  );
  event AdminAddThresholdReward(XPThresholdReward xpThresholdReward);

  event BoostFinished(uint playerId);

  // For logging
  event Died(address from, uint playerId, uint queueId);
  event QuestRewardConsumes(
    address from,
    uint playerId,
    uint[] rewardItemTokenIds,
    uint[] rewardAmounts,
    uint[] consumedItemTokenIds,
    uint[] consumedAmounts
  );
  event Rewards(address from, uint playerId, uint queueId, uint[] itemTokenIds, uint[] amounts);
  event DailyReward(address from, uint playerId, uint itemTokenId, uint amount);
  event WeeklyReward(address from, uint playerId, uint itemTokenId, uint amount);
  event Consumes(address from, uint playerId, uint queueId, uint[] itemTokenIds, uint[] amounts);
  event ActionFinished(address from, uint playerId, uint queueId);
  event ActionPartiallyFinished(address from, uint playerId, uint queueId, uint elapsedTime);
  event ActionAborted(address from, uint playerId, uint queueId);
  event ClaimedXPThresholdRewards(address from, uint playerId, uint[] itemTokenIds, uint[] amounts);
  event LevelUp(address from, uint playerId, Skill skill, uint32 oldLevel, uint32 newLevel);
  event AddFullAttireBonus(Skill skill, uint16[5] itemTokenIds, uint8 bonusXPPercent, uint8 bonusRewardsPercent);

  struct FullAttireBonus {
    uint8 bonusXPPercent; // 3 = 3%
    uint8 bonusRewardsPercent; // 3 = 3%
    uint16[5] itemTokenIds; // 0 = head, 1 = body, 2 arms, 3 body, 4 = feet
  }

  error NotOwnerOfPlayer();
  error NotOwnerOfPlayerAndActive();
  error EquipSameItem();
  error NotEquipped();
  error ArgumentLengthMismatch();
  error NotPlayerNFT();
  error NotItemNFT();
  error ActionNotAvailable();
  error UnsupportedAttire();
  error UnsupportedChoiceId();
  error InvalidHandEquipment(uint16 itemTokenId);
  error DoNotHaveEnoughQuantityToEquipToAction();
  error NoActiveBoost();
  error BoostTimeAlreadyStarted();
  error TooManyActionsQueued();
  error TooManyActionsQueuedSomeAlreadyExist();
  error ActionTimespanExceedsMaxTime();
  error ActionTimespanZero();
  error ActionMinimumXPNotReached();
  error ActionChoiceMinimumXPNotReached();
  error ItemMinimumXPNotReached();
  error AttireMinimumXPNotReached();
  error ConsumableMinimumXPNotReached();
  error InvalidStartSlot();
  error NoItemBalance(uint16 itemTokenId);
  error CannotEquipTwoHandedAndOtherEquipment();
  error IncorrectRightHandEquipment(uint16 equippedItemTokenId);
  error IncorrectLeftHandEquipment(uint16 equippedItemTokenId);
  error IncorrectEquippedItem(uint16 equippedItemTokenId);
  error NotABoostVial();
  error StartTimeTooFarInTheFuture();
  error UnsupportedRegenerateItem();
  error InvalidCombatStyle();
  error InvalidSkill();
  error InvalidTravellingTimespan();
  error ActionChoiceIdRequired();
  error ActionChoiceIdNotRequired();
  error InvalidEquipPosition();
  error NoActionsToProcess();
  error NotAdminAndBeta();
  error XPThresholdNotFound();
  error XPThresholdAlreadyExists();
  error InvalidItemTokenId();
  error ItemDoesNotExist();
  error InvalidAmount();
  error EmptyTimespan();
  error PlayerAlreadyActive();
  error TestInvalidXP();
  error HasQueuedActions();
  error CannotCallInitializerOnImplementation();
  error InvalidReward();

  uint32 internal constant MAX_TIME_ = 1 days;
  uint internal constant START_XP_ = 374;
  // 90%, used for actions/actionChoices which can have a failure rate like thieving/cooking
  uint internal constant MAX_SUCCESS_PERCENT_CHANCE_ = 90;
  uint internal constant MAX_UNIQUE_TICKETS_ = 240;
  uint internal constant RANDOM_REWARD_CHANCE_MULTIPLIER_CUTOFF_ = 1000;

  // *IMPORTANT* keep as the first non-constant state variable
  uint internal startSlot;

  mapping(address user => uint playerId) internal activePlayer_;

  mapping(uint playerId => PlayerBoostInfo boostInfo) internal activeBoosts_;

  World internal world;
  // Constants for the damage formula
  uint8 internal alphaCombat;
  uint8 internal betaCombat;
  uint64 internal nextQueueId; // Global queued action id
  bool internal dailyRewardsEnabled;
  bool internal isBeta;

  mapping(uint playerId => PackedXP packedXP) internal xp_;

  mapping(uint playerId => Player player) internal players_;
  mapping(uint playerId => mapping(uint queuedId => Attire attire)) internal attire_;
  ItemNFT internal itemNFT;
  PlayerNFT internal playerNFT;
  bool internal gamePaused;
  mapping(uint playerId => PendingRandomReward[] pendingRandomRewards) internal pendingRandomRewards; // queue, will be sorted by timestamp

  // First 7 bytes are whether that day has been claimed (Can be extended to 30 days), the last 2 bytes is the current checkpoint number (whether it needs clearing)
  mapping(uint playerId => bytes32) internal dailyRewardMasks;

  mapping(uint xp => Equipment[] equipments) internal xpRewardThresholds; // Thresholds and all items rewarded for it

  address internal implQueueActions;
  address internal implProcessActions;
  address internal implRewards;
  address internal implMisc;
  address internal reserved1;

  AdminAccess internal adminAccess;

  mapping(Skill skill => FullAttireBonus) internal fullAttireBonus;
  Quests internal quests;
  Clans internal clans;

  modifier onlyPlayerNFT() {
    if (msg.sender != address(playerNFT)) {
      revert NotPlayerNFT();
    }
    _;
  }

  modifier onlyItemNFT() {
    if (msg.sender != address(itemNFT)) {
      revert NotItemNFT();
    }
    _;
  }

  modifier isAdminAndBeta() {
    if (!(adminAccess.isAdmin(msg.sender) && isBeta)) {
      revert NotAdminAndBeta();
    }
    _;
  }

  function _getSkillFromChoiceOrStyle(
    ActionChoice memory _choice,
    CombatStyle _combatStyle,
    uint16 _actionId
  ) internal view returns (Skill skill) {
    if (_combatStyle == CombatStyle.DEFENCE) {
      return Skill.DEFENCE;
    }

    if (_choice.skill != Skill.NONE) {
      skill = _choice.skill;
    } else {
      skill = world.getSkill(_actionId);
    }
  }

  function _isCombatStyle(CombatStyle _combatStyle) internal pure returns (bool) {
    return _combatStyle != CombatStyle.NONE;
  }

  function _getElapsedTime(uint _startTime, uint _endTime) internal view returns (uint elapsedTime) {
    bool consumeAll = _endTime <= block.timestamp;
    if (consumeAll) {
      // Fully consume this skill
      elapsedTime = _endTime - _startTime;
    } else if (block.timestamp > _startTime) {
      // partially consume
      elapsedTime = block.timestamp - _startTime;
    }
  }

  function _setActionQueue(
    address _from,
    uint _playerId,
    QueuedAction[] memory _queuedActions,
    Attire[] memory _attire,
    uint _startTime
  ) internal {
    Player storage player = players_[_playerId];

    // If ids are the same as existing, then just change the first one. Optimization when just claiming loot
    bool same = true;
    if (player.actionQueue.length == _queuedActions.length) {
      for (uint i = 0; i < _queuedActions.length; ++i) {
        if (player.actionQueue[i].queueId != _queuedActions[i].queueId) {
          same = false;
          break;
        }
      }
    }

    if (same && player.actionQueue.length == _queuedActions.length && _queuedActions.length != 0) {
      player.actionQueue[0] = _queuedActions[0];
    } else {
      // Replace everything
      player.actionQueue = _queuedActions;
      for (uint i; i < _attire.length; ++i) {
        attire_[_playerId][player.actionQueue[i].queueId] = _attire[i];
      }
    }
    emit SetActionQueue(_from, _playerId, _queuedActions, _attire, _startTime);
  }

  // This does not update player.totalXP!!
  function _updateXP(address _from, uint _playerId, Skill _skill, uint128 _pointsAccrued) internal {
    PackedXP storage packedXP = xp_[_playerId];
    uint oldPoints = PlayersLibrary.readXP(_skill, packedXP);
    uint newPoints = oldPoints.add(_pointsAccrued);
    if (newPoints > type(uint32).max) {
      newPoints = type(uint32).max;
      _pointsAccrued = uint32(newPoints - oldPoints);
    }
    if (_pointsAccrued == 0) {
      return;
    }
    uint offset = 2; // Accounts for NONE & COMBAT skills
    uint skillOffsetted = uint8(_skill) - offset;
    uint slotNum = skillOffsetted / 6;
    uint relativePos = skillOffsetted % 6;

    uint40 _newPoints = uint40(newPoints);
    assembly ("memory-safe") {
      let val := sload(add(packedXP.slot, slotNum))
      // Clear the 5 bytes containing the old xp
      val := and(val, not(shl(mul(relativePos, 40), 0xffffffffff)))
      // Now set new xp
      val := or(val, shl(mul(relativePos, 40), _newPoints))
      sstore(add(packedXP.slot, slotNum), val)
    }

    emit AddXP(_from, _playerId, _skill, _pointsAccrued);

    uint16 oldLevel = PlayersLibrary.getLevel(oldPoints);
    uint16 newLevel = PlayersLibrary.getLevel(newPoints);
    // Update the player's level
    if (newLevel > oldLevel) {
      emit LevelUp(_from, _playerId, _skill, oldLevel, newLevel);
    }
  }

  function _processActions(
    address _from,
    uint _playerId
  )
    internal
    returns (QueuedAction[] memory remainingQueuedActions, PendingQueuedActionData memory currentActionProcessed)
  {
    bytes memory data = _delegatecall(
      implProcessActions,
      abi.encodeWithSelector(IPlayersProcessActionsDelegate.processActions.selector, _from, _playerId)
    );
    return abi.decode(data, (QueuedAction[], PendingQueuedActionData));
  }

  function _claimableXPThresholdRewards(
    uint _oldTotalXP,
    uint _newTotalXP
  ) internal view returns (uint[] memory ids, uint[] memory amounts) {
    // Call self
    bytes memory data = _staticcall(
      address(this),
      abi.encodeWithSelector(
        IPlayersMiscDelegateView.claimableXPThresholdRewardsImpl.selector,
        _oldTotalXP,
        _newTotalXP
      )
    );
    return abi.decode(data, (uint[], uint[]));
  }

  function _checkStartSlot() internal pure {
    uint expectedStartSlotNumber = 251; // From the various slot arrays expected in the base classes
    uint slot;
    assembly ("memory-safe") {
      slot := startSlot.slot
    }
    if (slot != expectedStartSlotNumber) {
      revert InvalidStartSlot();
    }
  }

  function _setPrevPlayerState(
    Player storage _player,
    PendingQueuedActionData memory _currentActionProcessed
  ) internal {
    _player.currentActionProcessedSkill1 = _currentActionProcessed.skill1;
    _player.currentActionProcessedXPGained1 = _currentActionProcessed.xpGained1;
    _player.currentActionProcessedSkill2 = _currentActionProcessed.skill2;
    _player.currentActionProcessedXPGained2 = _currentActionProcessed.xpGained2;
    _player.currentActionProcessedSkill3 = _currentActionProcessed.skill3;
    _player.currentActionProcessedXPGained3 = _currentActionProcessed.xpGained3;
    _player.currentActionProcessedFoodConsumed = _currentActionProcessed.foodConsumed;
    _player.currentActionProcessedBaseInputItemsConsumedNum = _currentActionProcessed.baseInputItemsConsumedNum;
  }

  function _processClaimableRewards(
    address _from,
    uint _playerId,
    uint[] memory itemTokenIds,
    uint[] memory amounts,
    uint[] memory queueIds,
    uint numPastRandomRewardInstancesToRemove
  ) internal {
    if (numPastRandomRewardInstancesToRemove != 0) {
      if (numPastRandomRewardInstancesToRemove == pendingRandomRewards[_playerId].length) {
        delete pendingRandomRewards[_playerId];
      } else {
        // Shift the remaining rewards to the front of the array
        U256 bounds = pendingRandomRewards[_playerId].length.asU256().sub(numPastRandomRewardInstancesToRemove);
        for (U256 iter; iter < bounds; iter = iter.inc()) {
          uint i = iter.asUint256();
          pendingRandomRewards[_playerId][i] = pendingRandomRewards[_playerId][
            i + numPastRandomRewardInstancesToRemove
          ];
        }
        for (U256 iter = numPastRandomRewardInstancesToRemove.asU256(); iter.neq(0); iter = iter.dec()) {
          pendingRandomRewards[_playerId].pop();
        }
      }
    }
    if (itemTokenIds.length != 0) {
      itemNFT.mintBatch(_from, itemTokenIds, amounts);
      emit PendingRandomRewardsClaimed(
        _from,
        _playerId,
        numPastRandomRewardInstancesToRemove,
        itemTokenIds,
        amounts,
        queueIds
      );
    }
  }

  function _delegatecall(address target, bytes memory data) internal returns (bytes memory returndata) {
    bool success;
    (success, returndata) = target.delegatecall(data);
    if (!success) {
      if (returndata.length == 0) revert();
      assembly ("memory-safe") {
        revert(add(32, returndata), mload(returndata))
      }
    }
  }

  function _staticcall(address target, bytes memory data) internal view returns (bytes memory returndata) {
    bool success;
    (success, returndata) = target.staticcall(data);
    if (!success) {
      if (returndata.length == 0) revert();
      assembly ("memory-safe") {
        revert(add(32, returndata), mload(returndata))
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Use this first to get the same storage layout for implementation files as the main contract
contract PlayersImplBase {
  // From UUPSUpgradeable, includes ERC1967UpgradeUpgradeable
  uint256[100] private __gap;
  // From OwnableUpgradeable, includes ContextUpgradeable
  uint256[100] private __gap1;
  // From ReentrancyGuardUpgradeable
  uint256[51] private __gap2;
  // DO NOT UPDATE THIS AFTER DEPLOYMENT!!!
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {UnsafeMath, U256} from "@0xdoublesharp/unsafe-math/contracts/UnsafeMath.sol";

import {PlayersImplBase} from "./PlayersImplBase.sol";
import {PlayersBase} from "./PlayersBase.sol";
import {PlayersLibrary} from "./PlayersLibrary.sol";
import {ItemNFT} from "../ItemNFT.sol";
import {PlayerNFT} from "../PlayerNFT.sol";
import {World} from "../World.sol";
import {ItemNFT} from "../ItemNFT.sol";
import {AdminAccess} from "../AdminAccess.sol";
import {Quests} from "../Quests.sol";
import {Clans} from "../Clans/Clans.sol";
import {IPlayersMiscDelegate, IPlayersMiscDelegateView} from "../interfaces/IPlayersDelegates.sol";

// solhint-disable-next-line no-global-import
import "../globals/all.sol";

contract PlayersImplMisc is PlayersImplBase, PlayersBase, IPlayersMiscDelegate, IPlayersMiscDelegateView {
  using UnsafeMath for U256;
  using UnsafeMath for uint8;
  using UnsafeMath for uint16;
  using UnsafeMath for uint24;
  using UnsafeMath for uint32;
  using UnsafeMath for uint40;
  using UnsafeMath for uint128;
  using UnsafeMath for uint256;

  address immutable _this;

  constructor() {
    _checkStartSlot();
    _this = address(this);
  }

  // === XP Threshold rewards ===
  function claimableXPThresholdRewardsImpl(
    uint _oldTotalXP,
    uint _newTotalXP
  ) external view returns (uint[] memory itemTokenIds, uint[] memory amounts) {
    uint16 prevIndex = _findBaseXPThreshold(_oldTotalXP);
    uint16 nextIndex = _findBaseXPThreshold(_newTotalXP);

    uint diff = nextIndex - prevIndex;
    itemTokenIds = new uint[](diff);
    amounts = new uint[](diff);
    U256 length;
    for (U256 iter; iter.lt(diff); iter = iter.inc()) {
      uint i = iter.asUint256();
      uint32 xpThreshold = _getXPReward(prevIndex.inc().add(i));
      Equipment[] memory items = xpRewardThresholds[xpThreshold];
      if (items.length != 0) {
        // TODO: Currently assumes there is only 1 item per threshold
        uint l = length.asUint256();
        itemTokenIds[l] = items[0].itemTokenId;
        amounts[l] = items[0].amount;
        length = length.inc();
      }
    }

    assembly ("memory-safe") {
      mstore(itemTokenIds, length)
      mstore(amounts, length)
    }
  }

  function addXPThresholdRewards(XPThresholdReward[] calldata _xpThresholdRewards) external {
    U256 iter = _xpThresholdRewards.length.asU256();
    while (iter.neq(0)) {
      iter = iter.dec();
      XPThresholdReward calldata xpThresholdReward = _xpThresholdRewards[iter.asUint256()];

      // Check that it is part of the hexBytes
      uint16 index = _findBaseXPThreshold(xpThresholdReward.xpThreshold);
      uint32 xpThreshold = _getXPReward(index);
      if (xpThresholdReward.xpThreshold != xpThreshold) {
        revert XPThresholdNotFound();
      }

      if (xpRewardThresholds[xpThresholdReward.xpThreshold].length != 0) {
        revert XPThresholdAlreadyExists();
      }

      U256 bounds = xpThresholdReward.rewards.length.asU256();
      for (U256 jIter; jIter < bounds; jIter = jIter.inc()) {
        uint j = jIter.asUint256();
        if (xpThresholdReward.rewards[j].itemTokenId == NONE) {
          revert InvalidItemTokenId();
        }
        if (xpThresholdReward.rewards[j].amount == 0) {
          revert InvalidAmount();
        }
      }

      xpRewardThresholds[xpThresholdReward.xpThreshold] = xpThresholdReward.rewards;
      emit AdminAddThresholdReward(xpThresholdReward);
    }
  }

  // Index not level, add one after (check for > max)
  function _findBaseXPThreshold(uint256 _xp) private pure returns (uint16) {
    U256 low;
    U256 high = xpRewardBytes.length.asU256().div(4);

    while (low < high) {
      U256 mid = (low + high).div(2);

      // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
      // Math.average rounds down (it does integer division with truncation).
      if (_getXPReward(mid.asUint256()) > _xp) {
        high = mid;
      } else {
        low = mid.inc();
      }
    }

    if (low.neq(0)) {
      return low.dec().asUint16();
    } else {
      return 0;
    }
  }

  function _getXPReward(uint256 _index) private pure returns (uint32) {
    U256 index = _index.asU256().mul(4);
    return
      uint32(
        xpRewardBytes[index.asUint256()] |
          (bytes4(xpRewardBytes[index.add(1).asUint256()]) >> 8) |
          (bytes4(xpRewardBytes[index.add(2).asUint256()]) >> 16) |
          (bytes4(xpRewardBytes[index.add(3).asUint256()]) >> 24)
      );
  }

  // === End XP Threshold rewards ===

  function dailyRewardsViewImpl(
    uint _playerId
  ) public view returns (uint[] memory itemTokenIds, uint[] memory amounts, bytes32 dailyRewardMask) {
    uint streakStart = ((block.timestamp.sub(4 days)).div(1 weeks)).mul(1 weeks).add(4 days);
    bool hasRandomWordLastSunday = world.lastRandomWordsUpdatedTime() >= streakStart;
    if (hasRandomWordLastSunday) {
      uint streakStartIndex = streakStart.div(1 weeks);
      bytes32 mask = dailyRewardMasks[_playerId];
      uint16 lastRewardStartIndex = uint16(uint256(mask));
      if (lastRewardStartIndex < streakStartIndex) {
        mask = bytes32(streakStartIndex); // Reset the mask
      }

      uint maskIndex = ((block.timestamp.div(1 days)).mul(1 days).sub(streakStart)).div(1 days);

      // Claim daily reward
      if (mask[maskIndex] == 0 && dailyRewardsEnabled) {
        (uint itemTokenId, uint amount) = world.getDailyReward();
        if (itemTokenId != NONE) {
          // Add clan member boost to daily reward (if applicable)
          uint clanTierMembership = clans.getClanTierMembership(_playerId);
          amount += (amount * clanTierMembership) / 10; // +10% extra for each clan tier

          dailyRewardMask = mask | ((bytes32(hex"ff") >> (maskIndex * 8)));
          bool canClaimWeeklyRewards = uint(dailyRewardMask >> (25 * 8)) == 2 ** (7 * 8) - 1;
          uint length = canClaimWeeklyRewards ? 2 : 1;
          itemTokenIds = new uint[](length);
          amounts = new uint[](length);
          itemTokenIds[0] = itemTokenId;
          amounts[0] = amount;

          // Claim weekly rewards (this shifts the left-most 7 day streaks to the very right and checks all bits are set)
          if (canClaimWeeklyRewards) {
            (itemTokenIds[1], amounts[1]) = world.getWeeklyReward();
          }
        }
      }
    }
  }

  function dailyClaimedRewardsImpl(uint _playerId) external view returns (bool[7] memory claimed) {
    uint streakStart = ((block.timestamp.sub(4 days)).div(1 weeks)).mul(1 weeks).add(4 days);
    uint streakStartIndex = streakStart.div(1 weeks);
    bytes32 mask = dailyRewardMasks[_playerId];
    uint16 lastRewardStartIndex = uint16(uint256(mask));
    if (lastRewardStartIndex < streakStartIndex) {
      mask = bytes32(streakStartIndex);
    }

    for (U256 iter; iter.lt(7); iter = iter.inc()) {
      uint i = iter.asUint256();
      claimed[i] = mask[i] != 0;
    }
  }

  function handleDailyRewards(address _from, uint _playerId) external {
    (uint[] memory rewardItemTokenIds, uint[] memory rewardAmounts, bytes32 dailyRewardMask) = dailyRewardsViewImpl(
      _playerId
    );
    if (uint(dailyRewardMask) != 0) {
      dailyRewardMasks[_playerId] = dailyRewardMask;
    }
    if (rewardAmounts.length != 0) {
      itemNFT.mint(_from, rewardItemTokenIds[0], rewardAmounts[0]);
      emit DailyReward(_from, _playerId, rewardItemTokenIds[0], rewardAmounts[0]);
    }

    if (rewardAmounts.length > 1) {
      itemNFT.mint(_from, rewardItemTokenIds[1], rewardAmounts[1]);
      emit WeeklyReward(_from, _playerId, rewardItemTokenIds[1], rewardAmounts[1]);
    }
  }

  function initialize(
    ItemNFT _itemNFT,
    PlayerNFT _playerNFT,
    World _world,
    AdminAccess _adminAccess,
    Quests _quests,
    Clans _clans,
    address _implQueueActions,
    address _implProcessActions,
    address _implRewards,
    address _implMisc,
    bool _isBeta
  ) external {
    if (address(this) == _this) {
      revert CannotCallInitializerOnImplementation();
    }

    itemNFT = _itemNFT;
    playerNFT = _playerNFT;
    world = _world;
    adminAccess = _adminAccess;
    quests = _quests;
    clans = _clans;
    implQueueActions = _implQueueActions;
    implProcessActions = _implProcessActions;
    implRewards = _implRewards;
    implMisc = _implMisc;

    nextQueueId = 1;
    alphaCombat = 1;
    betaCombat = 1;
    isBeta = _isBeta;
  }

  function addFullAttireBonuses(FullAttireBonusInput[] calldata _fullAttireBonuses) external {
    U256 bounds = _fullAttireBonuses.length.asU256();
    for (U256 iter; iter < bounds; iter = iter.inc()) {
      uint i = iter.asUint256();
      FullAttireBonusInput calldata _fullAttireBonus = _fullAttireBonuses[i];

      if (_fullAttireBonus.skill == Skill.NONE) {
        revert InvalidSkill();
      }
      EquipPosition[5] memory expectedEquipPositions = [
        EquipPosition.HEAD,
        EquipPosition.BODY,
        EquipPosition.ARMS,
        EquipPosition.LEGS,
        EquipPosition.FEET
      ];
      U256 jbounds = expectedEquipPositions.length.asU256();
      for (U256 jter; jter < jbounds; jter = jter.inc()) {
        uint j = jter.asUint256();
        if (_fullAttireBonus.itemTokenIds[j] == NONE) {
          revert InvalidItemTokenId();
        }
        if (itemNFT.getItem(_fullAttireBonus.itemTokenIds[j]).equipPosition != expectedEquipPositions[j]) {
          revert InvalidEquipPosition();
        }
      }

      fullAttireBonus[_fullAttireBonus.skill] = FullAttireBonus(
        _fullAttireBonus.bonusXPPercent,
        _fullAttireBonus.bonusRewardsPercent,
        _fullAttireBonus.itemTokenIds
      );
      emit AddFullAttireBonus(
        _fullAttireBonus.skill,
        _fullAttireBonus.itemTokenIds,
        _fullAttireBonus.bonusXPPercent,
        _fullAttireBonus.bonusRewardsPercent
      );
    }
  }

  function _getConsumablesEquipment(
    uint _playerId,
    uint _currentActionStartTime,
    uint _xpElapsedTime,
    ActionChoice calldata _actionChoice,
    uint16 _regenerateId,
    uint16 _foodConsumed,
    PendingQueuedActionProcessed calldata _pendingQueuedActionProcessed,
    uint16 baseInputItemsConsumedNum
  ) private view returns (Equipment[] memory consumedEquipment, Equipment memory producedEquipment) {
    consumedEquipment = new Equipment[](MAX_CONSUMED_PER_ACTION);
    uint consumedEquipmentLength;
    if (_regenerateId != NONE && _foodConsumed != 0) {
      consumedEquipment[consumedEquipmentLength] = Equipment(_regenerateId, _foodConsumed);
      consumedEquipmentLength = consumedEquipmentLength.inc();
    }

    if (baseInputItemsConsumedNum != 0) {
      if (_actionChoice.inputTokenId1 != NONE) {
        consumedEquipment[consumedEquipmentLength] = Equipment(
          _actionChoice.inputTokenId1,
          baseInputItemsConsumedNum * _actionChoice.inputAmount1
        );
        consumedEquipmentLength = consumedEquipmentLength.inc();
      }
      if (_actionChoice.inputTokenId2 != NONE) {
        consumedEquipment[consumedEquipmentLength] = Equipment(
          _actionChoice.inputTokenId2,
          baseInputItemsConsumedNum * _actionChoice.inputAmount2
        );
        consumedEquipmentLength = consumedEquipmentLength.inc();
      }
      if (_actionChoice.inputTokenId3 != NONE) {
        consumedEquipment[consumedEquipmentLength] = Equipment(
          _actionChoice.inputTokenId3,
          baseInputItemsConsumedNum * _actionChoice.inputAmount3
        );
        consumedEquipmentLength = consumedEquipmentLength.inc();
      }
    }

    if (_actionChoice.outputTokenId != 0) {
      uint8 successPercent = 100;
      if (_actionChoice.successPercent != 100) {
        uint minLevel = PlayersLibrary.getLevel(_actionChoice.minXP);
        uint skillLevel = PlayersLibrary.getLevel(
          PlayersLibrary.getAbsoluteActionStartXP(_actionChoice.skill, _pendingQueuedActionProcessed, xp_[_playerId])
        );
        uint extraBoost = skillLevel - minLevel;

        successPercent = uint8(Math.min(MAX_SUCCESS_PERCENT_CHANCE_, _actionChoice.successPercent + extraBoost));
      }

      // Some might be burnt cooking for instance
      uint16 numProduced = uint16(
        (uint(baseInputItemsConsumedNum) * _actionChoice.outputAmount * successPercent) / 100
      );

      if (_xpElapsedTime != 0) {
        // Check for any gathering boosts
        PlayerBoostInfo storage activeBoost = activeBoosts_[_playerId];
        uint boostedTime = PlayersLibrary.getBoostedTime(
          _currentActionStartTime,
          _xpElapsedTime,
          activeBoost.startTime,
          activeBoost.duration
        );
        if (boostedTime != 0 && activeBoost.boostType == BoostType.GATHERING) {
          numProduced += uint16((boostedTime * numProduced * activeBoost.value) / (_xpElapsedTime * 100));
        }
      }

      if (numProduced != 0) {
        producedEquipment = Equipment(_actionChoice.outputTokenId, numProduced);
      }
    }

    assembly ("memory-safe") {
      mstore(consumedEquipment, consumedEquipmentLength)
    }
  }

  function _processConsumablesView(
    address _from,
    uint _playerId,
    QueuedAction calldata _queuedAction,
    uint _currentActionStartTime,
    uint _elapsedTime,
    CombatStats calldata _combatStats,
    ActionChoice calldata _actionChoice,
    PendingQueuedActionEquipmentState[] memory _pendingQueuedActionEquipmentStates,
    PendingQueuedActionProcessed calldata _pendingQueuedActionProcessed
  )
    private
    view
    returns (
      Equipment[] memory consumedEquipment,
      Equipment memory producedEquipment,
      uint xpElapsedTime,
      bool died,
      uint16 foodConsumed,
      uint16 baseInputItemsConsumedNum
    )
  {
    // Figure out how much food should be consumed.
    // This is based on the damage done from battling
    bool isCombat = _isCombatStyle(_queuedAction.combatStyle);
    if (isCombat) {
      // Fetch the requirements for it
      CombatStats memory enemyCombatStats = world.getCombatStats(_queuedAction.actionId);

      uint combatElapsedTime;
      (xpElapsedTime, combatElapsedTime, baseInputItemsConsumedNum, foodConsumed, died) = PlayersLibrary
        .getCombatAdjustedElapsedTimes(
          _from,
          itemNFT,
          world,
          _elapsedTime,
          _actionChoice,
          _queuedAction.regenerateId,
          _queuedAction,
          _combatStats,
          enemyCombatStats,
          alphaCombat,
          betaCombat,
          _pendingQueuedActionEquipmentStates
        );
    } else {
      (xpElapsedTime, baseInputItemsConsumedNum) = PlayersLibrary.getNonCombatAdjustedElapsedTime(
        _from,
        itemNFT,
        _elapsedTime,
        _actionChoice,
        _pendingQueuedActionEquipmentStates
      );
    }

    (consumedEquipment, producedEquipment) = _getConsumablesEquipment(
      _playerId,
      _currentActionStartTime,
      xpElapsedTime,
      _actionChoice,
      _queuedAction.regenerateId,
      foodConsumed,
      _pendingQueuedActionProcessed,
      baseInputItemsConsumedNum
    );
  }

  function processConsumablesView(
    address from,
    uint _playerId,
    QueuedAction calldata queuedAction,
    ActionChoice calldata actionChoice,
    CombatStats calldata combatStats,
    uint elapsedTime,
    uint startTime,
    PendingQueuedActionEquipmentState[] memory pendingQueuedActionEquipmentStates, // Memory as it is modified
    PendingQueuedActionProcessed calldata _pendingQueuedActionProcessed
  )
    external
    view
    returns (
      Equipment[] memory consumedEquipments,
      Equipment memory producedEquipment,
      uint xpElapsedTime,
      bool died,
      uint16 foodConsumed,
      uint16 baseInputItemsConsumedNum
    )
  {
    // Processed
    uint prevProcessedTime = queuedAction.prevProcessedTime;
    uint veryStartTime = startTime.sub(prevProcessedTime);
    uint prevXPElapsedTime = queuedAction.prevProcessedXPTime;

    // Total used
    if (prevProcessedTime != 0) {
      uint16 currentActionProcessedFoodConsumed = players_[_playerId].currentActionProcessedFoodConsumed;
      uint16 currentActionProcessedBaseInputItemsConsumedNum = players_[_playerId]
        .currentActionProcessedBaseInputItemsConsumedNum;

      (Equipment[] memory prevConsumedEquipments, Equipment memory prevProducedEquipment) = _getConsumablesEquipment(
        _playerId,
        veryStartTime,
        prevXPElapsedTime,
        actionChoice,
        queuedAction.regenerateId,
        currentActionProcessedFoodConsumed,
        _pendingQueuedActionProcessed,
        currentActionProcessedBaseInputItemsConsumedNum
      );

      // Copy existing pending
      PendingQueuedActionEquipmentState
        memory extendedPendingQueuedActionEquipmentState = pendingQueuedActionEquipmentStates[
          pendingQueuedActionEquipmentStates.length - 1
        ];

      if (prevConsumedEquipments.length != 0) {
        // Add to produced
        extendedPendingQueuedActionEquipmentState.producedItemTokenIds = new uint[](prevConsumedEquipments.length);
        extendedPendingQueuedActionEquipmentState.producedAmounts = new uint[](prevConsumedEquipments.length);
        for (uint j = 0; j < prevConsumedEquipments.length; ++j) {
          extendedPendingQueuedActionEquipmentState.producedItemTokenIds[j] = prevConsumedEquipments[j].itemTokenId;
          extendedPendingQueuedActionEquipmentState.producedAmounts[j] = prevConsumedEquipments[j].amount;
        }
      }
      if (prevProducedEquipment.itemTokenId != NONE) {
        // Add to consumed
        extendedPendingQueuedActionEquipmentState.consumedItemTokenIds = new uint[](1);
        extendedPendingQueuedActionEquipmentState.consumedAmounts = new uint[](1);
        extendedPendingQueuedActionEquipmentState.consumedItemTokenIds[0] = prevProducedEquipment.itemTokenId;
        extendedPendingQueuedActionEquipmentState.consumedAmounts[0] = prevProducedEquipment.amount;
      }

      Equipment[] memory __consumedEquipments;
      (
        __consumedEquipments,
        producedEquipment,
        xpElapsedTime,
        died,
        foodConsumed,
        baseInputItemsConsumedNum
      ) = _processConsumablesView(
        from,
        _playerId,
        queuedAction,
        veryStartTime,
        elapsedTime + prevProcessedTime,
        combatStats,
        actionChoice,
        pendingQueuedActionEquipmentStates,
        _pendingQueuedActionProcessed
      );
      delete extendedPendingQueuedActionEquipmentState;

      // Get the difference
      consumedEquipments = new Equipment[](__consumedEquipments.length); // This should be greater than _consumedEquipments
      uint consumedEquipmentsLength;
      for (uint j = 0; j < __consumedEquipments.length; ++j) {
        // Check if it exists in _consumedEquipments and if so, subtract the amount
        bool nonZero = true;
        for (uint k = 0; k < prevConsumedEquipments.length; ++k) {
          if (__consumedEquipments[j].itemTokenId == prevConsumedEquipments[k].itemTokenId) {
            if (__consumedEquipments[j].amount >= prevConsumedEquipments[k].amount) {
              __consumedEquipments[j].amount = uint24(
                __consumedEquipments[j].amount.sub(prevConsumedEquipments[k].amount)
              );
            } else {
              __consumedEquipments[j].amount = 0;
            }
            nonZero = __consumedEquipments[j].amount != 0;
            break;
          }
        }
        if (nonZero) {
          consumedEquipments[consumedEquipmentsLength++] = __consumedEquipments[j];
        }
      }

      assembly ("memory-safe") {
        mstore(consumedEquipments, consumedEquipmentsLength)
      }

      // Do the same for outputEquipment, check if it exists and subtract amount
      if (producedEquipment.amount >= prevProducedEquipment.amount) {
        producedEquipment.amount = uint24(producedEquipment.amount.sub(prevProducedEquipment.amount));
      } else {
        producedEquipment.amount = 0;
      }
      if (producedEquipment.amount == 0) {
        producedEquipment.itemTokenId = NONE;
      }

      if (xpElapsedTime >= prevXPElapsedTime) {
        // Maybe died
        xpElapsedTime = xpElapsedTime.sub(prevXPElapsedTime);
      }
      // These are scrolls/arrows, doesn't affect melee
      if (baseInputItemsConsumedNum >= currentActionProcessedBaseInputItemsConsumedNum) {
        baseInputItemsConsumedNum = uint16(
          baseInputItemsConsumedNum.sub(currentActionProcessedBaseInputItemsConsumedNum)
        );
      } else {
        baseInputItemsConsumedNum = 0;
      }

      if (foodConsumed >= currentActionProcessedFoodConsumed) {
        foodConsumed = uint16(foodConsumed.sub(currentActionProcessedFoodConsumed));
      } else {
        // Could be lower if combat equation or items change later
        foodConsumed = 0;
      }
    } else {
      (
        consumedEquipments,
        producedEquipment,
        xpElapsedTime,
        died,
        foodConsumed,
        baseInputItemsConsumedNum
      ) = _processConsumablesView(
        from,
        _playerId,
        queuedAction,
        veryStartTime,
        elapsedTime + prevProcessedTime,
        combatStats,
        actionChoice,
        pendingQueuedActionEquipmentStates,
        _pendingQueuedActionProcessed
      );
    }
  }

  function mintedPlayer(
    address _from,
    uint _playerId,
    Skill[2] calldata _startSkills,
    uint[] calldata _startingItemTokenIds,
    uint[] calldata _startingAmounts
  ) external {
    Player storage player = players_[_playerId];
    player.totalXP = uint56(START_XP_);

    U256 length = uint256(_startSkills[1] != Skill.NONE ? 2 : 1).asU256();
    uint32 xpEach = uint32(START_XP_ / length.asUint256());

    for (U256 iter; iter < length; iter = iter.inc()) {
      uint i = iter.asUint256();
      Skill skill = _startSkills[i];
      _updateXP(_from, _playerId, skill, xpEach);
    }

    player.skillBoosted1 = _startSkills[0];
    player.skillBoosted2 = _startSkills[1]; // Can be NONE

    // Mint starting equipment
    itemNFT.mintBatch(_from, _startingItemTokenIds, _startingAmounts);
  }

  function buyBrushQuest(address _to, uint _playerId, uint _questId, bool _useExactETH) external payable {
    // This is a one off quest
    bool success = quests.buyBrushQuest{value: msg.value}(msg.sender, _to, _playerId, _questId, _useExactETH);
    if (success) {
      (uint[] memory itemTokenIds, uint[] memory amounts, Skill skillGained, uint32 xpGained) = quests
        .getQuestCompletedRewards(QUEST_PURSE_STRINGS);

      if (itemTokenIds.length != 0) {
        // Not handled currently
        revert InvalidReward();
      }
      _updateXP(msg.sender, _playerId, skillGained, xpGained);
    }
  }

  // Random rewards
  function _setupRandomRewards(
    ActionRewards memory _rewards
  ) private pure returns (RandomReward[] memory randomRewards) {
    randomRewards = new RandomReward[](4);
    uint randomRewardLength;
    if (_rewards.randomRewardTokenId1 != 0) {
      randomRewards[randomRewardLength] = RandomReward(
        _rewards.randomRewardTokenId1,
        _rewards.randomRewardChance1,
        _rewards.randomRewardAmount1
      );
      randomRewardLength = randomRewardLength.inc();
    }
    if (_rewards.randomRewardTokenId2 != 0) {
      randomRewards[randomRewardLength] = RandomReward(
        _rewards.randomRewardTokenId2,
        _rewards.randomRewardChance2,
        _rewards.randomRewardAmount2
      );
      randomRewardLength = randomRewardLength.inc();
    }
    if (_rewards.randomRewardTokenId3 != 0) {
      randomRewards[randomRewardLength] = RandomReward(
        _rewards.randomRewardTokenId3,
        _rewards.randomRewardChance3,
        _rewards.randomRewardAmount3
      );
      randomRewardLength = randomRewardLength.inc();
    }
    if (_rewards.randomRewardTokenId4 != 0) {
      randomRewards[randomRewardLength] = RandomReward(
        _rewards.randomRewardTokenId4,
        _rewards.randomRewardChance4,
        _rewards.randomRewardAmount4
      );
      randomRewardLength = randomRewardLength.inc();
    }

    assembly ("memory-safe") {
      mstore(randomRewards, randomRewardLength)
    }
  }

  function _getSlice(bytes memory _b, uint _index) private pure returns (uint16) {
    uint256 index = _index.mul(2);
    return uint16(_b[index] | (bytes2(_b[index.inc()]) >> 8));
  }

  // hasRandomWord means there was pending reward we tried to get a reward from
  function getRandomRewards(
    uint _playerId,
    uint40 _skillStartTime,
    uint _elapsedTime,
    uint _numTickets,
    ActionRewards memory _actionRewards,
    uint8 _successPercent,
    uint8 _fullAttireBonusRewardsPercent
  ) external view returns (uint[] memory ids, uint[] memory amounts, bool hasRandomWord) {
    ids = new uint[](MAX_RANDOM_REWARDS_PER_ACTION);
    amounts = new uint[](MAX_RANDOM_REWARDS_PER_ACTION);
    uint length;

    RandomReward[] memory _randomRewards = _setupRandomRewards(_actionRewards);

    if (_randomRewards.length != 0) {
      uint skillEndTime = _skillStartTime.add(_elapsedTime);
      hasRandomWord = world.hasRandomWord(skillEndTime);
      if (hasRandomWord) {
        uint numIterations = Math.min(MAX_UNIQUE_TICKETS_, _numTickets);

        bytes memory randomBytes = world.getRandomBytes(numIterations, skillEndTime, _playerId);
        for (U256 iter; iter.lt(numIterations); iter = iter.inc()) {
          uint i = iter.asUint256();
          uint operation = (uint(_getSlice(randomBytes, i)) * 100) / _successPercent;

          // If there is above 240 tickets we need to mint more if a ticket is hit unless it
          // is a rare item in which case we just increase the change that it can get get

          // The random component is out of 65535, so we can take 2 bytes at a time from the total bytes array
          uint extraChance = (operation * _fullAttireBonusRewardsPercent) / 100;
          if (operation > extraChance) {
            operation -= extraChance;
          } else {
            operation = 1;
          }
          uint16 rand = uint16(Math.min(type(uint16).max, operation));

          U256 randomRewardsLength = _randomRewards.length.asU256();
          for (U256 iterJ; iterJ < randomRewardsLength; iterJ = iterJ.inc()) {
            uint j = iterJ.asUint256();
            RandomReward memory randomReward = _randomRewards[j];

            uint mintMultiplier = 1;
            uint remainder = _numTickets % MAX_UNIQUE_TICKETS_;
            uint16 updatedRand = rand;
            if (_numTickets > MAX_UNIQUE_TICKETS_) {
              uint multiplier = _numTickets / MAX_UNIQUE_TICKETS_;
              if (randomReward.chance < RANDOM_REWARD_CHANCE_MULTIPLIER_CUTOFF_) {
                // Rare item, increase chance if there aren't enough unique tickets
                if (i < remainder) {
                  ++multiplier;
                }
                uint16 extraChance = uint16(randomReward.chance * multiplier);
                if (updatedRand > extraChance) {
                  updatedRand -= extraChance;
                } else {
                  updatedRand = 1;
                }
              } else {
                mintMultiplier = multiplier;
                if (i < remainder) {
                  mintMultiplier = mintMultiplier.inc();
                }
              }
            }

            if (updatedRand <= randomReward.chance) {
              // This random reward's chance was hit, so add it
              bool found;
              U256 idsLength = length.asU256();
              // Add this random item
              for (U256 iterK; iterK < idsLength; iterK = iterK.inc()) {
                uint k = iterK.asUint256();
                if (randomReward.itemTokenId == ids[k]) {
                  // This item exists so accumulate it with the existing value
                  amounts[k] += randomReward.amount * mintMultiplier;
                  found = true;
                  break;
                }
              }

              if (!found) {
                // New item
                ids[length] = randomReward.itemTokenId;
                amounts[length] = randomReward.amount * mintMultiplier;
                length = length.inc();
              }
            } else {
              // A common one isn't found so a rarer one won't be.
              break;
            }
          }
        }
      }
    }
    assembly ("memory-safe") {
      mstore(ids, length)
      mstore(amounts, length)
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UnsafeMath, U256} from "@0xdoublesharp/unsafe-math/contracts/UnsafeMath.sol";

import {PlayersImplBase} from "./PlayersImplBase.sol";
import {PlayersBase} from "./PlayersBase.sol";
import {PlayersLibrary} from "./PlayersLibrary.sol";
import {IPlayersRewardsDelegateView, IPlayersRewardsDelegate, IPlayersMiscDelegate} from "../interfaces/IPlayersDelegates.sol";

// solhint-disable-next-line no-global-import
import "../globals/all.sol";

contract PlayersImplProcessActions is PlayersImplBase, PlayersBase {
  using UnsafeMath for U256;
  using UnsafeMath for uint8;
  using UnsafeMath for uint16;
  using UnsafeMath for uint24;
  using UnsafeMath for uint32;
  using UnsafeMath for uint40;
  using UnsafeMath for uint56;
  using UnsafeMath for uint128;
  using UnsafeMath for uint256;

  constructor() {
    _checkStartSlot();
  }

  function processActionsAndSetState(uint _playerId) external {
    (
      QueuedAction[] memory remainingQueuedActions,
      PendingQueuedActionData memory currentActionProcessed
    ) = processActions(msg.sender, _playerId);

    Player storage player = players_[_playerId];
    if (remainingQueuedActions.length != 0) {
      player.currentActionStartTime = uint40(block.timestamp);
    } else {
      player.currentActionStartTime = 0;
    }
    _setPrevPlayerState(player, currentActionProcessed);

    Attire[] memory remainingAttire = new Attire[](remainingQueuedActions.length);
    for (uint i = 0; i < remainingQueuedActions.length; ++i) {
      remainingAttire[i] = attire_[_playerId][remainingQueuedActions[i].queueId];
    }

    _setActionQueue(msg.sender, _playerId, remainingQueuedActions, remainingAttire, block.timestamp);
  }

  function processActions(
    address _from,
    uint _playerId
  )
    public
    returns (QueuedAction[] memory remainingQueuedActions, PendingQueuedActionData memory currentActionProcessed)
  {
    Player storage player = players_[_playerId];
    if (player.actionQueue.length == 0) {
      // No actions remaining
      PendingQueuedActionProcessed memory emptyPendingQueuedActionProcessed;
      _processActionsFinished(_from, _playerId, emptyPendingQueuedActionProcessed); // TODO: Could still use pendingQueuedActionState
      return (remainingQueuedActions, emptyPendingQueuedActionProcessed.currentAction);
    }
    PendingQueuedActionState memory pendingQueuedActionState = _pendingQueuedActionState(_from, _playerId);
    remainingQueuedActions = pendingQueuedActionState.remainingQueuedActions;
    PendingQueuedActionProcessed memory pendingQueuedActionProcessed = pendingQueuedActionState.processedData;
    currentActionProcessed = pendingQueuedActionProcessed.currentAction;
    // total xp is updated later
    for (uint i; i < pendingQueuedActionProcessed.skills.length; ++i) {
      _updateXP(
        _from,
        _playerId,
        pendingQueuedActionProcessed.skills[i],
        pendingQueuedActionProcessed.xpGainedSkills[i]
      );
    }

    uint startTime = players_[_playerId].currentActionStartTime;
    for (uint i = 0; i < pendingQueuedActionState.equipmentStates.length; ++i) {
      PendingQueuedActionEquipmentState memory equipmentState = pendingQueuedActionState.equipmentStates[i];
      PendingQueuedActionMetadata memory actionMetadata = pendingQueuedActionState.actionMetadatas[i];

      if (equipmentState.consumedItemTokenIds.length != 0) {
        itemNFT.burnBatch(_from, equipmentState.consumedItemTokenIds, equipmentState.consumedAmounts);
        emit Consumes(
          _from,
          _playerId,
          actionMetadata.queueId,
          equipmentState.consumedItemTokenIds,
          equipmentState.consumedAmounts
        );
      }
      if (equipmentState.producedItemTokenIds.length != 0) {
        itemNFT.mintBatch(_from, equipmentState.producedItemTokenIds, equipmentState.producedAmounts);
        emit Rewards(
          _from,
          _playerId,
          actionMetadata.queueId,
          equipmentState.producedItemTokenIds,
          equipmentState.producedAmounts
        );
      }

      ActionRewards memory actionRewards = world.getActionRewards(actionMetadata.actionId);

      ActionChoice memory actionChoice;
      QueuedAction storage queuedAction = players_[_playerId].actionQueue[i];
      bool isCombat = _isCombatStyle(queuedAction.combatStyle);
      if (queuedAction.choiceId != 0) {
        // Includes combat
        actionChoice = world.getActionChoice(isCombat ? NONE : queuedAction.actionId, queuedAction.choiceId);
      }

      Skill skill = _getSkillFromChoiceOrStyle(actionChoice, queuedAction.combatStyle, queuedAction.actionId);

      _addPendingRandomReward(
        _from,
        _playerId,
        actionRewards,
        actionMetadata.actionId,
        actionMetadata.queueId,
        uint40(startTime),
        actionMetadata.elapsedTime,
        actionMetadata.xpElapsedTime,
        attire_[_playerId][actionMetadata.queueId],
        skill,
        pendingQueuedActionState.equipmentStates
      );

      if (actionMetadata.died) {
        emit Died(_from, _playerId, actionMetadata.queueId);
      }
      // XP gained
      if (actionMetadata.xpGained != 0) {
        uint previousTotalXP = player.totalXP;
        uint newTotalXP = previousTotalXP.add(actionMetadata.xpGained);
        player.totalXP = uint56(newTotalXP);
      }
      bool fullyFinished = actionMetadata.elapsedTime >= queuedAction.timespan;
      if (fullyFinished) {
        emit ActionFinished(_from, _playerId, actionMetadata.queueId);
      } else {
        emit ActionPartiallyFinished(_from, _playerId, actionMetadata.queueId, actionMetadata.elapsedTime);
      }
      startTime += actionMetadata.elapsedTime;
    }

    // XP rewards
    if (pendingQueuedActionState.xpRewardItemTokenIds.length != 0) {
      itemNFT.mintBatch(_from, pendingQueuedActionState.xpRewardItemTokenIds, pendingQueuedActionState.xpRewardAmounts);
      emit ClaimedXPThresholdRewards(
        _from,
        _playerId,
        pendingQueuedActionState.xpRewardItemTokenIds,
        pendingQueuedActionState.xpRewardAmounts
      );
    }

    // Oracle loot from past random rewards
    if (pendingQueuedActionState.producedPastRandomRewards.length != 0) {
      PastRandomRewardInfo[] memory producedPastRandomRewards = pendingQueuedActionState.producedPastRandomRewards;

      uint[] memory itemTokenIds = new uint[](producedPastRandomRewards.length);
      uint[] memory amounts = new uint[](producedPastRandomRewards.length);
      uint[] memory queueIds = new uint[](producedPastRandomRewards.length);
      for (uint j = 0; j < producedPastRandomRewards.length; ++j) {
        itemTokenIds[j] = producedPastRandomRewards[j].itemTokenId;
        amounts[j] = producedPastRandomRewards[j].amount;
        queueIds[j] = producedPastRandomRewards[j].queueId;
      }
      _processClaimableRewards(
        _from,
        _playerId,
        itemTokenIds,
        amounts,
        queueIds,
        pendingQueuedActionState.numPastRandomRewardInstancesToRemove
      );
    }

    // Quests
    QuestState memory questState = pendingQueuedActionState.quests;
    quests.processQuests(_from, _playerId, questState.activeQuestInfo, questState.questsCompleted);
    if (questState.consumedItemTokenIds.length != 0 || questState.rewardItemTokenIds.length != 0) {
      if (questState.consumedItemTokenIds.length != 0) {
        itemNFT.burnBatch(_from, questState.consumedItemTokenIds, questState.consumedAmounts);
      }
      if (questState.rewardItemTokenIds.length != 0) {
        itemNFT.mintBatch(_from, questState.rewardItemTokenIds, questState.rewardAmounts);
      }
      emit QuestRewardConsumes(
        _from,
        _playerId,
        questState.rewardItemTokenIds,
        questState.rewardAmounts,
        questState.consumedItemTokenIds,
        questState.consumedAmounts
      );
    }

    // Any quest XP gains
    uint questXpGained;
    for (uint j; j < questState.skills.length; ++j) {
      _updateXP(_from, _playerId, questState.skills[j], questState.xpGainedSkills[j]);
      questXpGained += questState.xpGainedSkills[j];
    }
    if (questXpGained != 0) {
      player.totalXP = uint56(player.totalXP.add(questXpGained));
    }

    // Daily/weekly rewards
    if (pendingQueuedActionState.dailyRewardItemTokenIds.length != 0) {
      itemNFT.mintBatch(
        _from,
        pendingQueuedActionState.dailyRewardItemTokenIds,
        pendingQueuedActionState.dailyRewardAmounts
      );
      emit DailyReward(
        _from,
        _playerId,
        uint16(pendingQueuedActionState.dailyRewardItemTokenIds[0]),
        pendingQueuedActionState.dailyRewardAmounts[0]
      );

      if (pendingQueuedActionState.dailyRewardItemTokenIds.length == 2) {
        emit WeeklyReward(
          _from,
          _playerId,
          uint16(pendingQueuedActionState.dailyRewardItemTokenIds[1]),
          pendingQueuedActionState.dailyRewardAmounts[1]
        );
      }

      if (uint(pendingQueuedActionState.dailyRewardMask) != 0) {
        dailyRewardMasks[_playerId] = pendingQueuedActionState.dailyRewardMask;
      }
    }

    // Clear boost if it has expired
    PlayerBoostInfo storage playerBoost = activeBoosts_[_playerId];
    if (playerBoost.itemTokenId != NONE && playerBoost.startTime.add(playerBoost.duration) <= block.timestamp) {
      delete activeBoosts_[_playerId];
      emit BoostFinished(_playerId);
    }

    player.worldLocation = pendingQueuedActionState.worldLocation;
  }

  function _processActionsFinished(
    address _from,
    uint _playerId,
    PendingQueuedActionProcessed memory _pendingQueuedActionProcessed
  ) private {
    _claimRandomRewards(_playerId, _pendingQueuedActionProcessed);
    _handleDailyRewards(_from, _playerId);

    // Clear boost if it has expired
    PlayerBoostInfo storage playerBoost = activeBoosts_[_playerId];
    if (playerBoost.itemTokenId != NONE && playerBoost.startTime.add(playerBoost.duration) <= block.timestamp) {
      delete activeBoosts_[_playerId];
      emit BoostFinished(_playerId);
    }
  }

  function _claimRandomRewards(
    uint _playerId,
    PendingQueuedActionProcessed memory _pendingQueuedActionProcessed
  ) private {
    _delegatecall(
      implRewards,
      abi.encodeWithSelector(
        IPlayersRewardsDelegate.claimRandomRewards.selector,
        _playerId,
        _pendingQueuedActionProcessed
      )
    );
  }

  function _addPendingRandomReward(
    address _from,
    uint _playerId,
    ActionRewards memory _actionRewards,
    uint16 _actionId,
    uint64 _queueId,
    uint40 _skillStartTime,
    uint24 _elapsedTime,
    uint24 _xpElapsedTime,
    Attire storage _attire,
    Skill _skill,
    PendingQueuedActionEquipmentState[] memory _pendingQueuedActionEquipmentStates
  ) private {
    bool hasRandomRewards = _actionRewards.randomRewardTokenId1 != NONE; // A precheck as an optimization
    if (_xpElapsedTime != 0 && hasRandomRewards) {
      bool hasRandomWord = world.hasRandomWord(_skillStartTime.add(_elapsedTime));
      if (!hasRandomWord) {
        PlayerBoostInfo storage activeBoost = activeBoosts_[_playerId];
        BoostType boostType;
        uint40 boostStartTime;
        uint16 boostItemTokenId;
        if (activeBoost.boostType == BoostType.GATHERING) {
          uint24 boostedTime = PlayersLibrary.getBoostedTime(
            _skillStartTime,
            _xpElapsedTime,
            activeBoost.startTime,
            activeBoost.duration
          );
          if (boostedTime != 0) {
            boostType = activeBoost.boostType;
            boostItemTokenId = activeBoost.itemTokenId;
            boostStartTime = activeBoost.startTime;
          }
        }

        // Special case where thieving gives you a bonus if wearing full equipment
        uint8 bonusRewardsPercent = fullAttireBonus[_skill].bonusRewardsPercent;
        uint8 fullAttireBonusRewardsPercent = PlayersLibrary.getFullAttireBonusRewardsPercent(
          _from,
          _attire,
          itemNFT,
          _pendingQueuedActionEquipmentStates,
          bonusRewardsPercent,
          fullAttireBonus[_skill].itemTokenIds
        );

        // There's no random word for this yet, so add it to the loot queue. (TODO: They can force add it later)
        pendingRandomRewards[_playerId].push(
          PendingRandomReward({
            actionId: _actionId,
            queueId: _queueId,
            startTime: _skillStartTime,
            xpElapsedTime: uint24(_xpElapsedTime),
            elapsedTime: _elapsedTime,
            boostType: boostType,
            boostItemTokenId: boostItemTokenId,
            boostStartTime: boostStartTime,
            fullAttireBonusRewardsPercent: fullAttireBonusRewardsPercent
          })
        );
        emit AddPendingRandomReward(_from, _playerId, _queueId, _skillStartTime, _xpElapsedTime);
      }
    }
  }

  function _claimTotalXPThresholdRewards(address _from, uint _playerId, uint _oldTotalXP, uint _newTotalXP) private {
    (uint[] memory itemTokenIds, uint[] memory amounts) = _claimableXPThresholdRewards(_oldTotalXP, _newTotalXP);
    if (itemTokenIds.length != 0) {
      itemNFT.mintBatch(_from, itemTokenIds, amounts);
      emit ClaimedXPThresholdRewards(_from, _playerId, itemTokenIds, amounts);
    }
  }

  function testModifyXP(address _from, uint _playerId, Skill _skill, uint56 _xp, bool _force) external {
    if (!_force && players_[_playerId].actionQueue.length != 0) {
      revert HasQueuedActions();
    }

    // Make sure it isn't less XP
    uint oldPoints = PlayersLibrary.readXP(_skill, xp_[_playerId]);
    if (_xp < oldPoints) {
      revert TestInvalidXP();
    }
    if (playerNFT.balanceOf(_from, _playerId) == 0) {
      revert NotOwnerOfPlayer();
    }
    uint56 updatedPoints = uint56(_xp.sub(oldPoints));
    _updateXP(_from, _playerId, _skill, updatedPoints);
    uint56 newPoints = uint56(players_[_playerId].totalXP.add(updatedPoints));
    _claimTotalXPThresholdRewards(_from, _playerId, oldPoints, newPoints);
    players_[_playerId].totalXP = newPoints;
  }

  function _handleDailyRewards(address _from, uint _playerId) private {
    _delegatecall(implMisc, abi.encodeWithSelector(IPlayersMiscDelegate.handleDailyRewards.selector, _from, _playerId));
  }

  // Staticcall into ourselves and hit the fallback. This is done so that pendingQueuedActionState/dailyClaimedRewards can be exposed on the json abi.
  function _pendingQueuedActionState(
    address _owner,
    uint _playerId
  ) private view returns (PendingQueuedActionState memory) {
    bytes memory data = _staticcall(
      address(this),
      abi.encodeWithSelector(IPlayersRewardsDelegateView.pendingQueuedActionStateImpl.selector, _owner, _playerId)
    );
    return abi.decode(data, (PendingQueuedActionState));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UnsafeMath, U256} from "@0xdoublesharp/unsafe-math/contracts/UnsafeMath.sol";

import {PlayersImplBase} from "./PlayersImplBase.sol";
import {PlayersBase} from "./PlayersBase.sol";

import {World} from "../World.sol";
import {ItemNFT} from "../ItemNFT.sol";
import {AdminAccess} from "../AdminAccess.sol";

import {PlayersLibrary} from "./PlayersLibrary.sol";

// solhint-disable-next-line no-global-import
import "../globals/all.sol";

contract PlayersImplQueueActions is PlayersImplBase, PlayersBase {
  using UnsafeMath for U256;
  using UnsafeMath for uint16;
  using UnsafeMath for uint32;
  using UnsafeMath for uint64;
  using UnsafeMath for uint256;

  constructor() {
    _checkStartSlot();
  }

  function startActions(
    uint _playerId,
    QueuedActionInput[] memory _queuedActions,
    uint16 _boostItemTokenId,
    uint40 _boostStartTime,
    uint _questId,
    ActionQueueStatus _queueStatus
  ) external {
    address from = msg.sender;
    uint totalTimespan;
    (
      QueuedAction[] memory remainingQueuedActions,
      PendingQueuedActionData memory currentActionProcessed
    ) = _processActions(from, _playerId);

    Player storage player = players_[_playerId];
    if (_queueStatus == ActionQueueStatus.NONE) {
      if (player.actionQueue.length != 0) {
        // Clear action queue
        QueuedAction[] memory queuedActions;
        player.actionQueue = queuedActions;
      }
      // Don't care about remaining actions
      assembly ("memory-safe") {
        mstore(remainingQueuedActions, 0)
      }

      if (_queuedActions.length > 3) {
        revert TooManyActionsQueued();
      }
    } else {
      if (_queueStatus == ActionQueueStatus.KEEP_LAST_IN_PROGRESS && remainingQueuedActions.length > 1) {
        // Only want one
        assembly ("memory-safe") {
          mstore(remainingQueuedActions, 1)
        }
      }

      // Keep remaining actions
      if (remainingQueuedActions.length + _queuedActions.length > 3) {
        revert TooManyActionsQueuedSomeAlreadyExist();
      }
      player.actionQueue = remainingQueuedActions;
      U256 j = remainingQueuedActions.length.asU256();
      while (j.neq(0)) {
        j = j.dec();
        totalTimespan += remainingQueuedActions[j.asUint256()].timespan;
      }
    }

    if (
      (_queueStatus == ActionQueueStatus.KEEP_LAST_IN_PROGRESS || _queueStatus == ActionQueueStatus.APPEND) &&
      remainingQueuedActions.length != 0
    ) {
      _setPrevPlayerState(player, currentActionProcessed);
    } else {
      _clearCurrentActionProcessed(_playerId);
    }

    uint prevEndTime = block.timestamp.add(totalTimespan);

    U256 queueId = nextQueueId.asU256();
    U256 queuedActionsLength = _queuedActions.length.asU256();

    if (remainingQueuedActions.length != 0 || _queuedActions.length != 0) {
      player.currentActionStartTime = uint40(block.timestamp);
    } else {
      player.currentActionStartTime = 0;
    }

    for (U256 iter; iter != queuedActionsLength; iter = iter.inc()) {
      uint i = iter.asUint256();

      if (totalTimespan.add(_queuedActions[i].timespan) > MAX_TIME_) {
        // Must be the last one which will exceed the max time
        if (iter != queuedActionsLength.dec()) {
          revert ActionTimespanExceedsMaxTime();
        }
        // Shorten it so that it does not extend beyond the max time
        _queuedActions[i].timespan = uint24(MAX_TIME_.sub(totalTimespan));
      }

      _addToQueue(from, _playerId, _queuedActions[i], queueId.asUint64());

      queueId = queueId.inc();
      totalTimespan += _queuedActions[i].timespan;
      prevEndTime += _queuedActions[i].timespan;
    }

    // Create an array from remainingAttire and queuedActions passed in
    uint length = remainingQueuedActions.length + _queuedActions.length;
    Attire[] memory attire = new Attire[](length);
    for (uint i = 0; i < remainingQueuedActions.length; ++i) {
      attire[i] = attire_[_playerId][remainingQueuedActions[i].queueId];
    }
    for (uint i = 0; i < _queuedActions.length; ++i) {
      attire[i + remainingQueuedActions.length] = _queuedActions[i].attire;
    }

    emit SetActionQueue(from, _playerId, player.actionQueue, attire, player.currentActionStartTime);

    assert(totalTimespan <= MAX_TIME_); // Should never happen
    nextQueueId = queueId.asUint64();

    if (_questId != 0) {
      quests.activateQuest(_playerId, _questId);
    }

    if (_boostItemTokenId != NONE) {
      consumeBoost(from, _playerId, _boostItemTokenId, _boostStartTime);
    }
  }

  function consumeBoost(address _from, uint _playerId, uint16 _itemTokenId, uint40 _startTime) public {
    Item memory item = itemNFT.getItem(_itemTokenId);
    if (item.equipPosition != EquipPosition.BOOST_VIAL) {
      revert NotABoostVial();
    }
    if (_startTime >= block.timestamp + 7 days) {
      revert StartTimeTooFarInTheFuture();
    }
    if (_startTime < block.timestamp) {
      _startTime = uint40(block.timestamp);
    }

    // Burn it
    address from = msg.sender;
    itemNFT.burn(from, _itemTokenId, 1);

    // If there's an active potion which hasn't been consumed yet, then we can mint it back
    PlayerBoostInfo storage playerBoost = activeBoosts_[_playerId];
    if (playerBoost.itemTokenId != NONE && playerBoost.startTime > block.timestamp) {
      itemNFT.mint(from, playerBoost.itemTokenId, 1);
    }

    playerBoost.startTime = _startTime;
    playerBoost.duration = item.boostDuration;
    playerBoost.value = item.boostValue;
    playerBoost.boostType = item.boostType;
    playerBoost.itemTokenId = _itemTokenId;

    emit ConsumeBoostVial(_from, _playerId, playerBoost);
  }

  function _checkAddToQueue(QueuedActionInput memory _queuedAction) private view {
    if (_queuedAction.attire.ring != NONE) {
      revert UnsupportedAttire();
    }
    if (_queuedAction.attire.reserved1 != NONE) {
      revert UnsupportedAttire();
    }
    if (_queuedAction.regenerateId != NONE) {
      if (itemNFT.getItem(_queuedAction.regenerateId).equipPosition != EquipPosition.FOOD) {
        revert UnsupportedRegenerateItem();
      }
    }
  }

  function _addToQueue(address _from, uint _playerId, QueuedActionInput memory _queuedAction, uint64 _queueId) private {
    _checkAddToQueue(_queuedAction);
    Player storage _player = players_[_playerId];

    uint16 actionId = _queuedAction.actionId;

    (
      uint16 handItemTokenIdRangeMin,
      uint16 handItemTokenIdRangeMax,
      bool actionChoiceRequired,
      Skill actionSkill,
      uint32 actionMinXP,
      bool actionAvailable
    ) = world.getPermissibleItemsForAction(actionId);

    if (!actionAvailable) {
      revert ActionNotAvailable();
    }

    if (actionMinXP > 0 && PlayersLibrary.readXP(actionSkill, xp_[_playerId]) < actionMinXP) {
      revert ActionMinimumXPNotReached();
    }

    bool isCombat = actionSkill == Skill.COMBAT;

    // Check the actionChoice is valid
    ActionChoice memory actionChoice;
    if (actionChoiceRequired) {
      if (_queuedAction.choiceId == NONE) {
        revert ActionChoiceIdRequired();
      }
      actionChoice = world.getActionChoice(isCombat ? NONE : _queuedAction.actionId, _queuedAction.choiceId);

      if (PlayersLibrary.readXP(actionChoice.skill, xp_[_playerId]) < actionChoice.minXP) {
        revert ActionChoiceMinimumXPNotReached();
      }

      if (actionChoice.skill == Skill.NONE) {
        revert InvalidSkill();
      }

      // Timespan should be exact for the rate when travelling (e.g if it takes 2 hours, 2 hours should be queued)
      if (actionSkill == Skill.TRAVELLING) {
        if (_queuedAction.timespan != (RATE_MUL * 3600) / actionChoice.rate) {
          revert InvalidTravellingTimespan();
        }
      }
    } else if (_queuedAction.choiceId != NONE) {
      revert ActionChoiceIdNotRequired();
    }

    if (_queuedAction.timespan == 0) {
      revert EmptyTimespan();
    }

    {
      // Check combatStyle is only selected if queuedAction is combat
      bool combatStyleSelected = _queuedAction.combatStyle != CombatStyle.NONE;
      if (isCombat != combatStyleSelected) {
        revert InvalidCombatStyle();
      }
    }

    Attire memory attire = _queuedAction.attire;
    if (
      attire.head != NONE ||
      attire.neck != NONE ||
      attire.body != NONE ||
      attire.arms != NONE ||
      attire.legs != NONE ||
      attire.feet != NONE ||
      attire.ring != NONE
    ) {
      attire_[_playerId][_queueId] = _queuedAction.attire;
      _checkAttire(_from, _playerId, attire_[_playerId][_queueId]);
    }

    QueuedAction memory queuedAction;
    queuedAction.isValid = true;
    queuedAction.timespan = _queuedAction.timespan;
    queuedAction.queueId = _queueId;
    queuedAction.actionId = _queuedAction.actionId;
    queuedAction.regenerateId = _queuedAction.regenerateId;
    queuedAction.choiceId = _queuedAction.choiceId;
    queuedAction.rightHandEquipmentTokenId = _queuedAction.rightHandEquipmentTokenId;
    queuedAction.leftHandEquipmentTokenId = _queuedAction.leftHandEquipmentTokenId;
    queuedAction.combatStyle = _queuedAction.combatStyle;
    _player.actionQueue.push(queuedAction);

    _checkHandEquipments(
      _from,
      _playerId,
      [_queuedAction.leftHandEquipmentTokenId, _queuedAction.rightHandEquipmentTokenId],
      handItemTokenIdRangeMin,
      handItemTokenIdRangeMax,
      isCombat
    );

    _checkActionConsumables(_playerId, _queuedAction, actionChoice);
  }

  function _checkActionConsumables(
    uint _playerId,
    QueuedActionInput memory _queuedAction,
    ActionChoice memory actionChoice
  ) private view {
    if (_queuedAction.choiceId != NONE) {
      // Get all items for this
      uint16[] memory itemTokenIds = new uint16[](4);
      uint itemLength;

      if (_queuedAction.regenerateId != NONE) {
        itemTokenIds[itemLength] = _queuedAction.regenerateId;
        itemLength = itemLength.inc();
        (Skill skill, uint32 minXP, ) = itemNFT.getEquipPositionAndMinRequirement(itemTokenIds[itemLength.dec()]);
        if (PlayersLibrary.readXP(skill, xp_[_playerId]) < minXP) {
          revert ConsumableMinimumXPNotReached();
        }
      }
      if (actionChoice.inputTokenId1 != NONE) {
        itemTokenIds[itemLength] = actionChoice.inputTokenId1;
        itemLength = itemLength.inc();
      }
      if (actionChoice.inputTokenId2 != NONE) {
        itemTokenIds[itemLength] = actionChoice.inputTokenId2;
        itemLength = itemLength.inc();
      }
      if (actionChoice.inputTokenId3 != NONE) {
        itemTokenIds[itemLength] = actionChoice.inputTokenId3;
        itemLength = itemLength.inc();
      }
      assembly ("memory-safe") {
        mstore(itemTokenIds, itemLength)
      }
    }
  }

  function _checkEquipPosition(Attire storage _attire) private view {
    uint attireLength;
    uint16[] memory itemTokenIds = new uint16[](6);
    EquipPosition[] memory expectedEquipPositions = new EquipPosition[](6);
    if (_attire.head != NONE) {
      itemTokenIds[attireLength] = _attire.head;
      expectedEquipPositions[attireLength] = EquipPosition.HEAD;
      attireLength = attireLength.inc();
    }
    if (_attire.neck != NONE) {
      itemTokenIds[attireLength] = _attire.neck;
      expectedEquipPositions[attireLength] = EquipPosition.NECK;
      attireLength = attireLength.inc();
    }
    if (_attire.body != NONE) {
      itemTokenIds[attireLength] = _attire.body;
      expectedEquipPositions[attireLength] = EquipPosition.BODY;
      attireLength = attireLength.inc();
    }
    if (_attire.arms != NONE) {
      itemTokenIds[attireLength] = _attire.arms;
      expectedEquipPositions[attireLength] = EquipPosition.ARMS;
      attireLength = attireLength.inc();
    }
    if (_attire.legs != NONE) {
      itemTokenIds[attireLength] = _attire.legs;
      expectedEquipPositions[attireLength] = EquipPosition.LEGS;
      attireLength = attireLength.inc();
    }
    if (_attire.feet != NONE) {
      itemTokenIds[attireLength] = _attire.feet;
      expectedEquipPositions[attireLength] = EquipPosition.FEET;
      attireLength = attireLength.inc();
    }

    assembly ("memory-safe") {
      mstore(itemTokenIds, attireLength)
    }

    if (attireLength != 0) {
      EquipPosition[] memory equipPositions = itemNFT.getEquipPositions(itemTokenIds);
      U256 bounds = attireLength.asU256();
      for (U256 iter; iter < bounds; iter = iter.inc()) {
        uint i = iter.asUint256();
        if (expectedEquipPositions[i] != equipPositions[i]) {
          revert InvalidEquipPosition();
        }
      }
    }
  }

  // Checks they have sufficient balance to equip the items, and minimum skill points
  function _checkAttire(address _from, uint _playerId, Attire storage _attire) private view {
    // Check the user has these items
    _checkEquipPosition(_attire);

    bool skipNeck;
    PendingQueuedActionEquipmentState[] memory pendingQueuedActionEquipmentStates;
    (uint16[] memory itemTokenIds, uint[] memory balances) = PlayersLibrary.getAttireWithBalance(
      _from,
      _attire,
      itemNFT,
      skipNeck,
      pendingQueuedActionEquipmentStates
    );
    if (itemTokenIds.length != 0) {
      (Skill[] memory skills, uint32[] memory minXPs) = itemNFT.getMinRequirements(itemTokenIds);
      U256 iter = balances.length.asU256();
      while (iter.neq(0)) {
        iter = iter.dec();
        uint i = iter.asUint256();
        if (PlayersLibrary.readXP(skills[i], xp_[_playerId]) < minXPs[i]) {
          revert AttireMinimumXPNotReached();
        }
        if (balances[i] == 0) {
          revert NoItemBalance(itemTokenIds[i]);
        }
      }
    }
  }

  function _checkHandEquipments(
    address _from,
    uint _playerId,
    uint16[2] memory _equippedItemTokenIds, // left, right
    uint16 _handItemTokenIdRangeMin,
    uint16 _handItemTokenIdRangeMax,
    bool _isCombat
  ) private view {
    U256 iter = _equippedItemTokenIds.length.asU256();
    bool twoHanded;
    while (iter.neq(0)) {
      iter = iter.dec();
      uint i = iter.asUint256();
      bool isRightHand = i == 1;
      uint16 equippedItemTokenId = _equippedItemTokenIds[i];
      if (equippedItemTokenId != NONE) {
        if (
          _handItemTokenIdRangeMin != NONE &&
          (equippedItemTokenId < _handItemTokenIdRangeMin || equippedItemTokenId > _handItemTokenIdRangeMax)
        ) {
          revert InvalidHandEquipment(equippedItemTokenId);
        }

        uint256 balance = itemNFT.balanceOf(_from, equippedItemTokenId);
        if (balance == 0) {
          revert DoNotHaveEnoughQuantityToEquipToAction();
        }
        (Skill skill, uint32 minXP, EquipPosition equipPosition) = itemNFT.getEquipPositionAndMinRequirement(
          equippedItemTokenId
        );
        if (PlayersLibrary.readXP(skill, xp_[_playerId]) < minXP) {
          revert ItemMinimumXPNotReached();
        }
        if (isRightHand) {
          if (equipPosition != EquipPosition.RIGHT_HAND && equipPosition != EquipPosition.BOTH_HANDS) {
            revert IncorrectRightHandEquipment(equippedItemTokenId);
          }
          twoHanded = equipPosition == EquipPosition.BOTH_HANDS;
        } else {
          // left hand, if we've equipped a 2 handed weapon, we can't equip anything else
          if (twoHanded) {
            revert CannotEquipTwoHandedAndOtherEquipment();
          }
          if (equipPosition != EquipPosition.LEFT_HAND) {
            revert IncorrectLeftHandEquipment(equippedItemTokenId);
          }
        }
      } else {
        // Only combat actions can have no equipment
        // e.g smithing doesn't require anything equipped
        if (!_isCombat && _handItemTokenIdRangeMin != NONE && isRightHand) {
          revert IncorrectEquippedItem(equippedItemTokenId);
        }
      }
    }
  }

  function _clearActionQueue(address _from, uint _playerId) private {
    QueuedAction[] memory queuedActions;
    Attire[] memory attire;
    uint startTime = 0;
    _setActionQueue(_from, _playerId, queuedActions, attire, startTime);
  }

  function _clearCurrentActionProcessed(uint _playerId) private {
    Player storage player = players_[_playerId];
    player.currentActionProcessedSkill1 = Skill.NONE;
    player.currentActionProcessedXPGained1 = 0;
    player.currentActionProcessedSkill2 = Skill.NONE;
    player.currentActionProcessedXPGained2 = 0;
    player.currentActionProcessedSkill3 = Skill.NONE;
    player.currentActionProcessedXPGained3 = 0;
    player.currentActionProcessedFoodConsumed = 0;
    player.currentActionProcessedBaseInputItemsConsumedNum = 0;
  }

  // Consumes all the actions in the queue up to this time.
  // Unequips everything which is just emitting an event
  // Mints the boost vial if it hasn't been consumed at all yet
  // Removes all the actions from the queue
  function clearEverything(address _from, uint _playerId, bool _processTheActions) public {
    if (_processTheActions) {
      _processActions(_from, _playerId);
    }
    // Ensure player info is cleared
    _clearCurrentActionProcessed(_playerId);
    Player storage player = players_[_playerId];
    player.currentActionStartTime = 0;

    emit ClearAll(_from, _playerId);
    _clearActionQueue(_from, _playerId);
    // Can re-mint boost if it hasn't been consumed at all yet
    PlayerBoostInfo storage activeBoost = activeBoosts_[_playerId];
    if (activeBoost.boostType != BoostType.NONE && activeBoost.startTime > block.timestamp) {
      uint itemTokenId = activeBoost.itemTokenId;
      delete activeBoosts_[_playerId];
      itemNFT.mint(_from, itemTokenId, 1);
    }
  }

  function setActivePlayer(address _from, uint _playerId) external {
    uint existingActivePlayerId = activePlayer_[_from];
    // All attire and actions can be made for this player
    activePlayer_[_from] = _playerId;
    if (existingActivePlayerId == _playerId) {
      revert PlayerAlreadyActive();
    }
    if (existingActivePlayerId != 0) {
      // If there is an existing active player, unequip all items
      clearEverything(_from, existingActivePlayerId, true);
    }
    emit SetActivePlayer(_from, existingActivePlayerId, _playerId);
  }

  function unequipBoostVial(uint _playerId) external {
    if (activeBoosts_[_playerId].boostType == BoostType.NONE) {
      revert NoActiveBoost();
    }
    if (activeBoosts_[_playerId].startTime > block.timestamp) {
      revert BoostTimeAlreadyStarted();
    }
    address from = msg.sender;
    itemNFT.mint(from, activeBoosts_[_playerId].itemTokenId, 1);
    emit UnconsumeBoostVial(from, _playerId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UnsafeMath, U256} from "@0xdoublesharp/unsafe-math/contracts/UnsafeMath.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {PlayersImplBase} from "./PlayersImplBase.sol";
import {PlayersBase} from "./PlayersBase.sol";
import {PlayersLibrary} from "./PlayersLibrary.sol";
import {IPlayersRewardsDelegateView, IPlayersMiscDelegateView} from "../interfaces/IPlayersDelegates.sol";

// solhint-disable-next-line no-global-import
import "../globals/all.sol";

contract PlayersImplRewards is PlayersImplBase, PlayersBase, IPlayersRewardsDelegateView {
  using UnsafeMath for U256;
  using UnsafeMath for uint256;
  using UnsafeMath for uint40;
  using UnsafeMath for uint24;
  using UnsafeMath for uint16;

  constructor() {
    _checkStartSlot();
  }

  // Get any changes that are pending and not commited to the blockchain yet.
  // Such as items consumed/produced, xp gained, whether the player died, pending random reward rolls & quest rewards.
  function pendingQueuedActionStateImpl(
    address _owner,
    uint _playerId
  ) external view returns (PendingQueuedActionState memory pendingQueuedActionState) {
    Player storage player = players_[_playerId];
    QueuedAction[] storage actionQueue = player.actionQueue;
    pendingQueuedActionState.worldLocation = player.worldLocation;
    pendingQueuedActionState.equipmentStates = new PendingQueuedActionEquipmentState[](actionQueue.length + 1); // reserve +1 for handling the previously processed in current action
    pendingQueuedActionState.actionMetadatas = new PendingQueuedActionMetadata[](actionQueue.length + 1);

    PendingQueuedActionProcessed memory pendingQueuedActionProcessed = pendingQueuedActionState.processedData;
    pendingQueuedActionProcessed.skills = new Skill[](actionQueue.length * 2); // combat can have xp rewarded in 2 skills (combat + health)
    pendingQueuedActionProcessed.xpGainedSkills = new uint32[](actionQueue.length * 2);
    uint pendingQueuedActionProcessedLength;

    // This is done so that we can start the full XP calculation using the same stats as when the action was originally started
    PendingQueuedActionData memory currentActionProcessed = pendingQueuedActionProcessed.currentAction;
    currentActionProcessed.skill1 = player.currentActionProcessedSkill1;
    currentActionProcessed.xpGained1 = player.currentActionProcessedXPGained1;
    currentActionProcessed.skill2 = player.currentActionProcessedSkill2;
    currentActionProcessed.xpGained2 = player.currentActionProcessedXPGained2;
    currentActionProcessed.skill3 = player.currentActionProcessedSkill3;
    currentActionProcessed.xpGained3 = player.currentActionProcessedXPGained3;
    currentActionProcessed.foodConsumed = player.currentActionProcessedFoodConsumed;
    currentActionProcessed.baseInputItemsConsumedNum = player.currentActionProcessedBaseInputItemsConsumedNum;

    pendingQueuedActionState.remainingQueuedActions = new QueuedAction[](actionQueue.length);
    uint remainingQueuedActionsLength;

    // Past Random Rewards
    PendingQueuedActionProcessed memory emptyPendingQueuedActionProcessed;
    (
      uint[] memory ids,
      uint[] memory amounts,
      uint[] memory queueIds,
      uint numPastRandomRewardInstancesToRemove
    ) = _claimableRandomRewards(_playerId, emptyPendingQueuedActionProcessed);
    U256 idsLength = ids.length.asU256();

    pendingQueuedActionState.producedPastRandomRewards = new PastRandomRewardInfo[](
      actionQueue.length * MAX_RANDOM_REWARDS_PER_ACTION + ids.length
    );
    uint producedPastRandomRewardsLength;

    for (U256 iter; iter < idsLength; iter = iter.inc()) {
      uint i = iter.asUint256();
      pendingQueuedActionState.producedPastRandomRewards[producedPastRandomRewardsLength++] = PastRandomRewardInfo(
        uint64(queueIds[i]),
        uint16(ids[i]),
        uint24(amounts[i])
      );
    }

    pendingQueuedActionState.numPastRandomRewardInstancesToRemove = numPastRandomRewardInstancesToRemove;

    uint[] memory actionIds = new uint[](actionQueue.length);
    uint[] memory actionAmounts = new uint[](actionQueue.length);
    uint[] memory choiceIds = new uint[](actionQueue.length);
    uint[] memory choiceAmounts = new uint[](actionQueue.length);
    uint actionIdsLength;
    uint choiceIdsLength;

    address from = _owner;
    if (playerNFT.balanceOf(_owner, _playerId) == 0) {
      revert NotOwnerOfPlayer();
    }
    uint previousTotalXP = player.totalXP;
    uint totalXPGained;
    U256 bounds = actionQueue.length.asU256();
    uint pendingQueuedActionStateLength;
    uint startTime = players_[_playerId].currentActionStartTime;
    Skill firstRemainingActionSkill; // Can be Skill.COMBAT or Skill.TRAVELLING
    for (U256 iter; iter < bounds; iter = iter.inc()) {
      uint i = iter.asUint256();
      PendingQueuedActionEquipmentState memory pendingQueuedActionEquipmentState = pendingQueuedActionState
        .equipmentStates[i];
      PendingQueuedActionMetadata memory pendingQueuedActionMetadata = pendingQueuedActionState.actionMetadatas[i];
      pendingQueuedActionEquipmentState.producedItemTokenIds = new uint[](MAX_GUARANTEED_REWARDS_PER_ACTION);
      pendingQueuedActionEquipmentState.producedAmounts = new uint[](MAX_GUARANTEED_REWARDS_PER_ACTION);
      uint producedLength;
      pendingQueuedActionEquipmentState.consumedItemTokenIds = new uint[](MAX_CONSUMED_PER_ACTION);
      pendingQueuedActionEquipmentState.consumedAmounts = new uint[](MAX_CONSUMED_PER_ACTION);
      uint consumedLength;

      QueuedAction storage queuedAction = actionQueue[i];
      uint32 pointsAccrued;
      uint endTime = startTime + queuedAction.timespan;

      (ActionRewards memory actionRewards, Skill actionSkill, uint numSpawnedPerHour, uint8 worldLocation) = world
        .getRewardsHelper(queuedAction.actionId);

      uint elapsedTime = _getElapsedTime(startTime, endTime);
      bool correctWorldLocation = worldLocation == pendingQueuedActionState.worldLocation;
      if (elapsedTime == 0 || !correctWorldLocation) {
        _addRemainingQueuedAction(
          pendingQueuedActionState.remainingQueuedActions,
          queuedAction,
          queuedAction.timespan,
          0,
          0,
          remainingQueuedActionsLength
        );
        remainingQueuedActionsLength = remainingQueuedActionsLength.inc();
        startTime += queuedAction.timespan;
        continue;
      }

      // Also need to check the starting location is valid
      CombatStats memory combatStats;
      bool isCombat = _isCombatStyle(queuedAction.combatStyle);
      if (isCombat) {
        combatStats = PlayersLibrary.getCombatStats(
          pendingQueuedActionProcessed,
          xp_[_playerId],
          from,
          itemNFT,
          attire_[_playerId][queuedAction.queueId],
          pendingQueuedActionState.equipmentStates
        );
      }

      bool missingRequiredHandEquipment;
      (missingRequiredHandEquipment, combatStats) = PlayersLibrary.updateStatsFromHandEquipment(
        from,
        itemNFT,
        [queuedAction.rightHandEquipmentTokenId, queuedAction.leftHandEquipmentTokenId],
        combatStats,
        isCombat,
        pendingQueuedActionState.equipmentStates
      );

      if (missingRequiredHandEquipment) {
        if (i == 0) {
          // Clear the state and make sure the next queued action can finish
          clearActionProcessed(currentActionProcessed);
        }
        startTime += queuedAction.timespan;
        continue;
      }
      ++pendingQueuedActionStateLength;

      pendingQueuedActionMetadata.elapsedTime = uint24(elapsedTime);
      pendingQueuedActionMetadata.actionId = queuedAction.actionId;
      pendingQueuedActionMetadata.queueId = queuedAction.queueId;

      // Create some items if necessary (smithing ores to bars for instance)
      bool fullyFinished = elapsedTime >= queuedAction.timespan;
      bool died;
      firstRemainingActionSkill = actionSkill;
      bool actionHasRandomRewards = actionRewards.randomRewardTokenId1 != NONE;
      ActionChoice memory actionChoice;
      uint xpElapsedTime = elapsedTime;
      uint prevXPElapsedTime = queuedAction.prevProcessedXPTime;
      uint16 foodConsumed;
      uint16 baseInputItemsConsumedNum;
      if (queuedAction.choiceId != 0) {
        actionChoice = world.getActionChoice(isCombat ? 0 : queuedAction.actionId, queuedAction.choiceId);

        Equipment[] memory consumedEquipments;
        Equipment memory producedEquipment;
        (
          consumedEquipments,
          producedEquipment,
          xpElapsedTime,
          died,
          foodConsumed,
          baseInputItemsConsumedNum
        ) = _processConsumablesView(
          from,
          _playerId,
          queuedAction,
          actionChoice,
          combatStats,
          elapsedTime,
          startTime,
          pendingQueuedActionState.equipmentStates,
          pendingQueuedActionState.processedData
        );
        uint numChoicesCompleted;
        if (actionSkill == Skill.COOKING) {
          numChoicesCompleted = producedEquipment.amount; // Assume we want amount cooked
        } else {
          numChoicesCompleted = baseInputItemsConsumedNum;
        }
        if (numChoicesCompleted != 0) {
          choiceIds[choiceIdsLength] = queuedAction.choiceId;
          choiceAmounts[choiceIdsLength] = numChoicesCompleted;
          choiceIdsLength = choiceIdsLength.inc();
        }

        uint numActionsCompleted;
        if (actionSkill == Skill.COMBAT) {
          // Want monsters killed
          uint prevActionsCompleted = uint16((numSpawnedPerHour * prevXPElapsedTime) / (3600 * SPAWN_MUL));
          numActionsCompleted =
            uint16((numSpawnedPerHour * (xpElapsedTime + prevXPElapsedTime)) / (3600 * SPAWN_MUL)) -
            prevActionsCompleted;
        } else {
          // Not currently used
        }

        if (numActionsCompleted != 0) {
          actionIds[actionIdsLength] = queuedAction.actionId;
          actionAmounts[actionIdsLength] = numActionsCompleted;
          actionIdsLength = actionIdsLength.inc();
        }

        if (producedEquipment.itemTokenId != NONE) {
          pendingQueuedActionEquipmentState.producedItemTokenIds[producedLength] = producedEquipment.itemTokenId;
          pendingQueuedActionEquipmentState.producedAmounts[producedLength] = producedEquipment.amount;
          producedLength = producedLength.inc();
        }
        U256 consumedEquipmentLength = consumedEquipments.length.asU256();
        for (U256 jter; jter < consumedEquipmentLength; jter = jter.inc()) {
          uint j = jter.asUint256();
          pendingQueuedActionEquipmentState.consumedItemTokenIds[consumedLength] = consumedEquipments[j].itemTokenId;
          pendingQueuedActionEquipmentState.consumedAmounts[consumedLength] = consumedEquipments[j].amount;
          consumedLength = consumedLength.inc();
        }

        if (died) {
          pendingQueuedActionMetadata.died = true;
        }

        if (fullyFinished && actionSkill == Skill.TRAVELLING) {
          // Get the new world location
          pendingQueuedActionState.worldLocation = uint8(actionChoice.outputAmount);
        }
      } else {
        if (queuedAction.prevProcessedTime != 0) {
          // PrevXP
          bool hasGuaranteedRewards = actionRewards.guaranteedRewardTokenId1 != NONE;
          uint previouslyRefundedTime;
          uint refundTime;
          if (hasGuaranteedRewards) {
            uint numProduced = (uint(queuedAction.prevProcessedTime) * actionRewards.guaranteedRewardRate1) /
              (3600 * GUAR_MUL);
            previouslyRefundedTime =
              queuedAction.prevProcessedTime -
              (numProduced * (3600 * GUAR_MUL)) /
              actionRewards.guaranteedRewardRate1;

            // Get remainder for current too
            uint numProduced1 = ((elapsedTime + queuedAction.prevProcessedTime) * actionRewards.guaranteedRewardRate1) /
              (3600 * GUAR_MUL);
            refundTime =
              (elapsedTime + queuedAction.prevProcessedTime) -
              (numProduced1 * (3600 * GUAR_MUL)) /
              actionRewards.guaranteedRewardRate1;
          }

          if (actionHasRandomRewards) {
            uint tempRefundTime = queuedAction.prevProcessedTime % 3600;
            if (tempRefundTime > refundTime) {
              previouslyRefundedTime = tempRefundTime;
            }

            tempRefundTime = (elapsedTime + previouslyRefundedTime) % 3600;
            if (tempRefundTime > refundTime) {
              refundTime = tempRefundTime;
            }
          }

          xpElapsedTime = elapsedTime + queuedAction.prevProcessedTime - refundTime - prevXPElapsedTime;
        } else {
          bool hasGuaranteedRewards = actionRewards.guaranteedRewardTokenId1 != NONE;
          uint refundTime;
          if (hasGuaranteedRewards) {
            uint numProduced = (elapsedTime * actionRewards.guaranteedRewardRate1) / (3600 * GUAR_MUL);
            refundTime = elapsedTime - (numProduced * (3600 * GUAR_MUL)) / actionRewards.guaranteedRewardRate1;
          }

          if (actionHasRandomRewards) {
            uint tempRefundTime = elapsedTime % 3600;
            if (tempRefundTime > refundTime) {
              refundTime = tempRefundTime;
            }
          }
          xpElapsedTime = xpElapsedTime > refundTime ? xpElapsedTime.sub(refundTime) : 0;
        }

        uint numActionsCompleted;
        if (actionSkill == Skill.THIEVING) {
          // Hours thieving
          uint prevNumActionsCompleted = prevXPElapsedTime / 3600;
          numActionsCompleted = ((xpElapsedTime + prevXPElapsedTime) / 3600) - prevNumActionsCompleted;
        } else {
          // Output produced
          uint prevNumActionsCompleted = (uint(prevXPElapsedTime) * actionRewards.guaranteedRewardRate1) /
            (3600 * GUAR_MUL);
          numActionsCompleted =
            (uint(prevXPElapsedTime + xpElapsedTime) * actionRewards.guaranteedRewardRate1) /
            (3600 * GUAR_MUL) -
            prevNumActionsCompleted;
        }
        if (numActionsCompleted != 0) {
          actionIds[actionIdsLength] = queuedAction.actionId;
          actionAmounts[actionIdsLength] = numActionsCompleted;
          actionIdsLength = actionIdsLength.inc();
        }
      }

      uint pointsAccruedExclBaseBoost;
      uint prevProcessedTime = queuedAction.prevProcessedTime;
      uint veryStartTime = startTime.sub(prevProcessedTime);
      uint prevPointsAccrued;
      uint prevPointsAccruedExclBaseBoost;
      Skill skill = _getSkillFromChoiceOrStyle(actionChoice, queuedAction.combatStyle, queuedAction.actionId);
      (pointsAccrued, pointsAccruedExclBaseBoost) = _getPointsAccrued(
        from,
        _playerId,
        queuedAction,
        veryStartTime,
        skill,
        xpElapsedTime + prevXPElapsedTime,
        pendingQueuedActionState.equipmentStates
      );

      if (prevProcessedTime != 0) {
        (prevPointsAccrued, prevPointsAccruedExclBaseBoost) = _getPointsAccrued(
          from,
          _playerId,
          queuedAction,
          veryStartTime,
          skill,
          prevXPElapsedTime,
          pendingQueuedActionState.equipmentStates
        );

        pointsAccrued -= uint32(prevPointsAccrued);
        pointsAccruedExclBaseBoost -= uint32(prevPointsAccruedExclBaseBoost);
      }

      pendingQueuedActionMetadata.xpElapsedTime = uint24(xpElapsedTime);
      uint32 xpGained = pointsAccrued;
      uint32 healthPointsGained;
      if (pointsAccruedExclBaseBoost != 0 && _isCombatStyle(queuedAction.combatStyle)) {
        healthPointsGained = _getHealthPointsFromCombat(
          _playerId,
          pointsAccruedExclBaseBoost + prevPointsAccruedExclBaseBoost
        );
        if (prevPointsAccrued != 0) {
          // Remove old
          healthPointsGained -= _getHealthPointsFromCombat(_playerId, prevPointsAccruedExclBaseBoost);
        }
        xpGained += healthPointsGained;
      }

      bool hasCombatXP = pointsAccruedExclBaseBoost != 0 && _isCombatStyle(queuedAction.combatStyle);

      if (pointsAccrued != 0) {
        pendingQueuedActionProcessed.skills[pendingQueuedActionProcessedLength] = skill;
        pendingQueuedActionProcessed.xpGainedSkills[pendingQueuedActionProcessedLength++] = pointsAccrued;
        if (hasCombatXP) {
          pendingQueuedActionProcessed.skills[pendingQueuedActionProcessedLength] = Skill.HEALTH;
          pendingQueuedActionProcessed.xpGainedSkills[pendingQueuedActionProcessedLength++] = healthPointsGained;
        }
      }

      // Include loot
      {
        uint8 bonusRewardsPercent = fullAttireBonus[skill].bonusRewardsPercent;
        uint8 fullAttireBonusRewardsPercent = PlayersLibrary.getFullAttireBonusRewardsPercent(
          from,
          attire_[_playerId][queuedAction.queueId],
          itemNFT,
          pendingQueuedActionState.equipmentStates,
          bonusRewardsPercent,
          fullAttireBonus[skill].itemTokenIds
        );

        // Full
        if (xpElapsedTime != 0) {
          (
            uint[] memory newIds,
            uint[] memory newAmounts,
            uint[] memory newRandomIds,
            uint[] memory newRandomAmounts
          ) = _getRewards(
              _playerId,
              uint40(startTime),
              prevXPElapsedTime,
              xpElapsedTime,
              elapsedTime,
              prevProcessedTime,
              queuedAction.actionId,
              pendingQueuedActionProcessed,
              fullAttireBonusRewardsPercent
            );

          // Guaranteed rewards
          U256 newIdsLength = newIds.length.asU256();
          for (U256 jter; jter < newIdsLength; jter = jter.inc()) {
            uint j = jter.asUint256();
            pendingQueuedActionEquipmentState.producedItemTokenIds[producedLength] = newIds[j];
            pendingQueuedActionEquipmentState.producedAmounts[producedLength] = newAmounts[j];
            producedLength = producedLength.inc();
          }

          // Random rewards that can be claimed already from actions which ended in the previous 00:00
          // and processing is done afterwards and the oracle is called, so no pending dice rolls are needed
          U256 newRandomIdsLength = newRandomIds.length.asU256();
          for (U256 jter; jter < newRandomIdsLength; jter = jter.inc()) {
            uint j = jter.asUint256();
            pendingQueuedActionState.producedPastRandomRewards[
              producedPastRandomRewardsLength++
            ] = PastRandomRewardInfo(
              uint64(queuedAction.queueId),
              uint16(newRandomIds[j]),
              uint24(newRandomAmounts[j])
            );
          }
        }
      }

      if (!fullyFinished) {
        // Add the remainder if this action is not fully consumed
        uint remainingTimespan = queuedAction.timespan - elapsedTime;
        _addRemainingQueuedAction(
          pendingQueuedActionState.remainingQueuedActions,
          queuedAction,
          remainingTimespan,
          elapsedTime,
          xpElapsedTime,
          remainingQueuedActionsLength
        );
        remainingQueuedActionsLength = remainingQueuedActionsLength.inc();

        if (i == 0) {
          // Append it (or set it absolutely if unset)
          currentActionProcessed.skill1 = skill;
          currentActionProcessed.xpGained1 += uint24(pointsAccrued);
          if (hasCombatXP) {
            currentActionProcessed.skill2 = Skill.HEALTH;
            currentActionProcessed.xpGained2 += uint24(healthPointsGained);
          }

          currentActionProcessed.foodConsumed += foodConsumed;
          currentActionProcessed.baseInputItemsConsumedNum += baseInputItemsConsumedNum;
        } else {
          // Set it absolutely, this is a fresh "first action"
          currentActionProcessed.skill1 = skill;
          currentActionProcessed.xpGained1 = uint24(pointsAccrued);
          if (hasCombatXP) {
            currentActionProcessed.skill2 = Skill.HEALTH;
            currentActionProcessed.xpGained2 = uint24(healthPointsGained);
          } else {
            currentActionProcessed.skill2 = Skill.NONE;
            currentActionProcessed.xpGained2 = 0;
          }
          currentActionProcessed.foodConsumed = foodConsumed;
          currentActionProcessed.baseInputItemsConsumedNum = baseInputItemsConsumedNum;
        }
      } else {
        clearActionProcessed(currentActionProcessed);
      }

      // Total XP gained
      pendingQueuedActionMetadata.xpGained = xpGained;
      totalXPGained += xpGained;

      // Number of pending reward rolls
      if (actionHasRandomRewards) {
        bool hasRandomWord = world.hasRandomWord(startTime + elapsedTime);
        if (!hasRandomWord) {
          if (isCombat) {
            uint prevMonstersKilled = (numSpawnedPerHour * prevXPElapsedTime) / (SPAWN_MUL * 3600);
            uint16 monstersKilled = uint16(
              (numSpawnedPerHour * (xpElapsedTime + prevXPElapsedTime)) / (SPAWN_MUL * 3600) - prevMonstersKilled
            );
            pendingQueuedActionMetadata.rolls = uint32(monstersKilled);
          } else {
            uint prevRolls = prevXPElapsedTime / 3600;
            pendingQueuedActionMetadata.rolls = uint32((xpElapsedTime + prevXPElapsedTime) / 3600 - prevRolls);
          }
        }
      }

      // Compact to fit the arrays
      assembly ("memory-safe") {
        mstore(mload(pendingQueuedActionEquipmentState), consumedLength)
        mstore(mload(add(pendingQueuedActionEquipmentState, 32)), consumedLength)
        mstore(mload(add(pendingQueuedActionEquipmentState, 64)), producedLength)
        mstore(mload(add(pendingQueuedActionEquipmentState, 96)), producedLength)
      }
      startTime += queuedAction.timespan;
    } // end of loop

    // Quest Rewards
    QuestState memory questState = pendingQueuedActionState.quests;
    // Anything burnt happens after the actions are processed, so do not affect anything else.
    uint burnedAmountOwned;
    uint activeQuestBurnedItemTokenId = quests.getActiveQuestBurnedItemTokenId(_playerId);
    if (activeQuestBurnedItemTokenId != NONE) {
      burnedAmountOwned = PlayersLibrary.getRealBalance(
        from,
        activeQuestBurnedItemTokenId,
        itemNFT,
        pendingQueuedActionState.equipmentStates
      );
    }

    (
      questState.rewardItemTokenIds,
      questState.rewardAmounts,
      questState.consumedItemTokenIds,
      questState.consumedAmounts,
      questState.skills,
      questState.xpGainedSkills,
      questState.questsCompleted,
      questState.activeQuestInfo
    ) = quests.processQuestsView(_playerId, actionIds, actionAmounts, choiceIds, choiceAmounts, burnedAmountOwned);

    for (uint i = 0; i < questState.xpGainedSkills.length; ++i) {
      totalXPGained += questState.xpGainedSkills[i];

      if (remainingQueuedActionsLength != 0) {
        Skill questSkill = questState.skills[i];
        uint24 xpGainedSkill = uint24(questState.xpGainedSkills[i]);
        if (currentActionProcessed.skill1 == questSkill) {
          currentActionProcessed.xpGained1 += xpGainedSkill;
        } else if (currentActionProcessed.skill2 == questSkill) {
          currentActionProcessed.xpGained2 += xpGainedSkill;
        } else if (firstRemainingActionSkill == Skill.COMBAT && questSkill == Skill.DEFENCE) {
          // Special case for combat where you are training attack
          currentActionProcessed.skill3 = questSkill;
          currentActionProcessed.xpGained3 += xpGainedSkill;
        }
      }
    }

    // XPRewards
    if (totalXPGained != 0) {
      (
        pendingQueuedActionState.xpRewardItemTokenIds,
        pendingQueuedActionState.xpRewardAmounts
      ) = _claimableXPThresholdRewards(previousTotalXP, previousTotalXP + totalXPGained);
    }

    assembly ("memory-safe") {
      mstore(actionIds, actionIdsLength)
      mstore(actionAmounts, actionIdsLength)

      mstore(choiceIds, choiceIdsLength)
      mstore(choiceAmounts, choiceIdsLength)
    }

    // Daily rewards
    (
      pendingQueuedActionState.dailyRewardItemTokenIds,
      pendingQueuedActionState.dailyRewardAmounts,
      pendingQueuedActionState.dailyRewardMask
    ) = _dailyRewardsView(_playerId);

    // Compact to fit the array
    assembly ("memory-safe") {
      mstore(mload(pendingQueuedActionState), pendingQueuedActionStateLength)
      mstore(mload(add(pendingQueuedActionState, 32)), pendingQueuedActionStateLength)
      mstore(mload(add(pendingQueuedActionState, 64)), remainingQueuedActionsLength)
      mstore(mload(add(pendingQueuedActionState, 96)), producedPastRandomRewardsLength)

      mstore(mload(pendingQueuedActionProcessed), pendingQueuedActionProcessedLength)
      mstore(mload(add(pendingQueuedActionProcessed, 32)), pendingQueuedActionProcessedLength)
    }
  }

  function claimRandomRewards(
    uint _playerId,
    PendingQueuedActionProcessed memory _pendingQueuedActionProcessed
  ) external {
    address from = msg.sender;
    (
      uint[] memory ids,
      uint[] memory amounts,
      uint[] memory queueIds,
      uint numPastRandomRewardInstancesToRemove
    ) = _claimableRandomRewards(_playerId, _pendingQueuedActionProcessed);
    _processClaimableRewards(from, _playerId, ids, amounts, queueIds, numPastRandomRewardInstancesToRemove);
  }

  function _getRewards(
    uint _playerId,
    uint40 _startTime,
    uint _prevXPElapsedTime,
    uint _xpElapsedTime,
    uint _elapsedTime,
    uint _prevProcessedTime,
    uint16 _actionId,
    PendingQueuedActionProcessed memory _pendingQueuedActionProcessed,
    uint8 _fullAttireBonusRewardsPercent
  )
    private
    view
    returns (uint[] memory ids, uint[] memory amounts, uint[] memory randomIds, uint[] memory randomAmounts)
  {
    (ActionRewards memory actionRewards, Skill actionSkill, uint numSpawnedPerHour, ) = world.getRewardsHelper(
      _actionId
    );
    bool isCombat = actionSkill == Skill.COMBAT;

    uint16 monstersKilledFull = uint16(
      (numSpawnedPerHour * (_prevXPElapsedTime + _xpElapsedTime)) / (SPAWN_MUL * 3600)
    );
    uint8 successPercent = _getSuccessPercent(
      _playerId,
      _actionId,
      actionSkill,
      isCombat,
      _pendingQueuedActionProcessed
    );

    uint veryStartTime = _startTime.sub(_prevProcessedTime);
    // Full
    uint length;
    (ids, amounts, length) = _getGuaranteedRewards(
      _playerId,
      uint40(veryStartTime),
      _prevXPElapsedTime + _xpElapsedTime,
      actionRewards,
      monstersKilledFull,
      isCombat,
      successPercent
    );
    // Previously accumulated
    uint[] memory prevNewIds;
    uint[] memory prevNewAmounts;
    if (_prevXPElapsedTime != 0) {
      uint prevLength;
      uint16 monstersKilled = uint16((numSpawnedPerHour * _prevXPElapsedTime) / (SPAWN_MUL * 3600));

      (prevNewIds, prevNewAmounts, prevLength) = _getGuaranteedRewards(
        _playerId,
        uint40(veryStartTime),
        _prevXPElapsedTime,
        actionRewards,
        monstersKilled,
        isCombat,
        successPercent
      );
    }

    // Subtract any rewards that were already claimed
    if (prevNewIds.length != 0) {
      (ids, amounts) = PlayersLibrary.subtractMatchingRewards(ids, amounts, prevNewIds, prevNewAmounts);
    }

    // Any random rewards unlocked
    uint16 monstersKilled = uint16((numSpawnedPerHour * _xpElapsedTime) / (SPAWN_MUL * 3600));
    (randomIds, randomAmounts, ) = _getRandomRewards(
      _playerId,
      _startTime,
      _elapsedTime,
      isCombat ? monstersKilled : _xpElapsedTime / 3600,
      actionRewards,
      successPercent,
      _fullAttireBonusRewardsPercent
    );

    // Check for any boosts for random rewards (guaranteed rewards already have boosts applied)
    PlayerBoostInfo storage activeBoost = activeBoosts_[_playerId];
    if (activeBoost.boostType == BoostType.GATHERING) {
      uint boostedTime = PlayersLibrary.getBoostedTime(
        _startTime,
        _xpElapsedTime,
        activeBoost.startTime,
        activeBoost.duration
      );
      _addGatheringBoostedAmounts(boostedTime, randomAmounts, activeBoost.value, _elapsedTime);
    }
  }

  function _addGatheringBoostedAmounts(
    uint _boostedTime,
    uint[] memory _amounts,
    uint _boostedVal,
    uint _xpElapsedTime
  ) private pure {
    if (_xpElapsedTime != 0) {
      U256 bounds = _amounts.length.asU256();
      for (U256 iter; iter < bounds; iter = iter.inc()) {
        uint i = iter.asUint256();
        // amounts[i] takes into account the whole elapsed time so additional boosted amount is a fraction of that.
        _amounts[i] += uint32((_boostedTime * _amounts[i] * _boostedVal) / (_xpElapsedTime * 100));
      }
    }
  }

  function _getGuaranteedRewards(
    uint _playerId,
    uint40 _skillStartTime,
    uint _xpElapsedTime,
    ActionRewards memory _actionRewards,
    uint16 _monstersKilled,
    bool _isCombat,
    uint8 _successPercent
  ) private view returns (uint[] memory ids, uint[] memory amounts, uint length) {
    ids = new uint[](MAX_GUARANTEED_REWARDS_PER_ACTION);
    amounts = new uint[](MAX_GUARANTEED_REWARDS_PER_ACTION);

    length = _appendGuaranteedRewards(
      ids,
      amounts,
      _xpElapsedTime,
      _actionRewards,
      _monstersKilled,
      _isCombat,
      _successPercent
    );

    assembly ("memory-safe") {
      mstore(ids, length)
      mstore(amounts, length)
    }

    // Check for any boosts
    PlayerBoostInfo storage activeBoost = activeBoosts_[_playerId];
    if (activeBoost.boostType == BoostType.GATHERING) {
      uint boostedTime = PlayersLibrary.getBoostedTime(
        _skillStartTime,
        _xpElapsedTime,
        activeBoost.startTime,
        activeBoost.duration
      );
      _addGatheringBoostedAmounts(boostedTime, amounts, activeBoost.value, _xpElapsedTime);
    }
  }

  function _getSuccessPercent(
    uint _playerId,
    uint16 _actionId,
    Skill _actionSkill,
    bool _isCombat,
    PendingQueuedActionProcessed memory _pendingQueuedActionProcessed
  ) private view returns (uint8 successPercent) {
    return
      PlayersLibrary.getSuccessPercent(
        _actionId,
        _actionSkill,
        _isCombat,
        _pendingQueuedActionProcessed,
        world,
        MAX_SUCCESS_PERCENT_CHANCE_,
        xp_[_playerId]
      );
  }

  function _claimableRandomRewards(
    uint _playerId,
    PendingQueuedActionProcessed memory _pendingQueuedActionProcessed
  )
    private
    view
    returns (
      uint[] memory ids,
      uint[] memory amounts,
      uint[] memory queueIds,
      uint numPastRandomRewardInstancesToRemove
    )
  {
    PendingRandomReward[] storage _pendingRandomRewards = pendingRandomRewards[_playerId];
    U256 pendingRandomRewardsLength = _pendingRandomRewards.length.asU256();
    ids = new uint[](pendingRandomRewardsLength.asUint256() * MAX_RANDOM_REWARDS_PER_ACTION);
    amounts = new uint[](pendingRandomRewardsLength.asUint256() * MAX_RANDOM_REWARDS_PER_ACTION);
    queueIds = new uint[](pendingRandomRewardsLength.asUint256() * MAX_RANDOM_REWARDS_PER_ACTION);

    uint length;
    for (U256 iter; iter < pendingRandomRewardsLength; iter = iter.inc()) {
      uint i = iter.asUint256();
      PendingRandomReward storage pendingRandomReward = _pendingRandomRewards[i];
      (ActionRewards memory actionRewards, Skill actionSkill, uint numSpawnedPerHour, ) = world.getRewardsHelper(
        pendingRandomReward.actionId
      );
      bool isCombat = actionSkill == Skill.COMBAT;
      uint16 monstersKilled = uint16(uint(numSpawnedPerHour * pendingRandomReward.xpElapsedTime) / (SPAWN_MUL * 3600));
      uint8 successPercent = _getSuccessPercent(
        _playerId,
        pendingRandomReward.actionId,
        actionSkill,
        isCombat,
        _pendingQueuedActionProcessed
      );
      bool processedAny;
      uint numTickets = isCombat ? monstersKilled : pendingRandomReward.xpElapsedTime / 3600;

      uint elapsedTime = pendingRandomReward.elapsedTime;

      uint[] memory randomIds;
      uint[] memory randomAmounts;
      (randomIds, randomAmounts, processedAny) = _getRandomRewards(
        _playerId,
        pendingRandomReward.startTime,
        elapsedTime,
        numTickets,
        actionRewards,
        successPercent,
        pendingRandomReward.fullAttireBonusRewardsPercent
      );

      if (processedAny) {
        numPastRandomRewardInstancesToRemove = numPastRandomRewardInstancesToRemove.inc();
      }

      if (randomIds.length != 0) {
        // Check for boosts
        if (pendingRandomReward.boostType == BoostType.GATHERING) {
          (uint16 boostValue, uint24 boostDuration) = itemNFT.getBoostInfo(pendingRandomReward.boostItemTokenId);
          uint boostedTime = PlayersLibrary.getBoostedTime(
            pendingRandomReward.startTime,
            elapsedTime,
            pendingRandomReward.boostStartTime,
            boostDuration
          );

          _addGatheringBoostedAmounts(boostedTime, randomAmounts, boostValue, elapsedTime);
        }

        // Copy into main arrays
        uint oldLength = length;
        for (uint j = 0; j < randomIds.length; ++j) {
          ids[j + oldLength] = randomIds[j];
          amounts[j + oldLength] = randomAmounts[j];
          queueIds[j + oldLength] = pendingRandomReward.queueId;
          ++length;
        }
      }
    }

    assembly ("memory-safe") {
      mstore(ids, length)
      mstore(amounts, length)
      mstore(queueIds, length)
    }
  }

  function _getPointsAccrued(
    address _from,
    uint _playerId,
    QueuedAction storage _queuedAction,
    uint _startTime,
    Skill _skill,
    uint _xpElapsedTime,
    PendingQueuedActionEquipmentState[] memory _pendingQueuedActionEquipmentStates
  ) internal view returns (uint32 pointsAccrued, uint32 pointsAccruedExclBaseBoost) {
    (pointsAccrued, pointsAccruedExclBaseBoost) = PlayersLibrary.getPointsAccrued(
      _from,
      players_[_playerId],
      _queuedAction,
      _startTime,
      _skill,
      _xpElapsedTime,
      attire_[_playerId][_queuedAction.queueId],
      activeBoosts_[_playerId],
      itemNFT,
      world,
      fullAttireBonus[_skill].bonusXPPercent,
      fullAttireBonus[_skill].itemTokenIds,
      _pendingQueuedActionEquipmentStates
    );
  }

  function _addRemainingQueuedAction(
    QueuedAction[] memory _remainingQueuedActions,
    QueuedAction storage _queuedAction,
    uint _timespan,
    uint _elapsedTime,
    uint _xpElapsedTime,
    uint _length
  ) private pure {
    QueuedAction memory remainingAction = _queuedAction;
    remainingAction.timespan = uint24(_timespan);
    remainingAction.prevProcessedTime += uint24(_elapsedTime);
    remainingAction.prevProcessedXPTime += uint24(_xpElapsedTime);
    // Build a list of the skills queued that remain
    _remainingQueuedActions[_length] = remainingAction;
  }

  function _appendGuaranteedReward(
    uint[] memory _ids,
    uint[] memory _amounts,
    uint _elapsedTime,
    uint16 _rewardTokenId,
    uint24 _rewardRate,
    uint _oldLength,
    uint16 _monstersKilled,
    bool _isCombat,
    uint8 _successPercent
  ) private pure returns (uint length) {
    length = _oldLength;
    if (_rewardTokenId != NONE) {
      uint numRewards;
      if (_isCombat) {
        numRewards = (_monstersKilled * _rewardRate) / GUAR_MUL; // rate is per kill
      } else {
        numRewards = (_elapsedTime.mul(_rewardRate).mul(_successPercent)).div(3600 * GUAR_MUL * 100);
      }

      if (numRewards != 0) {
        _ids[length] = _rewardTokenId;
        _amounts[length] = numRewards;
        length = length.inc();
      }
    }
  }

  function _appendGuaranteedRewards(
    uint[] memory _ids,
    uint[] memory _amounts,
    uint _elapsedTime,
    ActionRewards memory _actionRewards,
    uint16 _monstersKilled,
    bool _isCombat,
    uint8 _successPercent
  ) private pure returns (uint length) {
    length = _appendGuaranteedReward(
      _ids,
      _amounts,
      _elapsedTime,
      _actionRewards.guaranteedRewardTokenId1,
      _actionRewards.guaranteedRewardRate1,
      length,
      _monstersKilled,
      _isCombat,
      _successPercent
    );
    length = _appendGuaranteedReward(
      _ids,
      _amounts,
      _elapsedTime,
      _actionRewards.guaranteedRewardTokenId2,
      _actionRewards.guaranteedRewardRate2,
      length,
      _monstersKilled,
      _isCombat,
      _successPercent
    );
    length = _appendGuaranteedReward(
      _ids,
      _amounts,
      _elapsedTime,
      _actionRewards.guaranteedRewardTokenId3,
      _actionRewards.guaranteedRewardRate3,
      length,
      _monstersKilled,
      _isCombat,
      _successPercent
    );
  }

  function _getRandomRewards(
    uint _playerId,
    uint40 _skillStartTime,
    uint _elapsedTime,
    uint _numTickets,
    ActionRewards memory _actionRewards,
    uint8 _successPercent,
    uint8 fullAttireBonusRewardsPercent
  ) private view returns (uint[] memory ids, uint[] memory amounts, bool hasRandomWord) {
    bytes memory data = _staticcall(
      address(this),
      abi.encodeWithSelector(
        IPlayersMiscDelegateView.getRandomRewards.selector,
        _playerId,
        _skillStartTime,
        _elapsedTime,
        _numTickets,
        _actionRewards,
        _successPercent,
        fullAttireBonusRewardsPercent
      )
    );
    return abi.decode(data, (uint[], uint[], bool));
  }

  function _processConsumablesView(
    address _from,
    uint _playerId,
    QueuedAction memory _queuedAction,
    ActionChoice memory _actionChoice,
    CombatStats memory _combatStats,
    uint _elapsedTime,
    uint _startTime,
    PendingQueuedActionEquipmentState[] memory _pendingQueuedActionEquipmentStates,
    PendingQueuedActionProcessed memory _pendingQueuedActionProcessed
  )
    private
    view
    returns (
      Equipment[] memory consumedEquipment,
      Equipment memory producedEquipment,
      uint xpElapsedTime,
      bool died,
      uint16 foodConsumed,
      uint16 baseInputItemsConsumedNum
    )
  {
    bytes memory data = _staticcall(
      address(this),
      abi.encodeWithSelector(
        IPlayersMiscDelegateView.processConsumablesView.selector,
        _from,
        _playerId,
        _queuedAction,
        _actionChoice,
        _combatStats,
        _elapsedTime,
        _startTime,
        _pendingQueuedActionEquipmentStates,
        _pendingQueuedActionProcessed
      )
    );
    return abi.decode(data, (Equipment[], Equipment, uint, bool, uint16, uint16));
  }

  function _getHealthPointsFromCombat(
    uint _playerId,
    uint _combatPoints
  ) internal view returns (uint32 healthPointsAccured) {
    // Get 1/3 of the combat points as health
    healthPointsAccured = uint32(_combatPoints / 3);
    // Get bonus health points from avatar starting skills
    uint bonusPercent = PlayersLibrary.getBonusAvatarXPPercent(players_[_playerId], Skill.HEALTH);
    healthPointsAccured += uint32((_combatPoints * bonusPercent) / (3600 * 100));
  }

  function clearActionProcessed(PendingQueuedActionData memory currentActionProcessed) private pure {
    // Clear it
    currentActionProcessed.skill1 = Skill.NONE;
    currentActionProcessed.xpGained1 = 0;
    currentActionProcessed.skill2 = Skill.NONE;
    currentActionProcessed.xpGained2 = 0;
    currentActionProcessed.skill3 = Skill.NONE;
    currentActionProcessed.xpGained3 = 0;
    currentActionProcessed.foodConsumed = 0;
    currentActionProcessed.baseInputItemsConsumedNum = 0;
  }

  function _dailyRewardsView(
    uint _playerId
  ) internal view returns (uint[] memory itemTokenIds, uint[] memory amounts, bytes32 dailyRewardMask) {
    bytes memory data = _staticcall(
      address(this),
      abi.encodeWithSelector(IPlayersMiscDelegateView.dailyRewardsViewImpl.selector, _playerId)
    );
    return abi.decode(data, (uint[], uint[], bytes32));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {UnsafeMath, U256} from "@0xdoublesharp/unsafe-math/contracts/UnsafeMath.sol";
import {ItemNFT} from "../ItemNFT.sol";
import {World} from "../World.sol";

// solhint-disable-next-line no-global-import
import "../globals/all.sol";

// This file contains methods for interacting with the player that is used to decrease implementation deployment bytecode code.
library PlayersLibrary {
  using Strings for uint32;
  using Strings for uint256;
  using Strings for bytes32;
  using UnsafeMath for U256;
  using UnsafeMath for uint256;

  error InvalidXPSkill();
  error InvalidAction();

  // Show all the player stats, return metadata json
  function uri(
    string calldata _playerName,
    PackedXP storage _packedXP,
    string calldata _avatarName,
    string calldata _avatarDescription,
    string calldata _imageURI,
    bool _isBeta,
    uint _playerId,
    string calldata _clanName
  ) external view returns (string memory) {
    uint overallLevel = getLevel(readXP(Skill.MELEE, _packedXP)) +
      getLevel(readXP(Skill.MAGIC, _packedXP)) +
      getLevel(readXP(Skill.DEFENCE, _packedXP)) +
      getLevel(readXP(Skill.HEALTH, _packedXP)) +
      getLevel(readXP(Skill.MINING, _packedXP)) +
      getLevel(readXP(Skill.WOODCUTTING, _packedXP)) +
      getLevel(readXP(Skill.FISHING, _packedXP)) +
      getLevel(readXP(Skill.SMITHING, _packedXP)) +
      getLevel(readXP(Skill.THIEVING, _packedXP)) +
      getLevel(readXP(Skill.CRAFTING, _packedXP)) +
      getLevel(readXP(Skill.COOKING, _packedXP)) +
      getLevel(readXP(Skill.FIREMAKING, _packedXP));

    string memory attributes = string(
      abi.encodePacked(
        _getTraitStringJSON("Avatar", _avatarName),
        ",",
        _getTraitStringJSON("Clan", _clanName),
        ",",
        _getTraitNumberJSON("Melee level", getLevel(readXP(Skill.MELEE, _packedXP))),
        ",",
        _getTraitNumberJSON("Magic level", getLevel(readXP(Skill.MAGIC, _packedXP))),
        ",",
        _getTraitNumberJSON("Defence level", getLevel(readXP(Skill.DEFENCE, _packedXP))),
        ",",
        _getTraitNumberJSON("Health level", getLevel(readXP(Skill.HEALTH, _packedXP))),
        ",",
        _getTraitNumberJSON("Mining level", getLevel(readXP(Skill.MINING, _packedXP))),
        ",",
        _getTraitNumberJSON("Woodcutting level", getLevel(readXP(Skill.WOODCUTTING, _packedXP))),
        ",",
        _getTraitNumberJSON("Fishing level", getLevel(readXP(Skill.FISHING, _packedXP))),
        ",",
        _getTraitNumberJSON("Smithing level", getLevel(readXP(Skill.SMITHING, _packedXP))),
        ",",
        _getTraitNumberJSON("Thieving level", getLevel(readXP(Skill.THIEVING, _packedXP))),
        ",",
        _getTraitNumberJSON("Crafting level", getLevel(readXP(Skill.CRAFTING, _packedXP))),
        ",",
        _getTraitNumberJSON("Cooking level", getLevel(readXP(Skill.COOKING, _packedXP))),
        ",",
        _getTraitNumberJSON("Firemaking level", getLevel(readXP(Skill.FIREMAKING, _packedXP))),
        ",",
        _getTraitNumberJSON("Total level", uint16(overallLevel))
      )
    );

    bytes memory fullName = abi.encodePacked(_playerName, " (", overallLevel.toString(), ")");
    bytes memory externalURL = abi.encodePacked(
      "https://",
      _isBeta ? "beta." : "",
      "estfor.com/game/journal/",
      _playerId.toString()
    );

    string memory json = Base64.encode(
      abi.encodePacked(
        '{"name":"',
        fullName,
        '","description":"',
        _avatarDescription,
        '","attributes":[',
        attributes,
        '],"image":"',
        _imageURI,
        '", "external_url":"',
        externalURL,
        '"}'
      )
    );

    return string(abi.encodePacked("data:application/json;base64,", json));
  }

  function _getTraitStringJSON(string memory _traitType, string memory _value) private pure returns (bytes memory) {
    return abi.encodePacked(_getTraitTypeJSON(_traitType), '"', _value, '"}');
  }

  function _getTraitNumberJSON(string memory _traitType, uint32 _value) private pure returns (bytes memory) {
    return abi.encodePacked(_getTraitTypeJSON(_traitType), _value.toString(), "}");
  }

  function _getTraitTypeJSON(string memory _traitType) private pure returns (bytes memory) {
    return abi.encodePacked('{"trait_type":"', _traitType, '","value":');
  }

  function getLevel(uint _xp) public pure returns (uint16) {
    U256 low;
    U256 high = XP_BYTES.length.asU256().div(4);

    while (low < high) {
      U256 mid = (low + high).div(2);

      // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
      if (_getXP(mid.asUint256()) > _xp) {
        high = mid;
      } else {
        low = mid.inc();
      }
    }

    if (low.neq(0)) {
      return low.asUint16();
    } else {
      return 1;
    }
  }

  function _getXP(uint256 _index) private pure returns (uint32) {
    uint256 index = _index * 4;
    return
      uint32(
        XP_BYTES[index] |
          (bytes4(XP_BYTES[index + 1]) >> 8) |
          (bytes4(XP_BYTES[index + 2]) >> 16) |
          (bytes4(XP_BYTES[index + 3]) >> 24)
      );
  }

  function _getRealBalance(
    uint _originalBalance,
    uint _itemId,
    PendingQueuedActionEquipmentState[] calldata _pendingQueuedActionEquipmentStates
  ) private pure returns (uint balance) {
    balance = _originalBalance;
    U256 bounds = _pendingQueuedActionEquipmentStates.length.asU256();
    for (U256 iter; iter < bounds; iter = iter.inc()) {
      uint i = iter.asUint256();
      PendingQueuedActionEquipmentState memory pendingQueuedActionEquipmentState = _pendingQueuedActionEquipmentStates[
        i
      ];
      U256 jBounds = pendingQueuedActionEquipmentState.producedItemTokenIds.length.asU256();
      for (U256 jIter; jIter < jBounds; jIter = jIter.inc()) {
        uint j = jIter.asUint256();
        if (pendingQueuedActionEquipmentState.producedItemTokenIds[j] == _itemId) {
          balance += pendingQueuedActionEquipmentState.producedAmounts[j];
        }
      }
      jBounds = pendingQueuedActionEquipmentState.consumedItemTokenIds.length.asU256();
      for (U256 jIter; jIter < jBounds; jIter = jIter.inc()) {
        uint j = jIter.asUint256();
        if (pendingQueuedActionEquipmentState.consumedItemTokenIds[j] == _itemId) {
          balance -= pendingQueuedActionEquipmentState.consumedAmounts[j];
        }
      }
    }
  }

  // This takes into account any intermediate changes from previous actions from view functions
  // as those cannot affect the blockchain state with balanceOf
  function getRealBalance(
    address _from,
    uint _itemId,
    ItemNFT _itemNFT,
    PendingQueuedActionEquipmentState[] calldata _pendingQueuedActionEquipmentStates
  ) public view returns (uint balance) {
    balance = _getRealBalance(_itemNFT.balanceOf(_from, _itemId), _itemId, _pendingQueuedActionEquipmentStates);
  }

  function getRealBalances(
    address _from,
    uint16[] memory _itemIds,
    ItemNFT _itemNFT,
    PendingQueuedActionEquipmentState[] calldata _pendingQueuedActionEquipmentStates
  ) public view returns (uint[] memory balances) {
    balances = _itemNFT.balanceOfs(_from, _itemIds);

    U256 bounds = balances.length.asU256();
    for (U256 iter; iter < bounds; iter = iter.inc()) {
      uint i = iter.asUint256();
      balances[i] = _getRealBalance(balances[i], _itemIds[i], _pendingQueuedActionEquipmentStates);
    }
  }

  function _getMaxRequiredRatio(
    address _from,
    ActionChoice memory _actionChoice,
    uint16 _baseInputItemsConsumedNum,
    ItemNFT _itemNFT,
    PendingQueuedActionEquipmentState[] calldata _pendingQueuedActionEquipmentStates
  ) private view returns (uint maxRequiredRatio) {
    maxRequiredRatio = _baseInputItemsConsumedNum;
    if (_baseInputItemsConsumedNum != 0) {
      if (_actionChoice.inputTokenId1 != 0) {
        maxRequiredRatio = _getMaxRequiredRatioPartial(
          _from,
          _actionChoice.inputTokenId1,
          _actionChoice.inputAmount1,
          maxRequiredRatio,
          _itemNFT,
          _pendingQueuedActionEquipmentStates
        );
      }
      if (_actionChoice.inputTokenId2 != 0) {
        maxRequiredRatio = _getMaxRequiredRatioPartial(
          _from,
          _actionChoice.inputTokenId2,
          _actionChoice.inputAmount2,
          maxRequiredRatio,
          _itemNFT,
          _pendingQueuedActionEquipmentStates
        );
      }
      if (_actionChoice.inputTokenId3 != 0) {
        maxRequiredRatio = _getMaxRequiredRatioPartial(
          _from,
          _actionChoice.inputTokenId3,
          _actionChoice.inputAmount3,
          maxRequiredRatio,
          _itemNFT,
          _pendingQueuedActionEquipmentStates
        );
      }
    }
  }

  function _getMaxRequiredRatioPartial(
    address _from,
    uint16 _inputTokenId,
    uint16 _inputAmount,
    uint _prevConsumeMaxRatio,
    ItemNFT _itemNFT,
    PendingQueuedActionEquipmentState[] calldata _pendingQueuedActionEquipmentStates
  ) private view returns (uint maxRequiredRatio) {
    uint balance = getRealBalance(_from, _inputTokenId, _itemNFT, _pendingQueuedActionEquipmentStates);
    uint tempMaxRequiredRatio = balance / _inputAmount;
    if (tempMaxRequiredRatio < _prevConsumeMaxRatio) {
      maxRequiredRatio = tempMaxRequiredRatio;
    } else {
      maxRequiredRatio = _prevConsumeMaxRatio;
    }
  }

  function _max(int a, int b) private pure returns (int) {
    return a > b ? a : b;
  }

  function dmg(
    int attack,
    int defence,
    uint8 _alphaCombat,
    uint8 _betaCombat,
    uint _elapsedTime
  ) public pure returns (uint32) {
    if (attack == 0) {
      return 0;
    }
    // Negative defence is capped at the negative of the attack value.
    // So attack of 10 and defence of -15 is the same as attack -10.
    defence = _max(-attack, defence);

    // Formula is max(1, a(atk) + b(2 * atk - def))
    // Always do at least 1 damage per minute (assuming attack is positive)
    return
      uint32(
        int32(
          (_max(1, attack * int8(_alphaCombat) + (attack * 2 - defence) * int8(_betaCombat)) * int(_elapsedTime)) / 60
        )
      );
  }

  function _timeToKill(
    int attack,
    int defence,
    uint8 _alphaCombat,
    uint8 _betaCombat,
    int16 _enemyHealth
  ) private pure returns (uint) {
    // Formula is max(1, a(atk) + b(2 * atk - def))
    // Always do at least 1 damage per minute
    uint dmgPerMinute = uint(_max(1, int128(attack) * int8(_alphaCombat) + (attack * 2 - defence) * int8(_betaCombat)));
    return Math.ceilDiv(uint(uint16(_enemyHealth)) * 60, dmgPerMinute);
  }

  function _getTimeToKill(
    ActionChoice memory _actionChoice,
    CombatStats memory _combatStats,
    CombatStats memory _enemyCombatStats,
    uint8 _alphaCombat,
    uint8 _betaCombat,
    int16 _enemyHealth
  ) private pure returns (uint timeToKill) {
    if (_actionChoice.skill == Skill.MELEE) {
      timeToKill = _timeToKill(
        _combatStats.melee,
        _enemyCombatStats.meleeDefence,
        _alphaCombat,
        _betaCombat,
        _enemyHealth
      );
    } else if (_actionChoice.skill == Skill.MAGIC) {
      timeToKill = _timeToKill(
        _combatStats.magic,
        _enemyCombatStats.magicDefence,
        _alphaCombat,
        _betaCombat,
        _enemyHealth
      );
    }
  }

  function _getDmgDealtByPlayer(
    ActionChoice calldata _actionChoice,
    CombatStats memory _combatStats,
    CombatStats calldata _enemyCombatStats,
    uint8 _alphaCombat,
    uint8 _betaCombat,
    uint _elapsedTime
  ) private pure returns (uint32 dmgDealt) {
    if (_actionChoice.skill == Skill.MELEE) {
      dmgDealt = dmg(_combatStats.melee, _enemyCombatStats.meleeDefence, _alphaCombat, _betaCombat, _elapsedTime);
    } else if (_actionChoice.skill == Skill.MAGIC) {
      _combatStats.magic += _actionChoice.skillDiff; // Extra/Reduced magic damage
      dmgDealt = dmg(_combatStats.magic, _enemyCombatStats.magicDefence, _alphaCombat, _betaCombat, _elapsedTime);
    }
  }

  function getCombatAdjustedElapsedTimes(
    address _from,
    ItemNFT _itemNFT,
    World _world,
    uint _elapsedTime,
    ActionChoice calldata _actionChoice,
    uint16 _regenerateId,
    QueuedAction calldata _queuedAction,
    CombatStats memory _combatStats,
    CombatStats calldata _enemyCombatStats,
    uint8 _alphaCombat,
    uint8 _betaCombat,
    PendingQueuedActionEquipmentState[] calldata _pendingQueuedActionEquipmentStates
  )
    external
    view
    returns (
      uint xpElapsedTime,
      uint combatElapsedTime,
      uint16 baseInputItemsConsumedNum,
      uint16 foodConsumed,
      bool died
    )
  {
    uint numSpawnedPerHour = _world.getNumSpawn(_queuedAction.actionId);
    uint respawnTime = (3600 * SPAWN_MUL) / numSpawnedPerHour;
    uint32 dmgDealt = _getDmgDealtByPlayer(
      _actionChoice,
      _combatStats,
      _enemyCombatStats,
      _alphaCombat,
      _betaCombat,
      respawnTime
    );

    uint numKilled;
    bool canKillAll = dmgDealt > uint16(_enemyCombatStats.health);
    if (canKillAll) {
      // But how many can we kill in the time that has elapsed?
      numKilled = (_elapsedTime * numSpawnedPerHour) / (3600 * SPAWN_MUL);
      uint combatTimePerEnemy = Math.ceilDiv(uint16(_enemyCombatStats.health) * respawnTime, dmgDealt);
      combatElapsedTime = combatTimePerEnemy * numKilled;
    } else {
      uint combatTimePerKill = _getTimeToKill(
        _actionChoice,
        _combatStats,
        _enemyCombatStats,
        _alphaCombat,
        _betaCombat,
        _enemyCombatStats.health
      );
      numKilled = _elapsedTime / combatTimePerKill;
      combatElapsedTime = _elapsedTime; // How much time was spent in combat
    }

    xpElapsedTime = respawnTime * numKilled;

    // Check how many to consume, and also adjust xpElapsedTime if they don't have enough consumables
    baseInputItemsConsumedNum = uint16(Math.ceilDiv(combatElapsedTime * _actionChoice.rate, 3600 * RATE_MUL));
    if (_actionChoice.rate != 0) {
      baseInputItemsConsumedNum = uint16(Math.max(numKilled, baseInputItemsConsumedNum));
    }

    if (baseInputItemsConsumedNum != 0) {
      // This checks the balances
      uint maxRequiredRatio = _getMaxRequiredRatio(
        _from,
        _actionChoice,
        baseInputItemsConsumedNum,
        _itemNFT,
        _pendingQueuedActionEquipmentStates
      );

      if (baseInputItemsConsumedNum > maxRequiredRatio) {
        // How many can we kill with the consumeables we do have
        numKilled = (numKilled * maxRequiredRatio) / baseInputItemsConsumedNum;
        xpElapsedTime = respawnTime * numKilled;

        combatElapsedTime = _elapsedTime;
        baseInputItemsConsumedNum = uint16(maxRequiredRatio);
      }
    } else if (_actionChoice.rate != 0) {
      xpElapsedTime = 0;
      combatElapsedTime = _elapsedTime;
    }

    // Also check food consumed
    uint32 totalHealthLost = dmg(
      _enemyCombatStats.melee,
      _combatStats.meleeDefence,
      _alphaCombat,
      _betaCombat,
      combatElapsedTime
    );
    totalHealthLost += dmg(
      _enemyCombatStats.magic,
      _combatStats.magicDefence,
      _alphaCombat,
      _betaCombat,
      combatElapsedTime
    );
    if (int32(totalHealthLost) > _combatStats.health) {
      // Take away our health points from the total dealt
      totalHealthLost -= uint16(int16(_max(0, _combatStats.health)));
    } else {
      totalHealthLost = 0;
    }

    (foodConsumed, numKilled, xpElapsedTime, died) = _getFoodConsumed(
      _from,
      _regenerateId,
      respawnTime,
      totalHealthLost,
      xpElapsedTime,
      numKilled,
      _itemNFT,
      _pendingQueuedActionEquipmentStates
    );
  }

  function _getFoodConsumed(
    address _from,
    uint16 _regenerateId,
    uint _respawnTime,
    uint32 _totalHealthLost,
    uint _xpElapsedTime,
    uint _numKilled,
    ItemNFT _itemNFT,
    PendingQueuedActionEquipmentState[] calldata _pendingQueuedActionEquipmentStates
  ) private view returns (uint16 foodConsumed, uint numKilled, uint xpElapsedTime, bool died) {
    numKilled = _numKilled;
    xpElapsedTime = _xpElapsedTime;
    uint healthRestored;
    if (_regenerateId != NONE) {
      Item memory item = _itemNFT.getItem(_regenerateId);
      healthRestored = item.healthRestored;
    }

    if (healthRestored == 0 || _totalHealthLost <= 0) {
      // No food attached or didn't lose any health
      died = _totalHealthLost != 0;
      if (died) {
        xpElapsedTime = 0;
      }
    } else {
      // Round up
      uint _totalFoodRequired = Math.ceilDiv(uint32(_totalHealthLost), healthRestored);
      // Can only consume a maximum of 65535 food
      if (_totalFoodRequired > type(uint16).max) {
        foodConsumed = type(uint16).max;
        died = true;
      } else {
        uint balance = getRealBalance(_from, _regenerateId, _itemNFT, _pendingQueuedActionEquipmentStates);
        died = _totalFoodRequired > balance;
        if (died) {
          foodConsumed = uint16(balance > type(uint16).max ? type(uint16).max : balance);
        } else {
          foodConsumed = uint16(_totalFoodRequired);
        }
      }

      if (died) {
        // How many can we kill with the food we did consume
        numKilled = (numKilled * foodConsumed) / _totalFoodRequired;
        xpElapsedTime = _respawnTime * numKilled;
      }
    }
  }

  function getNonCombatAdjustedElapsedTime(
    address _from,
    ItemNFT _itemNFT,
    uint _elapsedTime,
    ActionChoice calldata _actionChoice,
    PendingQueuedActionEquipmentState[] calldata _pendingQueuedActionEquipmentStates
  ) external view returns (uint xpElapsedTime, uint16 baseInputItemsConsumedNum) {
    // Check the max that can be used
    baseInputItemsConsumedNum = uint16((_elapsedTime * _actionChoice.rate) / (3600 * RATE_MUL));

    if (baseInputItemsConsumedNum != 0) {
      // This checks the balances
      uint maxRequiredRatio = _getMaxRequiredRatio(
        _from,
        _actionChoice,
        baseInputItemsConsumedNum,
        _itemNFT,
        _pendingQueuedActionEquipmentStates
      );
      bool hadEnoughConsumables = baseInputItemsConsumedNum <= maxRequiredRatio;
      if (!hadEnoughConsumables) {
        baseInputItemsConsumedNum = uint16(maxRequiredRatio);
      }
    }
    // Work out what the actual elapsedTime should be had all those been made
    xpElapsedTime = (uint(baseInputItemsConsumedNum) * 3600 * RATE_MUL) / _actionChoice.rate;
  }

  function _isCombat(CombatStyle _combatStyle) private pure returns (bool) {
    return _combatStyle != CombatStyle.NONE;
  }

  function getBoostedTime(
    uint _actionStartTime,
    uint _elapsedTime,
    uint40 _boostStartTime,
    uint24 _boostDuration
  ) public pure returns (uint24 boostedTime) {
    uint actionEndTime = _actionStartTime + _elapsedTime;
    uint boostEndTime = _boostStartTime + _boostDuration;
    bool boostFinishedBeforeOrOnActionStarted = _actionStartTime >= boostEndTime;
    bool boostStartedAfterOrOnActionFinished = actionEndTime <= _boostStartTime;
    uint24 actionDuration = uint24(actionEndTime - _actionStartTime);
    if (boostFinishedBeforeOrOnActionStarted || boostStartedAfterOrOnActionFinished || _elapsedTime == 0) {
      // Boost was not active at all during this queued action
      boostedTime = 0;
    } else if (_boostStartTime <= _actionStartTime && boostEndTime >= actionEndTime) {
      boostedTime = actionDuration;
    } else if (_boostStartTime < _actionStartTime && boostEndTime < actionEndTime) {
      boostedTime = uint24(boostEndTime - _actionStartTime);
    } else if (_boostStartTime > _actionStartTime && boostEndTime > actionEndTime) {
      boostedTime = uint24(actionEndTime - _boostStartTime);
    } else if (_boostStartTime > _actionStartTime && boostEndTime <= actionEndTime) {
      boostedTime = _boostDuration;
    } else if (_boostStartTime == _actionStartTime && boostEndTime <= actionEndTime) {
      boostedTime = _boostDuration;
    } else {
      assert(false); // Should never happen
    }
  }

  function _extraXPFromBoost(
    bool _isCombatSkill,
    uint _actionStartTime,
    uint _xpElapsedTime,
    uint24 _xpPerHour,
    PlayerBoostInfo storage activeBoost
  ) private view returns (uint32 boostPointsAccrued) {
    if (activeBoost.itemTokenId != NONE && activeBoost.startTime < block.timestamp && _xpElapsedTime != 0) {
      // A boost is active
      BoostType boostType = activeBoost.boostType;
      if (
        boostType == BoostType.ANY_XP ||
        (_isCombatSkill && activeBoost.boostType == BoostType.COMBAT_XP) ||
        (!_isCombatSkill && activeBoost.boostType == BoostType.NON_COMBAT_XP)
      ) {
        uint boostedTime = getBoostedTime(
          _actionStartTime,
          _xpElapsedTime,
          activeBoost.startTime,
          activeBoost.duration
        );
        boostPointsAccrued = uint32((boostedTime * _xpPerHour * activeBoost.value) / (3600 * 100));
      }
    }
  }

  function _extraBoostFromFullAttire(
    uint16[] memory itemTokenIds,
    uint[] memory balances,
    uint16[5] calldata expectedItemTokenIds
  ) private pure returns (bool matches) {
    // Check if they have the full equipment required
    if (itemTokenIds.length == 5) {
      for (U256 iter; iter.lt(5); iter = iter.inc()) {
        uint i = iter.asUint256();
        if (itemTokenIds[i] != expectedItemTokenIds[i] || balances[i] == 0) {
          return false;
        }
      }
      return true;
    }
  }

  function subtractMatchingRewards(
    uint[] calldata newIds,
    uint[] calldata newAmounts,
    uint[] calldata prevNewIds,
    uint[] calldata prevNewAmounts
  ) external pure returns (uint[] memory ids, uint[] memory amounts) {
    // Subtract previous rewards. If amount is zero after, replace with end and reduce the array size
    ids = newIds;
    amounts = newAmounts;
    U256 prevNewIdsLength = prevNewIds.length.asU256();
    for (U256 jter; jter < prevNewIdsLength; jter = jter.inc()) {
      uint j = jter.asUint256();
      uint16 prevNewId = uint16(prevNewIds[j]);
      uint24 prevNewAmount = uint24(prevNewAmounts[j]);
      uint length = ids.length;
      for (uint k = 0; k < length; ++k) {
        if (ids[k] == prevNewId) {
          amounts[k] -= prevNewAmount;
          if (amounts[k] == 0) {
            ids[k] = ids[ids.length - 1];
            amounts[k] = amounts[amounts.length - 1];

            assembly ("memory-safe") {
              mstore(ids, length)
              mstore(amounts, length)
            }
            --length;
          }
          break;
        }
      }
    }
  }

  function readXP(Skill _skill, PackedXP storage _packedXP) internal view returns (uint) {
    if (_skill == Skill.COMBAT || _skill == Skill.TRAVELLING) {
      revert InvalidXPSkill();
    }
    if (_skill == Skill.NONE) {
      return 0;
    }
    uint offset = 2; // Accounts for NONE & COMBAT skills
    uint val = uint8(_skill) - offset;
    uint slotNum = val / 6;
    uint relativePos = val % 6;

    uint slotVal;
    assembly ("memory-safe") {
      slotVal := sload(add(_packedXP.slot, slotNum))
    }

    return uint40(slotVal >> (relativePos * 40));
  }

  function getCombatStats(
    PendingQueuedActionProcessed calldata _pendingQueuedActionProcessed,
    PackedXP storage _packedXP,
    address _from,
    ItemNFT _itemNFT,
    Attire storage _attire,
    PendingQueuedActionEquipmentState[] calldata _pendingQueuedActionEquipmentStates
  ) external view returns (CombatStats memory combatStats) {
    combatStats.melee = int16(
      getLevel(getAbsoluteActionStartXP(Skill.MELEE, _pendingQueuedActionProcessed, _packedXP))
    );
    combatStats.magic = int16(
      getLevel(getAbsoluteActionStartXP(Skill.MAGIC, _pendingQueuedActionProcessed, _packedXP))
    );
    combatStats.health = int16(
      getLevel(getAbsoluteActionStartXP(Skill.HEALTH, _pendingQueuedActionProcessed, _packedXP))
    );
    uint16 defenceLevel = getLevel(getAbsoluteActionStartXP(Skill.DEFENCE, _pendingQueuedActionProcessed, _packedXP));
    combatStats.meleeDefence = int16(defenceLevel);
    combatStats.magicDefence = int16(defenceLevel);

    bool skipNeck;
    (uint16[] memory itemTokenIds, uint[] memory balances) = getAttireWithBalance(
      _from,
      _attire,
      _itemNFT,
      skipNeck,
      _pendingQueuedActionEquipmentStates
    );
    if (itemTokenIds.length != 0) {
      Item[] memory items = _itemNFT.getItems(itemTokenIds);
      U256 iter = items.length.asU256();
      while (iter.neq(0)) {
        iter = iter.dec();
        uint i = iter.asUint256();
        if (balances[i] != 0) {
          _updateCombatStatsFromItem(combatStats, items[i]);
        }
      }
    }
  }

  function getAttireWithBalance(
    address _from,
    Attire storage _attire,
    ItemNFT _itemNFT,
    bool _skipNeck,
    PendingQueuedActionEquipmentState[] calldata _pendingQueuedActionEquipmentStates
  ) public view returns (uint16[] memory itemTokenIds, uint[] memory balances) {
    uint attireLength;
    itemTokenIds = new uint16[](6);
    if (_attire.head != NONE) {
      itemTokenIds[attireLength++] = _attire.head;
    }
    if (_attire.neck != NONE && !_skipNeck) {
      itemTokenIds[attireLength++] = _attire.neck;
    }
    if (_attire.body != NONE) {
      itemTokenIds[attireLength++] = _attire.body;
    }
    if (_attire.arms != NONE) {
      itemTokenIds[attireLength++] = _attire.arms;
    }
    if (_attire.legs != NONE) {
      itemTokenIds[attireLength++] = _attire.legs;
    }
    if (_attire.feet != NONE) {
      itemTokenIds[attireLength++] = _attire.feet;
    }

    assembly ("memory-safe") {
      mstore(itemTokenIds, attireLength)
    }

    if (attireLength != 0) {
      balances = getRealBalances(_from, itemTokenIds, _itemNFT, _pendingQueuedActionEquipmentStates);
    }
  }

  // Subtract any existing xp gained from the first in-progress actions and add the new xp gained
  function getAbsoluteActionStartXP(
    Skill _skill,
    PendingQueuedActionProcessed calldata _pendingQueuedActionProcessed,
    PackedXP storage packedXP
  ) public view returns (uint) {
    uint xp = readXP(_skill, packedXP);
    if (_pendingQueuedActionProcessed.currentAction.skill1 == _skill) {
      xp -= _pendingQueuedActionProcessed.currentAction.xpGained1;
    } else if (_pendingQueuedActionProcessed.currentAction.skill2 == _skill) {
      xp -= _pendingQueuedActionProcessed.currentAction.xpGained2;
    } else if (_pendingQueuedActionProcessed.currentAction.skill3 == _skill) {
      xp -= _pendingQueuedActionProcessed.currentAction.xpGained3;
    }

    // Add any new xp gained from previous actions now completed that haven't been pushed to the blockchain yet. For instance
    // battling monsters may increase your level so you are stronger for a later queued action.
    for (uint i; i < _pendingQueuedActionProcessed.skills.length; ++i) {
      if (_pendingQueuedActionProcessed.skills[i] == _skill) {
        xp += _pendingQueuedActionProcessed.xpGainedSkills[i];
      }
    }

    return xp;
  }

  function updateStatsFromHandEquipment(
    address _from,
    ItemNFT _itemNFT,
    uint16[2] calldata _handEquipmentTokenIds,
    CombatStats calldata _combatStats,
    bool isCombat,
    PendingQueuedActionEquipmentState[] calldata _pendingQueuedActionEquipmentStates
  ) external view returns (bool missingRequiredHandEquipment, CombatStats memory combatStats) {
    U256 iter = _handEquipmentTokenIds.length.asU256();
    combatStats = _combatStats;
    while (iter.neq(0)) {
      iter = iter.dec();
      uint16 i = iter.asUint16();
      uint16 handEquipmentTokenId = _handEquipmentTokenIds[i];
      if (handEquipmentTokenId != NONE) {
        uint256 balance = getRealBalance(_from, handEquipmentTokenId, _itemNFT, _pendingQueuedActionEquipmentStates);
        if (balance == 0) {
          // Assume that if the player doesn't have the non-combat item that this action cannot be done
          if (!isCombat) {
            missingRequiredHandEquipment = true;
          }
        } else if (isCombat) {
          // Update the combat stats
          Item memory item = _itemNFT.getItem(handEquipmentTokenId);
          _updateCombatStatsFromItem(combatStats, item);
        }
      }
    }
  }

  function _updateCombatStatsFromItem(CombatStats memory _combatStats, Item memory _item) private pure {
    _combatStats.melee += _item.melee;
    _combatStats.magic += _item.magic;
    _combatStats.meleeDefence += _item.meleeDefence;
    _combatStats.magicDefence += _item.magicDefence;
    _combatStats.health += _item.health;
  }

  function getBonusAvatarXPPercent(Player storage _player, Skill _skill) public view returns (uint8 bonusPercent) {
    bool hasBonusSkill = _player.skillBoosted1 == _skill || _player.skillBoosted2 == _skill;
    if (!hasBonusSkill) {
      return 0;
    }
    bool bothSet = _player.skillBoosted1 != Skill.NONE && _player.skillBoosted2 != Skill.NONE;
    bonusPercent = bothSet ? 5 : 10;
  }

  function _extraFromAvatar(
    Player storage _player,
    Skill _skill,
    uint _elapsedTime,
    uint24 _xpPerHour
  ) internal view returns (uint32 extraPointsAccrued) {
    uint8 bonusPercent = getBonusAvatarXPPercent(_player, _skill);
    extraPointsAccrued = uint32((_elapsedTime * _xpPerHour * bonusPercent) / (3600 * 100));
  }

  function getPointsAccrued(
    address _from,
    Player storage _player,
    QueuedAction storage _queuedAction,
    uint _startTime,
    Skill _skill,
    uint _xpElapsedTime,
    Attire storage _attire,
    PlayerBoostInfo storage _activeBoost,
    ItemNFT _itemNFT,
    World _world,
    uint8 _bonusAttirePercent,
    uint16[5] calldata _expectedItemTokenIds,
    PendingQueuedActionEquipmentState[] calldata _pendingQueuedActionEquipmentStates
  ) external view returns (uint32 pointsAccrued, uint32 pointsAccruedExclBaseBoost) {
    bool _isCombatSkill = _queuedAction.combatStyle != CombatStyle.NONE;
    uint24 xpPerHour = _world.getXPPerHour(_queuedAction.actionId, _isCombatSkill ? NONE : _queuedAction.choiceId);
    pointsAccrued = uint32((_xpElapsedTime * xpPerHour) / 3600);
    pointsAccrued += _extraXPFromBoost(_isCombatSkill, _startTime, _xpElapsedTime, xpPerHour, _activeBoost);
    pointsAccrued += _extraXPFromFullAttire(
      _from,
      _attire,
      _xpElapsedTime,
      xpPerHour,
      _itemNFT,
      _bonusAttirePercent,
      _expectedItemTokenIds,
      _pendingQueuedActionEquipmentStates
    );
    pointsAccruedExclBaseBoost = pointsAccrued;
    pointsAccrued += _extraFromAvatar(_player, _skill, _xpElapsedTime, xpPerHour);
  }

  function _extraXPFromFullAttire(
    address _from,
    Attire storage _attire,
    uint _elapsedTime,
    uint24 _xpPerHour,
    ItemNFT _itemNFT,
    uint8 _bonusPercent,
    uint16[5] calldata _expectedItemTokenIds,
    PendingQueuedActionEquipmentState[] calldata _pendingQueuedActionEquipmentStates
  ) internal view returns (uint32 extraPointsAccrued) {
    if (_bonusPercent == 0) {
      return 0;
    }

    // Check if they have the full equipment set, if so they can get some bonus
    bool skipNeck = true;
    (uint16[] memory itemTokenIds, uint[] memory balances) = getAttireWithBalance(
      _from,
      _attire,
      _itemNFT,
      skipNeck,
      _pendingQueuedActionEquipmentStates
    );
    bool hasFullAttire = _extraBoostFromFullAttire(itemTokenIds, balances, _expectedItemTokenIds);
    if (hasFullAttire) {
      extraPointsAccrued = uint32((_elapsedTime * _xpPerHour * _bonusPercent) / (3600 * 100));
    }
  }

  function getSuccessPercent(
    uint16 _actionId,
    Skill _actionSkill,
    bool isCombat,
    PendingQueuedActionProcessed calldata _pendingQueuedActionProcessed,
    World _world,
    uint _maxSuccessPercentChange,
    PackedXP storage _packedXP
  ) external view returns (uint8 successPercent) {
    successPercent = 100;
    (uint8 actionSuccessPercent, uint32 minXP) = _world.getActionSuccessPercentAndMinXP(_actionId);
    if (actionSuccessPercent != 100) {
      if (isCombat) {
        revert InvalidAction();
      }

      uint minLevel = getLevel(minXP);
      uint skillLevel = getLevel(getAbsoluteActionStartXP(_actionSkill, _pendingQueuedActionProcessed, _packedXP));
      uint extraBoost = skillLevel - minLevel;

      successPercent = uint8(Math.min(_maxSuccessPercentChange, actionSuccessPercent + extraBoost));
    }
  }

  function getFullAttireBonusRewardsPercent(
    address _from,
    Attire storage _attire,
    ItemNFT _itemNFT,
    PendingQueuedActionEquipmentState[] calldata _pendingQueuedActionEquipmentStates,
    uint8 _bonusRewardsPercent,
    uint16[5] calldata fullAttireBonusItemTokenIds
  ) external view returns (uint8 fullAttireBonusRewardsPercent) {
    if (_bonusRewardsPercent != 0) {
      // Check if they have the full equipment set, if so they can get some bonus
      bool skipNeck = true;
      (uint16[] memory itemTokenIds, uint[] memory balances) = getAttireWithBalance(
        _from,
        _attire,
        _itemNFT,
        skipNeck,
        _pendingQueuedActionEquipmentStates
      );
      bool hasFullAttire = _extraBoostFromFullAttire(itemTokenIds, balances, fullAttireBonusItemTokenIds);

      if (hasFullAttire) {
        fullAttireBonusRewardsPercent = _bonusRewardsPercent;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UUPSUpgradeable} from "./ozUpgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "./ozUpgradeable/access/OwnableUpgradeable.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IQuests} from "./interfaces/IQuests.sol";
import {IPlayers} from "./interfaces/IPlayers.sol";

import {UnsafeMath, U256} from "@0xdoublesharp/unsafe-math/contracts/UnsafeMath.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

// solhint-disable-next-line no-global-import
import "./globals/all.sol";

interface Router {
  function swapExactETHForTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts);

  function swapETHForExactTokens(
    uint amountOut,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts);

  function swapExactTokensForETH(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapTokensForExactETH(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
}

contract Quests is UUPSUpgradeable, OwnableUpgradeable, IQuests {
  using UnsafeMath for uint256;
  using UnsafeMath for U256;
  using Math for uint256;
  using BitMaps for BitMaps.BitMap;

  event AddFixedQuest(Quest quest, MinimumRequirement[3] minimumRequirements);
  event EditQuest(Quest quest, MinimumRequirement[3] minimumRequirements);
  event AddBaseRandomQuest(Quest quest, MinimumRequirement[3] minimumRequirements);
  event RemoveQuest(uint questId);
  event NewRandomQuest(Quest randomQuest, uint oldQuestId);
  event ActivateNewQuest(uint playerId, uint questId);
  event DeactivateQuest(uint playerId, uint questId);
  event QuestCompleted(address from, uint playerId, uint questId);
  event UpdateQuestProgress(uint playerId, PlayerQuest playerQuest);

  error NotWorld();
  error NotOwnerOfPlayerAndActive();
  error NotPlayers();
  error QuestDoesntExist();
  error InvalidQuestId();
  error CannotRemoveActiveRandomQuest();
  error QuestWithIdAlreadyExists();
  error QuestCompletedAlready();
  error InvalidRewardAmount();
  error InvalidActionNum();
  error InvalidActionChoiceNum();
  error LengthMismatch();
  error InvalidSkillXPGained();
  error InvalidFTMAmount();
  error InvalidBrushAmount();
  error InvalidActiveQuest();
  error InvalidBurnAmount();
  error NoActiveQuest();
  error ActivatingQuestAlreadyActivated();
  error RandomNotSupportedYet();
  error DependentQuestNotCompleted(uint16 dependentQuestId);
  error RefundFailed();
  error InvalidMinimumRequirement();

  struct MinimumRequirement {
    Skill skill;
    uint64 xp;
  }

  struct PlayerQuestInfo {
    uint32 numFixedQuestsCompleted;
    uint32 numRandomQuestsCompleted;
  }

  address private world;
  IPlayers private players;
  uint40 public randomQuestId;
  uint16 public numTotalQuests;
  mapping(uint questId => Quest quest) public allFixedQuests;
  mapping(uint playerId => BitMaps.BitMap) private questsCompleted;
  mapping(uint playerId => PlayerQuest playerQuest) public activeQuests;
  mapping(uint playerId => PlayerQuest playerQuest) public inProgressRandomQuests;
  mapping(uint playerId => mapping(uint queueId => PlayerQuest quest)) public inProgressFixedQuests; // Only puts it here if changing active quest for something else
  mapping(uint questId => MinimumRequirement[3]) minimumRequirements; // Not checked yet
  BitMaps.BitMap private questIsRandom;
  mapping(uint playerId => PlayerQuestInfo) public playerInfo;
  Quest[] private randomQuests;
  Quest private previousRandomQuest; // Allow people to complete it if they didn't process it in the current day
  Quest private randomQuest; // Same for everyone
  Router private router;
  address private buyPath1; // For buying brush
  address private buyPath2;

  modifier onlyWorld() {
    if (msg.sender != world) {
      revert NotWorld();
    }
    _;
  }

  modifier onlyPlayers() {
    if (msg.sender != address(players)) {
      revert NotPlayers();
    }
    _;
  }

  modifier isOwnerOfPlayerAndActive(uint _playerId) {
    if (!players.isOwnerOfPlayerAndActive(msg.sender, _playerId)) {
      revert NotOwnerOfPlayerAndActive();
    }
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address _world, Router _router, address[2] calldata _buyPath) public initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();

    world = _world;
    router = _router;
    buyPath1 = _buyPath[0];
    buyPath2 = _buyPath[1];

    IERC20(buyPath2).approve(address(_router), type(uint256).max);
  }

  function activateQuest(uint _playerId, uint _questId) external onlyPlayers {
    Quest storage quest = allFixedQuests[_questId];
    if (_questId == 0) {
      revert InvalidQuestId();
    }
    if (quest.questId != _questId) {
      revert QuestDoesntExist();
    }
    if (questsCompleted[_playerId].get(_questId)) {
      revert QuestCompletedAlready();
    }

    if (quest.dependentQuestId != 0) {
      if (!questsCompleted[_playerId].get(quest.dependentQuestId)) {
        revert DependentQuestNotCompleted(quest.dependentQuestId);
      }
    }

    for (uint i = 0; i < minimumRequirements[_questId].length; ++i) {
      MinimumRequirement storage minimumRequirement = minimumRequirements[_questId][i];
      if (minimumRequirement.skill != Skill.NONE) {
        uint xp = players.xp(_playerId, minimumRequirement.skill);
        if (xp < minimumRequirement.xp) {
          revert InvalidMinimumRequirement();
        }
      }
    }

    uint existingActiveQuestId = activeQuests[_playerId].questId;
    if (existingActiveQuestId == _questId) {
      revert ActivatingQuestAlreadyActivated();
    }

    if (existingActiveQuestId != 0) {
      // Another quest was activated
      emit DeactivateQuest(_playerId, existingActiveQuestId);
      inProgressFixedQuests[_playerId][existingActiveQuestId] = activeQuests[_playerId];
    }

    if (inProgressFixedQuests[_playerId][_questId].questId != 0) {
      // If the quest is already in progress, just activate it
      activeQuests[_playerId] = inProgressFixedQuests[_playerId][_questId];
    } else {
      // Start fresh quest
      PlayerQuest memory playerQuest;
      playerQuest.questId = uint32(_questId);
      playerQuest.isFixed = true;
      activeQuests[_playerId] = playerQuest;
    }
    emit ActivateNewQuest(_playerId, _questId);
  }

  function deactivateQuest(uint _playerId) external onlyPlayers {
    PlayerQuest storage playerQuest = activeQuests[_playerId];
    uint questId = playerQuest.questId;
    if (questId == 0) {
      revert NoActiveQuest();
    }

    // Move it to in progress
    inProgressFixedQuests[_playerId][activeQuests[_playerId].questId] = activeQuests[_playerId];
    delete activeQuests[_playerId];

    emit DeactivateQuest(_playerId, questId);
  }

  function newOracleRandomWords(uint[3] calldata _randomWords) external override onlyWorld {
    // Pick a random quest which is assigned to everyone (could be random later)
    uint length = randomQuests.length;
    if (length == 0) {
      return; // Don't revert as this would mess up the chainlink callback
    }

    uint index = uint8(_randomWords[0]) % length;
    randomQuest = randomQuests[index];
    uint oldQuestId = randomQuest.questId;
    uint newQuestId = randomQuestId++;
    randomQuest.questId = uint16(newQuestId); // Update to a unique one so we can distinguish the same quests
    emit NewRandomQuest(randomQuest, oldQuestId);
  }

  function processQuests(
    address _from,
    uint _playerId,
    PlayerQuest[] calldata _activeQuestInfo,
    uint[] memory _questsCompleted
  ) external onlyPlayers {
    if (_questsCompleted.length != 0) {
      U256 bounds = _questsCompleted.length.asU256();
      for (U256 iter; iter < bounds; iter = iter.inc()) {
        uint i = iter.asUint256();
        uint questId = _questsCompleted[i];
        _questCompleted(_from, _playerId, questId);
      }
    } else if (_activeQuestInfo.length != 0) {
      PlayerQuest storage activeQuest = activeQuests[_playerId];
      // Only handling 1 active quest at a time currently
      PlayerQuest calldata activeQuestInfo = _activeQuestInfo[0];
      bool hasQuestProgress = activeQuestInfo.actionCompletedNum1 != activeQuest.actionCompletedNum1 ||
        activeQuestInfo.actionChoiceCompletedNum != activeQuest.actionChoiceCompletedNum ||
        activeQuestInfo.burnCompletedAmount != activeQuest.burnCompletedAmount;

      if (hasQuestProgress) {
        activeQuests[_playerId] = activeQuestInfo;
        emit UpdateQuestProgress(_playerId, activeQuestInfo);
      }
    }
  }

  function buyBrushQuest(
    address _from,
    address _to,
    uint _playerId,
    uint _minimumBrushBack,
    bool _useExactETH
  ) external payable onlyPlayers returns (bool success) {
    PlayerQuest storage playerQuest = activeQuests[_playerId];
    if (playerQuest.questId != QUEST_PURSE_STRINGS) {
      revert InvalidActiveQuest();
    }
    uint[] memory amounts = buyBrush(_to, _minimumBrushBack, _useExactETH);
    if (amounts[0] != 0) {
      // Refund the rest if it isn't players contract calling it otherwise do it elsewhere
      (success, ) = _from.call{value: msg.value - amounts[0]}("");
      if (!success) {
        revert RefundFailed();
      }
    }
    _questCompleted(_from, _playerId, playerQuest.questId);
    success = true;
  }

  function buyBrush(
    address _to,
    uint _minimumBrushExpected,
    bool _useExactETH
  ) public payable returns (uint[] memory amounts) {
    if (msg.value == 0) {
      revert InvalidFTMAmount();
    }

    uint deadline = block.timestamp.add(10 minutes);
    // Buy brush and send it back to the user
    address[] memory buyPath = new address[](2);
    buyPath[0] = buyPath1;
    buyPath[1] = buyPath2;

    if (_useExactETH) {
      uint amountOutMin = _minimumBrushExpected;
      amounts = router.swapExactETHForTokens{value: msg.value}(amountOutMin, buyPath, _to, deadline);
    } else {
      uint amountOut = _minimumBrushExpected;
      amounts = router.swapETHForExactTokens{value: msg.value}(amountOut, buyPath, _to, deadline);
      if (amounts[0] != 0 && msg.sender != address(players)) {
        // Refund the rest if it isn't players contract calling it otherwise do it elsewhere
        (bool success, ) = msg.sender.call{value: msg.value - amounts[0]}("");
        if (!success) {
          revert RefundFailed();
        }
      }
    }
  }

  // This doesn't really belong here, just for consistency
  function sellBrush(address _to, uint _brushAmount, uint _minFTM, bool _useExactETH) external {
    if (_brushAmount == 0) {
      revert InvalidBrushAmount();
    }

    uint deadline = block.timestamp.add(10 minutes);
    // Sell brush and send it back to the user
    address[] memory sellPath = new address[](2);
    sellPath[0] = buyPath2;
    sellPath[1] = buyPath1;

    IERC20(buyPath2).transferFrom(msg.sender, address(router), _brushAmount);

    if (_useExactETH) {
      uint amountOut = _minFTM;
      uint amountInMax = _brushAmount;
      router.swapTokensForExactETH(amountOut, amountInMax, sellPath, _to, deadline);
    } else {
      uint amountIn = _brushAmount;
      uint amountOutMin = _minFTM;
      router.swapExactTokensForETH(amountIn, amountOutMin, sellPath, _to, deadline);
    }
  }

  function processQuestsView(
    uint _playerId,
    uint[] calldata _actionIds,
    uint[] calldata _actionAmounts,
    uint[] calldata _choiceIds,
    uint[] calldata _choiceAmounts,
    uint _burnedAmountOwned
  )
    external
    view
    returns (
      uint[] memory itemTokenIds,
      uint[] memory amounts,
      uint[] memory itemTokenIdsBurned,
      uint[] memory amountsBurned,
      Skill[] memory skillsGained,
      uint32[] memory xpGained,
      uint[] memory _questsCompleted,
      PlayerQuest[] memory activeQuestsCompletionInfo
    )
  {
    // Handle active quest
    PlayerQuest memory questCompletionInfo = activeQuests[_playerId];
    if (questCompletionInfo.questId != 0) {
      activeQuestsCompletionInfo = new PlayerQuest[](2);
      itemTokenIds = new uint[](2 * MAX_QUEST_REWARDS);
      amounts = new uint[](2 * MAX_QUEST_REWARDS);
      itemTokenIdsBurned = new uint[](2);
      amountsBurned = new uint[](2);
      skillsGained = new Skill[](2);
      xpGained = new uint32[](2);
      _questsCompleted = new uint[](2);
      uint itemTokenIdsLength;
      uint itemTokenIdsBurnedLength;
      uint skillsGainedLength;
      uint questsCompletedLength;
      uint activeQuestsLength;

      (
        uint[] memory _itemTokenIds,
        uint[] memory _amounts,
        uint itemTokenIdBurned,
        uint amountBurned,
        Skill skillGained,
        uint32 xp,
        bool questCompleted
      ) = _processQuestView(
          _actionIds,
          _actionAmounts,
          _choiceIds,
          _choiceAmounts,
          questCompletionInfo,
          _burnedAmountOwned
        );

      U256 bounds = _itemTokenIds.length.asU256();
      for (U256 iter; iter < bounds; iter = iter.inc()) {
        uint i = iter.asUint256();
        itemTokenIds[itemTokenIdsLength] = _itemTokenIds[i];
        amounts[itemTokenIdsLength] = _amounts[i];
        itemTokenIdsLength = itemTokenIdsLength.inc();
      }

      if (questCompleted) {
        _questsCompleted[questsCompletedLength++] = questCompletionInfo.questId;
      } else {
        activeQuestsCompletionInfo[activeQuestsLength++] = questCompletionInfo;
      }
      if (itemTokenIdBurned != NONE) {
        itemTokenIdsBurned[itemTokenIdsBurnedLength] = itemTokenIdBurned;
        amountsBurned[itemTokenIdsBurnedLength++] = amountBurned;
      }
      if (xp != 0) {
        skillsGained[skillsGainedLength] = skillGained;
        xpGained[skillsGainedLength++] = xp;
      }

      assembly ("memory-safe") {
        mstore(itemTokenIds, itemTokenIdsLength)
        mstore(amounts, itemTokenIdsLength)
        mstore(itemTokenIdsBurned, itemTokenIdsBurnedLength)
        mstore(amountsBurned, itemTokenIdsBurnedLength)
        mstore(skillsGained, skillsGainedLength)
        mstore(xpGained, skillsGainedLength)
        mstore(_questsCompleted, questsCompletedLength)
        mstore(activeQuestsCompletionInfo, activeQuestsLength)
      }
    }
  }

  function isQuestCompleted(uint _playerId, uint _questId) external view returns (bool) {
    return questsCompleted[_playerId].get(_questId);
  }

  function isRandomQuest(uint _questId) external view returns (bool) {
    return questIsRandom.get(_questId);
  }

  function getActiveQuestId(uint _player) external view returns (uint) {
    return activeQuests[_player].questId;
  }

  function getActiveQuestBurnedItemTokenId(uint _playerId) external view returns (uint) {
    uint questId = activeQuests[_playerId].questId;
    if (questId == 0) {
      return NONE;
    }

    return allFixedQuests[questId].burnItemTokenId;
  }

  function _questCompleted(address _from, uint _playerId, uint _questId) private {
    emit QuestCompleted(_from, _playerId, _questId);
    questsCompleted[_playerId].set(_questId);
    delete activeQuests[_playerId];
    ++playerInfo[_playerId].numFixedQuestsCompleted;
  }

  function _addToBurn(
    Quest storage _quest,
    PlayerQuest memory _playerQuest,
    uint _burnedAmountOwned
  ) private view returns (uint amountBurned) {
    // Handle quest that burns and requires actions to be done at the same time
    uint burnRemainingAmount = _quest.burnAmount > _playerQuest.burnCompletedAmount
      ? _quest.burnAmount - _playerQuest.burnCompletedAmount
      : 0;
    amountBurned = Math.min(burnRemainingAmount, _burnedAmountOwned);
    if (amountBurned != 0) {
      _playerQuest.burnCompletedAmount += uint16(amountBurned);
    }
  }

  function _processQuestView(
    uint[] calldata _actionIds,
    uint[] calldata _actionAmounts,
    uint[] calldata _choiceIds,
    uint[] calldata _choiceAmounts,
    PlayerQuest memory _playerQuest,
    uint _burnedAmountOwned
  )
    private
    view
    returns (
      uint[] memory itemTokenIds,
      uint[] memory amounts,
      uint itemTokenIdBurned,
      uint amountBurned,
      Skill skillGained,
      uint32 xpGained,
      bool questCompleted
    )
  {
    Quest storage quest = allFixedQuests[_playerQuest.questId];
    U256 bounds = _actionIds.length.asU256();
    for (U256 iter; iter < bounds; iter = iter.inc()) {
      uint i = iter.asUint256();
      if (quest.actionId1 == _actionIds[i]) {
        uint remainingAmount = quest.actionNum1 > _playerQuest.actionCompletedNum1
          ? quest.actionNum1 - _playerQuest.actionCompletedNum1
          : 0;
        uint amount = Math.min(remainingAmount, _actionAmounts[i]);
        if (quest.burnItemTokenId != NONE && quest.requireActionsCompletedBeforeBurning) {
          amount = Math.min(_burnedAmountOwned, amount);
          amount = _addToBurn(quest, _playerQuest, amount);
          amountBurned += amount;

          if (
            amount == 0 &&
            _playerQuest.burnCompletedAmount >= quest.burnAmount &&
            _playerQuest.actionCompletedNum1 < quest.actionNum1
          ) {
            // Needed in case the quest is changed later where the amount to burn has already been exceeded
            _playerQuest.actionCompletedNum1 = _playerQuest.burnCompletedAmount;
          }
        }
        _playerQuest.actionCompletedNum1 += uint16(amount);
      }
    }

    bounds = _choiceIds.length.asU256();
    for (U256 iter; iter < bounds; iter = iter.inc()) {
      uint i = iter.asUint256();
      if (quest.actionChoiceId == _choiceIds[i]) {
        uint remainingAmount = quest.actionChoiceNum > _playerQuest.actionChoiceCompletedNum
          ? quest.actionChoiceNum - _playerQuest.actionChoiceCompletedNum
          : 0;
        uint amount = Math.min(remainingAmount, _choiceAmounts[i]);
        if (quest.burnItemTokenId != NONE && quest.requireActionsCompletedBeforeBurning) {
          amount = Math.min(_burnedAmountOwned, amount);
          amount = _addToBurn(quest, _playerQuest, amount);
          amountBurned += amount;

          if (
            amount == 0 &&
            _playerQuest.burnCompletedAmount >= quest.burnAmount &&
            _playerQuest.actionChoiceCompletedNum < quest.actionChoiceNum
          ) {
            // Needed in case the quest is changed later where the amount to burn has already been exceeded
            _playerQuest.actionChoiceCompletedNum = _playerQuest.burnCompletedAmount;
          }
        }
        _playerQuest.actionChoiceCompletedNum += uint16(amount);
      }
    }

    // Handle quest that burns but doesn't require actions completed before burning
    if (quest.burnItemTokenId != NONE && !quest.requireActionsCompletedBeforeBurning) {
      amountBurned += _addToBurn(quest, _playerQuest, _burnedAmountOwned);
    }

    if (amountBurned != 0) {
      itemTokenIdBurned = quest.burnItemTokenId;
    }

    // Buy brush quest is handled specially for instance and doesn't have any of these set
    if (quest.actionNum1 != 0 || quest.actionChoiceNum != 0 || quest.burnAmount != 0) {
      questCompleted =
        _playerQuest.actionCompletedNum1 >= quest.actionNum1 &&
        _playerQuest.actionChoiceCompletedNum >= quest.actionChoiceNum &&
        _playerQuest.burnCompletedAmount >= quest.burnAmount;
    }

    if (questCompleted) {
      (itemTokenIds, amounts, skillGained, xpGained) = getQuestCompletedRewards(_playerQuest.questId);
    }
  }

  function getQuestCompletedRewards(
    uint _questId
  ) public view returns (uint[] memory itemTokenIds, uint[] memory amounts, Skill skillGained, uint32 xpGained) {
    Quest storage quest = allFixedQuests[_questId];
    // length can be 0, 1 or 2
    uint mintLength = quest.rewardItemTokenId1 == NONE ? 0 : 1;
    mintLength += (quest.rewardItemTokenId2 == NONE ? 0 : 1);

    itemTokenIds = new uint[](mintLength);
    amounts = new uint[](mintLength);
    if (quest.rewardItemTokenId1 != NONE) {
      itemTokenIds[0] = quest.rewardItemTokenId1;
      amounts[0] = quest.rewardAmount1;
    }
    if (quest.rewardItemTokenId2 != NONE) {
      itemTokenIds[1] = quest.rewardItemTokenId2;
      amounts[1] = quest.rewardAmount2;
    }
    skillGained = quest.skillReward;
    xpGained = quest.skillXPGained;
  }

  function _checkQuest(Quest calldata _quest) private pure {
    if (_quest.rewardItemTokenId1 != NONE && _quest.rewardAmount1 == 0) {
      revert InvalidRewardAmount();
    }
    if (_quest.rewardItemTokenId2 != NONE && _quest.rewardAmount2 == 0) {
      revert InvalidRewardAmount();
    }
    if (_quest.actionId1 != 0 && _quest.actionNum1 == 0) {
      revert InvalidActionNum();
    }
    if (_quest.actionId2 != 0 && _quest.actionNum2 == 0) {
      revert InvalidActionNum();
    }
    if (_quest.actionChoiceId != 0 && _quest.actionChoiceNum == 0) {
      revert InvalidActionChoiceNum();
    }
    if (_quest.skillReward != Skill.NONE && _quest.skillXPGained == 0) {
      revert InvalidSkillXPGained();
    }
    if (_quest.burnItemTokenId != NONE && _quest.burnAmount == 0) {
      revert InvalidBurnAmount();
    }
    if (_quest.questId == 0) {
      revert InvalidQuestId();
    }
  }

  function _addQuest(
    Quest calldata _quest,
    bool _isRandom,
    MinimumRequirement[3] calldata _minimumRequirements
  ) private {
    _checkQuest(_quest);
    if (_isRandom) {
      revert RandomNotSupportedYet();
    }

    bool anyMinimumRequirement;
    U256 bounds = _minimumRequirements.length.asU256();
    for (U256 iter; iter < bounds; iter = iter.inc()) {
      uint i = iter.asUint256();
      if (_minimumRequirements[i].skill != Skill.NONE) {
        anyMinimumRequirement = true;
        break;
      }
    }

    if (anyMinimumRequirement) {
      minimumRequirements[_quest.questId] = _minimumRequirements;
    }

    if (allFixedQuests[_quest.questId].questId != 0) {
      revert QuestWithIdAlreadyExists();
    }

    allFixedQuests[_quest.questId] = _quest;
    emit AddFixedQuest(_quest, _minimumRequirements);
  }

  function setPlayers(IPlayers _players) external onlyOwner {
    players = _players;
  }

  function addQuests(
    Quest[] calldata _quests,
    bool[] calldata _isRandom,
    MinimumRequirement[3][] calldata _minimumRequirements
  ) external onlyOwner {
    if (_quests.length != _isRandom.length) {
      revert LengthMismatch();
    }
    if (_quests.length != _minimumRequirements.length) {
      revert LengthMismatch();
    }

    U256 bounds = _quests.length.asU256();
    for (U256 iter; iter < bounds; iter = iter.inc()) {
      uint i = iter.asUint256();
      _addQuest(_quests[i], _isRandom[i], _minimumRequirements[i]);
    }
    numTotalQuests += uint16(_quests.length);
  }

  function editQuest(Quest calldata _quest, MinimumRequirement[3] calldata _minimumRequirements) public onlyOwner {
    _checkQuest(_quest);

    minimumRequirements[_quest.questId] = _minimumRequirements;

    if (allFixedQuests[_quest.questId].questId == 0) {
      revert QuestDoesntExist();
    }

    allFixedQuests[_quest.questId] = _quest;
    emit EditQuest(_quest, _minimumRequirements);
  }

  // TODO: Use an EditQuests event
  function editQuests(
    Quest[] calldata _quests,
    MinimumRequirement[3][] calldata _minimumRequirements
  ) external onlyOwner {
    for (uint i = 0; i < _quests.length; ++i) {
      editQuest(_quests[i], _minimumRequirements[i]);
    }
  }

  function removeQuest(uint _questId) external onlyOwner {
    if (_questId == 0) {
      revert InvalidQuestId();
    }
    Quest storage quest = allFixedQuests[_questId];
    if (quest.questId != _questId) {
      revert QuestDoesntExist();
    }

    delete allFixedQuests[_questId];
    emit RemoveQuest(_questId);
    --numTotalQuests;
  }

  receive() external payable {}

  // solhint-disable-next-line no-empty-blocks
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "./ozUpgradeable/proxy/utils/Initializable.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2Upgradeable is Initializable {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private vrfCoordinator;

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  // solhint-disable-next-line func-name-mixedcase
  function __VRFConsumerBaseV2_init(address _vrfCoordinator) internal onlyInitializing {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import {UUPSUpgradeable} from "./ozUpgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "./ozUpgradeable/access/OwnableUpgradeable.sol";

import {UnsafeMath, U256} from "@0xdoublesharp/unsafe-math/contracts/UnsafeMath.sol";
import {VRFConsumerBaseV2Upgradeable} from "./VRFConsumerBaseV2Upgradeable.sol";

import {WorldLibrary} from "./WorldLibrary.sol";
import {IQuests} from "./interfaces/IQuests.sol";

// solhint-disable-next-line no-global-import
import "./globals/all.sol";

contract World is VRFConsumerBaseV2Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
  using UnsafeMath for U256;
  using UnsafeMath for uint256;

  event RequestSent(uint requestId, uint32 numWords, uint lastRandomWordsUpdatedTime);
  event RequestFulfilled(uint requestId, uint[3] randomWords);
  event AddActionV2(Action action);
  event AddActionsV2(Action[] actions);
  event EditActionsV2(Action[] actions);
  event AddAction(ActionV1 action);
  event AddActions(ActionV1[] actions);
  event EditActions(ActionV1[] actions);
  event SetAvailableAction(uint16 actionId, bool available);
  event AddDynamicActions(uint16[] actionIds);
  event RemoveDynamicActions(uint16[] actionIds);
  event AddActionChoice(uint16 actionId, uint16 actionChoiceId, ActionChoice choice);
  event AddActionChoices(uint16 actionId, uint16[] actionChoiceIds, ActionChoice[] choices);
  event EditActionChoice(uint16 actionId, uint16 actionChoiceId, ActionChoice choice);
  event EditActionChoices_(uint16[] actionIds, uint16[] actionChoiceIds, ActionChoice[] choices);
  event NewDailyRewards(Equipment[8] dailyRewards);
  error RandomWordsCannotBeUpdatedYet();
  error CanOnlyRequestAfterTheNextCheckpoint(uint256 currentTime, uint256 checkpoint);
  error RequestAlreadyFulfilled();
  error NoValidRandomWord();
  error CanOnlyRequestAfter1DayHasPassed();
  error ActionIdZeroNotAllowed();
  error MinCannotBeGreaterThanMax();
  error DynamicActionsCannotBeAdded();
  error ActionAlreadyExists();
  error ActionDoesNotExist();
  error ActionChoiceIdZeroNotAllowed();
  error DynamicActionsCannotBeSet();
  error LengthMismatch();
  error NoActionChoices();
  error ActionChoiceAlreadyExists();
  error ActionChoiceDoesNotExist();
  error OnlyCombatMultipleGuaranteedRewards();
  error NotAFactorOf3600();
  error NonCombatCannotHaveBothGuaranteedAndRandomRewards();
  error InvalidDay();
  error InvalidReward();

  struct DailyReward {
    Equipment reward;
    uint8 day;
  }

  // solhint-disable-next-line var-name-mixedcase
  VRFCoordinatorV2Interface public COORDINATOR;

  // Your subscription ID.
  uint64 public subscriptionId;

  // Past request ids
  uint[] public requestIds; // Each one is a set of random words for 1 day
  mapping(uint requestId => uint[3] randomWord) public randomWords;
  uint40 public lastRandomWordsUpdatedTime;
  uint40 public startTime;
  uint40 public weeklyRewardCheckpoint;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network, this is 10000gwei
  // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
  bytes32 public constant KEY_HASH = 0x5881eea62f9876043df723cf89f0c2bb6f950da25e9dfe66995c24f919c8f8ab;

  uint32 public constant CALLBACK_GAS_LIMIT = 500000;
  // The default is 3, but you can set this higher.
  uint16 public constant REQUEST_CONFIRMATIONS = 1;
  // For this example, retrieve 3 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 public constant NUM_WORDS = 3;

  uint32 public constant MIN_RANDOM_WORDS_UPDATE_TIME = 1 days;
  uint32 public constant MIN_DYNAMIC_ACTION_UPDATE_TIME = 1 days;

  mapping(uint actionId => ActionInfo actionInfo) public actions;
  uint16[] private lastAddedDynamicActions;
  uint public lastDynamicUpdatedTime;

  bytes32 public dailyRewards; // Effectively stores Equipment[8] which is packed, first 7 are daily, last one is weekly reward

  mapping(uint actionId => mapping(uint16 choiceId => ActionChoice actionChoice)) private actionChoices;
  mapping(uint actionId => CombatStats combatStats) private actionCombatStats;

  mapping(uint actionId => ActionRewards actionRewards) private actionRewards;

  IQuests private quests;

  mapping(uint index => Equipment[]) public dailyRewardsToBeAdded;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    VRFCoordinatorV2Interface _coordinator,
    uint64 _subscriptionId,
    DailyReward[] calldata _dailyRewards
  ) public initializer {
    __VRFConsumerBaseV2_init(address(_coordinator));
    __Ownable_init();
    __UUPSUpgradeable_init();

    COORDINATOR = _coordinator;
    subscriptionId = _subscriptionId;
    startTime = uint40((block.timestamp / MIN_RANDOM_WORDS_UPDATE_TIME) * MIN_RANDOM_WORDS_UPDATE_TIME) - 5 days; // Floor to the nearest day 00:00 UTC
    lastRandomWordsUpdatedTime = startTime + 4 days;
    weeklyRewardCheckpoint = uint40((block.timestamp - 4 days) / 1 weeks) * 1 weeks + 4 days + 1 weeks;

    // Issue new available daily rewards
    Equipment[8] memory rewards = [
      Equipment(COPPER_ORE, 100),
      Equipment(COAL_ORE, 200),
      Equipment(RUBY, 100),
      Equipment(MITHRIL_BAR, 200),
      Equipment(COOKED_BOWFISH, 100),
      Equipment(LEAF_FRAGMENTS, 20),
      Equipment(HELL_SCROLL, 300),
      Equipment(XP_BOOST, 1)
    ];

    _storeDailyRewards(rewards);
    emit NewDailyRewards(rewards);

    // Initialize 4 days worth of random words
    for (U256 iter; iter.lt(4); iter = iter.inc()) {
      uint i = iter.asUint256();
      uint requestId = 200 + i;
      requestIds.push(requestId);
      emit RequestSent(requestId, NUM_WORDS, startTime + (i * 1 days) + 1 days);
      uint[] memory _randomWords = new uint[](3);
      _randomWords[0] = uint(
        blockhash(block.number - 4 + i) ^ 0x3632d8eba811d69784e6904a58de6e0ab55f32638189623b309895beaa6920c4
      );
      _randomWords[1] = uint(
        blockhash(block.number - 4 + i) ^ 0xca820e9e57e5e703aeebfa2dc60ae09067f931b6e888c0a7c7a15a76341ab2c2
      );
      _randomWords[2] = uint(
        blockhash(block.number - 4 + i) ^ 0xd1f1b7d57307aee9687ae39dbb462b1c1f07a406d34cd380670360ef02f243b6
      );
      fulfillRandomWords(requestId, _randomWords);
    }

    addDailyRewards(_dailyRewards);
  }

  function canRequestRandomWord() external view returns (bool) {
    // Last one has not been fulfilled yet
    if (requestIds.length != 0 && randomWords[requestIds[requestIds.length - 1]][0] == 0) {
      return false;
    }
    if (lastRandomWordsUpdatedTime + MIN_RANDOM_WORDS_UPDATE_TIME > block.timestamp) {
      return false;
    }
    return true;
  }

  function requestRandomWords() external returns (uint256 requestId) {
    // Last one has not been fulfilled yet
    if (requestIds.length != 0 && randomWords[requestIds[requestIds.length - 1]][0] == 0) {
      revert RandomWordsCannotBeUpdatedYet();
    }
    uint40 newLastRandomWordsUpdatedTime = lastRandomWordsUpdatedTime + MIN_RANDOM_WORDS_UPDATE_TIME;
    if (newLastRandomWordsUpdatedTime > block.timestamp) {
      revert CanOnlyRequestAfterTheNextCheckpoint(block.timestamp, newLastRandomWordsUpdatedTime);
    }

    // Will revert if subscription is not set and funded.
    requestId = COORDINATOR.requestRandomWords(
      KEY_HASH,
      subscriptionId,
      REQUEST_CONFIRMATIONS,
      CALLBACK_GAS_LIMIT,
      NUM_WORDS
    );

    requestIds.push(requestId);
    lastRandomWordsUpdatedTime = newLastRandomWordsUpdatedTime;
    emit RequestSent(requestId, NUM_WORDS, newLastRandomWordsUpdatedTime);
    return requestId;
  }

  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
    if (randomWords[_requestId][0] != 0) {
      revert RequestAlreadyFulfilled();
    }

    uint256[3] memory random = [_randomWords[0], _randomWords[1], _randomWords[2]];

    if (random[0] == 0) {
      // Not sure if 0 can be selected, but in case use previous block hash as pseudo random number
      random[0] = uint(blockhash(block.number - 1));
    }
    if (random[1] == 0) {
      random[1] = uint(blockhash(block.number - 2));
    }
    if (random[2] == 0) {
      random[2] = uint(blockhash(block.number - 3));
    }

    randomWords[_requestId] = random;
    if (address(quests) != address(0)) {
      quests.newOracleRandomWords(random);
    }
    emit RequestFulfilled(_requestId, random);

    // Are we at the threshold for a new week
    if (weeklyRewardCheckpoint <= ((block.timestamp) / 1 days) * 1 days) {
      // Issue new daily rewards based on the new random words

      uint randomWord = random[0];
      Equipment[8] memory rewards = [
        dailyRewardsToBeAdded[0][randomWord % dailyRewardsToBeAdded[0].length],
        dailyRewardsToBeAdded[1][(randomWord >> (1 * 8)) % dailyRewardsToBeAdded[1].length],
        dailyRewardsToBeAdded[2][(randomWord >> (2 * 8)) % dailyRewardsToBeAdded[2].length],
        dailyRewardsToBeAdded[3][(randomWord >> (3 * 8)) % dailyRewardsToBeAdded[3].length],
        dailyRewardsToBeAdded[4][(randomWord >> (4 * 8)) % dailyRewardsToBeAdded[4].length],
        dailyRewardsToBeAdded[5][(randomWord >> (5 * 8)) % dailyRewardsToBeAdded[5].length],
        dailyRewardsToBeAdded[6][(randomWord >> (6 * 8)) % dailyRewardsToBeAdded[6].length],
        dailyRewardsToBeAdded[7][(randomWord >> (7 * 8)) % dailyRewardsToBeAdded[7].length]
      ];
      _storeDailyRewards(rewards);
      emit NewDailyRewards(rewards);
      weeklyRewardCheckpoint = uint40((block.timestamp - 4 days) / 1 weeks) * 1 weeks + 4 days + 1 weeks;
    }
  }

  function addDailyRewards(DailyReward[] calldata _dailyRewards) public {
    for (uint i = 0; i < _dailyRewards.length; ++i) {
      if (_dailyRewards[i].day > 7) {
        revert InvalidDay();
      }
      if (_dailyRewards[i].reward.itemTokenId == 0) {
        revert InvalidReward();
      }

      dailyRewardsToBeAdded[_dailyRewards[i].day].push(_dailyRewards[i].reward);
    }
  }

  function getDailyReward() external view returns (uint itemTokenId, uint amount) {
    uint checkpoint = ((block.timestamp - 4 days) / 1 weeks) * 1 weeks + 4 days;
    uint day = ((block.timestamp / 1 days) * 1 days - checkpoint) / 1 days;
    (itemTokenId, amount) = _getDailyReward(day);
  }

  function getWeeklyReward() external view returns (uint itemTokenId, uint amount) {
    (itemTokenId, amount) = _getDailyReward(7);
  }

  function _getRandomWordOffset(uint _timestamp) private view returns (int) {
    if (_timestamp < startTime) {
      return -1;
    }
    return int((_timestamp - startTime) / MIN_RANDOM_WORDS_UPDATE_TIME);
  }

  // Just returns the first random word of the array
  function _getRandomWord(uint _timestamp) private view returns (uint) {
    int offset = _getRandomWordOffset(_timestamp);
    if (offset < 0 || requestIds.length <= uint(offset)) {
      return 0;
    }
    return randomWords[requestIds[uint(offset)]][0];
  }

  function hasRandomWord(uint _timestamp) external view returns (bool) {
    return _getRandomWord(_timestamp) != 0;
  }

  function getRandomWord(uint _timestamp) public view returns (uint randomWord) {
    randomWord = _getRandomWord(_timestamp);
    if (randomWord == 0) {
      revert NoValidRandomWord();
    }
  }

  function getFullRandomWords(uint _timestamp) public view returns (uint[3] memory) {
    int offset = _getRandomWordOffset(_timestamp);
    if (offset < 0 || requestIds.length <= uint(offset)) {
      revert NoValidRandomWord();
    }
    return randomWords[requestIds[uint(offset)]];
  }

  function getMultipleFullRandomWords(uint _timestamp) public view returns (uint[3][5] memory words) {
    for (U256 iter; iter.lt(5); iter = iter.inc()) {
      uint i = iter.asUint256();
      words[i] = getFullRandomWords(_timestamp - i * 1 days);
    }
  }

  function getSkill(uint _actionId) external view returns (Skill) {
    return actions[_actionId].skill;
  }

  function getActionRewards(uint _actionId) external view returns (ActionRewards memory) {
    return actionRewards[_actionId];
  }

  function getPermissibleItemsForAction(
    uint _actionId
  )
    external
    view
    returns (
      uint16 handItemTokenIdRangeMin,
      uint16 handItemTokenIdRangeMax,
      bool actionChoiceRequired,
      Skill skill,
      uint32 minXP,
      bool actionAvailable
    )
  {
    ActionInfo storage actionInfo = actions[_actionId];
    return (
      actionInfo.handItemTokenIdRangeMin,
      actionInfo.handItemTokenIdRangeMax,
      actionInfo.actionChoiceRequired,
      actionInfo.skill,
      actionInfo.minXP,
      actionInfo.isAvailable
    );
  }

  function getXPPerHour(uint16 _actionId, uint16 _actionChoiceId) external view returns (uint24 xpPerHour) {
    return _actionChoiceId != 0 ? actionChoices[_actionId][_actionChoiceId].xpPerHour : actions[_actionId].xpPerHour;
  }

  function getNumSpawn(uint16 _actionId) external view returns (uint numSpawned) {
    return actions[_actionId].numSpawned;
  }

  function getCombatStats(uint16 _actionId) external view returns (CombatStats memory stats) {
    stats = actionCombatStats[_actionId];
  }

  function getActionChoice(uint16 _actionId, uint16 _choiceId) external view returns (ActionChoice memory) {
    return actionChoices[_actionId][_choiceId];
  }

  function getActionSuccessPercentAndMinXP(
    uint16 _actionId
  ) external view returns (uint8 successPercent, uint32 minXP) {
    return (actions[_actionId].successPercent, actions[_actionId].minXP);
  }

  function getRewardsHelper(
    uint16 _actionId
  ) external view returns (ActionRewards memory, Skill skill, uint numSpanwed, uint8 worldLocation) {
    return (
      actionRewards[_actionId],
      actions[_actionId].skill,
      actions[_actionId].numSpawned,
      actions[_actionId].worldLocation
    );
  }

  function getRandomBytes(uint _numTickets, uint _skillEndTime, uint _playerId) external view returns (bytes memory b) {
    if (_numTickets <= 16) {
      // 32 bytes
      bytes32 word = bytes32(getRandomWord(_skillEndTime));
      b = abi.encodePacked(_getRandomComponent(word, _skillEndTime, _playerId));
    } else if (_numTickets <= 48) {
      uint[3] memory fullWords = getFullRandomWords(_skillEndTime);
      // 3 * 32 bytes
      for (U256 iter; iter.lt(3); iter = iter.inc()) {
        uint i = iter.asUint256();
        fullWords[i] = uint(_getRandomComponent(bytes32(fullWords[i]), _skillEndTime, _playerId));
      }
      b = abi.encodePacked(fullWords);
    } else {
      // 3 * 5 * 32 bytes
      uint[3][5] memory multipleFullWords = getMultipleFullRandomWords(_skillEndTime);
      for (U256 iter; iter.lt(5); iter = iter.inc()) {
        uint i = iter.asUint256();
        for (U256 jter; jter.lt(3); jter = jter.inc()) {
          uint j = jter.asUint256();
          multipleFullWords[i][j] = uint(
            _getRandomComponent(bytes32(multipleFullWords[i][j]), _skillEndTime, _playerId)
          );
          // XOR all the full words with the first fresh random number to give more randomness to the existing random words
          if (i != 0) {
            multipleFullWords[i][j] = multipleFullWords[i][j] ^ multipleFullWords[0][j];
          }
        }
      }

      b = abi.encodePacked(multipleFullWords);
    }
  }

  function _addAction(Action calldata _action) private {
    if (_action.info.isDynamic) {
      revert DynamicActionsCannotBeAdded();
    }
    if (actions[_action.actionId].skill != Skill.NONE) {
      revert ActionAlreadyExists();
    }
    _setAction(_action);
  }

  function _getDailyReward(uint256 _day) private view returns (uint itemTokenId, uint amount) {
    itemTokenId = uint((dailyRewards & ((bytes32(hex"ffff0000") >> (_day * 32)))) >> ((7 - _day) * 32 + 16));
    amount = uint((dailyRewards & ((bytes32(hex"0000ffff") >> (_day * 32)))) >> ((7 - _day) * 32));
  }

  function _getUpdatedDailyReward(
    uint _index,
    Equipment memory _equipment,
    bytes32 _rewards
  ) private pure returns (bytes32) {
    bytes32 rewardItemTokenId;
    bytes32 rewardAmount;
    assembly ("memory-safe") {
      rewardItemTokenId := mload(_equipment)
      rewardAmount := mload(add(_equipment, 32))
    }

    _rewards = _rewards | (rewardItemTokenId << ((7 - _index) * 32 + 16));
    _rewards = _rewards | (rewardAmount << ((7 - _index) * 32));
    return _rewards;
  }

  function _storeDailyRewards(Equipment[8] memory equipments) private {
    bytes32 rewards;
    U256 bounds = equipments.length.asU256();
    for (U256 iter; iter < bounds; iter = iter.inc()) {
      uint i = iter.asUint256();
      rewards = _getUpdatedDailyReward(i, equipments[i], rewards);
    }
    dailyRewards = rewards;
  }

  function _setAction(Action calldata _action) private {
    if (_action.actionId == 0) {
      revert ActionIdZeroNotAllowed();
    }
    if (_action.info.handItemTokenIdRangeMin > _action.info.handItemTokenIdRangeMax) {
      revert MinCannotBeGreaterThanMax();
    }

    if (_action.info.skill != Skill.COMBAT && _action.guaranteedRewards.length > 1) {
      revert OnlyCombatMultipleGuaranteedRewards();
    }

    if (_action.info.numSpawned != 0) {
      // Combat
      if ((3600 * SPAWN_MUL) % _action.info.numSpawned != 0) {
        revert NotAFactorOf3600();
      }
    } else if (_action.guaranteedRewards.length != 0) {
      // Non-combat guaranteed rewards
      if ((3600 * GUAR_MUL) % _action.guaranteedRewards[0].rate != 0) {
        revert NotAFactorOf3600();
      }
    }

    actions[_action.actionId] = _action.info;

    // Set the rewards
    ActionRewards storage actionReward = actionRewards[_action.actionId];
    WorldLibrary.setActionGuaranteedRewards(_action, actionReward);
    WorldLibrary.setActionRandomRewards(_action, actionReward);

    if (_action.info.skill == Skill.COMBAT) {
      actionCombatStats[_action.actionId] = _action.combatStats;
    } else {
      bool actionHasGuaranteedRewards = _action.guaranteedRewards.length != 0;
      bool actionHasRandomRewards = _action.randomRewards.length != 0;
      if (actionHasGuaranteedRewards && actionHasRandomRewards) {
        revert NonCombatCannotHaveBothGuaranteedAndRandomRewards();
      }
    }
  }

  function _addActionChoice(uint16 _actionId, uint16 _actionChoiceId, ActionChoice calldata _actionChoice) private {
    if (_actionChoiceId == 0) {
      revert ActionChoiceIdZeroNotAllowed();
    }
    if (actionChoices[_actionId][_actionChoiceId].skill != Skill.NONE) {
      revert ActionChoiceAlreadyExists();
    }
    WorldLibrary.checkActionChoice(_actionChoice);

    actionChoices[_actionId][_actionChoiceId] = _actionChoice;
  }

  function _editActionChoice(uint16 _actionId, uint16 _actionChoiceId, ActionChoice calldata _actionChoice) private {
    if (actionChoices[_actionId][_actionChoiceId].skill == Skill.NONE) {
      revert ActionChoiceDoesNotExist();
    }

    WorldLibrary.checkActionChoice(_actionChoice);

    actionChoices[_actionId][_actionChoiceId] = _actionChoice;
  }

  function _getRandomComponent(bytes32 _word, uint _skillEndTime, uint _playerId) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(_word, _skillEndTime, _playerId));
  }

  function addAction(Action calldata _action) external onlyOwner {
    _addAction(_action);
    emit AddActionV2(_action);
  }

  function addActions(Action[] calldata _actions) external onlyOwner {
    U256 iter = _actions.length.asU256();
    while (iter.neq(0)) {
      iter = iter.dec();
      uint16 i = iter.asUint16();
      _addAction(_actions[i]);
    }
    emit AddActionsV2(_actions);
  }

  function editActions(Action[] calldata _actions) external onlyOwner {
    for (uint i = 0; i < _actions.length; ++i) {
      if (actions[_actions[i].actionId].skill == Skill.NONE) {
        revert ActionDoesNotExist();
      }
      _setAction(_actions[i]);
    }
    emit EditActionsV2(_actions);
  }

  // actionId of 0 means it is not tied to a specific action (combat)
  function addActionChoice(
    uint16 _actionId,
    uint16 _actionChoiceId,
    ActionChoice calldata _actionChoice
  ) external onlyOwner {
    _addActionChoice(_actionId, _actionChoiceId, _actionChoice);
    emit AddActionChoice(_actionId, _actionChoiceId, _actionChoice);
  }

  function addBulkActionChoices(
    uint16[] calldata _actionIds,
    uint16[][] calldata _actionChoiceIds,
    ActionChoice[][] calldata _actionChoices
  ) external onlyOwner {
    if (_actionIds.length != _actionChoices.length) {
      revert LengthMismatch();
    }
    if (_actionIds.length == 0) {
      revert NoActionChoices();
    }

    U256 actionIdsLength = _actionIds.length.asU256();
    for (U256 iter; iter < actionIdsLength; iter = iter.inc()) {
      uint16 i = iter.asUint16();
      uint16 actionId = _actionIds[i];
      emit AddActionChoices(actionId, _actionChoiceIds[i], _actionChoices[i]);

      U256 actionChoiceLength = _actionChoices[i].length.asU256();

      if (actionChoiceLength.neq(_actionChoiceIds[i].length)) {
        revert LengthMismatch();
      }

      for (U256 jter; jter < actionChoiceLength; jter = jter.inc()) {
        uint16 j = jter.asUint16();
        _addActionChoice(actionId, _actionChoiceIds[i][j], _actionChoices[i][j]);
      }
    }
  }

  function editActionChoice(uint16 _actionId, uint16 _actionChoiceId, ActionChoice calldata _actionChoice) external {
    _editActionChoice(_actionId, _actionChoiceId, _actionChoice);
    emit EditActionChoice(_actionId, _actionChoiceId, _actionChoice);
  }

  function editActionChoices(
    uint16[] calldata _actionIds,
    uint16[] calldata _actionChoiceIds,
    ActionChoice[] calldata _actionChoices
  ) external {
    if (_actionIds.length == 0) {
      revert NoActionChoices();
    }
    if (_actionIds.length != _actionChoiceIds.length) {
      revert LengthMismatch();
    }
    if (_actionIds.length != _actionChoices.length) {
      revert LengthMismatch();
    }

    U256 actionIdsLength = _actionIds.length.asU256();
    for (U256 iter; iter < actionIdsLength; iter = iter.inc()) {
      uint16 i = iter.asUint16();
      _editActionChoice(_actionIds[i], _actionChoiceIds[i], _actionChoices[i]);
    }

    emit EditActionChoices_(_actionIds, _actionChoiceIds, _actionChoices);
  }

  function setAvailable(uint16 _actionId, bool _isAvailable) external onlyOwner {
    if (actions[_actionId].skill == Skill.NONE) {
      revert ActionDoesNotExist();
    }
    if (actions[_actionId].isDynamic) {
      revert DynamicActionsCannotBeSet();
    }
    actions[_actionId].isAvailable = _isAvailable;
    emit SetAvailableAction(_actionId, _isAvailable);
  }

  function setQuests(IQuests _quests) external onlyOwner {
    quests = _quests;
  }

  // solhint-disable-next-line no-empty-blocks
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UnsafeMath, U256} from "@0xdoublesharp/unsafe-math/contracts/UnsafeMath.sol";

// solhint-disable-next-line no-global-import
import "./globals/all.sol";

// This file contains methods for interacting with the World, used to decrease implementation deployment bytecode code.
library WorldLibrary {
  using UnsafeMath for U256;
  using UnsafeMath for uint;

  error InputSpecifiedWithoutAmount();
  error PreviousInputTokenIdMustBeSpecified();
  error InputAmountsMustBeInOrder();
  error OutputSpecifiedWithoutAmount();
  error RandomRewardsMustBeInOrder(uint16 chance1, uint16 chance2);
  error RandomRewardNoDuplicates();
  error GuaranteedRewardsMustBeInOrder();
  error GuaranteedRewardsNoDuplicates();
  error NotAFactorOf3600();

  function checkActionChoice(ActionChoice calldata _actionChoice) external pure {
    if (_actionChoice.inputTokenId1 != NONE && _actionChoice.inputAmount1 == 0) {
      revert InputSpecifiedWithoutAmount();
    }
    if (_actionChoice.inputTokenId2 != NONE) {
      if (_actionChoice.inputAmount2 == 0) {
        revert InputSpecifiedWithoutAmount();
      }
      if (_actionChoice.inputTokenId1 == NONE) {
        revert PreviousInputTokenIdMustBeSpecified();
      }
      if (_actionChoice.inputAmount2 < _actionChoice.inputAmount1) {
        revert InputAmountsMustBeInOrder();
      }
    }
    if (_actionChoice.inputTokenId3 != NONE) {
      if (_actionChoice.inputAmount3 == 0) {
        revert InputSpecifiedWithoutAmount();
      }
      if (_actionChoice.inputTokenId2 == NONE) {
        revert PreviousInputTokenIdMustBeSpecified();
      }
      if (_actionChoice.inputAmount3 < _actionChoice.inputAmount2) {
        revert InputAmountsMustBeInOrder();
      }
    }

    if (_actionChoice.outputTokenId != 0 && _actionChoice.outputAmount == 0) {
      revert OutputSpecifiedWithoutAmount();
    }

    if (_actionChoice.rate != 0) {
      // Check that it is a factor of 3600
      if ((3600 * RATE_MUL) % _actionChoice.rate != 0) {
        revert NotAFactorOf3600();
      }
    }
  }

  // Random rewards have most common one first
  function setActionRandomRewards(Action calldata _action, ActionRewards storage actionReward) external {
    uint randomRewardsLength = _action.randomRewards.length;
    if (randomRewardsLength != 0) {
      actionReward.randomRewardTokenId1 = _action.randomRewards[0].itemTokenId;
      actionReward.randomRewardChance1 = _action.randomRewards[0].chance;
      actionReward.randomRewardAmount1 = _action.randomRewards[0].amount;
    }
    if (randomRewardsLength > 1) {
      actionReward.randomRewardTokenId2 = _action.randomRewards[1].itemTokenId;
      actionReward.randomRewardChance2 = _action.randomRewards[1].chance;
      actionReward.randomRewardAmount2 = _action.randomRewards[1].amount;

      if (actionReward.randomRewardChance2 > actionReward.randomRewardChance1) {
        revert RandomRewardsMustBeInOrder(_action.randomRewards[0].chance, _action.randomRewards[1].chance);
      }
      if (actionReward.randomRewardTokenId1 == actionReward.randomRewardTokenId2) {
        revert RandomRewardNoDuplicates();
      }
    }
    if (randomRewardsLength > 2) {
      actionReward.randomRewardTokenId3 = _action.randomRewards[2].itemTokenId;
      actionReward.randomRewardChance3 = _action.randomRewards[2].chance;
      actionReward.randomRewardAmount3 = _action.randomRewards[2].amount;

      if (actionReward.randomRewardChance3 > actionReward.randomRewardChance2) {
        revert RandomRewardsMustBeInOrder(_action.randomRewards[1].chance, _action.randomRewards[2].chance);
      }

      U256 bounds = randomRewardsLength.dec().asU256();
      for (U256 iter; iter < bounds; iter = iter.inc()) {
        uint i = iter.asUint256();
        if (_action.randomRewards[i].itemTokenId == _action.randomRewards[randomRewardsLength.dec()].itemTokenId) {
          revert RandomRewardNoDuplicates();
        }
      }
    }
    if (_action.randomRewards.length > 3) {
      actionReward.randomRewardTokenId4 = _action.randomRewards[3].itemTokenId;
      actionReward.randomRewardChance4 = _action.randomRewards[3].chance;
      actionReward.randomRewardAmount4 = _action.randomRewards[3].amount;
      if (actionReward.randomRewardChance4 > actionReward.randomRewardChance3) {
        revert RandomRewardsMustBeInOrder(_action.randomRewards[2].chance, _action.randomRewards[3].chance);
      }
      U256 bounds = _action.randomRewards.length.dec().asU256();
      for (U256 iter; iter < bounds; iter = iter.inc()) {
        uint i = iter.asUint256();
        if (
          _action.randomRewards[i].itemTokenId == _action.randomRewards[_action.randomRewards.length - 1].itemTokenId
        ) {
          revert RandomRewardNoDuplicates();
        }
      }
    }
  }

  function setActionGuaranteedRewards(Action calldata _action, ActionRewards storage _actionRewards) external {
    uint guaranteedRewardsLength = _action.guaranteedRewards.length;
    if (guaranteedRewardsLength != 0) {
      _actionRewards.guaranteedRewardTokenId1 = _action.guaranteedRewards[0].itemTokenId;
      _actionRewards.guaranteedRewardRate1 = _action.guaranteedRewards[0].rate;
    }
    if (guaranteedRewardsLength > 1) {
      _actionRewards.guaranteedRewardTokenId2 = _action.guaranteedRewards[1].itemTokenId;
      _actionRewards.guaranteedRewardRate2 = _action.guaranteedRewards[1].rate;
      if (_actionRewards.guaranteedRewardRate2 < _actionRewards.guaranteedRewardRate1) {
        revert GuaranteedRewardsMustBeInOrder();
      }
      if (_actionRewards.guaranteedRewardTokenId1 == _actionRewards.guaranteedRewardTokenId2) {
        revert GuaranteedRewardsNoDuplicates();
      }
    }
    if (guaranteedRewardsLength > 2) {
      _actionRewards.guaranteedRewardTokenId3 = _action.guaranteedRewards[2].itemTokenId;
      _actionRewards.guaranteedRewardRate3 = _action.guaranteedRewards[2].rate;

      if (_actionRewards.guaranteedRewardRate3 < _actionRewards.guaranteedRewardRate2) {
        revert GuaranteedRewardsMustBeInOrder();
      }

      U256 bounds = guaranteedRewardsLength.dec().asU256();
      for (U256 iter; iter < bounds; iter = iter.inc()) {
        uint i = iter.asUint256();
        if (
          _action.guaranteedRewards[i].itemTokenId ==
          _action.guaranteedRewards[guaranteedRewardsLength.dec()].itemTokenId
        ) {
          revert GuaranteedRewardsNoDuplicates();
        }
      }
    }
  }
}