// Official contract for CHATIT Token(CHT)
//An ERC20 token in accordance with ERC20 token standards

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.11 < 0.9.0;

interface ICHT {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function mint(address account, uint256 amount) external returns(bool);
    function burn(address account, uint256 amount) external returns(bool);
}

contract CHT {

    string  private _name;
    string  private _symbol;
    uint256 private _totalSupply;
    address private _admin; //contract admin
    mapping (address => bool) private _isAuthorized; //authorized account to perform special functions
    mapping(address => uint256) private _balances; //account balances
    mapping(address => mapping(address => uint256)) private _allowances;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    ///don't make name and symbol hardcoded(for flexibility)
    constructor(string memory token_name, string memory token_symbol )  {
        _name = token_name;
        _symbol = token_symbol;
        _admin = msg.sender;
        _isAuthorized[msg.sender] = true;
    }

//-----READ FUNCTIONS-------
    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) external view  returns (uint256) {
        return _allowances[owner][spender];
    }

    function admin() external view returns(address) {
        return _admin;
    }

    function isAuthorized(address account) external  view returns(bool) {
        return _isAuthorized[account];
    }

//------MODIFIERS---------
    modifier validateAddress(address account) {
        require(account != address(0), "ERR_1: Invalid address passed");
        _;
    }

    modifier isAdmin() {
        require(msg.sender == _admin, "ERR_2: Only contract admin can call this function");
        _;
    }

    modifier authorized() {
        require(_isAuthorized[msg.sender] == true, "ERR_3: Only authorized users can call this function");
        _;
    }

    modifier validateNotAdmin(address account) {
        require(account != _admin, "ERR_4: Can't unauthorize contract admin");
        _;
    }

    modifier validateBalance(address account, uint256 amount) {
        require(_balances[account] >= amount, "ERR_5: insufficient balance(transfer amount exceeds balance)");
        _;
    }

    modifier validateAllowance(address owner, address spender, uint256 amount) {
       require(_allowances[owner][spender] >= amount, "ERR_6: insufficient allowance(current allowance is lesser than amount passed)");
        _;
    }


//-------MATH(LIKE SAFEMATH)----
    function add(uint a, uint b) internal pure returns (uint c) {
        require((c = a + b) >= a, "MATH_ERR_1: addition overflow occured");
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require((c = a - b) <= a, "MATH_ERR_2: subtration underflow occured");
    }
    
//-------WRITE FUNCTIONS-----
    function transfer(address to, uint256 amount) external returns(bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;

    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 amount) external returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = _allowances[owner][spender];
        uint256 newAllowance = add(currentAllowance,  amount);
        _approve(owner, spender, newAllowance);
        return true;
    }

    function decreaseAllowance(address spender, uint256 amount) external validateAllowance(msg.sender, spender, amount) returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = _allowances[owner][spender];
        uint256 newAllowance = sub(currentAllowance, amount);
        _approve(owner, spender, newAllowance);
        return true;
    }

    function mint(address account, uint256 amount) external authorized() validateAddress(account) returns(bool) {
        _totalSupply = add(_totalSupply, amount);
        _balances[account] = add(_balances[account], amount);
        emit Transfer(address(0), account, amount);
        return true;
    }

    function burn(address account, uint256 amount) external validateAddress(account) validateBalance(account, amount) returns(bool) {
       if (msg.sender != account) {
           _spendAllowance(account, msg.sender, amount);
       }
        uint256 accountBalance = _balances[account];
        _balances[account] = sub(accountBalance, amount);
        _totalSupply = sub(_totalSupply, amount);
        emit Transfer(account, address(0), amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal validateAddress(from) validateAddress(to) validateBalance(from, amount) {
        uint256 senderBalance = _balances[from];
        _balances[from] = sub(senderBalance, amount);
        uint256 receiverBalance = _balances[to];
        _balances[to] = add(receiverBalance, amount);
        emit Transfer(from, to, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal validateAllowance(owner, spender, amount) {
        uint256 currentAllowance =  _allowances[owner][spender];
        uint256 maxUint256 = type(uint256).max;
        if (currentAllowance != maxUint256) {
            uint256 newAllowance = sub(currentAllowance, amount);
            _approve(owner, spender, newAllowance);
           
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal validateAddress(owner) validateAddress(spender)  {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function changeAdmin(address account) external isAdmin() validateAddress(account) {
        address prevAdmin = _admin;
        _admin = account;
        _isAuthorized[account] = true;
        delete _isAuthorized[prevAdmin];
    }

    function authorize(address account) external isAdmin() validateAddress(account){
        _isAuthorized[account] = true;
    }

    function unauthorize(address account) external isAdmin() validateNotAdmin(account) {
        delete _isAuthorized[account];
    } 

}