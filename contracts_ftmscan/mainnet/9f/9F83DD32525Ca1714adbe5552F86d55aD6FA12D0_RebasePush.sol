/**
 *Submitted for verification at FtmScan.com on 2022-01-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IStaking {
    function epoch() external view returns (uint256 number, uint256 distribute, uint256 length, uint256 endTime);
    function rebase() external;
}

contract RebasePush {
    IStaking public constant staking = IStaking(0x1a16805c1e60E7bf206304efDF31E7b8a151235B);

    function rebase(uint256 maxIterations) public {
        (,,,uint256 endTime) = staking.epoch();

        if (endTime < block.timestamp) {
            for (uint256 i = 0; i < maxIterations; i++) {
                staking.rebase();
            }
        }
    }
}