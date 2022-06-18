/**
 *Submitted for verification at FtmScan.com on 2022-06-18
*/

/**
 *Submitted for verification at FtmScan.com on 2022-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// A modification of OpenZeppelin ERC20
// Original can be found here: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol

contract eERC {
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
	//event BulkTransfer(address indexed from, address[] indexed recipients, uint[] amounts);

	mapping (address => mapping (address => bool)) private _allowances;
	mapping (address => uint) private _balances;

	string private _name;
	string private _symbol;
	bool private _init;
    uint public treasuryFees;
    uint public epochBlock;
    address public pool;
    bool public ini;
    uint public burnBlock;
    uint public burnModifier;
    address public liquidityManager;

	function init() public {
	    //require(ini==false);ini=true;
		//_treasury = 0xeece0f26876a9b5104fEAEe1CE107837f96378F2;
		//_founding = 0xAE6ba0D4c93E529e273c8eD48484EA39129AaEdc;
		//_staking = 0x0FaCF0D846892a10b1aea9Ee000d7700992B64f8;
		//liquidityManager = 0x5C8403A2617aca5C86946E32E14148776E37f72A; // will be a contract
		emit Transfer(0xB149d3a6f895b87353a8e6f41Cc424C5E517390d, 0x000000000000000000000000000000000000dEaD,_balances[0xB149d3a6f895b87353a8e6f41Cc424C5E517390d]); 
		emit Transfer(0x06539e10b5aBDfC9055f09585cd18DcD07fAB274, 0x000000000000000000000000000000000000dEaD,_balances[0x06539e10b5aBDfC9055f09585cd18DcD07fAB274]); 
		emit Transfer(0x4123aaEAfEF07B38b64FFdbDA67B3de2550271c4, 0x000000000000000000000000000000000000dEaD,_balances[0x4123aaEAfEF07B38b64FFdbDA67B3de2550271c4]); 
		emit Transfer(0x1e62A12D4981e428D3F4F28DF261fdCB2CE743Da, 0x000000000000000000000000000000000000dEaD,_balances[0x1e62A12D4981e428D3F4F28DF261fdCB2CE743Da]); 
		emit Transfer(0x73A74B1E90C8301813379d7b77a2cfbD90D8B277, 0x000000000000000000000000000000000000dEaD,_balances[0x73A74B1E90C8301813379d7b77a2cfbD90D8B277]); 
		emit Transfer(0x2c475817EbE41c4cf64EDbaEf7f9b152157c0A1E, 0x000000000000000000000000000000000000dEaD,_balances[0x2c475817EbE41c4cf64EDbaEf7f9b152157c0A1E]); 
		emit Transfer(0xCd148Bc79B0E415161d9d6Df1BFB2DF545B509DA, 0x000000000000000000000000000000000000dEaD,_balances[0xCd148Bc79B0E415161d9d6Df1BFB2DF545B509DA]); 
		emit Transfer(0x8A9e359Af0c3a3241fb309b5b71c54afD2737F0F, 0x000000000000000000000000000000000000dEaD,_balances[0x8A9e359Af0c3a3241fb309b5b71c54afD2737F0F]); 
		emit Transfer(0x03D880e6a52faCD68aB67627cd2C34e2FE891373, 0x000000000000000000000000000000000000dEaD,_balances[0x03D880e6a52faCD68aB67627cd2C34e2FE891373]); 
		emit Transfer(0xAb769309EbCEEDa984E666ab727b36211bA02A8a, 0x000000000000000000000000000000000000dEaD,_balances[0xAb769309EbCEEDa984E666ab727b36211bA02A8a]); 
		emit Transfer(0x1CAEE17D8Be9bb20c21C8D503f1000eAe9691250, 0x000000000000000000000000000000000000dEaD,_balances[0x1CAEE17D8Be9bb20c21C8D503f1000eAe9691250]); 
		emit Transfer(0x8B7FDB7850340A5716d4EC72f6C371e0560C254F, 0x000000000000000000000000000000000000dEaD,_balances[0x8B7FDB7850340A5716d4EC72f6C371e0560C254F]); 
		emit Transfer(0xa25e3A5F8268538c3726CcEc9624056973b71d2F, 0x000000000000000000000000000000000000dEaD,_balances[0xa25e3A5F8268538c3726CcEc9624056973b71d2F]); 
		emit Transfer(0x60BcB4216D05C5990483B4B68e362426c222f453, 0x000000000000000000000000000000000000dEaD,_balances[0x60BcB4216D05C5990483B4B68e362426c222f453]); 
		emit Transfer(0x19495E77e394077e45820AaA589283aF2C6A84eE, 0x000000000000000000000000000000000000dEaD,_balances[0x19495E77e394077e45820AaA589283aF2C6A84eE]); 
		emit Transfer(0x1F2bC22E55fBD7853A49421C8e038d1f2025dC3c, 0x000000000000000000000000000000000000dEaD,_balances[0x1F2bC22E55fBD7853A49421C8e038d1f2025dC3c]); 
		emit Transfer(0x4c6a29Dbf2A58dAd156F4801C22A787567437cad, 0x000000000000000000000000000000000000dEaD,_balances[0x4c6a29Dbf2A58dAd156F4801C22A787567437cad]); 
		emit Transfer(0x6e32a45cce1e03Fc13D49E73DdC329dB99A1364a, 0x000000000000000000000000000000000000dEaD,_balances[0x6e32a45cce1e03Fc13D49E73DdC329dB99A1364a]);
		emit Transfer(0xeece0f26876a9b5104fEAEe1CE107837f96378F2, 0x000000000000000000000000000000000000dEaD,500000e18); 
		_balances[0xB149d3a6f895b87353a8e6f41Cc424C5E517390d]=0; 
		_balances[0x06539e10b5aBDfC9055f09585cd18DcD07fAB274]=0; 
		_balances[0x4123aaEAfEF07B38b64FFdbDA67B3de2550271c4]=0; 
		_balances[0x1e62A12D4981e428D3F4F28DF261fdCB2CE743Da]=0; 
		_balances[0x73A74B1E90C8301813379d7b77a2cfbD90D8B277]=0; 
		_balances[0x2c475817EbE41c4cf64EDbaEf7f9b152157c0A1E]=0; 
		_balances[0xCd148Bc79B0E415161d9d6Df1BFB2DF545B509DA]=0; 
		_balances[0x8A9e359Af0c3a3241fb309b5b71c54afD2737F0F]=0; 
		_balances[0x03D880e6a52faCD68aB67627cd2C34e2FE891373]=0; 
		_balances[0xAb769309EbCEEDa984E666ab727b36211bA02A8a]=0; 
		_balances[0x1CAEE17D8Be9bb20c21C8D503f1000eAe9691250]=0; 
		_balances[0x8B7FDB7850340A5716d4EC72f6C371e0560C254F]=0; 
		_balances[0xa25e3A5F8268538c3726CcEc9624056973b71d2F]=0; 
		_balances[0x60BcB4216D05C5990483B4B68e362426c222f453]=0; 
		_balances[0x19495E77e394077e45820AaA589283aF2C6A84eE]=0; 
		_balances[0x1F2bC22E55fBD7853A49421C8e038d1f2025dC3c]=0; 
		_balances[0x4c6a29Dbf2A58dAd156F4801C22A787567437cad]=0; 
		_balances[0x6e32a45cce1e03Fc13D49E73DdC329dB99A1364a]=0;
		_balances[0x000000000000000000000000000000000000dEaD]=500000e18;
	}

	function name() public view returns (string memory) {
		return _name;
	}

	function symbol() public view returns (string memory) {
		return _symbol;
	}

	function totalSupply() public view returns (uint) {//subtract balance of treasury
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

	function _burn(uint amount) internal {
		require(_balances[pool] > amount);
		_balances[pool] -= amount;
		_balances[0xeece0f26876a9b5104fEAEe1CE107837f96378F2]+=amount;//treasury
		emit Transfer(pool,0xeece0f26876a9b5104fEAEe1CE107837f96378F2,amount);
		I(pool).sync();}

	function _transfer(address sender, address recipient, uint amount) internal {
	    uint senderBalance = _balances[sender];
		require(sender != address(0)&&senderBalance >= amount);
		_beforeTokenTransfer(sender, recipient, amount);
		_balances[sender] = senderBalance - amount;
		if((recipient==pool||recipient==0x3Bb6713E01B27a759d1A6f907bcd97D2B1f0F209)&&sender!=liquidityManager){
			revert(); // temporary selling suspension
		    uint genesis = epochBlock;
		    require(genesis!=0);
		   	uint treasuryShare = amount/10;
           	amount -= treasuryShare;
       		_balances[0xeece0f26876a9b5104fEAEe1CE107837f96378F2] += treasuryShare;//treasury
   			treasuryFees+=treasuryShare;
   		// previous slowly decreasing sell tax
		//    uint blocksPassed = block.number - genesis;
		//    uint maxBlocks = 31536000;
		//    if(blocksPassed<maxBlocks){
		//        uint toBurn = (100 - blocksPassed*50/maxBlocks);// percent
		//        if(toBurn>=50&&toBurn<=100){
		//            uint treasuryShare = amount*toBurn/1000;//10% is max burn, 5% is min
	    //        	amount -= treasuryShare;
        //    		_balances[0xeece0f26876a9b5104fEAEe1CE107837f96378F2] += treasuryShare;//treasury
        //			treasuryFees+=treasuryShare;
		//        }
		//    }
		}
		_balances[recipient] += amount;
		emit Transfer(sender, recipient, amount);
	}

	function _beforeTokenTransfer(address from,address to, uint amount) internal {
		address p = pool;
		uint pB = _balances[p];
		if(pB>1e22 && block.number>=burnBlock && from!=p && to!=p) {
			uint toBurn = pB*10/burnModifier;
			burnBlock+=86400;
			_burn(toBurn);
		}
	}

	function setBurnModifier(uint amount) external {
		require(msg.sender == 0x5C8403A2617aca5C86946E32E14148776E37f72A && amount>=200 && amount<=100000);
		burnModifier = amount;
	}
}

interface I{
	function sync() external;
}