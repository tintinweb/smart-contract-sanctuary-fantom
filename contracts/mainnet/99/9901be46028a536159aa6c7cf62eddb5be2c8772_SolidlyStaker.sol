/**
 *Submitted for verification at FtmScan.com on 2022-02-27
*/

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        assembly { size := extcodesize(account) }
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
        (bool success, ) = recipient.call{ value: amount }("");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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


// File @openzeppelin/contracts/token/ERC20/[email protected]



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
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/utils/[email protected]



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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]



pragma solidity >=0.6.0 <0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


// File @openzeppelin/contracts/access/[email protected]



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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
}


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File contracts/BIFI/strategies/Solidly/SolidlyStaker.sol


pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
interface IVoter {
    function _ve() external view returns (address);
    function gauges(address) external view returns (address);
    function bribes(address) external view returns (address);
    function minter() external view returns (address);
    function length() external view returns(uint256);
    function pools(uint) external view returns (address);
    function vote(uint tokenId, address[] calldata _poolVote, int256[] calldata _weights) external;
    function reset(uint _tokenId) external;
    function whitelist(address _token, uint _tokenId) external;
    function createGauge(address _pool) external returns (address);
    function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint _tokenId) external;
    function listing_fee() external view returns (uint);
}

interface IVeToken {
    function token() external view returns (address);
    function ownerOf(uint) external view returns (address);
    function create_lock(uint _value, uint _lock_duration) external returns (uint);
    function withdraw(uint _tokenId) external;
    function increase_amount(uint _tokenId, uint _value) external;
    function increase_unlock_time(uint _tokenId, uint _lock_duration) external;
    function merge(uint _from, uint _to) external;
    function locked(uint) external view returns (uint, uint);
    function safeTransferFrom(address from, address to, uint tokenId) external;
    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);
    function balanceOfNFT(uint256 tokenId) external view returns (uint);
}

interface IGauge {
    function bribe() external view returns (address);
    function isReward(address) external view returns (bool);
    function getReward(address account, address[] memory tokens) external;
    function earned(address token, address account) external view returns (uint);
    function stake() external view returns (address);
    function deposit(uint amount, uint tokenId) external;
    function withdraw(uint amount) external;
    function withdrawToken(uint amount, uint tokenId) external;
    function tokenIds(address owner) external view returns (uint256 tokenId);
}

interface IBribe {
    function isReward(address) external view returns (bool);
    function getReward(uint tokenId, address[] memory tokens) external;
    function earned(address token, uint tokenId) external view returns (uint);
}

interface IVeDist {
    function claim(uint tokenId) external returns (uint);
}

interface IMinter {
    function _ve_dist() external view returns (address);
}

interface IBaseV1Pair {
    function claimFees() external returns (uint claimed0, uint claimed1);
}

