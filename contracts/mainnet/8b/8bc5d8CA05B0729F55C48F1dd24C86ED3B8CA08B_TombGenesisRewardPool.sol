/**
 *Submitted for verification at FtmScan.com on 2022-08-26
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}




////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * ////IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}




////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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




////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}




////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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




////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

////import "../IERC20.sol";
////import "../extensions/draft-IERC20Permit.sol";
////import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
////import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
////import "../interfaces/IUniswapV2Router.sol";

interface IFeeManager {
    function manageFees(IERC20 _token, uint256 _amount) external;
}

// Note that this pool has no minter key of Tomb (rewards).
// Instead, the governance will call Tomb distributeReward method and send reward to this pool at the beginning.
contract TombGenesisRewardPool is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // governance
    address public operator;

    address public guardian;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardDebt; // Deposit debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Tomb to distribute.
        uint256 lastRewardTime; // Last time that Tomb distribution occurs.
        uint256 accTombPerShare; // Accumulated Tomb per share, times 1e18. See below.
        uint256 depositFee;
        uint256 totalDeposited;
        bool isStarted; // if lastRewardBlock has passed
        bool isTombLp;
        address[] path;
    }

    IERC20 public immutable tomb;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The time when Tomb mining starts.
    uint256 public poolStartTime;

    // The time when Tomb mining ends.
    uint256 public poolEndTime;

    IFeeManager public feeManager;

    bool public compoundEnabled = false;
    bool public secondPhaseEnabled = false;

    uint256 public constant TOTAL_REWARDS_PHASE_ONE = 56000 ether;
    uint256 public constant TOTAL_REWARDS_PHASE_TWO = 84000 ether;
    uint256 public TOTAL_REWARDS = TOTAL_REWARDS_PHASE_ONE;
    uint256 public constant RUNNING_TIME = 4 days;
    uint256 public TOMB_PER_SECOND = TOTAL_REWARDS / (RUNNING_TIME / 2);
    uint256 public constant MAX_DEPOSIT_FEE = 100; // 1% (default 0.5%)

    IUniswapV2Router public immutable router;
    IERC20 public immutable WETH;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event RewardPaid(address indexed user, uint256 amount);

    error RouterAddressZero();
    error TombAddressZero();
    error FeeManagerIsAddressZero();
    error NewOperatorIsAddressZero();
    error StartTimeTooLate(uint256 _blocktimestamp, uint256 _startTime);
    error GenesisAlreadyStarted(uint256 _blocktimestamp, uint256 _startTime);
    error CallerIsNotOperator(address _caller);
    error PoolPathIsWrong();
    error PoolAlreadyExists(address _token);
    error DepositFeeTooHigh(uint256 _fee);
    error OnlyTombLpAllowed();
    error WithdrawNotGood(uint256 _userAmount, uint256 _amountToWithdraw);
    error GovernanceRecoverTooSoon(uint256 _currentTime, uint256 _limit);
    error NotStartedYet();

    receive() external payable {}

    constructor(
        address _Tomb,
        address _feeManagerAddr,
        address _router
    ) {
        if (_router == address(0)) revert RouterAddressZero();
        if (_Tomb == address(0)) revert TombAddressZero();
        if (_feeManagerAddr == address(0)) revert FeeManagerIsAddressZero();

        tomb = IERC20(_Tomb);
        feeManager = IFeeManager(_feeManagerAddr);

        //
        poolStartTime = 365 days;
        poolEndTime = 365 days + RUNNING_TIME;
        operator = msg.sender;
        guardian = msg.sender;
        router = IUniswapV2Router(_router);
        WETH = IERC20(IUniswapV2Router(_router).WETH());
    }

    modifier onlyOperator() {
        if (operator != msg.sender) revert CallerIsNotOperator(msg.sender);
        _;
    }

    function checkPoolDuplicate(IERC20 _token) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            if (poolInfo[pid].token == _token)
                revert PoolAlreadyExists(address(_token));
        }
    }

    function setStart(uint256 _poolStartTime) external {
        if (msg.sender != guardian) revert CallerIsNotOperator(msg.sender);

        if (block.timestamp >= poolStartTime)
            revert GenesisAlreadyStarted(block.timestamp, _poolStartTime);

        if (block.timestamp >= _poolStartTime)
            revert StartTimeTooLate(block.timestamp, _poolStartTime);

        poolStartTime = _poolStartTime;
        poolEndTime = _poolStartTime + RUNNING_TIME;

        massUpdatePools();
    }

    // Add a new pool. Can only be called by the owner.
    // @ _allocPoint - amount of Tomb this pool will emit
    // @ _token - token that can be deposited into this pool
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        bool _withUpdate,
        uint256 _lastRewardTime,
        uint256 _depositFee,
        bool _isTombLp,
        address[] memory _path
    ) public onlyOperator {
        if (_depositFee > MAX_DEPOSIT_FEE)
            revert DepositFeeTooHigh(_depositFee);

        if (!_isTombLp && _path.length < 2) revert PoolPathIsWrong();

        checkPoolDuplicate(_token);

        if (_withUpdate) {
            massUpdatePools();
        }

        bool _isStarted = false;

        if (poolStartTime > 0) {
            if (block.timestamp < poolStartTime) {
                // chef is sleeping
                if (_lastRewardTime == 0) {
                    _lastRewardTime = poolStartTime;
                } else {
                    if (_lastRewardTime < poolStartTime) {
                        _lastRewardTime = poolStartTime;
                    }
                }
            } else {
                // chef is cooking
                if (_lastRewardTime == 0 || _lastRewardTime < block.timestamp) {
                    _lastRewardTime = block.timestamp;
                }
            }
            _isStarted =
                (_lastRewardTime <= poolStartTime) ||
                (_lastRewardTime <= block.timestamp);
        }

        poolInfo.push(
            PoolInfo({
                token: _token,
                allocPoint: _allocPoint,
                lastRewardTime: _lastRewardTime,
                accTombPerShare: 0,
                isStarted: _isStarted,
                depositFee: _depositFee,
                totalDeposited: 0,
                isTombLp: _isTombLp,
                path: _path
            })
        );
        if (_isStarted) {
            totalAllocPoint += _allocPoint;
        }
    }

    // Update the given pool's Tomb allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint256 _depositFee
    ) public {
        if (msg.sender != operator && msg.sender != guardian)
            revert CallerIsNotOperator(msg.sender);

        if (_depositFee > MAX_DEPOSIT_FEE)
            revert DepositFeeTooHigh(_depositFee);

        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.isStarted && pool.allocPoint != _allocPoint) {
            totalAllocPoint -= pool.allocPoint;
            totalAllocPoint += _allocPoint;
        }
        pool.allocPoint = _allocPoint;
        pool.depositFee = _depositFee;
    }

    // Return accumulate rewards over the given _from to _to block.
    function getGeneratedReward(uint256 _fromTime, uint256 _toTime)
        public
        view
        returns (uint256)
    {
        if (_fromTime >= _toTime) return 0;

        if (_toTime >= poolEndTime) {
            if (_fromTime >= poolEndTime) return 0;

            if (_fromTime <= poolStartTime)
                return (poolEndTime - poolStartTime) * TOMB_PER_SECOND;

            return (poolEndTime - _fromTime) * TOMB_PER_SECOND;
        } else {
            if (_toTime <= poolStartTime) return 0;

            if (_fromTime <= poolStartTime)
                return (_toTime - poolStartTime) * TOMB_PER_SECOND;

            return (_toTime - _fromTime) * TOMB_PER_SECOND;
        }
    }

    // View function to see pending Tomb on frontend.
    function pendingTomb(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTombPerShare = pool.accTombPerShare;
        uint256 tokenSupply = pool.totalDeposited;
        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = getGeneratedReward(
                pool.lastRewardTime,
                block.timestamp
            );
            uint256 _multiplyHelper = _generatedReward * pool.allocPoint; // intermidiate var to avoid multiply and division calc errors
            uint256 _TombReward = _multiplyHelper / totalAllocPoint;
            accTombPerShare += (_TombReward * 1e18) / tokenSupply;
        }

        return ((user.amount * accTombPerShare) / 1e18) - user.rewardDebt;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) private {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 tokenSupply = pool.totalDeposited;
        if (tokenSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        if (!pool.isStarted) {
            pool.isStarted = true;
            totalAllocPoint += pool.allocPoint;
        }
        if (totalAllocPoint > 0) {
            uint256 _generatedReward = getGeneratedReward(
                pool.lastRewardTime,
                block.timestamp
            );
            uint256 multiplyHelper = _generatedReward * pool.allocPoint;
            uint256 _TombReward = multiplyHelper / totalAllocPoint;
            pool.accTombPerShare += (_TombReward * 1e18) / tokenSupply;
        }
        pool.lastRewardTime = block.timestamp;
    }

    // Deposit tokens.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        _deposit(msg.sender, _pid, _amount, false);
    }

    function _deposit(
        address _user,
        uint256 _pid,
        uint256 _amount,
        bool isCompound
    ) internal {
        address _sender = _user;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        updatePool(_pid);
        if (user.amount > 0) {
            // transfer rewards to user if any pending rewards
            uint256 _pending = ((user.amount * pool.accTombPerShare) / 1e18) -
                user.rewardDebt;
            if (_pending > 0) {
                // send pending reward to user, if rewards accumulating in _pending
                safeTombTransfer(_sender, _pending);
                emit RewardPaid(_sender, _pending);
            }
        }
        if (_amount > 0) {
            if (!isCompound) {
                uint256 _before = pool.token.balanceOf(address(this));
                pool.token.safeTransferFrom(_sender, address(this), _amount);
                uint256 _after = pool.token.balanceOf(address(this));

                _amount = _after - _before;
            }

            uint256 _feeAmount = (_amount * pool.depositFee) / 10000;

            user.amount += _amount - _feeAmount;
            pool.totalDeposited += _amount - _feeAmount;

            pool.token.approve(address(feeManager), 0);
            pool.token.approve(address(feeManager), _feeAmount);
            feeManager.manageFees(pool.token, _feeAmount);
        }

        user.rewardDebt = (user.amount * pool.accTombPerShare) / 1e18;
        emit Deposit(_sender, _pid, _amount);
    }

    // Withdraw tokens.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        if (user.amount < _amount) revert WithdrawNotGood(user.amount, _amount);

        updatePool(_pid);

        uint256 _pending = ((user.amount * pool.accTombPerShare) / 1e18) -
            user.rewardDebt;

        if (_pending > 0) {
            if (_amount == 0) {
                uint256 _feeAmount = (_pending * 50) / 10000;

                pool.token.approve(address(feeManager), 0);
                pool.token.approve(address(feeManager), _feeAmount);
                feeManager.manageFees(pool.token, _feeAmount);

                _pending -= _feeAmount;
            }
            safeTombTransfer(_sender, _pending);
            emit RewardPaid(_sender, _pending);
        }

        if (_amount > 0) {
            user.amount -= _amount;
            pool.totalDeposited -= _amount;
            uint256 _feeAmount = (_amount * 50) / 10000;
            pool.token.safeTransfer(_sender, _amount - _feeAmount);

            pool.token.approve(address(feeManager), 0);
            pool.token.approve(address(feeManager), _feeAmount);
            feeManager.manageFees(pool.token, _feeAmount);
        }
        user.rewardDebt = (user.amount * pool.accTombPerShare) / 1e18;
        emit Withdraw(_sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        uint256 _feeAmount = (_amount * 50) / 10000;
        _amount -= _feeAmount;
        pool.totalDeposited -= _amount;

        pool.token.approve(address(feeManager), 0);
        pool.token.approve(address(feeManager), _feeAmount);
        feeManager.manageFees(pool.token, _feeAmount);

        pool.token.safeTransfer(msg.sender, _amount);
        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    // Safe Tomb transfer function, in case if rounding error causes pool to not have enough Tombs.
    function safeTombTransfer(address _to, uint256 _amount) internal {
        uint256 _tombBalance = tomb.balanceOf(address(this));
        if (_tombBalance > 0) {
            if (_amount > _tombBalance) {
                tomb.safeTransfer(_to, _tombBalance);
            } else {
                tomb.safeTransfer(_to, _amount);
            }
        }
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 amount,
        address to
    ) external onlyOperator {
        if (block.timestamp < poolEndTime + 30 days) {
            if (_token == tomb)
                revert GovernanceRecoverTooSoon(
                    block.timestamp,
                    poolEndTime + 30
                );

            uint256 length = poolInfo.length;
            for (uint256 pid = 0; pid < length; ++pid) {
                PoolInfo storage pool = poolInfo[pid];
                if (_token == pool.token)
                    revert GovernanceRecoverTooSoon(
                        block.timestamp,
                        poolEndTime + 30
                    );
            }
        }
        _token.safeTransfer(to, amount);
    }

    function setOperator(address _operator) external onlyOperator {
        if (_operator == address(0)) revert NewOperatorIsAddressZero();
        operator = _operator;
    }

    function setCompound(bool _status) external {
        if (msg.sender != guardian) revert CallerIsNotOperator(msg.sender);
        compoundEnabled = _status;
    }

    function activateSecondPhase() external {
        if (msg.sender != guardian) revert CallerIsNotOperator(msg.sender);
        if (!secondPhaseEnabled) {
            secondPhaseEnabled = true;
            massUpdatePools();

            TOTAL_REWARDS = TOTAL_REWARDS_PHASE_TWO;
            TOMB_PER_SECOND = TOTAL_REWARDS / (RUNNING_TIME / 2);

            uint256 length = poolInfo.length;
            for (uint256 pid = 0; pid < length; ++pid) {
                PoolInfo storage pool = poolInfo[pid];
                if (pid == 0) {
                    pool.allocPoint *= 2;
                    pool.depositFee = (pool.depositFee * 120) / 100;
                } else {
                    pool.allocPoint /= 2;
                    pool.depositFee = (pool.depositFee * 150) / 100;
                }
            }
        }
    }

    function compoundUserRewards(uint256 _pid) external nonReentrant {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];

        updatePool(_pid);

        uint256 _pending = ((user.amount * pool.accTombPerShare) / 1e18) -
            user.rewardDebt;

        if (_pending > 0) {
            // Single token : Swap tomb reward for deposit token (if depositToken != tokenReward) and re-deposit on behalf of current user.
            if (!pool.isTombLp) {
                uint amount = _pending;

                if (pool.token != tomb) {
                    uint256 _before = pool.token.balanceOf(address(this));

                    tomb.approve(address(router), _pending);

                    router.swapExactTokensForTokens(
                        _pending,
                        1,
                        pool.path,
                        address(this),
                        block.timestamp
                    );

                    uint256 _after = pool.token.balanceOf(address(this));

                    amount = _after - _before;
                }

                _deposit(msg.sender, _pid, amount, true);
            } else {
                // Lp pool (BONES-FTM) : Swap half rewards for FTM, add liquidity and re-deposit on behalf of current user.
                uint256 half = _pending / 2;
                uint256 otherHalf = _pending - half;

                tomb.approve(address(router), _pending);

                address[] memory _pathToETH = new address[](2);
                _pathToETH[0] = address(tomb);
                _pathToETH[1] = address(WETH);

                uint256 before = address(this).balance;

                router.swapExactTokensForETH(
                    half,
                    1,
                    _pathToETH,
                    address(this),
                    block.timestamp
                );

                // How much ETH we get.
                uint256 ethAmount = address(this).balance - before;

                uint256 lpAmountBefore = pool.token.balanceOf(msg.sender);

                pool.token.approve(address(router), otherHalf);

                router.addLiquidityETH{value: ethAmount}(
                    address(tomb),
                    otherHalf,
                    0,
                    0,
                    msg.sender,
                    block.timestamp
                );

                // How much Lp tokens we get.
                uint256 lpAmount = pool.token.balanceOf(msg.sender) -
                    lpAmountBefore;

                _deposit(msg.sender, _pid, lpAmount, true);
            }
        }

        user.rewardDebt = (user.amount * pool.accTombPerShare) / 1e18;
    }
}