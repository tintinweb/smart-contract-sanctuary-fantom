/**
 *Submitted for verification at FtmScan.com on 2023-03-22
*/

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/math/Math.sol


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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/access/IAccessControl.sol


// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/access/AccessControl.sol


// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;





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
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
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
 * accounts that have been granted it.
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

// File: @chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol


pragma solidity ^0.8.4;

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
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
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

// File: @chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol


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

// File: IHub.sol



pragma solidity ^0.8.0;

/**
 * @title IHub
 * @dev Interface for the BlueBlur Hub Contracts. 
 * @author BlueBlur
 */
interface IHub {

    /**
     * @dev Allows an authorized party to withdraw funds from the contract.
     * @param _to The address of the recipient of the funds.
     * @param _amount The amount of funds to be withdrawn.
     */
    function withdraw(address _to, uint256 _amount) external;

    /**
     * @dev Allows the contract to receive funds.
     */
    function receiveFunds() external payable;
}
// File: IIDGenerator.sol



pragma solidity ^0.8.0;

/**
 * @title IIDGenerator interface
 * @dev Interface for the IDGenerator contract that generates unique IDs
 * @author BlueBlur
 */
interface IIDGenerator {
    /**
     * @dev Generates and returns a unique ID
     * @param _initiatorLocalId The local ID of the initiator
     * @return The generated ID
     */
    function generateID(uint256 _initiatorLocalId) external returns(uint256);

    /**
     * @dev Decrements the ID counter by one
     */
    function decrementID() external;

    
    /**
     * @dev Resets the ID counter to zero
     */
    function resetID() external;
}
// File: IDistributionNode.sol



pragma solidity ^0.8.0;

interface IDistributionNode {
    function distribute(address _to, uint256 _amount) external;
    function getDistributedAmountFor(address _for) view external returns(uint256);
}
// File: LotteryEnums.sol



pragma solidity ^0.8.0;

/**
 * @title LotteryEnums Library
 * @dev A library that contains enums for lottery status and types.
 * @author BlueBlur
 */
library LotteryEnums {

    /**
     * @dev Enum that defines the status of a lottery contract.
     * INITIALIZED: The lottery contract has been initialized.
     * STOPPED: The lottery contract has been stopped.
     * COMPLETE: The lottery contract has been completed.
     * AWARDING: The lottery contract is awarding prizes to winners.
     * FULFILLED: The lottery contract has been fulfilled.
     */
    enum LotteryStatus {
        INITIALIZED,
        STOPPED,
        COMPLETE,
        AWARDING,
        FULFILLED
    }

    /**
     * @dev Enum that defines the types of lotteries.
     * COMMON: A common lottery where a fixed number of winners are selected.
     * PERCENTAGE: A lottery where winners are selected based on a percentage of participants.
     * TICKET_PERC: A lottery where winners are selected based on a percentage of total tickets.
     */
    enum LotteryType {
        COMMON,
        PERCENTAGE,
        TICKET_PERC
    }
}
// File: ILotteryStructV2.sol



pragma solidity ^0.8.0;


/**
 * @title ILotteryStructV2
 * @notice This interface defines the data structure of the Lottery contract
 * @author BlueBlur   
 */
interface ILotteryStructV2 {

