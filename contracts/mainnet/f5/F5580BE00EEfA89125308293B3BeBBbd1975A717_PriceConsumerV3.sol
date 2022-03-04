pragma solidity ^0.6.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

import "./interfaces/IPriceConsumer.sol";
import './libraries/SafeMath.sol';
import "excalibur-core/contracts/interfaces/IExcaliburV2Pair.sol";
import "excalibur-core/contracts/interfaces/IExcaliburV2Factory.sol";
import "excalibur-core/contracts/interfaces/IERC20.sol";

contract PriceConsumerV3 is IPriceConsumer {
  using SafeMath for uint;

  address public owner;
  address public factory;

  address public immutable override USD; // stable usd coin, will be adapted depending on the used chain
  address public immutable override WETH;
  address public immutable override EXC;

  uint public immutable USD_DECIMALS;
  uint internal _lastEXCPrice;

  // token => quote address to use
  mapping(address => address) public tokensQuote;

  // [tokenAddress][quoteAddress] = priceFeederAddress => quoteAddress (WETH,USD)
  mapping(address => mapping(address => address)) public tokenPriceFeeder;

  event SetLastEXCPrice(uint lastEXCPrice, uint newPrice);
  event SetWhitelistToken(address token, bool isWhitelisted);
  event SetOwner(address prevOwner, address newOwner);
  event SetTokenPriceFeeder(address token, address quote, address priceFeeder);
  event SetTokenQuote(address token, address quote);

  constructor(address _factory, address _WETH, address _USD, address _EXC, uint usdDecimals) public {
    owner = msg.sender;
    factory = _factory;
    WETH = _WETH;
    USD = _USD;
    EXC = _EXC;
    USD_DECIMALS = usdDecimals; // Carefully put the right value !
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner == msg.sender, "PriceConsumerV3: caller is not the owner");
    _;
  }

  function lastEXCPrice() external view override returns (uint){
    return _lastEXCPrice;
  }

  function getTokenFairPriceUSD(address token) external override view returns (uint) {
    return _getTokenFairPriceUSD(token);
  }

  function getTokenPriceUSDUsingPair(address token) external override view returns (uint){
    return _getTokenPriceUSDUsingPair(token);
  }

  function getTokenMinPriceUSD(address token) external override view returns (uint) {
    if (token == USD) return 10 ** USD_DECIMALS;

    uint fairPriceUSD = _getTokenFairPriceUSD(token);
    if (fairPriceUSD == 0) return 0;
    // Only manage tokens from which a fair price can be fetch
    uint calculatedPriceUSD = _getTokenPriceUSDUsingPair(token);
    if (calculatedPriceUSD == 0) return 0;
    return fairPriceUSD < calculatedPriceUSD ? fairPriceUSD : calculatedPriceUSD;
  }

  function getEXCMaxPriceUSD() public override returns (uint){
    uint calculatedPriceUSD = _getTokenPriceUSDUsingPair(EXC);
    if (_lastEXCPrice < calculatedPriceUSD) {
      emit SetLastEXCPrice(_lastEXCPrice, calculatedPriceUSD);
      _lastEXCPrice = calculatedPriceUSD;
    }
    return _lastEXCPrice;
  }

  function valueOfTokenUSD(address token) external view override returns (uint valueInUSD) {
    return _valueOfTokenUSD(token);
  }

  function setTokenQuote(address token, address quote) external onlyOwner {
    require((quote == USD || quote == WETH) && token != quote, "PriceConsumerV3: invalid quote");
    tokensQuote[token] = quote;
    emit SetTokenQuote(token, quote);
  }

  function setTokenPriceFeeder(address token, address quote, address priceFeeder) external onlyOwner {
    require((quote == USD || quote == WETH) && token != quote, "PriceConsumerV3: invalid quote");
    tokenPriceFeeder[token][quote] = priceFeeder;
    emit SetTokenPriceFeeder(token, quote, priceFeeder);
  }

  function setLastEXCPrice(uint price, uint decimals) external onlyOwner {
    price = price.mul(10 ** USD_DECIMALS) / (10 ** decimals);
    emit SetLastEXCPrice(_lastEXCPrice, price);
    _lastEXCPrice = price;
    getEXCMaxPriceUSD();
  }

  function setOwner(address _owner) external onlyOwner {
    emit SetOwner(owner, _owner);
    owner = _owner;
  }

  function _valueOfTokenUSD(address token) internal view returns (uint valueInUSD) {
    if (token == WETH) return _getWETHFairPriceUSD();
    if (token == USD) return 10 ** USD_DECIMALS;

    uint fairPrice = _getTokenFairPriceUSD(token);
    if (fairPrice > 0) return fairPrice;

    return _getTokenPriceUSDUsingPair(token);
  }

  /**
   * @dev Returns the token latest price in USD based on priceFeeder
   */
  function _getTokenFairPriceUSD(address token) internal view returns (uint) {
    address quote = tokenPriceFeeder[token][USD] != address(0) ? USD : WETH;
    address priceFeeder = tokenPriceFeeder[token][quote];

    // no priceFeeder available
    if (priceFeeder == address(0)) return 0;

    uint priceDecimals = uint(AggregatorV3Interface(priceFeeder).decimals());
    (uint80 roundId,int price,,,uint80 answeredInRound) = AggregatorV3Interface(priceFeeder).latestRoundData();
    if (price <= 0 || answeredInRound < roundId) return 0;

    if (quote == WETH) {
      return uint(price).mul(_getWETHFairPriceUSD()) / 10 ** priceDecimals;
    }

    uint _usdDecimals = USD_DECIMALS;
    if (priceDecimals < _usdDecimals) {
      return uint(price).mul(10 ** (_usdDecimals - priceDecimals));
    }
    else if (priceDecimals > _usdDecimals) {
      return uint(price) / (10 ** (priceDecimals - _usdDecimals));
    }

    return uint(price);
  }

  /**
   * @dev Returns the WETH latest price in USD based on priceFeeder
   */
  function _getWETHFairPriceUSD() internal view returns (uint){
    address priceFeeder = tokenPriceFeeder[WETH][USD];
    if (priceFeeder == address(0)) return 0;

    uint priceDecimals = uint(AggregatorV3Interface(priceFeeder).decimals());
    (uint80 roundId,int price,,,uint80 answeredInRound) = AggregatorV3Interface(priceFeeder).latestRoundData();
    if (price <= 0 || answeredInRound < roundId) return 0;

    uint _usdDecimals = USD_DECIMALS;
    if (priceDecimals < _usdDecimals) {
      return uint(price).mul(10 ** (_usdDecimals - priceDecimals));
    }
    else if (priceDecimals > _usdDecimals) {
      return uint(price) / (10 ** (priceDecimals - _usdDecimals));
    }
    return uint(price);
  }

  /**
   * @dev Returns the token latest price in USD based on pair
   *
   * Called if no priceFeeder is available for this token
   */
  function _getTokenPriceUSDUsingPair(address token) internal view returns (uint){
    address quote = tokensQuote[token];
    if (quote == address(0)) return 0;
    address _pair = IExcaliburV2Factory(factory).getPair(token, quote);
    if (_pair == address(0)) return 0;
    IExcaliburV2Pair pair = IExcaliburV2Pair(_pair);

    (uint reserve0, uint reserve1,) = pair.getReserves();
    if (reserve0 == 0 || reserve1 == 0) return 0;

    uint priceInQuote = 0;
    address token0 = pair.token0();
    if (token0 == quote) {
      priceInQuote = reserve0.mul(10 ** uint(IERC20(pair.token1()).decimals())) / reserve1;
    }
    else {
      priceInQuote = reserve1.mul(10 ** uint(IERC20(token0).decimals())) / reserve0;
    }

    if (quote == WETH) {
      return priceInQuote.mul(_getWETHFairPriceUSD()) / (10 ** uint(IERC20(quote).decimals()));
    }
    return priceInQuote;
  }
}

pragma solidity =0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

pragma solidity ^0.6.0;

interface IPriceConsumer {
  function USD() external pure returns (address);
  function WETH() external pure returns (address);
  function EXC() external pure returns (address);
  function lastEXCPrice() external view returns (uint);
  function getTokenFairPriceUSD(address token) external view returns (uint);
  function getTokenPriceUSDUsingPair(address token) external view returns (uint);
  function valueOfTokenUSD(address token) external view returns (uint);
  function getTokenMinPriceUSD(address token) external view returns (uint);
  function getEXCMaxPriceUSD() external returns (uint);
}

pragma solidity >=0.5.0;

interface IExcaliburV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function feeAmount() external view returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function setFeeAmount(uint newFeeAmount) external;
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data, address referrer) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IExcaliburV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function owner() external view returns (address);
    function feeTo() external view returns (address);

    function ownerFeeShare() external view returns (uint256);
    function referrersFeeShare(address) external view returns (uint256);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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