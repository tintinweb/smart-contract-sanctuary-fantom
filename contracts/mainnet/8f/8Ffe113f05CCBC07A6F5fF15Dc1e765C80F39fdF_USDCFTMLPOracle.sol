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

/// @title USDCFTMOracleV1
/// @notice Oracle used for getting the price of 1 USDC in FTM using Chainlink
contract USDCFTMLPOracle is AggregatorV3Interface {
    AggregatorV3Interface public constant USDCUSD = AggregatorV3Interface(0x2553f4eeb82d5A26427b8d1106C51499CBa5D99c);
    AggregatorV3Interface public constant FTMUSD = AggregatorV3Interface(0xf4766552D15AE4d256Ad41B6cf2933482B0680dc);

    function decimals() external pure override returns (uint8) {
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
        (, int256 usdcUsdFeed, , , ) = USDCUSD.latestRoundData();
        (, int256 ftmUsdFeed, , , ) = FTMUSD.latestRoundData();

        return (0, (usdcUsdFeed * 1e18) / ftmUsdFeed, 0, 0, 0);
    }
}