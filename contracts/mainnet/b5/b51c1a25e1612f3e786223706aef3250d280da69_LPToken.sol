/**
 *Submitted for verification at FtmScan.com on 2023-01-26
*/

pragma solidity ^0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256);
    function approve(address spender, uint256 tokens) external returns (bool);
    function transfer(address to, uint256 tokens) external returns (bool);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool);
}

contract LPToken is IERC20 {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    address public owner;
    uint256 public totalSupply;
    uint256 public lpTotalSupply;

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event LPCreation(address indexed owner, uint256 tokens);

    constructor() public {
        owner = msg.sender;
        totalSupply = 100000;
        balances[owner] = totalSupply;
    }

    function purchase(address to, uint256 tokens) external {
        require(balances[msg.sender] >= tokens && tokens > 0, "Not enough tokens or invalid amount.");
        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        lpTotalSupply += tokens;
        emit Transfer(msg.sender, to, tokens);
        emit LPCreation(msg.sender, tokens);
    }

    function balanceOf(address tokenOwner) external view returns (uint256) {
        return balances[tokenOwner];
    }

    function approve(address spender, uint256 tokens) external returns (bool) {
        require(tokens > 0, "Invalid amount.");
        allowance[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint256 tokens) external returns (bool) {
        require(balances[msg.sender] >= tokens && tokens > 0, "Not enough tokens or invalid amount.");
        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) external returns (bool) {
        require(allowance[from][msg.sender] >= tokens && balances[from] >= tokens && tokens > 0, "Not enough tokens or invalid amount.");
        allowance[from][msg.sender] -= tokens;
        balances[from] -= tokens;
        balances[to] += tokens;
        emit Transfer(from, to, tokens);
        return true;
    }
}