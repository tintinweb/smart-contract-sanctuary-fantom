/**
 *Submitted for verification at FtmScan.com on 2022-07-21
*/

// SPDX-License-Identifier: Frensware
pragma solidity 0.8.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
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
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address _token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address _token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address private _owner = msg.sender;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function getOwner() external override view returns (address) { return _owner; }
    function name() public override view returns (string memory) { return _name; }
    function decimals() public override view returns (uint8) { return _decimals; }
    function symbol() public override view returns (string memory) { return _symbol; }
    function totalSupply() public override view returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public override view returns (uint256) { return _balances[account]; }
    function allowance(address owner, address spender) public override view returns (uint256) { return _allowances[owner][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract token is ERC20 {
    IUniswapV2Router02 public _router = IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
    address public _pair;
    address private _operator;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    bool private launched;

    //uint256 private _totalSupply;
    uint256 private _baseSupply = 1000000000 * (10 ** 18);
    uint256 private LPRate = 2;
    uint256 private mrktFee = 5;

    mapping(address => bool) whitelisted;
    mapping(address => bool) blacklisted;

    constructor() ERC20("TEST", "T") {
        _operator = msg.sender;
        whitelisted[msg.sender] = true;
        _mint(msg.sender, _baseSupply);
        _pair = IUniswapV2Factory(_router.factory()).createPair(_router.WETH(), address(this));
        _approve(address(this), address(_router), type(uint256).max);
    }

    function operator() public view returns (address) { return _operator; }
    function isBlacklisted(address input) public view returns (bool) { return blacklisted[input]; }
    function isWhitelisted(address input) public view returns (bool) { return whitelisted[input]; }

    receive() external payable {}

    function launch() public onlyOperator { require(!launched); launched = true; }
    function toggleWhitelist(address input) public onlyOperator { whitelisted[input] = !whitelisted[input]; }
    function toggleBlacklist(address input) public onlyOperator { blacklisted[input] = !blacklisted[input]; }

    function updateLPRate(uint256 val) public onlyOperator {
        require(val <= 5);
        LPRate = val;
    }

    function updateMarketingRate(uint256 val) public onlyOperator {
        require(val <= 5);
        mrktFee = val;
    }

    function transferOperator(address newOperator) public onlyOperator { 
        whitelisted[msg.sender] = false;
        whitelisted[newOperator] = true;
        _operator = newOperator; 
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        require(!blacklisted[sender] && !blacklisted[recipient]);
        if(sender == _operator) { super._transfer(sender, recipient, amount); }
        if(_isLPSwap(sender, recipient) == true) { super._transfer(sender, recipient, amount); }
        if(sender == _pair && !launched) { revert("Trading disabled"); }

        if (sender == _pair || recipient == _pair) {
            if (!whitelisted[recipient]) {
                uint256 liquidityAmount = (amount * LPRate) / 100;
                uint256 opAmount = (amount * mrktFee) / 100;
                uint256 taxAmount = liquidityAmount + opAmount;
                uint256 sendAmount = amount - taxAmount;

                super._transfer(sender, address(this), opAmount);
                    _teamSwap(opAmount);
                super._transfer(sender, address(this), liquidityAmount);
                    _swapForLP(liquidityAmount);
                super._transfer(sender, recipient, sendAmount);   
            }

        } else { super._transfer(sender, recipient, amount); }
    }

    function _teamSwap(uint256 val) internal {
        address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = _router.WETH();

        uint256 spotVal = IERC20(_router.WETH()).balanceOf(address(this));
            _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                val, 0, path, address(this), block.timestamp
            );
        uint256 takeVal = IERC20(_router.WETH()).balanceOf(address(this)) - spotVal;
        IERC20(_router.WETH()).transfer(_operator, takeVal);
    }

    function _swapForLP(uint256 val) internal {
        address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = _router.WETH();
        uint256 spotVal = IERC20(_router.WETH()).balanceOf(address(this));
            _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                val / 2, 0, path, address(this), block.timestamp
            );

        uint256 breakVal = IERC20(_router.WETH()).balanceOf(address(this)) - spotVal;
            IERC20(_router.WETH()).approve(address(_router), breakVal);
            _router.addLiquidity(_router.WETH(), address(this), breakVal, val/2, 0, 0, address(this), block.timestamp);
            IERC20(_pair).transfer(_operator, IERC20(_pair).balanceOf(address(this)));
    }

    function _isLPSwap(address a, address b) internal view returns (bool) {
        require(a == address(this) && b == _pair);
        return true;
    }

    modifier onlyOperator() { require(msg.sender == _operator) ;_; }
}