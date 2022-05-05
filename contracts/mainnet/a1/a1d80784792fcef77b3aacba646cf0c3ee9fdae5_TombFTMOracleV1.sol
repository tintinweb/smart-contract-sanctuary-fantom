/**
 *Submitted for verification at FtmScan.com on 2022-05-05
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

interface iTombOracle {
    function consult(address _token, uint256 _amountIn) external view returns (uint144 amountOut);
}

/// @title TombFTMOracleV1
/// @author 0xCalibur
/// @notice Oracle used for getting the price of 1 Tomb in FTM
contract TombFTMOracleV1 is AggregatorV3Interface {
    iTombOracle public constant TOMBFTM = iTombOracle(0x55530fA1B042582D5FA3C313a7e02d21Af6B82f4);
    address public constant tomb = 0x6c021Ae822BEa943b2E66552bDe1D2696a53fbB7;

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
        uint256 price = uint256(TOMBFTM.consult(tomb, 1e18));
        return (0, int256(price), 0, 0, 0);
    }
}