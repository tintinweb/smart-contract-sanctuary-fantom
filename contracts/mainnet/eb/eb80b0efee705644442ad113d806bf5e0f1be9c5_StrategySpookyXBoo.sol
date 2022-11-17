/**
 *Submitted for verification at FtmScan.com on 2022-11-17
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File @openzeppelin/contracts-upgradeable/math/[email protected]

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File @openzeppelin/contracts/math/[email protected]

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File @openzeppelin/contracts-upgradeable/proxy/[email protected]

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// File @openzeppelin/contracts-upgradeable/access/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

// File contracts/strategies/SpookySwap/StrategySpookyBase.sol

pragma solidity ^0.6.12;

abstract contract StrategySpookyBase is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMath for uint256;
    using AddressUpgradeable for address;

    // Tokens
    address public want;

    // User accounts
    address public depositor;

    address public feeHandler;
    uint256 public feePerformance;
    uint256 public feeHarvest;
    uint256 public feeMax;

    mapping(address => bool) public harvesters;

    constructor() public {}

    function initializeStrategyBase(
        address _want,
        address _depositor,
        address _feeHandler,
        uint256 _feePerformance,
        uint256 _feeHarvest,
        uint256 _feeMax
    ) public initializer {
        __Ownable_init();
        require(_want != address(0), "!zero address");
        require(_depositor != address(0), "!zero address");
        require(_feeMax != 0, "!feeMax");

        want = _want;
        depositor = _depositor;
        feeHandler = _feeHandler;
        feePerformance = _feePerformance;
        feeHarvest = _feeHarvest;
        feeMax = _feeMax;
    }

    // **** Modifiers **** //

    modifier onlyBenevolent() {
        require(harvesters[msg.sender] || msg.sender == owner() || msg.sender == depositor);
        _;
    }

    // **** Views **** //

    function balanceOfWant() public view returns (uint256) {
        return IERC20Upgradeable(want).balanceOf(address(this));
    }

    function balanceOfPool() public view virtual returns (uint256);

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function setFees(
        uint256 _feePerformance,
        uint256 _feeHarvest,
        uint256 _feeMax
    ) external onlyOwner {
        require(_feePerformance + _feeHarvest < _feeMax, "!fee values");
        feePerformance = _feePerformance;
        feeHarvest = _feeHarvest;
        feeMax = _feeMax;
    }

    function setFeeHandler(address _feeHandler) external onlyOwner {
        require(_feeHandler != address(0), "!Null Address");
        feeHandler = _feeHandler;
    }

    // **** Setters **** //

    function whitelistHarvesters(address[] calldata _harvesters) external {
        require(msg.sender == owner() || harvesters[msg.sender], "not authorized");

        for (uint256 i = 0; i < _harvesters.length; i++) {
            harvesters[_harvesters[i]] = true;
        }
    }

    function revokeHarvesters(address[] calldata _harvesters) external onlyOwner {
        for (uint256 i = 0; i < _harvesters.length; i++) {
            harvesters[_harvesters[i]] = false;
        }
    }

    function setDepositor(address _depositor) external onlyOwner {
        depositor = _depositor;
    }

    // **** State mutations **** //
    function deposit() public virtual;

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20Upgradeable _asset) external onlyOwner returns (uint256 balance) {
        require(want != address(_asset), "want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(depositor, balance);
    }

    // Withdraw partial funds
    function withdraw(uint256 _amount) external returns (uint256) {
        require(msg.sender == depositor, "!depositor");
        uint256 _balance = IERC20Upgradeable(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        IERC20Upgradeable(want).safeTransfer(depositor, _amount);
        return _amount;
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == owner() || msg.sender == depositor, "!owner");
        _withdrawAll();

        balance = IERC20Upgradeable(want).balanceOf(address(this));

        IERC20Upgradeable(want).safeTransfer(depositor, balance);
    }

    function _withdrawAll() internal {
        _withdrawSome(balanceOfPool());
    }

    function _withdrawSome(uint256 _amount) internal virtual returns (uint256);
}

// File contracts/strategies/SpiritBoostedFarms/interfaces/IMasterChef.sol

pragma solidity 0.6.12;

interface IMasterChef {
    function BONUS_MULTIPLIER() external view returns (uint256);

    function add(
        uint256 _allocPoint,
        address _lpToken,
        bool _withUpdate
    ) external;

    function bonusEndBlock() external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function dev(address _devaddr) external;

    function devFundDivRate() external view returns (uint256);

    function devaddr() external view returns (address);

    function lpToken(uint256) external view returns (address);

    function emergencyWithdraw(uint256 _pid) external;

    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);

    function massUpdatePools() external;

    function owner() external view returns (address);

    function pendingPickle(uint256 _pid, address _user) external view returns (uint256);

    function pendingReward(uint256 _pid, address _user) external view returns (uint256);

    function pending(uint256 _pid, address _user) external view returns (uint256);

    function poolInfo(uint256)
        external
        view
        returns (
            address,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accPicklePerShare
        );

    function poolLength() external view returns (uint256);

    function renounceOwnership() external;

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function setBonusEndBlock(uint256 _bonusEndBlock) external;

    function setDevFundDivRate(uint256 _devFundDivRate) external;

    function setPicklePerBlock(uint256 _picklePerBlock) external;

    function startBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updatePool(uint256 _pid) external;

    function userInfo(uint256, address) external view returns (uint256 amount, uint256 rewardDebt);

    function withdraw(uint256 _pid, uint256 _amount) external;
}

// File contracts/strategies/SpiritBoostedFarms/interfaces/IBar.sol

pragma solidity 0.6.12;

interface IBar {
    function enter(uint256 _amount) external;

    function leave(uint256 _shareOfFreshBeets) external;
}

// File contracts/strategies/SpiritBoostedFarms/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.5.0;

interface IUniswapV2Router02 {
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

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

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

// File contracts/interfaces/IAceLab.sol

pragma solidity ^0.6.2;

interface IAceLab {
    function poolInfo(uint256)
        external
        returns (
            address,
            uint32,
            uint8,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            uint32,
            uint32,
            uint32
        );
}

// File @boringcrypto/boring-solidity/contracts/interfaces/[email protected]

pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// File contracts/interfaces/IShadowChef.sol

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IShadowChef {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        uint128 accLqdrPerShare;
        uint64 lastRewardTime;
        uint64 allocPoint;
    }

    function lpToken() external view returns (IERC20);

    function strategy() external view returns (address);

    function poolLength() external view returns (uint256);

    function updatePool(uint256 pid) external returns (IShadowChef.PoolInfo memory);

    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

    function deposit(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function withdraw(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function harvest(uint256 pid, address to) external;

    function withdrawAndHarvest(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function emergencyWithdraw(uint256 pid, address to) external;

    function pendingReward(uint256 _pid, address _user) external view returns (uint256);
}

// File contracts/interfaces/IRewarder.sol

pragma solidity ^0.6.2;

interface IRewarder {
    function rewardToken() external returns (address);
}

// File contracts/interfaces/IMasterChefV2.sol

pragma solidity ^0.6.2;

interface IMasterChefV2 {
    function rewarder(uint256) external returns (address);
}

// File hardhat/[email protected]

pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int)", p0));
    }

    function logUint(uint256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function logString(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function log(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint256 p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
    }

    function log(uint256 p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
    }

    function log(uint256 p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
    }

    function log(uint256 p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
    }

    function log(string memory p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
    }

    function log(bool p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
    }

    function log(address p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(
        uint256 p0,
        uint256 p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
    }

    function log(
        uint256 p0,
        uint256 p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
    }

    function log(
        uint256 p0,
        uint256 p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
    }

    function log(
        uint256 p0,
        string memory p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
    }

    function log(
        uint256 p0,
        bool p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
    }

    function log(
        uint256 p0,
        bool p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
    }

    function log(
        uint256 p0,
        bool p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
    }

    function log(
        uint256 p0,
        bool p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
    }

    function log(
        uint256 p0,
        address p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
    }

    function log(
        uint256 p0,
        address p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
    }

    function log(
        uint256 p0,
        address p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
    }

    function log(
        string memory p0,
        uint256 p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(
        string memory p0,
        string memory p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(
        string memory p0,
        bool p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(
        string memory p0,
        bool p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(
        string memory p0,
        bool p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
    }

    function log(
        string memory p0,
        address p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(
        string memory p0,
        address p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(
        string memory p0,
        address p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(
        bool p0,
        uint256 p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
    }

    function log(
        bool p0,
        uint256 p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
    }

    function log(
        bool p0,
        uint256 p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
    }

    function log(
        bool p0,
        uint256 p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
    }

    function log(
        bool p0,
        string memory p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(
        bool p0,
        string memory p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(
        bool p0,
        string memory p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(
        bool p0,
        bool p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
    }

    function log(
        bool p0,
        bool p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(
        bool p0,
        bool p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(
        bool p0,
        bool p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(
        bool p0,
        address p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
    }

    function log(
        bool p0,
        address p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(
        bool p0,
        address p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(
        bool p0,
        address p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(
        address p0,
        uint256 p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
    }

    function log(
        address p0,
        uint256 p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
    }

    function log(
        address p0,
        uint256 p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
    }

    function log(
        address p0,
        string memory p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(
        address p0,
        string memory p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(
        address p0,
        string memory p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(
        address p0,
        bool p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
    }

    function log(
        address p0,
        bool p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(
        address p0,
        bool p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(
        address p0,
        bool p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(
        address p0,
        address p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
    }

    function log(
        address p0,
        address p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(
        address p0,
        address p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(
        address p0,
        address p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(
        uint256 p0,
        uint256 p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }
}

// File contracts/strategies/SpookySwap/StrategySpookyXBoo.sol

pragma solidity ^0.6.7;

contract StrategySpookyXBoo is StrategySpookyBase {
    string public __NAME__;
    // Token addresses
    address public masterChef;
    uint256 public pid;

    // Second reward
    address public secondReward;
    uint256 public secondRewardSellLimit;
    address[] public secondRewardPath;

    // token addresses for spooky
    address public spookyRouter;
    address public boo;
    address public xBoo;
    uint256 public aceLabInfoId;
    mapping(address => bool) aceLabAdded;

    struct AceLabInfo {
        address aceLab;
        uint256 aceLabPid;
        address aceLabReward;
        uint256 aceLabRewardSellLimit;
        address[] booPath;
    }

    AceLabInfo[] public aceLabInfo;

    constructor() public {}

    function initialize(
        string memory _name,
        address _lp,
        address _masterChef,
        uint256 _pid,
        address _depositor,
        address _feeHandler,
        uint256 _feePerformance,
        uint256 _feeHarvest,
        uint256 _feeMax
    ) public initializer {
        // check lp token
        require(_lp == IMasterChef(_masterChef).lpToken(_pid), "lp and masterchef don't match");

        __NAME__ = _name;

        initializeStrategyBase(_lp, _depositor, _feeHandler, _feePerformance, _feeHarvest, _feeMax);
        masterChef = _masterChef;
        pid = _pid;
        spookyRouter = address(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
        boo = address(0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE);
        xBoo = address(0xa48d959AE2E88f1dAA7D5F611E01908106dE7598);

        // check aceLab
        // aceLab = address(0x2352b745561e7e6FCD03c093cE7220e3e126ace0);
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IMasterChef(masterChef).userInfo(pid, address(this));
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        uint256 _pendingReward = IMasterChef(masterChef).pendingReward(pid, address(this));
        return _pendingReward;
    }

    // **** Setters ****

    function addAceLab(
        address _aceLab,
        uint256 _aceLabPid,
        address _aceLabReward,
        uint256 _aceLabRewardSellLimit,
        address[] memory _booPath
    ) external onlyOwner {
        (address _rewardToken, , , , , , , , , , , ) = IAceLab(_aceLab).poolInfo(_aceLabPid);
        require(_aceLabReward == _rewardToken, "AceLab reward token doesn't match.");
        require(_booPath.length > 0, "!route length");
        require(_booPath[0] == _aceLabReward, "!first route");
        require(_booPath[_booPath.length - 1] == boo, "!last route");
        require(!aceLabAdded[_aceLabReward], "Already added");
        aceLabInfo.push(
            AceLabInfo({
                aceLab: _aceLab,
                aceLabPid: _aceLabPid,
                aceLabReward: _aceLabReward,
                aceLabRewardSellLimit: _aceLabRewardSellLimit,
                booPath: _booPath
            })
        );
        aceLabAdded[_aceLabReward] = true;
    }

    function setSecondReward(
        address _secondReward,
        uint256 _secondRewardSellLimit,
        address[] memory _route
    ) external onlyOwner {
        address _rewarder = IMasterChefV2(masterChef).rewarder(pid);
        require(_secondReward == IRewarder(_rewarder).rewardToken(), "!rewardToken");
        require(_route.length > 0, "!route length");
        require(_route[0] == _secondReward, "!first route");
        require(_route[_route.length - 1] == boo, "!last route");
        secondReward = _secondReward;
        secondRewardSellLimit = _secondRewardSellLimit;
        secondRewardPath = _route;
    }

    function deposit() public override onlyBenevolent {
        uint256 _want = IERC20Upgradeable(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20Upgradeable(want).safeApprove(masterChef, 0);
            IERC20Upgradeable(want).safeApprove(masterChef, _want);
            IMasterChef(masterChef).deposit(pid, _want);
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        uint256 _balance = balanceOfPool();
        if (_amount > _balance) {
            _amount = _balance;
        }
        IMasterChef(masterChef).withdraw(pid, _amount);
        return _amount;
    }

    // **** State Mutations ****

    function harvest(address _harvester) public onlyBenevolent returns (uint256) {
        // harvest from Spooky MasterChef
        IMasterChef(masterChef).withdraw(pid, 0);

        AceLabInfo storage _aceLabInfo = aceLabInfo[aceLabInfoId];

        // harvest from aceLab
        IMasterChef(_aceLabInfo.aceLab).withdraw(_aceLabInfo.aceLabPid, 0);
        uint256 aceLabRewardAmount = IERC20Upgradeable(_aceLabInfo.aceLabReward).balanceOf(address(this));

        if (aceLabRewardAmount > _aceLabInfo.aceLabRewardSellLimit) {
            _swapWithPath(_aceLabInfo.booPath, aceLabRewardAmount);
        }

        if (secondReward != address(0)) {
            uint256 secondRewardAmount = IERC20Upgradeable(secondReward).balanceOf(address(this));
            if (secondRewardAmount > secondRewardSellLimit) {
                _swapWithPath(secondRewardPath, secondRewardAmount);
            }
        }

        // get boo balance
        uint256 booBalance = IERC20Upgradeable(boo).balanceOf(address(this));

        // enter to xBoo
        _enterXBoo(booBalance);

        // get xBoo balance
        uint256 xBooBalance = IERC20Upgradeable(xBoo).balanceOf(address(this));
        uint256 _feePerformance = xBooBalance.mul(feePerformance).div(feeMax);
        uint256 _feeHarvest = xBooBalance.mul(feeHarvest).div(feeMax);
        xBooBalance = xBooBalance.sub(_feePerformance).sub(_feeHarvest);

        IERC20Upgradeable(xBoo).safeTransfer(feeHandler, _feePerformance);
        IERC20Upgradeable(xBoo).safeTransfer(_harvester, _feeHarvest);

        // stake in aceLab
        _approveToken(_aceLabInfo.aceLab, xBoo, xBooBalance);
        aceLabInfoId = getBestAceLab(xBooBalance);
        IMasterChef(_aceLabInfo.aceLab).deposit(_aceLabInfo.aceLabPid, xBooBalance);

        return xBooBalance;
    }

    function getBestAceLab(uint256 _xBooBalance) public returns (uint256 _aceLabInfoId) {
        AceLabInfo storage _aceLabInfo = aceLabInfo[aceLabInfoId];
        (uint256 _deposited, ) = IMasterChef(_aceLabInfo.aceLab).userInfo(_aceLabInfo.aceLabPid, address(this));
        uint256 _toDeposit = _deposited.add(_xBooBalance);
        uint256 _poolLength = aceLabInfo.length;

        uint256 _bestAceLabInfoId;
        uint256 _bestReward;

        for (uint256 i = 0; i < _poolLength; i++) {
            uint256 _aceLabPid = aceLabInfo[i].aceLabPid;
            (, uint256 _rewardPerSecond, , uint256 _xBooStakedAmount, , , , , , , , ) = IAceLab(aceLabInfo[i].aceLab).poolInfo(_aceLabPid);

            if (_rewardPerSecond > 0) {
                uint256 _rewardPerDay = _rewardPerSecond.mul(86400);
                if (aceLabInfo[i].aceLabPid == _aceLabPid) {
                    _xBooStakedAmount = _xBooStakedAmount.sub(_deposited);
                }

                uint256[] memory _amounts = IUniswapV2Router02(spookyRouter).getAmountsOut(_rewardPerDay, aceLabInfo[i].booPath);
                uint256 _rewardAmount = _amounts[aceLabInfo[i].booPath.length - 1];
                uint256 _rewardPerXBoo = _rewardAmount.div(_xBooStakedAmount + _toDeposit);

                if (_rewardPerXBoo > _bestReward) {
                    _bestAceLabInfoId = i;
                    _bestReward = _rewardPerXBoo;
                }
            }
        }

        _aceLabInfoId = _bestAceLabInfoId;
    }

    function xBooBalanceInAceLab() public view returns (uint256 _xBooBalance) {
        (_xBooBalance, ) = IMasterChef(aceLabInfo[aceLabInfoId].aceLab).userInfo(aceLabInfo[aceLabInfoId].aceLabPid, address(this));
    }

    function claim(uint256 pendingXBoo) external onlyBenevolent {
        IMasterChef(aceLabInfo[aceLabInfoId].aceLab).withdraw(aceLabInfo[aceLabInfoId].aceLabPid, pendingXBoo);
        IERC20Upgradeable(xBoo).safeTransfer(msg.sender, pendingXBoo);
    }

    function _enterXBoo(uint256 _amount) private returns (uint256 enterAmount) {
        _approveToken(xBoo, boo, _amount);
        IBar(xBoo).enter(_amount);
        enterAmount = IERC20Upgradeable(xBoo).balanceOf(address(this));
    }

    function _approveToken(
        address _spender,
        address _token,
        uint256 _amount
    ) internal {
        require(_token != address(0) && _spender != address(0), "_approveToken address(0)");
        uint256 allowances = IERC20Upgradeable(_token).allowance(address(this), _spender);
        // if allowances are too low and we have _amount then increase, if _amount is zero then no need on this tx
        if (allowances < _amount && _amount > 0) {
            IERC20Upgradeable(_token).safeApprove(_spender, 0);
            IERC20Upgradeable(_token).safeApprove(_spender, uint256(-1));
        }
    }

    function _swapWithPath(address[] memory _path, uint256 _amount) internal {
        require(_path[1] != address(0));
        _approveToken(spookyRouter, _path[0], _amount);
        IUniswapV2Router02(spookyRouter).swapExactTokensForTokens(_amount, 1, _path, address(this), now.add(60));
    }

    function getBalance() public view returns (uint256) {
        // retrieve the balance of xBoo
        (uint256 amount, ) = IMasterChef(aceLabInfo[aceLabInfoId].aceLab).userInfo(aceLabInfo[aceLabInfoId].aceLabPid, address(this));
        return amount;
    }
}