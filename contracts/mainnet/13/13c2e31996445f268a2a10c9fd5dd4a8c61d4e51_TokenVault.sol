/**
 *Submitted for verification at FtmScan.com on 2023-05-05
*/

pragma solidity ^0.8.0;

interface Token {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract TokenVault {
    address public owner;
    address public tokenAddress;
    address public contractAddress;
    mapping(address => uint256) public balances;

    constructor(address _owner, address _tokenAddress) {
        owner = _owner;
        tokenAddress = _tokenAddress;
        contractAddress = address(this);
    }

    function deposit(uint256 _amount) public {
        Token token = Token(tokenAddress);
        require(token.transfer(contractAddress, _amount), "Transfer failed");
        balances[msg.sender] += _amount;
    }

    function withdraw(uint256 _amount) public {
        require(msg.sender == owner, "Only owner can withdraw tokens");
        require(_amount <= balances[msg.sender], "Insufficient balance");
        Token token = Token(tokenAddress);
        require(token.transfer(owner, _amount), "Transfer failed");
        balances[msg.sender] -= _amount;
    }

    function changeContractAddress(address _newContractAddress) public {
        require(msg.sender == owner, "Only owner can change contract address");
        contractAddress = _newContractAddress;
    }

    function balance() public view returns (uint256) {
        Token token = Token(tokenAddress);
        return token.balanceOf(contractAddress);
    }
}