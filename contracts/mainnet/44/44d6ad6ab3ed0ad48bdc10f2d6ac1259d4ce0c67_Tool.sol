/**
 *Submitted for verification at FtmScan.com on 2023-01-17
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

contract Tool {

    function getTimestampBlockNumber() external view returns (uint256, uint256) {
        return (block.timestamp, block.number);
    }

    function getBlockNumber() external view returns (uint256) {
        return block.number;
    }

    function getTimestamp() external view returns (uint256) {
        return block.timestamp;
    }
}