/**
 *Submitted for verification at FtmScan.com on 2023-07-05
*/

/**
 *Submitted for verification at BscScan.com on 2022-07-31
*/

/**
 *Submitted for verification at BscScan.com on 2022-06-12
*/

/**
 *Submitted for verification at BNBScan.com on 2021-10-11
*/

// FastYield Dev Team
    // File contracts/helpers/Context.sol

    // SPDX-License-Identifier: MIT

    pragma solidity 0.6.12;

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol
    abstract contract Context {
        function _msgSender() internal view virtual returns (address payable) {
            return msg.sender;
        }

        function _msgData() internal view virtual returns (bytes memory) {
            this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
            return msg.data;
        }
    }

    // File contracts/helpers/Ownable.sol

    pragma solidity 0.6.12;
    // import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
    abstract contract Ownable is Context {
        address private _owner;

        event OwnershipTransferred(
            address indexed previousOwner,
            address indexed newOwner
        );

        /**
         * @dev Initializes the contract setting the deployer as the initial owner.
         */
        constructor() internal {
            address msgSender = _msgSender();
            _owner = msgSender;
            emit OwnershipTransferred(address(0), msgSender);
        }

        /**
         * @dev Returns the address of the current owner.
         */
        function owner() public view returns (address) {
            return _owner;
        }

        /**
         * @dev Throws if called by any account other than the owner.
         */
        modifier onlyOwner() {
            require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
            require(
                newOwner != address(0),
                "Ownable: new owner is the zero address"
            );
            emit OwnershipTransferred(_owner, newOwner);
            _owner = newOwner;
        }
    }

    // File contracts/helpers/Pausable.sol

    pragma solidity 0.6.12;
    // "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Pausable.sol";
    contract Pausable is Context {
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
        constructor() internal {
            _paused = false;
        }

        /**
         * @dev Returns true if the contract is paused, and false otherwise.
         */
        function paused() public view returns (bool) {
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
            require(!_paused, "Pausable: paused");
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
            require(_paused, "Pausable: not paused");
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

    // File contracts/helpers/ReentrancyGuard.sol

    pragma solidity 0.6.12;

    // "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol";
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

        constructor() internal {
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

    // File contracts/interfaces/IERC20.sol

    pragma solidity ^0.6.12;

    // import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
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
        function transfer(address recipient, uint256 amount)
            external
            returns (bool);

        /**
         * @dev Returns the remaining number of tokens that `spender` will be
         * allowed to spend on behalf of `owner` through {transferFrom}. This is
         * zero by default.
         *
         * This value changes when {approve} or {transferFrom} are called.
         */
        function allowance(address owner, address spender)
            external
            view
            returns (uint256);

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
        event Approval(
            address indexed owner,
            address indexed spender,
            uint256 value
        );
    }

    // File contracts/libraries/SafeMath.sol

    pragma solidity ^0.6.12;

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
    library SafeMath {
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
            return sub(a, b, "SafeMath: subtraction overflow");
        }

        /**
         * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
         * overflow (when the result is negative).
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
            uint256 c = a - b;

            return c;
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
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) {
                return 0;
            }

            uint256 c = a * b;
            require(c / a == b, "SafeMath: multiplication overflow");

            return c;
        }

        /**
         * @dev Returns the integer division of two unsigned integers. Reverts on
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
            return div(a, b, "SafeMath: division by zero");
        }

        /**
         * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        function div(
            uint256 a,
            uint256 b,
            string memory errorMessage
        ) internal pure returns (uint256) {
            require(b > 0, errorMessage);
            uint256 c = a / b;
            // assert(a == b * c + a % b); // There is no case in which this doesn't hold

            return c;
        }

        /**
         * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
         * Reverts when dividing by zero.
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
            return mod(a, b, "SafeMath: modulo by zero");
        }

        /**
         * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
         * Reverts with custom message when dividing by zero.
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
            require(b != 0, errorMessage);
            return a % b;
        }
    }

    // File contracts/libraries/Address.sol

    pragma solidity 0.6.12;

    // import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/SafeERC20.sol";
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
            assembly {
                size := extcodesize(account)
            }
            return size > 0;
        }

        /**
         * @dev Converts an `address` into `address payable`. Note that this is
         * simply a type cast: the actual underlying value is not changed.
         *
         * _Available since v2.4.0._
         */
        function toPayable(address account)
            internal
            pure
            returns (address payable)
        {
            return address(uint160(account));
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
            require(
                address(this).balance >= amount,
                "Address: insufficient balance"
            );

            // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
            (bool success, ) = recipient.call{value: amount}("");
            require(
                success,
                "Address: unable to send value, recipient may have reverted"
            );
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
        function functionCall(address target, bytes memory data)
            internal
            returns (bytes memory)
        {
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
            return
                functionCallWithValue(
                    target,
                    data,
                    value,
                    "Address: low-level call with value failed"
                );
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
            require(
                address(this).balance >= value,
                "Address: insufficient balance for call"
            );
            require(isContract(target), "Address: call to non-contract");

            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory returndata) =
                target.call{value: value}(data);
            return _verifyCallResult(success, returndata, errorMessage);
        }

        /**
         * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
         * but performing a static call.
         *
         * _Available since v3.3._
         */
        function functionStaticCall(address target, bytes memory data)
            internal
            view
            returns (bytes memory)
        {
            return
                functionStaticCall(
                    target,
                    data,
                    "Address: low-level static call failed"
                );
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

        /**
         * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
         * but performing a delegate call.
         *
         * _Available since v3.3._
         */
        function functionDelegateCall(address target, bytes memory data)
            internal
            returns (bytes memory)
        {
            return
                functionDelegateCall(
                    target,
                    data,
                    "Address: low-level delegate call failed"
                );
        }

        /**
         * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
         * but performing a delegate call.
         *
         * _Available since v3.3._
         */
        function functionDelegateCall(
            address target,
            bytes memory data,
            string memory errorMessage
        ) internal returns (bytes memory) {
            require(isContract(target), "Address: delegate call to non-contract");

            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory returndata) = target.delegatecall(data);
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

    // File contracts/libraries/SafeERC20.sol

    pragma solidity 0.6.12;
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

        function safeTransfer(
            IERC20 token,
            address to,
            uint256 value
        ) internal {
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(token.transfer.selector, to, value)
            );
        }

        function safeTransferFrom(
            IERC20 token,
            address from,
            address to,
            uint256 value
        ) internal {
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
            );
        }

        /**
         * @dev Deprecated. This function has issues similar to the ones found in
         * {IERC20-approve}, and its usage is discouraged.
         *
         * Whenever possible, use {safeIncreaseAllowance} and
         * {safeDecreaseAllowance} instead.
         */
        function safeApprove(
            IERC20 token,
            address spender,
            uint256 value
        ) internal {
            // safeApprove should only be called when setting an initial allowance,
            // or when resetting it to zero. To increase and decrease it, use
            // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
            // solhint-disable-next-line max-line-length
            require(
                (value == 0) || (token.allowance(address(this), spender) == 0),
                "SafeERC20: approve from non-zero to non-zero allowance"
            );
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(token.approve.selector, spender, value)
            );
        }

        function safeIncreaseAllowance(
            IERC20 token,
            address spender,
            uint256 value
        ) internal {
            uint256 newAllowance =
                token.allowance(address(this), spender).add(value);
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }

        function safeDecreaseAllowance(
            IERC20 token,
            address spender,
            uint256 value
        ) internal {
            uint256 newAllowance =
                token.allowance(address(this), spender).sub(
                    value,
                    "SafeERC20: decreased allowance below zero"
                );
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

            bytes memory returndata =
                address(token).functionCall(
                    data,
                    "SafeERC20: low-level call failed"
                );
            if (returndata.length > 0) {
                // Return data is optional
                // solhint-disable-next-line max-line-length
                require(
                    abi.decode(returndata, (bool)),
                    "SafeERC20: ERC20 operation did not succeed"
                );
            }
        }
    }

    // File contracts/interfaces/IJetSwapPair.sol

    pragma solidity >=0.6.12;

    interface IJetSwapPair {
        event Approval(address indexed owner, address indexed spender, uint value);
        event Transfer(address indexed from, address indexed to, uint value);

        function name() external pure returns (string memory);
        function symbol() external pure returns (string memory);
        function decimals() external pure returns (uint8);
        function totalSupply() external view returns (uint);
        function balanceOf(address owner) external view returns (uint);
        function allowance(address owner, address spender) external view returns (uint);

        function approve(address spender, uint value) external returns (bool);
        function transfer(address to, uint value) external returns (bool);
        function transferFrom(address from, address to, uint value) external returns (bool);

        function DOMAIN_SEPARATOR() external view returns (bytes32);
        function PERMIT_TYPEHASH() external pure returns (bytes32);
        function nonces(address owner) external view returns (uint);

        function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

        event Mint(address indexed sender, uint amount0, uint amount1);
        event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
        event Swap(
            address indexed sender,
            uint amount0In,
            uint amount1In,
            uint amount0Out,
            uint amount1Out,
            address indexed to
        );
        event Sync(uint112 reserve0, uint112 reserve1);

        function MINIMUM_LIQUIDITY() external pure returns (uint);
        function factory() external view returns (address);
        function token0() external view returns (address);
        function token1() external view returns (address);
        function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
        function price0CumulativeLast() external view returns (uint);
        function price1CumulativeLast() external view returns (uint);
        function kLast() external view returns (uint);

        function mint(address to) external returns (uint liquidity);
        function burn(address to) external returns (uint amount0, uint amount1);
        function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
        function skim(address to) external;
        function sync() external;

        function initialize(address, address) external;
    }

    // File contracts/interfaces/IXRouter01.sol

    pragma solidity 0.6.12;

    interface IXRouter01 {
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

        function getAmountsOut(uint256 amountIn, address[] calldata path)
            external
            view
            returns (uint256[] memory amounts);

        function getAmountsIn(uint256 amountOut, address[] calldata path)
            external
            view
            returns (uint256[] memory amounts);
    }

    // File contracts/interfaces/IXRouter02.sol

    pragma solidity 0.6.12;
    interface IXRouter02 is IXRouter01 {
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

    // File contracts/Zappy.sol

    pragma solidity ^0.6.12;
    interface IWBNB is IERC20 {
        function deposit() external payable;
        function withdraw(uint256 wad) external;
    }

    pragma solidity ^0.6.12;
    interface IVault is IERC20 {
        function deposit(uint256 _pid, uint256 _wantAmt, address _user) external payable;
    }

    contract SwampZap is ReentrancyGuard, Ownable, Pausable {
        using SafeMath for uint256;
        using SafeERC20 for IERC20;

        address private constant wbnbAddress = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
        //0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
        address private constant busd = 0x740640C19d8e544eCcf099db1B4514f91a9C602A;
        //0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
        address public feeWallet = 0x6A93f56627306371D87Fd520b7E8Cc6dBdDE4296;
        //0x2add64A6077Aa946282Da263a839Dd0caA0D1668
       
        uint256 public fee = 0;
        uint256 routerDeadlineDuration = 300;

        constructor() public {
        }

        receive() external payable {}

        modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
        }


        function zapIn(
            address _fromTokenAddress,
            uint256 _amountIn,
            address _lpAddress,
            uint256 poolId,
            address[] memory _token0Path,
            address[] memory _token1Path,
            // address _token0RouterAddress,
            // address _token1RouterAddress,
            address _LPRouterAddress,
            address vaultAddress
        ) external payable nonReentrant whenNotPaused notContract {
            uint256 halfAmount = _pullTokens(
                _fromTokenAddress,
                _amountIn
            ).div(2);
            
            if (_fromTokenAddress == address(0)) {
                _wrapBNB();
                _fromTokenAddress = wbnbAddress;
            }

            IJetSwapPair pair = IJetSwapPair(_lpAddress);

            uint256 token0Amt; uint256 token1Amt;
            if (pair.token0() != _fromTokenAddress)
                token0Amt = _safeSwap(_LPRouterAddress, _fromTokenAddress, halfAmount, _token0Path, address(this));
            else
                token0Amt = halfAmount;

            if (pair.token1() != _fromTokenAddress)
                token1Amt = _safeSwap(_LPRouterAddress, _fromTokenAddress, halfAmount, _token1Path, address(this));
            else 
                token1Amt = halfAmount;

            _approveTokenIfNeeded(pair.token0(), _LPRouterAddress);
            _approveTokenIfNeeded(pair.token1(), _LPRouterAddress);
            ( , , uint256 LPBought) = IXRouter02(_LPRouterAddress).addLiquidity(
                pair.token0(),
                pair.token1(),
                token0Amt,
                token1Amt,
                1,
                1,
                address(this),  
                now + routerDeadlineDuration
            );

            require(LPBought >= 0, "ERR: High Slippage");
            uint lprecieve = IERC20(_lpAddress).balanceOf(address(this));
            
            if (lprecieve > 0) {
                if (IERC20(_lpAddress).allowance(address(this), vaultAddress) == 0) {
                    IERC20(_lpAddress).safeApprove(vaultAddress, uint256(- 1));
                }
                IVault(vaultAddress).deposit(poolId, lprecieve, msg.sender); 
                // uint share = IERC20(vaultAddress).balanceOf(address(this));
                // require (share > 0, "err: something wrong ");
                // IERC20(vaultAddress).safeTransfer(msg.sender, share);
            }

            // send remaining bnb and busd to fee wallet
            uint bnbbal = IERC20(wbnbAddress).balanceOf(address(this));
            uint busdbal = IERC20(busd).balanceOf(address(this));

            if (bnbbal>0) {
                IERC20(wbnbAddress).safeTransfer(feeWallet, bnbbal);
            }
            if (busdbal>0) {
                IERC20(busd).safeTransfer(feeWallet, busdbal);
            }

            uint token0bal = IERC20(pair.token0()).balanceOf(address(this));
            uint token1bal = IERC20(pair.token1()).balanceOf(address(this));

            if (token0bal>0) {
                IERC20(pair.token0()).safeTransfer(feeWallet, token0bal);
            }
            if (token1bal>0) {
                IERC20(pair.token1()).safeTransfer(feeWallet, token1bal);
            }
        }

        function _pullWrapAndSwapSingle(
            address _fromTokenAddress,
            address _token,
            uint256 _amountIn,
            address _LPRouterAddress,
            address[] memory token0Path
        ) internal returns (uint256 amount) {
            amount = _pullTokens(
                _fromTokenAddress,
                _amountIn
            );
            
            if (_fromTokenAddress == address(0)) {
                _wrapBNB();
                _fromTokenAddress = wbnbAddress;
            }

            if (_token != _fromTokenAddress)
                return _safeSwap(_LPRouterAddress, _fromTokenAddress, amount, token0Path, address(this));
            else
                return amount;
        }

        function _pullTokens(
            address token,
            uint256 amount
        ) internal returns (uint256 value) {
            uint256 totalfeePortion;

            if (token == address(0)) {
                require(msg.value > 0, "No eth sent");

                // subtract fee
                totalfeePortion = _subtractfee(msg.value);

                return msg.value.sub(totalfeePortion);
            } else {
                require(amount > 0, "Invalid token amount");
                require(msg.value == 0, "BNB sent with token");

                IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

                totalfeePortion = _subtractfee(amount);

                return amount.sub(totalfeePortion);
            }
        }

        function _subtractfee(uint256 amount) internal view returns (uint256 totalfeePortion) {
            if (fee > 0) {
                totalfeePortion = amount.mul(fee).div(10000);
            }
        }

        function _safeSwap(
            address _routerAddress,
            address _from,
            uint256 _amountIn,
            address[] memory _path,
            address _recipient
        ) private returns (uint256) {
            _approveTokenIfNeeded(_from, _routerAddress);
            uint256 amount;

            // if (_from == address(0)) {
            //     amounts = IXRouter02(_routerAddress)
            //                 .swapExactETHForTokensSupportingFeeOnTransferTokens{value : _amountIn}(
            //         0,
            //         _path,
            //         _recipient,
            //         now + routerDeadlineDuration
            //     )[_path.length - 1];
            // } else {

            amount = IXRouter02(_routerAddress).swapExactTokensForTokens(
                _amountIn,
                0,
                _path,
                _recipient,
                now + routerDeadlineDuration
            )[_path.length - 1];
            
            return amount;
        }

        function _approveTokenIfNeeded(address token, address _routerAddress) private {
            if (IERC20(token).allowance(address(this), _routerAddress) == 0) {
                IERC20(token).safeApprove(_routerAddress, uint256(- 1));
            }
        }

        function _wrapBNB() internal {
            uint256 BNBBal = address(this).balance;
            if (BNBBal > 0) {
                IWBNB(wbnbAddress).deposit{value: BNBBal}(); // BNB -> WBNB
            }
        }

        function setfee(uint16 _fee) public onlyOwner {
            // require(
            //     _fee >= 0 && _fee <= 100,
            //     "Invalid fee value"
            // );
            fee = _fee;
        }

        function setfeeWallet(address _newwallet) external onlyOwner {
            feeWallet = _newwallet;
        }

        function withdrawTokens(address[] calldata tokens) external onlyOwner {
            for (uint256 i = 0; i < tokens.length; i++) {
                uint256 qty;

                if (tokens[i] == address(0)) {
                    qty = address(this).balance;
                    Address.sendValue(Address.toPayable(owner()), qty);
                } else {
                    qty = IERC20(tokens[i]).balanceOf(address(this));
                    IERC20(tokens[i]).safeTransfer(owner(), qty);
                }
            }
        }

        function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
    }

    //0x0000000000000000000000000000000000000000
    //