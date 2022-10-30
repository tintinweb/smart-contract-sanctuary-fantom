/**
 *Submitted for verification at FtmScan.com on 2022-10-30
*/

/**
 *Submitted for verification at FtmScan.com on 2022-04-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;



// Part: Address

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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// Part: Context

/*
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

// Part: IERC20

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

// Part: MasterChefV2

interface MasterChefV2 {
    function userInfo(uint256 pid, address _user) external view returns (uint256, uint256);

    function deposit(uint256 pid, uint256 _amount, address to) external;

    function harvest(uint256 pid, address to) external;

    function withdraw(uint256 pid, uint256 _amount, address to) external;

    function emergencyWithdraw(uint256 pid, address to) external;
}

// Part: IStrategyManager

interface IStrategyManager {
    function operators(address addr) external returns (bool);

    function performanceFee() external returns (uint256);

    function performanceFeeBountyPct() external returns (uint256);

    function stakedTokens(uint256 pid, address user) external view returns (uint256);
}

// Part: LPToken

interface LPToken {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 value) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 value) external returns (bool);


}


// Part: ReentrancyGuard

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

// Part: Swap

interface Swap {

    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external payable returns (uint256);
    
    function removeLiquidity(
        uint256 amount,
        uint256[] calldata minAmounts,
        uint256 deadline
    ) external payable returns (uint256[] memory);


    function calculateTokenAmount(uint256[] calldata amounts, bool deposit)
        external
        returns (uint256);

    function calculateRemoveLiquidity(uint256 amount)
        external
        returns (uint256[] memory);

}

// Part: IWNATIVE

interface IWNATIVE is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

// Part: Ownable

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Part: Pausable

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// Part: SafeERC20

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

// File: VaultStrategy.sol



contract VaultStrategy is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    //*=============== State Variables. ===============*//

    //Pool variables.
    IStrategyManager public strategyManager; // address of the StrategyManager staking contract.
    MasterChefV2 public masterChef; // address of the farm staking contract
    uint256 public pid; // pid of pool in the farm staking contract

    //Token variables.
    IERC20 public stakeToken; // token staked on the underlying farm
    IERC20 public token0; // first token of the lp (or 0 if it's a single token)
    IERC20 public token1; // second token of the lp (or 0 if it's a single token)
    IERC20 public earnToken; // reward token paid by the underlying farm
    address[] public extraEarnTokens; // some underlying farms can give rewards in multiple tokens

    //Swap variables.
    Swap public swapRouter; // router used for swapping tokens.
    address public WNATIVE; // address of the network's native currency.
    mapping(address => mapping(address => address[])) public swapPath; // paths for swapping 2 given tokens.


    //Shares variables.
    uint256 public sharesTotal = 0;
    
    //Vault status variables.
    bool public initialized;
    bool public emergencyWithdrawn;

    //*=============== Events. ===============*//

    event Initialize();
    event Farm();
    event Pause();
    event Unpause();
    event EmergencyWithdraw();
    event TokenToEarn(address token);
    event WrapNative();

    //*=============== Modifiers. ===============*//

    modifier onlyOperator() { 
        require(strategyManager.operators(msg.sender), "Error: onlyOperator, NOT_ALLOWED");
        _;
    }

    //*=============== Constructor/Initializer. ===============*//

    function initialize(
        uint256 _pid,
        bool _isLpToken,
        address[6] calldata _addresses

    ) external onlyOwner {
        require(!initialized, 'Error: Already initialized');
        initialized = true;

        //State variable initialization.
        strategyManager = IStrategyManager(_addresses[0]);
        stakeToken = IERC20(_addresses[1]);
        earnToken = IERC20(_addresses[2]);
        masterChef = MasterChefV2(_addresses[3]);
        swapRouter = Swap(_addresses[4]);
        WNATIVE = _addresses[5];
        pid = _pid;
        
        emit Initialize();
    }

    //*=============== Functions. ===============*//

    //Default receive function. Handles native token pools.
    receive() external payable {}

    //Pause/Unpause functions.
    function pause() external virtual onlyOperator {
        _pause();
        emit Pause();
    } 

    function unpause() external virtual onlyOperator {
        require(!emergencyWithdrawn, 'unpause: CANNOT_UNPAUSE_AFTER_EMERGENCY_WITHDRAW');
        _unpause();
        emit Unpause();
    }

    //Wrap native tokens if present.
    function wrapNative() public virtual {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            IWNATIVE(WNATIVE).deposit{value: balance}();
            emit WrapNative();
        }
    }

    //Farm functions.
    function _farmDeposit(uint256 amount) internal {
        stakeToken.safeIncreaseAllowance(address(masterChef), amount);
        masterChef.deposit(pid, amount, address(this));
    }

    function _farmWithdraw(uint256 amount) internal {
        masterChef.withdraw(pid, amount, address(this));
    }

    function _farmEmergencyWithdraw() internal {
        masterChef.emergencyWithdraw(pid, address(this));
    }

    function _totalStaked() internal view returns (uint256 amount) {
        (amount, ) = masterChef.userInfo(pid, address(this));
    }

    function totalStakeTokens() public view virtual returns (uint256) {
        return _totalStaked() + stakeToken.balanceOf(address(this));
    }

    function _farm() internal virtual { 
        uint256 depositAmount = stakeToken.balanceOf(address(this));
        _farmDeposit(depositAmount);
    }

    function _farmHarvest() internal virtual {
        masterChef.harvest(pid, address(this));
    }

    function farm() external virtual nonReentrant whenNotPaused {
        _farm();
        emit Farm();
    }

    function emergencyWithdraw() external virtual onlyOperator {
        if (!paused()) { _pause(); }
        emergencyWithdrawn = true;
        _farmEmergencyWithdraw();
        emit EmergencyWithdraw();
    }

    //Functions to interact with farm. {deposit, withdraw, earn}

    //Deposit - funds are put in this contract before this is called.
    function deposit(
        uint256 _depositAmount
    ) external virtual onlyOwner nonReentrant whenNotPaused returns (uint256) {

        //Calculate totalStakedTokens and deposit into farm.
        uint256 totalStakedBefore = totalStakeTokens() - _depositAmount;
        _farm(); 
        uint256 totalStakedAfter = totalStakeTokens();

        //Adjusts for deposit fees on the underlying farm and token transfer taxes.
        _depositAmount = totalStakedAfter - totalStakedBefore;

        //Calculates and returns the sharesAdded variable..
        uint256 sharesAdded = _depositAmount;
        if (totalStakedBefore > 0 && sharesTotal > 0) {
            sharesAdded = (_depositAmount * sharesTotal) / totalStakedBefore;
        }
        sharesTotal = sharesTotal + sharesAdded;

        return sharesAdded;
    }

    function withdraw(
        uint256 _withdrawAmount,
        address _withdrawTo
    ) external virtual onlyOwner nonReentrant returns (uint256) {
        
        uint256 totalStakedOnFarm = _totalStaked();
        uint256 totalStake = totalStakeTokens();

        //Number of shares that the withdraw amount represents (rounded up).
        uint256 sharesRemoved = (_withdrawAmount * sharesTotal - 1) / totalStake + 1;
        if (sharesRemoved > sharesTotal) { sharesRemoved = sharesTotal; }
        sharesTotal = sharesTotal - sharesRemoved;
        
        //Withdraw
        if (totalStakedOnFarm > 0) { _farmWithdraw(_withdrawAmount); }

        //Catch transfer fees & insufficient balance.
        uint256 stakeBalance = stakeToken.balanceOf(address(this));
        if (_withdrawAmount > stakeBalance) { _withdrawAmount = stakeBalance; }
        if (_withdrawAmount > totalStake) { _withdrawAmount = totalStake; }

        //Safe transfer tokens.
        stakeToken.safeTransfer(_withdrawTo, _withdrawAmount);

        return sharesRemoved;
    }

    function earn(
        address _bountyHunter
    ) external virtual onlyOwner returns (uint256 bountyReward) {
        if (paused()) { return 0; }

        //Log tokens before harvest.
        uint256 earnAmountBefore = earnToken.balanceOf(address(this));

        //Harvest and convert all tokens to those earnt.
        _farmHarvest();
        for (uint256 i; i < extraEarnTokens.length; i++) {
            tokenToEarn(extraEarnTokens[i]);
        }

        //Calculate full amount harvested.
        uint256 harvestAmount = earnToken.balanceOf(address(this)) - earnAmountBefore;

        //If there has been any harvested then calculate the fees to distribute.
        if (harvestAmount > 0) {
            bountyReward = _distributeFees(harvestAmount, _bountyHunter);
        }

        //Reasses the amount earnt.
        uint256 earnAmount = earnToken.balanceOf(address(this));


        //Add liquidiy it the chosen amount is >0. - This is where we can have leftover bits.
        uint256 token0Amt = token0.balanceOf(address(this));
        uint256 token1Amt = token1.balanceOf(address(this));
        uint256[] memory tokenBals = new uint[](2);
        tokenBals[0] = token0Amt;
        tokenBals[1] = token1Amt;

        if (token0Amt > 0 && token1Amt > 0) {
            token0.safeIncreaseAllowance(address(swapRouter), token0Amt);
            token1.safeIncreaseAllowance(address(swapRouter), token1Amt);
            swapRouter.addLiquidity(
                tokenBals,
                0,
                block.timestamp+1000
            );
        }

        //Deposit tokens and return the bountyReward.
        _farm();
        return bountyReward;
    }


    function setSwapRouter(
        address _router
    ) external virtual onlyOwner {
        swapRouter = Swap(_router);
    }

    function setExtraEarnTokens(
        address[] calldata _extraEarnTokens
    ) external virtual onlyOwner {
        require(_extraEarnTokens.length <= 5, "Error: Extra tokens set cap excluded");
        extraEarnTokens = _extraEarnTokens;
    }


    
    //Swap token to earn - used for extraEarnTokens & can be called externally to convert dust to earnedToken.
    function tokenToEarn(
        address _token
    ) public virtual nonReentrant whenNotPaused {
        uint256 amount = IERC20(_token).balanceOf(address(this));

    }

    function _distributeFees(
        uint256 _amount, 
        address _bountyHunter
    ) internal virtual returns (uint256 bountyReward) { 
        uint256 performanceFee = (_amount * strategyManager.performanceFee()) / 10_000; //[0%, 5%]
        uint256 bountyRewardPct = _bountyHunter == address(0) ? 0 : strategyManager.performanceFeeBountyPct(); //[0%, 100%]]
        bountyReward = (performanceFee * bountyRewardPct) / 10_000;
        uint256 platformFee = performanceFee - bountyReward;

        //Transfer the bounty reward to the bountyHunter.
        if (bountyReward > 0) {
            earnToken.safeTransfer(_bountyHunter, bountyReward);
        }


        return bountyReward;
    }



}