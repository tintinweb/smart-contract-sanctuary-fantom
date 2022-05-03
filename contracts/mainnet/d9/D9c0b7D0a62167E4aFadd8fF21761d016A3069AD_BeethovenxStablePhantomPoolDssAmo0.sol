/**
 *Submitted for verification at FtmScan.com on 2022-05-03
*/

/**
 *Submitted for verification at FtmScan.com on 2022-04-27
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

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


// File contracts/interop/BalancerV2.sol


pragma solidity 0.8.9;

interface IVault
{
	enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }
	enum SwapKind { GIVEN_IN, GIVEN_OUT }

	struct SingleSwap {
		bytes32 poolId;
		SwapKind kind;
		address assetIn;
		address assetOut;
		uint256 amount;
		bytes userData;
	}

	struct BatchSwapStep {
		bytes32 poolId;
		uint256 assetInIndex;
		uint256 assetOutIndex;
		uint256 amount;
		bytes userData;
	}

	struct FundManagement {
		address sender;
		bool fromInternalBalance;
		address payable recipient;
		bool toInternalBalance;
	}

	function getPool(bytes32 _poolId) external view returns (address _pool, PoolSpecialization _specialization);
	function getPoolTokens(bytes32 _poolId) external view returns (address[] memory _tokens, uint256[] memory _balances, uint256 _lastChangeBlock);

	function queryBatchSwap(SwapKind _kind, BatchSwapStep[] memory _swaps, address[] memory _assets, FundManagement memory _funds) external returns (int256[] memory _assetDeltas);
	function swap(SingleSwap memory _singleSwap, FundManagement memory _funds, uint256 _limit, uint256 _deadline) external payable returns (uint256 _amountCalculated);
}

interface IStablePhantomPool
{
	function getVirtualSupply() external view returns (uint256 _virtualSupply);
}


// File contracts/interop/BeethovenX.sol


pragma solidity 0.8.9;

interface BeethovenxMasterChef
{
	function beets() external view returns (address _beets);
	function pendingBeets(uint256 _pid, address _account) external view returns (uint256 _pendingBeets);
	function userInfo(uint256 _pid, address _account) external view returns (uint256 _amount, uint256 _rewardDebt);

	function deposit(uint256 _pid, uint256 _amount, address _to) external;
	function emergencyWithdraw(uint256 _pid, address _to) external;
	function harvest(uint256 _pid, address _to) external;
	function withdrawAndHarvest(uint256 _pid, uint256 _amount, address _to) external;
}


// File contracts/interop/Mor.sol


pragma solidity 0.8.9;

interface DssAmo
{
	function bal(address _account) external view returns (uint256 _bal);
	function max(address _account) external view returns (uint256 _max);

	function mint(uint256 _amount) external;
	function burn(uint256 _amount) external;
}


// File contracts/INonViewableRateProvider.sol


pragma solidity 0.8.9;

interface INonViewableRateProvider
{
	function getRate() external returns (uint256 _rate);
}


// File contracts/BeethovenxStablePhantomPoolDssAmo0.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;






contract BeethovenxStablePhantomPoolDssAmo0 is Ownable, ReentrancyGuard
{
	using SafeERC20 for IERC20;

	uint256 constant DEFAULT_MIN_COLLECT_AMOUNT = 10e18; // 10 units
	uint256 constant DEFAULT_MIN_RECYCLE_AMOUNT = 10e18; // 10 units

	uint256 constant DEFAULT_TARGET_RATIO = 75e16; // 75%
	uint256 constant DEFAULT_TARGET_MARGIN = 5e16; // 5%

	uint256 constant DEFAULT_MAX_SLIPPAGE = 1e16; // 1%
	uint256 constant DEFAULT_MAX_MINTABLE = 10_000e18; // 10k units

	address public immutable vault;
	bytes32 public immutable poolId;
	address public immutable pool;
	address public immutable token0;
	address public immutable token1;

	address public immutable dssAmo;

	address public immutable masterChef;
	uint256 public immutable pid;
	address public immutable rewardToken;

	bool public emergencyMode;

	uint256 public minCollectAmount = DEFAULT_MIN_COLLECT_AMOUNT;
	uint256 public minRecycleAmount = DEFAULT_MIN_RECYCLE_AMOUNT;

	uint256 public targetRatio = DEFAULT_TARGET_RATIO;
	uint256 public targetMargin = DEFAULT_TARGET_MARGIN;

	uint256 public maxSlippage = DEFAULT_MAX_SLIPPAGE;
	uint256 public maxMintable = DEFAULT_MAX_MINTABLE;

	address public rateProvider;
	address public lpRateProvider;

	address public treasury;

	address public rewardsRecipient;
	address public excessRecipient;

	mapping(address => bool) public whitelist;

	modifier whitelisted
	{
		require(whitelist[msg.sender], "access denied");
		_;
	}

	constructor(address _vault, bytes32 _poolId, address _dssAmo, address _masterChef, uint256 _pid, address _rateProvider, address _lpRateProvider, address _treasury)
	{
		address _pool = _getPool(_vault, _poolId);
		(address _token0, address _token1, address _token2) = _getTokens(_vault, _poolId);
		require(_token2 == _pool, "token mismatch");
		address _rewardToken = _getRewardToken(_masterChef);
		vault = _vault;
		poolId = _poolId;
		pool = _pool;
		token0 = _token0;
		token1 = _token1;
		dssAmo = _dssAmo;
		masterChef = _masterChef;
		pid = _pid;
		rewardToken = _rewardToken;
		rateProvider = _rateProvider;
		lpRateProvider = _lpRateProvider;
		treasury = _treasury;
		rewardsRecipient = _treasury;
		excessRecipient = _treasury;
	}

	function estimate() external view returns (uint256 _rewardAmount)
	{
		uint256 _pending = _getPendingReward();
		uint256 _balance = _getBalance(rewardToken);
		uint256 _total = _pending + _balance;
		if (_total >= minCollectAmount) {
			return _total;
		}
		return 0;
	}

	function collect() external nonReentrant
	{
		uint256 _pending = _getPendingReward();
		uint256 _balance = _getBalance(rewardToken);
		uint256 _total = _pending + _balance;
		if (_total >= minCollectAmount) {
			if (_pending > 0) {
				_harvest(rewardsRecipient);
			}
			if (_balance > 0) {
				_pushFunds(rewardToken, rewardsRecipient, _balance);
			}
		}
		emit Collect(_total);
	}

	// to be called by web3 as view-like
	function unbalanced() external /*view*/ returns (bool _unbalanced)
	{
		(uint256 _reserve0, uint256 _reserve1) = _getReserves();
		uint256 _reserve = _reserve0 + _reserve1 * _getRate() / 1e18;
		uint256 _ratio = _reserve0 * 1e18 / _reserve;
		if (_ratio > targetRatio + targetMargin) {
			uint256 _balance = emergencyMode ? _getBalance(pool) : _getDepositedAmount();
			return _balance > 0;
		}
		else
		if (_ratio < targetRatio - targetMargin) {
			uint256 _minted0 = _getMinted();
			uint256 _maxMintable0 = Math.min(maxMintable, _getMaxMintable());
			return _maxMintable0 > _minted0;
		}
		return false;
	}

	function rebalance() external whitelisted nonReentrant
	{
		(uint256 _reserve0, uint256 _reserve1) = _getReserves();
		uint256 _reserve = _reserve0 + _reserve1 * _getRate() / 1e18;
		uint256 _ratio = _reserve0 * 1e18 / _reserve;
		if (_ratio > targetRatio + targetMargin) {
			uint256 _amount = (_ratio - targetRatio) * _getLpSupply() / 1e18;
			uint256 _balance = emergencyMode ? _getBalance(pool) : _getDepositedAmount();
			if (_amount > _balance) {
				_amount = _balance;
			}
			if (_amount > 0) {
				if (!emergencyMode) {
					_withdraw(_amount);
				}
				_safeExitPool(_amount);
			}
		}
		else
		if (_ratio < targetRatio - targetMargin) {
			uint256 _minted0 = _getMinted();
			uint256 _maxMintable0 = Math.min(maxMintable, _getMaxMintable());
			uint256 _swapAmount0 = (targetRatio - _ratio) * _reserve / 1e18;
			uint256 _amount0 = _swapAmount0 * targetRatio / (1e18 - targetRatio);
			uint256 _mintAmount0 = _amount0 + _swapAmount0;
			uint256 _freeAmount0 = _maxMintable0 > _minted0 ? _maxMintable0 - _minted0 : 0;
			if (_mintAmount0 > _freeAmount0) {
				_swapAmount0 = _swapAmount0 * _freeAmount0 / _mintAmount0;
				_amount0 = _freeAmount0 - _swapAmount0;
				_mintAmount0 = _freeAmount0;
			}
			if (_mintAmount0 > 0) {
				_mint(_mintAmount0);
				_safeJoinPool(_amount0, _safeConvert0(_swapAmount0));
			}
		}
		if (!emergencyMode) {
			uint256 _balance = _getBalance(pool);
			if (_balance > 0) {
				_deposit(_balance);
			}
		}
		{
			uint256 _balance1 = _getBalance(token1);
			if (_balance1 * _getRate() / 1e18 >= minRecycleAmount) {
				_safeConvert1(_balance1);
			}
		}
		{
			uint256 _balance0 = _getBalance(token0);
			if (_balance0 >= minRecycleAmount) {
				uint256 _minted0 = _getMinted();
				if (_balance0 > _minted0) {
					uint256 _excess0 = _balance0 - _minted0;
					_pushFunds(token0, excessRecipient, _excess0);
					_balance0 = _minted0;
				}
				_burn(_balance0);
			}
		}
		emit Rebalance();
	}

	function enterEmergencyMode() external onlyOwner
	{
		require(!emergencyMode, "unavailable");
		emergencyMode = true;
		_emergencyWithdraw();
		emit EmergencyDeclared();
	}

	function setMinCollectAmount(uint256 _minCollectAmount) external onlyOwner
	{
		require(_minCollectAmount > 0, "invalid amount");
		minCollectAmount = _minCollectAmount;
		emit SetMinCollectAmount(_minCollectAmount);
	}

	function setMinRecycleAmount(uint256 _minRecycleAmount) external onlyOwner
	{
		require(_minRecycleAmount > 0, "invalid amount");
		minRecycleAmount = _minRecycleAmount;
		emit SetMinRecycleAmount(_minRecycleAmount);
	}

	function setRebalanceParameters(uint256 _targetRatio, uint256 _targetMargin) external onlyOwner
	{
		require(_targetMargin <= _targetRatio && _targetRatio + _targetMargin <= 1e18, "invalid parameters");
		targetRatio = _targetRatio;
		targetMargin = _targetMargin;
		emit SetRebalanceParameters(_targetRatio, _targetMargin);
	}

	function setMaxSlippage(uint256 _maxSlippage) external onlyOwner
	{
		require(_maxSlippage <= 1e18, "invalid slippage");
		maxSlippage = _maxSlippage;
		emit SetMaxSlippage(_maxSlippage);
	}

	function setMaxMintable(uint256 _maxMintable) external onlyOwner
	{
		maxMintable = _maxMintable;
		emit SetMaxMintable(_maxMintable);
	}

	function setRateProvider(address _rateProvider) external onlyOwner
	{
		require(_rateProvider != address(0), "invalid address");
		rateProvider = _rateProvider;
		emit SetRateProvider(_rateProvider);
	}

	function setLpRateProvider(address _lpRateProvider) external onlyOwner
	{
		require(_lpRateProvider != address(0), "invalid address");
		lpRateProvider = _lpRateProvider;
		emit SetLpRateProvider(_lpRateProvider);
	}

	function setTreasury(address _treasury) external onlyOwner
	{
		require(_treasury != address(0), "invalid address");
		treasury = _treasury;
		emit SetTreasury(_treasury);
	}

	function setRewardsRecipient(address _rewardsRecipient) external onlyOwner
	{
		require(_rewardsRecipient != address(0), "invalid recipient");
		rewardsRecipient = _rewardsRecipient;
		emit SetRewardsRecipient(_rewardsRecipient);
	}

	function setExcessRecipient(address _excessRecipient) external onlyOwner
	{
		require(_excessRecipient != address(0), "invalid recipient");
		excessRecipient = _excessRecipient;
		emit SetExcessRecipient(_excessRecipient);
	}

	function updateWhitelist(address _account, bool _enabled) external onlyOwner
	{
		whitelist[_account] = _enabled;
		emit Whitelisted(_account, _enabled);
	}

	function recoverLostFunds(address _token) external onlyOwner nonReentrant
	{
		require(_token != pool, "invalid token");
		require(_token != token0, "invalid token");
		require(_token != token1, "invalid token");
		_pushFunds(_token, treasury, _getBalance(_token));
	}

	// protection layer

	function _getRate() internal returns (uint256 _rate)
	{
		return INonViewableRateProvider(rateProvider).getRate();
	}

	function _getLpRate() internal returns (uint256 _rate)
	{
		return INonViewableRateProvider(lpRateProvider).getRate();
	}

	function _safeConvert0(uint256 _amount0) internal returns (uint256 _amount1)
	{
		return _convert(token0, token1, _amount0, _calcMinAmount(_amount0 * 1e18 / _getRate()));
	}

	function _safeConvert1(uint256 _amount1) internal returns (uint256 _amount0)
	{
		return _convert(token1, token0, _amount1, _calcMinAmount(_amount1 * _getRate() / 1e18));
	}

	function _safeJoinPool(uint256 _amount0, uint256 _amount1) internal
	{
		_joinPool(_amount0, _amount1, _calcMinAmount((_amount0 + _amount1 * _getRate() / 1e18) * 1e18 / _getLpRate()));
	}

	function _safeExitPool(uint256 _amount) internal
	{
		(uint256 _reserve0, uint256 _reserve1) = _getReserves();
		uint256 _reserve = _reserve0 + _reserve1 * _getRate() / 1e18;
		uint256 _exit = _amount * _getLpRate() / 1e18;
		uint256 _exit0 = _exit * _reserve0 / _reserve;
		uint256 _exit1 = (_exit - _exit0) * 1e18 / _getRate();
		_exitPool(_amount, _calcMinAmount(_exit0), _calcMinAmount(_exit1));
	}

	function _calcMinAmount(uint256 _amount) internal view returns (uint256 _minAmount)
	{
		return _amount * (1e18 - maxSlippage) / 1e18;
	}

	// token library

	function _getBalance(address _token) internal view returns (uint256 _balance)
	{
		return IERC20(_token).balanceOf(address(this));
	}

	function _pushFunds(address _token, address _to, uint256 _amount) internal
	{
		IERC20(_token).safeTransfer(_to, _amount);
	}

	function _safeApprove(address _token, address _spender, uint256 _amount) internal
	{
		uint256 _allowance = IERC20(_token).allowance(address(this), _spender);
		if (_amount > _allowance) {
			if (_allowance > 0) {
				IERC20(_token).safeApprove(_spender, 0);
			}
			IERC20(_token).safeApprove(_spender, _amount);
		}
	}

	// mor library
	function _getMinted() internal view returns (uint256 _minted)
	{
		return DssAmo(dssAmo).bal(address(this));
	}

	function _getMaxMintable() internal view returns (uint256 _maxMintable)
	{
		return DssAmo(dssAmo).max(address(this));
	}

	function _mint(uint256 _amount) internal
	{
		DssAmo(dssAmo).mint(_amount);
	}

	function _burn(uint256 _amount) internal
	{
		_safeApprove(token0, dssAmo, _amount);
		DssAmo(dssAmo).burn(_amount);
	}

	// farming library

	function _getRewardToken(address _masterChef) internal view returns (address _rewardToken)
	{
		return BeethovenxMasterChef(_masterChef).beets();
	}

	function _getPendingReward() internal view returns (uint256 _pendingReward)
	{
		return BeethovenxMasterChef(masterChef).pendingBeets(pid, address(this));
	}

	function _getDepositedAmount() internal view returns (uint256 _depositedAmount)
	{
		(_depositedAmount,) = BeethovenxMasterChef(masterChef).userInfo(pid, address(this));
		return _depositedAmount;
	}

	function _deposit(uint256 _amount) internal
	{
		_safeApprove(pool, masterChef, _amount);
		BeethovenxMasterChef(masterChef).deposit(pid, _amount, address(this));
	}

	function _harvest(address _to) internal
	{
		BeethovenxMasterChef(masterChef).harvest(pid, _to);
	}

	function _withdraw(uint256 _amount) internal
	{
		BeethovenxMasterChef(masterChef).withdrawAndHarvest(pid, _amount, address(this));
	}

	function _emergencyWithdraw() internal
	{
		BeethovenxMasterChef(masterChef).emergencyWithdraw(pid, address(this));
	}

	// pool library

	function _getPool(address _vault, bytes32 _poolId) internal view returns (address _pool)
	{
		(_pool,) = IVault(_vault).getPool(_poolId);
		return _pool;
	}

	function _getTokens(address _vault, bytes32 _poolId) internal view returns (address _token0, address _token1, address _token2)
	{
		(address[] memory _tokens,,) = IVault(_vault).getPoolTokens(_poolId);
		require(_tokens.length == 3, "invalid length");
		return (_tokens[0], _tokens[1], _tokens[2]);
	}

	function _getReserves() internal view returns (uint256 _reserve0, uint256 _reserve1)
	{
		(,uint256[] memory _balances,) = IVault(vault).getPoolTokens(poolId);
		return (_balances[0], _balances[1]);
	}

	function _getLpSupply() internal view returns (uint256 _supply)
	{
		return IStablePhantomPool(pool).getVirtualSupply();
	}

	function _convert(address _tokenA, address _tokenB, uint256 _amountA, uint256 _minAmountB) internal returns (uint256 _amountB)
	{
		if (_amountA == 0) {
			_amountB = 0;
		} else {
			_safeApprove(_tokenA, vault, _amountA);
			IVault.SingleSwap memory _swap;
			_swap.poolId = poolId;
			_swap.kind = IVault.SwapKind.GIVEN_IN;
			_swap.assetIn = _tokenA;
			_swap.assetOut = _tokenB;
			_swap.amount = _amountA;
			_swap.userData = new bytes(0);
			IVault.FundManagement memory _funds;
			_funds.sender = address(this);
			_funds.fromInternalBalance = false;
			_funds.recipient = payable(address(this));
			_funds.toInternalBalance = false;
			_amountB = IVault(vault).swap(_swap, _funds, 0, block.timestamp);
		}
		require(_amountB >= _minAmountB, "high slippage");
		return _amountB;
	}

	function _joinPool(uint256 _amount0, uint256 _amount1, uint256 _minAmount) internal
	{
		_convert(token0, pool, _amount0, _minAmount / 2);
		_convert(token1, pool, _amount1, _minAmount / 2);
	}

	function _exitPool(uint256 _amount, uint256 _minAmount0, uint256 _minAmount1) internal
	{
		uint256 _half = _amount / 2;
		_convert(pool, token0, _amount - _half, _minAmount0);
		_convert(pool, token1, _half, _minAmount1);
	}

	event Collect(uint256 _total);
	event Rebalance();
	event EmergencyDeclared();
	event SetMinCollectAmount(uint256 _minCollectAmount);
	event SetMinRecycleAmount(uint256 _minRecycleAmount);
	event SetRebalanceParameters(uint256 _targetRatio, uint256 _targetMargin);
	event SetMaxSlippage(uint256 _maxSlippage);
	event SetMaxMintable(uint256 _maxMintable);
	event SetRateProvider(address _rateProvider);
	event SetLpRateProvider(address _lpRateProvider);
	event SetTreasury(address _treasury);
	event SetExcessRecipient(address _excessRecipient);
	event SetRewardsRecipient(address _rewardsRecipient);
	event Whitelisted(address indexed _account, bool indexed _enabled);
}

