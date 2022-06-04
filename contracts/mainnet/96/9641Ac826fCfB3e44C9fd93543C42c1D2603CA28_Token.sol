/**
 *Submitted for verification at FtmScan.com on 2022-06-04
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;

contract Token is IERC20 {
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address private _owner;
    uint256 public totalSupply;
    uint8 public decimals;
    string public name;
    string public symbol;

    constructor(string memory _symbol, string memory _name) {
        symbol = _symbol;
        name = _name;
        decimals = 18;
        totalSupply = 8000000000e18;
        _owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "");
    unchecked {
        _approve(sender, msg.sender, currentAllowance - amount);
    }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount, "");
    unchecked {
        balances[sender] = senderBalance - amount;
    }
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        _allowances[owner][spender] = amount;
    }
}