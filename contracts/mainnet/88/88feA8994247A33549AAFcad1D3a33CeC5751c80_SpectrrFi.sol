/**
 *Submitted for verification at FtmScan.com on 2023-03-06
*/

// Sources flattened with hardhat v2.12.7 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
}


// File @openzeppelin/contracts/utils/math/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/cryptography/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

// EIP-712 is Final as of 2022-08-11. This file is deprecated.


// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File contracts/SpectrrData.sol


pragma solidity >=0.4.22 <0.9.0;

/// @title SpectrrData
/// @author Supergrayfly
/// @notice Defines and initializes the data for the SpectrrCore Contract
contract SpectrrData {
    /// @notice The minimum collateral to debt ratio allowing a liquidation (1.25)
    uint256 public constant MIN_RATIO_LIQUIDATION = 125 * 10 ** 16;

    /// @notice The collateral to debt ratio when the value of the collateral is equal to the value of the debt (1)
    uint256 public constant RATIO_LIQUIDATION_IS_LOSS = 1 * 10 ** 18;

    /// @notice The initial collateral to debt ratio needed to create an offer (1.5)
    uint256 public constant RATIO_COLLATERAL_TO_DEBT = 15 * 10 ** 17;

    uint256 public constant WEI = 10 ** 18;

    /** @dev Number of existing sale offers, initialized as 0 in the beginning,
        and incremented by one at every sale offer creation.
    */
    uint256 public saleOffersCount = 0;

    /** @dev Number of existing buy offers, initialized as 0 in the beginning,
        and incremented by one at every buy offer creation.
    */
    uint256 public buyOffersCount = 0;

    /// @dev Map of offer id (saleOffersCount) and sale offer struct
    mapping(uint256 => SaleOffer) public saleOffers;

    /// @dev Map of offer id (buyOffersCount) and buy offer struct
    mapping(uint256 => BuyOffer) public buyOffers;

    /// @dev Enum set tracking the status of an offer
    enum OfferStatus {
        open,
        accepted,
        closed
    }

    /// @dev Enum set tracking the lock state of an offer
    enum OfferLockState {
        locked,
        unlocked
    }

    /// @dev SaleOffer struct, containing all the data composing a sale offer.
    struct SaleOffer {
        OfferStatus offerStatus;
        OfferLockState offerLockState;
        uint256 offerId;
        uint256 selling;
        uint256 sellingFor;
        uint256 collateral;
        uint256 repayInSeconds;
        uint256 timeAccepted;
        uint8 sellingId;
        uint8 sellingForId;
        uint8 collateralId;
        address seller;
        address buyer;
    }

    /// @dev BuyOffer struct, containing all the data composing a buy offer.
    struct BuyOffer {
        OfferStatus offerStatus;
        OfferLockState offerLockState;
        uint256 offerId;
        uint256 buying;
        uint256 buyingFor;
        uint256 collateral;
        uint256 repayInSeconds;
        uint256 timeAccepted;
        uint8 buyingId;
        uint8 buyingForId;
        uint8 collateralId;
        address buyer;
        address seller;
    }

    /// @notice Event emitted when a sale offer is created
    event SaleOfferCreated(
        uint256 offerId,
        uint256 selling,
        uint8 sellingId,
        uint256 sellingFor,
        uint8 sellingForId,
        uint256 exRate,
        uint256 repayInSeconds,
        address seller,
        uint256 timestamp
    );

    /// @notice Event emitted when a sale offer is accepted
    event SaleOfferAccepted(
        uint256 offerId,
        uint256 collateral,
        uint8 collateralId,
        address buyer,
        uint256 timestamp
    );

    /// @notice Event emitted when collateral is added to a sale offer
    event SaleOfferCollateralAdded(uint256 offerId, uint256 amount);

    /// @notice Event emitted when a sale offer is canceled
    event SaleOfferCanceled(uint256 offerId);

    /// @notice Event emitted when a sale offer is liquidated
    event SaleOfferLiquidated(uint256 offerId, address liquidator);

    /// @notice Event emitted when the seller address of a sale offer changes
    event SaleOfferSellerAddressChanged(uint256 offerId, address newAddress);

    /// @notice Event emitted when the buyer address of a sale offer changes
    event SaleOfferBuyerAddressChanged(uint256 offerId, address newAddress);

    /// @notice Event emitted when a sale offer is repaid
    event SaleOfferRepaid(
        uint256 offerId,
        uint256 amount,
        uint8 amountId,
        bool byPart
    );

    /// @notice Event emitted when a sale offer is forfeited
    event SaleOfferForfeited(uint256 offerId);

    /// @notice Event emitted when a buy offer is created
    event BuyOfferCreated(
        uint256 offerId,
        uint256 buying,
        uint8 buyingId,
        uint256 buyingFor,
        uint8 buyingForId,
        uint256 exRate,
        uint8 collateralId,
        uint256 repayInSeconds,
        address buyer,
        uint256 timestamp
    );

    /// @notice Event emitted when a buy offer is accepted
    event BuyOfferAccepted(uint256 offerId, address seller, uint256 timestamp);

    /// @notice Event emitted when collateral is added to a buy offer
    event BuyOfferCollateralAdded(uint256 offerId, uint256 amount);

    /// @notice Event emitted when a buy offer is canceled
    event BuyOfferCanceled(uint256 offerId);

    /// @notice Event emitted when a buy offer is liquidated
    event BuyOfferLiquidated(uint256 offerId, address liquidator);

    /// @notice Event emitted when the seller address of a buy offer changes
    event BuyOfferSellerAddressChanged(uint256 offerId, address newAddress);

    /// @notice Event emitted when the buyer address of a buy offer changes
    event BuyOfferBuyerAddressChanged(uint256 offerId, address newAddress);

    /// @notice Event emitted when a buy offer is repaid
    event BuyOfferRepaid(
        uint256 offerId,
        uint256 amount,
        uint8 amountId,
        bool byPart
    );

    /// @notice Event emitted when a buy offer is forfeited
    event BuyOfferForfeited(uint256 offerId);

    /** @dev Modifier used to protect from reentrancy.
        Called when a function changing the state of a sale offer struct is entered, it prevents changes by anyone aside from the current msg.sender.
        It differs from the nonReentrant modifier, 
        as the latter only restricts the msg.sender from calling other functions in the contract.
    */
    modifier lockSaleOffer(uint256 _offerId) {
        require(
            saleOffers[_offerId].offerLockState != OfferLockState.locked,
            "Sale Offer Locked"
        );

        saleOffers[_offerId].offerLockState = OfferLockState.locked;
        _;
        saleOffers[_offerId].offerLockState = OfferLockState.unlocked;
    }

    /// @dev Same as modifier above, but for buy offers
    modifier lockBuyOffer(uint256 _offerId) {
        require(
            buyOffers[_offerId].offerLockState != OfferLockState.locked,
            "Buy Offer Locked"
        );

        buyOffers[_offerId].offerLockState = OfferLockState.locked;
        _;
        buyOffers[_offerId].offerLockState = OfferLockState.unlocked;
    }
}


// File contracts/SpectrrManager.sol


pragma solidity >=0.4.22 <0.9.0;

