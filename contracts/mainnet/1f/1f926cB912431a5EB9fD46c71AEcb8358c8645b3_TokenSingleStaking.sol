// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./owner/Operator.sol";
import "./interfaces/IERC20Mintable.sol";

/*
  ______                __
 /_  __/___  ____ ___  / /_
  / / / __ \/ __ `__ \/ __ \
 / / / /_/ / / / / / / /_/ /
/_/  \____/_/ /_/ /_/_.___/

    http://tomb.com
*/
// TODO: Check if operating on rewardTokensLeft cannot cause issues because of possible amounts rounding
contract TokenSingleStaking is Operator {
    using SafeERC20 for IERC20;

    /// Token to be staked
    IERC20 public depositToken;
    /// Share token (XToken)
    IERC20Mintable public shareToken;

    /// Reward tokens waiting to be emitted
    uint256 public rewardTokensLeft;
    /// Amount of tokens emitted per second
    uint256 public rewardTokensPerSecond;
    /// When was the last time the rewards were updated
    uint256 public lastUpdateTime;
    /// When do the reward emissions start
    uint256 public startTime;
    /// Fee collector address
    address public feeCollector;
    /// Deposit fee in %, where 100 == 1%.
    uint256 public depositFee;

    /* EVENTS */

    event StakedTokens(address indexed user, uint256 amountStaked, uint256 sharesMinted);
    event UnstakedTokens(address indexed user, uint256 amountUnstaked, uint256 sharesBurned);
    event DepositedRewardTokens(address indexed depositedBy, uint256 amountDeposited);
    event UpdatedRewardTokensPerSecond(
        address indexed updatedBy,
        uint256 oldTokensPerSecond,
        uint256 newTokensPerSecond
    );
    event RecoveredTokens(address indexed triggeredBy, address indexed token, uint256 amount, address indexed to);
    event TransferredShareTokenOperator(address indexed triggerredBy, address oldOperator, address indexed newOperator);
    event UpdateFeeCollector(address indexed triggeredBy, address indexed feeCollector);
    event UpdateDepositFee(address indexed triggeredBy, uint256 depositFee);

    /// Default constructor
    /// @param _depositToken Address of token to be staked in the pool and also emitted as rewards from the pool
    /// @param _shareToken Address of share token to be send to the user after staking the deposit token
    /// @param _startTime Unix timestamp specifying when do the reward emissions start
    constructor(
        address _depositToken,
        address _shareToken,
        uint256 _startTime,
        address _feeCollector,
        uint256 _depositFee
    ) {
        require(_depositToken != address(0), "Deposit token cannot be 0 address");
        require(_shareToken != address(0), "Receipt token cannot be 0 address");
        require(_feeCollector != address(0), "Fee collector cannot be 0 address");
        require(_depositFee <= 4000, "Deposit fee cannot be higher than 40%");
        require(_startTime > block.timestamp, "Start time too early");
        depositToken = IERC20(_depositToken);
        shareToken = IERC20Mintable(_shareToken);
        startTime = _startTime;
        lastUpdateTime = _startTime;
        feeCollector = _feeCollector;
        depositFee = _depositFee;
    }

    /// Stake deposit token to earn more of it. Get share token as a receipt
    /// @param _amount Amount of deposit token to be staked
    function stake(uint256 _amount) external {
        updateRewards();
        if(depositFee > 0){
            uint256 depositFeeAmount = (_amount * depositFee) / 10000;
            depositToken.safeTransferFrom(msg.sender, feeCollector, depositFeeAmount);
            _amount =  _amount - depositFeeAmount;
        }
        uint256 totalDepositTokens = depositToken.balanceOf(address(this)) - rewardTokensLeft;
        uint256 totalShares = shareToken.totalSupply();
        uint256 sharesToMint;
        if (totalShares == 0 || totalDepositTokens == 0) {
            sharesToMint = _amount;
        } else {
            sharesToMint = (_amount * totalShares) / totalDepositTokens;
        }
        shareToken.mint(msg.sender, sharesToMint);
        depositToken.safeTransferFrom(msg.sender, address(this), _amount);

        emit StakedTokens(msg.sender, _amount, sharesToMint);
    }

    /// Unstake deposit token, by burning share token (receipt)
    /// @param _share Amount of share token to burn to retrieve staked deposit token + rewards
    function unstake(uint256 _share) external {
        updateRewards();

        uint256 totalShares = shareToken.totalSupply();
        uint256 amountToUnstake = (_share * (depositToken.balanceOf(address(this)) - rewardTokensLeft)) / (totalShares);
        shareToken.burnFrom(msg.sender, _share);
        depositToken.safeTransfer(msg.sender, amountToUnstake);

        emit UnstakedTokens(msg.sender, amountToUnstake, _share);
    }

    /// Send deposit token to the contract, to be emitted as rewards
    /// @param _amount Amount of deposit token to send to the contract
    /// @dev Can only be performed by Operator
    function depositRewardTokens(uint256 _amount) external onlyOperator {
        updateRewards();

        rewardTokensLeft += _amount;
        depositToken.safeTransferFrom(msg.sender, address(this), _amount);

        emit DepositedRewardTokens(msg.sender, _amount);
    }

    /// Set amount of deposit token to be emitted per second as rewards
    /// @param _newRewardTokensPerSecond New amount of deposit token to be emitted per second as rewards
    /// @dev Can only be performed by Operator
    function setRewardTokensPerSecond(uint256 _newRewardTokensPerSecond) external onlyOperator {
        updateRewards();

        uint256 oldRewardTokensPerSecond = rewardTokensPerSecond;
        rewardTokensPerSecond = _newRewardTokensPerSecond;

        emit UpdatedRewardTokensPerSecond(msg.sender, oldRewardTokensPerSecond, _newRewardTokensPerSecond);
    }

    /// Recover tokens sent to this contract by mistake
    /// @param _token Address of token to be transferred
    /// @param _amount Amount of tokens to be transferred
    /// @param _to Recipient address of the transfer
    /// @dev Can only be called by the Operator. Main token cannot be withdrawn if vesting hasn't finished.
    function recoverTokens(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        require(IERC20(_token) != depositToken, "Cannot withdraw deposit token");
        require(_to != address(0), "Cannot withdraw to 0 address");
        require(_token != address(0), "Token cannot be 0 address");

        IERC20(_token).safeTransfer(_to, _amount);

        emit RecoveredTokens(msg.sender, _token, _amount, _to);
    }

    /// Transfer share token operator access rights to a different address
    /// @param _newOperator Address to transfer share token operator access rights to
    function transferShareTokenOperator(address _newOperator) external onlyOperator {
        require(_newOperator != address(0), "New Operator cannot be 0 address");

        address oldOperator = shareToken.operator();
        shareToken.transferOperator(_newOperator);

        emit TransferredShareTokenOperator(msg.sender, oldOperator, _newOperator);
    }

    /// Return total amount of deposit token available in the contract for user
    /// @param _user User's address
    /// @return Available deposit token balance for user
    function tokenBalance(address _user) external view returns (uint256) {
        uint256 shareTokenUserBalance = shareToken.balanceOf(_user);
        uint256 shareTokenTotalSupply = shareToken.totalSupply();
        uint256 availableDepositTokenBalance = depositToken.balanceOf(address(this)) - rewardTokensLeft;
        return (shareTokenUserBalance * availableDepositTokenBalance) / shareTokenTotalSupply;
    }

    /// Return amount of deposit tokens returned for unstaking specified amount of share token
    /// @param _shareTokenAmount Amount of share token for which to calculate amount of deposit token
    /// @return Amount of deposit token returned for specified amount of share token
    function depositForShares(uint256 _shareTokenAmount) external view returns (uint256) {
        uint256 shareTokenTotalSupply = shareToken.totalSupply();
        uint256 availableDepositTokenBalance = depositToken.balanceOf(address(this)) - rewardTokensLeft;
        return (_shareTokenAmount * availableDepositTokenBalance) / shareTokenTotalSupply;
    }

    /// Return amount of share tokens returned for staking specified amount of deposit token
    /// @param _depositTokenAmount Amount of deposit token for which to calculate amount of share token
    /// @return shareTokenAmount Amount of share token returned for staking specified amount of deposit token
    function sharesForDeposit(uint256 _depositTokenAmount) external view returns (uint256 shareTokenAmount) {
        uint256 availableDepositTokenBalance = depositToken.balanceOf(address(this)) - rewardTokensLeft;
        uint256 shareTokenTotalSupply = shareToken.totalSupply();

        if (shareTokenTotalSupply == 0 || availableDepositTokenBalance == 0) {
            shareTokenAmount = _depositTokenAmount;
        } else {
            shareTokenAmount = (_depositTokenAmount * shareTokenTotalSupply) / availableDepositTokenBalance;
        }
    }

    /// Emit rewards, by increasing the amount of deposit token available and increasing value of share token
    /// @dev Rewards are emitted by manipulating the rewardsToEmit value.
    /// The lower the value in comparison with amount of deposit token in the contract,
    /// the more tokens are available for users to withdraw and the higher the value of share token
    function updateRewards() public {
        if (block.timestamp >= startTime) {
            uint256 rewardsToEmit = (block.timestamp - lastUpdateTime) * rewardTokensPerSecond;
            if (rewardsToEmit <= rewardTokensLeft) {
                rewardTokensLeft -= rewardsToEmit;
            } else {
                rewardTokensLeft = 0;
            }
            lastUpdateTime = block.timestamp;
        }
    }

    /// Set a new deposit fees collector address.
    /// @param _feeCollector A new deposit fee collector address
    /// @dev Can only be called by the Operator
    function setFeeCollector(address _feeCollector) external onlyOperator {
        require(_feeCollector != address(0), "Address cannot be 0");
        feeCollector = _feeCollector;
        emit UpdateFeeCollector(msg.sender, address(_feeCollector));
    }

    /// Set a new deposit fee value.
    /// @param _depositFee Deposit fee amount. 100 = 1%
    /// @dev Can only be called by the Operator
    function setDepositFee(uint256 _depositFee) external onlyOperator {
        require(_depositFee <= 4000, "Deposit fee cannot be higher than 40%");
        depositFee = _depositFee;
        emit UpdateDepositFee(msg.sender, depositFee);
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// Additional access control mechanism on top of {Ownable}.
/// @dev Introduces a new - Operator role, in addition to already existing Owner role.
abstract contract Operator is Context, Ownable {
    /// Address of the Operator
    address private _operator;

    /* EVENTS */
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    /// Default constructor.
    constructor() {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    /// Returns the current Operator address.
    function operator() public view returns (address) {
        return _operator;
    }

    /// Access control modifier, which only allows Operator to call the annotated function.
    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    /// Access control modifier, which only allows Operator or Owner to call the annotated function.
    modifier onlyOwnerOrOperator() {
        require((owner() == msg.sender) || (_operator == msg.sender), "operator: caller is not the owner or the operator");
        _;
    }

    /// Checks if caller is an Operator.
    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    /// Checks if called is an Owner or an Operator.
    function isOwnerOrOperator() public view returns (bool) {
        return (_msgSender() == _operator) || (_msgSender() == owner());
    }

    /// Transfers Operator role to a new address.
    /// @param newOperator_ Address to which the Operator role should be transferred.
    function transferOperator(address newOperator_) public onlyOwnerOrOperator {
        _transferOperator(newOperator_);
    }

    /// Transfers Operator role to a new address.
    /// @param newOperator_ Address to which the Operator role should be transferred.
    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IERC20Mintable {
    function mint(address recipient, uint256 amount) external returns (bool);

    function burn(uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function isOperator() external returns (bool);

    function operator() external view returns (address);

    function transferOperator(address newOperator_) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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