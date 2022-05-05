/**
 *Submitted for verification at FtmScan.com on 2022-05-05
*/

pragma solidity ^0.6.2;

interface IERC20 {
  function totalSupply() external view returns(uint);
}

contract RewardFormula {
   IERC20 public token;

   constructor(address _token)public {
     token = IERC20(_token);
   }

   // mint 1% from total supply
   function calculateRewards() external view returns(uint){
     return token.totalSupply() / 100;
   }
}