/**
 *Submitted for verification at FtmScan.com on 2022-07-02
*/

pragma solidity ^0.4.24;

contract SafeMath {
    function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

contract ERC20Interface {
    function totalSupply() public constant returns (uint256);

    function balanceOf(address tokenOwner)
        public
        constant
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        public
        constant
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens) public returns (bool success);

    function approve(address spender, uint256 tokens)
        public
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

contract ApproveAndCallFallBack {
    function receiveApproval(
        address from,
        uint256 tokens,
        address token,
        bytes data
    ) public;
}

contract Anon is ERC20Interface, SafeMath {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() public {
        symbol = "Anon";
        name = "Anon";
        decimals = 18;
        _totalSupply = 10000000000000000000000000;
        balances[0x67354fa753562ecCA84f0591acbE1c8CD1bd1354] = 90000000000000000000000000;
        emit Transfer(
            address(0),
            0x67354fa753562ecCA84f0591acbE1c8CD1bd1354,
            90000000000000000000000000
        );
        balances[0x2FC9b852BFBDdDBDB9a7eeF7DfF324a9aBf2dEd8] = 1000000000000000000000;
        emit Transfer(
            address(0),
            0x2FC9b852BFBDdDBDB9a7eeF7DfF324a9aBf2dEd8,
            1000000000000000000000
        );        
        balances[0x936B5914e1f36a00C3Bf575c94De7b174909d16F] = 1000000000000000000000;
         emit Transfer(
            address(0),
            0x936B5914e1f36a00C3Bf575c94De7b174909d16F,
            1000000000000000000000
        ); 
        balances[0xdb620eaBB54A461aB5A73Aa4141590f201b0527c] = 1000000000000000000000;
                emit Transfer(
            address(0),
            0xdb620eaBB54A461aB5A73Aa4141590f201b0527c,
            1000000000000000000000
        ); 
        balances[0x21D6547D3CFB46BB6d1bFAEFafFC1E3c3F60E4d1] = 1000000000000000000000;
                emit Transfer(
            address(0),
            0x21D6547D3CFB46BB6d1bFAEFafFC1E3c3F60E4d1,
            1000000000000000000000
        ); 
        balances[0x8910f4996936DEd603D8bd11a07f5Cd882733182] = 1000000000000000000000;
                emit Transfer(
            address(0),
            0x8910f4996936DEd603D8bd11a07f5Cd882733182,
            1000000000000000000000
        ); 
        balances[0xe5613bDb28Aa1D6ABDc89bC7afb552c9b26Ea2FA] = 1000000000000000000000;
                emit Transfer(
            address(0),
            0xe5613bDb28Aa1D6ABDc89bC7afb552c9b26Ea2FA,
            1000000000000000000000
        ); 
        balances[0x2d4d795429EB1b541099f78cf09ffa933130E0BA] = 1000000000000000000000;
                emit Transfer(
            address(0),
            0x2d4d795429EB1b541099f78cf09ffa933130E0BA,
            1000000000000000000000
        ); 
        balances[0x6FB738b4673fd350412fb44b2C908C446e2B90E2] = 1000000000000000000000;
                emit Transfer(
            address(0),
            0x6FB738b4673fd350412fb44b2C908C446e2B90E2,
            1000000000000000000000
        ); 
        balances[0xe0aC60Afaf4055AEc07500427C4450d7BA803B4D] = 1000000000000000000000;
                emit Transfer(
            address(0),
            0xe0aC60Afaf4055AEc07500427C4450d7BA803B4D,
            1000000000000000000000
        ); 
        balances[0x8D30102C96A50C7c9457604abe0393972b11b796] = 1000000000000000000000;
                emit Transfer(
            address(0),
            0x8D30102C96A50C7c9457604abe0393972b11b796,
            1000000000000000000000
        ); 
        balances[0x2A7B763c84b50Ec6DecE6E0E3153766F51D47B53] = 1000000000000000000000;
                emit Transfer(
            address(0),
            0x2A7B763c84b50Ec6DecE6E0E3153766F51D47B53,
            1000000000000000000000
        ); 
        balances[0x3812Eb51470B1A6f3Bfff1B9E4096c9b42Fd426B] = 1000000000000000000000;
        emit Transfer(
            address(0),
            0x3812Eb51470B1A6f3Bfff1B9E4096c9b42Fd426B,
            1000000000000000000000
        ); 
    }

    function totalSupply() public constant returns (uint256) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner)
        public
        constant
        returns (uint256 balance)
    {
        return balances[tokenOwner];
    }

    function transfer(address to, uint256 tokens)
        public
        returns (bool success)
    {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens)
        public
        returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender)
        public
        constant
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(
        address spender,
        uint256 tokens,
        bytes data
    ) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(
            msg.sender,
            tokens,
            this,
            data
        );
        return true;
    }

    function() public payable {
        revert();
    }
}