    /**
    * @dev Structure containing the lottery parameters
    * @param uniqueId Unique ID for all lottery contract
    * @param lotteryId ID for lottery within this contract
    * @param currentTicketId ID for a ticket within the lottery
    * @param currentLot Current lottery lot
    * @param lotteryStartAt Lottery start time
    * @param lotteryDuration Lottery duration time
    * @param lotteryEntryPrice Amount of native currency to participate in lottery
    * @param maxParticipantsCount Maximum participants count in lottery
    * @param winnersCount !NUMBER or PERCENT! of winners in current lottery 
    * @param lotteryWinnerAward Amount of native currency to send to the each ticket
    * @param randomRange Range var to selects a number between two values
    * @param isRewardable Enable/disable participates rewarding
    * @param lotteryStatus Status of the lottery
    * @param lotteryType Type of the lottery                 
    * @param participants Array of participant's addresses
    * @param winners Array of winner's addresses
    * @param claimers Array of claimer's addresses
    * @param returners Array of entry returners 
    * @param randoms Array with random words
    * @param tickets Array with tickets
    * @param winningTickets Array with winning tickets
    */
    struct Lottery {
        uint256 uniqueId;
        uint256 lotteryId;
        uint256 currentTicketId;
        uint256 currentLot;
        uint256 lotteryStartAt;
        uint256 lotteryDuration;
        uint256 lotteryEntryPrice;
        uint256 maxParticipantsCount;
        uint256 winnersCount;
        uint256 lotteryWinnerAward;
        uint256 randomRange;
        bool isRewardable;
        LotteryEnums.LotteryStatus lotteryStatus;
        LotteryEnums.LotteryType lotteryType;
        address[] participants;
        address[] winners;
        address[] claimers;
        address[] returners;
        uint256[] randoms;
        uint256[] tickets;
        uint256[] winningTickets;
    }
}
// File: ILotteryV2.sol



pragma solidity ^0.8.0;



/**
 * @title ILotteryV2
 * @notice Interface for a lottery contract that allows users to participate, finish, determine winners, claim rewards,
 * and return entries.
 * @dev This interface inherits from ILotteryStructV2 interface, which defines the Lottery struct used in the contract.
 * @author BlueBlur
 */
interface ILotteryV2 is ILotteryStructV2 {
    /**
     * @dev Adds a new lottery with the given parameters.
     * @param _lotteryDuration The duration of the lottery in seconds.
     * @param _lotteryEntryPrice The price of a ticket for the lottery.
     * @param _lotteryStartAt The start time of the lottery.
     * @param _maxParticipantsCount The maximum number of participants allowed in the lottery (0 for unlimited).
     * @param _winnersCount The number of winners to be selected from the lottery.
     * @param _isRewardable Whether or not the lottery is rewardable.
     */
    function addLottery(
        uint256 _lotteryDuration, 
        uint256 _lotteryEntryPrice, 
        uint256 _lotteryStartAt,
        uint256 _maxParticipantsCount,
        uint256 _winnersCount,
        bool _isRewardable) external;

    /**
     * @dev Allows a user to participate in the current lottery by purchasing one or more tickets.
     * @notice This function is marked as payable, meaning it can receive Ether payments.
     */
    function participate() external payable;

    /**
     * @dev Finish the current lottery. Only the Lottery Manager can call this function.
     */ 
    function finish() external;

    /**
    * @dev Determines the winners of the current lottery.
    */
    function determineWinners() external;

    /**
    * @dev Fills the winners of the current lottery. Only callable by the Lottery Manager role.
    */
    function fillWinners() external;

    /**
    * @dev Allows a user to claim their reward for a specific lottery.
    * @param _lotteryId The ID of the lottery for which the user is claiming the reward.
    */
    function claimReward(uint256 _lotteryId) external;
    
    /**
    * @notice Allows a participant to return their entry
    * @param _lotteryId The ID of the lottery from which the participant wants to return their entry
    */
    function returnEntry(uint256 _lotteryId) external;

    /**
     * @notice Retrieves the details of the latest lottery.
     * @return A Lottery object containing the details of the latest lottery.
     */
    function getLastLottery() external view returns(Lottery memory);
    
    /** 
     * @notice Retrieves the lottery with the given ID.
     * @param _lotteryId The ID of the lottery to retrieve.
     * @return A Lottery object containing the details of the requested lottery.
     */
    function getLotteryById(uint256 _lotteryId) external view returns(Lottery memory);
    
    /**
     * @notice Returns the total winners count and the total number of tokens awarded in all lotteries.
     * @return A tuple containing two uint256 values: the total number of winners and the total number of tokens awarded.
     */
    function getLotteriesTotalInfo() external view returns(uint256, uint256);
    
