/**
 *Submitted for verification at FtmScan.com on 2022-05-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

interface ITestContract {
    function trigger() external view returns (bool);
}

contract TestResolver {

    function checker(address testAddress)
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {

        // solhint-disable not-rely-on-time
        canExec = ITestContract(testAddress).trigger();

    }
}