// SolidlyStaker
contract SolidlyStaker is ERC20, Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        mapping(address => uint256) rewardDebt; // Reward debt for each reward token.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // LP address
        IGauge gauge; // Gauge address
        IBribe bribe; // Bribe address
        uint256 totalDepositedAmount; // # of deposit tokens in this pool
        uint256 lastRewardTime; // Last block time that reward distribution occurred.
        mapping(address => uint256) accRewardPerShare; // Accumulated reward per share, times 1e18.
        address[] rewards; // Reward tokens for the pool.
    }

    modifier onlyManager() {
        require(msg.sender == owner() || msg.sender == keeper, "!manager");
        _;
    }

    modifier onlyVoter() {
        require(msg.sender == owner() || msg.sender == keeper || msg.sender == beefyVoter, "!voter");
        _;
    }

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Stored balance of rewards.
    mapping(address => uint256) public storedRewardBalance;
    // Existing pools to check for duplicates.
    mapping(address => bool) public isExistingPool;

    IVoter public voter;
    IVeToken public veToken;
    IVeDist public veDist;
    uint256 public veTokenId;
    IERC20 public want;
    address public treasury;
    address public rewardPool;
    address public keeper;
    address public beefyVoter;

    event Deposit(address indexed user, uint256 pid, uint256 amount);
    event Withdraw(address indexed user, uint256 pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 pid, uint256 amount);

    event CreateLock(address indexed user, uint256 veTokenId, uint256 amount, uint256 unlockTime);
    event Release(address indexed user, uint256 veTokenId, uint256 amount);
    event IncreaseTime(address indexed user, uint256 veTokenId, uint256 unlockTime);
    event IncreaseAmount(address indexed user, uint256 veTokenId, uint256 amount);
    event ClaimVeEmissions(address indexed user, uint256 veTokenId, uint256 amount);
    event ClaimOwnerRewards(address indexed user, address[] tokenVote, address[][] tokens);
    event Merge(address indexed user, uint256 fromId, uint256 toId, uint256 amount);
    event TransferVeToken(address indexed user, address to, uint256 veTokenId);

    constructor(
        string memory _name,
        string memory _symbol,
        address _voter,
        address _treasury,
        address _rewardPool,
        address _keeper,
        address _beefyVoter
    ) public ERC20(
        _name,
        _symbol
    ) {
        voter = IVoter(_voter);
        veToken = IVeToken(voter._ve());
        want = IERC20(veToken.token());
        IMinter _minter = IMinter(voter.minter());
        veDist = IVeDist(_minter._ve_dist());
        treasury = _treasury;
        rewardPool = _rewardPool;
        keeper = _keeper;
        beefyVoter = _beefyVoter;

        want.safeApprove(address(veToken), uint256(-1));
        want.safeApprove(address(voter), uint256(-1));
    }

    function setVeTokenId(uint256 _veTokenId) external onlyManager {
        require(_veTokenId == 0 || veToken.ownerOf(_veTokenId) == address(this), "!veTokenId");
        veTokenId = _veTokenId;
    }

    function setVeDist(address _veDist) external onlyOwner {
        veDist = IVeDist(_veDist);
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setRewardPool(address _rewardPool) external onlyOwner {
        rewardPool = _rewardPool;
    }

    function setKeeper(address _keeper) external onlyManager {
        keeper = _keeper;
    }

    function setBeefyVoter(address _beefyVoter) external onlyManager {
        beefyVoter = _beefyVoter;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the manager.
    function add(address _poolToken, address[] memory _rewards) public onlyManager {
        require(isExistingPool[_poolToken] == false, "pool already exists");

        address _gauge = voter.gauges(_poolToken);
        if (_gauge == address(0)) {
            _gauge = voter.createGauge(_poolToken);
        }

        poolInfo.push(PoolInfo({
            lpToken: IERC20(_poolToken),
            gauge: IGauge(_gauge),
            bribe: IBribe(voter.bribes(_gauge)),
            totalDepositedAmount: 0,
            lastRewardTime: block.timestamp,
            rewards: _rewards
        }));

        IERC20(_poolToken).safeApprove(_gauge, uint256(-1));
        isExistingPool[_poolToken] = true;
    }

    // Set rewards for the pool.
    function set(uint256 _pid, address[] memory _rewards) public onlyManager {
        poolInfo[_pid].rewards = _rewards;
    }

    // View function to see pending reward.
    function pendingReward(address _user, uint256 _pid) external view returns (address[] memory, uint256[] memory) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256[] memory _amounts;

        for (uint256 i; i < pool.rewards.length; i++) {
            address _reward = pool.rewards[i];
            uint256 _rewardBal = pool.gauge.earned(_reward, address(this));
            if (_rewardBal > 0) {
                uint256 _accRewardPerShare = pool.accRewardPerShare[_reward];
                _accRewardPerShare = _accRewardPerShare.add((_rewardBal.mul(1e18).div(pool.totalDepositedAmount)));
                _amounts[i] = user.amount
                    .mul(_accRewardPerShare)
                    .div(1e18)
                    .sub(user.rewardDebt[_reward]);
            }
        }

        return (pool.rewards, _amounts);
    }

    // Update reward variables of the given pool to be up-to-date.
    function _updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];

        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        if (pool.totalDepositedAmount == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }

        pool.gauge.getReward(address(this), pool.rewards);
        for (uint256 i; i < pool.rewards.length; i++) {
            address _reward = pool.rewards[i];
            uint256 _rewardBal = IERC20(_reward).balanceOf(address(this)).sub(storedRewardBalance[_reward]);

            pool.accRewardPerShare[_reward] = pool.accRewardPerShare[_reward]
                .add((_rewardBal.mul(1e18).div(pool.totalDepositedAmount)));
            storedRewardBalance[_reward] = storedRewardBalance[_reward].add(_rewardBal);
        }

        pool.lastRewardTime = block.timestamp;
    }

    // Deposit tokens.
    function deposit(uint256 _pid, uint256 _amount) external whenNotPaused nonReentrant {
        require(veTokenId > 0, "!veTokenId");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        _updatePool(_pid);
        if (user.amount > 0) {
            _sendRewards(pool, user);
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
            user.amount = user.amount.add(_amount);
            pool.totalDepositedAmount = pool.totalDepositedAmount.add(_amount);
            pool.gauge.deposit(_amount, veTokenId);
        }
        _updateUserRewardDebt(pool, user);

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw tokens.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw not good");

        _updatePool(_pid);
        _sendRewards(pool, user);
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalDepositedAmount = pool.totalDepositedAmount.sub(_amount);
            pool.gauge.withdraw(_amount);
            pool.lpToken.safeTransfer(msg.sender, _amount);
        }
        _updateUserRewardDebt(pool, user);

        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        pool.gauge.withdraw(user.amount);
        pool.lpToken.safeTransfer(msg.sender, user.amount);
        pool.totalDepositedAmount = pool.totalDepositedAmount.sub(user.amount);
        user.amount = 0;

        for (uint256 i; i < pool.rewards.length; i++) {
            address _reward = pool.rewards[i];
            user.rewardDebt[_reward] = 0;
        }

        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    }

    function _sendRewards(PoolInfo storage _pool, UserInfo storage _user) internal {
        for (uint256 i; i < _pool.rewards.length; i++) {
            address _reward = _pool.rewards[i];

            uint256 _pending = _user.amount
                .mul(_pool.accRewardPerShare[_reward])
                .div(1e18)
                .sub(_user.rewardDebt[_reward]);

            if (_pending > 0) {
                safeTransfer(IERC20(_reward), msg.sender, _pending);
                storedRewardBalance[_reward] = storedRewardBalance[_reward] > _pending
                    ? storedRewardBalance[_reward].sub(_pending)
                    : 0;
            }
        }
    }

    function _updateUserRewardDebt(PoolInfo storage _pool, UserInfo storage _user) internal {
        for (uint256 i; i < _pool.rewards.length; i++) {
            address _reward = _pool.rewards[i];
            _user.rewardDebt[_reward] = _user.amount.mul(_pool.accRewardPerShare[_reward]).div(1e18);
        }
    }

    // pause deposits to gauges
    function pause() public onlyManager {
        _pause();
    }

    // unpause deposits to gauges
    function unpause() external onlyManager {
        _unpause();
    }

    // claim veToken emissions and increases locked amount in veToken
    function claimVeEmissions() external {
        uint256 _amount = veDist.claim(veTokenId);
        emit ClaimVeEmissions(msg.sender, veTokenId, _amount);
    }

    // vote for emission weights
    function vote(
        uint256 _veTokenId,
        address[] memory _tokenVote,
        int256[] memory _weights
    ) external onlyVoter {
        voter.vote(_veTokenId, _tokenVote, _weights);
    }

    // reset current votes
    function resetVote(uint256 _veTokenId) external onlyVoter {
        voter.reset(_veTokenId);
    }

    // claim owner rewards such as trading fees and bribes from gauges, transferred to rewardPool
    function claimOwnerRewards(
        uint256 _veTokenId,
        address[] memory _tokenVote,
        address[][] memory _tokens
    ) external onlyVoter {
        address[] memory _bribes;
        for (uint256 i; i < _tokenVote.length; i++) {
            _bribes[i] = voter.bribes(_tokenVote[i]);
            IBaseV1Pair(_tokenVote[i]).claimFees();
        }
        voter.claimBribes(_bribes, _tokens, _veTokenId);

        for (uint256 i; i < _tokens.length; i++) {
            for (uint256 j; j < _tokens[i].length; j++) {
                address _reward = _tokens[i][j];
                uint256 _rewardBal = IERC20(_reward).balanceOf(address(this)).sub(storedRewardBalance[_reward]);
                if (_rewardBal > 0) {
                    IERC20(_reward).safeTransfer(rewardPool, _rewardBal);
                }
            }
        }

        emit ClaimOwnerRewards(msg.sender, _tokenVote, _tokens);
    }

    // create a new veToken if none is assigned to this address
    function createLock(uint256 _amount, uint256 _lock_duration) external onlyManager {
        require(veTokenId == 0, "veToken > 0");
        require(_amount > 0, "amount == 0");

        want.safeTransferFrom(address(msg.sender), address(this), _amount);
        veTokenId = veToken.create_lock(_amount, _lock_duration);

        emit CreateLock(msg.sender, veTokenId, _amount, _lock_duration);
    }

    // release expired lock of a non-main veToken owned by this address and transfer want token to treasury
    function release(uint256 _veTokenId) external onlyManager {
        require(_veTokenId > 0 && veTokenId != _veTokenId, "!veTokenId");

        veToken.withdraw(_veTokenId);
        uint256 _wantBal = want.balanceOf(address(this)).sub(storedRewardBalance[address(want)]);
        safeTransfer(want, treasury, _wantBal);

        emit Release(msg.sender, _veTokenId, _wantBal);
    }

    // manager can merge veTokens owned by this contract
    function mergeManager(uint256 _fromId) external onlyManager {
        require(veToken.ownerOf(_fromId) == address(this), "!veToken owner");
        _merge(msg.sender, _fromId);
    }

    // merge veToken with the main veToken on this contract to mint reward
    function merge(uint256 _fromId) external {
        require(veToken.isApprovedOrOwner(msg.sender, _fromId), "!veToken owner or approved");
        _merge(msg.sender, _fromId);
    }

    // merge veToken with the main veToken on this contract to mint reward for another user
    function mergeFor(address _user, uint256 _fromId) external {
        require(veToken.isApprovedOrOwner(msg.sender, _fromId), "!veToken owner or approved");
        _merge(_user, _fromId);
    }

    // merge voting power of two veTokens by burning the _from veToken, _from must be detached and not voted with
    // reward token is minted to specified user
    function _merge(address _user, uint256 _fromId) internal nonReentrant {
        (uint256 _amount,) = veToken.locked(_fromId);
        veToken.merge(_fromId, veTokenId);
        _mint(_user, _amount);

        emit Merge(msg.sender, _fromId, veTokenId, _amount);
    }

    // extend lock time for veToken to increase voting power
    function increaseUnlockTime(uint256 _lock_duration) external onlyManager {
        uint256 maxTime = 4 * 365 * 86400;
        _lock_duration = _lock_duration > maxTime ? maxTime : _lock_duration;
        veToken.increase_unlock_time(veTokenId, _lock_duration);

        emit IncreaseTime(msg.sender, veTokenId, _lock_duration);
    }

    // deposit an amount of want
    function deposit(uint256 _amount) external {
        _deposit(msg.sender, _amount);
    }

    // deposit an amount of want token on behalf of an address
    function depositFor(address _user, uint256 _amount) external {
        _deposit(_user, _amount);
    }

    // transfer an amount of want token to this address and lock into veToken
    function _deposit(address _user, uint256 _amount) internal whenNotPaused nonReentrant {
        want.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 wantBal = want.balanceOf(address(this)).sub(storedRewardBalance[address(want)]);

        if (_amount > wantBal) {
            _amount = wantBal;
        }

        veToken.increase_amount(veTokenId, _amount);
        _mint(_user, _amount);

        emit IncreaseAmount(msg.sender, veTokenId, _amount);
    }

    // whitelist new token
    function whitelist(address _token) external onlyManager {
        uint256 _fee = voter.listing_fee();
        if (veToken.balanceOfNFT(veTokenId) <= _fee) {
            want.safeTransferFrom(msg.sender, address(this), _fee);
        }
        voter.whitelist(_token, veTokenId);
    }

    // detach veToken from many gauges
    function withdrawVeTokenFromGauges(uint256[] memory _pids, uint256 _veTokenId) public onlyManager {
        for (uint256 i; i < _pids.length; i++) {
            _updatePool(_pids[i]);
            PoolInfo storage pool = poolInfo[_pids[i]];
            pool.gauge.withdrawToken(0, _veTokenId);
        }
    }

    // transfer veToken to another address, must be detached from all gauges first
    function transferVeToken(address _to, uint256 _veTokenId) external onlyOwner {
        if (veTokenId == _veTokenId) {
            veTokenId = 0;
        }
        veToken.safeTransferFrom(address(this), _to, _veTokenId);

        emit TransferVeToken(msg.sender, _to, _veTokenId);
    }

    // Safe erc20 transfer function, just in case if rounding error causes pool to not have enough reward tokens.
    function safeTransfer(IERC20 token, address _to, uint256 _amount) internal {
        uint256 bal = token.balanceOf(address(this));
        if (_amount > bal) {
            token.safeTransfer(_to, bal);
        } else {
            token.safeTransfer(_to, _amount);
        }
    }

    // confirmation required for receiving veToken to smart contract
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external view returns (bytes4) {
        operator;
        from;
        tokenId;
        data;
        require(msg.sender == address(veToken), "!veToken");
        return bytes4(keccak256("onERC721Received(address,address,uint,bytes)"));
    }
}