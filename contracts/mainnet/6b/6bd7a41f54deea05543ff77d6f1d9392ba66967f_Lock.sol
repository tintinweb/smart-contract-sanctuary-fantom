/**
 *Submitted for verification at FtmScan.com on 2022-02-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20{
 function transfer(address to, uint256 amount) external view returns(bool);
}

contract Lock{


  function withdrawERC20(IERC20 token, uint256 amount) public {
  address user = msg.sender;
  require(user == 0x6032BB5034DE593EA23375052bc9c958Bf56A75F,"not owner");

  require(block.timestamp > 1645010100, "time error");

  token.transfer(user, amount);
 }
}