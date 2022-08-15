/**
 *Submitted for verification at FtmScan.com on 2022-08-14
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
    address[] public pools;

	function init() public {
	    require(ini==false);ini=true;
	    //require(msg.sender==0x0f2fe9CD6e8339E9Eb791814EE760Efc15a7ac90);
		//_treasury = 0xeece0f26876a9b5104fEAEe1CE107837f96378F2;
		//_founding = 0xAE6ba0D4c93E529e273c8eD48484EA39129AaEdc;
		//_staking = 0x0FaCF0D846892a10b1aea9Ee000d7700992B64f8;
		//liquidityManager = 0x2Fe82aa8332Ba19F8bf194440f63A254A19d99F3;
		//address p1 = 0xbf8fDdf052bEb8E61F1d9bBD736A88b2B57F0a94;
		//address p2 = 0x3Bb6713E01B27a759d1A6f907bcd97D2B1f0F209;
		//address p3 = 0xE3450307997CB52C50B50fF040681401C56AecDe;
		//_balances[liquidityManager]+=40000e18;
		//_balances[0xeece0f26876a9b5104fEAEe1CE107837f96378F2]-=40000e18;
		uint amount = _balances[liquidityManager]-30000e18;
		_transfer(liquidityManager,0xeece0f26876a9b5104fEAEe1CE107837f96378F2,amount);
		_transfer(0xeece0f26876a9b5104fEAEe1CE107837f96378F2,0x000000000000000000000000000000000000dEaD,200000e18);
		exchangeRate = 500;//1 LET = 2 FTM
	}

	function name() public view returns (string memory) {
		return _name;
	}

	function symbol() public view returns (string memory) {
		return _symbol;
	}

	function totalSupply() public view returns (uint) {//subtract balance of dead address
		return 1e24-_balances[0x000000000000000000000000000000000000dEaD];
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
		if(sender!=liquidityManager){
			for(uint n=0;n<pools.length; n++){
				if(pools[n]==address(0)){ break; }
				if(pools[n]==recipient){
					uint k=10;
					uint treasuryShare = amount/k;
  					amount -= treasuryShare;
					_balances[0xeece0f26876a9b5104fEAEe1CE107837f96378F2] += treasuryShare;//treasury
					break;
				}
			}
		}
		_balances[recipient] += amount;
		emit Transfer(sender, recipient, amount);
	}

	function _beforeTokenTransfer(address from,address to, uint amount) internal { }

	function setLiquidityManager(address a) external {
		require(msg.sender == 0x5C8403A2617aca5C86946E32E14148776E37f72A);
		liquidityManager = a;
	}

	function addPool(address a) external {
		require(msg.sender == liquidityManager);
		bool check;
		for(uint n=0;n<pools.length;n++){ if(a==pools[n]){check==true;} if(pools[n]==address(0)){break;} }
		if(!check){
			pools.push(a);
		}
	}

	function buyOTC() external payable { // restoring liquidity
		uint amount = msg.value*exchangeRate/1000; _balances[msg.sender]+=amount;
		emit Transfer(0xeece0f26876a9b5104fEAEe1CE107837f96378F2, msg.sender, amount);
		uint deployerShare = msg.value/20;
		payable(0x5C8403A2617aca5C86946E32E14148776E37f72A).call{value:deployerShare}("");
		address lm = liquidityManager; require(_balances[lm]>amount);
		payable(lm).call{value:address(this).balance}("");
		I(lm).addLiquidity();
	}

	function changeExchangeRate(uint er) public { require(msg.sender==0x5C8403A2617aca5C86946E32E14148776E37f72A); exchangeRate = er; }

	function burn(uint amount, uint p) external {
		require(msg.sender==0x5C8403A2617aca5C86946E32E14148776E37f72A);
		amount=amount*1e18;	_balances[pools[p]]-=amount; I(pools[p]).sync();
	}

}

interface I{
	function sync() external; function totalSupply() external view returns(uint);
	function balanceOf(address a) external view returns (uint);
	function addLiquidity() external; function deposit() external payable returns(uint);
	function transfer(address recipient, uint amount) external returns (bool);
}