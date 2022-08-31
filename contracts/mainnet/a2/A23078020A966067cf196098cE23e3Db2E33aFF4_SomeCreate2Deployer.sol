// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IProxy {
    function initialize(address) external;
}

contract SomeCreate2Deployer {
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    function deployAndInit(bytes memory code, uint256 salt)
        public
        returns (address)
    {
        address addr;
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        // low-level call 'cause not all of them have initialize
        IProxy(addr).initialize(admin);

        return addr;
    }

    function deploy(bytes memory code, uint256 salt) public returns (address) {
        address addr;
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        return addr;
    }
}