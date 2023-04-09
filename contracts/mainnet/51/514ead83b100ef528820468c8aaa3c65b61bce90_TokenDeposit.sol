/**
 *Submitted for verification at FtmScan.com on 2023-04-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function _setOwner(address newOwner) private {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenDeposit is Ownable {
    IERC20 public token;

    mapping(address => uint256) public deposits;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(IERC20 _token) {
        token = _token;
    }

    function deposit(uint256 _amount) external {
        require(_amount > 0, "Deposit amount must be greater than 0");
        token.transferFrom(msg.sender, address(this), _amount);
        deposits[msg.sender] += _amount;
        emit Deposit(msg.sender, _amount);
    }

    function withdrawTokens(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Withdraw amount must be greater than 0");
        require(token.balanceOf(address(this)) >= _amount, "Not enough tokens in contract");

        token.transfer(owner(), _amount);
        emit Withdraw(owner(), _amount);
    }
}