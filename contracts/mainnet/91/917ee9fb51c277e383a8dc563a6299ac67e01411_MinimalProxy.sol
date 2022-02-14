/**
 *Submitted for verification at FtmScan.com on 2022-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// EIP-1167
contract MinimalProxy {
    function cloneWithTemplateAddress(address templateAddress)
        external
        returns (address poolAddress)
    {
        bytes20 _templateAddress = bytes20(templateAddress);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), _templateAddress)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            poolAddress := create(0, clone, 0x37)
        }
    }
}