/// @title SpectrrManager
/// @author Supergrayfly
/// @notice This contract handles functions that can only be called by the dev address (e.g.: Adding new tradable tokens).
contract SpectrrManager is Ownable {
    /// @notice address where transaction fees will be sent
    address public feeAddress;

    /** @notice Fee corresponding to 0.1% (100 / 0.1 = 1000),
				taken when an offer is created and accepted.
    */
    uint16 public constant FEE_PERCENT = 1000;

    /// @notice The number of tokens tradable by this contract
    /// @dev Used as a counter for the tokens mapping
    uint8 public tokenCount = 0;

    /// @dev Map of the number of tokens and Token struct
    mapping(uint8 => Token) public tokens;

    /// @dev Token struct, containing info on a ERC20 token
    struct Token {
        string name;
        uint8 id;
        uint8 decimals;
        uint8 chainlinkPriceDecimals;
        address chainlinkOracleAddress;
        address addr;
    }

    /// @notice Event emitted when a new token is added
    event NewTokenAdded(
        uint8 tokenId,
        string tokenName,
        address tokenAddress,
        address chainlinkOracleAddress
    );

    /// @notice Event emitted when the fee address is changed
    event FeeAddressChanged(address newAddress);

    /// @notice Adds a token to the array of tokens tradable by this contract
    /// @dev Only callable by owner
    /// @param _tokenName Name of the token to add in the format: "wbtc"
    /// @param _tokenAddress Address of the token
    /// @param _chainlinkOracleAddress Address of the chainlink contract used to take the price from
    /// @param _chainlinkOracleDecimals Number of decimals the chainlink price has
    /// @param _decimals Number of decimals the token contract has
    function addToken(
        string memory _tokenName,
        address _tokenAddress,
        address _chainlinkOracleAddress,
        uint8 _chainlinkOracleDecimals,
        uint8 _decimals
    ) external onlyOwner {
        uint8 id = ++tokenCount;

        Token memory token = Token(
            _tokenName,
            id,
            _decimals,
            _chainlinkOracleDecimals,
            _chainlinkOracleAddress,
            _tokenAddress
        );

        tokens[id] = token;

        emit NewTokenAdded(
            id,
            _tokenName,
            _tokenAddress,
            _chainlinkOracleAddress
        );
    }

    /// @notice Changes the address of the chainlink oracle of a token
    /// @dev Only callable by the current owner
    /// @param _tokenId id of the token we want to change the oracle address
    /// @param _newChainlinkOracleAddress address of the new chainlink oracle
    function changeChainlinkOracleAddress(
        uint8 _tokenId,
        address _newChainlinkOracleAddress
    ) external onlyOwner {
        require(_tokenId > 0 && _tokenId <= tokenCount, "Invalid Id");
        require(_newChainlinkOracleAddress != address(0), "Address is Zero");

        tokens[_tokenId].chainlinkOracleAddress = _newChainlinkOracleAddress;
    }

    /// @notice Changes the fee address
    /// @dev Only callable by the current owner
    /// @param _newFeeAddress The new fee address
    function changeFeeAddress(address _newFeeAddress) external onlyOwner {
        feeAddress = _newFeeAddress;
        emit FeeAddressChanged(_newFeeAddress);
    }
}


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}


// File contracts/SpectrrPrices.sol


pragma solidity >=0.4.22 <0.9.0;

/// @title SpectrrPrices
/// @author Supergrayfly
/// @notice Fetches the prices of various currency pairs from Chainlink price feed oracles
contract SpectrrPrices {
    function getChainlinkPrice(
        address _chainlinkOracleAddress
    ) public view returns (int256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            _chainlinkOracleAddress
        );

        (, int256 tokenPrice, , , ) = priceFeed.latestRoundData();

        require(tokenPrice > 0, "Negative price");

        return tokenPrice;
    }
}


// File contracts/SpectrrUtils.sol


pragma solidity >=0.4.22 <0.9.0;




