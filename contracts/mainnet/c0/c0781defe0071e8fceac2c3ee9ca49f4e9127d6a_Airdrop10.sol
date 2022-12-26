/**
 *Submitted for verification at FtmScan.com on 2022-12-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Tetraktys Airdrop
 *
 * People can claim cherry trees when they have reacted on Cherrific.
 *
 * 1) the contract is filled with CHRT reward reserve
 * 2) as long as the reserve is > zero, any wallet that have reacted
 *    on Cherrific can claim the number of CHRT tokens equal to the nb
 *    of CHRY that was burnt for the reaction.
 *
 * Warning: diamond reactions don't count, because 5 isn't part of the Tetraktys.
 * If you are unhappy about this, please address your complain to Pythagoras.
 *
 * Owner powers:
 *   - none
 °
 * Governance:
 *   - none
 *
 * This contract is not upgradable.
 *
 * For all details about the Tetraktys airdrop, please read:
 * https://cherrific.io/0xedB00816FB204b4CD9bCb45FF2EF693E99723484/story/28
 */


// From OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
// simplified (not is Context)

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



interface ICherrific {
  struct Reaction { uint32 reactorId; uint32 timestamp; int8 reaction; }

  function getReaction(
		address storyAuthorAddress_,
		uint24  storyId_,
		uint16  commentId_,
    uint    reactionId_
  ) external view returns (Reaction memory);

	function getUserAddressFromId(uint32 id_) external view returns (address);
}

interface IERC20Tree {
    function transfer(     address to,                uint256 amount)  external returns (bool);
    function transferFrom( address from,  address to, uint256 amount ) external returns (bool);
}



contract Airdrop10 is Ownable {

  // ----- Events -----
  event ReserveAdded (address indexed user, uint80 amount);
  event Claimed (address indexed claimer, uint80 amount);

  // ----- Structs -----
  struct Claimer {
    // slot 1
    bool   claim1;
    bool   claim2;
    bool   claim3;
    bool   claim4;
    uint32 lastClaimEpoch;
    // 36 bits in all
  }

  // ----- Constants -----
  uint    public constant PERIOD    = 6 hours;
  address public constant cherrific = 0xD022D9AC8bdE380B028682664b5F58d034254BEf;
  address public constant tree      = 0x8Dc673878d325C028D08d73C24cD59E15df62a4c;


  // ----- Storage -----
  uint80  public reserve;     // total CHRT left to distribute

  // users who already claimed
	mapping(address => Claimer) public claimers;


  // ----- Governance -----
  //   - none


  // ----- Views -----
  // Current epoch
  function getEpoch() public view returns (uint) {
    return block.timestamp / PERIOD;
  }

  function getEpoch(uint time_) public pure returns (uint) {
    return time_ / PERIOD;
  }


  // ----- Mutators -----

  // add reserve to be distributed
  // anyone can add reserve if they want to give CHRT
  function addReserve(uint amount_) public returns(bool) {

    IERC20Tree(tree).transferFrom(msg.sender, address(this), amount_);
    reserve += uint80(amount_);

    emit ReserveAdded(msg.sender, uint80(amount_));

    return true;
  }

  // claim by passing the reference to your reaction
  function claim(
		address storyAuthorAddress_,
		uint24  storyId_,
		uint16  commentId_,
    uint    reactionId_
  ) external returns (bool) {
    // get claimer
    Claimer memory me = claimers[msg.sender];

    // check we haven't already claimed during this epoch
    uint currentEpoch = getEpoch();
    require (me.lastClaimEpoch < currentEpoch, "Airdrop10: cannot claim twice in same epoch");
    me.lastClaimEpoch = uint32(currentEpoch);

    // get reaction
    ICherrific.Reaction memory reac = ICherrific(cherrific).getReaction(storyAuthorAddress_, storyId_, commentId_, reactionId_);

    // check reaction isn't from same epoch
    require(currentEpoch > getEpoch(reac.timestamp), "Airdrop10: wait next epoch before claim");

    // check passed reaction is mine
    address reactorAddress = ICherrific(cherrific).getUserAddressFromId(reac.reactorId);
    require(reactorAddress == msg.sender, "Airdrop10: this reaction isn't yours");

    uint claimable = 0;

    if (reac.reaction == 2) {
      require(me.claim1 == false, "Airdrop10: you already claimed a thumb up");
      me.claim1 = true;
      claimable = 1;
    } else if (reac.reaction == 5) {
      require(me.claim2 == false, "Airdrop10: you already claimed a smiley");
      me.claim2 = true;
      claimable = 2;
    } else if (reac.reaction == 10) {
      require(me.claim3 == false, "Airdrop10: you already claimed a heart");
      me.claim3 = true;
      claimable = 3;
    } else if (reac.reaction == 20) {
      require(me.claim4 == false, "Airdrop10: you already claimed a present");
      me.claim4 = true;
      claimable = 4;
    } else {
      revert("Airdrop10: this reaction isn't claimable");
    }

    claimable = claimable * 1e18;

    // check we have enough reserve
    require(claimable <= reserve, "Airdrop10: drat! Not enough reserve left!");
    reserve -= uint80(claimable);

    // update claimer
    claimers[msg.sender] = me;

    // send token
    IERC20Tree(tree).transfer(msg.sender, claimable);  // we trust tree (no re-entrancy)
    emit Claimed(msg.sender, uint80(claimable));

    return true;
  }
}