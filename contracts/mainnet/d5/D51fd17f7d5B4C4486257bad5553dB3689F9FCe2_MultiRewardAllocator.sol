/**
 *Submitted for verification at FtmScan.com on 2022-04-26
*/

// Sources flattened with hardhat v2.8.2 https://hardhat.org

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


// File @openzeppelin/contracts/security/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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


// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}


// File contracts/DelayedActionGuard.sol


pragma solidity 0.8.9;

abstract contract DelayedActionGuard
{
	uint256 private constant DEFAULT_WAIT_INTERVAL = 1 days;
	uint256 private constant DEFAULT_OPEN_INTERVAL = 1 days;

	struct DelayedAction {
		uint256 release;
		uint256 expiration;
	}

	mapping (address => mapping (bytes32 => DelayedAction)) private actions_;

	modifier delayed()
	{
		bytes32 _actionId = keccak256(msg.data);
		DelayedAction storage _action = actions_[msg.sender][_actionId];
		require(_action.release <= block.timestamp && block.timestamp < _action.expiration, "invalid action");
		delete actions_[msg.sender][_actionId];
		emit ExecuteDelayedAction(msg.sender, _actionId);
		_;
	}

	function announceDelayedAction(bytes calldata _data) external
	{
		bytes4 _selector = bytes4(_data);
		bytes32 _actionId = keccak256(_data);
		(uint256 _wait, uint256 _open) = _delayedActionIntervals(_selector);
		uint256 _release = block.timestamp + _wait;
		uint256 _expiration = _release + _open;
		actions_[msg.sender][_actionId] = DelayedAction({ release: _release, expiration: _expiration });
		emit AnnounceDelayedAction(msg.sender, _actionId, _selector, _data, _release, _expiration);
	}

	function _delayedActionIntervals(bytes4 _selector) internal pure virtual returns (uint256 _wait, uint256 _open)
	{
		_selector;
		return (DEFAULT_WAIT_INTERVAL, DEFAULT_OPEN_INTERVAL);
	}

	event AnnounceDelayedAction(address indexed _sender, bytes32 indexed _actionId, bytes4 indexed _selector, bytes _data, uint256 _release, uint256 _expiration);
	event ExecuteDelayedAction(address indexed _sender, bytes32 indexed _actionId);
}


// File contracts/IERC20Historical.sol


pragma solidity 0.8.9;

interface IERC20Historical is IERC20
{
	function totalSupply(uint256 _when) external view returns (uint256 _totalSupply);
	function balanceOf(address _account, uint256 _when) external view returns (uint256 _balance);

	function checkpoint() external;
}

interface IERC20HistoricalCumulative is IERC20Historical
{
	function cumulativeTotalSupply(uint256 _when) external view returns (uint256 _cumulativeTotalSupply);
	function cumulativeBalanceOf(address _account, uint256 _when) external view returns (uint256 _cumulativeBalance);
}


// File contracts/IOwnership.sol


pragma solidity 0.8.9;

interface IOwnership
{
	function token() external view returns (address _token);
	function totalOwnership(uint256 _when) external view returns (uint256 _totalOwnership);
	function localOwnership(address _account, uint256 _when) external view returns (uint256 _localOwnership);
	function totalOwnershipPersist(uint256 _when) external returns (uint256 _totalOwnership);
	function localOwnershipPersist(address _account, uint256 _when) external returns (uint256 _localOwnership);
}

interface ICumulativeOwnership is IOwnership
{
	function period() external view returns (uint256 _period);
}

