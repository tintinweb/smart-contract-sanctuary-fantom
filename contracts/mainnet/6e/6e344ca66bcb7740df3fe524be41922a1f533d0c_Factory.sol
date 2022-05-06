/**
 *Submitted for verification at FtmScan.com on 2022-05-06
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

contract DeployCreate2 {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function destroy() external onlyOwner {
        selfdestruct(payable(owner));
    }
}

contract Factory {
    event Deploy(address a);

    function deploy (uint256 _salt) external {
        DeployCreate2 _contract = new DeployCreate2 {
            salt: bytes32(_salt)
        }(msg.sender);
        emit Deploy(address(_contract));
    }

    function getAddress(bytes memory bytecode, uint256 _salt) public view returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode)));
        return address(uint160(uint256(hash)));
    }

    function getByteCode(address _owner) public pure returns (bytes memory) {
        bytes memory bytecode = type(DeployCreate2).creationCode;
        return abi.encodePacked(bytecode, abi.encode(_owner));
    }
}