/**
 *Submitted for verification at FtmScan.com on 2022-03-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// No BS Here LFG!

contract CryptoCog_Contract {

  string public name = "Crypto Cogs";
  string public symbol = "xCC";

  uint256 public totalSupply = 1000000000000000000000000000;
  uint8 public decimals = 18;  
  
  mapping(address => uint256) public balanceOf;
  mapping(address => mapping (address => uint256)) allowanceOf;
  
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
  event Transfer(address indexed from, address indexed to, uint tokens);

  constructor () {
      balanceOf[msg.sender] = totalSupply;
      emit Transfer(address(0), msg.sender, totalSupply);
  }

  function approve(address tokenManager, uint256 tokenAmount) external returns (bool){

      allowanceOf[msg.sender][tokenManager] = tokenAmount;
      emit Approval (msg.sender, tokenManager, tokenAmount);
      return (true);

  }  
  
  function allowance(address tokenHolder, address tokenManager) external view returns (uint256) {
      return allowanceOf[tokenHolder][tokenManager];
  }

  function transfer(address tokenReceiver, uint256 tokenAmount) external returns (bool){

      require (balanceOf[msg.sender] >= tokenAmount, "Insufficient Balance");
      
      balanceOf[msg.sender] -= tokenAmount;
      balanceOf[tokenReceiver] += tokenAmount;
      
      emit Transfer (msg.sender, tokenReceiver, tokenAmount);
      return (true);

  }  
  
  function transferFrom(address tokenOwner, address tokenReceiver, uint256 tokenAmount) external returns (bool){

      require (tokenAmount <= allowanceOf[tokenOwner][msg.sender], "Insufficient Allowance");
      require (tokenAmount <= balanceOf[tokenOwner], "Insufficient Balance");
      
      balanceOf[tokenOwner] -= tokenAmount;
      balanceOf[tokenReceiver] += tokenAmount;
      
      emit Transfer (tokenOwner, tokenReceiver, tokenAmount);
      return true;
  }  
}