// File contracts/StablePhantomPoolLpRateProvider.sol


pragma solidity 0.8.9;

contract StablePhantomPoolLpRateProvider is INonViewableRateProvider
{
	address public immutable vault;
	bytes32 public immutable poolId;
	address public immutable pool;
	address public immutable rateProvider;

	constructor(address _vault, bytes32 _poolId, address _rateProvider)
	{
		address _pool = _getPool(_vault, _poolId);
		vault = _vault;
		poolId = _poolId;
		pool = _pool;
		rateProvider = _rateProvider;
	}

	function getRate() external override returns (uint256 _rate)
	{
		(uint256 _reserve0, uint256 _reserve1) = _getReserves();
		return (_reserve0 + _reserve1 * _getRate() / 1e18) * 1e18 / _getLpSupply();
	}

	// protection layer

	function _getRate() internal returns (uint256 _rate)
	{
		return INonViewableRateProvider(rateProvider).getRate();
	}

	// pool library

	function _getPool(address _vault, bytes32 _poolId) internal view returns (address _pool)
	{
		(_pool,) = IVault(_vault).getPool(_poolId);
		return _pool;
	}

	function _getReserves() internal view returns (uint256 _reserve0, uint256 _reserve1)
	{
		(,uint256[] memory _balances,) = IVault(vault).getPoolTokens(poolId);
		return (_balances[0], _balances[1]);
	}

	function _getLpSupply() internal view returns (uint256 _supply)
	{
		return IStablePhantomPool(pool).getVirtualSupply();
	}
}