    /**
     * @notice Retrieves the number of times the given account has participated in the lottery.
     * @param _account The address of the account to check.
     * @return The number of times the account has participated in the lottery.
     */
    function getAddressParticipateCount(address _account) external view returns(uint256);

    /**
     * @notice Returns an array of tickets owned by the specified address in a particular lottery.
     * @param _lotteryId The ID of the lottery to get tickets from.
     * @param _account The address to get the tickets for.
     * @return An array of uint256 representing the IDs of tickets owned by the specified address.
     */
    function getAddressLotteryTickets(uint256 _lotteryId, address _account) external view returns(uint256[] memory);

    /**
     * @notice Returns the total amount of tokens that will be awarded to the specified address in a particular lottery.
     * @param _lotteryId The ID of the lottery to get the award amount from.
     * @param _account The address to get the award amount for.
     * @return An uint256 representing the total amount of tokens that will be awarded to the specified address.
     */
    function getAddressLotteryAwardAmount(uint256 _lotteryId, address _account) external view returns(uint256);

    /**
     * @notice Gets the number of positive tickets held by a given account for a given lottery
     * @param _lotteryId The ID of the lottery to check
     * @param _account The account to check for
     * @return The number of positive tickets held by the account for the given lottery
     **/
    function getLotteryWinnerPositiveTicketsAmount(uint256 _lotteryId, address _account) external view returns(uint256);
}
// File: PercentageTicketLottery.sol



pragma solidity ^0.8.0;










