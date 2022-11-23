/**
 *Submitted for verification at FtmScan.com on 2022-11-23
*/

pragma solidity 0.7.6;
contract testContract 
{ 
     function calcalkey(address ad, uint256 epoch) public view returns (uint256) {
          return uint256(uint160(ad)) * (epoch**2);
     }
}