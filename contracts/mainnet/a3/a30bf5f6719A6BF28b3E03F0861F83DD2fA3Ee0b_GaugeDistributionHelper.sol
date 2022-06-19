/**
 *Submitted for verification at FtmScan.com on 2022-06-19
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File contracts/GaugeDistributionHelper.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IGaugeProxy {
    function distribute() external;
}

contract GaugeDistributionHelper {
  uint256 public lastDistributeTime = 0;
  uint256 public firstTimeDistribute = 0;
  IGaugeProxy public gaugeProxy;

  constructor(
      address _gaugeProxy,
      uint256 _firstTimeDistribute
  ) {
      gaugeProxy = IGaugeProxy(_gaugeProxy);
      firstTimeDistribute = _firstTimeDistribute;
  }

  function callDistribute() external {
    require((block.timestamp - firstTimeDistribute) >= 0, "firstTimeDistribute not elapsed");
    require((block.timestamp - lastDistributeTime) >= 7 days, "weekly timer not elapsed yet");
    gaugeProxy.distribute();
    lastDistributeTime = block.timestamp;
  }
}