/**
 *Submitted for verification at FtmScan.com on 2022-04-18
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IDistributor {
    struct Stake {
        address owner;
        IERC20 token;
        uint256 amount;
        uint256 rewardAmount;
        uint256 createdAt;
        uint256 unlockAt;
    }

    function stakeIds(address) external view returns (bytes32[] memory);
    function stakeInfo(bytes32) external view returns (Stake memory);
}

contract wTRTLBalanceChecker {
    IERC20 wTRTL = IERC20(0x6a31Aca4d2f7398F04d9B6ffae2D898d9A8e7938);
    IDistributor distributor = IDistributor(0x9dff61106C617F5D426053B9E323185b79E4216a);

    function decimals() public view returns (uint8) {
        return wTRTL.decimals();
    }

    function name() public view returns (string memory) {
        return wTRTL.name();
    }

    function symbol() public view returns (string memory) {
        return wTRTL.symbol();
    }

    function totalSupply() public view returns (uint256) {
        return wTRTL.totalSupply();
    }

    function balanceOf(address owner) public view returns (uint256) {
        uint256 balance = wTRTL.balanceOf(owner);

        bytes32[] memory stakeIds = distributor.stakeIds(owner);

        for (uint256 i = 0; i < stakeIds.length; i++) {
            IDistributor.Stake memory staked = distributor.stakeInfo(stakeIds[i]);

            if (address(staked.token) == address(wTRTL)) {
                balance += staked.amount;
            }
        }

        return balance;
    }
}