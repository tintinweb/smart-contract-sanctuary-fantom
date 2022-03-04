pragma solidity =0.6.6;

import 'excalibur-core/contracts/interfaces/IExcaliburV2Pair.sol';
import 'excalibur-core/contracts/interfaces/IExcaliburV2Factory.sol';
import 'excalibur-core/contracts/interfaces/IERC20.sol';

import './libraries/SafeMath.sol';
import "./interfaces/IPriceConsumer.sol";
import "./interfaces/ISwapFeeRebate.sol";

contract SwapFeeRebate is ISwapFeeRebate{
  using SafeMath for uint;

  IExcaliburV2Factory public immutable factory;
  address immutable EXC;

  IPriceConsumer public priceConsumer;
  uint public feeRebateShare = 100; // 100%
  mapping(address => bool) public whitelistedPairs; // trustable pairs for transaction fee mining

  event FeeRebateShareUpdated(uint feeRebateShare, uint newFeeRebateShare);
  event SetPriceConsumer(address prevPriceConsumer, address priceConsumer);
  event SetWhitelistPair(address pair, bool whitelisted);

  constructor (IExcaliburV2Factory _factory, address excAddress, IPriceConsumer _priceConsumer) public {
    factory = _factory;
    EXC = excAddress;
    priceConsumer = _priceConsumer;
  }

  function owner() public view returns (address){
    return factory.owner();
  }

  function setPriceConsumer(IPriceConsumer _priceConsumer) external {
    require(msg.sender == owner(), "SwapFeeRebate: not allowed");
    emit SetPriceConsumer(address(priceConsumer), address(_priceConsumer));
    priceConsumer = _priceConsumer;
  }

  function setFeeRebateShare(uint newFeeRebateShare) external {
    require(msg.sender == owner(), "SwapFeeRebate: not allowed");
    require(newFeeRebateShare <= 100, "SwapFeeRebate: feeRebateShare mustn't exceed maximum");
    emit FeeRebateShareUpdated(feeRebateShare, newFeeRebateShare);
    feeRebateShare = newFeeRebateShare;
  }

  function setWhitelistPair(address token0, address token1, address pair, bool whitelisted) external {
    require(msg.sender == owner(), "SwapFeeRebate: not allowed");
    require(factory.getPair(token0, token1) == pair, "SwapFeeRebate: invalid pair address");
    whitelistedPairs[pair] = whitelisted;
    emit SetWhitelistPair(pair, whitelisted);
  }

  function isWhitelistedPair(address pair) external view returns (bool) {
    return whitelistedPairs[pair];
  }

  function updateEXCLastPrice() external override {
    priceConsumer.getEXCMaxPriceUSD();
  }

  function getEXCFees(address inputToken, address outputToken, uint outputTokenAmount) external view override returns (uint){
    if (feeRebateShare == 0) return 0;

    address pair = factory.getPair(inputToken, outputToken);
    if (!whitelistedPairs[pair]) return 0;
    uint feeAmount = IExcaliburV2Pair(pair).feeAmount();

    if(outputToken == EXC){
      return outputTokenAmount.mul(feeAmount).mul(feeRebateShare) / 100000 / 100;
    }

    uint excPrice = priceConsumer.lastEXCPrice();
    if(excPrice == 0) return 0;

    uint outputTokenPriceUSD = priceConsumer.getTokenMinPriceUSD(outputToken);
    if(outputTokenPriceUSD == 0) return 0;

    // check if token decimals is 18 like the EXC token and adjust it for conversion
    uint outputTokenDecimals = IERC20(outputToken).decimals();
    if (outputTokenDecimals < 18) {
      outputTokenAmount = outputTokenAmount.mul(10 ** (18 - outputTokenDecimals));
    }
    else if (outputTokenDecimals > 18){
      outputTokenAmount = outputTokenAmount / (10 ** (outputTokenDecimals - 18));
    }

    return outputTokenAmount.mul(outputTokenPriceUSD).mul(feeAmount).mul(feeRebateShare) / 100000 / 100 / excPrice;
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

interface ISwapFeeRebate {
  function updateEXCLastPrice() external;
  function getEXCFees(address inputToken, address outputToken, uint outputTokenAmount) external view returns (uint);
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