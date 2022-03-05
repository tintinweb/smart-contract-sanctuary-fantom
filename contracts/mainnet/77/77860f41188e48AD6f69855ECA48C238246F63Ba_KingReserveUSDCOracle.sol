// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOracle {
    function decimals() external pure returns (uint8);

    function latestAnswer() external pure returns (uint256);
}

contract KingReserveUSDCOracle {
    IOracle public immutable oracle;

    constructor(address _oracle) {
        oracle = IOracle(_oracle);
    }

    /// @notice Exchange rate of `amount` of FUSD to the underlying asset
    function getExchangeRate(uint256 amount) external view returns (uint256 result) {
        uint256 decimals = oracle.decimals();
        uint256 latestAnswer = oracle.latestAnswer();

        uint256 exchanged = latestAnswer - (latestAnswer * 10) / 100;

        // FUSD has 18 decimals
        if (decimals != 18) {
            exchanged = exchanged * 10**(18 - decimals);
        }

        result = ((((latestAnswer * exchanged) * amount) / (1e18 * (10**(decimals))))) / 1e12;

        require(result > 0, 'Oracle: invalid amount');
    }
}