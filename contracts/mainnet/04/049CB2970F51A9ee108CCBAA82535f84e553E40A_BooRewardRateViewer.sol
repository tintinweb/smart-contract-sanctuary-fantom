/**
 *Submitted for verification at FtmScan.com on 2023-03-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract BooRewardRateViewer {
    IMasterChefV2 constant MCV2 = IMasterChefV2(0x18b4f774fdC7BF685daeeF66c2990b1dDd9ea6aD);
    uint private constant ACC_BOO_PRECISION = 1e12;
    struct Snapshot {
        uint time;
        uint value;
    }
    mapping(uint => Snapshot[]) public history;
    constructor() {}
    function capture(uint pid) external {
        history[pid].push(Snapshot(block.timestamp, getBooRewardRate(pid)));
    }
    function getBooRewardRate(uint pid) public view returns (uint) {
        IMasterChefV2DataTypes.PoolInfo memory poolInfo = MCV2.poolInfo(pid);
        return poolInfo.allocPoint * ACC_BOO_PRECISION / MCV2.totalAllocPoint() * MCV2.booPerSecond() / ACC_BOO_PRECISION;
    }
}

interface IMasterChefV2DataTypes {
    struct UserInfo {
        uint amount;
        uint rewardDebt;
    }
    struct PoolInfo {
        uint128 accBooPerShare;
        uint64 lastRewardTime;
        uint64 allocPoint;
    }
}

interface IMasterChefV2 is IMasterChefV2DataTypes {
    function poolInfo(uint pid) external view returns (PoolInfo memory);
    function totalAllocPoint() external view returns (uint);
    function booPerSecond() external view returns (uint);
}