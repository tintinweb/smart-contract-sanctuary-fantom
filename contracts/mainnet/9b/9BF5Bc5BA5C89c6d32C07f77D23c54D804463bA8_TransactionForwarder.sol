/**
 *Submitted for verification at FtmScan.com on 2023-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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




contract TransactionForwarder is Ownable, ReentrancyGuard {
    address private feeClaimer;
    
    receive() external payable {
        
    }

    constructor(address _feeClaimer) {
        feeClaimer = _feeClaimer;
    }

    // encapsulate all data necessary for a transaction
    struct Transaction {
        uint256 value;
        address to;
        address proxy;
        address[] sentTokens;
        uint256[] sentAmounts;
        address[] expectedReturnedTokens;
        uint256[] expectedReturnedAmounts;
        bytes data;
    }

    // check if token address is the 0 address or the standard eeee address and therefor is not an erc20 token address
    function checkIsERC20Address(address tokenAddress) internal pure returns (bool) {
        if (tokenAddress == address(0x0000000000000000000000000000000000000000) || tokenAddress == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
            return false;
        } else {
            return true;
        }
    }

    // safely transfer a specific amount of a specific erc20 token this contract holds to another address
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        uint256 balance = token.balanceOf(address(this));
        require(balance >= value, string(abi.encodePacked("Attempted to transfer more ERC20 token than this contract holds. Currently holding: ", Strings.toString(balance), " but trying to transfer: ", Strings.toString(value) ) ) );
        token.transfer(to, value);
    }

    // safely transfer tokens of a certain type from one address to another address
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        uint256 balance = token.balanceOf(from);
        require(balance >= value, string(abi.encodePacked("Attempted to transfer more ERC20 token from address than address holds. Currently holding: ", Strings.toString(balance), " but trying to transfer: ", Strings.toString(value) ) ) );
        token.transferFrom(from, to, value);
    }

    // safely send all of a specific erc20 token this contract holds to the owner
    function withdrawTokensToOwner(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "Attempted to transfer ERC20 token when this contract holds none");
        safeTransfer(token, owner(), balance);
    }

    // safely send all of the native token this contract holds to the owner
    function withdrawNativeTokenToOwner() external onlyOwner {
        uint256 nativebalance = address(this).balance;
        require(nativebalance > 0, "Attempted to transfer native token when this contract holds none");
        payable(owner()).transfer(nativebalance);
    }

    // check if a specific token is allowed to be spent from the holder to the spender
    function checkAllowance(IERC20 Token, address Holder, address Spender) internal view returns (uint256) {
        return Token.allowance(Holder, Spender);
    }

    // safely approve a specific amount of a specific erc20 token from this contract to a specific address
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        uint256 balance = token.balanceOf(address(this));
        require(balance >= value, string(abi.encodePacked("Contract must hold enough ERC20 tokens before approval. Currently holding: ", Strings.toString(balance), ", but trying to approve: ", Strings.toString(value) ) ) );
        token.approve(spender, value);
    }

    function addressToString(address _addr) internal pure returns(string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }



    function setFeeClaimer(address _feeClaimer) public onlyOwner {
        require(_feeClaimer != address(0), "Cannot set fee claimer to zero address");
        feeClaimer = _feeClaimer;
    }

    // Add a contract address to the whitelist
    function addContractToWhitelist(address contractAddress) external onlyOwner {
        require(contractAddress != address(0), "Cannot add zero address");
        require(!fee_whitelist[contractAddress], "Address already whitelisted");

        fee_whitelist[contractAddress] = true;
    }

    // Remove a contract address from the whitelist
    function removeContractFromWhitelist(address contractAddress) external onlyOwner {
        require(contractAddress != address(0), "Cannot remove zero address");
        require(fee_whitelist[contractAddress], "Address not in whitelist");

        fee_whitelist[contractAddress] = false;
    }
    
    // Check if a contract address is in the whitelist
    function isContractWhitelisted(address contractAddress) public view returns (bool) {
        return fee_whitelist[contractAddress];
    }

    // Add an address to the whitelist
    function addToWhitelist(address account) external onlyOwner {
        require(account != address(0), "Cannot add zero address");
        require(!fee_whitelist[account], "Address already whitelisted");

        fee_whitelist[account] = true;
    }

    // Remove an address from the whitelist
    function removeFromWhitelist(address account) external onlyOwner {
        require(account != address(0), "Cannot remove zero address");
        require(fee_whitelist[account], "Address not in whitelist");

        fee_whitelist[account] = false;
    }
    
    // Check if an address is in the whitelist
    function isWhitelisted(address account) public view returns (bool) {
        return fee_whitelist[account];
    }

    function setFee(uint256 newFee) external onlyOwner{
        feeRate = newFee;
    }

    mapping(address => bool) fee_whitelist;

    uint256 feeRate = 45;

    uint256 constant PERCENTAGE_DIVISOR = 100;
    
    // execute a list of transactions, checking that all go through successfully
    function forwardTransactions(Transaction[] memory transactions) external payable onlyOwner nonReentrant {
        
        require(transactions[0].sentTokens.length == transactions[0].sentAmounts.length, "sent tokens and amounts arrays must be the same length!");
        require(transactions[0].expectedReturnedTokens.length == transactions[0].expectedReturnedAmounts.length, "received tokens and amounts arrays must be the same length!");

        // check if any erc20 token needs to be sent from user
        for (uint256 j = 0; j < transactions[0].sentTokens.length; j++) {
            if (checkIsERC20Address(transactions[0].sentTokens[j])) {
                IERC20 Token = IERC20(transactions[0].sentTokens[j]);

                uint256 Allowance = checkAllowance(Token, msg.sender, address(this));
                uint256 fromAmount = transactions[0].sentAmounts[j];

                require(Allowance >= fromAmount, string(abi.encodePacked("Insufficent allowance given to this contract from user for transfer. Allowance given: ", Strings.toString(Allowance), " but trying to transfer: ", Strings.toString(fromAmount) ) ) );

                safeTransferFrom(Token, msg.sender, address(this), fromAmount);
            }
        }

        // Loop over all transactions, and submit them to the dest contract
        for (uint256 i = 0; i < transactions.length; i++) {

            address router = transactions[i].to;
            address proxy = transactions[i].proxy;
            bytes memory data = transactions[i].data;

            // check if dest contracts are whitelisted
            require(isContractWhitelisted(transactions[i].to), string(abi.encodePacked("Sub-Transaction Address ", addressToString(transactions[i].to), " Not Whitelisted")));
            require(isContractWhitelisted(transactions[i].proxy), string(abi.encodePacked("Sub-Transaction Address ", addressToString(transactions[i].proxy), " Not Whitelisted")));
            
            require(transactions[i].sentTokens.length == transactions[i].sentAmounts.length, "sent tokens and amounts arrays must be the same length!");

            // approve necessary tokens for the subtransaction
            for (uint256 j = 0; j < transactions[i].sentTokens.length; j++) {
                if (checkIsERC20Address(transactions[i].sentTokens[j])) {
                    IERC20 Token = IERC20(transactions[i].sentTokens[j]);
                    safeApprove(Token, router, transactions[i].sentAmounts[j]);
                    safeApprove(Token, proxy, transactions[i].sentAmounts[j]);
                }
            }

            require(address(this).balance >= transactions[i].value, string(abi.encodePacked("Subtransaction ", Strings.toString(i), " requires: ", Strings.toString(transactions[i].value), " native token but is only holding: ", Strings.toString(address(this).balance) ) ) );
            
            // call the dest contract
            (bool success, bytes memory result) = router.call{value: transactions[i].value}(data);

            // require the dest contract call to be successful, else print the error
            require(success, string(abi.encodePacked(result)));
            
            // revoke approval necessary tokens for the subtransaction
            for (uint256 j = 0; j < transactions[i].sentTokens.length; j++) {
                if (checkIsERC20Address(transactions[i].sentTokens[j])) {
                    IERC20 Token = IERC20(transactions[i].sentTokens[j]);
                    safeApprove(Token, router, 0);
                    safeApprove(Token, proxy, 0);
                }
            }

        }

        // After last Transaction, 
        // Ensure final received amount of output tokens is greater or equal to expected final received amounts
        uint256 finalTransactionIndex = transactions.length - 1;
        for (uint256 j = 0; j < transactions[finalTransactionIndex].expectedReturnedTokens.length; j++) {
            if (checkIsERC20Address(transactions[finalTransactionIndex].expectedReturnedTokens[j])) {
                IERC20 token = IERC20(transactions[finalTransactionIndex].expectedReturnedTokens[j]);
                uint256 balance = token.balanceOf(address(this));
                require(balance >= transactions[finalTransactionIndex].expectedReturnedAmounts[j], string(abi.encodePacked("Final output of: ", Strings.toString(balance), " is less than expected amount of: ", Strings.toString(transactions[finalTransactionIndex].expectedReturnedAmounts[j]) ) ) );
            
            }
        }

        // After last Transaction, 
        // Process the fee
        if (isWhitelisted(msg.sender) == false) {
            
            uint256 thisProfit;
            uint256 thisFeeAmnt;

            uint256 thisNativeProfit;
            uint256 thisNativeFeeAmnt;

            // loop through all tokens in the final transaction and calculate profits
            for (uint256 i = 0; i < transactions[finalTransactionIndex].expectedReturnedTokens.length; i++) {
                if (checkIsERC20Address(transactions[finalTransactionIndex].expectedReturnedTokens[i])) {
                    // calculate erc20 token profits
                    IERC20 token = IERC20(transactions[finalTransactionIndex].expectedReturnedTokens[i]);
                    if (token.balanceOf(address(this)) > transactions[finalTransactionIndex].expectedReturnedAmounts[i]) {
                        thisProfit = token.balanceOf(address(this)) - transactions[finalTransactionIndex].expectedReturnedAmounts[i];
                        thisFeeAmnt = (thisProfit * feeRate) / PERCENTAGE_DIVISOR;
                        if (thisFeeAmnt > 0) {
                            safeTransfer(token, feeClaimer, thisFeeAmnt);
                        }
                    }
                }
            }
            // calculate native token profits
            if (address(this).balance > transactions[finalTransactionIndex].value) {
                thisNativeProfit = address(this).balance - transactions[finalTransactionIndex].value;
                thisNativeFeeAmnt = (thisNativeProfit * feeRate) / PERCENTAGE_DIVISOR;
                if (thisNativeFeeAmnt > 0) {
                    payable(feeClaimer).transfer(thisNativeFeeAmnt);
                }
            }
        }

        // Loop over all transactions, and send any held tokens back to the sender
        for (uint256 i = 0; i < transactions.length; i++) {

            // transfer all remaining tokens back to the sender
            for (uint256 j = 0; j < transactions[i].expectedReturnedTokens.length; j++) {
                if (checkIsERC20Address(transactions[i].expectedReturnedTokens[j])) {
                    IERC20 token = IERC20(transactions[i].expectedReturnedTokens[j]);
                    uint256 balance = token.balanceOf(address(this));
                    if (balance > 0) {
                        safeTransfer(token, msg.sender, balance);
                    }
                }
            }
        }

        // Return any remaining ether
        uint256 nativebalance = address(this).balance;
        if (nativebalance > 0) {
            payable(msg.sender).transfer(nativebalance);
        }
    }
}