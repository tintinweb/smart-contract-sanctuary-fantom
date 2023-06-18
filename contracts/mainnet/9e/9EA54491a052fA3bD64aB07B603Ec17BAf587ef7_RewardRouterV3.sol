// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract Governable {
    address public gov;

    constructor() public {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IVault.sol";

interface IGlpManager {
    function glp() external view returns (address);
    function usdg() external view returns (address);
    function vault() external view returns (IVault);
    function cooldownDuration() external returns (uint256);
    function getAumInUsdg(bool maximise) external view returns (uint256);
    function lastAddedAt(address _account) external returns (uint256);
    function addLiquidity(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external returns (uint256);
    function addLiquidityForAccount(address _fundingAccount, address _account, address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external returns (uint256);
    function removeLiquidity(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver) external returns (uint256);
    function removeLiquidityForAccount(address _account, address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver) external returns (uint256);
    function setShortsTrackerAveragePriceWeight(uint256 _shortsTrackerAveragePriceWeight) external;
    function setCooldownDuration(uint256 _cooldownDuration) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IVaultUtils.sol";

interface IVault {
    function isInitialized() external view returns (bool);
    function isSwapEnabled() external view returns (bool);
    function isLeverageEnabled() external view returns (bool);

    function setVaultUtils(IVaultUtils _vaultUtils) external;
    function setError(uint256 _errorCode, string calldata _error) external;

    function router() external view returns (address);
    function usdg() external view returns (address);
    function gov() external view returns (address);

    function whitelistedTokenCount() external view returns (uint256);
    function maxLeverage() external view returns (uint256);

    function minProfitTime() external view returns (uint256);
    function hasDynamicFees() external view returns (bool);
    function fundingInterval() external view returns (uint256);
    function totalTokenWeights() external view returns (uint256);
    function getTargetUsdgAmount(address _token) external view returns (uint256);

    function inManagerMode() external view returns (bool);
    function inPrivateLiquidationMode() external view returns (bool);

    function maxGasPrice() external view returns (uint256);

    function approvedRouters(address _account, address _router) external view returns (bool);
    function isLiquidator(address _account) external view returns (bool);
    function isManager(address _account) external view returns (bool);

    function minProfitBasisPoints(address _token) external view returns (uint256);
    function tokenBalances(address _token) external view returns (uint256);
    function lastFundingTimes(address _token) external view returns (uint256);

    function setMaxLeverage(uint256 _maxLeverage) external;
    function setInManagerMode(bool _inManagerMode) external;
    function setManager(address _manager, bool _isManager) external;
    function setIsSwapEnabled(bool _isSwapEnabled) external;
    function setIsLeverageEnabled(bool _isLeverageEnabled) external;
    function setMaxGasPrice(uint256 _maxGasPrice) external;
    function setUsdgAmount(address _token, uint256 _amount) external;
    function setBufferAmount(address _token, uint256 _amount) external;
    function setMaxGlobalShortSize(address _token, uint256 _amount) external;
    function setInPrivateLiquidationMode(bool _inPrivateLiquidationMode) external;
    function setLiquidator(address _liquidator, bool _isActive) external;

    function setFundingRate(uint256 _fundingInterval, uint256 _fundingRateFactor, uint256 _stableFundingRateFactor) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _minProfitBps,
        uint256 _maxUsdgAmount,
        bool _isStable,
        bool _isShortable
    ) external;

    function setPriceFeed(address _priceFeed) external;
    function withdrawFees(address _token, address _receiver) external returns (uint256);

    function directPoolDeposit(address _token) external;
    function buyUSDG(address _token, address _receiver) external returns (uint256);
    function sellUSDG(address _token, address _receiver) external returns (uint256);
    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);
    function increasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external;
    function decreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256);
    function validateLiquidation(address _account, address _collateralToken, address _indexToken, bool _isLong, bool _raise) external view returns (uint256, uint256);
    function liquidatePosition(address _account, address _collateralToken, address _indexToken, bool _isLong, address _feeReceiver) external;
    function tokenToUsdMin(address _token, uint256 _tokenAmount) external view returns (uint256);

    function priceFeed() external view returns (address);
    function fundingRateFactor() external view returns (uint256);
    function stableFundingRateFactor() external view returns (uint256);
    function cumulativeFundingRates(address _token) external view returns (uint256);
    function getNextFundingRate(address _token) external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _usdgDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);
    function taxBasisPoints() external view returns (uint256);
    function stableTaxBasisPoints() external view returns (uint256);
    function mintBurnFeeBasisPoints() external view returns (uint256);
    function swapFeeBasisPoints() external view returns (uint256);
    function stableSwapFeeBasisPoints() external view returns (uint256);
    function marginFeeBasisPoints() external view returns (uint256);

    function allWhitelistedTokensLength() external view returns (uint256);
    function allWhitelistedTokens(uint256) external view returns (address);
    function whitelistedTokens(address _token) external view returns (bool);
    function stableTokens(address _token) external view returns (bool);
    function shortableTokens(address _token) external view returns (bool);
    function feeReserves(address _token) external view returns (uint256);
    function globalShortSizes(address _token) external view returns (uint256);
    function globalShortAveragePrices(address _token) external view returns (uint256);
    function maxGlobalShortSizes(address _token) external view returns (uint256);
    function tokenDecimals(address _token) external view returns (uint256);
    function tokenWeights(address _token) external view returns (uint256);
    function guaranteedUsd(address _token) external view returns (uint256);
    function poolAmounts(address _token) external view returns (uint256);
    function bufferAmounts(address _token) external view returns (uint256);
    function reservedAmounts(address _token) external view returns (uint256);
    function usdgAmounts(address _token) external view returns (uint256);
    function maxUsdgAmounts(address _token) external view returns (uint256);
    function getRedemptionAmount(address _token, uint256 _usdgAmount) external view returns (uint256);
    function getMaxPrice(address _token) external view returns (uint256);
    function getMinPrice(address _token) external view returns (uint256);

    function getDelta(address _indexToken, uint256 _size, uint256 _averagePrice, bool _isLong, uint256 _lastIncreasedTime) external view returns (bool, uint256);
    function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IVaultUtils {
    function updateCumulativeFundingRate(address _collateralToken, address _indexToken) external returns (bool);
    function validateIncreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external view;
    function validateDecreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external view;
    function validateLiquidation(address _account, address _collateralToken, address _indexToken, bool _isLong, bool _raise) external view returns (uint256, uint256);
    function getEntryFundingRate(address _collateralToken, address _indexToken, bool _isLong) external view returns (uint256);
    function getPositionFee(address _account, address _collateralToken, address _indexToken, bool _isLong, uint256 _sizeDelta) external view returns (uint256);
    function getFundingFee(address _account, address _collateralToken, address _indexToken, bool _isLong, uint256 _size, uint256 _entryFundingRate) external view returns (uint256);
    function getBuyUsdgFeeBasisPoints(address _token, uint256 _usdgAmount) external view returns (uint256);
    function getSellUsdgFeeBasisPoints(address _token, uint256 _usdgAmount) external view returns (uint256);
    function getSwapFeeBasisPoints(address _tokenIn, address _tokenOut, uint256 _usdgAmount) external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _usdgDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "../math/SafeMath.sol";
import "../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
contract ReentrancyGuard {
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IRewardRouterV2 {
    function feeGlpTracker() external view returns (address);
    function stakedGlpTracker() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IRewardTracker {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);
    function stakedAmounts(address _account) external view returns (uint256);
    function updateRewards() external;
    function stake(address _depositToken, uint256 _amount) external;
    function stakeForAccount(address _fundingAccount, address _account, address _depositToken, uint256 _amount) external;
    function unstake(address _depositToken, uint256 _amount) external;
    function unstakeForAccount(address _account, address _depositToken, uint256 _amount, address _receiver) external;
    function tokensPerInterval() external view returns (uint256);
    function claim(address _receiver) external returns (uint256);
    function claimForAccount(address _account, address _receiver) external returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function averageStakedAmounts(address _account) external view returns (uint256);
    function cumulativeRewards(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IVester {
    function rewardTracker() external view returns (address);

    function claimForAccount(address _account, address _receiver) external returns (uint256);

    function claimable(address _account) external view returns (uint256);
    function cumulativeClaimAmounts(address _account) external view returns (uint256);
    function claimedAmounts(address _account) external view returns (uint256);
    function pairAmounts(address _account) external view returns (uint256);
    function getVestedAmount(address _account) external view returns (uint256);
    function transferredAverageStakedAmounts(address _account) external view returns (uint256);
    function transferredCumulativeRewards(address _account) external view returns (uint256);
    function cumulativeRewardDeductions(address _account) external view returns (uint256);
    function bonusRewards(address _account) external view returns (uint256);

    function transferStakeValues(address _sender, address _receiver) external;
    function setTransferredAverageStakedAmounts(address _account, uint256 _amount) external;
    function setTransferredCumulativeRewards(address _account, uint256 _amount) external;
    function setCumulativeRewardDeductions(address _account, uint256 _amount) external;
    function setBonusRewards(address _account, uint256 _amount) external;

    function getMaxVestableAmount(address _account) external view returns (uint256);
    function getCombinedAverageStakedAmount(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";
import "../libraries/utils/Address.sol";

import "./interfaces/IRewardTracker.sol";
import "./interfaces/IRewardRouterV2.sol";
import "./interfaces/IVester.sol";
import "../tokens/interfaces/IMintable.sol";
import "../tokens/interfaces/IWETH.sol";
import "../core/interfaces/IGlpManager.sol";
import "../access/Governable.sol";

interface IClaimer {
    function claimForAccount(
        address _account,
        address _receiver
    ) external returns (uint256);
}

interface ILpRouter {
    function zapMintLpToken(
        uint ethIn,
        uint minLiquidity,
        address payable to
    ) external returns (uint256);
}

contract RewardRouterV3 is IRewardRouterV2, ReentrancyGuard, Governable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    bool public isInitialized;

    address public weth;

    address public gmx;
    address public esGmx;

    address public glp; // GMX Liquidity Provider token

    address public lpToken;
    address public bnLpToken;

    address public stakedEsGmxTracker;
    address public feeEsGmxTracker;

    address public override stakedGlpTracker;
    address public override feeGlpTracker;

    address public stakedLpTokenTracker;
    address public bonusLpTokenTracker;
    address public feeLpTokenTracker;

    address public glpManager;

    address public esGmxVester;
    address public glpVester;
    address public lpTokenVester;

    address public lpRouter;

    mapping(address => address) public pendingReceivers;

    event StakeEsGmx(address account, uint256 amount);
    event UnstakeEsGmx(address account, uint256 amount);

    event StakeGlp(address account, uint256 amount);
    event UnstakeGlp(address account, uint256 amount);

    event StakeLpToken(address account, uint256 amount);
    event UnstakeLpToken(address account, uint256 amount);

    receive() external payable {
        require(msg.sender == weth, "Router: invalid sender");
    }

    // Setup tokens
    constructor(
        address _weth,
        address _gmx,
        address _esGmx,
        address _glp,
        address _lpToken,
        address _bnLpToken
    ) public {
        weth = _weth;
        gmx = _gmx;
        esGmx = _esGmx;
        glp = _glp;
        lpToken = _lpToken;
        bnLpToken = _bnLpToken;
    }

    function initialize(
        address _stakedEsGmxTracker,
        address _feeEsGmxTracker,
        address _stakedGlpTracker,
        address _feeGlpTracker,
        address _stakedLpTokenTracker,
        address _bonusLpTokenTracker,
        address _feeLpTokenTracker,
        address _glpManager,
        address _esGmxVester,
        address _glpVester,
        address _lpTokenVester,
        address _lpRouter
    ) external onlyGov {
        require(!isInitialized, "RewardRouter: already initialized");
        isInitialized = true;

        // Trackers
        stakedEsGmxTracker = _stakedEsGmxTracker;
        feeEsGmxTracker = _feeEsGmxTracker;
        feeGlpTracker = _feeGlpTracker;
        stakedGlpTracker = _stakedGlpTracker;
        stakedLpTokenTracker = _stakedLpTokenTracker;
        bonusLpTokenTracker = _bonusLpTokenTracker;
        feeLpTokenTracker = _feeLpTokenTracker;

        glpManager = _glpManager;

        // Vesters
        esGmxVester = _esGmxVester;
        glpVester = _glpVester;
        lpTokenVester = _lpTokenVester;

        // Zapper
        lpRouter = _lpRouter;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(
        address _token,
        address _account,
        uint256 _amount
    ) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    // Allow the admin to stake esGmx for a set of accounts
    function batchStakeEsGmxForAccount(
        address[] memory _accounts,
        uint256[] memory _amounts
    ) external nonReentrant onlyGov {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _stakeEsGmx(msg.sender, _accounts[i], _amounts[i]);
        }
    }

    // Stake esGmx for msg.sender
    function stakeEsGmx(uint256 _amount) external nonReentrant {
        _stakeEsGmx(msg.sender, msg.sender, _amount);
    }

    // Unstake esGmx for msg.sender
    function unstakeEsGmx(uint256 _amount) external nonReentrant {
        _unstakeEsGmx(msg.sender, _amount);
    }

    // Stake lpToken for msg.sender
    function stakeLpToken(uint256 _amount) external nonReentrant {
        _stakeLpToken(msg.sender, msg.sender, _amount);
    }

    /**
     * @dev Stake your LP tokens for an account
     *
     * @param _account Stake for this account
     * @param _amount Amount to stake
     */
    function stakeLpTokenForAccount(address _account, uint256 _amount) external nonReentrant {
        _stakeLpToken(msg.sender, _account, _amount);
    }

    // Unstake lpToken for msg.sender
    function unstakeLpToken(uint256 _amount) external nonReentrant {
        _unstakeLpToken(msg.sender, _amount, true);
    }

    /**
     * @dev Mint staked GLP
     * Users cannot obtain GLP in unstaked form
     *
     * @param _token Whitelisted token to stake
     * @param _amount Amount to stake
     * @param _minUsdg Min dollar value of liquidity added
     * @param _minGlp Min GLP out
     */
    function mintAndStakeGlp(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external nonReentrant returns (uint256) {
        require(_amount > 0, "RewardRouter: invalid _amount");

        address account = msg.sender;
        uint256 glpAmount = IGlpManager(glpManager).addLiquidityForAccount(
            account,
            account,
            _token,
            _amount,
            _minUsdg,
            _minGlp
        );
        _stakeGlp(account, account, glpAmount);

        return glpAmount;
    }

    /**
     * @dev Mint staked GLP with native token
     * Users cannot obtain GLP in unstaked form
     *
     * @param _minUsdg Min dollar value of liquidity added
     * @param _minGlp Min GLP out
     */
    function mintAndStakeGlpETH(
        uint256 _minUsdg,
        uint256 _minGlp
    ) external payable nonReentrant returns (uint256) {
        require(msg.value > 0, "RewardRouter: invalid msg.value");

        IWETH(weth).deposit{value: msg.value}();
        IERC20(weth).approve(glpManager, msg.value);

        address account = msg.sender;
        uint256 glpAmount = IGlpManager(glpManager).addLiquidityForAccount(
            address(this),
            account,
            weth,
            msg.value,
            _minUsdg,
            _minGlp
        );
        _stakeGlp(account, account, glpAmount);

        return glpAmount;
    }

    /**
     * @dev Unstake and burn GLP and obtain one of the index token
     *
     * @param _tokenOut The index token to be obitaned
     * @param _glpAmount Amount of GLP to redeem
     * @param _minOut Minimum output amount for _tokenOut
     * @param _receiver The address to receive the output token
     */
    function unstakeAndRedeemGlp(
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) external nonReentrant returns (uint256) {
        require(_glpAmount > 0, "RewardRouter: invalid _glpAmount");
        address account = msg.sender;

        _unstakeGlp(account, _glpAmount);
        uint256 amountOut = IGlpManager(glpManager).removeLiquidityForAccount(
            account,
            _tokenOut,
            _glpAmount,
            _minOut,
            _receiver
        );

        return amountOut;
    }

    /**
     * @dev Unstake and burn GLP and obtain the native token
     *
     * @param _glpAmount Amount of GLP to redeem
     * @param _minOut Minimum output amount for _tokenOut
     * @param _receiver The address to receive the output token
     */
    function unstakeAndRedeemGlpETH(
        uint256 _glpAmount,
        uint256 _minOut,
        address payable _receiver
    ) external nonReentrant returns (uint256) {
        require(_glpAmount > 0, "RewardRouter: invalid _glpAmount");

        address account = msg.sender;
        _unstakeGlp(account, _glpAmount);

        uint256 amountOut = IGlpManager(glpManager).removeLiquidityForAccount(
            account,
            weth,
            _glpAmount,
            _minOut,
            address(this)
        );

        IWETH(weth).withdraw(amountOut);
        _receiver.sendValue(amountOut);

        return amountOut;
    }

    /**
     * @dev Claims rewards from 3 trackers, returning the total amount claimed.
     * Tracker can be RewardRracker or a Vester
     *
     * Must externally ensure that trackers give out the same reward
     *
     * @param tracker0 First tracker or vester
     * @param tracker1 Second tracker or vester
     * @param tracker2 Third tracker or vester
     * @param _account Claim rewards for this account
     * @param _receiver Credit rewards to the receiver.
     */
    function batchClaim(
        address tracker0,
        address tracker1,
        address tracker2,
        address _account,
        address _receiver
    ) internal returns (uint256) {
        uint256 amount0 = IClaimer(tracker0).claimForAccount(
            _account,
            _receiver
        );
        uint256 amount1 = IClaimer(tracker1).claimForAccount(
            _account,
            _receiver
        );
        uint256 amount2 = IClaimer(tracker2).claimForAccount(
            _account,
            _receiver
        );

        return amount0.add(amount1).add(amount2);
    }

    /**
     * @dev Claim ETH and esGMX rewards accrured to msg.sender
     */
    function claim() external nonReentrant {
        address account = msg.sender;

        // Claim ETH
        batchClaim(
            feeEsGmxTracker,
            feeGlpTracker,
            feeLpTokenTracker,
            account,
            account
        );

        // Claim esGMX
        batchClaim(
            stakedEsGmxTracker,
            stakedGlpTracker,
            stakedLpTokenTracker,
            account,
            account
        );
    }

    /**
     * @dev Claim esGMX rewards accrured to msg.sender
     */
    function claimEsGmx() external nonReentrant {
        address account = msg.sender;

        batchClaim(
            stakedEsGmxTracker,
            stakedGlpTracker,
            stakedLpTokenTracker,
            account,
            account
        );
    }

    /**
     * @dev Claim ETH rewards accrured to msg.sender
     */
    function claimFees() external nonReentrant {
        address account = msg.sender;

        batchClaim(
            feeEsGmxTracker,
            feeGlpTracker,
            feeLpTokenTracker,
            account,
            account
        );
    }

    /**
     * @dev Compound esGmx and bonusLpTokens for msg.sender
     */
    function compound() external nonReentrant {
        _compound(msg.sender);
    }

    /**
     * @dev Compound esGmx and bonusLpTokens for an account.
     * Only callable by gov.
     */
    function compoundForAccount(
        address _account
    ) external nonReentrant onlyGov {
        _compound(_account);
    }

    /**
     * @dev Compound esGmx and bonusLpTokens for msg.send
     * Only callable by gov.
     */
    function batchCompoundForAccounts(
        address[] memory _accounts
    ) external nonReentrant onlyGov {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _compound(_accounts[i]);
        }
    }

    /**
     * Common function to claim and compound accrued rewards
     *
     * Called by claim button on UI
     *
     * Changes made from RewardRouterV2
     * - _shouldStakeGmx Removed. There is no GMX staker now. User must LP into spookyswap
     * and call stakeLpToken()
     * - _shouldStakeEsGmx stakes esGmx into a dedicated staker
     *
     * @param _shouldClaimGmx Claim GMX accrued from vesters
     * @param _shouldClaimEsGmx Claim esGMX accrued from stakers
     * @param _shouldStakeEsGmx Stake esGMX accrued from stakers into the esGMX vault
     * @param _shouldStakeMultiplierPoints Stake bonus multiplier points into the LP token vault
     * @param _shouldClaimWeth Claim WETH fee from stakers
     * @param  _shouldStakeWeth Zap WETH into GMX-ETH liquidity pool
     * @param _shouldConvertWethToEth Unwrap WETH fee into ETH. Relavant only if _shouldStakeWethis false
     */
    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldStakeWeth,
        bool _shouldConvertWethToEth
    ) external nonReentrant {
        address account = msg.sender;
        address payable _rewardRouter = address(this);
        address _stakedLpTokenTracker = stakedLpTokenTracker;

        if (_shouldClaimGmx) {
            batchClaim(
                esGmxVester,
                glpVester,
                lpTokenVester,
                account,
                account
            );
        }

        uint256 esGmxAmount;
        if (_shouldClaimEsGmx) {
            esGmxAmount = batchClaim(
                stakedEsGmxTracker,
                stakedGlpTracker,
                _stakedLpTokenTracker,
                account,
                account
            );
        }

        if (_shouldStakeEsGmx && esGmxAmount > 0) {
            _stakeEsGmx(account, account, esGmxAmount);
        }

        if (_shouldStakeMultiplierPoints) {
            uint256 bnLpTokenAmount = IRewardTracker(bonusLpTokenTracker).claimForAccount(account, account);
            if (bnLpTokenAmount > 0) {
                IRewardTracker(feeLpTokenTracker).stakeForAccount(
                    account,
                    account,
                    bnLpToken,
                    bnLpTokenAmount
                );
            }
        }

        if (_shouldClaimWeth) {
            if (_shouldStakeWeth) {
                uint256 wethAmount = batchClaim(
                    feeEsGmxTracker,
                    feeGlpTracker,
                    feeLpTokenTracker,
                    account,
                    _rewardRouter
                );

                address _lpRouter = lpRouter;

                // Zap for LP tokens
                IERC20(weth).approve(_lpRouter, wethAmount);
                uint lpTokenAmount = ILpRouter(_lpRouter).zapMintLpToken(wethAmount, 0, _rewardRouter);

                // Stake LP tokens
                IERC20(lpToken).approve(_stakedLpTokenTracker, lpTokenAmount);
                _stakeLpToken(_rewardRouter, account, lpTokenAmount);

            } else if (_shouldConvertWethToEth) {
                uint256 wethAmount = batchClaim(
                    feeEsGmxTracker,
                    feeGlpTracker,
                    feeLpTokenTracker,
                    account,
                    _rewardRouter
                );
                IWETH(weth).withdraw(wethAmount);
                payable(account).sendValue(wethAmount);
            } else {
                batchClaim(
                    feeEsGmxTracker,
                    feeGlpTracker,
                    feeLpTokenTracker,
                    account,
                    account
                );
            }
        }
    }

    /**
     * @dev Initiate an account transfer
     *
     * @param _receiver Transfer recipient
     */
    function signalTransfer(address _receiver) external nonReentrant {
        // Must have no tokens in vesters
        require(
            IERC20(esGmxVester).balanceOf(msg.sender) == 0
                && IERC20(glpVester).balanceOf(msg.sender) == 0
                && IERC20(lpTokenVester).balanceOf(msg.sender) == 0,
            "RewardRouter: sender has vested tokens"
        );

        _validateReceiver(_receiver);
        pendingReceivers[msg.sender] = _receiver;
    }

    /**
     * @dev Accept an account transfer
     *
     * @param _sender The address making the transfer
     */
    function acceptTransfer(address _sender) external nonReentrant {
        require(
            IERC20(lpTokenVester).balanceOf(_sender) == 0,
            "RewardRouter: sender has vested tokens"
        );
        require(
            IERC20(glpVester).balanceOf(_sender) == 0,
            "RewardRouter: sender has vested tokens"
        );
        require(
            IERC20(esGmxVester).balanceOf(_sender) == 0,
            "RewardRouter: sender has vested tokens"
        );

        address receiver = msg.sender;
        require(pendingReceivers[_sender] == receiver, "RewardRouter: transfer not signalled");
        delete pendingReceivers[_sender];

        _validateReceiver(receiver);
        _compound(_sender);

        // Perform transfers- withdraw from trackers and stake into trackers for the reciver

        // 1. lpToken
        uint256 stakedLpTokenAmount = IRewardTracker(stakedLpTokenTracker).depositBalances(_sender, lpToken);
        if (stakedLpTokenAmount > 0) {
            _unstakeLpToken(_sender, stakedLpTokenAmount, false);
            _stakeLpToken(_sender, receiver, stakedLpTokenAmount);
        }

        // Staked bnLpToken
        address _bnLpToken = bnLpToken;
        uint256 stakedBnLpTokenAmount = IRewardTracker(feeLpTokenTracker).depositBalances(_sender, _bnLpToken);
        if (stakedBnLpTokenAmount > 0) {
            IRewardTracker(feeLpTokenTracker).unstakeForAccount(
                _sender,
                _bnLpToken,
                stakedBnLpTokenAmount,
                _sender
            );
            IRewardTracker(feeLpTokenTracker).stakeForAccount(
                _sender,
                receiver,
                _bnLpToken,
                stakedBnLpTokenAmount
            );
        }

        // 2. esGmx
        address _esGmx = esGmx;
        uint256 stakedEsGmxAmount = IRewardTracker(stakedEsGmxTracker).depositBalances(_sender, _esGmx);
        if (stakedEsGmxAmount > 0) {
            _unstakeEsGmx(_sender, stakedEsGmxAmount);
            _stakeEsGmx(_sender, receiver, stakedEsGmxAmount);
        }

        // 3. GLP
        uint256 glpAmount = IRewardTracker(feeGlpTracker).depositBalances(
            _sender,
            glp
        );
        if (glpAmount > 0) {
            _unstakeGlp(_sender, glpAmount);
            _stakeGlp(_sender, receiver, glpAmount);
        }

        // Transfer fee esGMX held in wallet
        uint256 esGmxBalance = IERC20(_esGmx).balanceOf(_sender);
        if (esGmxBalance > 0) {
            IERC20(_esGmx).transferFrom(_sender, receiver, esGmxBalance);
        }

        // Transfer vester stakes
        IVester(lpTokenVester).transferStakeValues(_sender, receiver);
        IVester(glpVester).transferStakeValues(_sender, receiver);
        IVester(esGmxVester).transferStakeValues(_sender, receiver);
    }

    /**
     * @dev Validate whether an address is ready to receive an account transfer
     *
     * @param _receiver The receiver address
     */
    function _validateReceiver(address _receiver) private view {
        // A. Trackers

        // 1. lpToken- staked, bonus, fee
        require(
            IRewardTracker(stakedLpTokenTracker).averageStakedAmounts(_receiver) == 0,
            "RewardRouter: stakedLpTokenTracker.averageStakedAmounts > 0"
        );
        require(
            IRewardTracker(stakedLpTokenTracker).cumulativeRewards(_receiver) == 0,
            "RewardRouter: stakedLpTokenTracker.cumulativeRewards > 0"
        );

        require(
            IRewardTracker(bonusLpTokenTracker).averageStakedAmounts(_receiver) == 0,
            "RewardRouter: bonusLpTokenTracker.averageStakedAmounts > 0"
        );
        require(
            IRewardTracker(bonusLpTokenTracker).cumulativeRewards(_receiver) == 0,
            "RewardRouter: bonusLpTokenTracker.cumulativeRewards > 0"
        );

        require(
            IRewardTracker(feeLpTokenTracker).averageStakedAmounts(_receiver) == 0,
            "RewardRouter: feeLpTokenTracker.averageStakedAmounts > 0"
        );
        require(
            IRewardTracker(feeLpTokenTracker).cumulativeRewards(_receiver) == 0,
            "RewardRouter: feeLpTokenTracker.cumulativeRewards > 0"
        );

        // 2. GLP- staked, fee
        require(
            IRewardTracker(stakedGlpTracker).averageStakedAmounts(_receiver) == 0,
            "RewardRouter: stakedGlpTracker.averageStakedAmounts > 0"
        );
        require(
            IRewardTracker(stakedGlpTracker).cumulativeRewards(_receiver) == 0,
            "RewardRouter: stakedGlpTracker.cumulativeRewards > 0"
        );

        require(
            IRewardTracker(feeGlpTracker).averageStakedAmounts(_receiver) == 0,
            "RewardRouter: feeGlpTracker.averageStakedAmounts > 0"
        );
        require(
            IRewardTracker(feeGlpTracker).cumulativeRewards(_receiver) == 0,
            "RewardRouter: feeGlpTracker.cumulativeRewards > 0"
        );

        // 3. esGmx- staked, fee
        require(
            IRewardTracker(stakedEsGmxTracker).averageStakedAmounts(_receiver) == 0,
            "RewardRouter: stakedEsGmxTracker.averageStakedAmounts > 0"
        );
        require(
            IRewardTracker(stakedEsGmxTracker).cumulativeRewards(_receiver) == 0,
            "RewardRouter: stakedEsGmxTracker.cumulativeRewards > 0"
        );

        require(
            IRewardTracker(feeEsGmxTracker).averageStakedAmounts(_receiver) == 0,
            "RewardRouter: feeEsGmxTracker.averageStakedAmounts > 0"
        );
        require(
            IRewardTracker(feeEsGmxTracker).cumulativeRewards(_receiver) == 0,
            "RewardRouter: feeEsGmxTracker.cumulativeRewards > 0"
        );

        // B. Vesters

        // 1. lpToken
        require(
            IVester(lpTokenVester).transferredAverageStakedAmounts(_receiver) == 0,
            "RewardRouter: lpTokenVester.transferredAverageStakedAmounts > 0"
        );
        require(
            IVester(lpTokenVester).transferredCumulativeRewards(_receiver) == 0,
            "RewardRouter: lpTokenVester.transferredCumulativeRewards > 0"
        );
        require(
            IERC20(lpTokenVester).balanceOf(_receiver) == 0,
            "RewardRouter: lpTokenVester.balance > 0"
        );

        // 2. glp
        require(
            IVester(glpVester).transferredAverageStakedAmounts(_receiver) == 0,
            "RewardRouter: gmxVester.transferredAverageStakedAmounts > 0"
        );
        require(
            IVester(glpVester).transferredCumulativeRewards(_receiver) == 0,
            "RewardRouter: gmxVester.transferredCumulativeRewards > 0"
        );
        require(
            IERC20(glpVester).balanceOf(_receiver) == 0,
            "RewardRouter: glpVester.balance > 0"
        );

        // 3. esGmx
        require(
            IVester(esGmxVester).transferredAverageStakedAmounts(_receiver) ==
                0,
            "RewardRouter: esGmxVester.transferredAverageStakedAmounts > 0"
        );
        require(
            IVester(esGmxVester).transferredCumulativeRewards(_receiver) == 0,
            "RewardRouter: esGmxVester.transferredCumulativeRewards > 0"
        );
        require(
            IERC20(esGmxVester).balanceOf(_receiver) == 0,
            "RewardRouter: esGmxVester.balance > 0"
        );
    }

    /**
     * @dev Compound esGmx rewards and bonus multiplier points accrured to an account
     * Does not compound Gmx and ETH fees. The user must manually add these to Spookyswap liquidity
     *
     * @param _account Compound for this account
     */
    function _compound(address _account) private {
        _compoundEsGmx(_account);
        _compoundGlp(_account);
        _compoundLpToken(_account);
    }

    /**
     * @dev Collect and stake esGMX and bonus points accrued from the LP token staker
     * esGmx is staked into the esGmx staker. Bonus points are staked into the lpToken staker.
     */
    function _compoundLpToken(address _account) private {
        uint256 esGmxAmount = IRewardTracker(stakedLpTokenTracker).claimForAccount(_account, _account);
        if (esGmxAmount > 0) {
            _stakeEsGmx(_account, _account, esGmxAmount);
        }

        uint256 bnLpTokenAmount = IRewardTracker(bonusLpTokenTracker).claimForAccount(_account, _account);
        if (bnLpTokenAmount > 0) {
            IRewardTracker(feeLpTokenTracker).stakeForAccount(
                _account,
                _account,
                bnLpToken,
                bnLpTokenAmount
            );
        }
    }

    /**
     * @dev Collect esGMX accrued from the GLP staker and stake it into the esGmx staker
     */
    function _compoundGlp(address _account) private {
        uint256 esGmxAmount = IRewardTracker(stakedGlpTracker).claimForAccount(
            _account,
            _account
        );
        if (esGmxAmount > 0) {
            _stakeEsGmx(_account, _account, esGmxAmount);
        }
    }

    /**
     * @dev Collect esGMX accrued from the esGmx staker and stake it back
     */
    function _compoundEsGmx(address _account) private {
        uint256 esGmxAmount = IRewardTracker(stakedEsGmxTracker)
            .claimForAccount(_account, _account);
        if (esGmxAmount > 0) {
            _stakeEsGmx(_account, _account, esGmxAmount);
        }
    }

    /**
     * @dev Stake LP tokens into staked, bonus and fee trackers to earn esGMX, bnLpToken and native token rewards
     * The _fundingAccount must approve an allowance worth atleast `_amount` lp tokens to _stakedLpTokenTracker
     * before making this call.
     *
     * @param _fundingAccount The account paying out the LP tokens
     * @param _account Staked tokens are credited to this account
     * @param _amount The amount to stake
     */
    function _stakeLpToken(
        address _fundingAccount,
        address _account,
        uint256 _amount
    ) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        address _stakedLpTokenTracker = stakedLpTokenTracker;
        address _bonusLpTokenTracker = bonusLpTokenTracker;
        IRewardTracker(_stakedLpTokenTracker).stakeForAccount(
            _fundingAccount,
            _account,
            lpToken,
            _amount
        );
        IRewardTracker(_bonusLpTokenTracker).stakeForAccount(
            _account,
            _account,
            _stakedLpTokenTracker,
            _amount
        );
        IRewardTracker(feeLpTokenTracker).stakeForAccount(
            _account,
            _account,
            _bonusLpTokenTracker,
            _amount
        );

        emit StakeLpToken(_account, _amount);
    }

    /**
     * @dev Unstake LP tokens for an account from fee, bonus and staked trackers
     *
     * @param _account Unstake for this account
     * @param _amount Amount to unstake
     * @param _shouldReduceBnLpToken Whether bonus multiplier points should be burnt
     */
    function _unstakeLpToken(
        address _account,
        uint256 _amount,
        bool _shouldReduceBnLpToken
    ) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        address _bnLpToken = bnLpToken;
        address _stakedLpTokenTracker = stakedLpTokenTracker;
        address _bonusLpTokenTracker = bonusLpTokenTracker;
        address _feeLpTokenTracker = feeLpTokenTracker;

        uint256 stakedLpTokenAmount = IRewardTracker(_stakedLpTokenTracker).stakedAmounts(
            _account
        );

        IRewardTracker(_feeLpTokenTracker).unstakeForAccount(
            _account,
            _bonusLpTokenTracker,
            _amount,
            _account
        );
        IRewardTracker(_bonusLpTokenTracker).unstakeForAccount(
            _account,
            _stakedLpTokenTracker,
            _amount,
            _account
        );
        IRewardTracker(_stakedLpTokenTracker).unstakeForAccount(
            _account,
            lpToken,
            _amount,
            _account
        );

        if (_shouldReduceBnLpToken) {
            // Collect accrued bonus tokens and stake them into fee tracker
            uint256 bnLpTokenAmount = IRewardTracker(_bonusLpTokenTracker)
                .claimForAccount(_account, _account);
            if (bnLpTokenAmount > 0) {
                IRewardTracker(_feeLpTokenTracker).stakeForAccount(
                    _account,
                    _account,
                    _bnLpToken,
                    bnLpTokenAmount
                );
            }

            // Proceed to burn from total
            uint256 stakedBnLpTokenAmount = IRewardTracker(_feeLpTokenTracker)
                .depositBalances(_account, _bnLpToken);
            if (stakedBnLpTokenAmount > 0) {
                // reductionAmount = stakedBnLpTokenAmount * amountWithdrawn / stakedLpToken
                uint256 reductionAmount = stakedBnLpTokenAmount.mul(_amount).div(
                    stakedLpTokenAmount
                );
                // unstake and burn reductionAmount
                IRewardTracker(_feeLpTokenTracker).unstakeForAccount(
                    _account,
                    bnLpToken,
                    reductionAmount,
                    _account
                );
                IMintable(_bnLpToken).burn(_account, reductionAmount);
            }
        }

        emit UnstakeLpToken(_account, _amount);
    }

    /**
     * @dev Stake esGmx into staked and fee trackers to earn esGMX and native token rewards
     *
     * @param _fundingAccount The account paying out esGmx
     * @param _account Staked tokens are credited to this account
     * @param _amount The amount to stake
     */
    function _stakeEsGmx(
        address _fundingAccount,
        address _account,
        uint256 _amount
    ) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        address _stakedEsGmxTracker = stakedEsGmxTracker;
        IRewardTracker(_stakedEsGmxTracker).stakeForAccount(
            _fundingAccount,
            _account,
            esGmx,
            _amount
        );
        IRewardTracker(feeEsGmxTracker).stakeForAccount(
            _account,
            _account,
            _stakedEsGmxTracker,
            _amount
        );

        emit StakeEsGmx(_account, _amount);
    }

    /**
     * @dev Unstake esGmx for an account from fee and staked trackers
     *
     * @param _account Unstake for this account
     * @param _amount Amount to unstake
     */
    function _unstakeEsGmx(address _account, uint256 _amount) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        address _stakedEsGmxTracker = stakedEsGmxTracker;

        IRewardTracker(feeEsGmxTracker).unstakeForAccount(
            _account,
            _stakedEsGmxTracker,
            _amount,
            _account
        );
        IRewardTracker(_stakedEsGmxTracker).unstakeForAccount(
            _account,
            esGmx,
            _amount,
            _account
        );

        emit UnstakeEsGmx(_account, _amount);
    }

    /**
     * @dev Stake GLP into fee and staked trackers to earn native token and esGmx rewards
     *
     * @param _fundingAccount The account paying out glp
     * @param _account Staked tokens are credited to this account
     * @param _amount The amount to stake
     */
    function _stakeGlp(
        address _fundingAccount,
        address _account,
        uint256 _amount
    ) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        address _feeGlpTracker = feeGlpTracker;
        IRewardTracker(_feeGlpTracker).stakeForAccount(
            _fundingAccount,
            _account,
            glp,
            _amount
        );
        IRewardTracker(stakedGlpTracker).stakeForAccount(
            _account,
            _account,
            _feeGlpTracker,
            _amount
        );

        emit StakeGlp(_account, _amount);
    }

    /**
     * @dev Unstake GLP for an account from staked and fee trackers
     *
     * @param _account Unstake for this account
     * @param _amount Amount to unstake
     */
    function _unstakeGlp(address _account, uint256 _amount) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        address _feeGlpTracker = feeGlpTracker;

        IRewardTracker(stakedGlpTracker).unstakeForAccount(
            _account,
            _feeGlpTracker,
            _amount,
            _account
        );
        IRewardTracker(_feeGlpTracker).unstakeForAccount(
            _account,
            glp,
            _amount,
            _account
        );

        emit UnstakeGlp(_account, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IMintable {
    function isMinter(address _account) external returns (bool);
    function setMinter(address _minter, bool _isActive) external;
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}