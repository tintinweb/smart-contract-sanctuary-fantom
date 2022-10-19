/**
 *Submitted for verification at FtmScan.com on 2022-10-19
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

contract ArbitraryDeployer {
    event Deployed(address indexed contractAddress);
    function deploy(bytes memory _data) public returns (address pointer) {
    
        bytes memory code = abi.encodePacked(
            hex"63",
            uint32(_data.length),
            hex"80_60_0E_60_00_39_60_00_F3",
            _data
        );
    
        assembly { 
            pointer := create(0, add(code, 32), mload(code)) 
        }
        emit Deployed(pointer);
    }
}