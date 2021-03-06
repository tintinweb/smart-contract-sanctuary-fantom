// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

interface SmartWalletChecker {
    function check(address) external view returns (bool);
}

/// @author RobAnon
contract SmartWalletWhitelistV2 {
    
    mapping(address => bool) public wallets;
    
    bytes32 public constant ADMIN = "ADMIN";

    mapping(address => bytes32) public roles;
    
    address public checker;
    address public future_checker;
    
    event ApproveWallet(address);
    event RevokeWallet(address);
    
    constructor(address _admin) {
        roles[_admin] = ADMIN;
    }
    
    function commitSetChecker(address _checker) external {
        require(isAdmin(msg.sender), "!admin");
        future_checker = _checker;
    }

    function changeAdmin(address _admin, bool validAdmin) external {
        require(isAdmin(msg.sender), "!admin");
        if(validAdmin) {
            roles[_admin] = ADMIN;
        } else {
            roles[_admin] = 0x0;
        }
    }
    
    function applySetChecker() external {
        require(isAdmin(msg.sender), "!admin");
        checker = future_checker;
    }
    
    function approveWallet(address _wallet) public {
        require(isAdmin(msg.sender), "!admin");
        wallets[_wallet] = true;
        
        emit ApproveWallet(_wallet);
    }
    function revokeWallet(address _wallet) external {
        require(isAdmin(msg.sender), "!admin");
        wallets[_wallet] = false;
        
        emit RevokeWallet(_wallet);
    }
    
    function check(address _wallet) external view returns (bool) {
        bool _check = wallets[_wallet];
        if (_check) {
            return _check;
        } else {
            if (checker != address(0)) {
                return SmartWalletChecker(checker).check(_wallet);
            }
        }
        return false;
    }

    function isAdmin(address checkAdd) internal view returns (bool valid) {
        valid = roles[checkAdd] == ADMIN;
    }


    
}