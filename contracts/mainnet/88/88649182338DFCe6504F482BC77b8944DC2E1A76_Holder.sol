// Be name Khoda
// Bime Abolfazl
// SPDX-License-Identifier: MIT

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ==================== Holder ===================
// ==============================================
// DEUS Finance: https://github.com/deusfinance

// Primary Author(s)
// Mmd: https://github.com/mmd-motafaee

pragma solidity 0.6.12;

interface LpDepositor {
    function getReward(address[] calldata pools) external;
}

interface HIERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract Holder {
    LpDepositor public lpDepositor;
    address public lender;
    address public user;

    constructor(
        address lpDepositor_,
        address lender_,
        address user_
    ) public {
        lpDepositor = LpDepositor(lpDepositor_);
        lender = lender_;
        user = user_;
    }

    function claim(address[] calldata pools) public {
        lpDepositor.getReward(pools);
    }

    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(msg.sender == lender, "SolidexHolder: You are not lender");
        HIERC20(token).transfer(to, amount);
        return true;
    }
}

//Dar panah khoda