// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../interfaces/IVault.sol";
import "../interfaces/beethovenx/IBalancerVault.sol";
import "../interfaces/beethovenx/IBalancerAsset.sol";
import "../interfaces/beethovenx/IBaseWeightedBool.sol";
import "../interfaces/beethovenx/IBeethovenxChef.sol";

contract BeetsZapper is Ownable, ReentrancyGuard, Pausable{
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;
  
  bytes32 public lpPoolId;
  address public lpPool;
  address public uniRouter;
  
  address[] public lpTokens;
  uint256[] public lpTokensWeights;
  
  bytes32 public wftmPoolId;
  address public wftmPool;
  uint256 public wftmIndex;
  address public wftm = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
  
  address public feeInput; 
  uint256 public wftmPoolFTIndex;
  uint256 public lpPoolFTIndex;
  
  address[] public wftmPoolTokens;
  
  /**
    * @dev Pod Contracts:
    * {treasury} - Address of the Pod treasury.
    * {vault} - Address of the pod vault.
    */
  address public vault;
  address public treasury;
  
  uint256 public treasuryFee = 0;
  uint256 public constant MAX_FEE = 50;
  uint256 public constant PERCENT_DIVISOR = 10000;
  
  IBalancerVault.FundManagement public funds;
  IBalancerVault.SwapKind public swapKind;
  
  event ZapIn(address user, address fromToken, uint256 amount);
  event ZapOut(address user, address toToken, uint256 shares);
  event TreasuryFeeUpdated(uint256 newFee);
  
  /** @dev Constructor:
    * {lpPoolId} - The id of the LP pool to be used for this zapper.
    * {treasury} - Address of the Pod treasury.
    * {uniRouter} - Beet vault.
    * {vault} - Address of the pod vault.
    * {feeInput} - Address of the intermediate token used to pay the wftm fee
    * {wftmPoolId}. - The id of the wftm pool to be used for this zapper fee charging.
    */
  constructor(
    bytes32 _lpPoolId,
    address _vault,
    address _treasury,
    address _unirouter,
    address _feeInput,
    bytes32 _wftmPoolId
  ){
    lpPoolId = _lpPoolId;
    vault = _vault;
    treasury = _treasury;
    uniRouter = _unirouter;
    feeInput = _feeInput;
    wftmPoolId = _wftmPoolId;
    
    (lpPool, ) = IBalancerVault(uniRouter).getPool(lpPoolId);
    lpTokensWeights = IBaseWeightedPool(lpPool).getNormalizedWeights();
    (lpTokens, , ) = IBalancerVault(uniRouter).getPoolTokens(lpPoolId);
    for (uint i = 0; i < lpTokens.length; i++){
      if (lpTokens[i] == feeInput){
        lpPoolFTIndex = i;
        break;
      }
    }
    
    (wftmPoolTokens, , ) = IBalancerVault(uniRouter).getPoolTokens(wftmPoolId);
    for (uint i = 0; i < wftmPoolTokens.length; i++){
      if (wftmPoolTokens[i] == wftm){
        wftmIndex = i;
        continue;
      }
      if (wftmPoolTokens[i] == feeInput){
        wftmPoolFTIndex = i;
        continue;
      }
    }
    
    swapKind = IBalancerVault.SwapKind.GIVEN_IN;
    funds = IBalancerVault.FundManagement(
        address(this),
        false,
        payable(address(this)),
        false
      );
    
    _giveAllowances();
  }
  
  function depositAll(address _fromToken) external {
    deposit(_fromToken, IERC20(_fromToken).balanceOf(msg.sender));
  }
  
  function deposit(address _fromToken, uint256 _amount) public nonReentrant whenNotPaused {
    require(_amount > 0, "please provide amount");
    
    bool isLpToken = false;
    for (uint i = 0; i < lpTokens.length; i++) {
      if (_fromToken == lpTokens[i]) {
        isLpToken = true;
        break;
      }
    }
    require( isLpToken, "token is not a LP token");
    
    uint256 _before = IERC20(_fromToken).balanceOf(address(this));
    IERC20(_fromToken).safeTransferFrom(msg.sender, address(this), _amount);
    uint256 _after = IERC20(_fromToken).balanceOf(address(this));
    _amount = _after.sub(_before);
    uint256 feeAmount = _amount.mul(treasuryFee).div(PERCENT_DIVISOR);
    uint256 liquidityAmount = _amount.sub(feeAmount);
    
    if (treasuryFee > 0) {
      _chargeFees(_fromToken, feeAmount);
    }
    
    _addLiquidity(_fromToken, liquidityAmount);
    
    IVault(vault).depositAll();
    uint256 shares = IERC20(vault).balanceOf(address(this));
    IERC20(vault).safeTransfer(msg.sender, shares);
    
    emit ZapIn(msg.sender, _fromToken, _amount);
  }
  
  function withdrawAll(address _toToken) external {
    withdraw(_toToken, IERC20(vault).balanceOf(msg.sender));
  }
  
  function withdraw(address _toToken, uint256 _shares) public nonReentrant {
    require(_shares > 0, "please provide amount");
    
    bool isLpToken = false;
    for (uint i = 0; i < lpTokens.length; i++) {
      if (_toToken == lpTokens[i]) {
        isLpToken = true;
        break;
      }
    }
    require( isLpToken, "token is not a LP token");
    
    IERC20(vault).safeTransferFrom(msg.sender, address(this), _shares);
    IVault(vault).withdraw(_shares);
    
    _removeLiquidity(_toToken, _shares);
    
    uint256 toTokenBal = IERC20(_toToken).balanceOf(address(this));
    uint256 feeAmount = toTokenBal.mul(treasuryFee).div(PERCENT_DIVISOR);
    uint256 returnAmount = toTokenBal.sub(feeAmount);
    
    if (treasuryFee > 0) {
      _chargeFees(_toToken, feeAmount);
    }
    
    IERC20(_toToken).safeTransfer(msg.sender, returnAmount);
    
    emit ZapOut(msg.sender, _toToken, _shares);
  }
  
  function updateWftmPoolId(bytes32 _wftmPoolId) public nonReentrant {
    require(!paused(), "cannot update wftm pool id while paused");
    require(wftmPoolId != _wftmPoolId, "cannot update wftm pool id to the same value");
    
    wftmPoolId = _wftmPoolId;
    (wftmPoolTokens, , ) = IBalancerVault(uniRouter).getPoolTokens(wftmPoolId);
    for (uint i = 0; i < wftmPoolTokens.length; i++){
      if (wftmPoolTokens[i] == wftm){
        wftmIndex = i;
        continue;
      }
      if (wftmPoolTokens[i] == feeInput){
        wftmPoolFTIndex = i;
        continue;
      }
    }
  }
  
  function updateFeeInput(address _feeInput) public nonReentrant {
    require(!paused(), "cannot update fee input while paused");
    require(feeInput != _feeInput, "cannot update fee input to the same value");
    
    feeInput = _feeInput;
    for (uint i = 0; i < wftmPoolTokens.length; i++){
      if (wftmPoolTokens[i] == feeInput){
        wftmPoolFTIndex = i;
        continue;
      }
    }
    
    for (uint i = 0; i < lpTokens.length; i++){
      if (lpTokens[i] == feeInput){
        lpPoolFTIndex = i;
        break;
      }
    }
  }
  
  function _chargeFees(address _fromToken, uint256 _feeAmount) internal {
    uint256 wftmBal = _feeAmount;
    if (_fromToken != wftm) {
      if (_fromToken == feeInput) {
        balancerSwap(lpPoolId, _fromToken, wftm, _feeAmount);
      } else {
        balancerBathSwap(_fromToken, _feeAmount);
      }
      wftmBal = IERC20(wftm).balanceOf(address(this));      
    }
    IERC20(wftm).safeTransfer(treasury, wftmBal);
  }
  
  function _addLiquidity(address _fromToken, uint256 _amount) internal {
    uint256[] memory amounts = new uint256[](lpTokens.length);
    
    uint fromTokenAmountIndex = 0;
    for (uint i = 0; i < lpTokens.length; i++) {
      uint256 amountInFromToken = _amount.mul(lpTokensWeights[i]).div(1e18);
      if (lpTokens[i] == _fromToken) {
        fromTokenAmountIndex = i;
        continue;
      }
      balancerSwap(lpPoolId, _fromToken, lpTokens[i], amountInFromToken);
      amounts[i] = IERC20(lpTokens[i]).balanceOf(address(this));
    }
    
    amounts[fromTokenAmountIndex] = IERC20(_fromToken).balanceOf(address(this));
    bytes memory userData = abi.encode(1, amounts, 1);
    IBalancerVault.JoinPoolRequest memory request = IBalancerVault.JoinPoolRequest(lpTokens, amounts, userData, false);
    IBalancerVault(uniRouter).joinPool(
      lpPoolId,
      address(this),
      address(this),
      request
    );
  }
  
  function _removeLiquidity(address _toToken, uint256 _shares) internal {
    uint256[] memory amounts = new uint256[](lpTokens.length);
    IBalancerAsset[] memory assets = new IBalancerAsset[](lpTokens.length);
    
    uint256 toTokenIndex = 0;
    for (uint i = 0; i < lpTokens.length; i++) {
      assets[i] = IBalancerAsset(lpTokens[i]);
      amounts[i] = 0;
      
      if (lpTokens[i] == _toToken) {
        toTokenIndex = i;
        amounts[i] = 1;
      }
    }
    
    bytes memory userData = abi.encode(IBaseWeightedPool.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, _shares, toTokenIndex);
    IBalancerVault.ExitPoolRequest memory request = IBalancerVault.ExitPoolRequest(
      assets,
      amounts,
      userData,
      false
    );
    IBalancerVault(uniRouter).exitPool(
      lpPoolId,
      address(this),
      payable(address(this)),
      request
    );
  }
  
  function balancerSwap(
    bytes32 _poolId,
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) internal returns (uint256) {
  IBalancerVault.SingleSwap memory singleSwap = IBalancerVault.SingleSwap(
    _poolId,
    swapKind,
    _tokenIn,
    _tokenOut,
    _amountIn,
    ""
  );
  return
    IBalancerVault(uniRouter).swap(
      singleSwap,
      funds,
      1,
      block.timestamp
    );
  }
  
  function balancerBathSwap(
    address _fromToken,
    uint256 _amount
  ) internal returns (int256[] memory) {
    uint fromTokenIndex;
    for (uint i = 0; i < lpTokens.length; i++) {
      if (lpTokens[i] == _fromToken) {
        fromTokenIndex = i;
        break;
      }
    }
    
    IBalancerVault.BatchSwapStep memory stepFromToFeeInput = IBalancerVault.BatchSwapStep(
      lpPoolId,
      fromTokenIndex,
      lpPoolFTIndex,
      _amount,
      ""
    );
    IBalancerVault.BatchSwapStep memory stepFeeInputToWftm = IBalancerVault.BatchSwapStep(
      wftmPoolId,
      wftmPoolFTIndex,
      wftmIndex,
      0,
      ""
    );
    
    IBalancerVault.BatchSwapStep[] memory steps = new IBalancerVault.BatchSwapStep[](2);
    steps[0] = stepFromToFeeInput;
    steps[1] = stepFeeInputToWftm;
    
    IBalancerAsset[] memory assets = new IBalancerAsset[](3);
    assets[0] = IBalancerAsset(_fromToken);
    assets[1] = IBalancerAsset(feeInput);
    assets[2] = IBalancerAsset(wftm);
    
    int256[] memory limit = new int256[](3);
    limit[0] = 0;
    limit[1] = 0;
    limit[2] = 0;
    
    return IBalancerVault(uniRouter).batchSwap(
      swapKind,
      steps,
      assets,
      funds,
      limit,
      block.timestamp
    );
  }
  
  /**
    * @dev updates the  fee, capped at 0.5%
    */
  function updateTotalFee(uint256 _treasuryFee) external onlyOwner {
    require(_treasuryFee <= MAX_FEE, "Fee Too High");
    treasuryFee = _treasuryFee;
    
    emit TreasuryFeeUpdated(treasuryFee);
  }
  
  /**
  * @dev Pauses the zapper.
  */
  function pause() public onlyOwner {
    _pause();
    _removeAllowances();
  }

    /**
     * @dev Unpauses the zapper.
     */
  function unpause() external onlyOwner {
    _unpause();
    _giveAllowances();
  }
  
  /**
  * @dev approve 3rd party contracts to use all the tokens
  */
  function _giveAllowances() internal {
    uint256 max = type(uint256).max;
    
    IERC20(lpPool).safeApprove(vault, 0);
    IERC20(lpPool).safeApprove(vault, max);
    
    IERC20(lpPool).safeApprove(uniRouter, 0);
    IERC20(lpPool).safeApprove(uniRouter, max);
    
    for(uint i = 0; i < lpTokens.length; i++) {
      IERC20(lpTokens[i]).safeApprove(uniRouter, 0);
      IERC20(lpTokens[i]).safeApprove(uniRouter, max);
    }
    for(uint i = 0; i < wftmPoolTokens.length; i++) {
      IERC20(wftmPoolTokens[i]).safeApprove(uniRouter, 0);
      IERC20(wftmPoolTokens[i]).safeApprove(uniRouter, max);
    }
  }
    
  /**
  * @dev remove 3rd party contracts to use all the tokens
  */
  function _removeAllowances() internal {
    IERC20(lpPool).safeApprove(vault, 0);        
    IERC20(lpPool).safeApprove(uniRouter, 0);
    
    for(uint i = 0; i < lpTokens.length; i++) {
      IERC20(lpTokens[i]).safeApprove(uniRouter, 0);
    }
    for(uint i = 0; i < wftmPoolTokens.length; i++) {
      IERC20(wftmPoolTokens[i]).safeApprove(uniRouter, 0);
    }
  }
}

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IVault {
    function depositAll() external;

    function deposit(uint256 _amount) external;

    function withdrawAll() external;

    function withdraw(uint256 _shares) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./IBalancerAsset.sol";

interface IBalancerVault {
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external;

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    function getPool(bytes32 poolId) external view returns (address, uint8);
    
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IBalancerAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);
    
    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IBalancerAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

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

    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IBalancerAsset {
    // solhint-disable-previous-line no-empty-blocks
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IBaseWeightedPool {
    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT,
        ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
    }
    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT,
        MANAGEMENT_FEE_TOKENS_OUT // for InvestmentPool
    }

    function getNormalizedWeights() external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IBeethovenxChef {
    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external;

    function withdrawAndHarvest(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external;

    function harvest(uint256 _pid, address _to) external;

    function userInfo(uint256 _pid, address _user)
        external
        view
        returns (uint256, uint256);

    function emergencyWithdraw(uint256 _pid, address _to) external;

    function pendingBeets(uint256 _pid, address _to)
        external
        view
        returns (uint256);

    function beetsPerBlock() external view returns (uint256);

    function lpTokens(uint256 _pid) external view returns (address);

    function poolLength() external view returns (uint256);
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