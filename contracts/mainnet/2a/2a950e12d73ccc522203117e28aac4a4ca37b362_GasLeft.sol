/**
 *Submitted for verification at FtmScan.com on 2022-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract GasLeft {
    function gasLeft() external view returns (uint256) {
        return gasleft();
    }
}