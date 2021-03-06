/**
 *Submitted for verification at FtmScan.com on 2022-04-08
*/

// Sources flattened with hardhat v2.9.2 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     * IMPORTANT: because control is transferred to `recipient`, care must be
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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


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


// File @openzeppelin/contracts/utils/math/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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


// File contracts/Node.sol


pragma solidity ^0.8.0;

contract Node {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public TOKEN;
    uint256[] public tierAllocPoints = [1 ether, 1.1 ether, 2 ether];
    uint256[] public tierAmounts = [25 ether, 100 ether, 1000 ether];
    struct User {
        uint256 total_deposits;
        uint256 total_claims;
        uint256 last_distPoints;
    }

    event CreateNode(uint256 timestamp, address account, uint256 num);

    address private dev;
    
    mapping(address => User) public users;
    mapping(address => mapping(uint256 => uint256)) public nodes;
    mapping(uint256 => uint256) public totalNodes;
    address[] public userIndices;

    uint256 public total_deposited;
    uint256 public total_claimed;
    uint256 public total_rewards;
    uint256 public treasury_rewards;
    uint256 public treasuryFeePercent;
    uint256 public totalDistributeRewards;
    uint256 public totalDistributePoints;
    uint256 public maxReturnPercent;
    uint256 public dripRate;
    uint256 public lastDripTime;
    uint256 public startTime;
    bool public enabled;
    uint256 public constant MULTIPLIER = 10e18;


    constructor(uint256 _startTime, address _token) public {
        maxReturnPercent = 500; 
        dripRate = 2400000; 
        treasuryFeePercent = 20; 

        lastDripTime = _startTime > block.timestamp ? _startTime : block.timestamp;
        startTime = _startTime;
        enabled = true;
        dev = msg.sender;
        TOKEN = IERC20(_token);
    }

    receive() external payable {
        revert("Do not send FTM.");
    }

    modifier onlyDev() {
        require(msg.sender == dev, "Caller is not the dev!");
        _;
    }

    function changeDev(address payable newDev) external onlyDev {
        require(newDev != address(0), "Zero address");
        dev = newDev;
    }

    function claimTreasuryRewards() external {
        if (treasury_rewards > 0) {
            TOKEN.safeTransfer(dev, treasury_rewards);
            treasury_rewards = 0;
        }   
    }

    function setStartTime(uint256 _startTime) external onlyDev {
        startTime = _startTime;
    }
    
    function setEnabled(bool _enabled) external onlyDev {
        enabled = _enabled;
    }

    function setTreasuryFeePercent(uint256 percent) external onlyDev {
        treasuryFeePercent = percent;
    }

    function setDripRate(uint256 rate) external onlyDev {
        dripRate = rate;
    }
    
    function setLastDripTime(uint256 timestamp) external onlyDev {
        lastDripTime = timestamp;
    }

    function setMaxReturnPercent(uint256 percent) external onlyDev {
        maxReturnPercent = percent;
    }

    function setTierValues(uint256[] memory _tierAllocPoints, uint256[] memory _tierAmounts) external onlyDev {
        require(_tierAllocPoints.length == _tierAmounts.length, "Length mismatch");
        tierAllocPoints = _tierAllocPoints;
        tierAmounts = _tierAmounts;
    }

    function setUser(address _addr, User memory _user) external onlyDev {
        total_deposited = total_deposited.sub(users[_addr].total_deposits).add(_user.total_deposits);
        total_claimed = total_claimed.sub(users[_addr].total_claims).add(_user.total_claims);
        users[_addr].total_deposits = _user.total_deposits;
        users[_addr].total_claims = _user.total_claims;
    }

    function setNodes(address _user, uint256[] memory _nodes) external onlyDev {
        for(uint256 i = 0; i < _nodes.length; i++) {
            totalNodes[i] = totalNodes[i].sub(nodes[_user][i]).add( _nodes[i]);
            nodes[_user][i] = _nodes[i];
        }
    }

    function totalAllocPoints() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < tierAllocPoints.length; i++) {
            total = total.add(tierAllocPoints[i].mul(totalNodes[i]));
        }
        return total;
    }

    function allocPoints(address account) public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < tierAllocPoints.length; i++) {
            total = total.add(tierAllocPoints[i].mul(nodes[account][i]));
        }
        return total;
    }

    function getDistributionRewards(address account) public view returns (uint256) {
        if (isMaxPayout(account)) return 0;

        uint256 newDividendPoints = totalDistributePoints.sub(users[account].last_distPoints);
        uint256 distribute = allocPoints(account).mul(newDividendPoints).div(MULTIPLIER);
        return distribute > total_rewards ? total_rewards : distribute;
    }
    
    function getTotalRewards(address _sender) public view returns (uint256) {
        if (users[_sender].total_deposits == 0) 
            return 0;
        
        uint256 rewards = getDistributionRewards(_sender).add(getRewardDrip().mul(allocPoints(_sender)).div(totalAllocPoints()));
        uint256 totalClaims = users[_sender].total_claims;
        uint256 maxPay = maxPayout(_sender);

        // Payout remaining if exceeds max payout
        return totalClaims.add(rewards) > maxPay ? maxPay.sub(totalClaims) : rewards;
    }


    function create(uint256 nodeTier, uint256 numNodes) external {
        address _sender = msg.sender;
        require(enabled && block.timestamp >= startTime, "Disabled");
        require(nodeTier < tierAllocPoints.length && nodeTier < tierAmounts.length, "Invalid nodeTier");

        if (users[_sender].total_deposits == 0) {
            userIndices.push(_sender); // New user
            users[_sender].last_distPoints = totalDistributePoints;
        } 
        if (users[_sender].total_deposits != 0 && isMaxPayout(_sender)) {
            users[_sender].last_distPoints = totalDistributePoints;
        }

        uint256 tierPrice = tierAmounts[nodeTier].mul(numNodes);
        
        require(TOKEN.balanceOf(_sender) >= tierPrice, "Insufficient balance");
        require(TOKEN.allowance(_sender, address(this)) >= tierPrice, "Insufficient allowance");
        TOKEN.safeTransferFrom(_sender, address(this), tierPrice);

        users[_sender].total_deposits = users[_sender].total_deposits.add(tierPrice);
        
        total_deposited = total_deposited.add(tierPrice);
        treasury_rewards = treasury_rewards.add(
            tierPrice.mul(treasuryFeePercent).div(100)
        );
        
        nodes[_sender][nodeTier] = nodes[_sender][nodeTier].add(numNodes);
        totalNodes[nodeTier] = totalNodes[nodeTier].add(numNodes);

        emit CreateNode(block.timestamp, _sender, numNodes);
    }

    function claim() public {
        dripRewards();

        address _sender = msg.sender;
        uint256 _rewards = getDistributionRewards(_sender);
        
        if (_rewards > 0) {
            
            total_rewards = total_rewards.sub(_rewards);
            uint256 totalClaims = users[_sender].total_claims;
            uint256 maxPay = maxPayout(_sender);

            // Payout remaining if exceeds max payout
            if(totalClaims.add(_rewards) > maxPay) {
                _rewards = maxPay.sub(totalClaims);
            }

            users[_sender].total_claims = users[_sender].total_claims.add(_rewards);
            total_claimed = total_claimed.add(_rewards);

            IERC20(TOKEN).safeTransfer(_sender, _rewards);
            
            users[_sender].last_distPoints = totalDistributePoints;
        }
    }

    function _compound(uint256 nodeTier, uint256 numNodes) internal {
        address _sender = msg.sender;
        require(enabled && block.timestamp >= startTime, "Disabled");
        require(nodeTier < tierAllocPoints.length && nodeTier < tierAmounts.length, "Invalid nodeTier");

        if (users[_sender].total_deposits == 0) {
            userIndices.push(_sender); // New user
            users[_sender].last_distPoints = totalDistributePoints;
        } 
        if (users[_sender].total_deposits != 0 && isMaxPayout(_sender)) {
            users[_sender].last_distPoints = totalDistributePoints;
        }

        uint256 tierPrice = tierAmounts[nodeTier].mul(numNodes);
        
        require(TOKEN.balanceOf(_sender) >= tierPrice, "Insufficient balance");
        require(TOKEN.allowance(_sender, address(this)) >= tierPrice, "Insufficient allowance");
        TOKEN.safeTransferFrom(_sender, address(this), tierPrice);

        users[_sender].total_deposits = users[_sender].total_deposits.add(tierPrice);
        
        total_deposited = total_deposited.add(tierPrice);
        treasury_rewards = treasury_rewards.add(
            tierPrice.mul(treasuryFeePercent).div(100)
        );
        
        nodes[_sender][nodeTier] = nodes[_sender][nodeTier].add(numNodes);
        totalNodes[nodeTier] = totalNodes[nodeTier].add(numNodes);

        emit CreateNode(block.timestamp, _sender, numNodes);
    }

    function compound() public {
      uint256 rewardsPending = getTotalRewards(msg.sender);  
      require(rewardsPending >= tierAmounts[0], "Not enough to compound");  
      uint256 numPossible = rewardsPending.div(tierAmounts[0]);
      claim();
      _compound(0, numPossible);
    }


    function maxPayout(address _sender) public view returns (uint256) {
        return users[_sender].total_deposits.mul(maxReturnPercent).div(100);
    }

    function isMaxPayout(address _sender) public view returns (bool) {
        return users[_sender].total_claims >= maxPayout(_sender);
    }

    function _disperse(uint256 amount) internal {
        if (amount > 0 ) {
            totalDistributePoints = totalDistributePoints.add(amount.mul(MULTIPLIER).div(totalAllocPoints()));
            totalDistributeRewards = totalDistributeRewards.add(amount);
            total_rewards = total_rewards.add(amount);
        }
    }

    function dripRewards() public {
        uint256 drip = getRewardDrip();

        if (drip > 0) {
            _disperse(drip);
            lastDripTime = block.timestamp;
        }
    }

    function getRewardDrip() public view returns (uint256) {
        if (lastDripTime < block.timestamp) {
            uint256 poolBalance = getBalancePool();
            uint256 secondsPassed = block.timestamp.sub(lastDripTime);
            uint256 drip = secondsPassed.mul(poolBalance).div(dripRate);

            if (drip > poolBalance) {
                drip = poolBalance;
            }

            return drip;
        }
        return 0;
    }

    function getDayDripEstimate(address _user) external view returns (uint256) {
        return
            allocPoints(_user) > 0 && !isMaxPayout(_user)
                ? getBalancePool()
                    .mul(86400)
                    .mul(allocPoints(_user))
                    .div(totalAllocPoints())
                    .div(dripRate)
                : 0;
    }

    function getDayDripEstimateByTier(uint256 _tier) external view returns (uint256) {
        uint256 alloc = tierAllocPoints[_tier].mul(totalNodes[_tier]);
        return
            getBalancePool()
                .mul(86400)
                .mul(alloc)
                .div(totalAllocPoints())
                .div(dripRate);
    }

    function total_users() external view returns (uint256) {
        return userIndices.length;
    }

    function numNodes(address _sender, uint256 _nodeId) external view returns (uint256) {
        return nodes[_sender][_nodeId];
    }

    function getNodes(address _sender) external view returns (uint256[] memory) {
        uint256[] memory userNodes = new uint256[](tierAllocPoints.length);
        for (uint256 i = 0; i < tierAllocPoints.length; i++) {
            userNodes[i] = userNodes[i].add(nodes[_sender][i]);
        }
        return userNodes;
    }
    
    function getTotalNodes() external view returns (uint256[] memory) {
        uint256[] memory totals = new uint256[](tierAllocPoints.length);
        for (uint256 i = 0; i < tierAllocPoints.length; i++) {
            totals[i] = totals[i].add(totalNodes[i]);
        }
        return totals;
    }

    function getTotalAllocPoints() external view returns (uint256[] memory) {
        uint256[] memory totals = new uint256[](tierAllocPoints.length);
        for (uint256 i = 0; i < tierAllocPoints.length; i++) {
            totals[i] = totals[i].add(tierAllocPoints[i].mul(totalNodes[i]));
        }
        return totals;        
    }

    function getBalance() public view returns (uint256) {
        return IERC20(TOKEN).balanceOf(address(this));
    }

     function getBalancePool() public view returns (uint256) {
        return getBalance().sub(total_rewards).sub(treasury_rewards);
    }
}