/**
 *Submitted for verification at FtmScan.com on 2022-09-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IPool {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

interface IVoterProxy {
    function bribeSupplyLag(address, address) external view returns (uint256);
}

interface ISolidlyLens {
    function bribeAddresByPoolAddress(address) external view returns (address);

    function gaugeAddressByPoolAddress(address) external view returns (address);
}

interface IGauge {
    function batchRewardPerToken(address, uint256) external;

    function lastUpdateTime(address) external view returns (uint256);

    function getPriorSupplyIndex(uint256) external view returns (uint256);
}

interface IBribe {
    function batchRewardPerToken(address, uint256) external;

    function lastUpdateTime(address) external view returns (uint256);

    function getPriorSupplyIndex(uint256) external view returns (uint256);
}

contract SolidlyFixoor {
    address owner;
    IVoterProxy constant voterProxy =
        IVoterProxy(0xDA0027f2368bA3cb65a494B1fc7EA7Fd05AB42DD);
    ISolidlyLens constant solidlyLens =
        ISolidlyLens(0xDA0024F99A9889E8F48930614c27Ba41DD447c45);
    address constant solidAddress = 0x888EF71766ca594DED1F0FA3AE64eD2941740A20;
    uint256 defaultGaugeRuns = 50;
    uint256 defaultBribeRuns = 100;

    constructor() {
        owner = msg.sender;
    }

    // Bribe fixing

    function fixBribeByPool(address poolAddress) external {
        fixBribeByPool(poolAddress, defaultBribeRuns);
    }

    function fixBribeByPool(address poolAddress, uint256 runs) public {
        address bribeAddress = solidlyLens.bribeAddresByPoolAddress(
            poolAddress
        );
        IBribe bribe = IBribe(bribeAddress);
        IPool pool = IPool(poolAddress);
        address token0 = pool.token0();
        address token1 = pool.token1();
        uint256 startTimestamp0 = bribe.lastUpdateTime(token0);
        uint256 startTimestamp1 = bribe.lastUpdateTime(token1);
        uint256 _runs0 = bribe.getPriorSupplyIndex(startTimestamp0) + runs;
        uint256 _runs1 = bribe.getPriorSupplyIndex(startTimestamp1) + runs;
        bribe.batchRewardPerToken(token0, _runs0);
        bribe.batchRewardPerToken(token1, _runs1);
    }

    // Gauge fixing

    function fixGaugeByPool(address poolAddress) external {
        fixGaugeByPool(poolAddress, defaultBribeRuns);
    }

    function fixGaugeByPool(address poolAddress, uint256 runs) public {
        address gaugeAddress = solidlyLens.gaugeAddressByPoolAddress(
            poolAddress
        );
        IGauge gauge = IGauge(gaugeAddress);
        uint256 startTimestamp = gauge.lastUpdateTime(solidAddress);
        uint256 _runs = gauge.getPriorSupplyIndex(startTimestamp) + runs;
        gauge.batchRewardPerToken(solidAddress, _runs);
    }

    // View methods

    function bribeLagsByPoolAddress(address poolAddress)
        public
        view
        returns (uint256[] memory)
    {
        address[] memory tokensAddresses = new address[](2);
        IPool pool = IPool(poolAddress);
        tokensAddresses[0] = pool.token0();
        tokensAddresses[1] = pool.token1();
        return bribeLagsByPoolAddressAndTokens(poolAddress, tokensAddresses);
    }

    function bribeLagsByPoolAddressAndTokens(
        address poolAddress,
        address[] memory tokensAddresses
    ) public view returns (uint256[] memory) {
        address bribeAddress = solidlyLens.bribeAddresByPoolAddress(
            poolAddress
        );
        uint256[] memory _lags = new uint256[](tokensAddresses.length);
        for (uint256 tokenIdx; tokenIdx < tokensAddresses.length; tokenIdx++) {
            address tokenAddress = tokensAddresses[tokenIdx];
            uint256 lag = voterProxy.bribeSupplyLag(bribeAddress, tokenAddress);
            _lags[tokenIdx] = lag;
        }
        return _lags;
    }

    function gaugeLagByPoolAddress(address poolAddress)
        public
        view
        returns (uint256 lag)
    {
        address gaugeAddress = solidlyLens.gaugeAddressByPoolAddress(
            poolAddress
        );
        lag = voterProxy.bribeSupplyLag(gaugeAddress, solidAddress);
    }

    // Management

    function setOwner(address _owner) external {
        require(msg.sender == owner);
        owner = _owner;
    }

    function setDefaultGaugeRuns(uint256 _defaultGaugeRuns) external {
        require(msg.sender == owner);
        defaultGaugeRuns = _defaultGaugeRuns;
    }

    function setDefaultBribeRuns(uint256 _defaultBribeRuns) external {
        require(msg.sender == owner);
        defaultBribeRuns = _defaultBribeRuns;
    }
}