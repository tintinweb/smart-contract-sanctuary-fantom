/**
 *Submitted for verification at FtmScan.com on 2022-01-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

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
}

/// @title UsdcFtmOracleV1
/// @author 0xCalibur
/// @notice Oracle used for getting the price of 1 USDC in FTM using Chainlink
contract UsdcFtmOracleV1 is AggregatorV3Interface {
    AggregatorV3Interface public constant USDCUSD = AggregatorV3Interface(0x2553f4eeb82d5A26427b8d1106C51499CBa5D99c);
    AggregatorV3Interface public constant FTMUSD = AggregatorV3Interface(0xf4766552D15AE4d256Ad41B6cf2933482B0680dc);
    
    function decimals() external override pure returns (uint8) {
        return 18;
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        (,int256 USDCUSDFeed,,,) = USDCUSD.latestRoundData();
        (,int256 FTMUSDFeed,,,) = FTMUSD.latestRoundData();

        return (0, (USDCUSDFeed * 1e18) / FTMUSDFeed, 0, 0, 0);
    }
}