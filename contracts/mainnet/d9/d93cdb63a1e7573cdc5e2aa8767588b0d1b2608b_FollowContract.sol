/**
 *Submitted for verification at FtmScan.com on 2022-10-27
*/

// Follow.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * A simple Follow implementation
 *
 * Bob can follow(Alice) and unfollow(Alice)
 *
 * This is not a good idea to copy and deploy your own version of that contract.
 * The whole point of that contract is to be unique.
 * Simply use that deployed contract in your Web3 application to make it social.
 * If Bob has already followed Alice in another Web3 social app, then Bob will be
 * following Alice in your application too.
 * Please, don't tie the followers of your users to your application.
 * If Alice has 10 000 followers via your application, then, let her followers be hers:
 * meaning, if she goes to another app, she should be able to keep her followers with her.
 *
 * Don't keep a Web2 mindset. This is Web3 now.
 * Our users should have the power over our apps.
 *
 *
 * Owner powers:
 *   - none
 *
 * Governance:
 *   - none
 *
 * This contract has been deployed on Fantom at address:
 * 0xD93CDb63A1e7573CDc5e2AA8767588B0d1b2608B
 * By MetaZebre:
 * 0xedB00816FB204b4CD9bCb45FF2EF693E99723484
 *
 * To discuss about this contract, go to:
 * https://cherrific.io/0xedB00816FB204b4CD9bCb45FF2EF693E99723484/story/27
 *
 * Please, follow me on ... Fantom !!!  :-D
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



contract FollowContract is Ownable {

  // ----- Events -----
  event Follow    (address indexed follower, address indexed followed);
  event Unfollow  (address indexed follower, address indexed followed);


  // ----- Structs -----
  // 1 slot
  // describes the following link
  struct Followage {
    uint40  timestamp;
    uint40  order;
    // 176 bits left: what could we do with them?
  }

  // describes a user
  struct User {
    uint40 followers; // nb of followers
    uint40 following; // nb of following
    uint40 orderCount; // for ordering of followers
    uint40 lastUpdate; // time the user was last updated
    // 96 bits left: what could we do with them
  }


  // ----- Storage -----

  // mapping of users
  // users[userAddress] = {followers, following}
  mapping(address => User) public users;

  // mapping of follows
  // followers[followerAddres][followedAddress] = {timestamp, order}
  mapping(address => mapping(address => Followage)) public follows;


  // ----- Governance -----
  // nothing

  // ----- Views -----
  // direct access to public storage


  // ----- Mutators -----
  function follow(address followed_) external returns (bool) {
    Followage memory fol = follows[msg.sender][followed_];

    // already following
    if (fol.timestamp > 0) {
      return false;
    }

    // update followed user
    User memory target = users[followed_];
    target.followers  += 1;
    target.orderCount += 1;
    target.lastUpdate = uint40(block.timestamp);
    users[followed_] = target;

    // update follower user
    User memory follower = users[msg.sender];
    follower.following += 1;
    follower.lastUpdate = uint40(block.timestamp);
    users[msg.sender] = follower;

    // add follow
    fol.order = target.orderCount;
    fol.timestamp = uint40(block.timestamp);
    follows[msg.sender][followed_] = fol;

    emit Follow(msg.sender, followed_);

    return true;
  }

  function unfollow(address followed_) external returns (bool) {
    Followage memory fol = follows[msg.sender][followed_];

    // not already following
    if (fol.timestamp == 0) {
      return false;
    }

    // update followed user
    User memory target = users[followed_];
    target.followers  -= 1;
    target.lastUpdate = uint40(block.timestamp);
    users[followed_] = target;

    // update follower user
    User memory follower = users[msg.sender];
    follower.following -= 1;
    follower.lastUpdate = uint40(block.timestamp);
    users[msg.sender] = follower;

    // remove follow
    delete follows[msg.sender][followed_];

    emit Unfollow(msg.sender, followed_);

    return true;
  }

}