/**
 *Submitted for verification at FtmScan.com on 2022-03-14
*/

// SPDX-License-Identifier: MIT

//💀💀💀💀 https://www.dworld.money 💀💀💀💀


/***
 *                                                                                                                   
 *    8 888888888o.   `8.`888b                 ,8'  ,o888888o.     8 888888888o.   8 8888         8 888888888o.      
 *    8 8888    `^888. `8.`888b               ,8'. 8888     `88.   8 8888    `88.  8 8888         8 8888    `^888.   
 *    8 8888        `88.`8.`888b             ,8',8 8888       `8b  8 8888     `88  8 8888         8 8888        `88. 
 *    8 8888         `88 `8.`888b     .b    ,8' 88 8888        `8b 8 8888     ,88  8 8888         8 8888         `88 
 *    8 8888          88  `8.`888b    88b  ,8'  88 8888         88 8 8888.   ,88'  8 8888         8 8888          88 
 *    8 8888          88   `8.`888b .`888b,8'   88 8888         88 8 888888888P'   8 8888         8 8888          88 
 *    8 8888         ,88    `8.`888b8.`8888'    88 8888        ,8P 8 8888`8b       8 8888         8 8888         ,88 
 *    8 8888        ,88'     `8.`888`8.`88'     `8 8888       ,8P  8 8888 `8b.     8 8888         8 8888        ,88' 
 *    8 8888    ,o88P'        `8.`8' `8,`'       ` 8888     ,88'   8 8888   `8b.   8 8888         8 8888    ,o88P'   
 *    8 888888888P'            `8.`   `8'           `8888888P'     8 8888     `88. 8 888888888888 8 888888888P'      
 */


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
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;

interface IERC20 {
  
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
   
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

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

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8.0;

contract ERC20 is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
}


pragma solidity 0.8.10;

contract Presale is ERC20('', ''), ReentrancyGuard {

    address payable constant devAddress = payable(0xBDe4C6A362F39A1D27B3aB937197c35e7b67f5dF);
    IERC20 public OBOLAddress;

    uint256 public salePrice = 1;
    uint256 public constant OBOLPresaleSupply = 5 * (10 ** 4) * (10 ** 9);
    uint256 public constant maxOBOLPurchase = 5000 * (10 ** 9);
    uint256 public OBOLRemaning = OBOLPresaleSupply;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public swapTime;

    address[] private whitelist;

    mapping(address => uint256) public OBOLBought;

    constructor(uint256 _startTime, address _OBOLAddress) {
        require(_startTime >= block.timestamp, "You must set it in the future");
        startTime = _startTime;
        endTime = _startTime + 7 days;
        swapTime = endTime + 1 hours ;
        OBOLAddress = IERC20(_OBOLAddress);
    }

    event OBOLBuy(address buyer, uint256 amount);
    event OBOLSwap(address swapper);

//@User functions        

    function buyOBOL(uint256 _amount) external payable nonReentrant {
        require(_amount > 0, "user cannot purchase 0 OBOL");
        uint256 cost = _amount * (10 ** 18);
        _amount = _amount * (10 ** 9);
        
        require(block.timestamp >= startTime, "presale hasn't started yet, good things come to those that wait");
        require(block.timestamp < endTime, "presale has ended, come back next time!");
        require(OBOLRemaning >= _amount, "not enough OBOL left!");
        require(OBOLBought[msg.sender] + _amount <= maxOBOLPurchase, "user has already purchased too much OBOL");

        devAddress.transfer(cost);
        OBOLBought[msg.sender] = (OBOLBought[msg.sender] + _amount);
        OBOLRemaning = OBOLRemaning - _amount;
        
        whitelist.push(address(msg.sender));

        emit OBOLBuy(address(msg.sender), _amount);
    }

    function swapOBOL() external nonReentrant {
        require(OBOLBought[msg.sender] > 0, "you have nothing to do here!");
        require(block.timestamp >= swapTime, "swap hasn't started yet, good things come to those that wait");
        require(IERC20(OBOLAddress).balanceOf(address(this)) >= (OBOLBought[msg.sender]), "not Enough tokens in contract for swap");

        IERC20(OBOLAddress).transfer(address(msg.sender), OBOLBought[msg.sender]);
        OBOLBought[msg.sender] = 0;

        emit OBOLSwap(address(msg.sender));
    }

//@Dev utility

    function setStartTime(uint256 _newStartTime) external onlyOwner {
        require(block.timestamp < startTime, "cannot change start time if sale has already commenced");
        require(block.timestamp < _newStartTime, "cannot set start time in the past");
        startTime = _newStartTime;
        endTime = _newStartTime + 7 days;
        swapTime = endTime + 2 hours;
    }

    function recoverUnclaimed() external onlyOwner {
        require(block.timestamp >= swapTime + 7 days, "can only claim excess Obol 7 days after presale has ended");
        require(IERC20(OBOLAddress).balanceOf(address(this)) > 0, "Nothing to claim!");
        IERC20(OBOLAddress).transfer(devAddress, IERC20(OBOLAddress).balanceOf(address(this)));
    }

    function setOBOLAddress(address _OBOLAddress) external onlyOwner {
    	require(block.timestamp < startTime, "cannot change the address if sale has already commenced");
	    OBOLAddress = IERC20(_OBOLAddress);
    }

    function PrintWhitelist(uint _index) external view onlyOwner returns (address){
           return (whitelist[_index]);
       }

}
//From Lilith with Love