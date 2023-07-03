/**
 *Submitted for verification at FtmScan.com on 2023-07-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserRegistration {
    /** 
     * @dev Private variables
    */
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    struct User {
        address walletAddress;
        string name;
    }

    mapping(address => User) public users;

    modifier nonReentrancy() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;

        _status = _NOT_ENTERED;
    }

    event UserRegistered(address indexed walletAddress, string name);
    event UserUpdated(address indexed walletAddress, string name);
    event UserDeleted(address indexed walletAddress);

    constructor() {
        _status = _NOT_ENTERED;
    }

    function registerUser(string memory _name) external nonReentrancy {
        require(users[msg.sender].walletAddress == address(0), "User already registered");
        
        User storage newUser = users[msg.sender];
        newUser.walletAddress = msg.sender;
        newUser.name = _name;

        emit UserRegistered(msg.sender, _name);
    }

    function getUserDetails() external view returns (string memory) {
        User memory user = users[msg.sender];
        require(user.walletAddress != address(0), "User not found");
        
        return (user.name);
    }

    function updateUser(string memory _name) external {
        User storage user = users[msg.sender];
        require(user.walletAddress != address(0), "User not found");

        user.name = _name;

        emit UserUpdated(msg.sender, _name);
    }

    function deleteUser() external {
        require(users[msg.sender].walletAddress != address(0), "User not found");

        delete users[msg.sender];

        emit UserDeleted(msg.sender);
    }

    
}