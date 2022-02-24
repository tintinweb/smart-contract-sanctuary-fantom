/**
 *Submitted for verification at FtmScan.com on 2022-02-24
*/

// Sources flattened with hardhat v2.6.7 https://hardhat.org

// File contracts/KingReserveStableOracle.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOracle {
    function decimals() external pure returns (uint8);

    function latestAnswer() external pure returns (uint256);
}

contract KingReserveStableOracle {
    IOracle immutable oracle;

    constructor(address _oracle) {
        oracle = IOracle(_oracle);
    }

    /// @notice Exchange rate of `amount` of FUSD to the underlying asset
    function getExchangeRate(uint256 amount) external view returns (uint256) {
        uint256 decimals = oracle.decimals();
        uint256 latestAnswer = oracle.latestAnswer();

        uint256 exchanged = latestAnswer - (latestAnswer * 10) / 100;

        // FUSD has 18 decimals
        if (decimals != 18) {
            exchanged = exchanged * 10**(18 - decimals);
        }

        return (latestAnswer * exchanged) / 10e18;
    }
}