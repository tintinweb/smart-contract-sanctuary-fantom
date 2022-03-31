// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface SmartWalletChecker {
    function check(address) external view returns (bool);
}

contract SmartWalletWhitelist {
    mapping(address => bool) public wallets;
    address public governance;
    address public checker;
    address public future_checker;

    event ApproveWallet(address);
    event RevokeWallet(address);

    constructor(address _governance) public {
        governance = _governance;
    }

    function commitSetChecker(address _checker) external {
        require(msg.sender == governance, "!governance");
        future_checker = _checker;
    }

    function applySetChecker() external {
        require(msg.sender == governance, "!governance");
        checker = future_checker;
    }

    function approveWallet(address _wallet) public {
        require(msg.sender == governance, "!governance");
        wallets[_wallet] = true;

        emit ApproveWallet(_wallet);
    }

    function revokeWallet(address _wallet) external {
        require(msg.sender == governance, "!governance");
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
}