/**
 *Submitted for verification at FtmScan.com on 2022-10-20
*/

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

interface IReaperTokenVault {
    function token() external view returns (address);

    function getPricePerFullShare() external view returns (uint256);
}

contract SFtmxReaperGranaryRateProvider is IRateProvider {
    address public immutable ftmStaking;
    address public immutable reaperVault;

    constructor(address _ftmStaking, address _reaperVault) {
        ftmStaking = _ftmStaking;
        reaperVault = _reaperVault;
    }

    function getRate() external view override returns (uint256 _rate) {
        return IFtmStaking(ftmStaking).getExchangeRate() * IReaperTokenVault(reaperVault).getPricePerFullShare() / 1e18;
    }
}