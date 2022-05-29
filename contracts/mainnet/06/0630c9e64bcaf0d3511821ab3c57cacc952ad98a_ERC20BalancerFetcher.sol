/**
 *Submitted for verification at FtmScan.com on 2022-05-28
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract ERC20BalancerFetcher {
    function withdraw(
        address user,
        address[] memory tokens
    ) external view returns (uint256[] memory) {
        uint256[] memory result;
        uint256 len = tokens.length;

        for (uint256 i = 0; i < len; ++i) {
            result[i] = IERC20(tokens[i]).balanceOf(user);
        }

        return result;
    }
}