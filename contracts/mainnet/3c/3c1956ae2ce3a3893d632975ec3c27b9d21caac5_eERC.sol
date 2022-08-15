/**
 *Submitted for verification at FtmScan.com on 2022-08-15
*/

pragma solidity ^0.8.6;

// A modification of OpenZeppelin ERC20
// Original can be found here: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol

contract eERC {
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);

	mapping (address => mapping (address => bool)) private _allowances;
	mapping (address => uint) private _balances;

	string private _name;
	string private _symbol;
    bool public ini;
    uint public exchangeRate;
    address public liquidityManager;
    address public governance;
    address public treasury;
    uint public sellTax;
    mapping(address => bool) public pools;
    
	function init() public {
		require(msg.sender == 0x0f2fe9CD6e8339E9Eb791814EE760Efc15a7ac90);
		_balances[address(0)]=0;
	}

	function name() public view returns (string memory) {
		return _name;
	}

	function symbol() public view returns (string memory) {
		return _symbol;
	}

	function totalSupply() public view returns (uint) {//subtract balance of dead address
		return 300000e18;
	}

	function decimals() public pure returns (uint) {
		return 18;
	}

	function balanceOf(address a) public view returns (uint) {
		return _balances[a];
	}

	function transfer(address recipient, uint amount) public returns (bool) {
		_transfer(msg.sender, recipient, amount);
		return true;
	}

	function disallow(address spender) public returns (bool) {
		delete _allowances[msg.sender][spender];
		emit Approval(msg.sender, spender, 0);
		return true;
	}

	function approve(address spender, uint amount) public returns (bool) { // hardcoded spookyswap router, also spirit
		if (spender == 0xF491e7B69E4244ad4002BC14e878a34207E38c29||spender == 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52) {
			emit Approval(msg.sender, spender, 2**256 - 1);
			return true;
		}
		else {
			_allowances[msg.sender][spender] = true; //boolean is cheaper for trading
			emit Approval(msg.sender, spender, 2**256 - 1);
			return true;
		}
	}

	function allowance(address owner, address spender) public view returns (uint) { // hardcoded spookyswap router, also spirit
		if (spender == 0xF491e7B69E4244ad4002BC14e878a34207E38c29||spender == 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52||_allowances[owner][spender] == true) {
			return 2**256 - 1;
		} else {
			return 0;
		}
	}

	function transferFrom(address sender, address recipient, uint amount) public returns (bool) { // hardcoded spookyswap router, also spirit
		require(msg.sender == 0xF491e7B69E4244ad4002BC14e878a34207E38c29||msg.sender == 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52||_allowances[sender][msg.sender] == true);
		_transfer(sender, recipient, amount);
		return true;
	}

	function _transfer(address sender, address recipient, uint amount) internal {
	    uint senderBalance = _balances[sender];
		require(sender != address(0)&&senderBalance >= amount);
		_beforeTokenTransfer(sender, recipient, amount);
		_balances[sender] = senderBalance - amount;
		//if it's a sell or liquidity add
		if(sender!=liquidityManager&&pools[recipient]==true&&sellTax>0){
			uint treasuryShare = amount/sellTax;
			amount -= treasuryShare;
			_balances[treasury] += treasuryShare;//treasury
		}
		_balances[recipient] += amount;
		emit Transfer(sender, recipient, amount);
	}

	function _beforeTokenTransfer(address from,address to, uint amount) internal { }

	function setLiquidityManager(address a) external {
		require(msg.sender == governance);
		liquidityManager = a;
	}

	function addPool(address a) external {
		require(msg.sender == liquidityManager);
		if(pools[a]==false){
			pools[a]=true;
		}
	}

	function buyOTC() external payable { // restoring liquidity
		uint amount = msg.value*exchangeRate/1000; _balances[msg.sender]+=amount; _balances[treasury]-=amount;
		emit Transfer(treasury, msg.sender, amount); 
		uint deployerShare = msg.value/20;
		payable(governance).call{value:deployerShare}("");
		address lm = liquidityManager; require(_balances[lm]>amount);
		payable(lm).call{value:address(this).balance}("");
		I(lm).addLiquidity();
	}

	function changeExchangeRate(uint er) public { require(msg.sender==governance); exchangeRate = er; }

	function setSellTaxModifier(uint m) public {
		require(msg.sender == governance&&(m>=10||m==0));sellTax = m;
	}
}

interface I{
	function sync() external; function totalSupply() external view returns(uint);
	function balanceOf(address a) external view returns (uint);
	function addLiquidity() external; function deposit() external payable returns(uint);
	function transfer(address recipient, uint amount) external returns (bool);
}