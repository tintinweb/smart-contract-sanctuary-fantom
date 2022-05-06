/**
 *Submitted for verification at FtmScan.com on 2022-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

struct ClaimableInfo {
        bytes32 stakeId;
        address token;
        uint256 amount;
    }

interface IStaking {
    function claim(bytes32 stakeId) external;
    function claimable(bytes32 stakeId) external view returns (ClaimableInfo memory);
    function stakeIds(address account) external view returns (bytes32[] memory);
}

contract Claimer {
    IStaking public constant staking = IStaking(0xA3830399642BafFfC79F8F1AFA85175C42B1F547);

    function claim(address account, uint256 startIndex, uint256 count) public {
        bytes32[] memory stakeIds = staking.stakeIds(account);

        uint256 processed = 0;
        for (uint256 i = startIndex; i < stakeIds.length; i++) {
            staking.claim(stakeIds[i]);

            if (++processed >= count) {
                break;
            }
        }
    }
}