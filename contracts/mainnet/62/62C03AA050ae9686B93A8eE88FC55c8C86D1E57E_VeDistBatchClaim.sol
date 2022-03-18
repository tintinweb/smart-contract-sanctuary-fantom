/**
 *Submitted for verification at FtmScan.com on 2022-03-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVoterProxy {
    function claim() external;
}

contract VeDistBatchClaim {
    address constant voterProxyAddress =
        0xDA0027f2368bA3cb65a494B1fc7EA7Fd05AB42DD;
    IVoterProxy private voterProxy = IVoterProxy(voterProxyAddress);

    function claim(uint256 runs) public {
        for (uint256 runIndex; runIndex < runs; runIndex++) {
            voterProxy.claim();
        }
    }
}