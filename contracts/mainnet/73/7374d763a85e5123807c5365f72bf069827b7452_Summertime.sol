/**
 *Submitted for verification at FtmScan.com on 2022-10-31
*/

// CherrySummertime.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**

Summertime

This contract is NOT supposed to have ANY token.
Not event token or tree tokens.

Owner Powers:
  - setOrchardForEver(address orchard_) once
  - nothing else

Operator Powers:
  - setPeg()
Operator is allowed to change peg targed, as long as it less or equal to 1 FTM.
This is in case FTM price goes crazy. Imagine FTM = $5, then a simple comment
or like on Cherrific would cost $10 !!! This would kill the app.

TRUST (and gas cost) over governance

Summertime, and the livin' is easy

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


// Interfaces

interface IERC20 {
    event Transfer(address indexed from,  address indexed to,      uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply()                             external view returns (uint256);
    function balanceOf(address account)                external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(     address to,                uint256 amount)  external returns (bool);
    function approve(      address spender,           uint256 amount)  external returns (bool);
    function transferFrom( address from,  address to, uint256 amount ) external returns (bool);
}


interface IERC20Metadata is IERC20 {
    function name()     external view returns (string memory);
    function symbol()   external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IERC20Mintable {
    function totalSupply()                       external view returns (uint256);
    function mint(address account, uint amount)  external      returns (bool);
}

interface IOrchard {
  function summertime() external view returns(address);
  function distributeSeigniorage(uint amount) external returns (bool);
}

interface IOracle {
  function epoch()  external view returns(uint32);
  function twap()   external view returns(uint112);
  function update() external      returns(bool);
}


contract Summertime is Ownable {

  // ==== Events ====

  event OrchardFunded(uint32 indexed epoch, uint80 expansionRate, uint112 minted);

  // ==== Constants ====

  uint constant PERIOD = 6 hours;
  uint constant maxExpansionRate  = 5 * 1e16;  // 5%
  uint constant minSupply         = 1e22; // minimum 10 000 tokens

  // ==== Storage ====

  // epoch
  // is incremented only in computeSeigniorage()
  uint32  public epoch;
  uint80  public peg = 100 * 1e16;  // 1.00 FTM

  address public operator;

  // related contracts
  address public immutable token;
  address public immutable oracle;
  address public orchard;
  // FYI: Summertime doesn't know tree token

  // ==== Constructor ====

  constructor(
    address token_,
    address oracle_,
    string  memory symbol_
  ) {
    require(token_   != address(0), "Token cannot be 0x00");
    require(oracle_  != address(0), "Oracle cannot be 0x00");

    // check the token contract that we set is indeed the good token contract
    require(
      keccak256(abi.encodePacked(IERC20Metadata(token_).symbol())) == keccak256(abi.encodePacked(symbol_)),
      "Not the right token"
    );

    token  = token_;
    oracle = oracle_;
    operator = msg.sender;
  }

  // ==== Governance ====

  // Setting the orchard can only be done once
  function setOrchardForEver(address orchard_) external onlyOwner returns(bool) {
    // can only be run once
    require(orchard == address(0), "Orchard already set");

    // Safeguard: make sure we are the Summertime of the Orchard
    require(IOrchard(orchard_).summertime() == address(this), "Wrong Orchard");

    orchard = orchard_;

    return true;
  }

  function setOperator(address operator_) external returns(bool) {
    require(msg.sender == operator, "Only operator can change operator");

    operator = operator_;
    return true;
  }

  function setPeg(uint peg_) external returns(bool) {
    require(msg.sender == operator, "Only operator can set peg");
    require(peg_ <= 1e18, "Peg must be under 1FTM");

    peg = uint80(peg_);
    return true;
  }


  // ==== Views ====

  // Current epoch
  function getEpoch() public view returns (uint) {
    return block.timestamp / PERIOD;
  }



  // ==== Mutators ====

  /**
   * Open for anyone to call
   */

  function computeSeigniorage() external returns(bool) {

    uint newEpoch = getEpoch();

    // don't do this or you will block Orchard update
    // require(newEpoch > epoch, "Summertime: has already run this epoch");

    // do this instead:
    if (newEpoch <= epoch) {
      return true;
    }

    // below code will only be run once per epoch

    // update epoch
    epoch = uint32(newEpoch);

    // check Oracle is on current epoch
    if (newEpoch > IOracle(oracle).epoch()) {
      IOracle(oracle).update(); // should revert if does not work
    }

    // "new" means the twap of new previous epoch
    uint newTwap = IOracle(oracle).twap();

    if (newTwap < (peg * 101 / 100)) {
      // no summer
      // just so that Orchard updates its epoch
      IOrchard(orchard).distributeSeigniorage(0);
      return true;
    }

    // summer: do seigniorage
    uint tokenSupply = IERC20Mintable(token).totalSupply();

    uint qtyToMint;
    uint expansionRate;

    if (tokenSupply < minSupply) {
      // to avoid suffocating the app in case base coins are burnt faster
      // than minted, we directly set supply to 120% of minSupply
      unchecked {
        qtyToMint = minSupply - tokenSupply + minSupply / 5;
        expansionRate = ((qtyToMint << 112) / tokenSupply) * 1e18 >> 112;
      }
    } else {

      // normal expansion
      unchecked {
        expansionRate = (newTwap - peg) / 10;
        // twap:  1.01 FTM  ->  exp: 0.001 = 0.1 %
        // twap:  1.10 FTM  ->  exp: 0.01  = 1.0 %
        // twap:  1.30 FTM  ->  exp: 0.03  = 3.0 %
        // twap:  1.50 FTM  ->  exp: 0.05  = 5.0 %
      }

      // cap expansionRate to 5%
      if (expansionRate > maxExpansionRate ) {
          expansionRate = maxExpansionRate;
      }
      // mint for Orchard
      unchecked {
        qtyToMint = tokenSupply * expansionRate / 1e18;
      }
    }

    IERC20Mintable(token).mint(orchard, qtyToMint);
    IOrchard(orchard).distributeSeigniorage(qtyToMint);

    emit OrchardFunded(uint32(newEpoch), uint80(expansionRate), uint112(qtyToMint));

    return true;
  }
}