contract Ownership is IOwnership
{
	address public override immutable token;

	struct Entry {
		bool cached;
		uint256 value;
	}

	mapping(address => mapping(uint256 => Entry)) private cache_;

	constructor(address _token)
	{
		token = _token;
	}

	function totalOwnership(uint256 _when) external view override returns (uint256 _totalOwnership)
	{
		return _totalv(_when);
	}

	function totalOwnershipPersist(uint256 _when) external override returns (uint256 _totalOwnership)
	{
		if (_when >= block.timestamp) return _totalv(_when);
		return _total(_when);
	}

	function localOwnership(address _account, uint256 _when) external view override returns (uint256 _localOwnership)
	{
		return _localv(_account, _when);
	}

	function localOwnershipPersist(address _account, uint256 _when) external override returns (uint256 _localOwnership)
	{
		if (_when >= block.timestamp) return _localv(_account, _when);
		return _local(_account, _when);
	}

	function _totalv(uint256 _when) internal view returns (uint256 _value)
	{
		Entry storage _entry = cache_[address(0)][_when];
		if (_entry.cached) return _entry.value;
		return IERC20Historical(token).totalSupply(_when);
	}

	function _total(uint256 _when) internal returns (uint256 _value)
	{
		Entry storage _entry = cache_[address(0)][_when];
		if (_entry.cached) return _entry.value;
		_value = IERC20Historical(token).totalSupply(_when);
		_entry.cached = true;
		_entry.value = _value;
		return _value;
	}

	function _localv(address _account, uint256 _when) internal view returns (uint256 _value)
	{
		Entry storage _entry = cache_[_account][_when];
		if (_entry.cached) return _entry.value;
		return IERC20Historical(token).balanceOf(_account, _when);
	}

	function _local(address _account, uint256 _when) internal returns (uint256 _value)
	{
		Entry storage _entry = cache_[_account][_when];
		if (_entry.cached) return _entry.value;
		_value = IERC20Historical(token).balanceOf(_account, _when);
		_entry.cached = true;
		_entry.value = _value;
		return _value;
	}
}

contract CumulativeOwnership is ICumulativeOwnership
{
	address public override immutable token;
	uint256 public override immutable period;

	struct Entry {
		bool cached;
		uint256 value;
	}

	mapping(address => mapping(uint256 => Entry)) private cache_;

	constructor(address _token, uint256 _period)
	{
		token = _token;
		period = _period;
	}

	function totalOwnership(uint256 _when) external view override returns (uint256 _totalOwnership)
	{
		return _totalv(_when) - _totalv(_when - period);
	}

	function totalOwnershipPersist(uint256 _when) external override returns (uint256 _totalOwnership)
	{
		if (_when >= block.timestamp) return _totalv(_when) - _totalv(_when - period);
		return _total(_when) - _total(_when - period);
	}

	function localOwnership(address _account, uint256 _when) external view override returns (uint256 _localOwnership)
	{
		return _localv(_account, _when) - _localv(_account, _when - period);
	}

	function localOwnershipPersist(address _account, uint256 _when) external override returns (uint256 _localOwnership)
	{
		if (_when >= block.timestamp) return _localv(_account, _when) - _localv(_account, _when - period);
		return _local(_account, _when) - _local(_account, _when - period);
	}

	function _totalv(uint256 _when) internal view returns (uint256 _value)
	{
		Entry storage _entry = cache_[address(0)][_when];
		if (_entry.cached) return _entry.value;
		return IERC20HistoricalCumulative(token).cumulativeTotalSupply(_when);
	}

	function _total(uint256 _when) internal returns (uint256 _value)
	{
		Entry storage _entry = cache_[address(0)][_when];
		if (_entry.cached) return _entry.value;
		_value = IERC20HistoricalCumulative(token).cumulativeTotalSupply(_when);
		_entry.cached = true;
		_entry.value = _value;
		return _value;
	}

	function _localv(address _account, uint256 _when) internal view returns (uint256 _value)
	{
		Entry storage _entry = cache_[_account][_when];
		if (_entry.cached) return _entry.value;
		return IERC20HistoricalCumulative(token).cumulativeBalanceOf(_account, _when);
	}

	function _local(address _account, uint256 _when) internal returns (uint256 _value)
	{
		Entry storage _entry = cache_[_account][_when];
		if (_entry.cached) return _entry.value;
		_value = IERC20HistoricalCumulative(token).cumulativeBalanceOf(_account, _when);
		_entry.cached = true;
		_entry.value = _value;
		return _value;
	}
}


// File contracts/RewardDistributor.sol


pragma solidity 0.8.9;






