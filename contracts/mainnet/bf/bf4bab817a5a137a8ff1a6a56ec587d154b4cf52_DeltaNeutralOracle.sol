// SPDX-License-Identifier: BUSL
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.8.10;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

import "./ILiquidityPair.sol";
import "./IDeltaNeutralOracle.sol";
import "./IChainLinkPriceOracle.sol";
import "./IERC20.sol";

import "./AlpacaMath.sol";

contract DeltaNeutralOracle is IDeltaNeutralOracle, Initializable, OwnableUpgradeable {
  using AlpacaMath for uint256;

  /// @dev Errors
  error DeltaNeutralOracle_InvalidLPAddress();

  /// @notice An address of chainlink usd token
  address public usd;
  /// @notice a chainLink interface to perform get price
  IChainLinkPriceOracle public chainLinkPriceOracle;

  function initialize(address _chainLinkPriceOracle, address _usd) public initializer {
    OwnableUpgradeable.__Ownable_init();
    chainLinkPriceOracle = IChainLinkPriceOracle(_chainLinkPriceOracle);
    usd = _usd;
  }

  /// @notice Perform the conversion from LP to dollar
  /// @dev convert lpToDollar using chainlink oracle price
  /// @param _lpAmount in ether format
  /// @param _lpToken address of LP token
  function lpToDollar(uint256 _lpAmount, address _lpToken) external view returns (uint256, uint256) {
    if (_lpAmount == 0) {
      return (0, block.timestamp);
    }
    (uint256 _lpPrice, uint256 _lastUpdate) = _getLPPrice(_lpToken);
    return ((_lpAmount * _lpPrice) / (10**18), _lastUpdate);
  }

  /// @notice Perform the conversion from dollar to LP
  /// @dev convert dollartoLp using chainlink oracle price
  /// @param _dollarAmount in ether format
  /// @param _lpToken address of LP token
  function dollarToLp(uint256 _dollarAmount, address _lpToken) external view returns (uint256, uint256) {
    if (_dollarAmount == 0) {
      return (0, block.timestamp);
    }
    (uint256 _lpPrice, uint256 _lastUpdate) = _getLPPrice(_lpToken);
    return (((_dollarAmount * (10**18)) / _lpPrice), _lastUpdate);
  }

  /// @notice Get token price in dollar
  /// @dev getTokenPrice from address
  /// @param _tokenAddress tokenAddress
  function getTokenPrice(address _tokenAddress) public view returns (uint256, uint256) {
    (uint256 _price, uint256 _lastTimestamp) = chainLinkPriceOracle.getPrice(_tokenAddress, usd);
    return (_price, _lastTimestamp);
  }

  /// @notice get LP price using internal only, return value in 1e18 format
  /// @dev getTokenPrice from address
  /// @param _lpToken lp token address
  function _getLPPrice(address _lpToken) internal view returns (uint256, uint256) {
    if (_lpToken == address(0)) {
      revert DeltaNeutralOracle_InvalidLPAddress();
    }
    uint256 _sqrtK;
    {
      uint256 _totalSupply = ILiquidityPair(_lpToken).totalSupply();
      if (_totalSupply == 0) {
        return (0, block.timestamp);
      }
      (uint256 _r0, uint256 _r1, ) = ILiquidityPair(_lpToken).getReserves();
      _sqrtK = AlpacaMath.sqrt(_r0 * _r1).fdiv(_totalSupply); //fdiv return in 2**112
    }

    (uint256 _px0, uint256 _px1, uint8 _d0, uint8 _d1, uint256 _olderLastUpdate) = _px(_lpToken);

    // fair token0 amt: _sqrtK * sqrt(_px1/_px0)
    // fair token1 amt: _sqrtK * sqrt(_px0/_px1)
    // fair lp price = 2 * sqrt(_px0 * _px1)
    // split into 2 sqrts multiplication to prevent uint overflow (note the 2**112)

    uint256 _totalValueIn18;
    {
      uint8 padDecimals = 36 - (_d0 + _d1);
      uint256 _totalValue = (((_sqrtK * 2 * (AlpacaMath.sqrt(_px0))) / (2**56)) * (AlpacaMath.sqrt(_px1))) / (2**56);
      _totalValueIn18 = (_totalValue / (2**112)) * 10**(padDecimals); // revert bumped up 2*112 from fdiv() and convert price to 1e18 unit
    }

    return (_totalValueIn18, _olderLastUpdate);
  }

  /// @notice Return token prices, token decimals, oldest price update of given lptoken
  /// @param _lpToken lp token address
  function _px(address _lpToken)
    internal
    view
    returns (
      uint256,
      uint256,
      uint8,
      uint8,
      uint256
    )
  {
    address _token0Address = ILiquidityPair(_lpToken).token0();
    address _token1Address = ILiquidityPair(_lpToken).token1();

    (uint256 _p0, uint256 _p0LastUpdate) = getTokenPrice(_token0Address); // in 2**112
    (uint256 _p1, uint256 _p1LastUpdate) = getTokenPrice(_token1Address); // in 2**112

    uint256 _olderLastUpdate = _p0LastUpdate > _p1LastUpdate ? _p1LastUpdate : _p0LastUpdate;

    uint8 _d0 = IERC20(_token0Address).decimals();
    uint8 _d1 = IERC20(_token1Address).decimals();

    uint256 _px0 = (_p0 * (2**112)) / 10**(18 - _d0); // in token decimals * 2**112
    uint256 _px1 = (_p1 * (2**112)) / 10**(18 - _d1); // in token decimals * 2**112

    return (_px0, _px1, _d0, _d1, _olderLastUpdate);
  }
}