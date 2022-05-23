/**
 *Submitted for verification at FtmScan.com on 2022-05-23
*/

// SPDX-License-Identifier: AGPL-3.0
// Feel free to change the license, but this is what we use

// Feel free to change this version of Solidity. We support >=0.6.0 <0.7.0;

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// Gary's Generic xBOO Staker

// These are the core Yearn libraries

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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// base strategy begins
struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}

interface VaultAPI is IERC20 {
    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function decimals() external view returns (uint256);

    function apiVersion() external pure returns (string memory);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function deposit() external returns (uint256);

    function deposit(uint256 amount) external returns (uint256);

    function deposit(uint256 amount, address recipient) external returns (uint256);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient) external returns (uint256);

    function token() external view returns (address);

    function strategies(address _strategy) external view returns (StrategyParams memory);

    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function depositLimit() external view returns (uint256);

    function maxAvailableShares() external view returns (uint256);

    /**
     * View how much the Vault would increase this Strategy's borrow limit,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function creditAvailable() external view returns (uint256);

    /**
     * View how much the Vault would like to pull back from the Strategy,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function debtOutstanding() external view returns (uint256);

    /**
     * View how much the Vault expect this Strategy to return at the current
     * block, based on its present performance (since its last report). Can be
     * used to determine expectedReturn in your Strategy.
     */
    function expectedReturn() external view returns (uint256);

    /**
     * This is the main contact point where the Strategy interacts with the
     * Vault. It is critical that this call is handled as intended by the
     * Strategy. Therefore, this function will be called by BaseStrategy to
     * make sure the integration is correct.
     */
    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256);

    /**
     * This function should only be used in the scenario where the Strategy is
     * being retired but no migration of the positions are possible, or in the
     * extreme scenario that the Strategy needs to be put into "Emergency Exit"
     * mode in order for it to exit as quickly as possible. The latter scenario
     * could be for any reason that is considered "critical" that the Strategy
     * exits its position as fast as possible, such as a sudden change in
     * market conditions leading to losses, or an imminent failure in an
     * external dependency.
     */
    function revokeStrategy() external;

    /**
     * View the governance address of the Vault to assert privileged functions
     * can only be called by governance. The Strategy serves the Vault, so it
     * is subject to governance defined by the Vault.
     */
    function governance() external view returns (address);

    /**
     * View the management address of the Vault to assert privileged functions
     * can only be called by management. The Strategy serves the Vault, so it
     * is subject to management defined by the Vault.
     */
    function management() external view returns (address);

    /**
     * View the guardian address of the Vault to assert privileged functions
     * can only be called by guardian. The Strategy serves the Vault, so it
     * is subject to guardian defined by the Vault.
     */
    function guardian() external view returns (address);
}

interface IGenericLender {
    function lenderName() external view returns (string memory);

    function nav() external view returns (uint256);

    function strategy() external view returns (address);

    function apr() external view returns (uint256);

    function weightedApr() external view returns (uint256);

    function withdraw(uint256 amount) external returns (uint256);

    function emergencyWithdraw(uint256 amount) external;

    function deposit() external;

    function withdrawAll() external returns (bool);

    function hasAssets() external view returns (bool);

    function aprAfterDeposit(uint256 amount) external view returns (uint256);

    function setDust(uint256 _dust) external;

    function sweep(address _token) external;
}


interface IBaseStrategy {
    function apiVersion() external pure returns (string memory);

    function name() external pure returns (string memory);

    function vault() external view returns (address);

    function keeper() external view returns (address);

    function tendTrigger(uint256 callCost) external view returns (bool);

    function tend() external;

    function harvestTrigger(uint256 callCost) external view returns (bool);

    function harvest() external;

    function strategist() external view returns (address);
}

