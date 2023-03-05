/**
 *Submitted for verification at FtmScan.com on 2023-03-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Source: https://github.com/smartcontractkit/chainlink/blob/master/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestAnswer() external view returns(int256);
}

contract FTMPriceOracle {
    AggregatorV3Interface internal priceFeed;

    constructor() {
        priceFeed = AggregatorV3Interface(
            0xf4766552D15AE4d256Ad41B6cf2933482B0680dc // Fantom network Chainlink FTM/USD price feed
        );
    }

    function getEthPrice() external view returns (uint256, uint256) {
        uint256 _price = uint256(priceFeed.latestAnswer());
        uint256 _decimals = uint256(priceFeed.decimals());
        return (_price, _decimals);
    }
}