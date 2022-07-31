pragma solidity 0.6.6;

import "../interfaces/ITwapUniOracle.sol";
import "../interfaces/IChainlink.sol";

contract MixerUniOracle {
    address public deusFtm;
    address public ftmChainlink;
    address public deus;

    constructor(
        address deus_,
        address deusFtm_,
        address ftmChainlink_
    ) public {
        deus = deus_;
        deusFtm = deusFtm_;
        ftmChainlink = ftmChainlink_;
    }

    function consult() external view returns (uint256 amountOut) {
        uint256 deusPerFtm = ITwapUniOracle(deusFtm).consult(deus, 1e18);
        int256 ftmPrice = (IChainlink(ftmChainlink).latestAnswer() * 1e6) /
            IChainlink(ftmChainlink).decimals();
        amountOut = (deusPerFtm * uint256(ftmPrice)) / 1e18;
    }
}

interface ITwapUniOracle {
    function consult(address token, uint256 amountIn)
        external
        view
        returns (uint256 amountOut);
}

interface IChainlink {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (int256);
}