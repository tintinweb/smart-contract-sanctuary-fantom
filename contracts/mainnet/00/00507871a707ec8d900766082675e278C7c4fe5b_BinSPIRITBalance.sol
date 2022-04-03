/**
 *Submitted for verification at FtmScan.com on 2022-04-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface BinSPIRITToken {
  function balanceOf(address account) external view returns (uint256);
}

interface BinSPIRITVault {
  function want() external view returns (BinSPIRITToken);
  function balanceOf(address account) external view returns (uint256);
  function getPricePerFullShare() external view returns (uint256);
}

interface MoonpotGate {
  function userTotalBalance(address user) external view returns (uint256);
}

contract BinSPIRITBalance {

  BinSPIRITToken public binSPIRIT;
  BinSPIRITVault public vault;
  MoonpotGate public gate;

  constructor(BinSPIRITVault _vault, MoonpotGate _gate) {
    binSPIRIT = _vault.want();
    vault = _vault;
    gate = _gate;
  }

  function balanceOf(address account) external view returns (uint256) {
    uint ppfs = vault.getPricePerFullShare();
    return binSPIRIT.balanceOf(account) + vault.balanceOf(account) * ppfs / 1e18 + gate.userTotalBalance(account);
  }

}