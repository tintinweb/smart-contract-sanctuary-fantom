pragma solidity 0.6.12;

import "./StrategyRedemption.sol";
pragma experimental ABIEncoderV2;

contract StrategyRedemption_Spooky is StrategyRedemption {

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
        token0Address = _tokenAddresses[4];
        token1Address = _tokenAddresses[5];

        pid = _pid;
        isSingleVault = _isSingleVault;
        isAutoComp = true;

        depositFeeFactor = 10000;
        withdrawFeeFactor = _withdrawFeeFactor;
        entranceFeeFactor = 10000;

        transferOwnership(nativeFarmAddress);
    }

    function convertDustToEarned() public override virtual whenNotPaused {}
}