/**
 *Submitted for verification at FtmScan.com on 2022-09-10
*/

// ISpookyLP.sol
// This is a minimal interface to SpookySwap Liquidity Pool contract.
// Here I'm only interested in the token1 (CHRY) and don't care
// about token0 (FTM)

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;


interface ISpookyLP {

    // returns contract address of the ERC20 token1
    function token1() external view returns (address);

    // returns the reserves of the liquidity pool
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    // returns the last cumulative price of token 1
    function price1CumulativeLast() external view returns (uint256);

}



// Ownable.sol

// Ownable from OpenZeppelin
abstract contract Ownable {

  // ==== Events ====

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  // ==== Storage ====

  address private _owner;


  // ==== Modifiers ====

  modifier onlyOwner() {
      _checkOwner();
      _;
  }


  // ==== Constructor ====

  constructor() {
    _transferOwnership(msg.sender);
  }


  // ==== Views ====

  function owner() public view virtual returns (address) {
    return _owner;
  }


  // ==== Mutators ====

  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }


  // ==== Privates ====

  function _checkOwner() private view {
    require(owner() == msg.sender, "Ownable: caller is not the owner");
  }

  function _transferOwnership(address newOwner) private {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

}



/**
  From https://github.com/Uniswap/v2-periphery/blob/master/contracts/examples/ExampleOracleSimple.sol

  Fixed window oracle that recomputes the average price for the entire epoch once every epoch.

  The price average is only guaranteed to be over at least 1 epoch, but may be over more
  in case the update() function has not been called for a long time.

  Strongly simplified so that:
    - we don't use the obscure FixedPoint library
        we simply >> 112 and << 112 when necessary
    - we don't rely on UniswapV2OracleLibrary.sol
        it does too much for our need
    - we don't use UniswapV2Library
        it does too much for our need
    - we don't care about the price of FTM in CHRY (aka token1 / token0)

    With these simplifications, we get a much simpler oracle that is:
      - much easier to understand
      - self contained, no dependency
      - more gas efficient
      - only cares about CHRY price so we don't need to pass which token we are interested in

  And we are compatible with Solidity 0.8 !!!
*/

// a uq112x112 is a uint224 where:
//        the first 112 bits are for integer part
// and    the last  112 bits are for the decimal part

contract CherryOracle is Ownable {

  event Updated(uint256 price1CumulativeLast, uint224 price1Average);

  // ==== Constants ====

  address public immutable spookyLP    = 0xa080773F1e84eE0Bd06362c8560e77AdB2109525;
  address public immutable cherryToken = 0x526012Fa3Ce0e44422D08171Cd38227946F5e522;
  string  constant symbol = 'CHRY';  // CHRY is token1

  uint256 public constant PERIOD = 6 hours;


  // ==== Storage ====

  uint32  public epoch;
  uint32  public lastBlockTimestamp;
  // prices are uq112x112: the representation of a decimal number as an uint224
  uint224 public price1Average;
  // cumulative prices are uq112x112 multiplied by uint32 seconds = uint256 number
  uint256 public price1CumulativeLast;


  constructor() {

    // coherence check:
    // we call the spookyLP.token1() to make sure its the right one
    require(ISpookyLP(spookyLP).token1() == cherryToken, "Hey, you took the wrong Spooky LP");

    // make sure liquidity pool not empty
    // ... and set lastBlockTimestamp
    uint112 reserveFTM;
    uint112 reserveCHRY;
    (reserveFTM, reserveCHRY, lastBlockTimestamp) = ISpookyLP(spookyLP).getReserves();
    require(reserveFTM  > 0, 'Oracle: FTM  reserve empty');
    require(reserveCHRY > 0, 'Oracle: CHRY reserve empty');

    // set the initial cherry cumulative price:
    price1CumulativeLast =  ISpookyLP(spookyLP).price1CumulativeLast(); // fetch the current accumulated price of Cherries

    // set initial Epoch
    epoch = getEpoch();

    // the average price cannot be initialised:
    // it will be zero until update() has been successfully called
  }

  // Current epoch
  function getEpoch() public view returns (uint32) {
    return uint32(block.timestamp / PERIOD);
  }

  // update the state of the Oracle once every epoch
  function update() external {
    // only once per epoch
    require(getEpoch() > epoch, "Oracle: wait until next epoch");

    // update epoch
    epoch = getEpoch();

    // now
    uint32 now32 = uint32(block.timestamp);

    // get last cumulative prices in SpookyLP:
    uint256 price1Cumulative = ISpookyLP(spookyLP).price1CumulativeLast();

    // if time has elapsed since the last update on the pair, mock the accumulated price values
    uint112 reserve0;
    uint112 reserve1;
    uint32  lastBlockTS;
    (reserve0, reserve1, lastBlockTS) = ISpookyLP(spookyLP).getReserves();
    if (lastBlockTS != now32) {
      // this is current cherry price as uq112x112
      uint224 token1currentPrice = uint224(reserve0) << 112 / uint224(reserve1);
      // mock accumulated price evolution
      // overflow is desired
      unchecked{
        price1Cumulative += uint256(token1currentPrice * ( now32 - lastBlockTS ));
      }
    }

    // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
    // overflow is desired, casting never truncates
    unchecked {
      price1Average = uint224((price1Cumulative - price1CumulativeLast) / ( now32 - lastBlockTimestamp));
    }

    price1CumulativeLast = price1Cumulative;
    lastBlockTimestamp   = now32;

    emit Updated(price1Cumulative, price1Average >> 112);
  }

  // gives the price of Cherries from the Oracle
  function consult() external view returns (uint256 oraclePrice) {
    oraclePrice = (uint256(price1Average) * 1e18) >> 112;
  }
}