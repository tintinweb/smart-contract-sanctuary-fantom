/**
 *Submitted for verification at FtmScan.com on 2022-08-09
*/

pragma solidity ^0.4.19;

contract Recover {
  function ecr (bytes32 msgh, uint8 v, bytes32 r, bytes32 s) public pure
  returns (address sender) {
    return ecrecover(msgh, v, r, s);
  }
}