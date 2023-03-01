/**
 *Submitted for verification at FtmScan.com on 2023-02-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IUserInfo {
    struct UserInfo {
        uint amount;
        uint rewardDebt;
    }
}

interface IMasterChefV2 is IUserInfo {
    function deposit(uint pid, uint amount, address to) external;
    function withdraw(uint pid, uint amount, address to) external;
    function userInfo(uint pid, address account) external view returns (UserInfo memory);
}

contract SpookyDepositTest is IUserInfo {
    address constant masterChefV2 = 0x18b4f774fdC7BF685daeeF66c2990b1dDd9ea6aD;

    mapping(address => uint) pidByPairAddress;
    mapping(address => uint) balance;

    address immutable owner;

    modifier onlyOwner {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier pidCheck(address pair) {
        require(pidByPairAddress[pair] != 0, "No pid for this pair");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setPid(address pair, uint pid) onlyOwner public {
        pidByPairAddress[pair] = pid;
    }

    function approve(address pair, uint amount) public {
        IERC20(pair).approve(address(this), amount);
    }

    function transfer(address pair, uint amount) public {
        IERC20(pair).transferFrom(msg.sender, address(this), amount);
        balance[msg.sender] += amount;
    }

    function deposit(uint pid, uint amount) public {
        IMasterChefV2(masterChefV2).deposit(pid, amount, msg.sender);
    }

    function deposit(address pair, uint amount) pidCheck(pair) public {
        approve(pair, amount);
        transfer(pair, amount);
        deposit(pidByPairAddress[pair], amount);
    }

    function withdrawAll(address pair) pidCheck(pair) public {
        UserInfo memory userInfo = IMasterChefV2(masterChefV2).userInfo(pidByPairAddress[pair], msg.sender);
        assert(userInfo.amount > 0);
        assert(balance[msg.sender] >= userInfo.amount);
        balance[msg.sender] -= userInfo.amount;
        IMasterChefV2(masterChefV2).withdraw(pidByPairAddress[pair], userInfo.amount, msg.sender);
        IERC20(pair).transfer(msg.sender, userInfo.amount);
    }
}