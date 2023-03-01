/**
 *Submitted for verification at FtmScan.com on 2023-02-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract ContractChecker {
    event ForRaste(uint256);

    constructor () {
        emit ForRaste(block.number);
    }

    function getCode(address _addr) external view returns (bytes memory o_code) {
        return _addr.code;
    }

    function isContract(address _addr) external view returns (bool) {
        bytes memory a = _addr.code;
        bytes memory b = hex"";
        return keccak256(a) != keccak256(b);
    }
}