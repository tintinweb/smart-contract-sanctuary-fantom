/**
 *Submitted for verification at FtmScan.com on 2023-04-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

interface IERC20 {
    function name() external view returns(string memory);

    function symbol() external view returns(string memory);

    function decimals() external pure returns(uint); // 0

    function totalSupply() external view returns(uint);

    function balanceOf(address account) external view returns(uint);

    function transfer(address to, uint amount) external;

    function allowance(address _owner, address spender) external view returns(uint);

    function approve(address spender, uint amount) external;

    function transferFrom(address sender, address recipient, uint amount) external;

    event Transfer(address indexed from, address indexed to, uint amount);

    event Approve(address indexed owner, address indexed to, uint amount);
}

contract USDPRICEINDEX is IERC20 {
    uint totalTokens;
    //address owner;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;
    string _name;
    string _symbol;
    uint initialSupply;
    address uniswap_oracle;
    //bool usd_first;
    IUniswapV2Pair usd_eth_pair; 

    function UniswapContract() external view returns(address) {
        return uniswap_oracle;
    }

    function name() external view returns(string memory) {
        return _name;
    }

    function symbol() external view returns(string memory) {
        return _symbol;
    }

    function decimals() external pure returns(uint) {
        return 18; // 1 token = 1 wei  
        // updated
    }

    function totalSupply() external view returns(uint) {
        return totalTokens;
    }

    modifier enoughTokens(address _from, uint _amount) {
        require(balanceOf(_from) >= _amount, "not enough tokens!");
        _;
    }

    constructor(string memory name_, string memory symbol_, address _uniswap_oracle) {
        //bool _usd_first
        //usd_first=_usd_first;
        //owner = msg.sender;
        _name = name_;
        _symbol = symbol_;
        uniswap_oracle=_uniswap_oracle;
        usd_eth_pair = IUniswapV2Pair(_uniswap_oracle);
    }

    function UsdPriceRate() public view  returns(uint) {
        //  0x2b4C76d0dc16BE1C31D4C1DC53bF9B45987Fc75c  - USDC/WFTM uniswap Fantom
     //  0xb4e16d0168e52d35cacd2c6185b44281ec28c9dc   - USDC/WETH uniswap v2  Ethereum
     // (uint112 _reserve0, uint112 _reserve1,) = getReserves(); 
     //(uint _reserve0, uint _reserve1)=arithmetic(10, 15);
     (uint112 _reserve0, uint112 _reserve1,) = usd_eth_pair.getReserves();
     // uint112 dec_rate_0= 1000000;
     uint112 dec_rate_1= 1000000000000000000;
     //_reserve0/= dec_rate_0;
      _reserve1/= dec_rate_1;
     uint rate;
     if (dec_rate_1>0) rate=_reserve0/_reserve1;
     return rate;
    }

    function UniswapEthToUSDPrice() public view  returns(uint) {
     (uint112 _reserve0, uint112 _reserve1,) = usd_eth_pair.getReserves();
     uint112 dec_rate_0= 1000000;
     uint112 dec_rate_1= 1000000000000000000;
     _reserve0/= dec_rate_0;
     _reserve1/= dec_rate_1;
     uint rate;
     if (dec_rate_1>0) rate=_reserve0/_reserve1;
    return rate;
    }

    function balanceOf(address account) public view returns(uint) {
        return balances[account];
    }

    function transfer(address to, uint amount) public enoughTokens(msg.sender, amount) {
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }

    function mint(uint amount, address user) internal  {
       // _beforeTokenTransfer(address(0), user, amount);
        balances[user] += amount;
        totalTokens += amount;
        emit Transfer(address(0), user, amount);
    }

    function burn(uint amount) public enoughTokens(msg.sender, amount) {
        //_beforeTokenTransfer(msg.sender, address(0), amount);
        balances[msg.sender] -= amount;
        totalTokens -= amount;
        
    }

    function allowance(address _owner, address spender) public view returns(uint) {
        return allowances[_owner][spender];
    }

    function approve(address spender, uint amount) public {
        _approve(msg.sender, spender, amount);
    }

    function _approve(address sender, address spender, uint amount) internal virtual {
        allowances[sender][spender] = amount;
        emit Approve(sender, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint amount) public enoughTokens(sender, amount) {
        //_beforeTokenTransfer(sender, recipient, amount);
        allowances[sender][msg.sender] -= amount; // error!
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function mintUSDI() external payable {
        uint tokensToBuy= msg.value*UsdPriceRate()/1000000 ; 
        require(tokensToBuy > 0, "not enough funds!");
        mint(tokensToBuy, msg.sender);
        payable(0).transfer(address(this).balance);
 
    }

    receive() external payable {
        uint tokensToBuy= msg.value*UsdPriceRate()/1000000 ; 
        require(tokensToBuy > 0, "not enough funds!");
        mint(tokensToBuy, msg.sender);
        payable(0).transfer(address(this).balance);
     }



}