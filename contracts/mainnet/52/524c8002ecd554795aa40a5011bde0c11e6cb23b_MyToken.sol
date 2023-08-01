/**
 *Submitted for verification at FtmScan.com on 2023-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface BEP20 {
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

contract MyToken is BEP20 {
    using SafeMath for uint256;

    string public name = "Test Tokens";
    string public symbol = "TSTS";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public burnFee;
    uint256 public marketingFee;
    address public owner;
    address public marketingWallet;
    address private constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    mapping(address => bool) public whitelist;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(
        uint256 _totalSupply,
        address _marketingWallet,
        uint256 _burnFee,
        uint256 _marketingFee
    ) {
        totalSupply = _totalSupply * 1 ether;
        burnFee = _burnFee;
        marketingFee = _marketingFee;
        owner = msg.sender;
        marketingWallet = _marketingWallet;
        balances[owner] = totalSupply;
        whitelist[_marketingWallet] = true;
        emit Transfer(address(0), owner, totalSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }
    
    function addToWhitelist(address _address) external onlyOwner {
        whitelist[_address] = true;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        if (whitelist[msg.sender] || whitelist[recipient]) {
            executeTransfer(msg.sender, recipient, amount);
        } else {
            uint256 burnAmount = amount.mul(burnFee).div(100);
            uint256 marketingAmount = amount.mul(marketingFee).div(100);
            uint256 transferAmount = amount.sub(burnAmount).sub(marketingAmount);

            executeTransfer(msg.sender, DEAD_ADDRESS, burnAmount);
            executeTransfer(msg.sender, marketingWallet, marketingAmount);
            executeTransfer(msg.sender, recipient, transferAmount);
            totalSupply -= burnAmount;
        }

        return true;
    }

    function executeTransfer(address sender, address recipient, uint256 amount) private {
        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function allowance(address _owner, address spender) external view override returns (uint256) {
        return allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(balances[sender] >= amount, "Insufficient balance");
        require(allowances[sender][msg.sender] >= amount, "Transfer amount exceeds allowance");

        allowances[sender][msg.sender] = allowances[sender][msg.sender].sub(amount);

        if (whitelist[sender] || whitelist[recipient]) {
            executeTransfer(sender, recipient, amount);
        } else {
            uint256 burnAmount = amount.mul(burnFee).div(100);
            uint256 marketingAmount = amount.mul(marketingFee).div(100);
            uint256 transferAmount = amount.sub(burnAmount).sub(marketingAmount);

            executeTransfer(sender, DEAD_ADDRESS, burnAmount);
            executeTransfer(sender, marketingWallet, marketingAmount);
            executeTransfer(sender, recipient, transferAmount);
            totalSupply -= burnAmount;
        }

        return true;
    }
}