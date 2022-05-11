pragma solidity 0.8.7;

// SPDX-License-Identifier: MIT

import "./IGainBaseFTM.sol";

interface IyVault {
    function pricePerShare() external view returns (uint256);
}

contract IGainYearnIRS is IGainBase {

    IyVault public vault; // yVault

    uint256 public initialRate;
    uint256 public endRate;
    uint256 public leverage; // in 1e18

    function init(address _baseToken, address _vault, address _treasury, string calldata _batchName, uint256 _leverage, uint256 _duration, uint256 _a, uint256 _b) public {
        _init(_baseToken, _treasury, _batchName, _duration, _a, _b);
        vault = IyVault(_vault);
        leverage = _leverage;
        initialRate = vault.pricePerShare();
        require(initialRate > 0, "initialRate = 0");
    }

    // 1 - swap fee (numerator, in 1e18 format)
    function fee() public override view returns (uint256) {
        uint256 time = _blockTimestamp();
        uint256 _fee;
        if(time < closeTime) {
            _fee = maxFee - (
                (time - openTime) * (maxFee - minFee) / (closeTime - openTime)
            );
        }
        else {
            _fee = minFee;
        }
        return 1e18 - _fee;
    }

    function close() external override {
        require(_blockTimestamp() >= closeTime, "Not yet");
        require(canBuy, "Closed");
        canBuy = false;
        endRate = vault.pricePerShare();

        if (endRate < initialRate) endRate = initialRate; // wierd cases prevention?

        uint256 ratio = (endRate - initialRate) * 1e18 / initialRate;
        uint256 _bPrice = ratio * leverage / 1e18; // leverage
        bPrice = _bPrice > 1e18 ? 1e18 : _bPrice;
    }

}