/// @title SpectrrUtils
/// @author Supergrayfly
/// @notice This contract handles 'secondary' functions, such as transferring tokens and calculating collateral tokens.
contract SpectrrUtils is SpectrrPrices, SpectrrData, SpectrrManager {
    /// @notice Gets the current block timestamp
    /// @return uint256 The current block timestamp
    function getBlockTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    /// @notice Gets the interface of a token based on its id
    /// @param _tokenId Id of the ERC20 token we want the interface
    /// @return IERC20 The ERC20 Interface of the token
    function getITokenFromId(uint8 _tokenId) public view returns (IERC20) {
        checkTokenIdInRange(_tokenId);
        return IERC20(tokens[_tokenId].addr);
    }

    /// @notice Gets the number of decimals of an ERC20 token
    /// @param _tokenId Id of the ERC20 token
    /// @return uint8 The number of decimals
    function getTokenDecimalsFromId(
        uint8 _tokenId
    ) public view returns (uint8) {
        checkTokenIdInRange(_tokenId);
        return tokens[_tokenId].decimals;
    }

    /// @notice Converts an amount to wei, based on the decimals the amount has
    /// @param _amount The amount to convert
    /// @param _amountTokenId Id of the amount we want to convert
    /// @return uint256 The converted amount in wei
    function amountToWei(
        uint256 _amount,
        uint8 _amountTokenId
    ) public view returns (uint256) {
        return _amount * 10 ** (18 - getTokenDecimalsFromId(_amountTokenId));
    }

    /// @notice Converts an amount from wei, based on the decimals the amount has
    /// @param _amount The amount to convert
    /// @param _amountTokenId Id of the amount we want to convert
    /// @return uint256 The converted amount
    function amountFromWei(
        uint256 _amount,
        uint8 _amountTokenId
    ) public view returns (uint256) {
        return _amount / 10 ** (18 - getTokenDecimalsFromId(_amountTokenId));
    }

    /// @notice Gets the price of a token from Chainlink
    /// @param _tokenId Id of the token we want the price
    /// @return uint256 The price of the token
    function tokenIdToPrice(uint8 _tokenId) public view returns (uint256) {
        checkTokenIdInRange(_tokenId);
        return
            uint256(
                getChainlinkPrice(tokens[_tokenId].chainlinkOracleAddress)
            ) * 10 ** (18 - tokens[_tokenId].chainlinkPriceDecimals);
    }

    /// @notice Calculates the liquidation price of the collateral token
    /// @return liquidationPrice Price of the collateral token at which a liquidation will be possible
    function getLiquidationPriceCollateral(
        uint256 _collateralTokenAmountWei,
        uint256 _amountForTokenWei,
        uint8 _amountForTokenId,
        uint256 _liquidationLimit
    ) public view returns (uint256) {
        checkTokenIdInRange(_amountForTokenId);
        return
            (_liquidationLimit *
                _amountForTokenWei *
                tokenIdToPrice(_amountForTokenId)) /
            (_collateralTokenAmountWei * WEI);
    }

    /// @notice Calculates the liquidation price of the debt token
    /// @return liquidationPrice Price of the debt token at which a liquidation will be possible
    function getLiquidationPriceAmountFor(
        uint256 _collateralTokenAmountWei,
        uint256 _amountForTokenWei,
        uint8 _collateralTokenId,
        uint256 _liquidationLimit
    ) public view returns (uint256) {
        checkTokenIdInRange(_collateralTokenId);
        return
            (_collateralTokenAmountWei *
                tokenIdToPrice(_collateralTokenId) *
                WEI) / (_liquidationLimit * _amountForTokenWei);
    }

    /// @notice Transfers tokens from the sender to this contract
    /// @dev Only callable internally by this contract
    function transferSenderToContract(
        address _sender,
        uint256 _amountToken,
        uint8 _amountTokenId
    ) internal {
        getITokenFromId(_amountTokenId).transferFrom(
            _sender,
            address(this),
            _amountToken
        );
    }

    /// @notice Transfers tokens from this contract to the sender of the tx
    /// @dev Only callable internally by this contract
    function transferContractToSender(
        address _sender,
        uint256 _amountToken,
        uint8 _amountTokenId
    ) internal {
        getITokenFromId(_amountTokenId).transfer(
            _sender,
            amountFromWei(_amountToken, _amountTokenId)
        );
    }

    /// @notice Handles the transfer of the collateral, fee, and amount bought
    /// @dev Only callable internally by this contract
    /// @param _sender Address sending the tokens
    /// @param _collateralTokenAmount Collateral amount to transfer from the sender
    /// @param _collateralTokenId Id of the collateral token
    /// @param _amountToken Amount bought by the sender
    /// @param _amountTokenId Id of the bought token
    function transferAcceptSale(
        address _sender,
        uint256 _collateralTokenAmount,
        uint8 _collateralTokenId,
        uint256 _amountToken,
        uint8 _amountTokenId
    ) internal {
        uint256 collateralTokenAmountFromWei = amountFromWei(
            _collateralTokenAmount,
            _collateralTokenId
        );

        getITokenFromId(_collateralTokenId).transferFrom(
            _sender,
            address(this),
            collateralTokenAmountFromWei
        );
        transferFee(collateralTokenAmountFromWei, _collateralTokenId, _sender);
        transferContractToSender(
            _sender,
            amountFromWei(_amountToken, _amountTokenId),
            _amountTokenId
        );
    }

    /// @notice Transfers token from the buyer to the seller of an offer
    /// @dev Only callable internally by this contract
    /// @param _sender Address sending the tokens
    /// @param _receiver Address receiving the tokens
    /// @param _amountToken Amount to send
    /// @param _amountTokenId Id of the amount to send
    function transferBuyerToSeller(
        address _sender,
        address _receiver,
        uint256 _amountToken,
        uint8 _amountTokenId
    ) internal {
        getITokenFromId(_amountTokenId).transferFrom(
            _sender,
            _receiver,
            _amountToken
        );
    }

    /// @notice Calculates the collateral needed to create a buy offer or accept a sale offer
    /// @param _amountTokenWei Amount on which the collateral will be calculated
    /// @param _amountTokenId Id of the amount
    /// @param _collateralTokenId Id of the collateral
    /// @param _collateralTokenAmountWeiToDebtRatio Collateral to debt ratio, used to calculate the collateral amount.
    /// @return collateral Computed collateral amount
    function getCollateral(
        uint256 _amountTokenWei,
        uint8 _amountTokenId,
        uint8 _collateralTokenId,
        uint256 _collateralTokenAmountWeiToDebtRatio
    ) public view returns (uint256) {
        return
            (((_amountTokenWei * tokenIdToPrice(_amountTokenId)) /
                tokenIdToPrice(_collateralTokenId)) *
                _collateralTokenAmountWeiToDebtRatio) / WEI;
    }

    /// @notice Calculates the ratio of the collateral over the debt
    /// @param _amountTokenWei Amount of debt
    /// @param _collateralTokenAmountWei Collateral amount
    /// @param _amountTokenId Id of the debt amount
    /// @param _collateralTokenId Id of the collateral
    /// @return ratio Calculated ratio
    function getRatio(
        uint256 _amountTokenWei,
        uint256 _collateralTokenAmountWei,
        uint8 _amountTokenId,
        uint8 _collateralTokenId
    ) public view returns (uint256) {
        if (_amountTokenWei == 0 || _collateralTokenAmountWei == 0) {
            return 0;
        } else {
            return
                (_collateralTokenAmountWei *
                    tokenIdToPrice(_collateralTokenId) *
                    WEI) / (_amountTokenWei * tokenIdToPrice(_amountTokenId));
        }
    }

    /// @notice Determines if the collateral to debt ratio has reached the liquidation limit
    /// @param _amountTokenWei Amount of debt
    /// @param _amountTokenId Id of the debt amount
    /// @param _collateralTokenAmountWei Collateral amount
    /// @param _collateralTokenId Id of the collateral
    /// @param _liquidationLimitRatio Ratio at which liquidation will be possible
    /// @return bool If the offer can be liquidated or not
    function canLiquidate(
        uint256 _amountTokenWei,
        uint8 _amountTokenId,
        uint256 _collateralTokenAmountWei,
        uint8 _collateralTokenId,
        uint256 _liquidationLimitRatio
    ) public view returns (bool) {
        if (
            getRatio(
                _amountTokenWei,
                _collateralTokenAmountWei,
                _amountTokenId,
                _collateralTokenId
            ) <=
            _liquidationLimitRatio &&
            _amountTokenWei > 0 &&
            _collateralTokenAmountWei > 0
        ) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice Determines if the repayment period has passed
    /// @param _timeAccepted Time at which the offer was accepted
    /// @param _repayInSeconds Repayment period of the offer
    /// @return bool If the offer can be liquidated or not
    function canLiquidateTimeOver(
        uint256 _timeAccepted,
        uint256 _repayInSeconds
    ) public view returns (bool) {
        if (_repayInSeconds == 0 || _timeAccepted == 0) {
            return false;
        } else {
            if (block.timestamp > (_timeAccepted + _repayInSeconds)) {
                return true;
            } else {
                return false;
            }
        }
    }

    /// @notice Liquidates an offer by repaying the debt, and then receiving a collateral amount equal to the debt amount.
    /** @dev Only callable internally by this contract.
        When the debt to collateral ratio is above 1, the value of the collateral equal to the debt is sent to the liquidator, and the rest is sent back to the buyer.
        Otherwise, the whole collateral amount is sent to the liquidator.    
    */
    /// @param _amountTokenWei Amount of debt
    /// @param _amountTokenId Id of the debt amount
    /// @param _collateralTokenAmountWei Amount of collateral
    /// @param _collateralTokenId Id of the collateral
    /// @param _seller Address of the offer's seller
    /// @param _buyer Address of the offer's buyer
    /// @param _sender Address of the liquidator
    /// @param _liquidationLossRatio Ratio at which a liquidation will incur a loss (i.e., the collateral value is below the debt)
    function liquidateTokens(
        uint256 _amountTokenWei,
        uint8 _amountTokenId,
        uint256 _collateralTokenAmountWei,
        uint8 _collateralTokenId,
        address _seller,
        address _buyer,
        address _sender,
        uint256 _liquidationLossRatio
    ) internal {
        IERC20 collateralToken = getITokenFromId(_collateralTokenId);

        if (
            getRatio(
                _amountTokenWei,
                _collateralTokenAmountWei,
                _amountTokenId,
                _collateralTokenId
            ) >= _liquidationLossRatio
        ) {
            uint256 toTransfer = _collateralTokenAmountWei -
                (_collateralTokenAmountWei -
                    ((_amountTokenWei * tokenIdToPrice(_amountTokenId)) /
                        tokenIdToPrice(_collateralTokenId)));

            getITokenFromId(_amountTokenId).transferFrom(
                _sender,
                _seller,
                amountFromWei(_amountTokenWei, _amountTokenId)
            );
            collateralToken.transfer(
                _sender,
                amountFromWei(toTransfer, _collateralTokenId)
            );
            collateralToken.transfer(
                _buyer,
                amountFromWei(
                    (_collateralTokenAmountWei -
                        ((_amountTokenWei * tokenIdToPrice(_amountTokenId)) /
                            tokenIdToPrice(_collateralTokenId))),
                    _amountTokenId
                )
            );
        } else {
            getITokenFromId(_amountTokenId).transferFrom(
                _sender,
                _seller,
                amountFromWei(_amountTokenWei, _amountTokenId)
            );
            collateralToken.transfer(
                _sender,
                amountFromWei(_collateralTokenAmountWei, _collateralTokenId)
            );
        }
    }

    /// @notice Liquidates an offer when the liquidator is the seller
    /** @dev Only callable internally by this contract.
        When the debt to collateral ratio is above 1, the value of the collateral equal to the debt is sent to the seller, and the rest is sent back to the buyer.
        Otherwise, the whole collateral amount is sent to the seller.    
    */
    /// @param _amountTokenWei Amount of debt
    /// @param _amountTokenId Id of the debt amount
    /// @param _collateralTokenAmountWei Amount of collateral
    /// @param _collateralTokenId Id of the collateral
    /// @param _buyer Address of the buyer
    /// @param _seller Address of the seller
    /// @param _liquidationLossRatio Collateral to debt ratio at which a liquidation will incur a loss (i.e., when the collateral value is below the debt value)
    function liquidateTokensBySeller(
        uint256 _amountTokenWei,
        uint8 _amountTokenId,
        uint256 _collateralTokenAmountWei,
        uint8 _collateralTokenId,
        address _buyer,
        address _seller,
        uint256 _liquidationLossRatio
    ) internal {
        IERC20 collateralToken = getITokenFromId(_collateralTokenId);

        uint256 ratio = getRatio(
            _amountTokenWei,
            _collateralTokenAmountWei,
            _amountTokenId,
            _collateralTokenId
        );

        if (ratio > _liquidationLossRatio) {
            uint256 toTransfer = _collateralTokenAmountWei -
                (_collateralTokenAmountWei -
                    (_amountTokenWei * tokenIdToPrice(_amountTokenId)) /
                    tokenIdToPrice(_collateralTokenId));

            collateralToken.transfer(
                _seller,
                amountFromWei(toTransfer, _collateralTokenId)
            );
            collateralToken.transfer(
                _buyer,
                amountFromWei(
                    _collateralTokenAmountWei -
                        ((_amountTokenWei * tokenIdToPrice(_amountTokenId)) /
                            tokenIdToPrice(_collateralTokenId)),
                    _collateralTokenId
                )
            );
        } else if (ratio <= _liquidationLossRatio) {
            collateralToken.transfer(
                _seller,
                amountFromWei(_collateralTokenAmountWei, _collateralTokenId)
            );
        } else {
            revert("Can not be liquidated...yet");
        }
    }

    /// @notice Liquidates an offer when the liquidator is the buyer
    /// @dev Only callable internally by this contract, reverts if it incurs a loss to the seller.
    /// @param _amountTokenWei Amount of debt
    /// @param _amountTokenId Id of the debt amount
    /// @param _collateralTokenAmountWei Amount of collateral
    /// @param _collateralTokenId Id of the collateral
    /// @param _buyer Address of the buyer
    /// @param _seller Address of the seller
    /// @param _liquidationLossRatio Collateral to debt ratio at which a liquidation will incur a loss (i.e., when the collateral value is below the debt value)
    function liquidateTokensByBuyer(
        uint256 _amountTokenWei,
        uint8 _amountTokenId,
        uint256 _collateralTokenAmountWei,
        uint8 _collateralTokenId,
        address _buyer,
        address _seller,
        uint256 _liquidationLossRatio
    ) internal {
        IERC20 collateralToken = getITokenFromId(_collateralTokenId);

        uint256 ratio = getRatio(
            _amountTokenWei,
            _collateralTokenAmountWei,
            _amountTokenId,
            _collateralTokenId
        );

        if (ratio > _liquidationLossRatio) {
            uint256 toTransfer = _collateralTokenAmountWei -
                (_collateralTokenAmountWei -
                    (_amountTokenWei * tokenIdToPrice(_amountTokenId)) /
                    tokenIdToPrice(_collateralTokenId));

            collateralToken.transfer(
                _seller,
                amountFromWei(toTransfer, _collateralTokenId)
            );
            collateralToken.transfer(
                _buyer,
                amountFromWei(
                    _collateralTokenAmountWei -
                        ((_amountTokenWei * tokenIdToPrice(_amountTokenId)) /
                            tokenIdToPrice(_collateralTokenId)),
                    _collateralTokenId
                )
            );
        } else if (ratio == _liquidationLossRatio) {
            collateralToken.transfer(
                msg.sender,
                amountFromWei(_collateralTokenAmountWei, _collateralTokenId)
            );
        } else {
            revert("Liquidation loss to seller");
        }
    }

    /// @notice Repays a debt, and transfers back the collateral.
    /// @dev Only callable internally by this contract
    /// @param _amountToRepay Amount to repay
    /// @param _amountToRepayId Id of the amount to repay
    /// @param _collateralTokenAmountWei Amount of collateral
    /// @param _collateralTokenId Id of the collateral
    /// @param _seller Address of the seller
    /// @param _buyer Address of the buyer
    function repay(
        uint256 _amountToRepay,
        uint8 _amountToRepayId,
        uint256 _collateralTokenAmountWei,
        uint8 _collateralTokenId,
        address _seller,
        address _buyer
    ) internal {
        getITokenFromId(_amountToRepayId).transferFrom(
            _buyer,
            _seller,
            amountFromWei(_amountToRepay, _amountToRepayId)
        );
        getITokenFromId(_collateralTokenId).transfer(
            _buyer,
            amountFromWei(_collateralTokenAmountWei, _collateralTokenId)
        );
    }

    /// @notice Transfers the fee from the sender to the fee address
    /// @dev Only callable internally by this contract
    /// @param _amountToken Amount of which 0.1% will be taken
    /// @param _amountTokenId Id of the amount
    /// @param _sender Address of the sender
    function transferFee(
        uint256 _amountToken,
        uint8 _amountTokenId,
        address _sender
    ) internal {
        getITokenFromId(_amountTokenId).transferFrom(
            _sender,
            feeAddress,
            (_amountToken / FEE_PERCENT)
        );
    }

    /// @notice Checks if token Id is a tradable token
    /// @param _id Id of the token
    function checkTokenIdInRange(uint8 _id) internal view {
        require(_id > 0 && _id <= tokenCount, "Invalid Id");
    }

    /// @notice Checks if address is zero address
    /// @param _address Address to check
    function checkAddressNotZero(address _address) internal pure {
        require(_address != address(0), "Address is Zero");
    }

    /// @notice Checks if address matches with sender of transaction, reverts if true
    /// @param _address Address to compare with msg.sender
    function checkAddressNotSender(address _address) internal view {
        require(_address != msg.sender, "Unvalid Sender");
    }

    /// @notice Checks if address matches with sender of transaction, reverts if false
    /// @param _address Address to compare with msg.snder
    function checkAddressSender(address _address) internal view {
        require(_address == msg.sender, "Unvalid Sender");
    }

    /// @notice Checks if amount is positive, reverts if false
    /// @param _amountTokenWei Amount to check
    function checkIsPositive(uint256 _amountTokenWei) internal pure {
        require(_amountTokenWei > 0, "Amount is negative");
    }

    /// @notice Checks if id of two tokens are the same, reverts if true
    /// @param _id Id of first token
    /// @param id_ id of second token
    function checkTokensIdNotSame(uint8 _id, uint8 id_) internal pure {
        require(_id != id_, "Cannot be same token Id");
    }

    /// @notice Checks if offer is open (i.e. not accepted or closed), reverts if false
    /// @param _offerStatus Current state of the offer
    function checkOfferIsOpen(OfferStatus _offerStatus) internal pure {
        require(_offerStatus != OfferStatus.accepted, "Offer is accepted");
        require(_offerStatus != OfferStatus.closed, "Offer is closed");
    }

    /// @notice Checks if offer is accepted (i.e. not open or closed), reverts if false
    /// @param _offerStatus Current state of the offer
    function checkOfferIsAccepted(OfferStatus _offerStatus) internal pure {
        require(_offerStatus != OfferStatus.closed, "Offer is closed");
        require(_offerStatus != OfferStatus.open, "Offer is open");
    }

    /// @notice Checks if offer is closed (i.e. not open or closed), reverts if false
    /// @param _offerStatus Current state of the offer
    function checkOfferIsClosed(OfferStatus _offerStatus) internal pure {
        require(_offerStatus != OfferStatus.accepted, "Offer is accepted");
        require(_offerStatus != OfferStatus.open, "Offer is open");
    }

    /// @notice Checks if offer is closed (i.e. not open or closed), reverts if false
    /// @param _offerStatus Current state of the offer
    function checkOfferIsNotClosed(OfferStatus _offerStatus) internal pure {
        require(_offerStatus != OfferStatus.closed, "Offer is closed");
    }

    /// @notice Checks if amount sent is bigger than debt, reverts if true
    /// @param _amountTokenWei The amount to send
    /// @param _debt The debt owed
    function checkIsLessThan(
        uint256 _amountTokenWei,
        uint256 _debt
    ) internal pure {
        require(_amountTokenWei < _debt, "Amount greater than debt");
    }
}


// File contracts/SpectrrFi.sol


pragma solidity >=0.4.22 <0.9.0;



/// @title SpectrrFi
/// @author Supergrayfly
/** @notice This contract is a lending and borrowing like platform;
    'like', because it is not interest based like other existing lending dApps.
    Users can post offers specifying a token they want to sell/buy,
    a collateral token (for buy offers), and a repayment period.
    This contract does not allow selling/buying a token for the same token. 
    Also, the collateral token chosen in a buy offer can not be the same than the repayment token.
    For example, one could make the following buy offer:
        Buy 1 BTC for 69,000$ (assuming a current BTC price of 68,500$), pledge 1.5 times the repayment amount in collateral (here, 1.5 BTC), 
        and specify a repayment period of 69 days. After that, let us say that that someone accepts the offer by sending 1 BTC to the buyer.
        Assuming that the price of BTC reaches 70,000$ when the debt is repaid,
        the buyer would then make a profit of 70,000$ - 69,000$ = 1000$, after selling the 1 BTC bought earlier.
        On the other hand, the seller will receive 69,000$, and would have made a profit of 69,000$ - 68,500$ = 500$.
        It can be noted that in our case, the seller would have made more profit just holding the BTC.
*/
/** @custom:extra This contract was voluntarily made this way in order for it to align with the principles of Islamic finance.
    In the latter, some prohibitions include dealing with interest, 
    activities related to prohibited things (e.g.: gambling & stealing), 
    and selling an asset for the same exact asset plus an extra amount (interest).

    Some Useful links:
    https://www.investopedia.com/articles/07/islamic_investing.asp
    https://www.gfmag.com/topics/blogs/what-products-does-islamic-finance-offer  
*/
contract SpectrrFi is SpectrrUtils, EIP712, ReentrancyGuard {
    /// @param _feeAddress Adress where fees will be sent
    /// @dev EIP712 Constructor
    /// @dev EIP712's params are the name and version of the contract
    constructor(address _feeAddress) EIP712("Spectrr Finance", "ver. 0.0.2") {
        feeAddress = _feeAddress;
    }

    /// @notice Creates and posts a sale offer
    /// @notice There is a 0.1% fee of the selling amount, paid by the seller to the fee address.
    /// @param _sellingTokenAmount Amount the sender is selling
    /// @param _sellingTokenId Id of the selling token, can not be same than id of sell for token.
    /// @param _exchangeRate Exchange rate between the selling amount sell for amount
    /// @param _sellingForTokenId Id of the token exchanged for, can not be same than id of the selling token.
    /// @param _repayInSeconds Repayment period in unix seconds, a value of 0 will allow an unlimited repayment time .
    /// @return uint256 Id of the offer created
    function createSaleOffer(
        uint256 _sellingTokenAmount,
        uint8 _sellingTokenId,
        uint256 _exchangeRate,
        uint8 _sellingForTokenId,
        uint256 _repayInSeconds
    ) external nonReentrant returns (uint256) {
        checkIsPositive(_sellingTokenAmount);
        checkIsPositive(_exchangeRate);
        checkTokensIdNotSame(_sellingForTokenId, _sellingTokenId);

        transferSenderToContract(
            msg.sender,
            _sellingTokenAmount,
            _sellingTokenId
        );

        transferFee(_sellingTokenAmount, _sellingTokenId, msg.sender);

        uint256 offerId = ++saleOffersCount;
        uint256 sellingTokenAmountWei = amountToWei(
            _sellingTokenAmount,
            getTokenDecimalsFromId(_sellingTokenId)
        );
        uint256 exchangeRateWei = amountToWei(
            _exchangeRate,
            getTokenDecimalsFromId(_sellingForTokenId)
        );
        uint256 sellingForTokenAmountWei = (exchangeRateWei *
            sellingTokenAmountWei) / WEI;

        SaleOffer memory offer = SaleOffer(
            OfferStatus.open,
            OfferLockState.unlocked,
            offerId,
            sellingTokenAmountWei,
            sellingForTokenAmountWei,
            0,
            _repayInSeconds,
            0,
            _sellingTokenId,
            _sellingForTokenId,
            0,
            msg.sender,
            address(0)
        );

        saleOffers[offerId] = offer;

        emit SaleOfferCreated(
            offerId,
            sellingTokenAmountWei,
            _sellingTokenId,
            sellingForTokenAmountWei,
            _sellingForTokenId,
            exchangeRateWei,
            _repayInSeconds,
            msg.sender,
            block.timestamp
        );

        return offerId;
    }

    /// @notice Accepts a sale offer by transferring the required collateral from the buyer to the contract
    /// @notice There is a 0.1% fee of the collateral amount, paid by the buyer to the fee address.
    /// @param _offerId Id of the sale offer to accept
    /** @param _collateralTokenId Id of the token to be pledged as collateral,
        cannot be same than id of selling token.
    */
    function acceptSaleOffer(
        uint256 _offerId,
        uint8 _collateralTokenId
    ) external nonReentrant lockSaleOffer(_offerId) {
        SaleOffer storage offer = saleOffers[_offerId];

        checkOfferIsOpen(offer.offerStatus);
        checkAddressNotSender(offer.seller);
        checkTokensIdNotSame(_collateralTokenId, offer.sellingId);

        uint256 collateralTokenAmount = getCollateral(
            offer.sellingFor,
            offer.sellingForId,
            _collateralTokenId,
            RATIO_COLLATERAL_TO_DEBT
        );

        transferAcceptSale(
            msg.sender,
            collateralTokenAmount,
            _collateralTokenId,
            offer.selling,
            offer.sellingId
        );

        offer.timeAccepted = block.timestamp;
        offer.offerStatus = OfferStatus.accepted;
        offer.collateral = collateralTokenAmount;
        offer.collateralId = _collateralTokenId;
        offer.buyer = msg.sender;

        emit SaleOfferAccepted(
            _offerId,
            amountToWei(collateralTokenAmount, _collateralTokenId),
            _collateralTokenId,
            msg.sender,
            block.timestamp
        );
    }

    /// @notice Cancels a sale offer, given that it is not accepted yet
    /// @param _offerId Id of the sale offer to cancel
    function cancelSaleOffer(
        uint256 _offerId
    ) external nonReentrant lockSaleOffer(_offerId) {
        SaleOffer storage offer = saleOffers[_offerId];

        checkOfferIsOpen(offer.offerStatus);
        checkAddressSender(offer.seller);

        transferContractToSender(msg.sender, offer.selling, offer.sellingId);

        offer.offerStatus = OfferStatus.closed;

        emit SaleOfferCanceled(_offerId);
    }

    /// @notice Adds collateral to a sale offer
    /// @dev Can only be called by the buyer of the sale offer
    /// @param _offerId Id of the sale offer to add collateral to
    /// @param _amountToAdd Amount of collateral to add
    function addCollateralSaleOffer(
        uint256 _offerId,
        uint256 _amountToAdd
    ) external nonReentrant lockSaleOffer(_offerId) {
        SaleOffer storage offer = saleOffers[_offerId];

        checkIsPositive(_amountToAdd);
        checkOfferIsAccepted(offer.offerStatus);
        checkAddressSender(offer.buyer);

        transferSenderToContract(msg.sender, _amountToAdd, offer.collateralId);

        offer.collateral += amountToWei(_amountToAdd, offer.collateralId);

        emit SaleOfferCollateralAdded(_offerId, _amountToAdd);
    }

    /// @notice Fully repays the debt of a sale offer
    /// @param _offerId Id of the sale offer to repay
    function repaySaleOffer(
        uint256 _offerId
    ) external nonReentrant lockSaleOffer(_offerId) {
        SaleOffer storage offer = saleOffers[_offerId];

        checkOfferIsAccepted(offer.offerStatus);
        checkAddressSender(offer.buyer);

        repay(
            offer.sellingFor,
            offer.sellingForId,
            offer.collateral,
            offer.collateralId,
            offer.seller,
            offer.buyer
        );

        offer.offerStatus = OfferStatus.closed;

        emit SaleOfferRepaid(
            _offerId,
            offer.sellingFor,
            offer.sellingForId,
            false
        );
    }

    /// @notice Partially repays the debt of a sale offer
    /// @param _offerId Id of the sale offer to partially repay
    /// @param _amountToRepay Amount to partially repay
    function repaySaleOfferPart(
        uint256 _offerId,
        uint256 _amountToRepay
    ) external nonReentrant lockSaleOffer(_offerId) {
        SaleOffer storage offer = saleOffers[_offerId];
        uint256 amountToRepayWei = amountToWei(
            _amountToRepay,
            offer.sellingForId
        );

        checkIsPositive(amountToRepayWei);
        checkIsLessThan(amountToRepayWei, offer.sellingFor);
        checkOfferIsAccepted(offer.offerStatus);
        checkAddressSender(offer.buyer);

        transferBuyerToSeller(
            msg.sender,
            offer.seller,
            _amountToRepay,
            offer.sellingForId
        );

        offer.sellingFor -= amountToRepayWei;

        emit SaleOfferRepaid(
            _offerId,
            amountToRepayWei,
            offer.sellingForId,
            true
        );
    }

    /// @notice Liquidates a sale offer by repaying the debt, and then receiving the pledged collateral.
    /// @notice An offer can be liquidated if and only if the collateral to debt ratio falls below the MIN_RATIO_LIQUIDATION value previously defined (1.8).
    /** @custom:warning Liquidating an offer may incur losses.
        For instance, say that the $ value of the collateral drops below the $ value of the debt,
        if the liquidator proceeds with the liquidation, he/she will have lost a negative amount of: collateral (in $) - debt (in $).
        It is therefore recommended to verify beforehand if the transaction is profitable or not. 
        This can be done using the isLiquidationLoss function, or any other external method.
    */
    /// @param _offerId Id of the sale offer to liquidate
    function liquidateSaleOffer(
        uint256 _offerId
    ) external nonReentrant lockSaleOffer(_offerId) {
        SaleOffer storage offer = saleOffers[_offerId];

        checkOfferIsAccepted(offer.offerStatus);

        require(
            canLiquidate(
                offer.sellingFor,
                offer.sellingForId,
                offer.collateral,
                offer.collateralId,
                MIN_RATIO_LIQUIDATION
            ) || canLiquidateTimeOver(offer.timeAccepted, offer.repayInSeconds),
            "Can not be liquidated...yet"
        );

        if (msg.sender == offer.seller) {
            liquidateTokensBySeller(
                offer.sellingFor,
                offer.sellingForId,
                offer.collateral,
                offer.collateralId,
                offer.buyer,
                offer.seller,
                RATIO_LIQUIDATION_IS_LOSS
            );
        } else {
            liquidateTokens(
                offer.sellingFor,
                offer.sellingForId,
                offer.collateral,
                offer.collateralId,
                offer.seller,
                offer.buyer,
                msg.sender,
                RATIO_LIQUIDATION_IS_LOSS
            );
        }

        offer.offerStatus = OfferStatus.closed;

        emit SaleOfferLiquidated(_offerId, msg.sender);
    }

    /// @notice Forfeits a sale offer
    /// @dev Only callable by the buyer
    /// @dev Transaction is reverted if it incurs a loss to the seller
    /// @param _offerId Id of the sale offer to forfeit
    function forfeitSaleOffer(
        uint256 _offerId
    ) external nonReentrant lockSaleOffer(_offerId) {
        SaleOffer storage offer = saleOffers[_offerId];

        checkOfferIsAccepted(offer.offerStatus);
        checkAddressSender(offer.buyer);

        liquidateTokensByBuyer(
            offer.sellingFor,
            offer.sellingForId,
            offer.collateral,
            offer.collateralId,
            offer.buyer,
            offer.seller,
            RATIO_LIQUIDATION_IS_LOSS
        );

        offer.offerStatus = OfferStatus.closed;

        emit SaleOfferForfeited(_offerId);
    }

    /// @notice Creates and posts a buy offer
    /// @notice There is a 0.1% fee of the buying amount, paid by the buyer to the fee address.
    /// @param _buyingTokenAmount Amount to buy
    /// @param _buyingTokenId Id of the buying token
    /// @param _exchangeRate Exchange rate between buying amount and buy for amount
    /** @param _buyingForTokenId Id of the repayment token,
        can not be same than id of token buying.
    */
    /** @param _collateralTokenId Id of the collateral token,
        cannot be same than id of buying token.
    */
    /** @param _repayInSeconds Repayment timeframe in unix seconds,
        a value of 0 will allow an unlimited repayment time .
    */
    function createBuyOffer(
        uint256 _buyingTokenAmount,
        uint8 _buyingTokenId,
        uint256 _exchangeRate,
        uint8 _buyingForTokenId,
        uint8 _collateralTokenId,
        uint256 _repayInSeconds
    ) external nonReentrant returns (uint256) {
        checkIsPositive(_buyingTokenAmount);
        checkIsPositive(_exchangeRate);
        checkTokensIdNotSame(_buyingTokenId, _buyingForTokenId);
        checkTokensIdNotSame(_collateralTokenId, _buyingTokenId);

        uint256 exchangeRateWei = amountToWei(_exchangeRate, _buyingForTokenId);
        uint256 buyingTokenAmountWei = amountToWei(
            _buyingTokenAmount,
            _buyingForTokenId
        );
        uint256 buyingForTokenAmountWei = (exchangeRateWei *
            buyingTokenAmountWei) / WEI;
        uint256 collateralTokenAmountWei = getCollateral(
            buyingForTokenAmountWei,
            _buyingForTokenId,
            _collateralTokenId,
            RATIO_COLLATERAL_TO_DEBT
        );

        transferSenderToContract(
            msg.sender,
            amountFromWei(collateralTokenAmountWei, _collateralTokenId),
            _collateralTokenId
        );

        transferFee(
            amountFromWei(collateralTokenAmountWei, _collateralTokenId),
            _collateralTokenId,
            msg.sender
        );

        uint256 offerId = ++buyOffersCount;

        BuyOffer memory offer = BuyOffer(
            OfferStatus.open,
            OfferLockState.unlocked,
            offerId,
            buyingTokenAmountWei,
            buyingForTokenAmountWei,
            collateralTokenAmountWei,
            _repayInSeconds,
            0,
            _buyingTokenId,
            _buyingForTokenId,
            _collateralTokenId,
            msg.sender,
            address(0)
        );

        buyOffers[offerId] = offer;

        emit BuyOfferCreated(
            offerId,
            buyingTokenAmountWei,
            _buyingTokenId,
            buyingForTokenAmountWei,
            _buyingForTokenId,
            exchangeRateWei,
            _collateralTokenId,
            _repayInSeconds,
            msg.sender,
            block.timestamp
        );

        return offerId;
    }

    /// @notice Accepts a buy offer by transferring the amount buying from the seller to the buyer
    /// @notice There is a 0.1% fee of the buying amount, paid by the seller.
    /// @param _offerId Id of the buy offer to accept
    function acceptBuyOffer(
        uint256 _offerId
    ) external nonReentrant lockBuyOffer(_offerId) {
        BuyOffer storage offer = buyOffers[_offerId];
        uint256 buyingAmountFromWei = amountFromWei(
            offer.buying,
            offer.buyingId
        );

        checkOfferIsOpen(offer.offerStatus);
        checkAddressNotSender(offer.buyer);

        transferBuyerToSeller(
            msg.sender,
            offer.buyer,
            buyingAmountFromWei,
            offer.buyingId
        );

        transferFee(buyingAmountFromWei, offer.buyingId, msg.sender);

        offer.timeAccepted = block.timestamp;
        offer.offerStatus = OfferStatus.accepted;
        offer.seller = msg.sender;

        emit BuyOfferAccepted(_offerId, msg.sender, block.timestamp);
    }

    /// @notice Cancels a buy offer, given that it not accepted yet
    /// @param _offerId Id of the buy offer to cancel
    function cancelBuyOffer(
        uint256 _offerId
    ) external nonReentrant lockBuyOffer(_offerId) {
        BuyOffer storage offer = buyOffers[_offerId];

        checkOfferIsOpen(offer.offerStatus);
        checkAddressSender(offer.buyer);

        transferContractToSender(
            msg.sender,
            offer.collateral,
            offer.collateralId
        );

        offer.offerStatus = OfferStatus.closed;

        emit BuyOfferCanceled(_offerId);
    }

    /// @notice Adds collateral to a buy offer
    /// @dev Can only be called by the buyer of the buy offer
    /// @param _offerId Id of the buy offer to add collateral to
    /// @param _amountToAdd The amount of collateral to add
    function addCollateralBuyOffer(
        uint256 _offerId,
        uint256 _amountToAdd
    ) external nonReentrant lockBuyOffer(_offerId) {
        BuyOffer storage offer = buyOffers[_offerId];

        checkIsPositive(_amountToAdd);
        checkOfferIsAccepted(offer.offerStatus);
        checkAddressSender(offer.buyer);

        transferSenderToContract(msg.sender, _amountToAdd, offer.collateralId);

        offer.collateral += amountToWei(_amountToAdd, offer.collateralId);

        emit BuyOfferCollateralAdded(_offerId, _amountToAdd);
    }

    /// @notice Fully repays the debt of the buy offer
    /// @param _offerId Id of the buy offer to repay
    function repayBuyOffer(
        uint256 _offerId
    ) external nonReentrant lockBuyOffer(_offerId) {
        BuyOffer storage offer = buyOffers[_offerId];

        checkOfferIsAccepted(offer.offerStatus);
        checkAddressSender(offer.buyer);

        repay(
            offer.buyingFor,
            offer.buyingForId,
            offer.collateral,
            offer.collateralId,
            offer.seller,
            offer.buyer
        );

        offer.offerStatus = OfferStatus.closed;

        emit BuyOfferRepaid(
            _offerId,
            offer.buyingFor,
            offer.buyingForId,
            false
        );
    }

    /// @notice Partially repays the debt of a buy offer
    /// @param _offerId Id of the buy offer to partially repay
    /// @param _amountToRepay Amount to partially repay
    function repayBuyOfferPart(
        uint256 _offerId,
        uint256 _amountToRepay
    ) external nonReentrant lockBuyOffer(_offerId) {
        BuyOffer storage offer = buyOffers[_offerId];
        uint256 amountToRepayWei = amountToWei(_amountToRepay, offer.buyingId);

        checkIsPositive(_amountToRepay);
        checkIsLessThan(amountToRepayWei, offer.buyingFor);
        checkOfferIsAccepted(offer.offerStatus);
        checkAddressSender(offer.buyer);

        transferBuyerToSeller(
            msg.sender,
            offer.seller,
            _amountToRepay,
            offer.buyingForId
        );

        offer.buyingFor -= amountToRepayWei;

        emit BuyOfferRepaid(
            _offerId,
            amountToRepayWei,
            offer.buyingForId,
            true
        );
    }

    /// @notice Liquidates a buy offer, by repaying the debt, and then receiving the pledged collateral.
    /// @notice An offer can be liquidated if and only if the collateral to debt ratio falls below the MIN_RATIO_LIQUIDATION value previously defined.
    /** @custom:warning Liquidating an offer may incur losses.
        For instance, say that the $ value of the collateral drops below the $ value of the debt,
        if the liquidator proceeds with the liquidation, he/she will have lost a negative amount of collateral (in $) - debt (in $).
        It is therefore recommended to verify beforehand if the transaction is profitable or not. 
        This can be done using the isLiquidationLoss function, or any other external method.
    */
    /// @param _offerId Id of the buy offer to liquidate
    function liquidateBuyOffer(
        uint256 _offerId
    ) external nonReentrant lockBuyOffer(_offerId) {
        BuyOffer storage offer = buyOffers[_offerId];

        checkOfferIsAccepted(offer.offerStatus);

        require(
            canLiquidate(
                offer.buyingFor,
                offer.buyingForId,
                offer.collateral,
                offer.collateralId,
                MIN_RATIO_LIQUIDATION
            ) || canLiquidateTimeOver(offer.timeAccepted, offer.repayInSeconds),
            "Can not be liquidated...yet"
        );

        if (msg.sender == offer.seller) {
            liquidateTokensBySeller(
                offer.buyingFor,
                offer.buyingForId,
                offer.collateral,
                offer.collateralId,
                offer.buyer,
                offer.seller,
                RATIO_LIQUIDATION_IS_LOSS
            );
        } else {
            liquidateTokens(
                offer.buyingFor,
                offer.buyingForId,
                offer.collateral,
                offer.collateralId,
                offer.seller,
                offer.buyer,
                msg.sender,
                RATIO_LIQUIDATION_IS_LOSS
            );
        }

        offer.offerStatus = OfferStatus.closed;

        emit BuyOfferLiquidated(_offerId, msg.sender);
    }

    /// @notice Forfeits a buy offer
    /// @dev Only callable by the buyer
    /// @dev Transaction is reverted if it incurs a loss to the seller
    /// @param _offerId Id of the buy offer to forfeit
    function forfeitBuyOffer(
        uint256 _offerId
    ) external nonReentrant lockBuyOffer(_offerId) {
        BuyOffer storage offer = buyOffers[_offerId];

        checkOfferIsAccepted(offer.offerStatus);
        checkAddressNotSender(offer.buyer);

        if (
            !canLiquidate(
                offer.buyingFor,
                offer.buyingForId,
                offer.collateral,
                offer.collateralId,
                MIN_RATIO_LIQUIDATION
            )
        ) {
            liquidateTokensByBuyer(
                offer.buyingFor,
                offer.buyingForId,
                offer.collateral,
                offer.collateralId,
                offer.buyer,
                offer.seller,
                RATIO_LIQUIDATION_IS_LOSS
            );
        } else {
            revert("Sender can be liquidated");
        }

        offer.offerStatus = OfferStatus.closed;

        emit BuyOfferForfeited(_offerId);
    }

    /// @notice Changes the seller or buyer's address of an offer
    /** @dev It should be noted that a contract address could be entered in the _newAddr field.
        However, doing so would not affect the contract's mechanism in a bad way.
        The only consequence would be that the msg.sender will relinquish control of the funds placed in the contract.
    */
    /// @param _offerId Id of the offer we want to change addresses
    /// @param _newAddress New address to replace the old one with
    /// @param _addressType Type of address: 0 for seller address, and 1 for buyer address.
    function changeAddressSale(
        uint256 _offerId,
        address _newAddress,
        uint8 _addressType
    ) external nonReentrant lockSaleOffer(_offerId) {
        checkOfferIsNotClosed(saleOffers[_offerId].offerStatus);

        if (_addressType == 0) {
            require(
                saleOffers[_offerId].seller == msg.sender,
                "Sender is not seller"
            );
            require(
                saleOffers[_offerId].buyer != _newAddress,
                "Address is buyer"
            );
            require(
                saleOffers[_offerId].seller != _newAddress,
                "Address is seller"
            );
            checkAddressNotZero(_newAddress);

            saleOffers[_offerId].seller = _newAddress;

            emit SaleOfferSellerAddressChanged(_offerId, _newAddress);
        } else if (_addressType == 1) {
            require(
                saleOffers[_offerId].buyer == msg.sender,
                "Sender is not buyer"
            );
            require(
                saleOffers[_offerId].seller != _newAddress,
                "Address is seller"
            );
            require(
                saleOffers[_offerId].buyer != _newAddress,
                "Address is buyer"
            );
            checkAddressNotZero(_newAddress);

            saleOffers[_offerId].buyer = _newAddress;

            emit SaleOfferBuyerAddressChanged(_offerId, _newAddress);
        } else {
            revert("Invalid Address Type");
        }
    }

    /// @notice Changes the seller or buyer's address of an offer
    /** @dev It should be noted that a contract address could be entered in the _newAddr field.
        However, doing so would not affect the contract's mechanism in a bad way.
        The only consequence would be that the msg.sender will relinquish control
        of the funds placed in the contract to the other contract address.
    */
    /// @param _offerId Id of the offer we want to change addresses
    /// @param _newAddress New address to replace the old one with
    /// @param _addressType Type of address: 0 for seller address, and 1 for buyer address.
    function changeAddressBuy(
        uint256 _offerId,
        address _newAddress,
        uint8 _addressType
    ) external nonReentrant lockSaleOffer(_offerId) {
        checkOfferIsNotClosed(buyOffers[_offerId].offerStatus);

        if (_addressType == 0) {
            require(
                buyOffers[_offerId].seller == msg.sender,
                "Sender is not seller"
            );
            require(
                buyOffers[_offerId].buyer != _newAddress,
                "Address is buyer"
            );
            require(
                buyOffers[_offerId].seller != _newAddress,
                "Address is seller"
            );
            checkAddressNotZero(_newAddress);

            buyOffers[_offerId].seller = _newAddress;

            emit BuyOfferSellerAddressChanged(_offerId, _newAddress);
        } else if (_addressType == 1) {
            require(
                buyOffers[_offerId].buyer == msg.sender,
                "Sender is not buyer"
            );
            require(
                buyOffers[_offerId].seller != _newAddress,
                "Address is seller"
            );
            require(
                buyOffers[_offerId].buyer != _newAddress,
                "Address is buyer"
            );
            checkAddressNotZero(_newAddress);

            buyOffers[_offerId].buyer = _newAddress;

            emit BuyOfferBuyerAddressChanged(_offerId, _newAddress);
        } else {
            revert("Invalid Address Type");
        }
    }
}