abstract contract GenericLenderBase is IGenericLender {
    using SafeERC20 for IERC20;
    VaultAPI public vault;
    address public override strategy;
    IERC20 public want;
    string public override lenderName;
    uint256 public dust;

    event Cloned(address indexed clone);

    bool public isOriginal = true;

    constructor(address _strategy, string memory _name) public {
        _initialize(_strategy, _name);
    }

    function _initialize(address _strategy, string memory _name) internal {
        require(address(strategy) == address(0), "Lender already initialized");

        strategy = _strategy;
        vault = VaultAPI(IBaseStrategy(strategy).vault());
        want = IERC20(vault.token());
        lenderName = _name;
        dust = 10000;

        want.safeApprove(_strategy, uint256(-1));
    }

    function initialize(address _strategy, string memory _name) external virtual {
        _initialize(_strategy, _name);
    }

    function _clone(address _strategy, string memory _name) internal returns (address newLender) {
        require(isOriginal, "!clone");
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(address(this));

        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(clone_code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(add(clone_code, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            newLender := create(0, clone_code, 0x37)
        }

        GenericLenderBase(newLender).initialize(_strategy, _name);
        emit Cloned(newLender);
    }

    function setDust(uint256 _dust) external virtual override management {
        dust = _dust;
    }

    function sweep(address _token) external virtual override govOnly {
        address[] memory _protectedTokens = protectedTokens();
        for (uint256 i; i < _protectedTokens.length; i++) require(_token != _protectedTokens[i], "!protected");

        IERC20(_token).safeTransfer(vault.governance(), IERC20(_token).balanceOf(address(this)));
    }

    function protectedTokens() internal view virtual returns (address[] memory);

    //make sure to use
    modifier management() {
        require(
            msg.sender == address(strategy) || msg.sender == vault.governance() || msg.sender == IBaseStrategy(strategy).strategist(),
            "!management"
        );
        _;
    }

    modifier govOnly() {
        require(
            msg.sender == vault.governance(),
            "!management"
        );
        _;
    }
}


// boo:xboo ratios, enter = "Locks Boo and mints xBoo", leave = "Unlocks the staked + gained Boo, and burns xBoo"
interface IXboo is IERC20 {
    function xBOOForBOO(uint256) external view returns (uint256);

    function BOOForxBOO(uint256) external view returns (uint256);

    function enter(uint256) external;

    function leave(uint256) external;
}

interface IUniswapV2Pair {
    function swap(
        uint256,
        uint256,
        address to,
        bytes calldata
    ) external;

    function getReserves()
        external
        view
        returns (
            uint256 reserve0,
            uint256 reserve1,
            uint256 timestamp
        );
}

interface IFactory {
    function getPair(address, address) external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint256 reserve0,
            uint256 reserve1,
            uint256 timestamp
        );
}

interface ChefLike {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external; // use amount = 0 for harvesting rewards

    function emergencyWithdraw(uint256 _pid) external;

    function userInfo(uint256 _pid, address user) external view returns (uint256 amount, uint256 rewardDebt);

    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address RewardToken,
            uint256 RewardPerSecond,
            uint256 TokenPrecision,
            uint256 xBooStakedAmount,
            uint256 lastRewardTime,
            uint256 accRewardPerShare,
            uint256 endTime,
            uint256 startTime,
            uint256 userLimitEndTime,
            address protocolOwnerAddress
        );
}