/**
    @title Percentage Ticket Lottery Contract
    @dev A contract that allows users to buy tickets for a lottery and participate in a draw.
    @author BlueBlur.
*/
contract PercentageTicketLottery is ILotteryV2, AccessControl, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;
    Counters.Counter private currentLotteryId;

    IHub public comissionsHub;
    bytes32 public constant LOTTERY_MANAGER = keccak256("LOTTERY_MANAGER");
    uint256 public constant comissionPercent = 5;
    uint256 public participantsReward;
    uint256 public totalWinnersCount;
    uint256 public totalAwardedTokens;
    IDistributionNode lotteryPlayersRewardDistributionNode;

    bytes32 internal keyHash; // identifies which chainlink oracle to use
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    uint32 private constant callbackGasLimit = 2500000;
    uint32 private constant RANDOM_NUMBERS_COUNT = 2; 
    uint16 private constant requestConfirmations = 3;

    mapping(uint256 => Lottery) private lotteries;
    mapping(uint256 => mapping(address => bool)) private isAddressParticipateInLottery;   // map to check if address participate in lottery by id
    mapping(address => uint256) private addressParticipateCount;
    mapping(uint256 => mapping(address => bool)) private isAddressWonInLottery; //  map to check if address won in a lottery by id. It's a technical variable, please, don't use it as an information source.
    mapping(uint256 => mapping(address => bool)) private isAddressReturnEntry; //  map to check if address return an entry if lottery is stopped

    mapping(uint256 => mapping(address => uint256[])) private lotteryOwnerTickets;
    mapping(uint256 => mapping(uint256 => address)) private lotteryTicketOwner;
    mapping(uint256 => mapping(address => uint256)) private lotteryWinnerPositiveTicketsAmount;

    IIDGenerator public idGenerator;

    event LotteryAdded(
        uint256 indexed lotteryId,
        uint256 lotteryStartAt,
        uint256 lotteryEntryPrice
    );

    event LotteryFulfilled(
        uint256 indexed lotteryId
    );

    event LotteryCompleted(
        uint256 indexed lotteryId
    );

    /**
     * @dev Initializes immutable params and params for chainlink vrf.
     * @param _idGenerator Address of the IDGenerator contract.
     * @param _comissionsHub Address of the hub contract that manages commissions.
     * @param _vrfCoordinator Address of the Chainlink VRF coordinator contract.
     * @param subscriptionId The subscription ID of the VRF request.
     * @param _keyHash The key hash used to identify which Chainlink oracle to use.
     * @param _owner The address that will have the admin and manager roles.
     */
    constructor(address _idGenerator,
                address _comissionsHub,
                address _vrfCoordinator,
                uint64 subscriptionId,
                bytes32 _keyHash,
                address _owner) VRFConsumerBaseV2(_vrfCoordinator) {
        require(_idGenerator != address(0) && _comissionsHub != address(0) && _vrfCoordinator != address(0) && subscriptionId > 0 && _owner != address(0), "incorrect params");
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(LOTTERY_MANAGER, _owner);
        idGenerator = IIDGenerator(_idGenerator);
        comissionsHub = IHub(_comissionsHub);
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        s_subscriptionId = subscriptionId;
    }

    /**
     * @dev This function is called when the contract receives ether.
     * It updates the current lottery's prize pool with the received amount.
     *
     * Requirements:
     * - The current lottery must be active.
     *
     */
    receive() external payable {
        Lottery storage lottery = lotteries[currentLotteryId.current()];
        require(block.timestamp < lottery.lotteryStartAt + lottery.lotteryDuration, "lottery is not active");
        lottery.currentLot += msg.value;
    }
    
    /**
     * @dev Adds a new lottery with the given parameters.
     * @param _lotteryDuration The duration of the lottery in seconds.
     * @param _lotteryEntryPrice The price of a ticket for the lottery.
     * @param _lotteryStartAt The start time of the lottery.
     * @param _maxParticipantsCount The maximum number of participants allowed in the lottery (0 for unlimited).
     * @param _winnersCount The number of winners to be selected from the lottery.
     * @param _isRewardable Whether or not the lottery is rewardable.
     *  
     * Requirements:
     * - `_lotteryEntryPrice` must be greater than 0.
     * - `_lotteryStartAt` must be greater than the current block timestamp.
     * - `_lotteryDuration` must be greater than 0.
     * - `_winnersCount` must be greater than 0 and less than 100.
     * - If `_maxParticipantsCount` is greater than 0, it must be greater than or equal to 100 divided by `_winnersCount`.
     * 
     * Emits a {LotteryAdded} event.
     */
    function addLottery(
                uint256 _lotteryDuration, 
                uint256 _lotteryEntryPrice, 
                uint256 _lotteryStartAt, 
                uint256 _maxParticipantsCount,
                uint256 _winnersCount,
                bool _isRewardable) external override virtual onlyRole(LOTTERY_MANAGER) {
        require(_lotteryEntryPrice > 0 && _lotteryStartAt > block.timestamp 
                    && _lotteryDuration > 0 && _winnersCount > 0 && _winnersCount < 100,
                    "incorrect param(s)");
        if (_maxParticipantsCount > 0) {
            require(_maxParticipantsCount >= (100 / _winnersCount), "incorrect max participants count");
        }
        if (currentLotteryId.current() > 0){
            Lottery storage prevLottery = lotteries[currentLotteryId.current()];
            if ( prevLottery.lotteryStatus != LotteryEnums.LotteryStatus.STOPPED ){
                require(prevLottery.lotteryStartAt + prevLottery.lotteryDuration < block.timestamp, "previous lottery is active");
                require(prevLottery.winners.length > 0, "previous lottery has not winners");
            }
        }
        currentLotteryId.increment();
        Lottery storage lottery = lotteries[currentLotteryId.current()];
        lottery.uniqueId = idGenerator.generateID(currentLotteryId.current());
        lottery.lotteryId = currentLotteryId.current();
        lottery.lotteryStartAt = _lotteryStartAt;
        lottery.lotteryDuration = _lotteryDuration;
        lottery.lotteryEntryPrice = _lotteryEntryPrice;
        lottery.maxParticipantsCount = _maxParticipantsCount;
        lottery.winnersCount = _winnersCount;
        lottery.isRewardable = _isRewardable;
        lottery.lotteryType = LotteryEnums.LotteryType.TICKET_PERC;

        emit LotteryAdded(currentLotteryId.current(), _lotteryStartAt, _lotteryEntryPrice);
    }

    /**
     * @dev Allows a user to participate in the current lottery by purchasing one or more tickets.
     * Users must send a payment equal to the lottery entry price in order to participate.
     * If the lottery has a maximum number of participants, users cannot participate once this limit has been reached.
     * Participants will receive a number of tickets equal to the number of tickets that can be purchased with their payment.
     * Any excess payment will be refunded to the participant.
     * 
     * @notice This function is marked as payable, meaning it can receive Ether payments.
     * 
     */
    function participate() external override virtual payable {
        Lottery storage lottery = lotteries[currentLotteryId.current()];
        require(msg.value >= lottery.lotteryEntryPrice, "incorrect funds");
        require(block.timestamp >= lottery.lotteryStartAt 
                    && block.timestamp < lottery.lotteryStartAt + lottery.lotteryDuration, "lottery is not active");
        
        uint256 boughtTicketsCount = msg.value / lottery.lotteryEntryPrice;
        if (lottery.maxParticipantsCount > 0){
            require(lottery.currentTicketId + boughtTicketsCount <= lottery.maxParticipantsCount, "Sorry, you can't purchase more tickets for this lottery. Please try buying fewer tickets.");
        }  
        uint256 boughtTicketsCost = boughtTicketsCount * lottery.lotteryEntryPrice;
        uint256 reminder = msg.value - boughtTicketsCost;
        if (reminder > 0){
            payable(msg.sender).transfer(reminder);
        }

        if (!isAddressParticipateInLottery[currentLotteryId.current()][msg.sender]){
            isAddressParticipateInLottery[currentLotteryId.current()][msg.sender] = true;
            lottery.participants.push(msg.sender);
        }

        for (uint256 i = 0; i < boughtTicketsCount; i++){
            lotteryOwnerTickets[currentLotteryId.current()][msg.sender].push(lottery.currentTicketId);
            lotteryTicketOwner[currentLotteryId.current()][lottery.currentTicketId] = msg.sender;
            lottery.tickets.push(lottery.currentTicketId);
            lottery.currentTicketId += 1;
        }

        lottery.currentLot += boughtTicketsCost;
        addressParticipateCount[msg.sender] += boughtTicketsCount;

        if (lottery.isRewardable 
            && address(lotteryPlayersRewardDistributionNode) != address(0)
            && participantsReward != 0) {
            lotteryPlayersRewardDistributionNode.distribute(msg.sender, participantsReward * boughtTicketsCount);
        }
    }

    /**
     * @dev Finish the current lottery. Only the Lottery Manager can call this function.
     * @notice This function can only be called after the lottery has ended or before it has started.
     * @notice This function will update the lottery's status to STOPPED.
     */ 
    function finish() external override virtual onlyRole(LOTTERY_MANAGER) {
        Lottery storage lottery = lotteries[currentLotteryId.current()];
        require(block.timestamp >= lottery.lotteryStartAt + lottery.lotteryDuration || block.timestamp < lottery.lotteryStartAt, "lottery is active");
        require(lottery.lotteryStatus != LotteryEnums.LotteryStatus.STOPPED && lottery.lotteryStatus != LotteryEnums.LotteryStatus.COMPLETE, "can't stop the finished lottery");
        lottery.lotteryStatus = LotteryEnums.LotteryStatus.STOPPED;
    }

    /**
    * @notice Allows a participant to return their entry
    * @dev The lottery must be stopped and the participant must have previously participated in the lottery and not have already returned their entry
    * @param _lotteryId The ID of the lottery from which the participant wants to return their entry
    */
    function returnEntry(uint256 _lotteryId) external override virtual {
        Lottery storage lottery = lotteries[_lotteryId];
        require(lottery.lotteryStatus == LotteryEnums.LotteryStatus.STOPPED, "incorrect lottery");
        require(isAddressParticipateInLottery[_lotteryId][msg.sender], "you can't return an entry");
        require(isAddressReturnEntry[_lotteryId][msg.sender] == false, "you already returned your entry");
        isAddressReturnEntry[_lotteryId][msg.sender] = true;
        lottery.returners.push(msg.sender);
        payable(msg.sender).transfer(lottery.lotteryEntryPrice * lotteryOwnerTickets[_lotteryId][msg.sender].length);
    }

    /**
    * @dev Determines the winners of the current lottery.
    * Only the lottery manager can call this function.
    * The function requires that the current time is after the end of the lottery,
    * enough tickets have been sold to cover the winners, and the lottery is in an initialized state.
    * The number of winners is determined by the winnersCount parameter when creating the lottery.
    * Calculates the winner award.
    * Sets the lottery status to awarding and calls the getRandomNumbers function.
    */
    function determineWinners() external override virtual onlyRole(LOTTERY_MANAGER) {
        Lottery storage lottery = lotteries[currentLotteryId.current()];
        require(block.timestamp >= lottery.lotteryStartAt + lottery.lotteryDuration, "lottery is active");
        require(lottery.currentTicketId >= (100 / lottery.winnersCount), "not enough tickets sold");
        require(lottery.lotteryStatus == LotteryEnums.LotteryStatus.INITIALIZED, "awarding unreachable");
        uint256 winnersCount = lottery.currentTicketId * lottery.winnersCount / 100;
        lottery.lotteryWinnerAward = (100 - comissionPercent) * lottery.currentLot / 100 / winnersCount;   // calculate winner award considering the fee
        lottery.randomRange = lottery.currentTicketId;
        lottery.lotteryStatus = LotteryEnums.LotteryStatus.AWARDING;
        getRandomNumbers();
    }

    /**
    * @dev Requests a random number from the Chainlink VRF coordinator contract.
    * @return requestId The ID of the VRF request.
    */
    function getRandomNumbers() private returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            RANDOM_NUMBERS_COUNT
        );
        return requestId;
    }

    /**
     * @dev Internal function called by the Chainlink VRF Coordinator when random words are generated.
     * It stores the random words for the current lottery and updates the lottery status to FULFILLED.
     * Emits a LotteryFulfilled event.
     * @param _requestId The ID of the Chainlink VRF request.
     * @param _randomWords An array of random numbers generated by the Chainlink VRF.
     * 
     * Requirements:
     *  - Only callable by the Chainlink VRF Coordinator.
     *  - The lottery status must be in the awarding state.
     *
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(msg.sender == address(COORDINATOR), "callable only for coordinator");
        Lottery storage lottery = lotteries[currentLotteryId.current()];
        require(lottery.lotteryStatus == LotteryEnums.LotteryStatus.AWARDING, "awarding is not started");
        lottery.randoms = _randomWords;
        lottery.lotteryStatus = LotteryEnums.LotteryStatus.FULFILLED;
        emit LotteryFulfilled(currentLotteryId.current());
    }

    /**
    * @dev Fills the winners of the current lottery. Only callable by the Lottery Manager role.
    * @notice This function requires the randomness to be already fulfilled by Chainlink VRF, 
    * and there must be enough tickets sold to determine the winners.
    * The function selects winners based on a random number generated by combining the 
    * Chainlink randomness with the range of available tickets.
    * The number of winners is calculated based on the percentage of winners set in the lottery.
    * The function stores the winning addresses and tickets, 
    * and updates the winning tickets and the amount of positive tickets for each winner.
    * The function also calculates the commission for the lottery owner, 
    * subtracts it from the lottery prize pool, and sends it to the CommissionsHub contract.
    * Finally, the function sets the lottery status to COMPLETE and emits a LotteryCompleted event.
    */
    function fillWinners() external onlyRole(LOTTERY_MANAGER) {
        Lottery storage lottery = lotteries[currentLotteryId.current()];
        require(lottery.lotteryStatus == LotteryEnums.LotteryStatus.FULFILLED, "randomness is not fulfilled");
        uint256 winnersCount = lottery.currentTicketId * lottery.winnersCount / 100;
        for(uint256 i = 0; i < winnersCount; i++){
            uint256 randomness = uint256(keccak256(abi.encodePacked(lottery.randoms[0], lottery.randoms[1], lottery.randomRange)));  // creating randomness based on chainlink random numbers.
            uint256 randomResult = randomness % lottery.randomRange;
            address winnerAddress = lotteryTicketOwner[currentLotteryId.current()][lottery.tickets[randomResult]];
            if(!isAddressWonInLottery[currentLotteryId.current()][winnerAddress]){
                lottery.winners.push(winnerAddress);
                isAddressWonInLottery[currentLotteryId.current()][winnerAddress] = true;
            }
            lottery.winningTickets.push(lottery.tickets[randomResult]);
            lotteryWinnerPositiveTicketsAmount[currentLotteryId.current()][winnerAddress] += 1;
            lottery.tickets[randomResult] = lottery.tickets[lottery.tickets.length - 1];
            lottery.tickets.pop();
            unchecked {
                lottery.randomRange -= 1;
            }
        }
        lottery.lotteryStatus = LotteryEnums.LotteryStatus.COMPLETE;
        totalWinnersCount += lotteries[currentLotteryId.current()].winnersCount;
        uint256 comission = lottery.currentLot - (lottery.lotteryWinnerAward * winnersCount);
        comissionsHub.receiveFunds{value: comission}();
        emit LotteryCompleted(currentLotteryId.current());
    }
 
    /**
    * @dev Allows a user to claim their reward for a specific lottery.
    * @param _lotteryId The ID of the lottery for which the user is claiming the reward.
    * 
    * Requirements:
    *  - The lottery must have ended and be in the "COMPLETE" status.
    *  - The user must have won a prize in the lottery.
    * 
    * Effects:
    *  - Transfers the awarded tokens to the user's address.
    *  - Adds the user to the list of claimers for the lottery.
    *  - Updates the total awarded tokens and sets the user's winning status for the lottery to false.
    *
    */
    function claimReward(uint256 _lotteryId) external override virtual {
        Lottery storage lottery = lotteries[_lotteryId];
        require(lottery.lotteryStatus == LotteryEnums.LotteryStatus.COMPLETE, "incorrect lottery");
        require(isAddressWonInLottery[_lotteryId][msg.sender], "you can't claim the reward");
        isAddressWonInLottery[_lotteryId][msg.sender] = false;
        lottery.claimers.push(msg.sender);
        uint256 awardedTokens = lottery.lotteryWinnerAward * lotteryWinnerPositiveTicketsAmount[_lotteryId][msg.sender];
        totalAwardedTokens += awardedTokens;
        payable(msg.sender).transfer(awardedTokens);
    }

    /** 
     * @notice Retrieves the lottery with the given ID.
     * @param _lotteryId The ID of the lottery to retrieve.
     * @return A Lottery object containing the details of the requested lottery.
     */
    function getLotteryById(uint256 _lotteryId) external view override virtual returns(Lottery memory){
        return lotteries[_lotteryId];
    }

    /**
     * @notice Retrieves the details of the latest lottery.
     * @return A Lottery object containing the details of the latest lottery.
     */
    function getLastLottery() external view override virtual returns (Lottery memory){
        return lotteries[currentLotteryId.current()];
    }

    /**
     * @notice Sets the address of the distribution node for players' rewards.
     * @param _distributionNode The address of the new distribution node.
     * @dev Only the account with the DEFAULT_ADMIN_ROLE can call this function.
     */
    function setPlayersRewardDistributionNode(address _distributionNode) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_distributionNode != address(0), "zero address");
        lotteryPlayersRewardDistributionNode = IDistributionNode(_distributionNode);
    }

    /**
     * @notice Sets the reward amount for lottery participants.
     * @param _participantsReward The new reward amount in wei.
     * @dev Only the account with the LOTTERY_MANAGER role can call this function.
     */
    function setParticipantsReward(uint256 _participantsReward) external onlyRole(LOTTERY_MANAGER) {
        participantsReward = _participantsReward;
    }

    /**
     * @notice Returns the total winners count and the total number of tokens awarded in all lotteries.
     * @return A tuple containing two uint256 values: the total number of winners and the total number of tokens awarded.
     */
    function getLotteriesTotalInfo() external view override virtual returns(uint256, uint256){
        return (totalWinnersCount, totalAwardedTokens);
    }

    /**
     * @notice Retrieves the number of times the given account has participated in the lottery.
     * @param _account The address of the account to check.
     * @return The number of times the account has participated in the lottery.
     */
    function getAddressParticipateCount(address _account) external view override virtual returns(uint256){
        return addressParticipateCount[_account];
    }

    /**
     * @notice Returns an array of tickets owned by the specified address in a particular lottery.
     * @param _lotteryId The ID of the lottery to get tickets from.
     * @param _account The address to get the tickets for.
     * @return An array of uint256 representing the IDs of tickets owned by the specified address.
     */
    function getAddressLotteryTickets(uint256 _lotteryId, address _account) external view override virtual returns(uint256[] memory){
        return lotteryOwnerTickets[_lotteryId][_account];
    }

    /**
     * @notice Returns the total amount of tokens that will be awarded to the specified address in a particular lottery.
     * @param _lotteryId The ID of the lottery to get the award amount from.
     * @param _account The address to get the award amount for.
     * @return An uint256 representing the total amount of tokens that will be awarded to the specified address.
     */
    function getAddressLotteryAwardAmount(uint256 _lotteryId, address _account) external view override virtual returns(uint256){
        return lotteries[_lotteryId].lotteryWinnerAward * lotteryWinnerPositiveTicketsAmount[_lotteryId][_account];
    }

    /**
     * @notice Returns the number of positive tickets that a particular account has won for a given lottery.
     * @param _lotteryId The ID of the lottery to query.
     * @param _account The account for which to retrieve the number of positive tickets.
     * @return The number of positive tickets that the specified account has won for the given lottery.
     */
    function getLotteryWinnerPositiveTicketsAmount(uint256 _lotteryId, address _account) external view override virtual returns(uint256){
        return lotteryWinnerPositiveTicketsAmount[_lotteryId][_account];
    }

    /**
     * @notice Sets the ID generator contract address.
     * @param _idGenerator The address of the ID generator contract.
    */
    function setIDGenerator(address _idGenerator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_idGenerator != address(0), "zero address");
        idGenerator = IIDGenerator(_idGenerator);
    }

    /**
     * @notice Sets the address of the Commissions Hub contract.
     * @param _comissionsHub The address of the Commissions Hub contract.
     */
    function setComissionsHub(address _comissionsHub) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_comissionsHub != address(0), "zero address");
        comissionsHub = IHub(_comissionsHub);
    }

    /**
     * @notice Sets the VRF key hash used for generating random numbers.
     * @param _keyHash The VRF key hash.
     */
    function setVRFKeyHash(bytes32 _keyHash) external onlyRole(DEFAULT_ADMIN_ROLE) {
        keyHash = _keyHash;
    }
    
    /**
     * @notice Sets the VRF subscription ID used for generating random numbers.
     * @param _subsId The VRF subscription ID.
     */
    function setVRFSubscriptionId(uint64 _subsId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        s_subscriptionId = _subsId;
    }

    /**
     * @notice Checks if a contract supports the specified interface.
     * @param interfaceId The ID of the interface to check.
     * @return A boolean indicating whether the contract supports the specified interface.
     */
    function supportsInterface(bytes4 interfaceId) public view override virtual returns(bool){
        return interfaceId == type(ILotteryV2).interfaceId || super.supportsInterface(interfaceId);
    }
}