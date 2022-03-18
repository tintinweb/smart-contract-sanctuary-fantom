/**
 *Submitted for verification at FtmScan.com on 2022-03-17
*/

/*
     _____ _____ _____ ____  _____    _____ _       _           
    |   __|  |  |  _  |    \|   __|  |   __| |_ ___| |_ ___ ___ 
    |__   |     |     |  |  |   __|  |__   |  _| .'| '_| -_|  _|
    |_____|__|__|__|__|____/|_____|  |_____|_| |__,|_,_|___|_|  

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// ------------------------------------- Context -------------------------------------------
abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		return msg.data;
	}
}

// ------------------------------------- Address -------------------------------------------
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

// ------------------------------------- Ownable -------------------------------------------
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

// ------------------------------------- IERC20 -------------------------------------------
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

// ------------------------------------- SafeERC20 -------------------------------------------
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
		require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
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

// ------------------------------------- ReentrancyGuard -------------------------------------------
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

// ------------------------------------- IWETH -------------------------------------------
interface IWETH {
	function deposit() external payable;
}

// ------------------------------------- IPenaltyReceiver -------------------------------------------
interface IPenaltyReceiver {
	function notifyReward(uint256 reward) external;
}

// Shade staked within this contact entitles stakers to a portion of the admin fees generated by Shade Payment contracts
contract ShadeStaker is ReentrancyGuard, Ownable {
	using SafeERC20 for IERC20;

	// -------------------------------- VARIABLES -----------------------------------
	struct Reward {
		uint256 periodFinish;
		uint256 rewardRate;
		uint256 lastUpdateTime;
		uint256 rewardPerTokenStored;
	}
	struct LockedBalance {
		uint256 amount;
		uint256 unlockTime;
	}
	struct RewardData {
		address token;
		uint256 amount;
	}

	IERC20 public immutable stakingToken;
	IWETH public immutable WETH;
	address[] public rewardTokens;

	uint256 private constant maxRewardsTokens = 10; 
	address public penaltyReceiver;

	mapping(address => Reward) public rewardData;

	// Duration that rewards are streamed over
	uint256 public constant rewardsDuration = 7 days;
	uint256 public constant lockDurationMultiplier = 13;
	// Duration of lock period
	uint256 public constant lockDuration = rewardsDuration * lockDurationMultiplier;

	// reward token -> distributor -> is approved to add rewards
	mapping(address => mapping(address => bool)) public rewardDistributors;
	// To view all rewardDistributors for reward token you can get array of all added addresses by one
	// And then check them in rewardDistributors nested mapping
	mapping(address => address[]) public rewardDistributorsMirror;

	// addresses that allowed to stake in lock
	mapping(address => bool) public lockStakers;
	// To to view all lockStakers you can get array of all added addresses by one
	// And then check them in lockStakers mapping
	address[] public lockStakersMirror;

	// user -> reward token -> amount
	mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
	mapping(address => mapping(address => uint256)) public rewards;

	uint256 public totalSupply;

	mapping(address => uint256) public balances;
	mapping(address => mapping(uint256 => LockedBalance)) public userLocks;
	mapping(address => uint256) public startIndex;
	mapping(address => uint256) public userLocksLength;

	uint256 public constant maxFeePercent = 50; // 5% 
	uint256 public feePercent; // 1 = 0.1% to maxFeePercent
	address public feeReceiver;

	// -------------------------------- CONSTRUCTOR -----------------------------------
	constructor() Ownable() {
		stakingToken = IERC20(0x3A3841f5fa9f2c283EA567d5Aeea3Af022dD2262); // SHADE
		WETH = IWETH(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83); // wFTM address

		setLockStaker(0x98aEaf40C265A36E0B7905193DD25F1367938C46, true); // LP FARM address
		addRewardToken(address(WETH), 0xc109De3Def78b54d225716947d21501815A04ac6); // Payments FTM 100 contract
		setRewardDistributor(address(WETH), 0xDD23aDF7945f453F81FF2C449ba98F18F4163d32, true); // Payments FTM 1000 contract
		setRewardDistributor(address(WETH), 0x44C8916C3F7528294C072FbfF4C0388658124aa0, true); // Payments FTM 100000 contract
		setRewardDistributor(address(WETH), 0x6456beB56e3751f0C116c3375dceCF255cC87d35, true); // Payments FTM 10000 contract
		setRewardDistributor(address(WETH), 0x51C800793D9BB1767874bF25ceA0e6a465F0DD88, true); // Payments FTM 1000000 contract

		setFeePercent(1);
		setFeeReceiver(0x408cd7CB6Bd9d16F65E5F55df8c9A2f723e2539D);
	}

	// -------------------------------- CONFIG -----------------------------------
	// Add a new reward token to be distributed to stakers
	function addRewardToken(address rewardsToken, address distributor) public onlyOwner {
		require(rewardData[rewardsToken].lastUpdateTime == 0, "Token already added");
		require(rewardTokens.length < maxRewardsTokens, "Maximun number of reward tokens reached");

		rewardTokens.push(rewardsToken);
		rewardData[rewardsToken].lastUpdateTime = block.timestamp;
		rewardData[rewardsToken].periodFinish = block.timestamp;
		setRewardDistributor(rewardsToken, distributor, true);
		emit AddRewardToken(rewardsToken, distributor);
	}

	// Modify approval for an address to call notifyRewardAmount
	function setRewardDistributor(
		address rewardsToken,
		address distributor,
		bool state
	) public onlyOwner {
		require(rewardData[rewardsToken].lastUpdateTime > 0, "Token not added");
		require(rewardDistributors[rewardsToken][distributor] != state, "Distributor already set");
		rewardDistributors[rewardsToken][distributor] = state;
		if (state) {
			rewardDistributorsMirror[rewardsToken].push(distributor);
		}
		emit SetRewardDistributor(rewardsToken, distributor, state);
	}

	// Set PenaltyReceiver address for send penalty
	function setPenaltyReceiver(address newPenaltyReceiver) public onlyOwner {
		penaltyReceiver = newPenaltyReceiver;
		emit SetPenaltyReceiver(newPenaltyReceiver);
	}

	// Add lock staker for staking claimed rewards
	function setLockStaker(address lockStaker, bool state) public onlyOwner {
		require(lockStakers[lockStaker] != state, "LockStaker already set");
		lockStakers[lockStaker] = state;
		if (state) {
			lockStakersMirror.push(lockStaker);
		}
		emit SetLockStaker(lockStaker);
	}

	// 
	function setFeePercent(uint256 newFeePercent) public onlyOwner {
    require(feePercent <= maxFeePercent, "Not allowed");
		feePercent = newFeePercent;
		emit SetFeePercent(feePercent);
	}

	// 
	function setFeeReceiver(address newFeeReceiver) public onlyOwner {
		feeReceiver = newFeeReceiver;
		emit SetFeeReceiver(feeReceiver);
	}

	// -------------------------------- VIEWS -----------------------------------
	function rewardPerToken(address rewardsToken) internal view returns (uint256) {
		if (totalSupply == 0) {
			return rewardData[rewardsToken].rewardPerTokenStored;
		}
		return rewardData[rewardsToken].rewardPerTokenStored + (((lastTimeRewardApplicable(rewardsToken) - rewardData[rewardsToken].lastUpdateTime) * rewardData[rewardsToken].rewardRate * 1e18) / totalSupply);
	}

	function earned(address user, address rewardsToken) internal view returns (uint256) {
		if (balances[user] == 0) return 0;
		return (balances[user] * (rewardPerToken(rewardsToken) - userRewardPerTokenPaid[user][rewardsToken])) / 1e18 + rewards[user][rewardsToken];
	}

	function lastTimeRewardApplicable(address rewardsToken) internal view returns (uint256) {
		return block.timestamp < rewardData[rewardsToken].periodFinish ? block.timestamp : rewardData[rewardsToken].periodFinish;
	}

	function claimRewardForDuration(address rewardsToken) internal view returns (uint256) {
		return rewardData[rewardsToken].rewardRate * rewardsDuration;
	}

	// Address and claimable amount of all reward tokens for the given account
	function claimableRewards(address account) public view returns (RewardData[] memory rewardsAvailable) {
		uint256 length = rewardTokens.length;
		rewardsAvailable = new RewardData[](length);
		for (uint256 i = 0; i < length; i++) {
			rewardsAvailable[i].token = rewardTokens[i];
			rewardsAvailable[i].amount = earned(account, rewardsAvailable[i].token);
		}
		return rewardsAvailable;
	}

	function lockedBalance(address account) public view returns (uint256 amount) {
		for (uint256 i = startIndex[account]; i < userLocksLength[account]; i++) {
			if (userLocks[account][i].unlockTime > block.timestamp) {
				amount += userLocks[account][i].amount;
			}
		}
	}

	// Contract Data method for decrease number of request to contract from dApp UI
	function contractData()
		public
		view
		returns (
			uint256 _totalStaked,
			address[] memory _rewardTokens, 
			uint256[] memory _rewardPerToken, 
			uint256[] memory _claimRewardForDuration, 
			uint256[] memory _rewardBalances, 
			uint256 _rewardsDuration, 
			uint256 _lockDuration 
		)
	{
		_totalStaked = totalSupply;
		_rewardTokens = rewardTokens;
		_rewardPerToken = new uint256[](rewardTokens.length);
		_claimRewardForDuration = new uint256[](rewardTokens.length);
		_rewardBalances = new uint256[](rewardTokens.length);

		for (uint256 i; i < rewardTokens.length; i++) {
			_rewardPerToken[i] = rewardPerToken(rewardTokens[i]);
			_claimRewardForDuration[i] = claimRewardForDuration(rewardTokens[i]);
			_rewardBalances[i] = IERC20(rewardTokens[i]).balanceOf(address(this));
		}

		_rewardsDuration = rewardsDuration;
		_lockDuration = lockDuration;
	}

	// User Data method for decrease number of request to contract from dApp UI
	function userData(address account)
		public
		view
		returns (
			uint256 _staked, 
			uint256 _locked,
			LockedBalance[] memory _userLocks, 
			RewardData[] memory _claimableRewards, 
			uint256 _allowance, // allowance of staking token
			uint256 _balance // balance of staking token
		)
	{
		_staked = balances[account];

		_userLocks = new LockedBalance[](userLocksLength[account] - startIndex[account]);
		uint256 idx;
		for (uint256 i = startIndex[account]; i < userLocksLength[account]; i++) {
			if (userLocks[account][i].unlockTime > block.timestamp) {
				_locked += userLocks[account][i].amount;
				_userLocks[idx] = userLocks[account][i];
				idx++;
			}
		}

		_claimableRewards = claimableRewards(account);
		_allowance = stakingToken.allowance(account, address(this));
		_balance = stakingToken.balanceOf(account);
	}

	// -------------------------------- MUTATIVE FUNCTIONS -----------------------------------
	function stakeFrom(address account, uint256 amount) external returns (bool) {
		require(lockStakers[msg.sender], "Sender not allowed to stake with lock");
		_stake(account, amount, true);
		return true;
	}

	function stake(uint256 amount) external {
		_stake(msg.sender, amount, false);
	}

	// Stake tokens to receive rewards
	// Locked tokens can't be withdrawn for lockDuration and are eligible to receive staking rewards
	function _stake(
		address account,
		uint256 amount,
		bool lock
	) internal nonReentrant {
		_updateReward(account);
		_updateUserLocks(account);
		_claimReward(account);

		require(amount != 0, "Can't stake 0");

		balances[account] += amount;
		if (lock) {
			uint256 unlockTime = ((block.timestamp / rewardsDuration) * rewardsDuration) + lockDuration;
			uint256 locksLength = userLocksLength[account];

			if (locksLength == 0 || userLocks[account][locksLength - 1].unlockTime < unlockTime) {
				userLocks[account][locksLength] = LockedBalance({ amount: amount, unlockTime: unlockTime });
				userLocksLength[account]++;
			} else {
				userLocks[account][locksLength - 1].amount += amount;
			}
		}

		stakingToken.safeTransferFrom(msg.sender, address(this), amount);
		totalSupply += amount;

		emit Staked(account, amount, lock);
	}

	// Withdraw defined amount of staked tokens
	// If amount higher than unlocked we get extra from locks and pay penalty
	function withdraw(uint256 amount) public nonReentrant {
		require(amount != 0, "Can't withdraw 0");

		_updateUserLocks(msg.sender);
		_updateReward(msg.sender);
		_claimReward(msg.sender);

		uint256 balance = balances[msg.sender];
		require(balance >= amount, "Not enough tokens to withdraw");
		balances[msg.sender] -= amount;

		uint256 unlocked = balance - lockedBalance(msg.sender);
		uint256 penalty;

		if (amount > unlocked) {
			uint256 remaining = amount - unlocked;
			penalty = remaining / 2;
			amount = unlocked + remaining - penalty;

			for (uint256 i = startIndex[msg.sender]; i < userLocksLength[msg.sender]; i++) {
				uint256 lockAmount = userLocks[msg.sender][i].amount;
				if (lockAmount < remaining) {
					remaining = remaining - lockAmount;
					delete userLocks[msg.sender][i];
				} else if (lockAmount == remaining) {
					delete userLocks[msg.sender][i];
					break;
				} else {
					userLocks[msg.sender][i].amount = lockAmount - remaining;
					break;
				}
			}
		}
		_sendTokensAndPenalty(amount, penalty);
		emit Withdrawn(msg.sender, amount);
	}

	// Withdraw defined amount of unlocked tokens
	function withdrawUnlocked() public nonReentrant {
		_updateUserLocks(msg.sender);
		_updateReward(msg.sender);
		_claimReward(msg.sender);

		uint256 balance = balances[msg.sender];
		require(balance != 0, "No tokens on balance");
		uint256 locked = lockedBalance(msg.sender);

		uint256 amount = balance - locked;
		require(amount != 0, "No unlocked tokens");

		balances[msg.sender] -= amount;

		_sendTokensAndPenalty(amount, 0);
		emit Withdrawn(msg.sender, amount);
	}

	// Withdraw all user locked tokens
	function withdrawLocked() public nonReentrant {
		_updateUserLocks(msg.sender);
		_updateReward(msg.sender);
		_claimReward(msg.sender);

		uint256 amount = lockedBalance(msg.sender);
		require(amount != 0, "Can't withdraw 0");

		balances[msg.sender] -= amount;

		for (uint256 i = startIndex[msg.sender]; i < userLocksLength[msg.sender]; i++) {
			delete userLocks[msg.sender][i];
		}
		startIndex[msg.sender] = 0;
		userLocksLength[msg.sender] = 0;

		uint256 penalty = amount / 2;
		amount -= penalty;

		_sendTokensAndPenalty(amount, penalty);
		emit Withdrawn(msg.sender, amount);
	}

	// Withdraw full unlocked balance and claim pending rewards
	function withdrawAll() public nonReentrant {
		_updateUserLocks(msg.sender);
		_updateReward(msg.sender);
		_claimReward(msg.sender);

		uint256 balance = balances[msg.sender];
		require(balance != 0, "Can't withdraw 0");

		uint256 locked = lockedBalance(msg.sender);
		uint256 unlocked = balance - locked;

		uint256 penalty = locked / 2;
		uint256 amount = unlocked + locked - penalty;

		balances[msg.sender] = 0;
		for (uint256 i = startIndex[msg.sender]; i < userLocksLength[msg.sender]; i++) {
			delete userLocks[msg.sender][i];
		}
		startIndex[msg.sender] = 0;
		userLocksLength[msg.sender] = 0;

		_sendTokensAndPenalty(amount, penalty);

		emit Withdrawn(msg.sender, amount);
	}

	// Claim all pending staking rewards
	function claimReward() public nonReentrant {
		_updateReward(msg.sender);
		_claimReward(msg.sender);
	}

	function updateUserLocks() public {
		_updateUserLocks(msg.sender);
	}

	function notifyRewardAmount(address rewardsToken, uint256 reward) external {
		require(rewardDistributors[rewardsToken][msg.sender], "Only distributor allowed to send rewards");
		require(reward != 0, "No reward");
		_updateReward(address(0));

		IERC20(rewardsToken).safeTransferFrom(msg.sender, address(this), reward);
		_notifyReward(rewardsToken, reward);
		emit RewardAdded(reward);
	}

	//
	function notifyRewardAmountFTM() public payable {
		require(rewardDistributors[address(WETH)][msg.sender], "Only distributor allowed to send FTM");
		require(msg.value != 0, "No reward");
		_updateReward(address(0));

		// swapt ftm to wrapped ftm
		IWETH(WETH).deposit{ value: msg.value }();
		_notifyReward(address(WETH), msg.value);
		emit FTMReceived(msg.sender, msg.value);
	}

	// Added to support recovering
	function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
		require(tokenAddress != address(stakingToken), "Can't withdraw staking token");
		require(rewardData[tokenAddress].lastUpdateTime == 0, "Can't withdraw reward token");
		IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
		emit Recovered(tokenAddress, tokenAmount);
	}

	receive() external payable {
		notifyRewardAmountFTM();
	}

	// -------------------------------- RESTRICTED -----------------------------------
	// Update all currently locked tokens where the unlock time has passed
	function _updateUserLocks(address account) internal {
		uint256 locksLength = userLocksLength[account];
		// return if user has no locks
		if (locksLength == 0) return;

		// searching for expired locks from stratIndex untill first locked found or end reached
		while (userLocks[account][startIndex[account]].unlockTime <= block.timestamp && startIndex[account] < locksLength) {
			startIndex[account]++;
		}

		// if end reached it means no lock found and we can reset startedIndex and clear all locks array
		if (startIndex[account] >= locksLength) {
			startIndex[account] = 0;
			userLocksLength[account] = 0;
		}
	}

	function _updateReward(address account) internal {
		for (uint256 i = 0; i < rewardTokens.length; i++) {
			address token = rewardTokens[i];
			rewardData[token].rewardPerTokenStored = rewardPerToken(token);
			rewardData[token].lastUpdateTime = lastTimeRewardApplicable(token);
			if (account != address(0)) {
				rewards[account][token] = earned(account, token);
				userRewardPerTokenPaid[account][token] = rewardData[token].rewardPerTokenStored;
			}
		}
	}

	// Claim all pending staking rewards
	function _claimReward(address account) internal {
		for (uint256 i; i < rewardTokens.length; i++) {
			address rewardsToken = rewardTokens[i];
			uint256 reward = rewards[account][rewardsToken];
			if (reward > 0) {
				rewards[account][rewardsToken] = 0;
				IERC20(rewardsToken).safeTransfer(account, reward);
				emit RewardPaid(account, rewardsToken, reward);
			}
		}
	}

	// Transfer tokens to user and penalty to xShade rewards distributor or wallet
	function _sendTokensAndPenalty(uint256 tokensAmount, uint256 penaltyAmount) internal {		
		totalSupply -= (tokensAmount + penaltyAmount);

		if (feePercent != 0 && feeReceiver != address(0) && tokensAmount >= 1000) {
			uint256 fee = tokensAmount / 1000 * feePercent;
			tokensAmount -= fee;
			
			stakingToken.safeTransfer(feeReceiver, fee);
			
			emit FeePaid(msg.sender, fee);
		}

		if (penaltyAmount != 0 && penaltyReceiver != address(0)) {
			stakingToken.safeTransfer(penaltyReceiver, penaltyAmount);

			if (penaltyReceiver.code.length > 0) {
				try IPenaltyReceiver(penaltyReceiver).notifyReward(penaltyAmount) {} catch {}
			}

			emit PenaltyPaid(msg.sender, penaltyAmount);

			stakingToken.safeTransfer(msg.sender, tokensAmount);
		} else {
			stakingToken.safeTransfer(msg.sender, tokensAmount + penaltyAmount);
		}		
	}

	//
	function _notifyReward(address rewardsToken, uint256 reward) internal {
		if (block.timestamp >= rewardData[rewardsToken].periodFinish) {
			rewardData[rewardsToken].rewardRate = reward / rewardsDuration;
		} else {
			uint256 remaining = rewardData[rewardsToken].periodFinish - block.timestamp;
			uint256 leftover = remaining * rewardData[rewardsToken].rewardRate;
			rewardData[rewardsToken].rewardRate = (reward + leftover) / rewardsDuration;
		}

		rewardData[rewardsToken].lastUpdateTime = block.timestamp;
		rewardData[rewardsToken].periodFinish = block.timestamp + rewardsDuration;
	}

	// -------------------------------- EVENTS -----------------------------------
	event RewardAdded(uint256 reward);
	event Staked(address indexed user, uint256 amount, bool locked);
	event Withdrawn(address indexed user, uint256 amount);
	event PenaltyPaid(address indexed user, uint256 amount);
	event RewardPaid(address indexed user, address indexed rewardsToken, uint256 reward);
	event RewardsDurationUpdated(address token, uint256 newDuration);
	event Recovered(address token, uint256 amount);
	event FTMReceived(address indexed distributor, uint256 amount);
	event AddRewardToken(address rewardsToken, address distributor);
	event SetRewardDistributor(address rewardsToken, address distributor, bool state);
	event SetPenaltyReceiver(address penaltyReceiver);
	event SetLockStaker(address lockStaker);
	event SetFeePercent(uint256 feePercent);
	event SetFeeReceiver(address feeReceiver);
	event FeePaid(address indexed user, uint256 amount);
  
}