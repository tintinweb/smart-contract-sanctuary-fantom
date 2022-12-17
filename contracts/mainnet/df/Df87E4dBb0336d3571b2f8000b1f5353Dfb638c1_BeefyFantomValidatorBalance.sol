/**
 *Submitted for verification at FtmScan.com on 2022-12-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IbeFTM {
  function totalSupply() external view returns (uint256);
  function balanceOfLocked() external view returns (uint256);
}

interface IStakingContract {
    function pendingRewards(address delegator, uint256 validatorID) external view returns (uint256);
    function getSelfStake(uint256 validatorID) external view returns (uint256);
}

contract BeefyFantomValidatorBalance {

  IStakingContract stakingContract = IStakingContract(0xFC00FACE00000000000000000000000000000000);
  IbeFTM beFTM = IbeFTM(0x7381eD41F6dE418DdE5e84B55590422a57917886);
  uint256 validatorID = 92;

  function balance() external view returns (uint256) {
    return stakingContract.pendingRewards(0xE97A5292248c2647466222Dc58563046b3E34b18, 92) 
        + stakingContract.getSelfStake(92) - (beFTM.totalSupply() - beFTM.balanceOfLocked());
  }
}