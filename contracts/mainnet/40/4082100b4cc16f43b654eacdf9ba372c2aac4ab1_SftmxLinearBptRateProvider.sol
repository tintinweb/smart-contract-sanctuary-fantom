/**
 *Submitted for verification at FtmScan.com on 2022-10-20
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface IRateProvider {
    function getRate() external view returns (uint256 _rate);
}

interface IFtmStaking {
    function getExchangeRate() external view returns (uint256);
}

contract SftmxLinearBptRateProvider is IRateProvider {
    address public immutable ftmStaking;
    address public immutable linearBpt;

    constructor(address _ftmStaking, address _linearBpt) {
        ftmStaking = _ftmStaking;
        linearBpt = _linearBpt;
    }

    function getRate() external view override returns (uint256 _rate) {
        return IFtmStaking(ftmStaking).getExchangeRate() * IRateProvider(linearBpt).getRate() / 1e18;
    }
}