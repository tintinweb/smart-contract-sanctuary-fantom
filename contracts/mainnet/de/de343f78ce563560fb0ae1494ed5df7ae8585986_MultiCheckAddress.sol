/**
 *Submitted for verification at FtmScan.com on 2023-06-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

contract MultiCheckAddress {

    struct CallResult {
        bytes data;
    }

    function getMultiCode(address[] memory _addresses) public view returns (bytes[] memory) {
        bytes[] memory codes = new bytes[](_addresses.length);

        for(uint256 i = 0; i < _addresses.length; i++) {
            codes[i] = _addresses[i].code;
        }

        return codes;
    }

    function getCode(address _address) public view returns (bytes memory) {
        return _address.code;
    }
}