/**
 *Submitted for verification at FtmScan.com on 2022-05-25
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

contract TestContract {
    uint256 public lastReported = 0;
    address public caller;

    constructor() {

    }

    function report() public {

        uint256 newReport = getNewReport();
        lastReported = newReport;
        caller = msg.sender;

    }

    function trigger() public view returns(bool) {
        uint256 newReport = getNewReport();

        if (newReport > lastReported) {
            return true;
        }
        return false;
    }

    function getNewReport() public view returns(uint256) {
        return block.timestamp / 300 * 300;
    }

}