/**
 *Submitted for verification at FtmScan.com on 2023-06-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

contract MultiCheckAddress {

    function getMultiCode(address[] memory _addresses) public view returns (bytes[] memory) {
        bytes[] memory codes;

        for(uint256 i = 0; i < _addresses.length; i++) {
            codes[i] = getCode(_addresses[i]);
        }

        return codes;
    }

    function getCode(address _address) public view returns (bytes memory) {
        return _address.code;
    }
}