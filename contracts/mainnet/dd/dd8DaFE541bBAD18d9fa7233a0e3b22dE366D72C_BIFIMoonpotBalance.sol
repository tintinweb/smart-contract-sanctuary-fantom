/**
 *Submitted for verification at FtmScan.com on 2022-04-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;



interface MoonpotGate {
  function userTotalBalance(address user) external view returns (uint256);
}

contract BIFIMoonpotBalance {

  MoonpotGate public gate;

  constructor(MoonpotGate _gate) {
    gate = _gate;
  }

  function balanceOf(address account) external view returns (uint256) {
    return gate.userTotalBalance(account);
  }

}