/**
 *Submitted for verification at FtmScan.com on 2022-03-20
*/

// Sources flattened with hardhat v2.8.2 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/math/[email protected]

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


// File contracts/interfaces/IERC20Lockable.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Lockable is IERC20 {
    function lock(address _holder, uint256 _amount) external;
}


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/GSN/[email protected]


// File @openzeppelin/contracts/access/[email protected]

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


// File contracts/owner/Operator.sol


contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() internal {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOperator { // Not sure why owner is allowed to change operator.  For security reasons, the operator will be the only one allowed to do this. This way we can change parameters without being able to do many scary things.
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}


// File contracts/Authorizable.sol

contract Authorizable is Operator {
    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender || operator() == msg.sender, "caller is not authorized");
        _;
    }

    function addAuthorized(address _toAdd) public onlyOwner {
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) public onlyOwner {
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }
}


// File contracts/interfaces/ITreasury.sol

interface ITreasury {
    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function getGamePrice() external view returns (uint256);

    function gamePriceOne() external view returns (uint256);
    function gamePriceCeiling() external view returns (uint256);
    function initialized() external view returns (bool);
    function daoFund() external view returns (address);

    function buyBonds(uint256 amount, uint256 targetPrice) external;

    function redeemBonds(uint256 amount, uint256 targetPrice) external;
}


// File contracts/utils/ContractGuard.sol

contract ContractGuard {
    mapping(uint256 => mapping(address => bool)) private _status;

    function checkSameOriginReentranted() internal view returns (bool) {
        return _status[block.number][tx.origin];
    }

    function checkSameSenderReentranted() internal view returns (bool) {
        return _status[block.number][msg.sender];
    }

    modifier onlyOneBlock() {
        require(!checkSameOriginReentranted(), "ContractGuard: one block, one function");
        require(!checkSameSenderReentranted(), "ContractGuard: one block, one function");

        _;

        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;
    }
}


// File contracts/distribution/TheoryRewardPool.sol







