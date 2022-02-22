/**
 *Submitted for verification at FtmScan.com on 2022-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IRNDM {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
	function burn(uint256 amount) external;
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
  function _msgSender() internal view virtual returns(address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns(bytes memory) {
    this;
    return msg.data;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns(address) {
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

abstract contract Controllable is Ownable {
    mapping(address => bool) internal _controllers;

    modifier onlyController() {
        require(
            _controllers[msg.sender] == true || address(this) == msg.sender,
            "Controllable: caller is not a controller"
        );
        _;
    }

    function addController(address _controller)
        external
        onlyOwner
    {
        _controllers[_controller] = true;
    }

    function delController(address _controller)
        external
        onlyOwner
    {
        delete _controllers[_controller];
    }

    function disableController(address _controller)
        external
        onlyOwner
    {
        _controllers[_controller] = false;
    }

    function isController(address _address)
        external
        view
        returns (bool allowed)
    {
        allowed = _controllers[_address];
    }

    function relinquishControl() external onlyController {
        delete _controllers[msg.sender];
    }
}

contract FractalPayroll is Controllable {

  address public rndmToken = 0x87d57F92852D7357Cf32Ac4F6952204f2B0c1A27;

  struct Employee {
	string name;
    uint256 rate;
	uint256 checkSize;
    uint256 time;
	uint256 paidToDate;
    address wallet;
  }

  mapping(string => Employee) Employees;
  
  function pushName(string memory Ename) internal {
    Employees[Ename].name = Ename;
}
  function pushWallet(string memory Ename, address Ewallet) internal {
    Employees[Ename].wallet = Ewallet;
}
  function pushRate(string memory Ename, uint256 weeklyrate) internal {
    Employees[Ename].rate = weeklyrate;
}
  function pushCheckSize(string memory Ename, uint256 check) internal {
    Employees[Ename].checkSize = check;
}
  function pushTime(string memory Ename, uint256 paidAt) internal {
    Employees[Ename].time = paidAt;
}
  function pushAmountPaidToDate(string memory Ename, uint256 amount) internal {
	Employees[Ename].paidToDate = amount;
}
  function addEmployee(string memory Ename, address Ewallet,
  uint256 weeklyrate, uint256 check) external onlyController {
	pushName(Ename);
	pushWallet(Ename, Ewallet);
	pushRate(Ename, weeklyrate);
	pushCheckSize(Ename, check);
	pushTime(Ename, block.timestamp);
	pushAmountPaidToDate(Ename, 0);
}
  function changeWallet(string memory Ename, address account) external onlyController {
  pushWallet(Ename, account);
}

  function removeEmployee(string memory Ename) external onlyController {
  pushRate(Ename, 0);
}
  function hardRemoveEmployee(string memory Ename) external onlyController {
  pushRate(Ename, 0);
  pushCheckSize(Ename, 0);
}
  function giveRaise(string memory Ename, uint256 payboost) external onlyController {
  uint256 Erate = getRate(Ename);
  pushRate(Ename, Erate + payboost);
}
  function deductRate(string memory Ename, uint256 payloss) external onlyController {
  uint256 Erate = getRate(Ename);
  pushRate(Ename, Erate - payloss);
}
  function giveBonus(string memory Ename, uint256 bonus) external onlyController {
  uint256 Esize = getCheckSize(Ename);
  pushCheckSize(Ename, Esize + bonus);
}

  function weeklyPlus(string memory Ename) internal {
  if (block.timestamp - getTime(Ename) >= 7 days) {
  pushCheckSize(Ename, getCheckSize(Ename) + getRate(Ename));
  } else { pushCheckSize(Ename, getCheckSize(Ename));}
  pushTime(Ename, block.timestamp);
}

  function cashCheck(string memory Ename) external {
  IRNDM rndm = IRNDM(rndmToken);
  require(msg.sender == getWallet(Ename));
  weeklyPlus(Ename);
  rndm.transfer(getWallet(Ename), getCheckSize(Ename));
  pushAmountPaidToDate(Ename, getCheckSize(Ename));
  pushCheckSize(Ename, 0);
}

  function adminDepo(uint256 amount) external onlyController {
  IRNDM rndm = IRNDM(rndmToken);
  rndm.transferFrom(msg.sender, address(this), amount);
}

  function adminRepo(uint256 amount) external onlyController {
  IRNDM rndm = IRNDM(rndmToken);
  rndm.transfer(msg.sender, amount);
}

  function getName(string memory Ename) public view returns(string memory) {
    return Employees[Ename].name;
  }
  function getWallet(string memory Ename) public view returns(address) {
    return Employees[Ename].wallet;
  }
  function getRate(string memory Ename) public view returns(uint256) {
    return Employees[Ename].rate;
  }
  function getTime(string memory Ename) public view returns(uint256) {
	return Employees[Ename].time;
  }
  function getCheckSize(string memory Ename) public view returns(uint256) {
	return Employees[Ename].checkSize;
  }
  function getAmountPaidToDate(string memory Ename) public view returns(uint256) {
    return Employees[Ename].paidToDate;
  }
  function setRndm(address value) external onlyController {
  rndmToken = value;
  }
}