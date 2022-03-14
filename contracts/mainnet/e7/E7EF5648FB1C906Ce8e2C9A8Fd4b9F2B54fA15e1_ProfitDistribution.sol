/**
 *Submitted for verification at FtmScan.com on 2022-03-14
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: contracts/owner/Operator.sol



pragma solidity ^0.8.0;



contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() {
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

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


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

// File: contracts/ProfitDistribution.sol

pragma solidity ^0.8.9;





contract ProfitDistribution is Operator {
    using SafeERC20 for IERC20;
    
    string public name = "ProfitDistribution"; // call it ProfitDistribution
    
    IERC20 public depositToken;
    address public burnAddress;
    uint256 public totalStaked;
    uint256 public depositFee;
    uint256 public totalBurned;

    //uint256[] public lockMultiplers; for later usage
    uint256 public totalAllocation;
    
    address[] public stakers;

    struct RewardInfo {
        IERC20 token;
        uint256 rewardsPerEpoch;
        uint256 totalRewards;
        bool isActive;
        uint256 distributedAmount;
        uint256 LastDistributedAmountPerAlloc;
        uint256[] rewardPerAllocHistory;
    }

    struct UserInfo {
        uint256 balance;
        uint256 allocation;
        bool hasStaked;
        bool isStaking;

        mapping(uint256=> uint256) lastSnapShotIndex; // Maps rewardPoolId to lastSnapshotindex
        mapping(IERC20 => uint256) claimedAmount;
        mapping(uint256 => uint256) pendingRewards; // Maps rewardPoolId to amount
    }


    RewardInfo[] public rewardInfo;

    

    mapping(address => UserInfo) public userInfo;

    // in constructor pass in the address for reward token 1 and reward token 2
    // that will be used to pay interest
    constructor(IERC20 _depositToken) {
        depositToken = _depositToken;
        burnAddress = 0x000000000000000000000000000000000000dEaD;
        //deposit fee default at 1%
        depositFee = 1000;

        //totalBurned to 0 

        totalBurned = 0;
    }

    //Events 

    event UpdateDepositFee(uint256 _depositFee);
    event AddReward(IERC20 _token);
    event UpdateBurnAddress(address _burnAddress);                    
    event UpdateRewardsPerEpoch(uint256 _rewardId, uint256 _amount);

    event RewardIncrease(uint256 _rewardId, uint256 _amount);
    event RewardDecrease(uint256 _rewardId, uint256 _amount);

    event TotalStakedIncrease(uint256 _amount);
    event TotalStakedDecrease(uint256 _amount);

    event UserStakedIncrease(address _user, uint256 _amount);
    event UserStakedDecrease(address _user, uint256 _amount);

    event PendingRewardIncrease(address _user, uint256 _rewardId, uint256 _amount);
    event PendingRewardClaimed(address _user);
  

    //update pending rewards modifier
    modifier updatePendingRewards(address _sender){
        UserInfo storage user = userInfo[_sender];
        for(uint256 i = 0; i < rewardInfo.length; ++i){
            RewardInfo storage reward = rewardInfo[i];
            
            //calculate pending rewards
            user.pendingRewards[i] = earned(_sender, i);
            user.lastSnapShotIndex[i] = reward.rewardPerAllocHistory.length -1;
        }   
        
        _;
    }

    /*this function calculates the earnings of user over the last recorded 
    epoch  to the most recent epoch using average rewardPerAllocation over time*/

    function earned(address _sender, uint256 _rewardId) public view returns (uint256) {

        UserInfo storage user = userInfo[_sender];
        RewardInfo storage reward = rewardInfo[_rewardId];

        uint256 latestRPA = reward.LastDistributedAmountPerAlloc;
        uint256 storedRPA = reward.rewardPerAllocHistory[user.lastSnapShotIndex[_rewardId]];

        return user.allocation*(latestRPA - storedRPA)+ user.pendingRewards[_rewardId];
    }

    //update deposit fee

    function updateDepositFee(uint256 _depositFee) external onlyOperator {
        require(_depositFee < 3000, "deposit fee too high");
        depositFee = _depositFee;
        emit UpdateDepositFee(_depositFee);
    }

    //add more reward tokens
    function addReward(IERC20 _token) external onlyOperator {

        uint256[] memory temp;
        temp[0] = 0;
        rewardInfo.push(RewardInfo({
            token: _token,
            rewardsPerEpoch: 0,
            totalRewards: 0,
            isActive: false,
            distributedAmount:0,
            LastDistributedAmountPerAlloc:0,
            rewardPerAllocHistory: temp
        }));

        emit AddReward(_token);
    }

    // Update burn address
    function updateBurnAddress(address _burnAddress) external onlyOperator {
        burnAddress = _burnAddress;
        emit UpdateBurnAddress(_burnAddress);
    }

    // update the rewards per Epoch of each reward token
    function updateRewardsPerEpoch(uint256 _rewardId, uint256 _amount) external onlyOperator {
        RewardInfo storage reward = rewardInfo[_rewardId];
        
        // checking amount
        require(_amount < reward.totalRewards,"amount must be lower than totalRewards");

        // update rewards per epoch
        reward.rewardsPerEpoch = _amount;

        if (_amount == 0) {
            reward.isActive = false;
        } else {
            reward.isActive = true;
        }

        emit UpdateRewardsPerEpoch(_rewardId, _amount);
    }

    // supply rewards to contract
    function supplyRewards(uint256 _rewardId, uint256 _amount) external onlyOperator {
        RewardInfo storage reward = rewardInfo[_rewardId];

        require(_amount > 0, "amount must be > 0");

        // Update the rewards balance in map
        reward.totalRewards += _amount;
        emit RewardIncrease(_rewardId, _amount);

        // update status for tracking
        if (reward.totalRewards > 0 && reward.totalRewards > reward.rewardsPerEpoch) {
            reward.isActive = true;
        }

        // Transfer reward tokens to contract
        reward.token.safeTransferFrom(msg.sender, address(this), _amount);

        
    }
    

    //withdraw rewards out of contract
    function withdrawRewards(uint256 _rewardId, uint256 _amount) external onlyOperator {
        RewardInfo storage reward = rewardInfo[_rewardId];

        require(_amount <= reward.totalRewards, "amount should be less than total rewards");

        // Update the rewards balance in map
        reward.totalRewards -= _amount;
        emit RewardDecrease(_rewardId, _amount);

        // update status for tracking
        if (reward.totalRewards == 0 || reward.totalRewards < reward.rewardsPerEpoch) {
            reward.isActive = false;
        }

        // Transfer reward tokens out of contract 
        reward.token.safeTransfer(msg.sender, _amount);
    }

    function stakeTokens(uint256 _amount) external updatePendingRewards(msg.sender){
        address _sender = msg.sender;
        UserInfo storage user = userInfo[_sender];

        require(_amount > 0, "can't stake 0");

        // 1% fee calculation 
        uint256 feeAmount = _amount * depositFee / 100000;
        uint256 depositAmount = _amount - feeAmount;

        //update totalBurned
        totalBurned += totalBurned;

        // Update the staking balance in map
        user.balance += depositAmount;
        emit UserStakedIncrease(_sender, depositAmount);

        //update allocation 
        user.allocation += depositAmount;
        totalAllocation += depositAmount;

        //update TotalStaked
        totalStaked += depositAmount;
        emit TotalStakedIncrease(depositAmount);

        // Add user to stakers array if they haven't staked already
        if(!user.hasStaked) {
            stakers.push(_sender);
        }

        // Update staking status to track
        user.isStaking = true;
        user.hasStaked = true;

        // Transfer based tokens to contract for staking
        depositToken.safeTransferFrom(_sender, address(this), _amount);

        // burn based
        depositToken.safeTransfer(burnAddress, feeAmount);
    }
        
    // allow user to unstake total balance and withdraw USDC from the contract
    function unstakeTokens(uint256 _amount) external updatePendingRewards(msg.sender) {
        address _sender = msg.sender;
        UserInfo storage user = userInfo[_sender];

        require(_amount > 0, "can't unstake 0");

        //check if amount is less than balance
        require(_amount <= user.balance, "staking balance too low");

        //update user balance
        user.balance -= _amount;
        emit UserStakedDecrease(_sender, _amount);

        //update allocation 
        user.allocation -= _amount;
        totalAllocation -= _amount;

        //update totalStaked
        totalStaked -= _amount;
        emit TotalStakedDecrease(_amount);
    
        // update the staking status
        if (user.balance == 0) {
            user.isStaking = false;
        }

        // transfer staked tokens out of this contract to the msg.sender
        depositToken.safeTransfer(_sender, _amount);
    }

    function issueInterestToken(uint256 _rewardId) public onlyOperator {
        RewardInfo storage reward = rewardInfo[_rewardId];
        require(reward.isActive, "No rewards");

        //update claimable amount and claimable amount per alloc

        reward.distributedAmount += reward.rewardsPerEpoch;

        uint256 thisEpochRPA = reward.rewardsPerEpoch*(1e18)/totalAllocation;

        reward.LastDistributedAmountPerAlloc = reward.LastDistributedAmountPerAlloc + thisEpochRPA;
        reward.rewardPerAllocHistory.push(reward.LastDistributedAmountPerAlloc);
        
        if(reward.totalRewards > 0) {
                //update totalRewards 
                reward.totalRewards -= reward.rewardsPerEpoch;
                emit RewardDecrease(_rewardId, reward.rewardsPerEpoch);
        }
            

        if (reward.totalRewards == 0 || reward.totalRewards < reward.rewardsPerEpoch) {
            reward.isActive = false;
        }
    }

    //get pending rewards
    function getPendingRewards(uint256 _rewardId, address _user) external view returns(uint256) {
         UserInfo storage user = userInfo[_user];
         return user.pendingRewards[_rewardId];
    }

    
    //collect rewards

    function collectRewards() external updatePendingRewards(msg.sender) {
        
        address _sender = msg.sender;

        
        UserInfo storage user = userInfo[_sender];

        //update pendingRewards and collectRewards

        //loop through the reward IDs
        for(uint256 i = 0; i < rewardInfo.length; ++i){
            //if pending rewards is not 0 
            if (user.allocation > 0){
                
                RewardInfo storage reward = rewardInfo[i];
                uint256 rewardsClaim = user.pendingRewards[i];
                //reset pending rewards 
                user.pendingRewards[i] = 0;
                
                //send rewards
                emit PendingRewardClaimed(_sender);
                reward.token.safeTransfer(_sender, rewardsClaim);
            }
        }
    }

    //get the pool share of a staker
    function getPoolShare(address _user) public view returns(uint256) {
        return (userInfo[_user].allocation * (1e18)) / totalStaked;
    }

    function distributeRewards() external onlyOperator {
        uint256 length = rewardInfo.length;
        for (uint256 i = 0; i < length; ++ i) {
            if (rewardInfo[i].isActive) {
                issueInterestToken(i);
            }
        }
    }

}