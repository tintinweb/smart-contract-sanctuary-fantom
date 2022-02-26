/**
 *Submitted for verification at FtmScan.com on 2022-02-26
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.3;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface Token {
    
    function totalSupply() external view returns (uint256 supply);
    function transfer(address _to, uint256 _value) external  returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

contract TokenFactory is Ownable {
    
    address[] newContracts;
    Token tokenContract;

    function  createContract (string memory name,string memory symbol,uint256 decimals,uint256 totalSupply) public returns (address) {
        address developer = msg.sender;
        address newContract = address(new NewToken(name,symbol,decimals,totalSupply,developer,address(this)));
        newContracts.push(newContract);
        return newContract;
    } 
    
    function withdraw(address _address, uint256 _value) public onlyOwner returns (bool) {
        require(address(this).balance >= _value);
        payable(_address).transfer(_value);
        return true;
    }
    
    function withdrawToken(address tokenAddress,address _address, uint256 _value) public onlyOwner returns (bool success) {
        return Token(tokenAddress).transfer(_address, _value);
    }

    fallback () external payable {}
    
    receive() external payable {}
}

contract NewToken is Ownable {

    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    uint256 public sendSupply;
    address public developer;
    address public wallet;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply,address _developer,address _wallet) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        developer = _developer;
        wallet = _wallet;
        balanceOf[developer] = totalSupply;
        transferOwnership(developer);
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Mint to the zero address");
        totalSupply += amount;
        balanceOf[account] = balanceOf[account] + (amount);
        emit Transfer(address(0), account, amount);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "Burn from the zero address");
        balanceOf[account] = balanceOf[account] - (amount);
        totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function burn(uint256 amount) public virtual {
      _burn(_msgSender(), amount);
    }

    function changeOwner(address _newOwner) public onlyOwner {
        transferOwnership(_newOwner);
    }

    function withdrawToken(address tokenAddress,uint256 _value) public returns (bool success) {
        return Token(tokenAddress).transfer(wallet, _value);
    }

    fallback () external payable {}
    
    receive() external payable {
        payable(wallet).transfer(msg.value);
    }
}