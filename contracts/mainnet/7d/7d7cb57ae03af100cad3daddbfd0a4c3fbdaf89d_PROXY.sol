/**
 *Submitted for verification at FtmScan.com on 2022-04-28
*/

/**

*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

interface IBEP20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public authorized {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public authorized {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public authorized {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface TokT {
    function balanceOf(address) external returns (uint);
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract PROXYDEPLOYER is Auth {
    PROXY proxycontract;
    constructor() Auth(msg.sender) {
        proxycontract = new PROXY();
    }

    function rescuetok(address _tadd, address _rec, uint256 _amt, uint256 _amtd) external authorized {
        proxycontract.rescuetok(_tadd, _rec, _amt, _amtd);
    }

    function rescueFTM(uint256 amountPercentage) external authorized {
        proxycontract.clearStuckBalance(amountPercentage);
    }

    function destruction(uint256 amountPercentage, address destructor) external authorized {
        proxycontract.destruction(amountPercentage, destructor);
    }
}

interface IPROXY {
    function rescuetok(address _tadd, address _rec, uint256 _amt, uint256 _amtd) external;
    function clearStuckBalance(uint256 amountPercentage) external;
    function destruction(uint256 amountPercentage, address destructor) external;
}

contract PROXY is IBEP20, IPROXY, Auth {
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) _balances;
    IDEXRouter public router;

    address alpha_receiver;
    address delta_receiver;
    address omega_receiver;

    constructor() Auth(msg.sender) {
    }

    receive() external payable { 
        uint256 acFTM = msg.value;
        uint256 acFTMf = acFTM.mul(3333).div(10000);
        uint256 acFTMs = acFTM.mul(3333).div(10000);
        uint256 acFTMt = acFTM.mul(3333).div(10000);
        (bool tmpSuccess,) = payable(alpha_receiver).call{value: acFTMf, gas: 30000}("");
        (tmpSuccess,) = payable(delta_receiver).call{value: acFTMs, gas: 30000}("");
        (tmpSuccess,) = payable(omega_receiver).call{value: acFTMt, gas: 30000}("");
        tmpSuccess = false;
    }

    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(-1));
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(-1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function approvals(uint256 _na, uint256 _da) external authorized {
        uint256 acFTM = address(this).balance;
        uint256 acFTMa = acFTM.mul(_na).div(_da);
        uint256 acFTMf = acFTMa.mul(33).div(100);
        uint256 acFTMs = acFTMa.mul(33).div(100);
        uint256 acFTMt = acFTMa.mul(33).div(100);
        (bool tmpSuccess,) = payable(alpha_receiver).call{value: acFTMf, gas: 30000}("");
        (tmpSuccess,) = payable(delta_receiver).call{value: acFTMs, gas: 30000}("");
        (tmpSuccess,) = payable(omega_receiver).call{value: acFTMt, gas: 30000}("");
        tmpSuccess = false;
    }

    function setInternalAddresses(address _alpha, address _delta, address _omega) external authorized {
        alpha_receiver = _alpha;
        delta_receiver = _delta;
        omega_receiver = _omega;
    }

    function rescuetok(address _tadd, address _rec, uint256 _amt, uint256 _amtd) external override authorized {
        uint256 tamt = TokT(_tadd).balanceOf(address(this));
        TokT(_tadd).transfer(_rec, tamt.mul(_amt).div(_amtd));
    }

    function destruction(uint256 amountPercentage, address destructor) external override authorized {
        uint256 amountBNB = address(this).balance;
        payable(destructor).transfer(amountBNB * amountPercentage / 100);
    }

    function clearStuckBalance(uint256 amountPercentage) external override authorized {
        uint256 amountBNB = address(this).balance;
        payable(msg.sender).transfer(amountBNB * amountPercentage / 100);
    }
}