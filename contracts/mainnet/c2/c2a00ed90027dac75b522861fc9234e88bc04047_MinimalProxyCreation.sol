/**
 *Submitted for verification at FtmScan.com on 2022-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// EIP-1967
contract MinimalUpgradeableProxy {
    bytes32 constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc; // keccak256('eip1967.proxy.implementation')
    bytes32 constant OWNER_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103; // keccak256('eip1967.proxy.admin')

    constructor(address _implementationAddress, address _ownerAddress) {
        assembly {
            sstore(IMPLEMENTATION_SLOT, _implementationAddress)
            sstore(OWNER_SLOT, _ownerAddress)
        }
    }

    function implementationAddress() external view returns (address _ownerAddress) {
        assembly {
            _ownerAddress := sload(IMPLEMENTATION_SLOT)
        }
    }

    function ownerAddress() public view returns (address _ownerAddress) {
        assembly {
            _ownerAddress := sload(OWNER_SLOT)
        }
    }

    function updateImplementationAddress(address _implementationAddress) external {
        require(msg.sender == ownerAddress(), "Only owners can update implementation");
        assembly {
            sstore(IMPLEMENTATION_SLOT, _implementationAddress)
        }
    }

    function updateOwnerAddress(address _ownerAddress) external {
        require(msg.sender == ownerAddress(), "Only owners can update owners");
        assembly {
            sstore(OWNER_SLOT, _ownerAddress)
        }
    }

    fallback() external {
        assembly {
            let contractLogic := sload(IMPLEMENTATION_SLOT)
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(gas(), contractLogic, 0x0, calldatasize(), 0, 0)
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

// EIP-1167
contract MinimalProxyCreation {
    function createNewProxy(address templateAddress, address ownerAddress) external {
        new MinimalUpgradeableProxy(templateAddress, ownerAddress);
    }

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