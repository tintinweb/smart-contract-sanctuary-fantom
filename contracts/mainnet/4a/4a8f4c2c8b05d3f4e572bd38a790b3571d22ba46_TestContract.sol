/**
 *Submitted for verification at FtmScan.com on 2022-06-01
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

contract TestContract {
    uint256 public lastReported = 0;
    address public keeper = 0x6EDe1597c05A0ca77031cBA43Ab887ccf24cd7e8;
    address public caller;

    constructor() {

    }

    modifier onlyKeeper() {
        require(msg.sender == keeper);
        _;
    }

    function harvest() public onlyKeeper {

        uint256 newReport = getNewReport();
        lastReported = newReport;
        caller = msg.sender;

    }

    function harvestTrigger(uint256 callCost) public view returns(bool) {
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