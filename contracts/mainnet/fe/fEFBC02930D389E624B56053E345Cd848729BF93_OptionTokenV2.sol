/**
 *Submitted for verification at FtmScan.com on 2023-06-30
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;


// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)




// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)



/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)




// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)



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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)



/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}


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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)




// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)



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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}




/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}



interface IERC20 {
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


interface IFlow {
    function totalSupply() external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address,address,uint) external returns (bool);
    function mint(address, uint) external returns (bool);
    function minter() external returns (address);
}



interface IGaugeV2 {
    function left(address token) external view returns (uint);
    function notifyRewardAmount(address token, uint amount) external;

    function depositWithLock(
        address account,
        uint256 amount,
        uint256 _lockDuration
    ) external;
}



interface IVoter {
    function _ve() external view returns (address);
    function governor() external view returns (address);
    function emergencyCouncil() external view returns (address);
    function attachTokenToGauge(uint _tokenId, address account) external;
    function detachTokenFromGauge(uint _tokenId, address account) external;
    function emitDeposit(uint _tokenId, address account, uint amount) external;
    function emitWithdraw(uint _tokenId, address account, uint amount) external;
    function isWhitelisted(address token) external view returns (bool);
    function notifyRewardAmount(uint amount) external;
    function distribute(address _gauge) external;
    function gauges(address) external view returns (address);
}



interface IVotingEscrow {

    struct Point {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    function token() external view returns (address);
    function team() external returns (address);
    function epoch() external view returns (uint);
    function point_history(uint loc) external view returns (Point memory);
    function user_point_history(uint tokenId, uint loc) external view returns (Point memory);
    function user_point_epoch(uint tokenId) external view returns (uint);

    function ownerOf(uint) external view returns (address);
    function isApprovedOrOwner(address, uint) external view returns (bool);
    function transferFrom(address, address, uint) external;

    function voting(uint tokenId) external;
    function abstain(uint tokenId) external;
    function attach(uint tokenId) external;
    function detach(uint tokenId) external;

    function checkpoint() external;
    function deposit_for(uint tokenId, uint value) external;
    function create_lock_for(uint, uint, address) external returns (uint);

    function balanceOfNFT(uint) external view returns (uint);
    function totalSupply() external view returns (uint);
}


interface IPair {
    function metadata() external view returns (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, address t1);
    function tokens() external returns (address, address);
    function token0() external returns (address);
    function token1() external returns (address);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function burn(address to) external returns (uint amount0, uint amount1);
    function mint(address to) external returns (uint liquidity);
    function getReserves() external view returns (uint _reserve0, uint _reserve1, uint _blockTimestampLast);
    function getAmountOut(uint, address) external view returns (uint);
    function setHasGauge(bool value) external;
    function setExternalBribe(address _externalBribe) external;
    function hasGauge() external view returns (bool);
    function stable() external view returns (bool);
    function prices(address tokenIn, uint amountIn, uint points) external view returns (uint[] memory);
}



interface IRouter {
    function pairFor(address tokenA, address tokenB, bool stable) external view returns (address pair);
    function getReserves(address tokenA, address tokenB, bool stable) external view returns (uint, uint);
    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint, uint, uint);
}


/// @title Option Token
/// @notice Option token representing the right to purchase the underlying token
/// at TWAP reduced rate. Similar to call options but with a variable strike
/// price that's always at a certain discount to the market price.
/// @dev Assumes the underlying token and the payment token both use 18 decimals and revert on
// failure to transfer.

contract OptionTokenV2 is ERC20, AccessControl {
    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------
    uint256 public constant MAX_DISCOUNT = 100; // 100%
    uint256 public constant MIN_DISCOUNT = 0; // 0%
    uint256 public constant MAX_TWAP_POINTS = 50; // 25 hours
    uint256 public constant FULL_LOCK = 52 * 7 * 86400; // 52 weeks
    uint256 public constant MAX_TEAM_FEE = 50; // 50%

    /// -----------------------------------------------------------------------
    /// Roles
    /// -----------------------------------------------------------------------
    /// @dev The identifier of the role which maintains other roles and settings
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    /// @dev The identifier of the role which is allowed to mint options token
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    /// @dev The identifier of the role which allows accounts to pause execrcising options
    /// in case of emergency
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER");

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------
    error OptionToken_PastDeadline();
    error OptionToken_NoAdminRole();
    error OptionToken_NoMinterRole();
    error OptionToken_NoPauserRole();
    error OptionToken_SlippageTooHigh();
    error OptionToken_InvalidDiscount();
    error OptionToken_InvalidLockDuration();
    error OptionToken_InvalidTeamFee();
    error OptionToken_Paused();
    error OptionToken_InvalidTwapPoints();
    error OptionToken_IncorrectPairToken();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Exercise(
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        uint256 paymentAmount
    );
    event ExerciseVe(
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        uint256 paymentAmount,
        uint256 nftId
    );
    event ExerciseLp(
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        uint256 paymentAmount,
        uint256 lpAmount
    );
    event SetPairAndPaymentToken(
        IPair indexed newPair,
        address indexed newPaymentToken
    );
    event SetGauge(address indexed newGauge);
    event SetTreasury(address indexed newTreasury);
    event SetTeamFee(uint256 newFee);
    event SetRouter(address indexed newRouter);
    event SetDiscount(uint256 discount);
    event SetVeDiscount(uint256 veDiscount);
    event SetMinLPDiscount(uint256 lpMinDiscount);
    event SetMaxLPDiscount(uint256 lpMaxDiscount);
    event SetLockDurationForMaxLpDiscount(uint256 lockDurationForMaxLpDiscount);
    event SetLockDurationForMinLpDiscount(uint256 lockDurationForMinLpDiscount);
    event PauseStateChanged(bool isPaused);
    event SetTwapPoints(uint256 twapPoints);

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    /// @notice The token paid by the options token holder during redemption
    address public paymentToken;

    /// @notice The underlying token purchased during redemption
    address public immutable underlyingToken;

    /// @notice The voting escrow for locking FLOW to veFLOW
    address public immutable votingEscrow;

    /// @notice The voter contract
    address public immutable voter;

 

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------


       /// @notice The router for adding liquidity
    address public router; // this should not be immutable

    /// @notice The pair contract that provides the current TWAP price to purchase
    /// the underlying token while exercising options (the strike price)
    IPair public pair;

    /// @notice The guage contract for the pair
    address public gauge;

    /// @notice The treasury address which receives tokens paid during redemption
    address public treasury;

    /// @notice the discount given during exercising with locking to the LP
    uint256 public  maxLPDiscount = 20; //  User pays 20%
    uint256 public  minLPDiscount = 80; //  User pays 80%

    /// @notice the discount given during exercising. 30 = user pays 30%
    uint256 public discount = 90; // User pays 90%

    /// @notice the discount for locking to veFLOW
    uint256 public veDiscount = 10; // User pays 10%

    /// @notice the lock duration for max discount to create locked LP
    uint256 public lockDurationForMaxLpDiscount = FULL_LOCK; // 52 weeks

    // @notice the lock duration for max discount to create locked LP
    uint256 public lockDurationForMinLpDiscount = 7 * 86400; // 1 week

    /// @notice
    uint256 public teamFee = 10; // 10%

    /// @notice controls the duration of the twap used to calculate the strike price
    // each point represents 30 minutes. 4 points = 2 hours
    uint256 public twapPoints = 4;

    /// @notice Is excersizing options currently paused
    bool public isPaused;

    /// -----------------------------------------------------------------------
    /// Modifiers
    /// -----------------------------------------------------------------------
    /// @dev A modifier which checks that the caller has the admin role.
    modifier onlyAdmin() {
        if (!hasRole(ADMIN_ROLE, msg.sender)) revert OptionToken_NoAdminRole();
        _;
    }

    /// @dev A modifier which checks that the caller has the admin role.
    modifier onlyMinter() {
        if (
            !hasRole(ADMIN_ROLE, msg.sender) &&
            !hasRole(MINTER_ROLE, msg.sender)
        ) revert OptionToken_NoMinterRole();
        _;
    }

    /// @dev A modifier which checks that the caller has the pause role.
    modifier onlyPauser() {
        if (!hasRole(PAUSER_ROLE, msg.sender))
            revert OptionToken_NoPauserRole();
        _;
    }

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(
        string memory _name,
        string memory _symbol,
        address _admin,
        address _paymentToken,
        address _underlyingToken,
        IPair _pair,
        address _gaugeFactory,
        address _treasury,
        address _voter,
        address _votingEscrow,
        address _router
    ) ERC20(_name, _symbol, 18) {
        _grantRole(ADMIN_ROLE, _admin);
        _grantRole(PAUSER_ROLE, _admin);
        _grantRole(ADMIN_ROLE, _gaugeFactory);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, ADMIN_ROLE);
        paymentToken = _paymentToken;
        underlyingToken = _underlyingToken;
        pair = _pair;
        treasury = _treasury;
        voter = _voter;
        votingEscrow = _votingEscrow;
        router = _router;

        emit SetPairAndPaymentToken(_pair, paymentToken);
        emit SetTreasury(_treasury);
        emit SetRouter(_router);
    }

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    /// @notice Exercises options tokens to purchase the underlying tokens.
    /// @dev The oracle may revert if it cannot give a secure result.
    /// @param _amount The amount of options tokens to exercise
    /// @param _maxPaymentAmount The maximum acceptable amount to pay. Used for slippage protection.
    /// @param _recipient The recipient of the purchased underlying tokens
    /// @return The amount paid to the treasury to purchase the underlying tokens
    function exercise(
        uint256 _amount,
        uint256 _maxPaymentAmount,
        address _recipient
    ) external returns (uint256) {
        return _exercise(_amount, _maxPaymentAmount, _recipient);
    }

    /// @notice Exercises options tokens to purchase the underlying tokens.
    /// @dev The oracle may revert if it cannot give a secure result.
    /// @param _amount The amount of options tokens to exercise
    /// @param _maxPaymentAmount The maximum acceptable amount to pay. Used for slippage protection.
    /// @param _recipient The recipient of the purchased underlying tokens
    /// @param _deadline The Unix timestamp (in seconds) after which the call will revert
    /// @return The amount paid to the treasury to purchase the underlying tokens
    function exercise(
        uint256 _amount,
        uint256 _maxPaymentAmount,
        address _recipient,
        uint256 _deadline
    ) external returns (uint256) {
        if (block.timestamp > _deadline) revert OptionToken_PastDeadline();
        return _exercise(_amount, _maxPaymentAmount, _recipient);
    }

    /// @notice Exercises options tokens to purchase the underlying tokens.
    /// @dev The oracle may revert if it cannot give a secure result.
    /// @param _amount The amount of options tokens to exercise
    /// @param _maxPaymentAmount The maximum acceptable amount to pay. Used for slippage protection.
    /// @param _recipient The recipient of the purchased underlying tokens
    /// @param _deadline The Unix timestamp (in seconds) after which the call will revert
    /// @return The amount paid to the treasury to purchase the underlying tokens
    function exerciseVe(
        uint256 _amount,
        uint256 _maxPaymentAmount,
        address _recipient,
        uint256 _deadline
    ) external returns (uint256, uint256) {
        if (block.timestamp > _deadline) revert OptionToken_PastDeadline();
        return _exerciseVe(_amount, _maxPaymentAmount, _recipient);
    }

    /// @notice Exercises options tokens to create LP and stake in gauges with lock.
    /// @dev The oracle may revert if it cannot give a secure result.
    /// @param _amount The amount of options tokens to exercise
    /// @param _maxPaymentAmount The maximum acceptable amount to pay. Used for slippage protection.
    /// @param _discount The desired discount
    /// @param _deadline The Unix timestamp (in seconds) after which the call will revert
    /// @return The amount paid to the treasury to purchase the underlying tokens

    function exerciseLp(
        uint256 _amount,
        uint256 _maxPaymentAmount,
        address _recipient,
        uint256 _discount,
        uint256 _deadline
    ) external returns (uint256, uint256) {
        if (block.timestamp > _deadline) revert OptionToken_PastDeadline();
        return _exerciseLp(_amount, _maxPaymentAmount, _recipient, _discount);
    }

    /// -----------------------------------------------------------------------
    /// Public functions
    /// -----------------------------------------------------------------------

    /// @notice Returns the discounted price in paymentTokens for a given amount of options tokens
    /// @param _amount The amount of options tokens to exercise
    /// @return The amount of payment tokens to pay to purchase the underlying tokens
    function getDiscountedPrice(uint256 _amount) public view returns (uint256) {
        return (getTimeWeightedAveragePrice(_amount) * discount) / 100;
    }

    /// @notice Returns the discounted price in paymentTokens for a given amount of options tokens redeemed to veFLOW
    /// @param _amount The amount of options tokens to exercise
    /// @return The amount of payment tokens to pay to purchase the underlying tokens
    function getVeDiscountedPrice(
        uint256 _amount
    ) public view returns (uint256) {
        return (getTimeWeightedAveragePrice(_amount) * veDiscount) / 100;
    }

    /// @notice Returns the discounted price in paymentTokens for a given amount of options tokens redeemed to veFLOW
    /// @param _amount The amount of options tokens to exercise
    /// @param _discount The discount amount
    /// @return The amount of payment tokens to pay to purchase the underlying tokens
    function getLpDiscountedPrice(
        uint256 _amount,
        uint256 _discount
    ) public view returns (uint256) {
        return (getTimeWeightedAveragePrice(_amount) * _discount) / 100;
    }

    /// @notice Returns the lock duration for a desired discount to create locked LP
    ///
    function getLockDurationForLpDiscount(
        uint256 _discount
    ) public view returns (uint256 duration) {
        (int256 slope, int256 intercept) = getSlopeInterceptForLpDiscount();
        duration = SignedMath.abs(slope * int256(_discount) + intercept);
    }

     // @notice Returns the amount in paymentTokens for a given amount of options tokens required for the LP exercise lp
    /// @param _amount The amount of options tokens to exercise
    /// @param _discount The discount amount
    function getPaymentTokenAmountForExerciseLp(uint256 _amount,uint256 _discount) public view returns (uint256 paymentAmount, uint256 paymentAmountToAddLiquidity)
    {
        paymentAmount = getLpDiscountedPrice(_amount, _discount);
        (uint256 underlyingReserve, uint256 paymentReserve) = IRouter(router).getReserves(underlyingToken, paymentToken, false);
        paymentAmountToAddLiquidity = (_amount * paymentReserve) / underlyingReserve;
    }

    function getSlopeInterceptForLpDiscount()
        public
        view
        returns (int256 slope, int256 intercept)
    {
        slope =
            int256(lockDurationForMaxLpDiscount - lockDurationForMinLpDiscount) /
            (int256(maxLPDiscount) - int256(minLPDiscount));
        intercept = int256(lockDurationForMinLpDiscount) - (slope * int256(minLPDiscount));
    }

    /// @notice Returns the average price in payment tokens over 2 hours for a given amount of underlying tokens
    /// @param _amount The amount of underlying tokens to purchase
    /// @return The amount of payment tokens
    function getTimeWeightedAveragePrice(
        uint256 _amount
    ) public view returns (uint256) {
        uint256[] memory amtsOut = IPair(pair).prices(
            underlyingToken,
            _amount,
            twapPoints
        );
        uint256 len = amtsOut.length;
        uint256 summedAmount;

        for (uint256 i = 0; i < len; i++) {
            summedAmount += amtsOut[i];
        }

        return summedAmount / twapPoints;
    }

    /// -----------------------------------------------------------------------
    /// Admin functions
    /// -----------------------------------------------------------------------

    /// @notice Sets the pair contract. Only callable by the admin.
    /// @param _pair The new pair contract
    function setPairAndPaymentToken(
        IPair _pair,
        address _paymentToken
    ) external onlyAdmin {
        (address token0, address token1) = _pair.tokens();
        if (
            !((token0 == _paymentToken && token1 == underlyingToken) ||
                (token0 == underlyingToken && token1 == _paymentToken))
        ) revert OptionToken_IncorrectPairToken();
        pair = _pair;
        gauge = IVoter(voter).gauges(address(_pair));
        paymentToken = _paymentToken;
        emit SetPairAndPaymentToken(_pair, _paymentToken);
    }

    /// @notice Update gauge address to match with Voter contract
    function updateGauge() external {
        address newGauge = IVoter(voter).gauges(address(pair));
        gauge = newGauge;
        emit SetGauge(newGauge);
    }

    /// @notice Sets the gauge address when the gauge is not listed in Voter. Only callable by the admin.
    /// @param _gauge The new treasury address
    function setGauge(address _gauge) external onlyAdmin {
        gauge = _gauge;
        emit SetGauge(_gauge);
    }

    /// @notice Sets the treasury address. Only callable by the admin.
    /// @param _treasury The new treasury address
    function setTreasury(address _treasury) external onlyAdmin {
        treasury = _treasury;
        emit SetTreasury(_treasury);
    }

    /// @notice Sets the router address. Only callable by the admin.
    /// @param _router The new router address
    function setRouter(address _router) external onlyAdmin {
        router = _router;
        emit SetRouter(_router);
    }

    /// @notice Sets the team fee. Only callable by the admin.
    /// @param _fee The new team fee.
    function setTeamFee(uint256 _fee) external onlyAdmin {
        if (_fee > MAX_TEAM_FEE) revert OptionToken_InvalidTeamFee();
        teamFee = _fee;
        emit SetTeamFee(_fee);
    }

    /// @notice Sets the discount amount. Only callable by the admin.
    /// @param _discount The new discount amount.
    function setDiscount(uint256 _discount) external onlyAdmin {
        if (_discount > MAX_DISCOUNT || _discount == MIN_DISCOUNT)
            revert OptionToken_InvalidDiscount();
        discount = _discount;
        emit SetDiscount(_discount);
    }

    /// @notice Sets the discount amount for locking. Only callable by the admin.
    /// @param _veDiscount The new discount amount.
    function setVeDiscount(uint256 _veDiscount) external onlyAdmin {
        if (_veDiscount > MAX_DISCOUNT || _veDiscount == MIN_DISCOUNT)
            revert OptionToken_InvalidDiscount();
        veDiscount = _veDiscount;
        emit SetVeDiscount(_veDiscount);
    }

    /// @notice Sets the discount amount for lp. Only callable by the admin.
    /// @param _lpMinDiscount The new discount amount.
    function setMinLPDiscount(uint256 _lpMinDiscount) external onlyAdmin {
        if (_lpMinDiscount > MAX_DISCOUNT || _lpMinDiscount == MIN_DISCOUNT || maxLPDiscount > _lpMinDiscount)
            revert OptionToken_InvalidDiscount();
        minLPDiscount = _lpMinDiscount;
        emit SetMinLPDiscount(_lpMinDiscount);
    }

    /// @notice Sets the discount amount for lp. Only callable by the admin.
    /// @param _lpMaxDiscount The new discount amount.
    function setMaxLPDiscount(uint256 _lpMaxDiscount) external onlyAdmin {
        if (_lpMaxDiscount > MAX_DISCOUNT || _lpMaxDiscount == MIN_DISCOUNT || _lpMaxDiscount > minLPDiscount)
            revert OptionToken_InvalidDiscount();
        maxLPDiscount = _lpMaxDiscount;
        emit SetMaxLPDiscount(_lpMaxDiscount);
    }

    /// @notice Sets the lock duration for max discount amount to create LP and stake in gauge. Only callable by the admin.
    /// @param _duration The new lock duration.
    function setLockDurationForMaxLpDiscount(
        uint256 _duration
    ) external onlyAdmin {
        if (_duration <= lockDurationForMinLpDiscount)
            revert OptionToken_InvalidLockDuration();
        lockDurationForMaxLpDiscount = _duration;
        emit SetLockDurationForMaxLpDiscount(_duration);
    }

    // @notice Sets the lock duration for min discount amount to create LP and stake in gauge. Only callable by the admin.
    /// @param _duration The new lock duration.
    function setLockDurationForMinLpDiscount(
        uint256 _duration
    ) external onlyAdmin {
        if (_duration > lockDurationForMaxLpDiscount)
            revert OptionToken_InvalidLockDuration();
        lockDurationForMinLpDiscount = _duration;
        emit SetLockDurationForMinLpDiscount(_duration);
    }

    /// @notice Sets the twap points. to control the length of our twap
    /// @param _twapPoints The new twap points.
    function setTwapPoints(uint256 _twapPoints) external onlyAdmin {
        if (_twapPoints > MAX_TWAP_POINTS || _twapPoints == 0)
            revert OptionToken_InvalidTwapPoints();
        twapPoints = _twapPoints;
        emit SetTwapPoints(_twapPoints);
    }

    /// @notice Called by the admin to mint options tokens. Admin must grant token approval.
    /// @param _to The address that will receive the minted options tokens
    /// @param _amount The amount of options tokens that will be minted
    function mint(address _to, uint256 _amount) external onlyMinter {
        // transfer underlying tokens from the caller
        _safeTransferFrom(underlyingToken, msg.sender, address(this), _amount);
        // mint options tokens
        _mint(_to, _amount);
    }

    /// @notice Called by the admin to burn options tokens and transfer underlying tokens to the caller.
    /// @param _amount The amount of options tokens that will be burned and underlying tokens transferred to the caller
    function burn(uint256 _amount) external onlyAdmin {
        // transfer underlying tokens to the caller
        _safeTransfer(underlyingToken, msg.sender, _amount);
        // burn option tokens
        _burn(msg.sender, _amount);
    }

    /// @notice called by the admin to re-enable option exercising from a paused state.
    function unPause() external onlyAdmin {
        if (!isPaused) return;
        isPaused = false;
        emit PauseStateChanged(false);
    }

    /// -----------------------------------------------------------------------
    /// Pauser functions
    /// -----------------------------------------------------------------------
    function pause() external onlyPauser {
        if (isPaused) return;
        isPaused = true;
        emit PauseStateChanged(true);
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    function _exercise(
        uint256 _amount,
        uint256 _maxPaymentAmount,
        address _recipient
    ) internal returns (uint256 paymentAmount) {
        if (isPaused) revert OptionToken_Paused();

        // burn callers tokens
        _burn(msg.sender, _amount);
        paymentAmount = getDiscountedPrice(_amount);
        if (paymentAmount > _maxPaymentAmount)
            revert OptionToken_SlippageTooHigh();

        // transfer team fee to treasury and notify reward amount in gauge
        uint256 gaugeRewardAmount = _takeTeamFee(paymentToken, paymentAmount);
        _usePaymentAsGaugeReward(gaugeRewardAmount);

        // send underlying tokens to recipient
        _safeTransfer(underlyingToken, _recipient, _amount);

        emit Exercise(msg.sender, _recipient, _amount, paymentAmount);
    }

    function _exerciseVe(
        uint256 _amount,
        uint256 _maxPaymentAmount,
        address _recipient
    ) internal returns (uint256 paymentAmount, uint256 nftId) {
        if (isPaused) revert OptionToken_Paused();

        // burn callers tokens
        _burn(msg.sender, _amount);
        paymentAmount = getVeDiscountedPrice(_amount);
        if (paymentAmount > _maxPaymentAmount)
            revert OptionToken_SlippageTooHigh();

        // transfer team fee to treasury and notify reward amount in gauge
        uint256 gaugeRewardAmount = _takeTeamFee(paymentToken, paymentAmount);
        _usePaymentAsGaugeReward(gaugeRewardAmount);

        // lock underlying tokens to veFLOW
        _safeApprove(underlyingToken, votingEscrow, _amount);
        nftId = IVotingEscrow(votingEscrow).create_lock_for(
            _amount,
            FULL_LOCK,
            _recipient
        );

        emit ExerciseVe(msg.sender, _recipient, _amount, paymentAmount, nftId);
    }

    function _exerciseLp(
        uint256 _amount,   // the oTOKEN amount the user wants to redeem with
        uint256 _maxPaymentAmount, // the 
        address _recipient,
        uint256 _discount
    ) internal returns (uint256 paymentAmount, uint256 lpAmount) {
        if (isPaused) revert OptionToken_Paused();
        if (_discount > minLPDiscount || _discount < maxLPDiscount)
            revert OptionToken_InvalidDiscount();

        // burn callers tokens
        _burn(msg.sender, _amount);
        (uint256 paymentAmount,uint256 paymentAmountToAddLiquidity) =  getPaymentTokenAmountForExerciseLp(_amount,_discount);
        if (paymentAmount > _maxPaymentAmount)
            revert OptionToken_SlippageTooHigh();
          
        // Take team fee
        uint256 paymentGaugeRewardAmount = _takeTeamFee(
            paymentToken,
            paymentAmount
        );
        _safeTransferFrom(
            paymentToken,
            msg.sender,
            address(this),
            paymentGaugeRewardAmount + paymentAmountToAddLiquidity
        );

        // Create Lp for users
        _safeApprove(underlyingToken, router, _amount);
        _safeApprove(paymentToken, router, paymentAmountToAddLiquidity);
        (, , lpAmount) = IRouter(router).addLiquidity(
            underlyingToken,
            paymentToken,
            false,
            _amount,
            paymentAmountToAddLiquidity,
            1,
            1,
            address(this),
            block.timestamp
        );

        // Stake the LP in the gauge with lock
        address _gauge = gauge;
        _safeApprove(address(pair), _gauge, lpAmount);
        IGaugeV2(_gauge).depositWithLock(
            _recipient,
            lpAmount,
            getLockDurationForLpDiscount(_discount)
        );

        // notify gauge reward with payment token
        _transferRewardToGauge();

        emit ExerciseLp(
            msg.sender,
            _recipient,
            _amount,
            paymentAmount,
            lpAmount
        );
    }

    function _takeTeamFee(
        address token,
        uint256 paymentAmount
    ) internal returns (uint256 remaining) {
        uint256 _teamFee = (paymentAmount * teamFee) / 100;
        _safeTransferFrom(token, msg.sender, treasury, _teamFee);
        remaining = paymentAmount - _teamFee;
    }

    function _usePaymentAsGaugeReward(uint256 amount) internal {
        _safeTransferFrom(paymentToken, msg.sender, address(this), amount);
        _transferRewardToGauge();
    }

    function _transferRewardToGauge() internal {
        uint256 paymentTokenCollectedAmount = IERC20(paymentToken).balanceOf(address(this));

        uint256 leftRewards = IGaugeV2(gauge).left(paymentToken);

        if(paymentTokenCollectedAmount > leftRewards) { // we are sending rewards only if we have more then the current rewards in the gauge
            _safeApprove(paymentToken, gauge, paymentTokenCollectedAmount);
            IGaugeV2(gauge).notifyRewardAmount(paymentToken, paymentTokenCollectedAmount);
        }
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeApprove(
        address token,
        address spender,
        uint256 value
    ) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, spender, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}