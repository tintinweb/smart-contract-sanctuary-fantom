/**
 *Submitted for verification at FtmScan.com on 2022-11-26
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

contract Hello {
  uint256 a;

  function setA(uint256 _a) external {
      a = _a; 
  }

  function getA() external view returns (uint256) {
      return a; 
  }
}