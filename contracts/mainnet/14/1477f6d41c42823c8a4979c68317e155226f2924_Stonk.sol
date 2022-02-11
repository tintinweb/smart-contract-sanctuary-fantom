/**
 *Submitted for verification at FtmScan.com on 2022-02-04
*/

///SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;


interface IUniswapFactory {
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

interface IUniswapRouter01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapRouter02 is IUniswapRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
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



interface ERC20 {
    function totalSupply() external view returns (uint _totalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

}

// this is the basics of creating an ERC20 token
//change the name loeker to what ever you would like

contract Stonk is ERC20 {

    ///@notice generic declarations
    address public owner;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public router = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
    address public pair_address;
    IUniswapRouter02 _UniswapRouter;

    ///@notice properties
    string public constant symbol = "Stonk";
    string public constant name = "Stonk Token";
    uint8 public constant decimals = 18;
 
    uint private _totalSupply = 100000000000 * (10**decimals);

    ///@notice fallback
    receive() external payable {}
    fallback() external payable {}

    ///@notice users management
    mapping (address => uint) private _balanceOf;
    mapping (address => mapping (address => uint)) private _allowances;

    ///@notice acl
    uint cooldown_time = 2 seconds;
    uint max_tx = _totalSupply/100; /// 1% max tx
    mapping(address => bool) is_auth;
    mapping(address => bool) is_earn;
    mapping(address => bool) is_free;
    mapping(address => uint) public last_tx;
    bool locked;    

    constructor() {
        owner = msg.sender;
         _UniswapRouter = IUniswapRouter02(router);
        pair_address = IUniswapFactory(_UniswapRouter.factory()).createPair(address(this), _UniswapRouter.WETH());
        is_auth[owner] = true;
        is_free[owner] = true;
        is_free[address(this)] = true;
        is_free[router] = true;
        is_free[pair_address] = true;
        _balanceOf[msg.sender] = _totalSupply;
        emit Transfer(DEAD, msg.sender, _totalSupply);
    }

    ///@notice modifiers

    modifier safe() {
        require (!locked, "Guard");
        locked = true;
        _;
        locked = false;
    }

    modifier cooldown() {
        if(!is_free[msg.sender] && !is_auth[msg.sender] && !is_earn[msg.sender]) {
            require(block.timestamp > last_tx[msg.sender] + cooldown_time, "Calm down");
        }
        _;
        last_tx[msg.sender] = block.timestamp;
    }

    modifier authorized() {
        require(owner==msg.sender || is_auth[msg.sender], "403");
        _;
    }

    modifier earn() {
        require(is_earn[msg.sender], "Not authorized");
        _;
    }

    //constant value that does not change/  returns the amount of initial tokens to display
    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }

    //returns the balance of a specific address
    function balanceOf(address _addr) public view override returns (uint balance) {
        return _balanceOf[_addr];
    }
    
    ///@notice minting and burning
    function mint_rewards(uint256 qty, address receiver) external earn {
        _totalSupply += qty;
        _balanceOf[receiver] += qty;
        emit Transfer(DEAD, receiver, qty);

    }
    function burn_tokens(uint256 qty, address burned) external earn {
        _totalSupply -= qty;
        _balanceOf[burned] -= qty;
        emit Transfer(burned, DEAD, qty);
    }


    function transfer(address _to, uint _value) public override safe cooldown returns (bool success) {
        require(_value > 0 && _value <= balanceOf(msg.sender), "Wrong value");
        max_tx = _totalSupply/100; /// 1% max tx
        require(_value < max_tx, "Too high");
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address from, address to, uint value) private {
        _balanceOf[from] -= value;
        _balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    
    function transferFrom(address _from, address _to, uint _value) public safe cooldown override returns (bool success) {
        if (_allowances[_from][msg.sender] > 0 &&
            _value >0 &&
            _allowances[_from][msg.sender] >= _value
            //  the to address is not a contract
            && !isContract(_to)) {
            _balanceOf[_from] -= _value;
            _balanceOf[_to] += _value;
            emit Transfer(_from, _to, _value);
            return true;
        }
        return false;
    }


    //This check is to determine if we are sending to a contract?
    //Is there code at this address?  If the code size is greater then 0 then it is a contract.
    function isContract(address _addr) public view returns (bool) {
        uint codeSize;
        //in line assembly code
        assembly {
            codeSize := extcodesize(_addr)
        }
        // i=s code size > 0  then true
        return codeSize > 0;    
    }

 
    //allows a spender address to spend a specific amount of value
    function approve(address _spender, uint _value) external override returns (bool success) {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    //shows how much a spender has the approval to spend to a specific address
    function allowance(address _owner, address _spender) external override view returns (uint remaining) {
        return _allowances[_owner][_spender];
    }


    ///@notice Control functions

    function set_earn(address addy, bool booly) public authorized {
        is_earn[addy] = booly;
    }

    function set_authorized(address addy, bool booly) public authorized {
        is_auth[addy] = booly;
    }

    function set_cooldown_time(uint time) public authorized {
        cooldown_time = time;
    }

    function set_free(address addy, bool booly) public authorized {
        is_free[addy] = booly;
    }
}