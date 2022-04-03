/**
 *Submitted for verification at FtmScan.com on 2022-04-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface Token {
  function balanceOf(address account) external view returns (uint256);
}

interface LP {
  function balanceOf(address account) external view returns (uint256);
  function totalSupply() external view returns (uint256);
}

interface LPVault {
  function want() external view returns (LP);
  function balanceOf(address account) external view returns (uint256);
  function getPricePerFullShare() external view returns (uint256);
  function totalSupply() external view returns (uint256);
}


contract BinSPIRITLPBalance {

  Token public binSPIRIT;
  LPVault public vault;

  constructor(Token _binSPIRIT, LPVault _vault) {
    binSPIRIT = _binSPIRIT;
    vault = _vault;
  }

  function lpToBinSpiritRatio() internal view returns (uint256) {
    LP lp = vault.want();
    uint256 lpTotalSupply = lp.totalSupply();
    uint256 lpBinSpiritBalance = binSPIRIT.balanceOf(address(lp));
    return lpBinSpiritBalance * 1e18 / lpTotalSupply;
  }

  function balanceOf(address account) external view returns (uint256) {
    uint256 ratio = lpToBinSpiritRatio();
    uint256 ppfs = vault.getPricePerFullShare();
    uint256 amountOfLp = vault.balanceOf(account) * ppfs / 1e18 + vault.want().balanceOf(account);
    return amountOfLp * ratio / 1e18;
  }

}