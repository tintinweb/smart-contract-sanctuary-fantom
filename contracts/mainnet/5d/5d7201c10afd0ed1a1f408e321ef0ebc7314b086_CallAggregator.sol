/**
 *Submitted for verification at FtmScan.com on 2022-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract CallAggregator {
    
    function getProperty(address target, string calldata name) public view returns (bytes memory res) {
        string memory methodSignature = string(abi.encodePacked(name, "()"));
        (bool success, bytes memory result) = target.staticcall(abi.encodeWithSignature(methodSignature));
        if (success) {
            return result;
        }
    }

    function getProperties(address target, string[] calldata names) public view returns (bytes[] memory) {
        uint namesLength = names.length;
        bytes[] memory result = new bytes[](namesLength);
        for (uint i; i < namesLength; i++) {
            bytes memory propertyData = this.getProperty(target, names[i]);
            result[i] = propertyData;
        }
        return result;
    }
}