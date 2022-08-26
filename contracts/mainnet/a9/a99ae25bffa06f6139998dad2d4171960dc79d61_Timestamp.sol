/**
 *Submitted for verification at FtmScan.com on 2022-08-25
*/

pragma solidity 0.6.12;

contract Timestamp {
  function getBlockTimestamp() external view returns (uint) {
    return block.timestamp;
  }
}