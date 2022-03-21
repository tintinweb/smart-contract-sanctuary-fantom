/**
 *Submitted for verification at FtmScan.com on 2022-03-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IERC20 {
	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function transfer(address recipient, uint256 amount)
	external
	returns (bool);

	function allowance(address owner, address spender)
	external
	view
	returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);

	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
}

interface IFactory {
	function createPair(address tokenA, address tokenB)
	external
	returns (address pair);

	function getPair(address tokenA, address tokenB)
	external
	view
	returns (address pair);
}

interface IRouter {
	function factory() external pure returns (address);

	function WETH() external pure returns (address);

	function addLiquidityETH(
		address token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	)
	external
	payable
	returns (
		uint256 amountToken,
		uint256 amountETH,
		uint256 liquidity
	);

	function swapExactETHForTokensSupportingFeeOnTransferTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable;

	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;
}

library SafeMath {

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");

		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}

	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;

		return c;
	}

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

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(a, b, "SafeMath: division by zero");
	}

	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return mod(a, b, "SafeMath: modulo by zero");
	}

	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}

library Address {
	function isContract(address account) internal view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}

	function sendValue(address payable recipient, uint256 amount) internal {
		require(
			address(this).balance >= amount,
			"Address: insufficient balance"
		);

		(bool success, ) = recipient.call{value: amount}("");
		require(
			success,
			"Address: unable to send value, recipient may have reverted"
		);
	}

	function functionCall(address target, bytes memory data)
	internal
	returns (bytes memory)
	{
		return functionCall(target, data, "Address: low-level call failed");
	}

	function functionCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}

	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value
	) internal returns (bytes memory) {
		return
		functionCallWithValue(
			target,
			data,
			value,
			"Address: low-level call with value failed"
		);
	}

	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(
			address(this).balance >= value,
			"Address: insufficient balance for call"
		);
		require(isContract(target), "Address: call to non-contract");

		(bool success, bytes memory returndata) = target.call{value: value}(
		data
		);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function functionStaticCall(address target, bytes memory data)
	internal
	view
	returns (bytes memory)
	{
		return
		functionStaticCall(
			target,
			data,
			"Address: low-level static call failed"
		);
	}

	function functionStaticCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal view returns (bytes memory) {
		require(isContract(target), "Address: static call to non-contract");

		(bool success, bytes memory returndata) = target.staticcall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function functionDelegateCall(address target, bytes memory data)
	internal
	returns (bytes memory)
	{
		return
		functionDelegateCall(
			target,
			data,
			"Address: low-level delegate call failed"
		);
	}

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
			if (returndata.length > 0) {
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

abstract contract Context {
		function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}

contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor () public {
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}

	function owner() public view returns (address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(_owner == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	function renounceOwnership() public virtual onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

contract Staking {
	function userInfo(uint8 _stakeType, address _account) public view returns (uint256 amount, uint256 available, uint256 locked) {}
}

contract EquitableGrowthOpportunity is IERC20, Ownable {
	using Address for address;
	using SafeMath for uint256;

	IRouter public uniswapV2Router;
	address public immutable uniswapV2Pair;

	string private constant _name =  "Equitable Growth Opportunity";
	string private constant _symbol = "EGO";
	uint8 private constant _decimals = 18;

	mapping (address => uint256) private _rOwned;
	mapping (address => uint256) private _tOwned;
	mapping (address => mapping (address => uint256)) private _allowances;

	uint256 private constant MAX = ~uint256(0);
	uint256 private constant _tTotal = 1000000000 * 10**18;
	uint256 private _rTotal = (MAX - (MAX % _tTotal));
	uint256 private _tFeeTotal;

	bool public isTradingEnabled;
    uint256 private _tradingPausedTimestamp;

	// max wallet is 2.5% of initialSupply
	uint256 public maxWalletAmount = _tTotal * 250 / 10000;

	uint256 public maxTxBuyAmount = 10000000 * (10**18);
	uint256 public maxTxSellAmount = 5000000 * (10**18);

	bool private _swapping;
	uint256 public minimumTokensBeforeSwap = 1 * (10**18);

	address public FETH = 0x658b0c7613e890EE50B8C4BC6A3f41ef411208aD;
    address private dead = 0x000000000000000000000000000000000000dEaD;
	Staking stakingContract;

	address public liquidityWallet;
	address public devWallet;
	address public investingWallet;
	address public dreamFoundationWallet;

	struct CustomTaxPeriod {
		bytes23 periodName;
		uint8 blocksInPeriod;
		uint256 timeInPeriod;
		uint256 liquidityFeeOnBuy;
		uint256 liquidityFeeOnSell;
		uint256 devFeeOnBuy;
		uint256 devFeeOnSell;
		uint256 investingFeeOnBuy;
		uint256 investingFeeOnSell;
		uint256 dreamFoundationFeeOnBuy;
		uint256 dreamFoundationFeeOnSell;
		uint256 holdersFeeOnBuy;
		uint256 holdersFeeOnSell;
	}

	// Launch taxes
	bool private _isLaunched;
	uint256 private _launchStartTimestamp;
	uint256 private _launchBlockNumber;
	CustomTaxPeriod private _launch1 = CustomTaxPeriod('launch1',5,0,100,1,0,3,0,12,0,1,0,3);
	CustomTaxPeriod private _launch2 = CustomTaxPeriod('launch2',0,86400,1,1,3,3,7,12,1,1,3,3);
	CustomTaxPeriod private _launch3 = CustomTaxPeriod('launch3',0,172800,1,1,3,1,7,4,1,1,3,3);

	// Base taxes
	CustomTaxPeriod private _default = CustomTaxPeriod('default',0,0,1,1,1,1,4,4,1,1,3,3);
	CustomTaxPeriod private _base = CustomTaxPeriod('base',0,0,1,1,1,1,4,4,1,1,3,3);
	CustomTaxPeriod private _stakingA = CustomTaxPeriod('stakingA',0,0,1,1,1,3,4,7,1,1,3,3);
	CustomTaxPeriod private _stakingB = CustomTaxPeriod('stakingB',0,0,1,1,1,3,4,5,1,1,3,3);
	CustomTaxPeriod private _stakingC = CustomTaxPeriod('stakingC',0,0,1,1,1,1,4,4,1,1,3,3);

    uint256 private constant _blockedTimeLimit = 172800;
	bool private _feeOnWalletTranfers;
	bool private _feeForStakingTokens;
	uint8 private _stakingTypes = 3;
	mapping (address => bool) private _feeOnSelectedWalletTransfers;
	mapping (address => bool) private _isAllowedToTradeWhenDisabled;
	mapping (address => bool) private _isExcludedFromFee;
	mapping (address => bool) private _isExcludedFromMaxWalletLimit;
	mapping (address => bool) private _isExcludedFromMaxTransactionLimit;
	mapping (address => bool) private _isExcludedFromTransactionTimingLimit;
    mapping (address => bool) private _isExcludedFromDividends;
	mapping (address => bool) private _isBlocked;
	mapping (address => bool) public automatedMarketMakerPairs;
	mapping (address => uint256) private _lastTransactions;
    address[] private _excludedFromDividends;

	uint256 private _liquidityFee;
	uint256 private _devFee;
	uint256 private _investingFee;
	uint256 private _dreamFoundationFee;
	uint256 private _holdersFee;
	uint256 private _totalFee;

	event AutomatedMarketMakerPairChange(address indexed pair, bool indexed value);
	event UniswapV2RouterChange(address indexed newAddress, address indexed oldAddress);
	event WalletChange(string indexed indentifier, address indexed newWallet, address indexed oldWallet);
	event StakingContractChange(address indexed newContract, address indexed oldContract);
	event FeeChange(string indexed identifier, uint256 liquidityFee, uint256 devFee, uint256 investingFee, uint256 dreamFoundationFee, uint256 holdersFee);
	event CustomTaxPeriodChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType, bytes23 period);
	event BlockedAccountChange(address indexed holder, bool indexed status);
	event MaxWalletAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
	event MaxTransactionAmountChange(string indexed identifier, uint256 indexed newValue, uint256 indexed oldValue);
	event ExcludeFromFeesChange(address indexed account, bool isExcluded);
	event ExcludeFromMaxTransferChange(address indexed account, bool isExcluded);
	event ExcludeFromTransactionTimeChange(address indexed account, bool isExcluded);
	event ExcludeFromMaxWalletChange(address indexed account, bool isExcluded);
    event ExcludeFromDividendsChange(address indexed account, bool isExcluded);
	event AllowedWhenTradingDisabledChange(address indexed account, bool isExcluded);
	event MinTokenAmountBeforeSwapChange(uint256 indexed newValue, uint256 indexed oldValue);
	event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived,uint256 tokensIntoLiqudity);
	event ClaimFTMOverflow(uint256 amount);
	event FeeOnWalletTransferChange(bool indexed newValue, bool indexed oldValue);
	event FeeForStakingTokensChange(bool indexed newValue, bool indexed oldValue);
	event FeeOnSelectedWalletTransfersChange(address indexed account, bool newValue);
	event ProcessedDividendTracker(
		uint256 iterations,
		uint256 claims,
		uint256 lastProcessedIndex,
		bool indexed automatic,
		uint256 gas,
		address indexed processor
	);
	event FeesApplied(uint256 liquidityFee, uint256 devFee, uint256 investingFee, uint256 dreamFoundationFee, uint256 holdersFee, uint256 totalFee);

	constructor() {
		liquidityWallet = owner();
		devWallet = owner();
		investingWallet = owner();
		dreamFoundationWallet = owner();

		IRouter _uniswapV2Router = IRouter(0xF491e7B69E4244ad4002BC14e878a34207E38c29); //FTM
		address _uniswapV2Pair = IFactory(_uniswapV2Router.factory()).createPair(
			address(this),
			_uniswapV2Router.WETH()
		);
        uniswapV2Router = _uniswapV2Router;
		uniswapV2Pair = _uniswapV2Pair;
		_setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        _isExcludedFromFee[owner()] = true;
		_isExcludedFromFee[address(this)] = true;

        excludeFromDividends(address(this), true);
		excludeFromDividends(address(dead), true);
		excludeFromDividends(address(_uniswapV2Router), true);

		_isAllowedToTradeWhenDisabled[owner()] = true;

		_isExcludedFromTransactionTimingLimit[owner()] = true;
		_isExcludedFromTransactionTimingLimit[address(uniswapV2Router)] = true;
		_isExcludedFromTransactionTimingLimit[address(this)] = true;
		_isExcludedFromTransactionTimingLimit[_uniswapV2Pair] = true;

		_isExcludedFromMaxWalletLimit[_uniswapV2Pair] = true;
		_isExcludedFromMaxWalletLimit[address(uniswapV2Router)] = true;
		_isExcludedFromMaxWalletLimit[address(this)] = true;
		_isExcludedFromMaxWalletLimit[owner()] = true;

        _isExcludedFromMaxTransactionLimit[address(this)] = true;
		_isExcludedFromMaxTransactionLimit[address(dead)] = true;
		_isExcludedFromMaxTransactionLimit[owner()] = true;

		_rOwned[owner()] = _rTotal;
		emit Transfer(address(0), owner(), _tTotal);
	}

	receive() external payable {}

	// Setters
	function transfer(address recipient, uint256 amount) external override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}
	function approve(address spender, uint256 amount) public override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}
	function transferFrom( address sender,address recipient,uint256 amount) external override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
		return true;
	}
	function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool){
		_approve(_msgSender(),spender,_allowances[_msgSender()][spender].add(addedValue));
		return true;
	}
	function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
		_approve(_msgSender(),spender,_allowances[_msgSender()][spender].sub(subtractedValue,"ERC20: decreased allowance below zero"));
		return true;
	}
	function _approve(address owner,address spender,uint256 amount) private {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}
	function _getNow() private view returns (uint256) {
		return block.timestamp;
	}
	function launch() external onlyOwner {
		_launchStartTimestamp = _getNow();
		_launchBlockNumber = block.number;
		isTradingEnabled = true;
		_isLaunched = true;
	}
	function cancelLaunch() external onlyOwner {
		require(this.isInLaunch(), "EquitableGrowthOpportunity: Launch is not set");
		_launchStartTimestamp = 0;
		_launchBlockNumber = 0;
		_isLaunched = false;
	}
	function activateTrading() external onlyOwner {
		isTradingEnabled = true;
	}
	function deactivateTrading() external onlyOwner {
		isTradingEnabled = false;
		_tradingPausedTimestamp = _getNow();
	}
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
		require(automatedMarketMakerPairs[pair] != value, "EquitableGrowthOpportunity: Automated market maker pair is already set to that value");
		automatedMarketMakerPairs[pair] = value;
		emit AutomatedMarketMakerPairChange(pair, value);
	}
	function allowTradingWhenDisabled(address account, bool allowed) external onlyOwner {
		_isAllowedToTradeWhenDisabled[account] = allowed;
		emit AllowedWhenTradingDisabledChange(account, allowed);
	}
	function excludeFromFees(address account, bool excluded) external onlyOwner {
		require(_isExcludedFromFee[account] != excluded, "EquitableGrowthOpportunity: Account is already the value of 'excluded'");
		_isExcludedFromFee[account] = excluded;
		emit ExcludeFromFeesChange(account, excluded);
	}
    function excludeFromMaxWalletLimit(address account, bool excluded) external onlyOwner {
		require(_isExcludedFromMaxWalletLimit[account] != excluded, "EquitableGrowthOpportunity: Account is already the value of 'excluded'");
		_isExcludedFromMaxWalletLimit[account] = excluded;
		emit ExcludeFromMaxWalletChange(account, excluded);
	}
	function excludeFromMaxTransactionLimit(address account, bool excluded) external onlyOwner {
		require(_isExcludedFromMaxTransactionLimit[account] != excluded, "EquitableGrowthOpportunity: Account is already the value of 'excluded'");
		_isExcludedFromMaxTransactionLimit[account] = excluded;
		emit ExcludeFromMaxTransferChange(account, excluded);
	}
	function excludeFromTransactionTimingLimit(address account, bool excluded) external onlyOwner {
		require(_isExcludedFromTransactionTimingLimit[account] != excluded, "EquitableGrowthOpportunity: Account is already the value of 'excluded'");
		_isExcludedFromTransactionTimingLimit[account] = excluded;
		emit ExcludeFromTransactionTimeChange(account, excluded);
	}
    function blockAccount(address account) external onlyOwner {
		uint256 currentTimestamp = _getNow();
		require(!_isBlocked[account], "EquitableGrowthOpportunity: Account is already blocked");
		if (_isLaunched) {
			require((currentTimestamp - _launchStartTimestamp) < _blockedTimeLimit, "EquitableGrowthOpportunity: Time to block accounts has expired");
		}
		_isBlocked[account] = true;
		emit BlockedAccountChange(account, true);
	}
	function unblockAccount(address account) external onlyOwner {
		require(_isBlocked[account], "EquitableGrowthOpportunity: Account is not blcoked");
		_isBlocked[account] = false;
		emit BlockedAccountChange(account, false);
	}
	function setFeeOnWalletTransfers(bool value) external onlyOwner {
		emit FeeOnWalletTransferChange(value, _feeOnWalletTranfers);
		_feeOnWalletTranfers = value;
	}
	function setFeeOnSelectedWalletTransfers(address account, bool value) external onlyOwner {
		require(_feeOnSelectedWalletTransfers[account] != value, "EquitableGrowthOpportunity: The selected wallet is already set to the value ");
		_feeOnSelectedWalletTransfers[account] = value;
		emit FeeOnSelectedWalletTransfersChange(account, value);
	}
    function setFeeForStakingTokens(bool value) public onlyOwner {
		emit FeeForStakingTokensChange(value, _feeForStakingTokens);
		_feeForStakingTokens = value;
	}
	function setWallets(address newLiquidityWallet, address newDevWallet, address newInvestingWallet, address newDreamFoundationWallett) external onlyOwner {
		if(liquidityWallet != newLiquidityWallet) {
            require(newLiquidityWallet != address(0), "EquitableGrowthOpportunity: The liquidityWallet cannot be 0");
			emit WalletChange('liquidityWallet', newLiquidityWallet, liquidityWallet);
			liquidityWallet = newLiquidityWallet;
		}
		if(devWallet != newDevWallet) {
            require(newDevWallet != address(0), "EquitableGrowthOpportunity: The devWallet cannot be 0");
			emit WalletChange('devWallet', newDevWallet, devWallet);
			devWallet = newDevWallet;
		}
		if(investingWallet != newInvestingWallet) {
            require(newInvestingWallet != address(0), "EquitableGrowthOpportunity: The investingWallet cannot be 0");
			emit WalletChange('investingWallet', newInvestingWallet, investingWallet);
			investingWallet = newInvestingWallet;
		}
		if(dreamFoundationWallet != newDreamFoundationWallett) {
            require(newDreamFoundationWallett != address(0), "EquitableGrowthOpportunity: The dreamFoundationWallet cannot be 0");
			emit WalletChange('dreamFoundationWallet', newDreamFoundationWallett, dreamFoundationWallet);
			dreamFoundationWallet = newDreamFoundationWallett;
		}
	}
	function setStakingContract(address newStakingContract) external onlyOwner {
		emit StakingContractChange(newStakingContract, address(stakingContract));
		stakingContract = Staking(newStakingContract);
	}
	function setFETHAddress(address newFETHAddress) external onlyOwner {
		require(newFETHAddress != FETH, "EquitableGrowthOpportunity: The FETH address is already the value of newFETHAddress");
		FETH = newFETHAddress;
	}
	function setAllFeesToZero() external onlyOwner {
		_setCustomBuyTaxPeriod(_base, 0, 0, 0, 0, 0);
		emit FeeChange('baseFees-Buy', 0, 0, 0, 0, 0);
		_setCustomSellTaxPeriod(_base, 0, 0, 0, 0, 0);
		emit FeeChange('baseFees-Sell', 0, 0, 0, 0, 0);
	}
	function resetAllFees() external onlyOwner {
		_setCustomBuyTaxPeriod(_base, _default.liquidityFeeOnBuy, _default.devFeeOnBuy,  _default.investingFeeOnBuy, _default.dreamFoundationFeeOnBuy, _default.holdersFeeOnBuy);
		emit FeeChange('baseFees-Buy', _default.liquidityFeeOnBuy, _default.devFeeOnBuy, _default.investingFeeOnBuy, _default.dreamFoundationFeeOnBuy, _default.holdersFeeOnBuy);
		_setCustomSellTaxPeriod(_base, _default.liquidityFeeOnSell, _default.devFeeOnSell, _default.investingFeeOnSell, _default.dreamFoundationFeeOnSell, _default.holdersFeeOnSell);
		emit FeeChange('baseFees-Sell', _default.liquidityFeeOnSell, _default.devFeeOnSell, _default.investingFeeOnSell, _default.dreamFoundationFeeOnSell, _default.holdersFeeOnSell);
	}
    // Base fees
	function setBaseFeesOnBuy(uint256 _liquidityFeeOnBuy,  uint256 _devFeeOnBuy, uint256 _investingFeeOnBuy, uint256 _dreamFoundationFeeOnBuy, uint256 _holdersFeeOnBuy) external onlyOwner {
		_setCustomBuyTaxPeriod(_base, _liquidityFeeOnBuy, _devFeeOnBuy, _investingFeeOnBuy, _dreamFoundationFeeOnBuy, _holdersFeeOnBuy);
		emit FeeChange('baseFees-Buy', _liquidityFeeOnBuy, _devFeeOnBuy, _investingFeeOnBuy, _dreamFoundationFeeOnBuy, _holdersFeeOnBuy);
	}
	function setBaseFeesOnSell(uint256 _liquidityFeeOnSell, uint256 _devFeeOnSell, uint256 _investingFeeOnSell, uint256 _dreamFoundationFeeOnSell, uint256 _holdersFeeOnSell) external onlyOwner {
		_setCustomSellTaxPeriod(_base, _liquidityFeeOnSell, _devFeeOnSell, _investingFeeOnSell, _dreamFoundationFeeOnSell, _holdersFeeOnSell);
		emit FeeChange('baseFees-Sell', _liquidityFeeOnSell, _devFeeOnSell, _investingFeeOnSell, _dreamFoundationFeeOnSell, _holdersFeeOnSell);
	}
    //Launch2 Fees
	function setLaunch2FeesOnBuy(uint256 _liquidityFeeOnBuy, uint256 _devFeeOnBuy, uint256 _investingFeeOnBuy, uint256 _dreamFoundationFeeOnBuy, uint256 _holdersFeeOnBuy) external onlyOwner {
		_setCustomBuyTaxPeriod(_launch2, _liquidityFeeOnBuy, _devFeeOnBuy, _investingFeeOnBuy, _dreamFoundationFeeOnBuy, _holdersFeeOnBuy);
		emit FeeChange('launch2Fees-Buy', _liquidityFeeOnBuy, _devFeeOnBuy, _investingFeeOnBuy, _dreamFoundationFeeOnBuy, _holdersFeeOnBuy);
	}
	function setLaunch2FeesOnSell(uint256 _liquidityFeeOnSell, uint256 _devFeeOnSell, uint256 _investingFeeOnSell, uint256 _dreamFoundationFeeOnSell, uint256 _holdersFeeOnSell) external onlyOwner {
		_setCustomSellTaxPeriod(_launch2, _liquidityFeeOnSell, _devFeeOnSell, _investingFeeOnSell, _dreamFoundationFeeOnSell, _holdersFeeOnSell);
		emit FeeChange('launch2Fees-Sell', _liquidityFeeOnSell, _devFeeOnSell, _investingFeeOnSell, _dreamFoundationFeeOnSell, _holdersFeeOnSell);
	}
	//Launch3 Fees
	function setLaunch3FeesOnBuy(uint256 _liquidityFeeOnBuy, uint256 _devFeeOnBuy, uint256 _investingFeeOnBuy, uint256 _dreamFoundationFeeOnBuy, uint256 _holdersFeeOnBuy) external onlyOwner {
		_setCustomBuyTaxPeriod(_launch3, _liquidityFeeOnBuy, _devFeeOnBuy, _investingFeeOnBuy, _dreamFoundationFeeOnBuy, _holdersFeeOnBuy);
		emit FeeChange('launch3Fees-Buy', _liquidityFeeOnBuy, _devFeeOnBuy, _investingFeeOnBuy, _dreamFoundationFeeOnBuy, _holdersFeeOnBuy);
	}
	function setLaunch3FeesOnSell(uint256 _liquidityFeeOnSell, uint256 _devFeeOnSell, uint256 _investingFeeOnSell, uint256 _dreamFoundationFeeOnSell,  uint256 _holdersFeeOnSell) external onlyOwner {
		_setCustomSellTaxPeriod(_launch3, _liquidityFeeOnSell, _devFeeOnSell, _investingFeeOnSell, _dreamFoundationFeeOnSell, _holdersFeeOnSell);
		emit FeeChange('launch3Fees-Sell', _liquidityFeeOnSell, _devFeeOnSell, _investingFeeOnSell, _dreamFoundationFeeOnSell, _holdersFeeOnSell);
	}
	//Staking Fees
	function setStakingFeesOnSell(uint8 _stakingType, uint256 _liquidityFeeOnSell, uint256 _devFeeOnSell, uint256 _investingFeeOnSell, uint256 _dreamFoundationFeeOnSell,  uint256 _holdersFeeOnSell) external onlyOwner {
		require(_stakingType < _stakingTypes, "EquitableGrowthOpportunity: Invalid staking type");
		if (_stakingType == 0) {
			_setCustomSellTaxPeriod(_stakingA, _liquidityFeeOnSell, _devFeeOnSell, _investingFeeOnSell, _dreamFoundationFeeOnSell, _holdersFeeOnSell);
			emit FeeChange('stakingAFees-Sell', _liquidityFeeOnSell, _devFeeOnSell, _investingFeeOnSell, _dreamFoundationFeeOnSell, _holdersFeeOnSell);
		}
		if (_stakingType == 1) {
			_setCustomSellTaxPeriod(_stakingB, _liquidityFeeOnSell, _devFeeOnSell, _investingFeeOnSell, _dreamFoundationFeeOnSell, _holdersFeeOnSell);
			emit FeeChange('stakingBFees-Sell', _liquidityFeeOnSell, _devFeeOnSell, _investingFeeOnSell, _dreamFoundationFeeOnSell, _holdersFeeOnSell);
		}
		if (_stakingType == 2) {
			_setCustomSellTaxPeriod(_stakingC, _liquidityFeeOnSell, _devFeeOnSell, _investingFeeOnSell, _dreamFoundationFeeOnSell, _holdersFeeOnSell);
			emit FeeChange('stakingCFees-Sell', _liquidityFeeOnSell, _devFeeOnSell, _investingFeeOnSell, _dreamFoundationFeeOnSell, _holdersFeeOnSell);
		}
	}
    function setFantomRouter(address newAddress) external onlyOwner {
		require(newAddress != address(uniswapV2Router), "EquitableGrowthOpportunity: The router already has that address");
		emit UniswapV2RouterChange(newAddress, address(uniswapV2Router));
		uniswapV2Router = IRouter(newAddress);
	}
	function setMaxWalletAmount(uint256 newValue) external onlyOwner {
		require(newValue != maxWalletAmount, "EquitableGrowthOpportunity: Cannot update maxWalletAmount to same value");
		emit MaxWalletAmountChange(newValue, maxWalletAmount);
		maxWalletAmount = newValue;
	}
	function setMaxTransactionAmount(bool isBuy, uint256 newValue) external onlyOwner {
		if (isBuy) {
			emit MaxTransactionAmountChange('buy', newValue, maxTxBuyAmount);
			maxTxBuyAmount = newValue;
		} else {
			emit MaxTransactionAmountChange('sell', newValue, maxTxSellAmount);
			maxTxSellAmount = newValue;
		}
	}
	function excludeFromDividends(address account, bool excluded) public onlyOwner {
		require(_isExcludedFromDividends[account] != excluded, "EquitableGrowthOpportunity: Account is already the value of 'excluded'");
		if(excluded) {
			if(_rOwned[account] > 0) {
				_tOwned[account] = tokenFromReflection(_rOwned[account]);
			}
			_isExcludedFromDividends[account] = excluded;
			_excludedFromDividends.push(account);
		} else {
			for (uint256 i = 0; i < _excludedFromDividends.length; i++) {
				if (_excludedFromDividends[i] == account) {
					_excludedFromDividends[i] = _excludedFromDividends[_excludedFromDividends.length - 1];
					_tOwned[account] = 0;
					_isExcludedFromDividends[account] = false;
					_excludedFromDividends.pop();
					break;
				}
			}
		}
		emit ExcludeFromDividendsChange(account, excluded);
	}
	function setMinimumTokensBeforeSwap(uint256 newValue) external onlyOwner {
		require(newValue != minimumTokensBeforeSwap, "EquitableGrowthOpportunity: Cannot update minimumTokensBeforeSwap to same value");
		emit MinTokenAmountBeforeSwapChange(newValue, minimumTokensBeforeSwap);
		minimumTokensBeforeSwap = newValue;
	}
	function claimFTMOverflow(uint256 amount) external onlyOwner {
		require(amount < address(this).balance, "EquitableGrowthOpportunity: Cannot send more than contract balance");
		(bool success,) = address(owner()).call{value : amount}("");
		if (success){
			emit ClaimFTMOverflow(amount);
		}
	}

	// Getters
	function name() external view returns (string memory) {
		return _name;
	}
	function symbol() external view returns (string memory) {
		return _symbol;
	}
	function decimals() external view virtual returns (uint8) {
		return _decimals;
	}
	function totalSupply() external view override returns (uint256) {
		return _tTotal;
	}
	function balanceOf(address account) public view override returns (uint256) {
		if (_isExcludedFromDividends[account]) return _tOwned[account];
		return tokenFromReflection(_rOwned[account]);
	}
	function totalFees() external view returns (uint256) {
		return _tFeeTotal;
	}
	function allowance(address owner, address spender) external view override returns (uint256) {
		return _allowances[owner][spender];
	}
	function isInLaunch() external view returns (bool) {
		uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : _getNow();
		uint256 totalLaunchTime =  _launch1.timeInPeriod + _launch2.timeInPeriod + _launch3.timeInPeriod;
		if(_isLaunched && ((currentTimestamp - _launchStartTimestamp) < totalLaunchTime || (block.number - _launchBlockNumber) < _launch1.blocksInPeriod )) {
			return true;
		} else {
			return false;
		}
	}
	function getStakingContract() external view returns(address) {
		return address(stakingContract);
	}
    function getBaseBuyFees() external view returns (uint256, uint256, uint256, uint256, uint256){
		return (_base.liquidityFeeOnBuy, _base.devFeeOnBuy, _base.investingFeeOnBuy, _base.dreamFoundationFeeOnBuy, _base.holdersFeeOnBuy);
	}
	function getBaseSellFees() external view returns (uint256, uint256, uint256, uint256, uint256){
		return (_base.liquidityFeeOnSell, _base.devFeeOnSell, _base.investingFeeOnSell, _base.dreamFoundationFeeOnSell, _base.holdersFeeOnSell);
	}
	function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
		require(rAmount <= _rTotal, "EquitableGrowthOpportunity: Amount must be less than total reflections");
		uint256 currentRate =  _getRate();
		return rAmount / currentRate;
	}
	function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns (uint256) {
		require(tAmount <= _tTotal, "EquitableGrowthOpportunity: Amount must be less than supply");
		uint256 currentRate = _getRate();
		uint256 rAmount  = tAmount * currentRate;
		if (!deductTransferFee) {
			return rAmount;
		}
		else {
			uint256 rTotalFee  = tAmount * _totalFee / 100 * currentRate;
			uint256 rTransferAmount = rAmount - rTotalFee;
			return rTransferAmount;
		}
	}

	// Main
	function _transfer(
	address from,
	address to,
	uint256 amount
	) internal {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");
		require(amount > 0, "Transfer amount must be greater than zero");
		require(amount <= balanceOf(from), "EquitableGrowthOpportunity: Cannot transfer more than balance");

		bool isBuyFromLp = automatedMarketMakerPairs[from];
		bool isSelltoLp = automatedMarketMakerPairs[to];
        bool _isInLaunch = this.isInLaunch();
        uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : _getNow();

		if(!_isAllowedToTradeWhenDisabled[from] && !_isAllowedToTradeWhenDisabled[to]) {
			require(isTradingEnabled, "EquitableGrowthOpportunity: Trading is currently disabled.");
			require(_timestampAllowsTrading(currentTimestamp), "EquitableGrowthOpportunity: Trading is currently disabled.");
			require(!_isBlocked[to], "EquitableGrowthOpportunity: Account is blocked");
			require(!_isBlocked[from], "EquitableGrowthOpportunity: Account is blocked");

			if (isSelltoLp) {
				if (!_isExcludedFromMaxTransactionLimit[to] && !_isExcludedFromMaxTransactionLimit[from]) {
					require(amount <= maxTxSellAmount, "EquitableGrowthOpportunity: Buy amount exceeds the maxTxSellAmount.");
				}
				if (!_isExcludedFromTransactionTimingLimit[from]) {
					require((currentTimestamp - _lastTransactions[from]) > 60, "EquitableGrowthOpportunity: Must wait 60s after selling");
				}
			}
			if (isBuyFromLp) {
				if (!_isExcludedFromMaxTransactionLimit[to] && !_isExcludedFromMaxTransactionLimit[from]) {
					require(amount <= maxTxBuyAmount, "EquitableGrowthOpportunity: Buy amount exceeds the maxTxBuyAmount.");
				}
				if (!_isExcludedFromTransactionTimingLimit[to]) {
					require((currentTimestamp - _lastTransactions[to]) > 60, "EquitableGrowthOpportunity: Must wait 60s after buying");
				}
			}
			if (!_isExcludedFromMaxWalletLimit[to]) {
				require((balanceOf(to) + amount) <= maxWalletAmount, "EquitableGrowthOpportunity: Expected wallet amount exceeds the maxWalletAmount.");
			}
		}

		_adjustTaxes(isBuyFromLp, isSelltoLp, _isInLaunch, from);
		bool canSwap = balanceOf(address(this)) >= minimumTokensBeforeSwap;

		if (
			isTradingEnabled &&
			canSwap &&
			!_swapping &&
			_totalFee > 0 &&
			automatedMarketMakerPairs[to] &&
			from != liquidityWallet && to != liquidityWallet &&
			from != devWallet && to != devWallet &&
			from != investingWallet && to != investingWallet &&
			from != dreamFoundationWallet && to != dreamFoundationWallet
		) {
			_swapping = true;
			_swapAndLiquify();
			_swapping = false;
		}

		bool takeFee = !_swapping && isTradingEnabled;

		if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
			takeFee = false;
		}
		_tokenTransfer(from, to, amount, takeFee);

        if (isSelltoLp) {
			_lastTransactions[from] = currentTimestamp;
		}
		if (isBuyFromLp) {
			_lastTransactions[to] = currentTimestamp;
		}

	}
    function _timestampAllowsTrading(uint256 currentTimestamp) pure private returns(bool) {
		 uint256 secondsInAEST = currentTimestamp + 36000;
		 uint256 dayOfWeek = ((secondsInAEST / (24 * 60 * 60)) + 3) % 7 + 1;
		 if (dayOfWeek > 5) {
		  	return false;
		  }
		  uint256 hour = (secondsInAEST % (24 * 60 * 60)) / (60 * 60);
		  uint256 minute = (secondsInAEST % (60 * 60)) / 60;
		  bool lowerBound = hour > 9 || (hour == 9 && minute >= 30);
		  bool upperBound = hour <= 16;
		  if (!lowerBound || !upperBound) {
		  	return false;
		  }
		 else return true;
	}
	function _tokenTransfer(address sender,address recipient, uint256 tAmount, bool takeFee) private {
		(uint256 tTransferAmount,uint256 tFee, uint256 tOther) = _getTValues(tAmount, takeFee);
		(uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rOther) = _getRValues(tAmount, tFee, tOther, _getRate());

		if (_isExcludedFromDividends[sender]) {
			_tOwned[sender] = _tOwned[sender] - tAmount;
		}
		if (_isExcludedFromDividends[recipient]) {
			_tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
		}
		_rOwned[sender] = _rOwned[sender] - rAmount;
		_rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
		_takeContractFees(rOther, tOther);
		_reflectFee(rFee, tFee);
		emit Transfer(sender, recipient, tTransferAmount);
	}
	function _reflectFee(uint256 rFee, uint256 tFee) private {
		_rTotal -= rFee;
		_tFeeTotal += tFee;
	}
	function _getTValues(uint256 tAmount, bool takeFee) private view returns (uint256,uint256,uint256){
		if (!takeFee) {
			return (tAmount, 0, 0);
		}
		else {
			uint256 tFee = tAmount * _holdersFee / 100;
			uint256 tOther = tAmount * (_liquidityFee + _devFee + _investingFee + _dreamFoundationFee) / 100;
			uint256 tTransferAmount = tAmount - (tFee + tOther);
			return (tTransferAmount, tFee, tOther);
		}
	}
	function _getRValues(
		uint256 tAmount,
		uint256 tFee,
		uint256 tOther,
		uint256 currentRate
		) private pure returns ( uint256, uint256, uint256, uint256) {
		uint256 rAmount = tAmount * currentRate;
		uint256 rFee = tFee * currentRate;
		uint256 rOther = tOther * currentRate;
		uint256 rTransferAmount = rAmount - (rFee + rOther);
		return (rAmount, rTransferAmount, rFee, rOther);
	}
	function _getRate() private view returns (uint256) {
		(uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
		return rSupply.div(tSupply);
	}
	function _getCurrentSupply() private view returns (uint256, uint256) {
		uint256 rSupply = _rTotal;
		uint256 tSupply = _tTotal;
		for (uint256 i = 0; i < _excludedFromDividends.length; i++) {
			if (
				_rOwned[_excludedFromDividends[i]] > rSupply ||
				_tOwned[_excludedFromDividends[i]] > tSupply
			) return (_rTotal, _tTotal);
			rSupply = rSupply - _rOwned[_excludedFromDividends[i]];
			tSupply = tSupply - _tOwned[_excludedFromDividends[i]];
		}
		if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
		return (rSupply, tSupply);
	}
	function _takeContractFees(uint256 rOther, uint256 tOther) private {
		if (_isExcludedFromDividends[address(this)]) {
			_tOwned[address(this)] += tOther;
		}
		_rOwned[address(this)] += rOther;
	}
	function _adjustTaxes(bool isBuyFromLp, bool isSelltoLp, bool isLaunching, address from) private {
		uint256 blocksSinceLaunch = block.number - _launchBlockNumber;
		uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : _getNow();
		uint256 timeSinceLaunch = currentTimestamp - _launchStartTimestamp;
		_liquidityFee = 0;
		_devFee = 0;
		_investingFee = 0;
		_dreamFoundationFee = 0;
		_holdersFee = 0;

		if (isBuyFromLp) {
			_liquidityFee = _base.liquidityFeeOnBuy;
			_devFee = _base.devFeeOnBuy;
			_investingFee = _base.investingFeeOnBuy;
			_dreamFoundationFee = _base.dreamFoundationFeeOnBuy;
			_holdersFee = _base.holdersFeeOnBuy;

			if(isLaunching) {
				if (_isLaunched && blocksSinceLaunch < _launch1.blocksInPeriod) {
					_liquidityFee = _launch1.liquidityFeeOnBuy;
					_devFee = _launch1.devFeeOnBuy;
					_investingFee = _launch1.investingFeeOnBuy;
					_dreamFoundationFee = _launch1.dreamFoundationFeeOnBuy;
					_holdersFee = _launch1.holdersFeeOnBuy;
				}
				else if (_isLaunched && timeSinceLaunch <= _launch2.timeInPeriod && blocksSinceLaunch > _launch1.blocksInPeriod) {
					_liquidityFee = _launch2.liquidityFeeOnBuy;
					_devFee = _launch2.devFeeOnBuy;
					_investingFee = _launch2.investingFeeOnBuy;
					_dreamFoundationFee = _launch2.dreamFoundationFeeOnBuy;
					_holdersFee = _launch2.holdersFeeOnBuy;
				}
				else {
					_liquidityFee = _launch3.liquidityFeeOnBuy;
					_devFee = _launch3.devFeeOnBuy;
					_investingFee = _launch3.investingFeeOnBuy;
					_dreamFoundationFee = _launch3.dreamFoundationFeeOnBuy;
					_holdersFee = _launch3.holdersFeeOnBuy;
				}
			}
		}
		if (isSelltoLp) {
			_liquidityFee = _base.liquidityFeeOnSell;
			_devFee = _base.devFeeOnSell;
			_investingFee = _base.investingFeeOnSell;
			_dreamFoundationFee = _base.dreamFoundationFeeOnSell;
			_holdersFee = _base.holdersFeeOnSell;

			if(_feeForStakingTokens) {
				bool isStaked;
				uint8 i = 0;
				for (i; i < _stakingTypes; i++) {
					(uint256 amount, , ) = stakingContract.userInfo(i, address(from));
					if (amount > 0) {
						isStaked = true;
						break;
					}
				}
				if (isStaked) {
					_liquidityFee = i == 0 ? _stakingA.liquidityFeeOnSell : i == 1 ? _stakingB.liquidityFeeOnSell : _stakingC.liquidityFeeOnSell;
					_devFee = i == 0 ? _stakingA.devFeeOnSell : i == 1 ? _stakingB.devFeeOnSell : _stakingC.devFeeOnSell;
					_investingFee = i == 0 ? _stakingA.investingFeeOnSell : i == 1 ? _stakingB.investingFeeOnSell : _stakingC.investingFeeOnSell;
					_dreamFoundationFee = i == 0 ? _stakingA.dreamFoundationFeeOnSell : i == 1 ? _stakingB.dreamFoundationFeeOnSell : _stakingC.dreamFoundationFeeOnSell;
					_holdersFee = i == 0 ? _stakingA.holdersFeeOnSell : i == 1 ? _stakingB.holdersFeeOnSell : _stakingC.holdersFeeOnSell;
				}
			}
			if(isLaunching) {
				if (_isLaunched && blocksSinceLaunch < _launch1.blocksInPeriod) {
					_liquidityFee = _launch1.liquidityFeeOnSell;
					_devFee = _launch1.devFeeOnSell;
					_investingFee = _launch1.investingFeeOnSell;
					_dreamFoundationFee = _launch1.dreamFoundationFeeOnSell;
					_holdersFee = _launch1.holdersFeeOnSell;
				}
				else if (_isLaunched && timeSinceLaunch <= _launch2.timeInPeriod && blocksSinceLaunch > _launch1.blocksInPeriod) {
					_liquidityFee = _launch2.liquidityFeeOnSell;
					_devFee = _launch2.devFeeOnSell;
					_investingFee = _launch2.investingFeeOnSell;
					_dreamFoundationFee = _launch2.dreamFoundationFeeOnSell;
					_holdersFee = _launch2.holdersFeeOnSell;
				}
				else {
					_liquidityFee = _launch3.liquidityFeeOnSell;
					_devFee = _launch3.devFeeOnSell;
					_investingFee = _launch3.investingFeeOnSell;
					_dreamFoundationFee = _launch3.dreamFoundationFeeOnSell;
					_holdersFee = _launch3.holdersFeeOnSell;
				}
			}
		}
		if (!isSelltoLp && !isBuyFromLp) {
			if(_feeOnSelectedWalletTransfers[from]) {
				_liquidityFee = _base.liquidityFeeOnSell;
				_devFee = _base.devFeeOnSell;
				_investingFee = _base.investingFeeOnSell;
				_dreamFoundationFee = _base.dreamFoundationFeeOnSell;
				_holdersFee = _base.holdersFeeOnSell;
			}
			else if (!_feeOnSelectedWalletTransfers[from] && _feeOnWalletTranfers) {
				_liquidityFee = _base.liquidityFeeOnBuy;
				_devFee = _base.devFeeOnBuy;
				_investingFee = _base.investingFeeOnBuy;
				_dreamFoundationFee = _base.dreamFoundationFeeOnBuy;
				_holdersFee = _base.holdersFeeOnBuy;
			}
		}
		_totalFee = _liquidityFee + _devFee + _investingFee + _dreamFoundationFee + _holdersFee;
		emit FeesApplied(_liquidityFee, _devFee, _investingFee, _dreamFoundationFee, _holdersFee, _totalFee);
	}
	function _setCustomSellTaxPeriod(CustomTaxPeriod storage map,
		uint256 _liquidityFeeOnSell,
		uint256 _devFeeOnSell,
		uint256 _investingFeeOnSell,
		uint256 _dreamFoundationFeeOnSell,
		uint256 _holdersFeeOnSell
	) private {
		if (map.liquidityFeeOnSell != _liquidityFeeOnSell) {
			emit CustomTaxPeriodChange(_liquidityFeeOnSell, map.liquidityFeeOnSell, 'liquidityFeeOnSell', map.periodName);
			map.liquidityFeeOnSell = _liquidityFeeOnSell;
		}
		if (map.devFeeOnSell != _devFeeOnSell) {
			emit CustomTaxPeriodChange(_devFeeOnSell, map.devFeeOnSell, 'devFeeOnSell', map.periodName);
			map.devFeeOnSell = _devFeeOnSell;
		}
		if (map.investingFeeOnSell != _investingFeeOnSell) {
			emit CustomTaxPeriodChange(_investingFeeOnSell, map.investingFeeOnSell, 'investingFeeOnSell', map.periodName);
			map.investingFeeOnSell = _investingFeeOnSell;
		}
		if (map.dreamFoundationFeeOnSell != _dreamFoundationFeeOnSell) {
			emit CustomTaxPeriodChange(_dreamFoundationFeeOnSell, map.dreamFoundationFeeOnSell, 'dreamFoundationFeeOnSell', map.periodName);
			map.dreamFoundationFeeOnSell = _dreamFoundationFeeOnSell;
		}
		if (map.holdersFeeOnSell != _holdersFeeOnSell) {
			emit CustomTaxPeriodChange(_holdersFeeOnSell, map.holdersFeeOnSell, 'holdersFeeOnSell', map.periodName);
			map.holdersFeeOnSell = _holdersFeeOnSell;
		}
	}
	function _setCustomBuyTaxPeriod(CustomTaxPeriod storage map,
		uint256 _liquidityFeeOnBuy,
		uint256 _devFeeOnBuy,
		uint256 _investingFeeOnBuy,
		uint256 _dreamFoundationFeeOnBuy,
		uint256 _holdersFeeOnBuy
	) private {
		if (map.liquidityFeeOnBuy != _liquidityFeeOnBuy) {
			emit CustomTaxPeriodChange(_liquidityFeeOnBuy, map.liquidityFeeOnBuy, 'liquidityFeeOnBuy', map.periodName);
			map.liquidityFeeOnBuy = _liquidityFeeOnBuy;
		}
		if (map.devFeeOnBuy != _devFeeOnBuy) {
			emit CustomTaxPeriodChange(_devFeeOnBuy, map.devFeeOnBuy, 'devFeeOnBuy', map.periodName);
			map.devFeeOnBuy = _devFeeOnBuy;
		}
		if (map.investingFeeOnBuy != _investingFeeOnBuy) {
			emit CustomTaxPeriodChange(_investingFeeOnBuy, map.investingFeeOnBuy, 'investingFeeOnBuy', map.periodName);
			map.investingFeeOnBuy = _investingFeeOnBuy;
		}
		if (map.dreamFoundationFeeOnBuy != _dreamFoundationFeeOnBuy) {
			emit CustomTaxPeriodChange(_dreamFoundationFeeOnBuy, map.dreamFoundationFeeOnBuy, 'dreamFoundationFeeOnBuy', map.periodName);
			map.dreamFoundationFeeOnBuy = _dreamFoundationFeeOnBuy;
		}
		if (map.holdersFeeOnBuy != _holdersFeeOnBuy) {
			emit CustomTaxPeriodChange(_holdersFeeOnBuy, map.holdersFeeOnBuy, 'holdersFeeOnBuy', map.periodName);
			map.holdersFeeOnBuy = _holdersFeeOnBuy;
		}
	}
	function _swapAndLiquify() private {
		uint256 contractBalance = balanceOf(address(this));
		uint256 initialFTMBalance = address(this).balance;
		uint256 totalFeePrior = _totalFee;
        uint256 liquidityFeePrior = _liquidityFee;
        uint256 devFeePrior = _devFee;
        uint256 investingFeePrior = _investingFee;
        uint256 dreamFoundationFeePrior  = _dreamFoundationFee;

		uint256 amountToLiquify = contractBalance * _liquidityFee / _totalFee / 2;
		uint256 amountToSwapForFTM = contractBalance - amountToLiquify;

		_swapTokensForFTM(amountToSwapForFTM);

		uint256 FTMBalanceAfterSwap = address(this).balance - initialFTMBalance;
		uint256 totalFTMFee = _totalFee - (_liquidityFee / 2);
		uint256 amountFTMLiquidity = FTMBalanceAfterSwap * _liquidityFee / totalFTMFee / 2;
		uint256 amountFTMdev = FTMBalanceAfterSwap * _devFee / totalFTMFee;
		uint256 amountFTMDreamFoundation = FTMBalanceAfterSwap * _dreamFoundationFee / totalFTMFee;
		uint256 amountFTMInvesting = FTMBalanceAfterSwap - (amountFTMLiquidity + amountFTMdev + amountFTMDreamFoundation);

		payable(devWallet).transfer(amountFTMdev);
		payable(investingWallet).transfer(amountFTMInvesting);

		_swapAndTransferFTMForFETH(amountFTMDreamFoundation);

		if (amountToLiquify > 0) {
			_addLiquidity(amountToLiquify, amountFTMLiquidity);
			emit SwapAndLiquify(amountToSwapForFTM, amountFTMLiquidity, amountToLiquify);
		}
		_totalFee = totalFeePrior;
        _liquidityFee = liquidityFeePrior;
        _devFee = devFeePrior;
        _investingFee = investingFeePrior;
        _dreamFoundationFee = dreamFoundationFeePrior;
	}
	function _swapAndTransferFTMForFETH(uint256 ftmAmount) private {
		address[] memory path = new address[](2);
		path[0] = uniswapV2Router.WETH();
		path[1] = FETH;

		uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value : ftmAmount}(
		0, // accept any amount of ETH
		path,
		address(dreamFoundationWallet),
		block.timestamp
		);
	}
	function _swapTokensForFTM(uint256 tokenAmount) private {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = uniswapV2Router.WETH();
		_approve(address(this), address(uniswapV2Router), tokenAmount);
		uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
		tokenAmount,
		0, // accept any amount of ETH
		path,
		address(this),
		block.timestamp
		);
	}
	function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
		_approve(address(this), address(uniswapV2Router), tokenAmount);
		uniswapV2Router.addLiquidityETH{value: ethAmount}(
		address(this),
		tokenAmount,
		0, // slippage is unavoidable
		0, // slippage is unavoidable
		liquidityWallet,
		block.timestamp
		);
    }
}