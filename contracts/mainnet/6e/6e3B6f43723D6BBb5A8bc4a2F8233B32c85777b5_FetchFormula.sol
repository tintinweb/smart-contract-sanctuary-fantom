/**
 *Submitted for verification at FtmScan.com on 2022-08-04
*/

pragma solidity ^0.8.11;

contract FetchFormula {
  function bonusPercent(uint _lockTime) external view returns(uint){
    if(_lockTime >= 7 days && _lockTime < 14 days){
      return 1;
    }
    else if(_lockTime >= 14 days && _lockTime < 30 days){
      return 2;
    }
    else if(_lockTime >= 30 days && _lockTime < 90 days){
      return 5;
    }
    else if(_lockTime >= 90 days && _lockTime < 180 days){
      return 20;
    }
    else if(_lockTime >= 180 days && _lockTime < 365 days){
      return 60;
    }
    else if(_lockTime >= 365 days && _lockTime < 730 days){
      return 140;
    }
    else if(_lockTime >= 730 days && _lockTime < 1460 days){
      return 300;
    }
    else if(_lockTime >= 1460 days){
      return 800;
    }
    else{
      return 0;
    }
  }
}