/**
 *Submitted for verification at FtmScan.com on 2022-09-09
*/

// Epoch.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**

Epoch:

Gas optimised version of Epoch contract:
  - 1 constant = period = 6 hours
  - no mutable variable => much less gas

So obviously, all functions are view functions.

No start time: Epoch starts at 1970-01-01T00:00:00Z
like the Unix Epoch.

Owner powers:
  - none

*/



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




contract Epoch is Ownable {

  uint256 public constant  period = 6 hours;

  // ==== Views ====

  // Current epoch number (ordinal)
  function epoch() public view returns (uint256) {
    return block.timestamp / period;
  }

  // Number of seconds since start of current epoch
  function elapsed() public view returns (uint256) {
    return ( block.timestamp ) % period;
  }

  // Number of seconds until next epoch
  // we can save a checkStartTime because it will be performed
  // in elapsed()
  function remaining() public view returns (uint256) {
    return period - elapsed();
  }

  // Time the current epoch started
  function epochStartTime() public view returns (uint256) {
    return block.timestamp - elapsed();
  }

  // Time when next epoch starts
  function nextEpochStartTime() public view returns (uint256) {
    return block.timestamp + period - elapsed();
  }



  /**
   * Same functions with argument in case you want to know
   * the epoch at some specified point in time/
   *
   * The following functions are all pure functions.
   */

  // Computes the epoch for given time
  function epoch(uint256 time_) public pure returns(uint256) {
    return time_ / period;
  }

  // Number of seconds since start of current epoch for given time
  function elapsed(uint256 time_) public pure returns (uint256) {
    return time_ % period;
  }

  // Number of seconds until next epoch given time
  function remaining(uint256 time_) public pure returns (uint256) {
    return period - elapsed(time_);
  }

  // Time the current epoch started given time
  function epochStartTime(uint256 time_) public pure returns (uint256) {
    return time_ - elapsed(time_);
  }

  // Time when next epoch will start given time
  function nextEpochStartTime(uint256 time_) public pure returns (uint256) {
    return time_ + period - elapsed(time_);
  }

}