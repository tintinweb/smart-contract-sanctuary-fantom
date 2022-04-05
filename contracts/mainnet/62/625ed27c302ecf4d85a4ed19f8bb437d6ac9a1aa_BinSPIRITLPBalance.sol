/**
 *Submitted for verification at FtmScan.com on 2022-04-04
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

interface Vault {
  function want() external view returns (LP);
  function balanceOf(address account) external view returns (uint256);
  function getPricePerFullShare() external view returns (uint256);
  function totalSupply() external view returns (uint256);
}


contract BinSPIRITLPBalance {

  Token public binSPIRIT;
  Token public marketMooBinSPIRITSPIRIT;
  Token public marketMooBinSpirit;
  Vault public binSPIRITSPIRITVault;

  Vault public binSPIRITVault;

  constructor(Token _binSPIRIT, Token _marketMooBinSPIRITSPIRIT, Token _marketMooBinSpirit,Vault _binSPIRITSPIRITVault, Vault _binSPIRITVault) {
    binSPIRIT = _binSPIRIT;
    marketMooBinSPIRITSPIRIT = _marketMooBinSPIRITSPIRIT;
    marketMooBinSpirit = _marketMooBinSpirit;
    binSPIRITSPIRITVault = _binSPIRITSPIRITVault;
    binSPIRITVault = _binSPIRITVault;
  }

  function lpToBinSpiritRatio() internal view returns (uint256) {
    LP lp = binSPIRITSPIRITVault.want();
    uint256 lpTotalSupply = lp.totalSupply();
    uint256 lpBinSpiritBalance = binSPIRIT.balanceOf(address(lp));
    return lpBinSpiritBalance * 1e18 / lpTotalSupply;
  }

  function balanceInSingleStakeMarket(address account) internal view returns (uint256) {
    uint256 mooBinSpiritMarketBalance = marketMooBinSpirit.balanceOf(account);
    uint256 ppfs = binSPIRITVault.getPricePerFullShare();
    return mooBinSpiritMarketBalance * ppfs /1e18;
  }

  function balanceInLpStakeMarket(address account) internal view returns (uint256) {
    uint256 mooBinSpiritSpiritMarketBalance = marketMooBinSPIRITSPIRIT.balanceOf(account);
    uint256 ratio = lpToBinSpiritRatio();
    uint256 ppfs = binSPIRITSPIRITVault.getPricePerFullShare();

    return (mooBinSpiritSpiritMarketBalance * ppfs / 1e18) * ratio / 1e18;

  }

  function balanceOf(address account) external view returns (uint256) {
    return balanceInSingleStakeMarket(account) + balanceInLpStakeMarket(account);
  }

}