contract RewardDistributor is Ownable, ReentrancyGuard, DelayedActionGuard
{
	using SafeERC20 for IERC20;

	address constant FURNACE = 0x000000000000000000000000000000000000dEaD;

	uint256 constant MAX_CLAIM_PERIODS = 26; // ~1/2 year

	uint256 public constant CLAIM_BASIS = 1 weeks;
	uint256 public constant MIN_ALLOC_TIME = 1 days;
	uint256 public constant MIN_ALLOC_AMOUNT = 10e18; // 10 coins

	uint256 constant DEFAULT_PENALTY_RATE = 50e16; // 50%
	uint256 constant DEFAULT_PENALTY_PERIODS = 13; // 13 weeks
	uint256 constant MAXIMUM_PENALTY_PERIODS = 5 * 52; // ~5 years

	address public immutable rewardToken;
	address public immutable escrowToken;
	address public immutable boostToken;

	address public immutable escrowOwnership;
	address public immutable boostOwnership;

	address public treasury;

	uint256 public penaltyRate = DEFAULT_PENALTY_RATE;
	uint256 public penaltyPeriods = DEFAULT_PENALTY_PERIODS;
	address public penaltyRecipient = FURNACE;

	address public excessRecipient = address(this);

	uint256 private lastAlloc_;
	uint256 private rewardBalance_;
	mapping(uint256 => uint256) private rewardPerPeriod_;

	uint256 private immutable firstPeriod_;
	mapping(address => uint256) private lastPeriod_;

	uint256 private criticalGas_;

	constructor(address _rewardToken, address _escrowToken, bool _escrowCumulative, address _escrowOwnership, address _boostToken, bool _boostCumulative, address _boostOwnership, address _treasury)
	{
		require(IOwnership(_escrowOwnership).token() == _escrowToken, "token mismatch");
		if (_escrowCumulative) {
			require(ICumulativeOwnership(_escrowOwnership).period() == CLAIM_BASIS, "period mismatch");
		}
		if (_boostToken != address(0)) {
			require(IOwnership(_boostOwnership).token() == _boostToken, "token mismatch");
			if (_boostCumulative) {
				require(ICumulativeOwnership(_boostOwnership).period() == CLAIM_BASIS, "period mismatch");
			}
		}
		rewardToken = _rewardToken;
		escrowToken = _escrowToken;
		boostToken = _boostToken;
		escrowOwnership = _escrowOwnership;
		boostOwnership = _boostOwnership;
		treasury = _treasury;
		lastAlloc_ = block.timestamp;
		firstPeriod_ = (block.timestamp / CLAIM_BASIS + 1) * CLAIM_BASIS;
	}

	function unallocated() public view returns (uint256 _amount)
	{
		uint256 _oldTime = lastAlloc_;
		uint256 _newTime = block.timestamp;
		uint256 _time = _newTime - _oldTime;
		if (_time < MIN_ALLOC_TIME) return 0;
		uint256 _oldBalance = rewardBalance_;
		uint256 _newBalance = IERC20(rewardToken).balanceOf(address(this));
		uint256 _balance = _newBalance - _oldBalance;
		if (_balance < MIN_ALLOC_AMOUNT) return 0;
		return _balance;
	}

	function allocate() public returns (uint256 _amount)
	{
		return _allocate(criticalGas_);
	}

	function _allocate(uint256 _criticalGas) internal returns (uint256 _amount)
	{
		uint256 _oldTime = lastAlloc_;
		uint256 _newTime = block.timestamp;
		uint256 _time = _newTime - _oldTime;
		if (_time < MIN_ALLOC_TIME) return 0;
		uint256 _oldBalance = rewardBalance_;
		uint256 _newBalance = IERC20(rewardToken).balanceOf(address(this));
		uint256 _balance = _newBalance - _oldBalance;
		if (_balance < MIN_ALLOC_AMOUNT) {
			lastAlloc_ = _newTime;
			return 0;
		}
		_newBalance = _oldBalance;
		uint256 _start = _oldTime;
		uint256 _period = (_start / CLAIM_BASIS) * CLAIM_BASIS;
		while (true) {
			uint256 _nextPeriod = _period + CLAIM_BASIS;
			uint256 _end = _nextPeriod < _newTime ? _nextPeriod : _newTime;
			uint256 _rewardPerPeriod = _balance * (_end - _start) / _time;
			_newBalance += _rewardPerPeriod;
			rewardPerPeriod_[_nextPeriod] += _rewardPerPeriod;
			if (_end == _newTime) break;
			if (gasleft() < _criticalGas) break; // special condition
			_start = _end;
			_period = _nextPeriod;
		}
		_balance = _newBalance - _oldBalance;
		lastAlloc_ = _newTime;
		rewardBalance_ = _newBalance;
		emit Allocate(_balance);
		return _balance;
	}

	function updateCriticalGas() external
	{
		uint256 _unallocated = unallocated();
		require(_unallocated > 0, "invalid state");
		uint256 _start = gasleft();
		_allocate(type(uint256).max);
		uint256 _end = gasleft();
		criticalGas_ = (_start - _end) * 110e16 / 100e16; // 10% room
	}

	function available(address _account, bool _noPenalty) external view returns (uint256 _amount, uint256 _penalty)
	{
		uint256 _lastAlloc = block.timestamp - lastAlloc_ < MIN_ALLOC_TIME ? lastAlloc_ : block.timestamp;
		(_amount, _penalty,,) = _claim(_account, _noPenalty, _lastAlloc);
		return (_amount, _penalty);
	}

	function claim(bool _noPenalty) external nonReentrant returns (uint256 _amount, uint256 _penalty)
	{
		IERC20Historical(escrowToken).checkpoint();
		if (boostToken != address(0)) {
			IERC20Historical(boostToken).checkpoint();
		}
		allocate();
		uint256 _excess;
		(_amount, _penalty, _excess, lastPeriod_[msg.sender]) = _claimPersist(msg.sender, _noPenalty, lastAlloc_);
		uint256 _total = _amount + _penalty + _excess;
		if (_total > 0) {
			rewardBalance_ -= _total;
			if (_amount > 0) {
				IERC20(rewardToken).safeTransfer(msg.sender, _amount);
			}
			if (_penalty > 0) {
				IERC20(rewardToken).safeTransfer(penaltyRecipient, _penalty);
			}
			if (_excess > 0) {
				IERC20(rewardToken).safeTransfer(excessRecipient, _excess);
			}
			emit Claim(msg.sender, _amount, _penalty, _excess);
		}
		return (_amount, _penalty);
	}

	function _claim(address _account, bool _noPenalty, uint256 _lastAlloc) internal view returns (uint256 _amount, uint256 _penalty, uint256 _excess, uint256 _period)
	{
		uint256 _firstPeriod = lastPeriod_[_account];
		if (_firstPeriod < firstPeriod_) _firstPeriod = firstPeriod_;
		uint256 _lastPeriod = (_lastAlloc / CLAIM_BASIS + 1) * CLAIM_BASIS;
		uint256 _middlePeriod =_lastPeriod - penaltyPeriods * CLAIM_BASIS;
		if (_middlePeriod < _firstPeriod) _middlePeriod = _firstPeriod;
		if (_noPenalty) _lastPeriod = _middlePeriod;
		(uint256 _amount1, uint256 _excess1) = _calculateAccruedClaim(_account, _firstPeriod, _middlePeriod);
		(uint256 _amount2, uint256 _excess2) = _calculateAccruedClaim(_account, _middlePeriod, _lastPeriod);
		_penalty = _amount2 * penaltyRate / 100e16;
		_amount = _amount1 + (_amount2 - _penalty);
		_excess = _excess1 + _excess2;
		return (_amount, _penalty, _excess, _lastPeriod);
	}

	function _claimPersist(address _account, bool _noPenalty, uint256 _lastAlloc) internal returns (uint256 _amount, uint256 _penalty, uint256 _excess, uint256 _period)
	{
		uint256 _firstPeriod = lastPeriod_[_account];
		if (_firstPeriod < firstPeriod_) _firstPeriod = firstPeriod_;
		uint256 _lastPeriod = (_lastAlloc / CLAIM_BASIS + 1) * CLAIM_BASIS;
		uint256 _middlePeriod =_lastPeriod - penaltyPeriods * CLAIM_BASIS;
		if (_middlePeriod < _firstPeriod) _middlePeriod = _firstPeriod;
		if (_noPenalty) _lastPeriod = _middlePeriod;
		{
			uint256 _limitPeriod = _firstPeriod + MAX_CLAIM_PERIODS * CLAIM_BASIS;
			if (_middlePeriod > _limitPeriod) _middlePeriod = _limitPeriod;
			if (_lastPeriod > _limitPeriod) _lastPeriod = _limitPeriod;
		}
		(uint256 _amount1, uint256 _excess1) = _calculateAccruedClaimPersist(_account, _firstPeriod, _middlePeriod);
		(uint256 _amount2, uint256 _excess2) = _calculateAccruedClaimPersist(_account, _middlePeriod, _lastPeriod);
		_penalty = _amount2 * penaltyRate / 100e16;
		_amount = _amount1 + (_amount2 - _penalty);
		_excess = _excess1 + _excess2;
		return (_amount, _penalty, _excess, _lastPeriod);
	}

	function _calculateAccruedClaim(address _account, uint256 _firstPeriod, uint256 _lastPeriod) internal view returns (uint256 _amount, uint256 _excess)
	{
		_amount = 0;
		_excess = 0;
		if (boostToken == address(0)) {
			for (uint256 _period = _firstPeriod; _period < _lastPeriod; _period += CLAIM_BASIS) {
				uint256 _local = IOwnership(escrowOwnership).localOwnership(_account, _period);
				if (_local == 0) continue;
				uint256 _total = IOwnership(escrowOwnership).totalOwnership(_period);
				if (_total == 0) continue;
				_amount += rewardPerPeriod_[_period] * _local / _total;
			}
		} else {
			for (uint256 _period = _firstPeriod; _period < _lastPeriod; _period += CLAIM_BASIS) {
				uint256 _local = IOwnership(escrowOwnership).localOwnership(_account, _period);
				uint256 _boostLocal = IOwnership(boostOwnership).localOwnership(_account, _period);
				if (_local == 0 && _boostLocal == 0) continue;
				uint256 _total = IOwnership(escrowOwnership).totalOwnership(_period);
				if (_total == 0) continue;
				uint256 _boostTotal = IOwnership(boostOwnership).totalOwnership(_period);
				if (_boostTotal == 0) continue;
				uint256 _normalizedTotal = 10 * _total * _boostTotal;
				uint256 _isolatedLocal = 10 * _local * _boostTotal;
				uint256 _normalizedLocal = 4 * _local * _boostTotal + 6 * _total * _boostLocal;
				uint256 _limitedLocal = _normalizedLocal > _isolatedLocal ? _isolatedLocal : _normalizedLocal;
				uint256 _exceededLocal = _normalizedLocal - _limitedLocal;
				uint256 _rewardPerPeriod = rewardPerPeriod_[_period];
				_amount += _rewardPerPeriod * _limitedLocal / _normalizedTotal;
				_excess += _rewardPerPeriod * _exceededLocal / _normalizedTotal;
			}
		}
		return (_amount, _excess);
	}

	function _calculateAccruedClaimPersist(address _account, uint256 _firstPeriod, uint256 _lastPeriod) internal returns (uint256 _amount, uint256 _excess)
	{
		_amount = 0;
		_excess = 0;
		if (boostToken == address(0)) {
			for (uint256 _period = _firstPeriod; _period < _lastPeriod; _period += CLAIM_BASIS) {
				uint256 _local = IOwnership(escrowOwnership).localOwnershipPersist(_account, _period);
				if (_local == 0) continue;
				uint256 _total = IOwnership(escrowOwnership).totalOwnershipPersist(_period);
				if (_total == 0) continue;
				_amount += rewardPerPeriod_[_period] * _local / _total;
			}
		} else {
			for (uint256 _period = _firstPeriod; _period < _lastPeriod; _period += CLAIM_BASIS) {
				uint256 _local = IOwnership(escrowOwnership).localOwnershipPersist(_account, _period);
				uint256 _boostLocal = IOwnership(boostOwnership).localOwnershipPersist(_account, _period);
				if (_local == 0 && _boostLocal == 0) continue;
				uint256 _total = IOwnership(escrowOwnership).totalOwnershipPersist(_period);
				if (_total == 0) continue;
				uint256 _boostTotal = IOwnership(boostOwnership).totalOwnershipPersist(_period);
				if (_boostTotal == 0) continue;
				uint256 _normalizedTotal = 10 * _total * _boostTotal;
				uint256 _isolatedLocal = 10 * _local * _boostTotal;
				uint256 _normalizedLocal = 4 * _local * _boostTotal + 6 * _total * _boostLocal;
				uint256 _limitedLocal = _normalizedLocal > _isolatedLocal ? _isolatedLocal : _normalizedLocal;
				uint256 _exceededLocal = _normalizedLocal - _limitedLocal;
				uint256 _rewardPerPeriod = rewardPerPeriod_[_period];
				_amount += _rewardPerPeriod * _limitedLocal / _normalizedTotal;
				_excess += _rewardPerPeriod * _exceededLocal / _normalizedTotal;
			}
		}
		return (_amount, _excess);
	}

	function unrecycled() external view returns (uint256 _amount)
	{
		uint256 _lastAlloc = block.timestamp - lastAlloc_ < MIN_ALLOC_TIME ? lastAlloc_ : block.timestamp;
		(_amount,) = _recycle(_lastAlloc);
		return _amount;
	}

	function recycle() external returns (uint256 _amount)
	{
		IERC20Historical(escrowToken).checkpoint();
		if (boostToken != address(0)) {
			IERC20Historical(boostToken).checkpoint();
		}
		allocate();
		(_amount, lastPeriod_[address(0)]) = _recyclePersist(lastAlloc_);
		if (_amount > 0) {
			rewardBalance_ -= _amount;
			emit Recycle(_amount);
		}
		return _amount;
	}

	function _recycle(uint256 _lastAlloc) internal view returns (uint256 _amount, uint256 _period)
	{
		uint256 _firstPeriod = lastPeriod_[address(0)];
		if (_firstPeriod < firstPeriod_) _firstPeriod = firstPeriod_;
		uint256 _lastPeriod = (_lastAlloc / CLAIM_BASIS + 1) * CLAIM_BASIS;
		_amount = _calculateAccruedRecycle(_firstPeriod, _lastPeriod);
		return (_amount, _lastPeriod);
	}

	function _recyclePersist(uint256 _lastAlloc) internal returns (uint256 _amount, uint256 _period)
	{
		uint256 _firstPeriod = lastPeriod_[address(0)];
		if (_firstPeriod < firstPeriod_) _firstPeriod = firstPeriod_;
		uint256 _lastPeriod = (_lastAlloc / CLAIM_BASIS + 1) * CLAIM_BASIS;
		{
			uint256 _limitPeriod = _firstPeriod + MAX_CLAIM_PERIODS * CLAIM_BASIS;
			if (_lastPeriod > _limitPeriod) _lastPeriod = _limitPeriod;
		}
		_amount = _calculateAccruedRecyclePersist(_firstPeriod, _lastPeriod);
		return (_amount, _lastPeriod);
	}

	function _calculateAccruedRecycle(uint256 _firstPeriod, uint256 _lastPeriod) internal view returns (uint256 _amount)
	{
		_amount = 0;
		if (boostToken == address(0)) {
			for (uint256 _period = _firstPeriod; _period < _lastPeriod; _period += CLAIM_BASIS) {
				uint256 _total = IOwnership(escrowOwnership).totalOwnership(_period);
				if (_total > 0) continue;
				_amount += rewardPerPeriod_[_period];
			}
		} else {
			for (uint256 _period = _firstPeriod; _period < _lastPeriod; _period += CLAIM_BASIS) {
				uint256 _total = IOwnership(escrowOwnership).totalOwnership(_period);
				uint256 _boostTotal = IOwnership(boostOwnership).totalOwnership(_period);
				if (_total > 0 && _boostTotal > 0) continue;
				_amount += rewardPerPeriod_[_period];
			}
		}
		return _amount;
	}

	function _calculateAccruedRecyclePersist(uint256 _firstPeriod, uint256 _lastPeriod) internal returns (uint256 _amount)
	{
		_amount = 0;
		if (boostToken == address(0)) {
			for (uint256 _period = _firstPeriod; _period < _lastPeriod; _period += CLAIM_BASIS) {
				uint256 _total = IOwnership(escrowOwnership).totalOwnershipPersist(_period);
				if (_total > 0) continue;
				_amount += rewardPerPeriod_[_period];
			}
		} else {
			for (uint256 _period = _firstPeriod; _period < _lastPeriod; _period += CLAIM_BASIS) {
				uint256 _total = IOwnership(escrowOwnership).totalOwnershipPersist(_period);
				uint256 _boostTotal = IOwnership(boostOwnership).totalOwnershipPersist(_period);
				if (_total > 0 && _boostTotal > 0) continue;
				_amount += rewardPerPeriod_[_period];
			}
		}
		return _amount;
	}

	function recoverLostFunds(address _token) external onlyOwner nonReentrant
	{
		require(_token != rewardToken, "invalid token");
		uint256 _balance = IERC20(_token).balanceOf(address(this));
		IERC20(_token).safeTransfer(treasury, _balance);
	}

	function setTreasury(address _newTreasury) external onlyOwner
	{
		require(_newTreasury != address(0), "invalid address");
		address _oldTreasury = treasury;
		treasury = _newTreasury;
		emit ChangeTreasury(_oldTreasury, _newTreasury);
	}

	function setPenaltyParams(uint256 _newPenaltyRate, uint256 _newPenaltyPeriods, address _newPenaltyRecipient) external onlyOwner delayed
	{
		require(_newPenaltyRate <= 100e16, "invalid rate");
		require(_newPenaltyPeriods <= MAXIMUM_PENALTY_PERIODS, "invalid periods");
		require(_newPenaltyRecipient != address(0), "invalid recipient");
		(uint256 _oldPenaltyRate, uint256 _oldPenaltyPeriods, address _oldPenaltyRecipient) = (penaltyRate, penaltyPeriods, penaltyRecipient);
		(penaltyRate, penaltyPeriods, penaltyRecipient) = (_newPenaltyRate, _newPenaltyPeriods, _newPenaltyRecipient);
		emit ChangePenaltyParams(_oldPenaltyRate, _oldPenaltyPeriods, _oldPenaltyRecipient, _newPenaltyRate, _newPenaltyPeriods, _newPenaltyRecipient);
	}

	function setExcessRecipient(address _newExcessRecipient) external onlyOwner delayed
	{
		require(_newExcessRecipient != address(0), "invalid recipient");
		address _oldExcessRecipient = excessRecipient;
		excessRecipient = _newExcessRecipient;
		emit ChangeExcessRecipient(_oldExcessRecipient, _newExcessRecipient);
	}

	event Allocate(uint256 _amount);
	event Claim(address indexed _account, uint256 _amount, uint256 _penalty, uint256 _excess);
	event Recycle(uint256 _amount);
	event ChangeTreasury(address _oldTreasury, address _newTreasury);
	event ChangePenaltyParams(uint256 _oldPenaltyRate, uint256 _oldPenaltyPeriods, address _oldPenaltyRecipient, uint256 _newPenaltyRate, uint256 _newPenaltyPeriods, address _newPenaltyRecipient);
	event ChangeExcessRecipient(address _oldExcessRecipient, address _newExcessRecipient);
}


