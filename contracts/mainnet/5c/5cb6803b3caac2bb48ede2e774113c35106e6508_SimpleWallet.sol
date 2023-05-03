/**
 *Submitted for verification at FtmScan.com on 2023-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract SimpleWallet {
    uint256 public testVar;
    
    bool private initialized;
    mapping(address => bool) isOwner;

    function initialize() external {
        require(!initialized);
        initialized == true;
        isOwner[msg.sender] = true;
    }

    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        bool operation
    ) external returns (bool success) {
        require(isOwner[msg.sender]);
        if (operation) {
            assembly {
                success := delegatecall(
                    gas(),
                    to,
                    add(data.offset, 0x20),
                    mload(data.offset),
                    0,
                    0
                )
            }
        } else {
            assembly {
                success := call(
                    gas(),
                    to,
                    value,
                    add(data.offset, 0x20),
                    mload(data.offset),
                    0,
                    0
                )
            }
        }
        assembly {
            let returnDataSize := returndatasize()
            returndatacopy(0, 0, returnDataSize)
            switch success
            case 0 {
                revert(0, returnDataSize)
            }
            default {
                return(0, returnDataSize)
            }
        }
    }
}