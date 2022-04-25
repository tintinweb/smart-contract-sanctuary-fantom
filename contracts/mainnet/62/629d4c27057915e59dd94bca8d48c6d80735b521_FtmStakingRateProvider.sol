/**
 *Submitted for verification at FtmScan.com on 2022-04-23
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface IRateProvider {
    function getRate() external view returns (uint256 _rate);
}

interface IFtmStaking {
    function getExchangeRate() external view returns (uint256);
}

contract FtmStakingRateProvider is IRateProvider {
    address public immutable ftmStaking;

    constructor(address _ftmStaking) {
        ftmStaking = _ftmStaking;
    }

    function getRate() external view override returns (uint256 _rate) {
        return IFtmStaking(ftmStaking).getExchangeRate();
    }
}