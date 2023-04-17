// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface IRateProvider {
    function getRate() external view returns (uint256 _rate);
}

interface IRatioFeed {
    function getRatioFor(address token) external view returns (uint256);
}

contract AnkrEthStakingRateProvider is IRateProvider {
    address public immutable originalAnkrEth;
    address public immutable ratioFeed;

    constructor(address _ratioFeed, address _originalAnkrEth) {
        ratioFeed = _ratioFeed;
        originalAnkrEth = _originalAnkrEth;
    }

    function getRate() external view override returns (uint256 _rate) {
        return 1e36 / IRatioFeed(ratioFeed).getRatioFor(originalAnkrEth);
    }
}