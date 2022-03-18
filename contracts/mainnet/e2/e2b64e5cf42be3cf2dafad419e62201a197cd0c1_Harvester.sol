/**
 *Submitted for verification at FtmScan.com on 2022-03-17
*/

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

contract Harvester {

    function doHardWork() external {
        (bool success,) = 0xC847B4fEab86f69a4766526A2Ce2dE2381bBF4e7.call(abi.encodeWithSignature("doHardWork()"));
        if(success) revert("e");
    }
}