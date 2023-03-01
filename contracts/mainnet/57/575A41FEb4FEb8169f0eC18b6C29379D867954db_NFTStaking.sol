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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

interface IERC721Ownable {
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);
}

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

interface IERC20Mintable {
    function mint(address to, uint amount) external;
}

interface IERC721Metadata {
    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract NFTStaking is ERC721Holder {

    struct NFTInfo {
        address tokenOwner;
        uint256 stakedStartTime;
        uint256 lastUpdate;
        bool isStaked;
    }

    struct StakingInfo {
        address collectionAddress;
        address rewardTokenAddress;
        address creatorAddress;
        uint256 minStakeSeconds;
        uint256 maxStakeSeconds;
        uint256 cooldownSeconds;
        uint256 timeUnitSeconds;
        uint256 rewardsPerTimeUnit;
        uint256 startTimestamp;
        uint256 endTimestamp;
        string baseURI;
    }

    struct CreatorPool {
        uint poolId;
        address collectionAddress;
    }

    struct StakingPool {
        StakingInfo Conditions;
        mapping(uint256 => NFTInfo) stakedNFTs;
        mapping(address => uint256[]) stakedArrays;
    }

    struct Rewards {
        uint NFTId;
        uint rewards;
        string uri;
    }

    uint public poolsCounter;

    address public immutable admin;

    mapping(address => bool) public isPoolExists;

    mapping(address => uint) public createdPools;

    StakingPool[] private _pools;

    constructor() {
        admin = msg.sender;
    }
    
    function initPool(
        address collectionAddress,
        address rewardTokenAddress,
        uint256 minStakeSeconds,
        uint256 maxStakeSeconds,
        uint256 cooldownSeconds,
        uint256 timeUnitSeconds,
        uint256 rewardsPerTimeUnit,
        uint256 startTimestamp,
        uint256 endTimestamp
    ) external {
        require(!isPoolExists[collectionAddress], "Collection already exists");

        require(
            IERC165(collectionAddress).supportsInterface(type(IERC721).interfaceId),
            "NFT contract does not supports ERC721 interface"
        );

        require(
            IERC165(rewardTokenAddress).supportsInterface(type(IERC20).interfaceId),
            "Reward token does not supports ERC20 interface"
        );

        // Checks if msg.sender is owner of collection contract
        // /// @dev Calls 'owner()' funtion to check if sender is an owner
        // require(IERC721Ownable(collectionAddress).owner() == msg.sender, "Sender is not an Owner of collection");

        _pools.push();

        bytes memory strBytes = bytes(IERC721Metadata(collectionAddress).tokenURI(0));
        bytes memory baseURI = new bytes(strBytes.length - 1);

        for(uint i; i < baseURI.length; i++) {
            baseURI[i] = strBytes[i];
        }

        StakingInfo memory info = StakingInfo({
            collectionAddress: collectionAddress,
            rewardTokenAddress: rewardTokenAddress,
            creatorAddress: msg.sender,
            minStakeSeconds: minStakeSeconds,
            maxStakeSeconds: maxStakeSeconds,
            cooldownSeconds: cooldownSeconds,
            timeUnitSeconds: timeUnitSeconds,
            rewardsPerTimeUnit: rewardsPerTimeUnit,
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp,
            baseURI: string(baseURI)
        });

        _pools[poolsCounter].Conditions = info;

        poolsCounter++;

        isPoolExists[collectionAddress] = true;

        createdPools[msg.sender] = createdPools[msg.sender] + 1;
    }

    function stake(uint256 poolId, uint256[] calldata nftIds) external {
        address collection = _pools[poolId].Conditions.collectionAddress;
        require(_pools[poolId].Conditions.startTimestamp < block.timestamp, "Pool has not started yet");
        require(_pools[poolId].Conditions.endTimestamp > block.timestamp, "Pool is passed out");
        
        for(uint i; i < nftIds.length; i++) {
            require(
                _pools[poolId].stakedNFTs[nftIds[i]].lastUpdate < block.timestamp - _pools[poolId].Conditions.cooldownSeconds,
                "Cooldown has not passed out"
            );

            IERC721(collection).safeTransferFrom(msg.sender, address(this), nftIds[i]);

            _pools[poolId].stakedNFTs[nftIds[i]] = NFTInfo({
                tokenOwner: msg.sender,
                stakedStartTime: block.timestamp,
                lastUpdate: block.timestamp,
                isStaked: true
            });

            _pools[poolId].stakedArrays[msg.sender].push(nftIds[i]);
        }
    }

    function claimRewards(uint256 poolId) external {
        uint[] memory stakedNFTs = _pools[poolId].stakedArrays[msg.sender];

        require(stakedNFTs.length > 0, "No NFTs were staked");

        uint rewards;

        StakingInfo memory conditions = _pools[poolId].Conditions;

        for(uint i; i < stakedNFTs.length; i++) {
            rewards += calculateReward(poolId, stakedNFTs[i]);

            _pools[poolId].stakedNFTs[stakedNFTs[i]].lastUpdate = block.timestamp;
            _pools[poolId].stakedNFTs[stakedNFTs[i]].stakedStartTime = block.timestamp;
        }

        /// @dev Mints tokens to staker
        IERC20Mintable(conditions.rewardTokenAddress).mint(msg.sender, rewards);
    }

    function unstake(uint256 poolId, uint256[] calldata nftIds) external {
        uint[] storage stakedArray = _pools[poolId].stakedArrays[msg.sender];

        for(uint i; i < nftIds.length; i++) {   
            require(_pools[poolId].stakedNFTs[nftIds[i]].tokenOwner == msg.sender, "Sender is not owner of nft id");
            require(_pools[poolId].stakedNFTs[nftIds[i]].isStaked, "NFT is not staked");

            IERC721(_pools[poolId].Conditions.collectionAddress).safeTransferFrom(address(this), msg.sender, nftIds[i]);

            _pools[poolId].stakedNFTs[nftIds[i]] = NFTInfo({
                tokenOwner: address(0),
                stakedStartTime: 0,
                lastUpdate: block.timestamp,
                isStaked: false
            });
            
            /// @dev Finds nft id at Sender`s 'stakedArrays' rewrites it and deletes id from array
            for(uint j; j < stakedArray.length; j++) {
                if(stakedArray[j] == nftIds[i]) {
                    for(uint y = j; y < stakedArray.length - 1; y++) {
                        stakedArray[y] = stakedArray[y+1];
                    }
                    stakedArray.pop();
                    break;
                }
            }
        }
    }

    function getPoolInfo(uint256 index) external view returns(StakingInfo memory) {
        return _pools[index].Conditions;
    }

    function getPoolsByCreator(address creator) external view returns(CreatorPool[] memory) {
        CreatorPool[] memory createdPoolz = new CreatorPool[](createdPools[creator]);
        uint j;

        for(uint i; i < _pools.length; i++) {
            if(_pools[i].Conditions.creatorAddress == creator) {
                createdPoolz[j].poolId = i;
                createdPoolz[j].collectionAddress = _pools[i].Conditions.collectionAddress;
                j++;
            }
        }

        return createdPoolz;
    }

    function getAllPools(uint offset, uint limit) external view returns(StakingInfo[] memory) {
        require(offset <= poolsCounter, "Offset must be less then _pools length");
        require(offset + limit <= poolsCounter, "Offset + limil must be less then _pools length");
        StakingInfo[] memory pools = new StakingInfo[](limit);
        for(uint i; offset < limit; i++) {
            pools[offset] = _pools[offset].Conditions;
            offset++;
        }
        return pools;
    }

    function getStakeInfo(uint256 poolId, address staker, uint start, uint end) external view returns(Rewards[] memory) {
        StakingInfo memory conditions = _pools[poolId].Conditions;

        Rewards[] memory rewards = new Rewards[](end - start);
        uint i;

        for( ; start < end; start++) {
            rewards[i].NFTId = _pools[poolId].stakedArrays[staker][start];
            rewards[i].rewards = calculateReward(poolId, rewards[i].NFTId);

            // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
            rewards[i].uri = string(abi.encodePacked(conditions.baseURI, Strings.toString(rewards[i].NFTId)));

            i++;
        }

        return rewards;
    }

    function getNFTStakedLength(uint256 poolId, address staker) external view returns(uint) {
        return _pools[poolId].stakedArrays[staker].length;
    }

    function getStakedArray(uint256 poolId, address staker) external view returns(uint[] memory array) {
        array = _pools[poolId].stakedArrays[staker];
    }

    function calculateReward(uint256 poolId, uint nftId) public view returns(uint256 reward) {
        require(_pools[poolId].stakedNFTs[nftId].isStaked, "NFT is not staked in pool");
        StakingInfo memory conditions = _pools[poolId].Conditions;

        uint duration = block.timestamp - _pools[poolId].stakedNFTs[nftId].stakedStartTime;

        if(duration > conditions.maxStakeSeconds) duration = conditions.maxStakeSeconds;

        uint accumulatedTimeUnits = duration / conditions.minStakeSeconds;

        reward = accumulatedTimeUnits * conditions.rewardsPerTimeUnit;
    }

    function removePool(uint poolId) external {
        require(msg.sender == _pools[poolId].Conditions.creatorAddress, "Sender is not pool creator");

        delete _pools[poolId];
    }

    function insertPool(
        uint poolId,
        address collectionAddress,
        address rewardTokenAddress,
        address creatorAddress,
        uint256 minStakeSeconds,
        uint256 maxStakeSeconds,
        uint256 cooldownSeconds,
        uint256 timeUnitSeconds,
        uint256 rewardsPerTimeUnit,
        uint256 startTimestamp,
        uint256 endTimestamp,
        string memory baseURI
    ) external {
        require(msg.sender == admin, "Sender is not admin");

        StakingInfo memory info = StakingInfo({
            collectionAddress: collectionAddress,
            rewardTokenAddress: rewardTokenAddress,
            creatorAddress: creatorAddress,
            minStakeSeconds: minStakeSeconds,
            maxStakeSeconds: maxStakeSeconds,
            cooldownSeconds: cooldownSeconds,
            timeUnitSeconds: timeUnitSeconds,
            rewardsPerTimeUnit: rewardsPerTimeUnit,
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp,
            baseURI: baseURI
        });

        _pools[poolId].Conditions = info;
    }

    function getNFTInfo(uint256 poolId, uint nftId) external view returns(NFTInfo memory) {
        return _pools[poolId].stakedNFTs[nftId];
    }

    function timestamp() external view returns(uint) {
        return block.timestamp;
    }
}