/**
 *Submitted for verification at FtmScan.com on 2022-07-05
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

contract Rage is ERC20Interface, SafeMath {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() public {
        symbol = "Rage";
        name = "Rage";
        decimals = 18;
        _totalSupply = 10000000000000000000000000;
        balances[0xFcc5dE5E03a6cE8e8f5cC5D65783657c7aADff06] = 90000000000000000000000000;
        emit Transfer(
            address(0),
            0xFcc5dE5E03a6cE8e8f5cC5D65783657c7aADff06,
            90000000000000000000000000
        );
        balances[0x6347Ba74a6D4BAa3F21B502991B047C1F68e1d78] = 1000000000000000000000;
        emit Transfer(address(0), 0x6347Ba74a6D4BAa3F21B502991B047C1F68e1d78, 1000000000000000000000);
        balances[0x18348FBfc00fb9a13F2ab5cf015F079428250c5a] = 1000000000000000000000;
        emit Transfer(address(0), 0x18348FBfc00fb9a13F2ab5cf015F079428250c5a, 1000000000000000000000);
        balances[0x635a816A306aC4948C451849a61916edbBaBbdbb] = 1000000000000000000000;
        emit Transfer(address(0), 0x635a816A306aC4948C451849a61916edbBaBbdbb, 1000000000000000000000);
        balances[0x10464310A3f3cF530f30F720c7EB282da526Becd] = 1000000000000000000000;
        emit Transfer(address(0), 0x10464310A3f3cF530f30F720c7EB282da526Becd, 1000000000000000000000);
        balances[0x9b8Cb737da01A9399Fe66Cdb4350Da051b8Fefce] = 1000000000000000000000;
        emit Transfer(address(0), 0x9b8Cb737da01A9399Fe66Cdb4350Da051b8Fefce, 1000000000000000000000);
        balances[0x0a2117E78943a043A8efF583b2E1aC6A01FA2053] = 1000000000000000000000;
        emit Transfer(address(0), 0x0a2117E78943a043A8efF583b2E1aC6A01FA2053, 1000000000000000000000);
        balances[0x43A21fC22629616aBBCA22eAB85d6A5Ae2D25742] = 1000000000000000000000;
        emit Transfer(address(0), 0x43A21fC22629616aBBCA22eAB85d6A5Ae2D25742, 1000000000000000000000);
        balances[0x773895542BF587f4072FaeF6b45839d2b93913c0] = 1000000000000000000000;
        emit Transfer(address(0), 0x773895542BF587f4072FaeF6b45839d2b93913c0, 1000000000000000000000);
        balances[0xEb6f6AdADA75F3e2b5030474A0E68E94A1bB3946] = 1000000000000000000000;
        emit Transfer(address(0), 0xEb6f6AdADA75F3e2b5030474A0E68E94A1bB3946, 1000000000000000000000);
        balances[0xcB6d9a94485E4EEAadded45Fa44240BcCdf74148] = 1000000000000000000000;
        emit Transfer(address(0), 0xcB6d9a94485E4EEAadded45Fa44240BcCdf74148, 1000000000000000000000);
        balances[0xf8d22cb1995052F4A4149110d7D609347eBBA086] = 1000000000000000000000;
        emit Transfer(address(0), 0xf8d22cb1995052F4A4149110d7D609347eBBA086, 1000000000000000000000);
        balances[0x7cFab71A6D8d62076Ec7b4303895BDD6bb7f1613] = 1000000000000000000000;
        emit Transfer(address(0), 0x7cFab71A6D8d62076Ec7b4303895BDD6bb7f1613, 1000000000000000000000);
        balances[0x9A0284abebC6d212E16C13d0d2B739b848D55121] = 1000000000000000000000;
        emit Transfer(address(0), 0x9A0284abebC6d212E16C13d0d2B739b848D55121, 1000000000000000000000);
        balances[0x4691Ac374286dDF8f30eA01610a6AE375A044cc1] = 1000000000000000000000;
        emit Transfer(address(0), 0x4691Ac374286dDF8f30eA01610a6AE375A044cc1, 1000000000000000000000);
        balances[0x69D1b175d0C67efADf90Ab4051B985b3e07741bC] = 1000000000000000000000;
        emit Transfer(address(0), 0x69D1b175d0C67efADf90Ab4051B985b3e07741bC, 1000000000000000000000);
        balances[0x4809BF3F26788659a6006efba2d6acC919aBF441] = 1000000000000000000000;
        emit Transfer(address(0), 0x4809BF3F26788659a6006efba2d6acC919aBF441, 1000000000000000000000);
        balances[0x9539F727813adF32170c84609Fddd387aCeFF2cA] = 1000000000000000000000;
        emit Transfer(address(0), 0x9539F727813adF32170c84609Fddd387aCeFF2cA, 1000000000000000000000);
        balances[0x94FB92476505ed54B8f7485f99fa1cd8d1761E00] = 1000000000000000000000;
        emit Transfer(address(0), 0x94FB92476505ed54B8f7485f99fa1cd8d1761E00, 1000000000000000000000);
        balances[0x929f985bA5F11D48f8b69Bbed6B644624E65296C] = 1000000000000000000000;
        emit Transfer(address(0), 0x929f985bA5F11D48f8b69Bbed6B644624E65296C, 1000000000000000000000);
        balances[0x6Ee0f0D0049078165023f84be04A1546E6e9664b] = 1000000000000000000000;
        emit Transfer(address(0), 0x6Ee0f0D0049078165023f84be04A1546E6e9664b, 1000000000000000000000);
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