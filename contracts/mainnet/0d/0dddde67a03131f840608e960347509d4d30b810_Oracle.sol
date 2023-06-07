// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import {IERC20} from "../../src/interfaces/IERC20.sol";

interface IChainklinkAggregator {
    function latestAnswer() external view returns (uint256);
}

/// @title Sample Chainlink Oracle
/// @dev Not to be used in production
contract Oracle {
    address public usdc = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    address public dai = 0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E;
    address public usdcOracle = 0x2553f4eeb82d5A26427b8d1106C51499CBa5D99c; // Chainlink decimals is 8 --in practice need to account for decimals difference
    address public daiOracle = 0x91d5DEFAFfE2854C7D02F50c80FA1fdc8A721e52; // Chainlink decimals is 8 --in practice need to account for decimals difference
    mapping(address => address) public chainlinkOracleByToken;

    constructor() {
        chainlinkOracleByToken[usdc] = usdcOracle;
        chainlinkOracleByToken[dai] = daiOracle;
    }

    function getChainlinkPrice(
        address token
    ) public view returns (uint256 price) {
        price = IChainklinkAggregator(chainlinkOracleByToken[token])
            .latestAnswer();
    }

    function calculateEquivalentAmountAfterSlippage(
        address _fromToken,
        address _toToken,
        uint256 _amountIn,
        uint256 _slippageBips
    ) external view returns (uint256 amountOut) {
        uint256 fromTokenPrice = getChainlinkPrice(_fromToken);
        uint256 toTokenPrice = getChainlinkPrice(_toToken);
        uint256 fromTokenDecimals = IERC20(_fromToken).decimals();
        uint256 toTokenDecimals = IERC20(_toToken).decimals();
        uint256 priceRatio = (10 ** toTokenDecimals * fromTokenPrice) /
            toTokenPrice;
        uint256 decimalsAdjustment;
        if (fromTokenDecimals >= toTokenDecimals) {
            decimalsAdjustment = fromTokenDecimals - toTokenDecimals;
        } else {
            decimalsAdjustment = toTokenDecimals - fromTokenDecimals;
        }
        if (decimalsAdjustment > 0) {
            amountOut =
                (_amountIn * priceRatio * (10 ** decimalsAdjustment)) /
                10 ** (decimalsAdjustment + fromTokenDecimals);
        } else {
            amountOut = (_amountIn * priceRatio) / 10 ** toTokenDecimals;
        }
        amountOut = ((10000 - _slippageBips) * amountOut) / 10000;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external;

    function approve(address, uint256) external;

    function transferFrom(address from, address to, uint256 amount) external;

    function decimals() external view returns (uint256);
}