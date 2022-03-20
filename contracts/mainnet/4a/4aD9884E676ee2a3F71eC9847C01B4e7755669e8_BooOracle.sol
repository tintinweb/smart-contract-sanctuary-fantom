// SPDX-License-Identifier: AGPL-3.0-only
// Using the same Copyleft License as in the original Repository
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import {Ownable} from '../dependencies/openzeppelin/contracts/Ownable.sol';
import './interfaces/IOracle.sol';
import '../interfaces/IChainlinkAggregator.sol';
import '../protocol/libraries/math/BoringMath.sol';
import '../dependencies/openzeppelin/contracts/IERC20.sol';
import '../interfaces/IUniswapV2Pair.sol';
import '../lib/FixedPoint.sol';

contract BooOracle is IOracle, Ownable {
  using FixedPoint for *;
  using BoringMath for uint256;
  uint256 public constant PERIOD = 10 minutes;
  IChainlinkAggregator public constant FTM_USD =
    IChainlinkAggregator(0xf4766552D15AE4d256Ad41B6cf2933482B0680dc);
  IUniswapV2Pair public constant BOO_FTM =
    IUniswapV2Pair(0xEc7178F4C41f346b2721907F5cF7628E388A7a58);
  IERC20 public constant BOO = IERC20(0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE);
  bool isCumulativePrice;

  struct PairInfo {
    uint256 priceCumulativeLast;
    uint256 priceAverage;
    uint32 blockTimestampLast;
  }

  PairInfo public pairInfo;

  function _get(uint32 blockTimestamp) internal view returns (uint256) {
    uint256 priceCumulative = BOO_FTM.price1CumulativeLast();

    // if time has elapsed since the last update on the pair, mock the accumulated price values
    (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(BOO_FTM)
      .getReserves();
    priceCumulative +=
      uint256(FixedPoint.fraction(reserve0, reserve1)._x) *
      (blockTimestamp - blockTimestampLast); // overflows ok

    // overflow is desired, casting never truncates
    // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
    return priceCumulative;
  }

  // Get the latest exchange rate, if no valid (recent) rate is available, return false
  /// @inheritdoc IOracle
  function get() public override returns (bool, uint256) {
    uint32 blockTimestamp = uint32(block.timestamp);
    if (pairInfo.blockTimestampLast == 0) {
      pairInfo.blockTimestampLast = blockTimestamp;
      pairInfo.priceCumulativeLast = _get(blockTimestamp);
      return (false, 0);
    }
    uint32 timeElapsed = blockTimestamp - pairInfo.blockTimestampLast; // overflow is desired

    if (timeElapsed < PERIOD) {
      return (true, pairInfo.priceAverage);
    }

    uint256 priceCumulative = _get(blockTimestamp);
    pairInfo.priceAverage =
      uint256(
        FixedPoint
          .uq112x112(uint224((priceCumulative - pairInfo.priceCumulativeLast) / timeElapsed))
          .mul(1e18)
          .decode144()
      ).mul(uint256(FTM_USD.latestAnswer())) /
      1e18;

    pairInfo.blockTimestampLast = blockTimestamp;
    pairInfo.priceCumulativeLast = priceCumulative;

    return (true, pairInfo.priceAverage);
  }

  // Check the last exchange rate without any state changes
  /// @inheritdoc IOracle
  function peek() public view override returns (bool, int256) {
    uint32 blockTimestamp = uint32(block.timestamp);
    if (pairInfo.blockTimestampLast == 0) {
      return (false, 0);
    }
    uint32 timeElapsed = blockTimestamp - pairInfo.blockTimestampLast; // overflow is desired
    if (timeElapsed < PERIOD) {
      return (true, int256(pairInfo.priceAverage));
    }

    uint256 priceCumulative = _get(blockTimestamp);
    int256 priceAverage = int256(
      uint256(
        FixedPoint
          .uq112x112(uint224((priceCumulative - pairInfo.priceCumulativeLast) / timeElapsed))
          .mul(1e18)
          .decode144()
      ).mul(uint256(FTM_USD.latestAnswer())) / 1e18
    );

    return (true, priceAverage);
  }

  function enableCumulativePrice(bool enable) external onlyOwner {
    isCumulativePrice = enable;
    if (enable) {
      get();
    }
  }

  // Check the current spot exchange rate without any state changes
  /// @inheritdoc IOracle
  function latestAnswer() external view override returns (int256 rate) {
    (uint256 reserve0, uint256 reserve1, ) = BOO_FTM.getReserves();
    if (isCumulativePrice) {
      (, rate) = peek();
    }

    if (rate <= 0) {
      rate = int256((reserve0.mul(1e18) / reserve1).mul(uint256(FTM_USD.latestAnswer())) / 1e18);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import './Context.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() public {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IOracle {
  /// @notice Get the latest price.
  /// @return success if no valid (recent) rate is available, return false else true.
  /// @return rate The rate of the requested asset / pair / pool.
  function get() external returns (bool success, uint256 rate);

  /// @notice Check the last price without any state changes.
  /// @return success if no valid (recent) rate is available, return false else true.
  /// @return rate The rate of the requested asset / pair / pool.
  function peek() external view returns (bool success, int256 rate);

  /// @notice Check the current spot price without any state changes. For oracles like TWAP this will be different from peek().
  /// @return rate The rate of the requested asset / pair / pool.
  function latestAnswer() external view returns (int256 rate);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IChainlinkAggregator {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library BoringMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require((c = a + b) >= b, 'BoringMath: Add Overflow');
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require((c = a - b) <= a, 'BoringMath: Underflow');
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require(b == 0 || (c = a * b) / b == a, 'BoringMath: Mul Overflow');
  }

  function to128(uint256 a) internal pure returns (uint128 c) {
    require(a <= uint128(-1), 'BoringMath: uint128 Overflow');
    c = uint128(a);
  }

  function to64(uint256 a) internal pure returns (uint64 c) {
    require(a <= uint64(-1), 'BoringMath: uint64 Overflow');
    c = uint64(a);
  }

  function to32(uint256 a) internal pure returns (uint32 c) {
    require(a <= uint32(-1), 'BoringMath: uint32 Overflow');
    c = uint32(a);
  }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
library BoringMath128 {
  function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
    require((c = a + b) >= b, 'BoringMath: Add Overflow');
  }

  function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
    require((c = a - b) <= a, 'BoringMath: Underflow');
  }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint64.
library BoringMath64 {
  function add(uint64 a, uint64 b) internal pure returns (uint64 c) {
    require((c = a + b) >= b, 'BoringMath: Add Overflow');
  }

  function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {
    require((c = a - b) <= a, 'BoringMath: Underflow');
  }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath32 {
  function add(uint32 a, uint32 b) internal pure returns (uint32 c) {
    require((c = a + b) >= b, 'BoringMath: Add Overflow');
  }

  function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {
    require((c = a - b) <= a, 'BoringMath: Underflow');
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;
import './FullMath.sol';

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
  // range: [0, 2**112 - 1]
  // resolution: 1 / 2**112
  struct uq112x112 {
    uint224 _x;
  }

  // range: [0, 2**144 - 1]
  // resolution: 1 / 2**112
  struct uq144x112 {
    uint256 _x;
  }

  uint8 private constant RESOLUTION = 112;
  uint256 private constant Q112 = 0x10000000000000000000000000000;
  uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000;
  uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

  // decode a UQ144x112 into a uint144 by truncating after the radix point
  function decode144(uq144x112 memory self) internal pure returns (uint144) {
    return uint144(self._x >> RESOLUTION);
  }

  // multiply a UQ112x112 by a uint256, returning a UQ144x112
  // reverts on overflow
  function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
    uint256 z = 0;
    require(y == 0 || (z = self._x * y) / y == self._x, 'FixedPoint::mul: overflow');
    return uq144x112(z);
  }

  // returns a UQ112x112 which represents the ratio of the numerator to the denominator
  // lossy if either numerator or denominator is greater than 112 bits
  function fraction(uint256 numerator, uint256 denominator)
    internal
    pure
    returns (uq112x112 memory)
  {
    require(denominator > 0, 'FixedPoint::fraction: div by 0');
    if (numerator == 0) return FixedPoint.uq112x112(0);

    if (numerator <= uint144(-1)) {
      uint256 result = (numerator << RESOLUTION) / denominator;
      require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
      return uq112x112(uint224(result));
    } else {
      uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
      require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
      return uq112x112(uint224(result));
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// SPDX-License-Identifier: CC-BY-4.0
pragma solidity 0.6.12;

// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library FullMath {
  function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
    uint256 mm = mulmod(x, y, uint256(-1));
    l = x * y;
    h = mm - l;
    if (mm < l) h -= 1;
  }

  function fullDiv(
    uint256 l,
    uint256 h,
    uint256 d
  ) private pure returns (uint256) {
    uint256 pow2 = d & -d;
    d /= pow2;
    l /= pow2;
    l += h * ((-pow2) / pow2 + 1);
    uint256 r = 1;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    return l * r;
  }

  function mulDiv(
    uint256 x,
    uint256 y,
    uint256 d
  ) internal pure returns (uint256) {
    (uint256 l, uint256 h) = fullMul(x, y);
    uint256 mm = mulmod(x, y, d);
    if (mm > l) h -= 1;
    l -= mm;
    require(h < d, 'FullMath::mulDiv: overflow');
    return fullDiv(l, h, d);
  }
}