contract GenericXboo is GenericLenderBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    ChefLike public masterchef;
    IERC20 public emissionToken;
    IERC20 public swapFirstStep;

    // swap stuff
    address internal constant spookyFactory = 0x152eE697f2E276fA89E96742e9bB9aB1F2E61bE3;
    address internal constant spiritFactory = 0xEF45d134b73241eDa7703fa787148D9C9F4950b0;

    // tokens
    IERC20 internal constant wftm = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
    IERC20 internal constant usdc = IERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75);
    IERC20 internal constant boo = IERC20(0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE);
    IXboo internal constant xboo = IXboo(0xa48d959AE2E88f1dAA7D5F611E01908106dE7598);

    bool public autoSell;
    uint256 public maxSell; // set to zero for unlimited

    bool public useSpiritPartOne;
    bool public useSpiritPartTwo;

    uint256 public pid; // the pool ID we are staking for

    string internal stratName; // we use this for our strategy's name on cloning

    uint256 private constant secondsPerYear = 31_536_000;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _strategy,
        uint256 _pid,
        string memory _name,
        address _masterchef,
        address _emissionToken,
        address _swapFirstStep,
        bool _autoSell
    ) public GenericLenderBase(_strategy, _name) {
        _initializeStrat(_pid, _masterchef, _emissionToken, _swapFirstStep, _autoSell);
    }



    // we use this to clone our original strategy to other vaults
    function cloneGenericXboo(
        address _strategy,
        uint256 _pid,
        string memory _name,
        address _masterchef,
        address _emissionToken,
        address _swapFirstStep,
        bool _autoSell
    ) external returns (address newLender) {
        newLender = _clone(_strategy, _name);
        GenericXboo(newLender).initialize(
            _pid,
            _masterchef,
            _emissionToken,
            _swapFirstStep,
            _autoSell
        );
    }

    // this will only be called by the clone function above
    function initialize(
        uint256 _pid,
        address _masterchef,
        address _emissionToken,
        address _swapFirstStep,
        bool _autoSell
    ) public {
        // _initialize(_strategy, _strategist, _rewards, _keeper);
        require(address(emissionToken) == address(0), "already initialized");
        _initializeStrat(_pid, _masterchef, _emissionToken, _swapFirstStep, _autoSell);
    }

    // this is called by our original strategy, as well as any clones
    function _initializeStrat(
        uint256 _pid,
        address _masterchef,
        address _emissionToken,
        address _swapFirstStep,
        bool _autoSell
    ) internal {
        masterchef = ChefLike(_masterchef);
        emissionToken = IERC20(_emissionToken);
        swapFirstStep = IERC20(_swapFirstStep);

        (
            address rewardsToken,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            
        ) = masterchef.poolInfo(_pid);

        require(rewardsToken == _emissionToken, "wrong token");

        autoSell = _autoSell;

        // make sure that we used the correct pid
        pid = _pid;

        // add approvals on all tokens
        want.approve(address(xboo), type(uint256).max);
        xboo.approve(address(masterchef), type(uint256).max);
    }

    /* ========== FUNCTIONS ========== */

    // balance of boo in strat - should be zero most of the time
    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function balanceOfXboo() public view returns (uint256) {
        return xboo.balanceOf(address(this));
    }

    // balance of xboo in strat (in boo) - should be zero most of the time
    function balanceOfXbooInWant() public view returns (uint256) {
        return xboo.xBOOForBOO(balanceOfXboo());
    }

    // balance of xboo in masterchef (in boo)
    function balanceOfStaked() public view returns (uint256) {
        (uint256 stakedInMasterchef, ) = masterchef.userInfo(pid, address(this));
        stakedInMasterchef = xboo.xBOOForBOO(stakedInMasterchef);
        return stakedInMasterchef;
    }

    // same as estimatedTotalAssets
    function nav() external view override returns (uint256) {
        return _nav();
    }

    // same as estimatedTotalAssets
    function _nav() internal view returns (uint256) {
        // look at our staked tokens and any free tokens sitting in the strategy
        return balanceOfStaked().add(balanceOfWant()).add(balanceOfXbooInWant());
    }

    function apr() external view override returns (uint256) {
        return _apr();
    }

    // calculate current reward apr
    function _apr() internal view returns (uint256) {
        return _aprAfterDeposit(0);
    }

    function aprAfterDeposit(uint256 amount) external view override returns (uint256) {
        return _aprAfterDeposit(amount);
    }

    function _aprAfterDeposit(uint256 amount) internal view returns (uint256) {
        (
            ,
            uint256 rewardsEachSecond,
            ,
            uint256 stakedXboo,
            ,
            ,
            uint256 poolEnds,
            uint256 poolStarts,
            ,
            
        ) = masterchef.poolInfo(pid);
        if (block.timestamp < poolStarts || block.timestamp > poolEnds) {
            return 0;
        }

        uint256 xbooAdded = xboo.BOOForxBOO(amount);
        uint256 booEachSecond = quoteEmissionToBoo(rewardsEachSecond.mul(10)).div(10);
        uint256 booEachYear = booEachSecond.mul(secondsPerYear);
        uint256 xbooEachYear = xboo.BOOForxBOO(booEachYear);
        uint256 newTotalXbooInPool = stakedXboo.add(xbooAdded);
        return xbooEachYear.mul(1e18).div(newTotalXbooInPool);
    }

    struct SellRoute {
        address pair;
        address input;
        address output;
        address to;
    }

    function quoteEmissionToBoo(uint256 _amount) internal view returns (uint256) {
        // we do all our sells in one go in a chain between pairs
        // inialise to 3 even if we use less to save on gas
        SellRoute[] memory sellRoute = new SellRoute[](3);

        // 1! sell our emission token for swap first step token
        address[] memory emissionTokenPath = new address[](2);
        emissionTokenPath[0] = address(emissionToken);
        emissionTokenPath[1] = address(swapFirstStep);
        uint256 id = 0;

        address factory = useSpiritPartOne ? spiritFactory : spookyFactory;
        // we deal directly with the pairs
        address pair = IFactory(factory).getPair(emissionTokenPath[0], emissionTokenPath[1]);

        // first
        sellRoute[id] = SellRoute(pair, emissionTokenPath[0], emissionTokenPath[1], address(0));

        if (address(want) == address(swapFirstStep)) {
            // end with only one step
            
            return _quoteUniswap(sellRoute, id, _amount);
        }

        // if the second token isnt wftm we need to do an etra step
        if (address(swapFirstStep) != address(wftm)) {
            id = id + 1;
            // ! 2
            emissionTokenPath[0] = address(swapFirstStep);
            emissionTokenPath[1] = address(wftm);

            pair = IFactory(spookyFactory).getPair(emissionTokenPath[0], emissionTokenPath[1]);

            // we set the to of the last step to
            sellRoute[id - 1].to = pair;

            sellRoute[id] = SellRoute(pair, emissionTokenPath[0], emissionTokenPath[1], address(0));

            if (address(want) == address(wftm)) {
                // end. final to is always us. second array
                sellRoute[id].to = address(this);

                // end with only one step
                
                return _quoteUniswap(sellRoute, id, _amount);
            }
        }

        id = id + 1;
        // final step is wftm to want
        emissionTokenPath[0] = address(wftm);
        emissionTokenPath[1] = address(want);
        factory = useSpiritPartTwo ? spiritFactory : spookyFactory;
        pair = IFactory(factory).getPair(emissionTokenPath[0], emissionTokenPath[1]);

        sellRoute[id - 1].to = pair;

        sellRoute[id] = SellRoute(pair, emissionTokenPath[0], emissionTokenPath[1], address(this));

        // id will be 0-1-2
        return _quoteUniswap(sellRoute, id, _amount);
    }

    function _quoteUniswap(
        SellRoute[] memory sell,
        uint256 id,
        uint256 amountIn
    ) internal view returns (uint256) {
        for (uint256 i = 0; i < id + 1; i++) {
            (address token0, ) = _sortTokens(sell[i].input, sell[i].output);
            IUniswapV2Pair pair = IUniswapV2Pair(sell[i].pair);

            (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
            (uint256 reserveInput, uint256 reserveOutput) = sell[i].input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

            amountIn = _getAmountOut(amountIn, reserveInput, reserveOutput);
        }

        return amountIn;
    }

    // following two functions are taken from uniswap library
    // https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
    function _sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator.div(denominator);
    }

    function weightedApr() external view override returns (uint256) {
        uint256 a = _apr();
        return a.mul(_nav());
    }

    function withdraw(uint256 amount) external override management returns (uint256) {
        return _withdraw(amount);
    }

    // Only do this if absolutely necessary; as assets will be withdrawn but rewards won't be claimed.
    function emergencyManualWithdraw() external management {
        masterchef.emergencyWithdraw(pid);
    }

    // Only do this if absolutely necessary; as assets will be withdrawn but rewards won't be claimed.
    function emergencyWithdraw(uint256 amount) external override management {
        masterchef.emergencyWithdraw(pid);

        // didn't have this in original xBOO HEC strat but it's there in other gen lenders
        want.safeTransfer(vault.governance(), balanceOfWant());
        IERC20(address(xboo)).safeTransfer(vault.governance(), balanceOfXboo());
    }

    // withdraw an amount including any want balance
    function _withdraw(uint256 amount) internal returns (uint256) {
        // claim our emissionToken rewards
        _claimRewards();

        // if we have emissionToken to sell, then sell all of it
         uint256 emissionTokenBalance = emissionToken.balanceOf(address(this));
        if (emissionTokenBalance > 0 && autoSell) {
            // sell our emissionToken
            _sell(emissionTokenBalance);
        }

        uint256 _liquidatedAmount;

        uint256 balanceOfBoo = balanceOfWant();
        // if we need more boo than is already loose in the contract
        if (balanceOfBoo < amount) {
            // boo needed beyond any boo that is already loose in the contract
            uint256 amountToFree = amount.sub(balanceOfBoo);
            // converts this amount into xboo
            uint256 amountToFreeInXboo = xboo.BOOForxBOO(amountToFree);
            // any xboo that is already loose in the contract
            uint256 balanceXboo = balanceOfXboo();
            // if we need more xboo than is already loose in the contract
            if (balanceXboo < amountToFreeInXboo) {
                // new amount of xboo needed after subtracting any xboo that is already loose in the contract
                uint256 newAmountToFreeInXboo = amountToFreeInXboo.sub(balanceXboo);

                (uint256 deposited, ) =
                    ChefLike(masterchef).userInfo(pid, address(this));
                // if xboo deposited in masterchef is less than what we want, deposited becomes what we want (all)
                if (deposited < newAmountToFreeInXboo) {
                    newAmountToFreeInXboo = deposited;
                }
                // stops us trying to withdraw if xboo deposited is zero
                if (deposited > 0) {
                    ChefLike(masterchef).withdraw(pid, newAmountToFreeInXboo);
                    // updating balanceOfXboo in preparation for when we leave xboo
                    balanceXboo = balanceOfXboo();
                }
            }
            // leave = "Unlocks the staked Boo + gained Boo (which should be zero?), and burns xBoo"
            // the lowest of these two options beause balanceOfXboo might be more than we need
            xboo.leave(Math.min(amountToFreeInXboo, balanceXboo));

            
            // this address' balance of boo - should it be balanceOfWant() ???
            _liquidatedAmount = want.balanceOf(address(this));
        } else {
            // shouldn't this line also be want.balanceOf(address(this))? or actually balanceOfWant()
            _liquidatedAmount = amount;
        }
        // NEW LINE
        want.safeTransfer(address(strategy), _liquidatedAmount);
        return _liquidatedAmount;
    }

    function claimRewards() external management {
        _claimRewards(); 
    }

    function _claimRewards() internal {
        // claim our emission tokens
        masterchef.withdraw(pid, 0); 
    }

    // sell from reward token to want
    function _sell(uint256 _amount) internal {

        if(maxSell > 0){
            _amount = Math.min(maxSell, _amount);
        }        

        // we do all our sells in one go in a chain between pairs
        // inialise to 3 even if we use less to save on gas
        SellRoute[] memory sellRoute = new SellRoute[](3);

        // 1! sell our emission token for swapfirststep token
        address[] memory emissionTokenPath = new address[](2);
        emissionTokenPath[0] = address(emissionToken);
        emissionTokenPath[1] = address(swapFirstStep);
        uint256 id = 0;

        address factory = useSpiritPartOne? spiritFactory: spookyFactory;
        // we deal directly with the pairs
        address pair = IFactory(factory).getPair(emissionTokenPath[0], emissionTokenPath[1]);

        // start off by sending our emission token to the first pair. we only do this once
        emissionToken.safeTransfer(pair, _amount);

        // first
        sellRoute[id] =
                SellRoute(
                    pair,
                    emissionTokenPath[0], 
                    emissionTokenPath[1],
                    address(0)
                );

        if (address(want) == address(swapFirstStep)) {

            // end with only one step
            _uniswap_sell_with_fee(sellRoute, id);
            return;
        }

        // if the second token isnt ftm we need to do an etra step
        if(address(swapFirstStep) != address(wftm)){
            id = id+1;
            // ! 2
            emissionTokenPath[0] = address(swapFirstStep);
            emissionTokenPath[1] = address(wftm);
            
            pair = IFactory(spookyFactory).getPair(emissionTokenPath[0], emissionTokenPath[1]);
            

            // we set the to of the last step to 
            sellRoute[id-1].to = pair;

            sellRoute[id] =
                SellRoute(
                    pair,
                    emissionTokenPath[0], 
                    emissionTokenPath[1],
                    address(0)
                );

            if (address(want) == address(wftm)) {

                // end with only one step
                _uniswap_sell_with_fee(sellRoute, id);
                return;
            }
        }

        id = id+1;
        // final step is wftm to want
        emissionTokenPath[0] = address(wftm);
        emissionTokenPath[1] = address(want);
        factory = useSpiritPartTwo? spiritFactory: spookyFactory;
        pair = IFactory(factory).getPair(emissionTokenPath[0], emissionTokenPath[1]);
        

        sellRoute[id - 1].to = pair;


        sellRoute[id] =
                SellRoute(
                    pair,
                    emissionTokenPath[0], 
                    emissionTokenPath[1],
                    address(this)
                );


        // id will be 0-1-2
        _uniswap_sell_with_fee(sellRoute, id);
    }

    function _uniswap_sell_with_fee(SellRoute[] memory sell, uint256 id) internal{
        sell[id].to = address(this); // last one is always to us
        for (uint i; i < id+1; i++) {
            
            (address token0,) = _sortTokens(sell[i].input, sell[i].output);
            IUniswapV2Pair pair = IUniswapV2Pair(sell[i].pair);
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = sell[i].input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(sell[i].input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = _getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = sell[i].input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            require(sell[i].to != address(0), "burning tokens");
            pair.swap(amount0Out, amount1Out, sell[i].to, new bytes(0));
        }
    }

    function deposit() external override management {
        // send all of our want tokens to be deposited
        uint256 balance = balanceOfWant();
        // stake only if we have something to stake
        if (balance > 0) {
            // deposit our boo into xboo
            xboo.enter(balance);
            // deposit xboo into masterchef
            masterchef.deposit(pid, balanceOfXboo());
        }
    }

    function withdrawAll() external override management returns (bool) {
        uint256 invested = _nav();
        // claim our emissionToken rewards
        _claimRewards();

        // if we have emissionToken to sell, then sell all of it
         uint256 emissionTokenBalance = emissionToken.balanceOf(address(this));
        if (emissionTokenBalance > 0 && autoSell) {
            // sell our emissionToken
            _sell(emissionTokenBalance);
        }
        (uint256 stakedXboo, ) = masterchef.userInfo(pid, address(this));
        if (stakedXboo > 0) {
            ChefLike(masterchef).withdraw(pid, stakedXboo);
        }

        uint256 balanceXboo = balanceOfXboo();
        xboo.leave(balanceXboo);
        uint256 balanceOfBoo = balanceOfWant();
        want.safeTransfer(address(strategy), balanceOfBoo);
    
        
        return balanceOfBoo.add(dust) >= invested;
    }

    
    function hasAssets() external view override returns (bool) {
        return _nav() > dust;
    }

    function manualSell(uint256 _amount) external management {
        _sell(_amount);
    }

    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {}


/* ========== SETTERS ========== */

    // autosell if pools are liquid enough
    function setAutoSell(bool _autoSell)
        external
        management
    {
        autoSell = _autoSell;
    }

    // set a max sell for illiquid pools
    function setMaxSell(uint256 _maxSell)
        external
        management
    {
        maxSell = _maxSell;
    }

    // set to use spirit instead of spooky
    function setUseSpiritOne(bool _useSpirit)
        external
        management
    {
        useSpiritPartOne = _useSpirit;
    }

    // set to use spirit instead of spooky
    function setUseSpiritTwo(bool _useSpirit)
        external
        management
    {
        useSpiritPartTwo = _useSpirit;
    }
 
}