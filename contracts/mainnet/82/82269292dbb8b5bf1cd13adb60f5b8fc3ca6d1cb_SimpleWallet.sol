/**
 *Submitted for verification at FtmScan.com on 2023-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract SimpleWallet {
    mapping(address => bool) private isOwner;

    constructor() {
        isOwner[msg.sender] = true;
    }

    function execute(
        address to,
        uint256 value,
        bytes memory data,
        bool operation
    ) external returns (bool success) {
        require(isOwner[msg.sender]);
        if (operation) {
            assembly {
                success := delegatecall(
                    gas(),
                    to,
                    add(data, 0x20),
                    mload(data),
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
                    add(data, 0x20),
                    mload(data),
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