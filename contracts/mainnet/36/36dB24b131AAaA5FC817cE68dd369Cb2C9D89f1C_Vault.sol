//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./mixins/Ownable.sol";
import "./interfaces/IStrategyManager.sol";
import "./interfaces/IOneRingCurveRouter.sol";

/// This contract is using the Ownable contract from openzeppelin but with a little change 
/// to enable a 2-step transfer of ownership. See ./mixins/Ownable.sol.

/// USD in the contract means plain US Dollar with 3 zeros as decimals, it is equivalent to take a
/// token amount and divide it by 10^(token.decimals()-3).

/// oneUSD Token is the token of the vault, it gets mint by depositing the allowed stables
/// and to redeem stables you need to burn oneUSD in the withdraw function.

contract Vault is ERC20, Ownable {

  using SafeERC20 for IERC20;

  enum StatusVault {
    Closed,
    Open
  }

  address public constant USDC_CONTRACT = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
  uint256 public constant USDC_DECIMALS = 6;
  uint256 public constant ONE_USD_DECIMALS = 18;
  uint256 public constant PLAIN_USD_DECIMALS = 3;

  StatusVault public status;

  // Intermediate contract used to communicate this contract (the vault) with the individual strategies
  // Must be possible to change this reference to point to other strategyManager contract without breaking 
  // the whole system
  address public strategyManager;
  address public curveRouter;

  // This variable is used to manage the allowed slippage when depositing and withdrawing
  uint256 public slippage;
  uint256 public withdrawalFee;
  
  // Bottom and Upper limit of amout of USD to deposit per transaction.
  uint256 public minDepositInUSDC;
  uint256 public maxDepositInUSDC;

  // Users cannot redeem more than this amount of oneUSD tokens per transaction.
  uint256 public maxAmountOf1USDToWithdraw;

  /// The block number the last time the deposit function was called.
  uint256 public lastBlockDepositWasCalled;

  mapping(address => bool) public isTokenEnabled;

  event ChangeStatus(StatusVault newStatus);
  event USDCAddedToExitPool(uint256 amount);
  event tokenEnabled(address indexed token, bool truthValue);
  event StrategyManagerSetted(address oldStrategyManager, address newStrategyManager);
  event Deposit(address indexed account, address indexed token, uint256 amountDeposited, uint256 amountMinted);
  event Withdraw(address indexed account, uint256 amountUSDC, uint256 oneUSDBurned);
  event AllWithdrawed(uint256 totalAmountWithdrawed);
  event ChangeSlippage(uint256 oldSlippage, uint256 newSlippage);
  event ERC20FundsWithdrawed(address indexed token, uint256 amount);
  event USDCWithdrawed(uint256 amount);
  event ChangedMaxDepositUSDC(uint256 oldMaxDepositInUSDC, uint256 newMaxDepositAmountInUSDC);
  event ChangedMinDepositUSDC(uint256 oldMinDepositAmountInUSDC, uint256 newMinDepositAmountInUSDC);
  event ChangedMaxAmount1USDToWithdraw(uint256 oldMaxAmount1USD, uint256 newMaxAmount);
  event CurveRouterChanged(address oldRouter, address newRouter);
  event ChangedFee(uint256 oldFee, uint256 newFee);

  error Vault_Is_Not_Open();
  error Vault_Is_Not_Closed();
  error Vault_Cannot_Withdraw_In_This_Block();
  error Vault_Cannot_Deposit_In_This_Block();
  error Vault_Stable_Is_Not_Supported();
  error Vault_Cannot_Deposit_Less_Than_Minimum();
  error Vault_Cannot_Withdraw_Less_Than_The_Minimum();
  error Vault_Too_Much_Slippage();
  error Vault_Cant_Withdraw_That_Amount();
  error Vault_Cannot_Deposit_That_Much();
  error Vault_Invalid_New_Max_Deposit_USDC();
  error Vault_Invalid_New_Min_Deposit_USDC();
  error Vault_Incorrect_Strategy_Manager();
  error Vault_Incorrect_Slippage();
  error Vault_Cannot_Withdraw_USDC();
  error Vault_Invalid_Fee();
 
  // No one should be able to call the withdraw function
  // in the same block that a deposit was made (If deposit was executed first) 
  // With this we should avoid attack vectors using flash loans
  modifier validBlockNumberForWithdraw() {
    if(block.number < lastBlockDepositWasCalled + 1) {
      revert Vault_Cannot_Withdraw_In_This_Block();
    }
    _;
  }

  // One deposit call per block
  modifier validBlockNumberForDeposit() {
    if(block.number < lastBlockDepositWasCalled + 1) {
      revert Vault_Cannot_Deposit_In_This_Block();
    }

    _;
  } 

  modifier vaultIsOpen() {
    if(status != StatusVault.Open) {
      revert Vault_Is_Not_Open();
    }

    _;
  }

  modifier vaultIsClosed() {
    if(status != StatusVault.Closed) {
      revert Vault_Is_Not_Closed();
    }
    _;
  }

  constructor(address _curveRouter) ERC20("test1USD","t1USD") {
    slippage = 995;
    withdrawalFee = 9995;
    curveRouter = _curveRouter;
    maxAmountOf1USDToWithdraw = 10_000 * (10**ONE_USD_DECIMALS);
    maxDepositInUSDC = 10_001 * (10**USDC_DECIMALS);
    minDepositInUSDC = 9 * (10**USDC_DECIMALS);

    address[6] memory _underlyings = [
      0xdc301622e621166BD8E82f2cA0A26c13Ad0BE355,0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E,
      0x04068DA6C83AFCFA0e13ba15A6696662335D5B75,0x049d68029688eAbF473097a2fC38ef61633A3C7A,
      0x82f0B8B456c1A451378467398982d4834b6829c1,0xfB98B335551a418cD0737375a2ea0ded62Ea213b
    ];

    for (uint256 i = 0; i < 6; i++) {
      isTokenEnabled[_underlyings[i]] = true;
      IERC20(_underlyings[i]).safeApprove(curveRouter, type(uint256).max);
      emit tokenEnabled(_underlyings[i], true);
    }
  }

  //////////////////////////////// USER INTERACTION FUNCTIONS /////////////////////////////////////////

  /**
   * @notice Deposit stables to the vault to get oneUSD.
   * @dev Contract should mint in a 1:1 ratio with the usd deposited.
   * @param token ERC20 Contract Address to deposit.
   * @param totalAmount Quantity of tokens to deposit to the vault
   */

  function deposit(address token, uint256 totalAmount) 
    external 
    vaultIsOpen 
    validBlockNumberForDeposit 
    returns(uint256) 
  {
    // Only allow to deposit whitelisted tokens
    if(!isTokenEnabled[token]) {
      revert Vault_Stable_Is_Not_Supported();
    }

    // We take the token and convert it to USDC
    uint256 totalAmountInUSDC = _swapTokenToUSDC(token, totalAmount);

    if(totalAmountInUSDC < minDepositInUSDC) {
      revert Vault_Cannot_Deposit_Less_Than_Minimum();
    }

    if(totalAmountInUSDC > maxDepositInUSDC) {
      revert Vault_Cannot_Deposit_That_Much();
    }

    // We only deposit 90%, the other 10% remains at the contract
    uint256 amountUSDCToDepositToStrategies = _returnNinetyPercentOfAmount(totalAmountInUSDC);
    uint256 amountUSDCToLetInTheContract = totalAmountInUSDC - amountUSDCToDepositToStrategies;    

    uint256 amountMinted = _deposit(msg.sender, amountUSDCToDepositToStrategies, amountUSDCToLetInTheContract);

    // Ideally we should mint 1:1 
    uint256 expected1USDTokens = (totalAmountInUSDC*(10**(ONE_USD_DECIMALS-USDC_DECIMALS)));

    // The minimum oneUSD tokens we are willing to accept
    uint256 minimum1USDTokens = (expected1USDTokens*slippage)/1000;

    if(amountMinted < minimum1USDTokens) {
      revert Vault_Too_Much_Slippage();
    }

    lastBlockDepositWasCalled = block.number;

    emit Deposit(msg.sender, token, totalAmountInUSDC, amountMinted);

    return amountMinted;
  }

  function _deposit(address beneficiary, uint256 amountUSDCToDepositToStrategies, uint256 amountUSDCToLetInTheContract) 
    internal 
    returns(uint256) 
  {

    // We send the USDC to the strategy manager
    IERC20(USDC_CONTRACT).safeTransfer(strategyManager, amountUSDCToDepositToStrategies);

    uint256 liquidityInUSD = 
          IStrategyManager(strategyManager).tokenToUnderlying(USDC_CONTRACT,amountUSDCToDepositToStrategies);

    uint256 liquidityNotDeposited = (amountUSDCToLetInTheContract)/(10**(USDC_DECIMALS-PLAIN_USD_DECIMALS));
    uint256 totalLiquidityInUSD = (liquidityInUSD + liquidityNotDeposited);

    uint256 totalUSDC = amountUSDCToDepositToStrategies + amountUSDCToLetInTheContract;

    IStrategyManager(strategyManager).investUnderlyings();

    if(totalLiquidityInUSD*(10**(USDC_DECIMALS-PLAIN_USD_DECIMALS)) > totalUSDC) {
      totalLiquidityInUSD = (totalUSDC)/(10**(USDC_DECIMALS-PLAIN_USD_DECIMALS));
    }

    // oneUSD is 1:1 ratio with the final amount of USD deposited
    uint256 amountToMint = totalLiquidityInUSD*(10**(ONE_USD_DECIMALS-PLAIN_USD_DECIMALS));

    _mint(beneficiary, amountToMint);

    return amountToMint;
  }

  /**
   * @notice Reedem your oneUSD tokens to get USDC.
   * @dev Withdrawals are always done in USDC.
   * @param amount Quantity of oneUSD to redeem.
   */

  function withdraw(uint256 amount) external validBlockNumberForWithdraw vaultIsOpen returns(uint256) {

    if(totalSupply() < amount) {
      revert Vault_Cant_Withdraw_That_Amount();
    }

    if(amount > maxAmountOf1USDToWithdraw)  {
      revert Vault_Cant_Withdraw_That_Amount();
    }

    _burn(msg.sender, amount);

    // We convert the oneUSD amount in usdc amount
    uint256 usdcToWithdraw = (amount)/(10**(ONE_USD_DECIMALS-USDC_DECIMALS));

    // How much usdc was sent to the user.
    uint256 usdcWithdrawed = _withdraw(msg.sender, usdcToWithdraw);

    uint256 minimumUSDCToWithdraw = (usdcToWithdraw * slippage)/1000;

    if(usdcWithdrawed < minimumUSDCToWithdraw) {
      revert Vault_Too_Much_Slippage();
    }
    
    emit Withdraw(msg.sender, usdcWithdrawed, amount);

    return usdcWithdrawed;
  }

  function _withdraw(address beneficiary, uint256 usdcToWithdraw) internal returns (uint256) {

    uint256 contractBalance = IERC20(USDC_CONTRACT).balanceOf(address(this));

    // The contract has enough USDC?
    if(contractBalance >= usdcToWithdraw) {
      IERC20(USDC_CONTRACT).safeTransfer(beneficiary, usdcToWithdraw);

      return usdcToWithdraw;
    }

    // This cannot underflow 
    uint256 missing = usdcToWithdraw - contractBalance;

    // How much USDC was sent to this contract when calling withdrawToVaultDistribution()
    uint256 usdcReceived = IStrategyManager(strategyManager).withdrawToVaultDistribution(missing);

    uint256 usdcToSentToUser = contractBalance + usdcReceived;

    if(usdcToSentToUser > usdcToWithdraw) {
      usdcToSentToUser = usdcToWithdraw;
    }

    // Take withdrawal fee
    uint256 usdcToSentAfterFee = (usdcToSentToUser * withdrawalFee)/10000;

    IERC20(USDC_CONTRACT).safeTransfer(beneficiary,usdcToSentAfterFee);

    return usdcToSentToUser; 
  }

  ////////////////////////////////////// Management OnlyOwner Functions //////////////////////////////////////

  function setStatus(StatusVault newStatus) external onlyOwner {
    status = newStatus;
    emit ChangeStatus(newStatus);
  }

  // We should be able to point to a new StrategyManager
  function setStrategyManager(address newStrategyManager) external onlyOwner vaultIsClosed {
    if(newStrategyManager == address(0)) {
      revert Vault_Incorrect_Strategy_Manager();
    }

    address oldStrategyManager = strategyManager;
    strategyManager = newStrategyManager;

    emit StrategyManagerSetted(oldStrategyManager,newStrategyManager);
  }

  function changeRouter(address newCurveRouter) external onlyOwner {
    address oldCurveRouter = curveRouter;

    curveRouter = newCurveRouter;

    emit CurveRouterChanged(oldCurveRouter, newCurveRouter);
  }

  function enableStableCoin(address[] calldata _underlyings, bool truthValue) external onlyOwner {
    uint256 length = _underlyings.length;

    for (uint256 i = 0; i < length; i++) {
      isTokenEnabled[_underlyings[i]] = truthValue;
      emit tokenEnabled(_underlyings[i], truthValue);
    }
  }

  function withdrawERC20(address erc20Contract, address recipient) external onlyOwner {
    require(erc20Contract != address(0));
  
    uint256 balance = IERC20(erc20Contract).balanceOf(address(this));
    IERC20(erc20Contract).safeTransfer(recipient, balance);

    emit ERC20FundsWithdrawed(erc20Contract, balance);
  }

  function changeMaxDepositUSDC(uint256 newMaxDepositAmountInUSDC) external onlyOwner {
    if(newMaxDepositAmountInUSDC <= minDepositInUSDC) {
      revert Vault_Invalid_New_Max_Deposit_USDC();
    }

    uint256 oldMaxDepositInUSDC = maxDepositInUSDC;
    maxDepositInUSDC = newMaxDepositAmountInUSDC;

    emit ChangedMaxDepositUSDC(oldMaxDepositInUSDC, newMaxDepositAmountInUSDC);
  }

  function changeMinimumDepositUSDC(uint256 newMinDepositAmountInUSDC) external onlyOwner {
    if(newMinDepositAmountInUSDC >= maxDepositInUSDC) {
      revert Vault_Invalid_New_Min_Deposit_USDC();
    }
    
    uint256 oldMinDepositAmountInUSDC = minDepositInUSDC;

    minDepositInUSDC = newMinDepositAmountInUSDC;

    emit ChangedMinDepositUSDC(oldMinDepositAmountInUSDC, newMinDepositAmountInUSDC);
  }

  function changeMinimumPercentageSlippage(uint256 newSlippage) external onlyOwner {
    if(newSlippage <= 990 || newSlippage >= 1000) {
      revert Vault_Incorrect_Slippage();
    }
    
    uint256 oldSlippage = slippage;
    slippage = newSlippage;

    emit ChangeSlippage(oldSlippage, newSlippage);
  }

  function changeMaxAmount1USDToWithdraw(uint256 newMaxAmount) external onlyOwner {  
    uint256 oldMaxAmount1USD = maxAmountOf1USDToWithdraw;
    maxAmountOf1USDToWithdraw = newMaxAmount;

    emit ChangedMaxAmount1USDToWithdraw(oldMaxAmount1USD, newMaxAmount);
  }

  function approveCurveRouter(address[] calldata _underlyings) external onlyOwner {

    uint256 length = _underlyings.length;

    for (uint256 i = 0; i < length; i++) {
      IERC20(_underlyings[i]).safeApprove(curveRouter, 0);
      IERC20(_underlyings[i]).safeApprove(curveRouter, type(uint256).max);
    }
  }

  function changeWithdrawalFee(uint256 newFee) external onlyOwner {
    if(newFee < 9800 || newFee > 10000) {
      revert Vault_Invalid_Fee();
    }

    uint256 oldFee = withdrawalFee;
    withdrawalFee = newFee;

    emit ChangedFee(oldFee, newFee);
  }

  /////////////////////////////////////////  VIEW FUNCTIONS  /////////////////////////////////////////

  // This function returns all the USD available
  // taking into account the reserves in USDC in the contract and all the through the strategies USD farming 
  function totalBalanceInUSD() public view returns (uint256) {
    uint256 reservesUSDC = IERC20(USDC_CONTRACT).balanceOf(address(this));
    uint256 reservesUSD = reservesUSDC/(10**(USDC_DECIMALS-PLAIN_USD_DECIMALS));

    uint256 balanceInUSDInvested = investedBalanceInUSD();

    uint256 balanceInUSD = balanceInUSDInvested + reservesUSD;

    return balanceInUSD;
  }

  // This function only returs the amount of USD farming
  function investedBalanceInUSD() public view returns(uint256) {
    uint256 investedBalance = IStrategyManager(strategyManager).investedBalanceInUSD();
    return investedBalance;
  }

  function tradingFeesEarnedInUSD() public view returns(uint256) {
    uint256 total1USDinUSD = totalSupply()/(10**(ONE_USD_DECIMALS-PLAIN_USD_DECIMALS));
    uint256 _totalBalanceInUSD = totalBalanceInUSD();

    if(_totalBalanceInUSD > total1USDinUSD) {
      return _totalBalanceInUSD - total1USDinUSD;
    }

    return 0;
  }

  ///////////////////////////////////////// HELPER FUNCTIONS /////////////////////////////////////////
  function isVaultClosed() external view returns(bool) {
    if(status == StatusVault.Closed) {
      return true;
    }

    else{
      return false;
    }
  }

  function _returnNinetyPercentOfAmount(uint256 totalAmount) internal pure returns(uint256) {

    uint256 numerator = totalAmount * 900;
    uint256 denominator = 1000;

    return numerator/denominator;  
  }

  function _swapTokenToUSDC(address token, uint256 amountToDeposit) internal returns(uint256) {

    IERC20(token).safeTransferFrom(msg.sender, address(this), amountToDeposit);

    if(token == USDC_CONTRACT) {
      return amountToDeposit;
    }

    uint256 usdcAmount = IOneRingCurveRouter(curveRouter).swap(token, USDC_CONTRACT, amountToDeposit);
    return usdcAmount;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

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

    address private _potentialOwner;

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
     * @dev Modified OpenZeppelin Implementation to have a two-step transfer ownership.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _potentialOwner = newOwner;
    }

    /**
     * @dev Potential Owner must accept the challenge
     */
    function finalizeTransferedOwnership() public {
      require(msg.sender == _potentialOwner, 'Only potential owner can accept');

      _transferOwnership(_potentialOwner);

      // We clean the potentialOwner
      _potentialOwner = address(0);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;



interface IStrategyManager {
  /// This function tells each individual strategy to convert the token to the respective underlying
  function tokenToUnderlying(address token, uint256 amount) external returns (uint256);

  /// This function says every individual strategy to deposit the LPs to farm
  function investUnderlyings() external;

  /// This function returns all the USD invested accross all the individual
  /// strategies
  function investedBalanceInUSD() external view returns(uint256);

  /// This function tells each individual strategy to send their rewards to the vault
  function withdrawAllRewardsAndSendThemToRecipient(address recipient) external;

   /// This function withdraw the "amount" in USDC taking into account the distribution
  function withdrawToVaultDistribution(uint256 amount) external returns(uint256);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

interface IOneRingCurveRouter {
  function swap(address from, address to, uint256 amount) external returns(uint256);
  function increaseAllowanceCurvePools(address[] calldata tokens, address[] calldata pools) external;
  function withdrawERC20(address erc20Contract) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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