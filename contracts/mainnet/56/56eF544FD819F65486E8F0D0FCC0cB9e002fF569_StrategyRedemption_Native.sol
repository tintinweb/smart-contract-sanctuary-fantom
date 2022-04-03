// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./StrategyRedemption.sol";

contract StrategyRedemption_Native is StrategyRedemption {
    address public earned0Address;
    address[] public earned0ToEarnedPath;

    constructor(
        address[] memory _addresses,
        address[] memory _tokenAddresses,
        bool _isSingleVault,
        uint256 _pid,
        uint256 _withdrawFeeFactor
    ) public {
        nativeFarmAddress = _addresses[0];
        farmContractAddress = _addresses[1];
        govAddress = _addresses[2];
        uniRouterAddress = _addresses[3];
        buybackRouterAddress = _addresses[4];

        NATIVEAddress = _tokenAddresses[0];
        wftmAddress = _tokenAddresses[1];
        wantAddress = _tokenAddresses[2];
        earnedAddress = _tokenAddresses[3];
        earned0Address = _tokenAddresses[4];
        token0Address = _tokenAddresses[5];
        token1Address = _tokenAddresses[6];

        pid = _pid;
        isSingleVault = _isSingleVault;
        isAutoComp = false;

        depositFeeFactor = 10000;
        withdrawFeeFactor = _withdrawFeeFactor;
        entranceFeeFactor = 10000;

        transferOwnership(nativeFarmAddress);
    }

    // not used
    function _farm() internal override {}
    // not used
    function _unfarm(uint256 _wantAmt) internal override {}
    // not used
    function _harvest() internal override {}
    // not used
    function earn() public override {}
    // not used
    function buyBack(uint256 _earnedAmt) internal override returns (uint256) {}
    // not used
    function distributeFees(uint256 _earnedAmt) internal override returns (uint256) {}
    // not used
    function convertDustToEarned() public override {}
}