// File contracts/MultiRewardAllocator.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;





contract MultiRewardAllocator is Ownable, ReentrancyGuard
{
	using SafeERC20 for IERC20;

	struct Alloc {
		address token;
		address source;
		address target;
		uint256 amount;
		uint256 period;
		uint256 unlock;
	}

	address public treasury;

	Alloc[] public allocs;

	constructor(address _treasury, address[] memory _targets, uint256[] memory _amounts)
	{
		treasury = _treasury;
		uint256 _length = _targets.length;
		require(_amounts.length == _length, "length mismatch");
		for (uint256 _i = 0; _i < _length; _i++) {
			_addAlloc(_targets[_i], _amounts[_i]);
		}
	}

	function unavailable() external view returns (bool _flag)
	{
		uint256 _length = allocs.length;
		for (uint256 _i = 0; _i < _length; _i++) {
			Alloc storage _alloc = allocs[_i];
			if (_alloc.amount > 0 && block.timestamp >= _alloc.unlock) {
				uint256 _available = Math.min(IERC20(_alloc.token).balanceOf(_alloc.source), IERC20(_alloc.token).allowance(_alloc.source, address(this)));
				if (_available < _alloc.amount) {
					return true;
				}
			}
		}
		return false;
	}

	function unallocated() external view returns (bool _flag)
	{
		uint256 _length = allocs.length;
		for (uint256 _i = 0; _i < _length; _i++) {
			Alloc storage _alloc = allocs[_i];
			if (_alloc.amount > 0 && block.timestamp >= _alloc.unlock) {
				uint256 _available = Math.min(IERC20(_alloc.token).balanceOf(_alloc.source), IERC20(_alloc.token).allowance(_alloc.source, address(this)));
				if (_available >= _alloc.amount) {
					return true;
				}
			}
			if (RewardDistributor(_alloc.target).unallocated() > 0) {
				return true;
			}
		}
		return false;
	}

	function allocate() external nonReentrant
	{
		uint256 _length = allocs.length;
		for (uint256 _i = 0; _i < _length; _i++) {
			Alloc storage _alloc = allocs[_i];
			if (_alloc.amount > 0 && block.timestamp >= _alloc.unlock) {
				uint256 _available = Math.min(IERC20(_alloc.token).balanceOf(_alloc.source), IERC20(_alloc.token).allowance(_alloc.source, address(this)));
				if (_available >= _alloc.amount) {
					_alloc.unlock = block.timestamp + _alloc.period;
					IERC20(_alloc.token).safeTransferFrom(_alloc.source, _alloc.target, _alloc.amount);
				} else {
					emit Missing(_alloc.source, _alloc.token, _alloc.amount);
				}
			}
			uint256 _amount = RewardDistributor(_alloc.target).allocate();
			if (_amount > 0) {
				emit Allocate(_alloc.target, _alloc.token, _amount);
			}
		}
	}

	function _addAlloc(address _target, uint256 _amount) internal
	{
		allocs.push(Alloc({
			token: RewardDistributor(_target).rewardToken(),
			source: treasury,
			target: _target,
			amount: _amount,
			period: RewardDistributor(_target).CLAIM_BASIS(),
			unlock: block.timestamp
		}));
	}

	function addAlloc(address _target, uint256 _amount) external onlyOwner
	{
		_addAlloc(_target, _amount);
		emit UpdateAllocs();
	}

	function removeAlloc(uint256 _index) external onlyOwner
	{
		uint256 _length = allocs.length;
		require(_index < _length, "invalid index");
		uint256 _last = _length - 1;
		if (_index < _last) {
			allocs[_index] = allocs[_last];
		}
		allocs.pop();
		emit UpdateAllocs();
	}

	function updateAllocAmount(uint256 _index, uint256 _amount) external onlyOwner
	{
		require(_index < allocs.length, "invalid index");
		allocs[_index].amount = _amount;
		emit UpdateAllocs();
	}

	function updateAllocPeriod(uint256 _index, uint256 _period) external onlyOwner
	{
		require(_period > 0, "invalid period");
		require(_index < allocs.length, "invalid index");
		allocs[_index].period = _period;
		emit UpdateAllocs();
	}

	function recoverLostFunds(address _token) external onlyOwner nonReentrant
	{
		uint256 _balance = IERC20(_token).balanceOf(address(this));
		IERC20(_token).safeTransfer(treasury, _balance);
	}

	function setTreasury(address _newTreasury) external onlyOwner
	{
		require(_newTreasury != address(0), "invalid address");
		address _oldTreasury = treasury;
		treasury = _newTreasury;
		emit ChangeTreasury(_oldTreasury, _newTreasury);
	}

	event Missing(address indexed _source, address _token, uint256 _amount);
	event Allocate(address indexed _target, address _token, uint256 _amount);
	event ChangeTreasury(address _oldTreasury, address _newTreasury);
	event UpdateAllocs();
}