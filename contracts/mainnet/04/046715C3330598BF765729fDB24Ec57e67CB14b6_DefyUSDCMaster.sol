/**
 *Submitted for verification at FtmScan.com on 2022-03-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// website: www.defyswap.finance

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeERC20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeERC20: decreased allowance below zero'
        );
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

        bytes memory returndata = address(token).functionCall(data, 'SafeERC20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
        }
    }
}

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
contract Ownable is Context {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface DefySwapper {
    function userList(address) external view returns (uint256);
}

contract DefyUSDCMaster is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
		uint256 depositTime;
        //
        // We do some fancy math here. Basically, any point in time, the amount of Reward Token
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accDefyPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accDefyPerShare` (and `lastRewardTimestamp`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Reward to distribute per second.
        uint256 depositFee; // LP Deposit fee.
        uint256 withdrawalFee; // LP Withdrawal fee
        uint256 lastRewardTimestamp; // Last Timestamp that Reward distribution occurs.
        uint256 accDefyPerShare; // Accumulated Reward per share, times 1e18. See below.
        uint256 lpSupply; // Total Lp tokens Staked in farm.
        uint256 rewardEndTimestamp; // Reward ending Timestamp.
    }

    // USDC address
    IERC20 public USDC;  
    // Dev address.
    address public devaddr;
    // Deposit fee collecting Address.
    address public feeAddress;
    // DEFY DFY swapper address
    DefySwapper public swapper;
    // USDC distributed per Second.
    uint256 public rewardPerSecond;
    // Bonus muliplier for early Reward makers.
    uint256 public BONUS_MULTIPLIER = 1;
    // Only DEFY swappers allowed
    bool public onlyDefy;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The timestamp when Reward mining starts.
    uint256 public startTimestamp;
    // The timestamp when Reward mining ends.
    uint256 public endTimestamp;
    // token lock period
    uint256 public lockDuration = 30 days;
    

    event feeAddressUpdated(address);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    
    modifier onlyDev() {
        require(msg.sender == owner() || msg.sender == devaddr , "Error: Require developer or Owner");
        _;
    }

    constructor(
        address _devaddr,
        address _feeAddress,
        address _usdc,
        address _dfy,
        address _swapper,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) public {
        require(_usdc != address(0), 'DEFY: usdc address cannot be the zero address');
        require(_swapper != address(0), 'DEFY: swapper cannot be the zero address');
        require(_dfy != address(0), 'DEFY: DFY token cannot be the zero address');
        require(_devaddr != address(0), 'DEFY: dev cannot be the zero address');
        require(_feeAddress != address(0), 'DEFY: FeeAddress cannot be the zero address');
        require(_startTimestamp >= block.timestamp , 'DEFY: Invalid Start time');
        require(_endTimestamp >= block.timestamp , 'DEFY: Invalid End time');
        
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        USDC = IERC20(_usdc);
        swapper = DefySwapper(_swapper);
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        onlyDefy = true;

        // DFY staking pool
        poolInfo.push(PoolInfo({
            lpToken: IERC20(_dfy),
            allocPoint: 1000,
            depositFee: 0,        
            withdrawalFee: 0,
            lastRewardTimestamp: startTimestamp,
            rewardEndTimestamp: 32509010280,
            accDefyPerShare: 0,
            lpSupply: 0
        }));

        totalAllocPoint = 1000;

    }
	
    function setFeeAddress(address _feeAddress)public onlyDev returns (bool){
        require(_feeAddress != address(0), 'DEFY: FeeAddress cannot be the zero address');
        feeAddress = _feeAddress;
        emit feeAddressUpdated(_feeAddress);
        return true;
    }

    function updateDefy(bool _onlyDefy)external onlyDev returns(bool){
        onlyDefy = _onlyDefy;
        return(true);
    }

    function updateLock(uint256 _lockDuration)external onlyDev returns(bool){
        lockDuration = _lockDuration;
        return(true);
    }
    
	function getUserInfo(uint256 pid, address userAddr) 
		public 
		view 
		returns(uint256 deposit, uint256 rewardDebt, uint256 daysSinceDeposit)
	{
		UserInfo storage user = userInfo[pid][userAddr];
		return (user.amount, user.rewardDebt, _getDaysSinceDeposit(pid, userAddr));
	}
    
    function updateReward(uint256 _reward, uint256 _endTimestamp) public onlyOwner{
        
       require(_endTimestamp > block.timestamp , "invalid end timestamp");

        massUpdatePools();
        endTimestamp = _endTimestamp;
        rewardPerSecond = 0;
        massUpdatePools();
        rewardPerSecond = _reward.div((_endTimestamp).sub(block.timestamp));        
        
    }
    
    function setStartTimestamp(uint256 sTimestamp) public onlyOwner{
        require(sTimestamp > block.timestamp , "invalid start timestamp");
        startTimestamp = sTimestamp;
    }

    function updateMultiplier(uint256 multiplierNumber) public onlyDev {
        require(multiplierNumber != 0, " multiplierNumber should not be null");
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner or dev.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        uint256 _depositFee,
        uint256 _withdrawalFee,
        IERC20 _lpToken,
        uint256 _rewardEndTimestamp
    ) public onlyDev {
        
        require(_depositFee <= 600 , "ADD : Max Deposit fee is 6%");
        require(_withdrawalFee <= 600 , "ADD : Max Withdrawal fee is 6%");
        require(_rewardEndTimestamp > block.timestamp , "ADD : invalid rewardEndTimestamp");
        require(_rewardEndTimestamp <= endTimestamp , "ADD : rewardEndTimestamp higher than endTimestamp");

        massUpdatePools();

		uint256 lastRewardTimestamp =
            block.timestamp > startTimestamp ? block.timestamp : startTimestamp;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                depositFee: _depositFee,
                withdrawalFee: _withdrawalFee,
                lastRewardTimestamp: lastRewardTimestamp,
                accDefyPerShare: 0,
                lpSupply: 0,
                rewardEndTimestamp: _rewardEndTimestamp
                
            })
        );
    }

    // Update the given pool's Reward allocation point. Can only be called by the owner or Dev.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint256 _depositFee,
        uint256 _withdrawalFee,
        uint256 _rewardEndTimestamp
    ) public onlyDev {
        
        require(_depositFee <= 600 , "SET : Max Deposit fee is 6%");
        require(_withdrawalFee <= 600 , "SET : Max Withdrawal fee is 6%");
        require(_rewardEndTimestamp > block.timestamp , "SET : invalid rewardEndTimestamp");
        require(_rewardEndTimestamp <= endTimestamp , "SET : rewardEndTimestamp higher than endTimestamp");
        
        massUpdatePools();
		
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFee = _depositFee;
        poolInfo[_pid].withdrawalFee = _withdrawalFee;
        poolInfo[_pid].rewardEndTimestamp = _rewardEndTimestamp;
    }

    // Return reward multiplier over the given _from to _to timestamp.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending Reward on frontend.
    function pendingReward(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accDefyPerShare = pool.accDefyPerShare;
        uint256 lpSupply = pool.lpSupply;
        if (block.timestamp > pool.lastRewardTimestamp && lpSupply != 0) {
            
            uint256 blockTimestamp; 
            if(block.timestamp  < endTimestamp){
                blockTimestamp = block.timestamp < pool.rewardEndTimestamp ? block.timestamp : pool.rewardEndTimestamp;
            }
            else{
                blockTimestamp = endTimestamp;
            }
            uint256 multiplier =
                getMultiplier(pool.lastRewardTimestamp, blockTimestamp);
            uint256 reward =
                multiplier.mul(rewardPerSecond).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accDefyPerShare = accDefyPerShare.add(
                reward.mul(1e18).div(lpSupply)
            );
        }
        return (user.amount.mul(accDefyPerShare).div(1e18).sub(user.rewardDebt));
    }

    
    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        
            uint256 length = poolInfo.length;
            for (uint256 pid = 0; pid < length; pid++) {
            updatePool(pid);
            }
    }
    
    
    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        
        if (block.timestamp <= pool.lastRewardTimestamp) {
            return;
        }
        uint256 lpSupply = pool.lpSupply;
        uint256 blockTimestamp; 
            if(block.timestamp  < endTimestamp){
                blockTimestamp = block.timestamp < pool.rewardEndTimestamp ? block.timestamp : pool.rewardEndTimestamp;
            }
            else{
                blockTimestamp = endTimestamp;
            }
        if (lpSupply == 0) {
            pool.lastRewardTimestamp = block.timestamp;
            return;
        }
        
        
        uint256 multiplier = getMultiplier(pool.lastRewardTimestamp, blockTimestamp);
        uint256 reward =
            multiplier.mul(rewardPerSecond).mul(pool.allocPoint).div(
                totalAllocPoint
            );
 
            pool.accDefyPerShare = pool.accDefyPerShare.add(
                reward.mul(1e18).div(lpSupply)
            );
            pool.lastRewardTimestamp = blockTimestamp;

            
            return;
        
    }

    // Deposit LP tokens to SubDefyMaster for Reward allocation.
    function deposit(uint256 _pid, uint256 _amount) 
	public 
	{
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);
        
		uint256 xfAmt = _amount;
		if(xfAmt > pool.lpToken.balanceOf(msg.sender))
			xfAmt = pool.lpToken.balanceOf(msg.sender);

        if(onlyDefy){
            uint256 maxAllowed = swapper.userList(msg.sender);
            require (maxAllowed > 0 , "you haven't swapped any DEFY!");
            require (maxAllowed >= user.amount , "invalid user amount");
            require (maxAllowed.sub(user.amount) >= xfAmt , "max Allowed dedposit amount reached!");
        }
		
        if(user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accDefyPerShare).div(1e18).sub(user.rewardDebt);
			
			if (pending > 0)
				safeDefyTransfer(msg.sender, pending);
			}
        
        if(xfAmt > 0) {
            
            uint256 before = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), xfAmt);
            uint256 _after = pool.lpToken.balanceOf(address(this));
            xfAmt = _after.sub(before); // Real amount of LP transfer to this address
            
             if (pool.depositFee > 0) {
                uint256 depositFee = xfAmt.mul(pool.depositFee).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(xfAmt).sub(depositFee);
                pool.lpSupply = pool.lpSupply.add(xfAmt).sub(depositFee);
            } else {
                user.amount = user.amount.add(xfAmt);
                pool.lpSupply = pool.lpSupply.add(xfAmt);
            }
            
            
        }
		
		user.depositTime = block.timestamp;
        user.rewardDebt = user.amount.mul(pool.accDefyPerShare).div(1e18);
        emit Deposit(msg.sender, _pid, xfAmt);
    }

    // Withdraw LP tokens from SubDefyMaster.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
		require(user.amount > 0, "Nothing deposited.");
        require(block.timestamp.sub(user.depositTime) >= lockDuration , "unlock time not reached!" );
		
        updatePool(_pid);

		
		uint256 xfAmt = _amount;
		if(xfAmt > user.amount)
			xfAmt = user.amount;
		

        uint256 pending =
            user.amount.mul(pool.accDefyPerShare).div(1e18).sub(
                user.rewardDebt
            );
			if (pending > 0)
				safeDefyTransfer(msg.sender, pending);
			
			
        if(xfAmt > 0) {
            user.amount = user.amount.sub(xfAmt);
            pool.lpSupply = pool.lpSupply.sub(xfAmt);
            
            if (pool.withdrawalFee > 0) {
                uint256 withdrawalFee = xfAmt.mul(pool.withdrawalFee).div(10000);
                pool.lpToken.safeTransfer(feeAddress, withdrawalFee);
                pool.lpToken.safeTransfer(address(msg.sender), xfAmt.sub(withdrawalFee));
            } else {
                pool.lpToken.safeTransfer(address(msg.sender), xfAmt);
            }
        }
		
		user.depositTime = block.timestamp;
        user.rewardDebt = user.amount.mul(pool.accDefyPerShare).div(1e18);
        emit Withdraw(msg.sender, _pid, xfAmt);
    }

    function harvest(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
		require(user.amount > 0, "Nothing deposited.");

        updatePool(_pid);

        uint256 pending = user.amount.mul(pool.accDefyPerShare).div(1e18).sub(user.rewardDebt);

		if (pending > 0){
			safeDefyTransfer(msg.sender, pending);
        }
        user.rewardDebt = user.amount.mul(pool.accDefyPerShare).div(1e18);
        emit Harvest(msg.sender , _pid);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid , address _user) public onlyDev {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        pool.lpToken.safeTransfer(_user, user.amount);
        pool.lpSupply = pool.lpSupply.sub(user.amount);
        emit EmergencyWithdraw(_user, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }


    // Safe Reward transfer function, just in case if rounding error causes pool to not have enough Reward.
    function safeDefyTransfer(address _to, uint256 _amount) internal {
        uint256 rewardBal = USDC.balanceOf(address(this));
        if (_amount > rewardBal) {
            USDC.transfer(_to, rewardBal);
        } else {
            USDC.transfer(_to, _amount);
        }
    }
    
    function withdrawRemainder() public onlyDev {
        require(block.timestamp > endTimestamp.add(1 weeks) , "only withdrawable after 1 week from rewarding period end"); 
        USDC.transfer(feeAddress, USDC.balanceOf(address(this)));
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
		
	//Time Functions
    function getDaysSinceDeposit(uint256 pid, address userAddr)
        external
        view
        returns (uint256 daysSinceDeposit)
    {
        return _getDaysSinceDeposit(pid, userAddr);
    }
    function _getDaysSinceDeposit(uint256 _pid, address _userAddr)
        internal
        view
        returns (uint256)
    {
		UserInfo storage user = userInfo[_pid][_userAddr];
		
        if (block.timestamp < user.depositTime){	
             return 0;	
        }else{	
             return (block.timestamp.sub(user.depositTime)) / 1 days;	
        }
    }
	

}