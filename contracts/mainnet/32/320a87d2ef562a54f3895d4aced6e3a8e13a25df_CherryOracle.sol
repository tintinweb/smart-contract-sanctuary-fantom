/**
 *Submitted for verification at FtmScan.com on 2022-09-13
*/

// CherryOracle.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  From https://github.com/Uniswap/v2-periphery/blob/master/contracts/examples/ExampleOracleSimple.sol

  Fixed window oracle that computes the Time Weighted Average Price for the entire epoch once every epoch.

  The TWAP is only guaranteed to be over at least 1 epoch, but may be over more
  in case the update() function has not been called for a long time.

  Strongly simplified so that:
    - we don't use the obscure FixedPoint library
        we simply >> 112 and << 112 when necessary
    - we don't rely on UniswapV2OracleLibrary.sol
        it does too much for our need
    - we don't use UniswapV2Library
        it does too much for our need
    - we don't care about the price of FTM in CHRY (aka token1 / token0)
    - we don't care about time overflow: get real boys!
        uint32 time will overflow in 2106!

    With these simplifications, we get a much simpler oracle that is:
      - much easier to understand
      - only cares about one token price
      - self contained, no dependency
      - much more gas efficient
      - compiles with solidity 0.8

  Owner powers:
    - none

  Some Maths:

    reserves are in uint112
    prices   are in uint224  (aka uq112x112)
      the 112 left  bits are the integer part
      the 112 right bits are the decimal part
    cumulative prices are in uint256 = uint224 price * uint32 time interval

    To compute a price:   price = uint224(reserveToken0) << 112 / uint224(reserveToken1)
    "<< 112" is equivalent to "* 2**112"
*/


abstract contract Ownable {

  // ==== Events      ====
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  // ==== Storage     ====
  // Private so it cannot be changed by inherited contracts
  address private _owner;


  // ==== Constructor ====
  constructor() {
    _transferOwnership(msg.sender);
  }


  // ==== Modifiers   ====
  modifier onlyOwner() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }


  // ==== Views       ====
  function owner() public view virtual returns (address) {
    return _owner;
  }


  // ==== Mutators    ====

  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner_) public virtual onlyOwner {
    require(newOwner_ != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner_);
  }


  // ==== Internals   ====

  function _transferOwnership(address newOwner_) internal virtual {
    address oldOwner = owner();
    _owner = newOwner_;
    emit OwnershipTransferred(oldOwner, newOwner_);
  }
}


// Minimal interface to Liquidity Pool contract.
// Here I'm only interested in the token1 (CHRY) and don't care about token0 (FTM)
interface IPool {
    // returns contract address of the ERC20 token1
    function token1() external view returns (address);

    // returns the reserves of the liquidity pool
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    // returns the last cumulative price of token 1
    function price1CumulativeLast() external view returns (uint256);
}


contract CherryOracle is Ownable {

  // ==== Events ====
  event Updated(uint32 indexed epoch, uint112 twap);


  // ==== Constants ====
  uint256 public constant PERIOD = 6 hours;

  address public constant pool   = 0xF2aDD870885c1B3E50B7cBA81a87C4d0291cBf6F;
  address public constant token  = 0x4C41bFf37db389BA1edC7ED7e757059a1D08ceb5;


  // ==== Storage ====
  // ---- Slot 1  ----
  uint32  public epoch;
  uint32  public blockTimestampLast;
  uint112 public twap;
  // ---- Slot 2  ----
  uint256 public price1CumulativeLast;


  // ==== Constructor ====
  constructor() {

    // coherence check:
    // we call the pool.token1() to make sure its the right one
    require(IPool(pool).token1() == token, "Hey, you took the wrong Spooky LP");

    // set blockTimestampLast
    uint112 reserveFTM;
    uint112 reserveCHRY;
    (reserveFTM, reserveCHRY, blockTimestampLast) = IPool(pool).getReserves();

    // make sure liquidity pool not empty
    require(reserveFTM  > 0, 'Oracle: FTM  reserve empty');
    require(reserveCHRY > 0, 'Oracle: CHRY reserve empty');

    // set the initial token cumulative price from LP
    price1CumulativeLast =  IPool(pool).price1CumulativeLast();

    // set initial Epoch
    epoch = uint32(getEpoch());

    // The TWAP cannot be initialised.
    // It will be zero until update() has been successfully called.
  }


  // Current epoch
  function getEpoch() public view returns (uint256) {
    return block.timestamp / PERIOD;
  }


  // Update the state of the Oracle once every epoch.
  function update() external returns(bool) {
    // only once per epoch
    uint256 newEpoch = getEpoch();
    require(newEpoch > epoch, "Oracle: wait until next epoch");

    // below code will only be run once per epoch

    // update epoch
    epoch = uint32(newEpoch);

    // get last cumulative prices from liquidity pool
    uint256 price1CumulativeNew = IPool(pool).price1CumulativeLast();

    // get last time the liquidity pool was updated
    (uint256 reserve0, uint256 reserve1, uint256 lastPoolUpdate) = IPool(pool).getReserves();

    // if time has elapsed since the last update of the liquidity pool
    if (lastPoolUpdate < block.timestamp) {
      // we mock the accumulated price increase
      unchecked {
        price1CumulativeNew += ((reserve0 << 112) / reserve1) * ( block.timestamp - lastPoolUpdate );
      }
    }

    // compute new twap = acc price delta / time delta
    uint112 newTwap;
    unchecked {
      newTwap = uint112( ((price1CumulativeNew - price1CumulativeLast) / ( block.timestamp - blockTimestampLast)) * 1e18 >> 112);
    }

    // write down new state to storage
    blockTimestampLast   = uint32(block.timestamp);
    price1CumulativeLast = price1CumulativeNew;
    twap                 = newTwap;

    emit Updated(uint32(newEpoch), newTwap);

    return true;
  }
}