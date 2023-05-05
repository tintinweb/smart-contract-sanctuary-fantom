/**
 *Submitted for verification at FtmScan.com on 2023-05-05
*/

pragma solidity ^0.8.0;

interface Token {
    function transfer(address _to, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
}

contract TokenVault {
    address private owner;
    address private deadAddress = 0x000000000000000000000000000000000000dEaD;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function withdrawTokens(address tokenAddress, uint256 amount) public onlyOwner {
        Token(tokenAddress).transfer(owner, amount);
    }

    function withdrawAllTokens(address tokenAddress) public onlyOwner {
        uint256 balance = Token(tokenAddress).balanceOf(address(this));
        Token(tokenAddress).transfer(owner, balance);
    }


    function createDeadAddress() public onlyOwner returns (address) {
        address payable newAddress = payable(address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))))));
        newAddress.transfer(address(this).balance);
        return newAddress;
    }
}