// Note that this pool has no minter key of THEORY (rewards).
// Instead, the governance will call THEORY distributeReward method and send reward to this pool at the beginning.
contract TheoryRewardPool is Authorizable, ContractGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Lockable;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt.
        uint256 rewardDebtAtTime; // The last time that the user has staked.
        uint256 lastDepositBlock;
        uint256 lastWithdrawTime;
        uint256 firstDepositTime;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. THEORYs to distribute per block.
        uint256 lastRewardTime; // Last time that THEORYs distribution occurs.
        uint256 accTheoryPerShare; // Accumulated THEORYs per share, times 1e18.
        bool isStarted; // if lastRewardTime has passed
    }

    IERC20Lockable public theory;
    ITreasury public treasury;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The time when THEORY mining starts.
    uint256 public poolStartTime;

    // The time when THEORY mining ends.
    uint256 public poolEndTime;

    uint256 public baseTheoryPerSecond = 0.0004692175 ether; // Allocation is based on this.
    uint256 public runningTime = 365 days; // 365 days

    uint256 public sameBlockFee;
    uint256[] public feeStagePercentage; //In 10000s for decimal
    uint256[] public feeStageTime;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount, uint256 lockAmount);

    // Bonus multiplier for early THEORY makers.
    uint256[] public REWARD_MULTIPLIER; // init in constructor function
    uint256[] public HALVING_AT_TIME; // init in constructor function
    uint256 public FINISH_BONUS_AT_TIME;

    uint256[] public PERCENT_LOCK_BONUS_REWARD; // lock xx% of bonus reward

    constructor(
        address _theory,
        ITreasury _treasury,
        uint256 _poolStartTime,
        uint256 _halvingAfterTime,
        uint256[] memory _rewardMultiplier,
        uint256[] memory _percentLockBonusRewards
    ) public {
        require(block.timestamp < _poolStartTime, "late");
        if (_theory != address(0)) theory = IERC20Lockable(_theory);
        treasury = _treasury;
        poolStartTime = _poolStartTime;
        poolEndTime = poolStartTime + runningTime;
        sameBlockFee = 2500;
        feeStageTime = [0, 1 hours, 1 days, 3 days, 5 days, 2 weeks, 4 weeks];
        feeStagePercentage = [800, 400, 200, 100, 50, 25, 1];
        REWARD_MULTIPLIER = _rewardMultiplier;
        uint256 i;
        uint256 len = _percentLockBonusRewards.length;
        for(i = 0; i < len; i += 1)
        {
            require(_percentLockBonusRewards[i] <= 95, "Lock % can't be higher than 95%.");
        }
        PERCENT_LOCK_BONUS_REWARD = _percentLockBonusRewards;
        len = REWARD_MULTIPLIER.length - 1;
        for (i = 0; i < len; i += 1) {
            uint256 halvingAtTime = _halvingAfterTime.mul(i+1).add(poolStartTime).add(1);
            HALVING_AT_TIME.push(halvingAtTime);
        }
        FINISH_BONUS_AT_TIME = _halvingAfterTime
        .mul(len)
        .add(poolStartTime);
        HALVING_AT_TIME.push(uint256(-1));
    }

    function reviseDeposit(uint256 _pid, address _user, uint256 _time) public onlyAuthorized() {
        userInfo[_pid][_user].firstDepositTime = _time;
    }

    function reviseWithdraw(uint256 _pid, address _user, uint256 _time) public onlyAuthorized() {
        userInfo[_pid][_user].lastWithdrawTime = _time;
    }

    //Careful of gas.
    function setFeeStages(uint256[] memory _feeStageTime, uint256[] memory _feeStagePercentage) public onlyAuthorized() {
        require(_feeStageTime.length > 0
        && _feeStageTime[0] == 0
            && _feeStagePercentage.length == _feeStageTime.length,
            "Fee stage arrays must be equal in non-zero length and time should start at 0.");
        feeStageTime = _feeStageTime;
        uint256 i;
        uint256 len = _feeStagePercentage.length;
        for(i = 0; i < len; i += 1)
        {
            require(_feeStagePercentage[i] <= 800, "Fee can't be higher than 8%.");
        }
        feeStagePercentage = _feeStagePercentage;
    }

    function setSameBlockFee(uint256 _fee) public onlyAuthorized() {
        require(_fee <= 2500, "Fee can't be higher than 25%.");
        sameBlockFee = _fee;
    }

    // Return reward multiplier over the given _from to _to time. Careful of gas when it is used in a transaction.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        uint256 result = 0;
        if (_from < poolStartTime) return 0;

        for (uint256 i = 0; i < HALVING_AT_TIME.length; i++) {
            uint256 endTime = HALVING_AT_TIME[i];
            if (i > REWARD_MULTIPLIER.length-1) return 0;

            if (_to <= endTime) {
                uint256 m = _to.sub(_from).mul(REWARD_MULTIPLIER[i]);
                return result.add(m);
            }

            if (_from < endTime) {
                uint256 m = endTime.sub(_from).mul(REWARD_MULTIPLIER[i]);
                _from = endTime;
                result = result.add(m);
            }
        }

        return result;
    }

    function getRequiredAllocation() public view returns (uint256)
    {
        uint256 _generatedReward = getGeneratedReward(poolStartTime, poolEndTime);
        return _generatedReward;
    }

    function getCurrentLockPercentage(uint256 _pid, address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        uint256 currentTime = block.timestamp;
        if (user.rewardDebtAtTime <= FINISH_BONUS_AT_TIME) {
            // If we are before the FINISH_BONUS_AT_TIME number, we need
            // to lock some of those tokens, based on the current lock
            // percentage of their tokens they just received.
            uint256 lockPercentage = getLockPercentage(currentTime > 0 ? currentTime.sub(1) : currentTime, currentTime);
            return lockPercentage;
        }
        return 0;
    }

    // Careful of gas when it is used in a transaction.
    function getLockPercentage(uint256 _from, uint256 _to) public view returns (uint256) {
        uint256 result = 0;
        if (_from < poolStartTime) return 100;
        if (_to >= poolEndTime) return 0;
        if (_to >= FINISH_BONUS_AT_TIME) return 0;

        for (uint256 i = 0; i < HALVING_AT_TIME.length; i++) {
            uint256 endTime = HALVING_AT_TIME[i];
            if (i > PERCENT_LOCK_BONUS_REWARD.length-1) return 0;

            if (_to <= endTime) {
                return PERCENT_LOCK_BONUS_REWARD[i];
            }
        }

        return result;
    }

    // Update Rewards Multiplier Array
    function rewardMulUpdate(uint256[] memory _newMulReward) public onlyAuthorized {
        REWARD_MULTIPLIER = _newMulReward;
    }

    // Update % lock for general users. Be careful of gas.
    function lockUpdate(uint256[] memory _newLock) public onlyAuthorized {
        uint256 i;
        uint256 len = _newLock.length;
        for(i = 0; i < len; i += 1)
        {
            require(_newLock[i] <= 95, "Lock % can't be higher than 95%.");
        }
        PERCENT_LOCK_BONUS_REWARD = _newLock;
    }

    // Update Finish Bonus Block
    function bonusFinishUpdate(uint256 _newFinish) public onlyAuthorized {
        FINISH_BONUS_AT_TIME = _newFinish;
    }

    // Update Halving At Block
    function halvingUpdate(uint256[] memory _newHalving) public onlyAuthorized {
        HALVING_AT_TIME = _newHalving;
    }

    function checkPoolDuplicate(IERC20 _token) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].token != _token, "TheoryRewardPool: existing pool?");
        }
    }

    // Allow us to delay or begin earlier if we have not started yet. Careful of gas.
    function setPoolStartTime(
        uint256 _time
    ) public onlyAuthorized
    {
        require(block.timestamp < poolStartTime, "Already started.");
        require(block.timestamp < _time, "Time input is too early.");
        require(_time < poolEndTime, "Time is after end time, please change end time first.");
        uint256 length = poolInfo.length;
        uint256 pid = 0;
        uint256 _lastRewardTime;
        for (pid = 0; pid < length; pid += 1) {
            PoolInfo storage pool = poolInfo[pid];
            _lastRewardTime = pool.lastRewardTime;
            if (_lastRewardTime == poolStartTime || _lastRewardTime < _time) {
                pool.lastRewardTime = _time;
            }
        }
        poolStartTime = _time;
    }

    function setPoolEndTime(
        uint256 _time
    ) public onlyAuthorized
    {
        require(block.timestamp < poolStartTime, "Already started.");
        require(poolStartTime < _time, "Time input is too early.");
        poolEndTime = _time;
        runningTime = poolEndTime - poolStartTime;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        bool _withUpdate,
        uint256 _lastRewardTime
    ) public onlyOperator {
        checkPoolDuplicate(_token);
        if (_withUpdate) {
            massUpdatePools();
        }
        if (block.timestamp < poolStartTime) {
            // chef is sleeping
            if (_lastRewardTime < poolStartTime) {
                _lastRewardTime = poolStartTime;
            }
        } else {
            // chef is cooking
            if (_lastRewardTime < block.timestamp) { // Why was == 0 here and above? Isn't that redundant?
                _lastRewardTime = block.timestamp;
            }
        }
        bool _isStarted =
        (_lastRewardTime <= poolStartTime) ||
        (_lastRewardTime <= block.timestamp);
        poolInfo.push(PoolInfo({
            token : _token,
            allocPoint : _allocPoint,
            lastRewardTime : _lastRewardTime,
            accTheoryPerShare : 0,
            isStarted : _isStarted
            }));
        if (_isStarted) {
            totalAllocPoint = totalAllocPoint.add(_allocPoint);
        }
    }

    // Update the given pool's THEORY allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint) public onlyOperator {
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.isStarted) {
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(
                _allocPoint
            );
        }
        pool.allocPoint = _allocPoint;
    }

    function getTheoryPerSecondInPool(uint256 _pid) public view returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 _poolTheoryPerSecond = getMultiplier(block.timestamp - 1, block.timestamp).mul(baseTheoryPerSecond).mul(pool.allocPoint).div(totalAllocPoint);
        return _poolTheoryPerSecond;
    }

    function getWithdrawFeeOf(uint256 _pid, address _user) public view returns (uint256)
    {
        UserInfo storage user = userInfo[_pid][_user];
        uint256 fee = sameBlockFee;
        if(block.number != user.lastDepositBlock)
        {
            if (!(user.firstDepositTime > 0)) {
                return feeStagePercentage[0];
            }
            uint256 deltaTime = user.lastWithdrawTime > 0 ?
            block.timestamp - user.lastWithdrawTime :
            block.timestamp - user.firstDepositTime;
            uint256 len = feeStageTime.length;
            uint256 n;
            uint256 i;
            for (n = len; n > 0; n -= 1) {
                i = n-1;
                if(deltaTime >= feeStageTime[i])
                {
                    fee = feeStagePercentage[i];
                    break;
                }
            }
        }
        return fee;
    }

    // Return accumulate rewards over the given _from to _to block.
    function getGeneratedReward(uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
        if (_fromTime >= _toTime) return 0;
        if (_toTime >= poolEndTime) {
            if (_fromTime >= poolEndTime) return 0;
            if (_fromTime <= poolStartTime) return getMultiplier(poolStartTime, poolEndTime).mul(baseTheoryPerSecond);
            return getMultiplier(_fromTime, poolEndTime).mul(baseTheoryPerSecond);
        } else {
            if (_toTime <= poolStartTime) return 0;
            if (_fromTime <= poolStartTime) return getMultiplier(poolStartTime, _toTime).mul(baseTheoryPerSecond);
            return getMultiplier(_fromTime, _toTime).mul(baseTheoryPerSecond);
        }
    }

    // View function to see pending THEORYs on frontend.
    function pendingShare(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTheoryPerShare = pool.accTheoryPerShare;
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _theoryReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            accTheoryPerShare = accTheoryPerShare.add(_theoryReward.mul(1e18).div(tokenSupply));
        }
        return user.amount.mul(accTheoryPerShare).div(1e18).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() internal { // Too scared of scary reentrancy warnings. Internal version.
        uint256 length = poolInfo.length;
        uint256 pid = 0;
        for (pid = 0; pid < length; pid += 1) {
            updatePool(pid);
        }
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function forceMassUpdatePools() external onlyAuthorized { // Too scared of scary reentrancy warnings. External version.
        massUpdatePools();
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) internal { // Too scared of scary reentrancy warnings. Internal version.
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (tokenSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        if (!pool.isStarted) {
            pool.isStarted = true;
            totalAllocPoint = totalAllocPoint.add(pool.allocPoint);
        }
        if (totalAllocPoint > 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _theoryReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            pool.accTheoryPerShare = pool.accTheoryPerShare.add(_theoryReward.mul(1e18).div(tokenSupply));
        }
        pool.lastRewardTime = block.timestamp;
    }

    // Update reward variables of the given pool to be up-to-date.
    function forceUpdatePool(uint256 _pid) external onlyAuthorized { // Too scared of scary reentrancy warnings. External version.
        updatePool(_pid);
    }

    // Deposit LP tokens.
    function deposit(uint256 _pid, uint256 _amount) public onlyOneBlock { // Poor smart contracts, can't deposit to multiple pools at once... But my OCD will not allow this.
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 _pending = user.amount.mul(pool.accTheoryPerShare).div(1e18).sub(user.rewardDebt);
            if (_pending > 0) {
                safeTheoryTransfer(_sender, _pending);
                uint256 lockAmount = 0;
                uint256 currentTime = block.timestamp;
                if (user.rewardDebtAtTime <= FINISH_BONUS_AT_TIME) {
                    // If we are before the FINISH_BONUS_AT_TIME number, we need
                    // to lock some of those tokens, based on the current lock
                    // percentage of their tokens they just received.
                    uint256 lockPercentage = getLockPercentage(currentTime > 0 ? currentTime.sub(1) : currentTime, currentTime);
                    lockAmount = _pending.mul(lockPercentage).div(100);
                    if(lockAmount > 0) theory.lock(_sender, lockAmount);
                }

                // Reset the rewardDebtAtTime to the current time for the user.
                user.rewardDebtAtTime = currentTime;
                emit RewardPaid(_sender, _pending, lockAmount);
            }
        }
        else
        {
            user.rewardDebtAtTime = block.timestamp;
        }
        user.lastDepositBlock = block.number;
        if (!(user.firstDepositTime > 0)) {
            user.firstDepositTime = block.timestamp;
        }
        if (_amount > 0) {
            pool.token.safeTransferFrom(_sender, address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accTheoryPerShare).div(1e18);
        emit Deposit(_sender, _pid, _amount);
    }

    // Withdraw LP tokens.
    function withdraw(uint256 _pid, uint256 _amount) public onlyOneBlock {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 _pending = user.amount.mul(pool.accTheoryPerShare).div(1e18).sub(user.rewardDebt);
        if (_pending > 0) {
            safeTheoryTransfer(_sender, _pending);
            uint256 lockAmount = 0;
            uint256 currentTime = block.timestamp;
            if (user.rewardDebtAtTime <= FINISH_BONUS_AT_TIME) {
                // If we are before the FINISH_BONUS_AT_TIME number, we need
                // to lock some of those tokens, based on the current lock
                // percentage of their tokens they just received.
                uint256 lockPercentage = getLockPercentage(currentTime > 0 ? currentTime.sub(1) : currentTime, currentTime);
                lockAmount = _pending.mul(lockPercentage).div(100);
                if(lockAmount > 0) theory.lock(_sender, lockAmount);
            }

            // Reset the rewardDebtAtTime to the current time for the user.
            user.rewardDebtAtTime = currentTime;
            emit RewardPaid(_sender, _pending, lockAmount);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            uint256 fee = sameBlockFee;
            if(block.number != user.lastDepositBlock)
            {
                uint256 deltaTime = user.lastWithdrawTime > 0 ?
                block.timestamp - user.lastWithdrawTime :
                block.timestamp - user.firstDepositTime;
                uint256 len = feeStageTime.length;
                uint256 n;
                uint256 i;
                for (n = len; n > 0; n -= 1) {
                    i = n-1;
                    if(deltaTime >= feeStageTime[i])
                    {
                        fee = feeStagePercentage[i];
                        break;
                    }
                }
            }
            user.lastWithdrawTime = block.timestamp;
            uint256 feeAmount = _amount.mul(fee).div(10000);
            uint256 amountToGive = _amount.sub(feeAmount);
            if(feeAmount > 0) pool.token.safeTransfer(treasury.daoFund(), feeAmount);
            pool.token.safeTransfer(_sender, amountToGive);
        }
        user.rewardDebt = user.amount.mul(pool.accTheoryPerShare).div(1e18);
        emit Withdraw(_sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY. This has the same fee as same block withdrawals to prevent abuse of this function.
    function emergencyWithdraw(uint256 _pid) public onlyOneBlock {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 fee = sameBlockFee;
        uint256 feeAmount = user.amount.mul(fee).div(10000);
        uint256 amountToGive = user.amount.sub(feeAmount);
        user.amount = 0;
        user.rewardDebt = 0;
        pool.token.safeTransfer(msg.sender, amountToGive);
        pool.token.safeTransfer(treasury.daoFund(), feeAmount);
        emit EmergencyWithdraw(msg.sender, _pid, amountToGive);
    }

    // Safe theory transfer function, just in case if rounding error causes pool to not have enough THEORYs.
    function safeTheoryTransfer(address _to, uint256 _amount) internal {
        uint256 _theoryBal = theory.balanceOf(address(this));
        if (_theoryBal > 0) {
            if (_amount > _theoryBal) {
                theory.safeTransfer(_to, _theoryBal);
            } else {
                theory.safeTransfer(_to, _amount);
            }
        }
    }

    function governanceRecoverUnsupported(IERC20 _token, uint256 amount, address to) external onlyAuthorized { //I don't know the point of these functions if we can't even call them once the Treasury is operator, so they should all be onlyAuthorized instead.
        if (block.timestamp < poolEndTime + 90 days) {
            // do not allow to drain core token (THEORY or lps) if less than 90 days after pool ends
            require(_token != theory, "theory");
            uint256 length = poolInfo.length;
            for (uint256 pid = 0; pid < length; ++pid) {
                PoolInfo storage pool = poolInfo[pid];
                require(_token != pool.token, "pool.token");
            }
        }
        _token.safeTransfer(to, amount);
    }
}