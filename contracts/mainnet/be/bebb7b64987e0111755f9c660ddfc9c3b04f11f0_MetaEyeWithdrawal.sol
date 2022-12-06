/**
 *Submitted for verification at FtmScan.com on 2022-12-06
*/

// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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






contract MetaEyeWithdrawal {
    using SafeMath for uint256; 
    IERC20 public Token;
    address public owner;

    bool private _paused;

    constructor ()
    {
        Token = IERC20(0x3247169137F7B7322D66DCF4D7Ee7BDC096904A9);
        owner = msg.sender;
    }

     modifier onlyOwner() {
        require(msg.sender==owner, "Only Call by Owner");
        _;
    }


    function paused() public view virtual returns (bool){
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        
    }

    function pauseContract() public onlyOwner{
        _pause();

    }
    function unpauseContract() public onlyOwner{
        _unpause();

    }
     
    function register(address _address)public pure returns(address){
        return _address;
    }
    
    
    function multisendToken(uint256 amount,  address[] calldata _contributors, uint256[] calldata __balances) external whenNotPaused
        {

            uint8 i = 0;
            uint256 total = amount;

            Token.transferFrom(msg.sender,address(this),amount);

            for (i; i < _contributors.length; i++) 
            {
              require(  total >= __balances[i]  , "add fund");
              Token.transfer(_contributors[i], __balances[i]);
              total = total.sub(__balances[i]);
            }
        }
    
    
  
    function sendMultiBnb(address payable[]  memory  _contributors, uint256[] memory __balances) public  payable whenNotPaused
    {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= __balances[i],"Invalid Amount");
            total = total - __balances[i];
            _contributors[i].transfer(__balances[i]);
        }
    }


    function buy() external payable whenNotPaused{
        require(msg.value>0,"Select amount first");
    }
    


    function sell (uint256 _token) external payable whenNotPaused{
        Token.transferFrom(msg.sender,address(this),_token);
    }
    
    
    
    function ClaimBNB (uint256 _amount) onlyOwner public whenNotPaused{
        payable(msg.sender).transfer(_amount);
    }

    
    function claimToken (uint256 _amount) onlyOwner public whenNotPaused{
        Token.transfer(msg.sender,_amount);
    }

}