// File contracts/StablePhantomPoolRateProvider.sol


pragma solidity 0.8.9;

contract StablePhantomPoolRateProvider is INonViewableRateProvider
{
	address public immutable vault;
	bytes32 public immutable poolId;
	address public immutable pool;
	address public immutable token0;
	address public immutable token1;

	constructor(address _vault, bytes32 _poolId)
	{
		address _pool = _getPool(_vault, _poolId);
		(address _token0, address _token1, address _token2) = _getTokens(_vault, _poolId);
		require(_token2 == _pool, "token mismatch");
		vault = _vault;
		poolId = _poolId;
		pool = _pool;
		token0 = _token0;
		token1 = _token1;
	}

	function getRate() external override returns (uint256 _rate)
	{
		IVault.BatchSwapStep[] memory _swaps = new IVault.BatchSwapStep[](1);
		_swaps[0].poolId = poolId;
		_swaps[0].assetInIndex = 1;
		_swaps[0].assetOutIndex = 0;
		_swaps[0].amount = 1e18;
		_swaps[0].userData = new bytes(0);
		address[] memory _assets = new address[](2);
		_assets[0] = token0;
		_assets[1] = token1;
		IVault.FundManagement memory _funds;
		_funds.sender = payable(address(this));
		_funds.fromInternalBalance = false;
		_funds.recipient = payable(address(this));
		_funds.toInternalBalance = false;
		int256[] memory _assetDeltas = IVault(vault).queryBatchSwap(IVault.SwapKind.GIVEN_IN, _swaps, _assets, _funds);
		_rate = uint256(-_assetDeltas[0]);
		return _rate;
	}

	// pool library

	function _getPool(address _vault, bytes32 _poolId) internal view returns (address _pool)
	{
		(_pool,) = IVault(_vault).getPool(_poolId);
		return _pool;
	}

	function _getTokens(address _vault, bytes32 _poolId) internal view returns (address _token0, address _token1, address _token2)
	{
		(address[] memory _tokens,,) = IVault(_vault).getPoolTokens(_poolId);
		require(_tokens.length == 3, "invalid length");
		return (_tokens[0], _tokens[1], _tokens[2]);
	}
}