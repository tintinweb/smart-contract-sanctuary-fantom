/**
 *Submitted for verification at FtmScan.com on 2022-02-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File contracts/Test/Test.sol

interface IERC20Metadata {
    function decimals() external view returns (uint8);
}

interface IBeethovenxMasterChef {
    function beetsPerBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);
}

interface IBlockTimeTracker {
    function PRECISION() external view returns (uint8);

    function average() external view returns (uint256);
}

contract BeetsInfo {
    IERC20Metadata public BEETS =
        IERC20Metadata(0xF24Bcf4d1e507740041C9cFd2DddB29585aDCe1e);
    IBeethovenxMasterChef public MASTERCHEF =
        IBeethovenxMasterChef(0x8166994d9ebBe5829EC86Bd81258149B87faCfd3);
    IBlockTimeTracker private tracker =
        IBlockTimeTracker(0x706e05D2b47cc6B1fb615EE76DD3789d2329E22e);

    function info()
        public
        view
        returns (
            uint256 beetsPerBlock,
            uint8 decimals,
            uint256 totalAllocPoint,
            uint256 blocksPerSecond,
            uint8 precision
        )
    {
        beetsPerBlock = MASTERCHEF.beetsPerBlock();
        decimals = BEETS.decimals();
        totalAllocPoint = MASTERCHEF.totalAllocPoint();
        blocksPerSecond = tracker.average();
        precision = tracker.PRECISION();
    }
}