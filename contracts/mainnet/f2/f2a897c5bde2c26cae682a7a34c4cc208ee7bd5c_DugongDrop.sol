/**
 *Submitted for verification at FtmScan.com on 2022-12-28
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address recepient, uint256 amount) external returns (bool);
}

contract DugongDrop {
    event SetDrop(address indexed tokenAddr, uint256 tokenDrop);
    event DropEnabled(bool isActive);
    event DropDisabled(bool isActive);
    event Airdrop(address indexed sender, address indexed recepient, uint256 amount);
    event TokenExtracted(address indexed sender, address indexed recepient, uint256 amount);

    address public owner;
    IERC20 public token;
    bool public isActive;
    uint256 public drop;
    uint256 public dropped;
    mapping(address => bool) public claimedDrop;

    constructor() {
        owner = msg.sender;
        isActive = true;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Access Denied, You're not the Owner.");
        _;
    }

    modifier run {
        require(isActive, "Airdrop is Disabled.");
        _;
    }

    function setDrop(address tokenAddr, uint256 tokenDrop) onlyOwner external returns (bool) {
        token = IERC20(tokenAddr);
        drop = tokenDrop;
        emit SetDrop(tokenAddr, tokenDrop);
        return true;
    }

    function enableDrop() onlyOwner external returns (bool) {
        require(!isActive, "Already Enabled.");
        isActive = !isActive;
        emit DropEnabled(isActive);
        return true;
    }
    
    function disableDrop() onlyOwner external returns (bool) {
        require(!isActive, "ALready Disabled.");
        isActive = !isActive;
        emit DropDisabled(isActive);
        return true;
    }

    function airdrop() run external returns (bool) {
        require(!claimedDrop[msg.sender], "Already Claimed.");
        token.transfer(msg.sender, drop);
        emit Airdrop(address(this), msg.sender, drop);
        claimedDrop[msg.sender] = true;
        dropped += drop;
        return true;
    }

    function airdrop(address[] memory recepient) onlyOwner run external returns (bool) {
        require(recepient.length <= 2000, "Reached Limit (Max of 2000 addresses are allowed per transaction).");
        require(token.balanceOf(address(this)) >= recepient.length * drop, "Low Balance.");
        for(uint16 i=0; i<recepient.length; i++) {
            if(!claimedDrop[recepient[i]]) {
                token.transfer(recepient[i], drop);
                emit Airdrop(address(this), msg.sender, drop);
                claimedDrop[recepient[i]] = true;
                dropped += drop;
            }
        }
        return true;
    }

    function extractToken(address recepient, uint256 amount) onlyOwner external returns (bool) {
        require(recepient != address(0), "Address of recepient can't be null/zero address.");
        require(token.balanceOf(address(this)) >= amount, "Low Balance.");
        token.transfer(recepient, amount);
        emit TokenExtracted(address(this), recepient, amount);
        return true;
    }

    receive() external payable{
        payable(owner).transfer(msg.value);
    }
}