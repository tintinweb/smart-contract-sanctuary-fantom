/**
 *Submitted for verification at FtmScan.com on 2022-04-01
*/

// SPDX-License-Identifier: MIT
/*
  _____                         _____ ______ _   _ 
 / ____|                       / ____|  ____| \ | |
| (___  _ __   __ _  ___ ___  | |  __| |__  |  \| |
 \___ \| '_ \ / _` |/ __/ _ \ | | |_ |  __| | . ` |
 ____) | |_) | (_| | (_|  __/ | |__| | |____| |\  |
|_____/| .__/ \__,_|\___\___|  \_____|______|_| \_|
       | |                                         
       |_|        

deployer address : 0x45db9E58cE958773a8042447EFd1c3669059F172
team address : 0x2DA081197119112d4876313dDEBec2799995351E

total supply : 6 milion
compiler version: 0.8.7+commit
launch day: 1 april 2022 
 */
pragma solidity ^0.8.0;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function getUserStakeOneBalance(address account) external returns (uint256);
    function getUserStakeTwoBalance(address account) external returns (uint256);
    function getStakeOnePaused() external returns (bool);
    function getStakeTwoPaused() external returns (bool);
    function getTotalStakePoolOne() external returns (uint256);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "cx");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;
contract ERC20 is Context, Ownable, IERC20, IERC20Metadata {

    bool stakeOnePaused = false;
    bool stakeTwoPaused = true;

    uint256 stakeOneAPY = 8250; // %8250
    uint256 stakeTwoAPY = 2; // %2

    mapping(address => uint256) public userStakeOneBalance;
    mapping(address => uint256) public userStakeTwoBalance;

    mapping(address => uint256) public userStakeOneTime;
    mapping(address => uint256) public userStakeTwoTime;

    uint256 totalStakePoolOne = 0;
    uint256 totalStakePoolTwo = 0;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _mint(msg.sender, 1000000 * 5 * 10 ** decimals()); // for liq address : 0x45db9E58cE958773a8042447EFd1c3669059F172
        _mint(0x2DA081197119112d4876313dDEBec2799995351E, 1000000 * 1 * 10 ** decimals()); // for team address: 0x2DA081197119112d4876313dDEBec2799995351E

    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function getStakeOnePaused() public view virtual override returns (bool) {
        return stakeOnePaused;
    }
    function getStakeTwoPaused() public view virtual override returns (bool) {
        return stakeTwoPaused;
    }

    function getTotalStakePoolOne()public view virtual override returns (uint256) {
        return totalStakePoolOne;
    }

    function getUserStakeOneBalance(address account) public view virtual override returns (uint256) {
        return userStakeOneBalance[account];
    }
    function getUserStakeTwoBalance(address account) public view virtual override returns (uint256) {
        return userStakeTwoBalance[account];
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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

    function setStakeOnePaused(bool state) public onlyOwner{
        stakeOnePaused = state;
    }
     function setStakeTwoPaused(bool state) public onlyOwner{
        stakeTwoPaused = state;
    }
    function setStakeOneAPY(uint256 apy) public onlyOwner{
        stakeOneAPY = apy;
    }
    function setStakeTwoAPY(uint256 apy) public onlyOwner{
        stakeTwoAPY = apy;
    }
    function stakeOne(uint256 amount) public {
        amount = amount * 10 ** 18;
        require(amount > 0, "Invalid Amount.");
        require(stakeOnePaused == false || msg.sender == owner() , "Stake hasn't start."); // owner for test 
        _burn(msg.sender, amount);
        userStakeOneBalance[msg.sender] += amount;
        totalStakePoolOne += amount;
        userStakeOneTime[msg.sender] = block.timestamp;
    }
    function stakeTwo(uint256 amount) public {
        amount = amount * 10 ** 18;
        require(amount > 0, "Invalid Amount.");
        require(stakeTwoPaused == false || msg.sender == owner() , "Stake hasn't start."); // owner for test 
        _burn(msg.sender, amount);
        userStakeTwoBalance[msg.sender] += amount;
        totalStakePoolTwo += amount;
        userStakeTwoTime[msg.sender] = block.timestamp;
    }

    function claimStakeOne() public{
        if(msg.sender != owner()){
            require(block.timestamp - userStakeOneTime[msg.sender] > 2592000 , "You are balance is locked. Unlocked 1 month after lock date."); // 1 month locked
        }        
        _mint(msg.sender , (userStakeOneBalance[msg.sender]) * (stakeOneAPY/100) / 12);
        totalStakePoolOne -= userStakeOneBalance[msg.sender];
        userStakeOneBalance[msg.sender] = 0;      
    }
    function claimStakeTwo() public{
        if(msg.sender != owner()){
            require(block.timestamp - userStakeTwoTime[msg.sender] > 2592000 , "You are balance is locked. Unlocked 1 month after lock date."); // 1 month locked
        }        
        _mint(msg.sender , (userStakeTwoBalance[msg.sender]) * (stakeTwoAPY/100) / 12);
        totalStakePoolTwo -= userStakeTwoBalance[msg.sender];
        userStakeTwoBalance[msg.sender] = 0;      
    }
}