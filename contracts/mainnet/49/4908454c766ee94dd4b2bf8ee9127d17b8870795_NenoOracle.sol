// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./interfaces/AggregatorV3Interface.sol";

contract NenoOracle {
    AggregatorV3Interface public assetPriceFeed;
    AggregatorV3Interface public collateralPriceFeed;

    constructor(AggregatorV3Interface _assetPriceFeed, AggregatorV3Interface _collateralPriceFeed){
        assetPriceFeed = (_assetPriceFeed);
        collateralPriceFeed = (_collateralPriceFeed);
    }

    ///@notice Get the latest price from both collateral price feed and asset price feed
    ///@return price of the collateral in terms of the asset
    function latestPrice() public view returns (uint256){
       (,int256 collateralPrice,,,)  = collateralPriceFeed.latestRoundData();
       (,int256 assetPrice,,,)  = assetPriceFeed.latestRoundData();
       return (uint256(collateralPrice)*1e6)/(uint256(assetPrice));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

}