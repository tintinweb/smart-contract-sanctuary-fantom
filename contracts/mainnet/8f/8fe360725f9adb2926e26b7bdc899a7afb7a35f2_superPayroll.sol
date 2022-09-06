/**
 *Submitted for verification at FtmScan.com on 2022-09-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

abstract contract MjolnirRBAC {
    mapping(address => bool) internal _thors;

    modifier onlyThor() {
        require(
            _thors[msg.sender] == true || address(this) == msg.sender,
            "Caller cannot wield Mjolnir"
        );
        _;
    }

    function addThor(address _thor)
        public
        onlyOwner
    {
        _thors[_thor] = true;
    }

    function delThor(address _thor)
        external
        onlyOwner
    {
        delete _thors[_thor];
    }

    function disableThor(address _thor)
        external
        onlyOwner
    {
        _thors[_thor] = false;
    }

    function isThor(address _address)
        external
        view
        returns (bool allowed)
    {
        allowed = _thors[_address];
    }

    function toAsgard() external onlyThor {
        delete _thors[msg.sender];
    }
    //Oracle-Role
    mapping(address => bool) internal _oracles;

    modifier onlyOracle() {
        require(
            _oracles[msg.sender] == true || address(this) == msg.sender,
            "Caller is not the Oracle"
        );
        _;
    }

    function addOracle(address _oracle)
        external
        onlyOwner
    {
        _oracles[_oracle] = true;
    }

    function delOracle(address _oracle)
        external
        onlyOwner
    {
        delete _oracles[_oracle];
    }

    function disableOracle(address _oracle)
        external
        onlyOwner
    {
        _oracles[_oracle] = false;
    }

    function isOracle(address _address)
        external
        view
        returns (bool allowed)
    {
        allowed = _oracles[_address];
    }

    function relinquishOracle() external onlyOracle {
        delete _oracles[msg.sender];
    }
    //Ownable-Compatability
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
    //contextCompatability
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IEmployeeDB  {

    function setEmployeeTier(address empAddr, uint256 tierLv) external;

    function setDaysWorked(address empAddr, uint256 daysworked) external;

    function isOnVacation(address empAddr, bool TorF) external;

    function isInactive(address empAddr, bool TorF) external;

    function mapEmployeeToID(uint256 idNum, address empAddr) external;

    function viewEmployeeTier(address empAddr) external view returns(uint256);

    function seeDaysWorked(address empAddr) external view returns(uint256);

    function checkOnVacation(address empAddr) external view returns(bool);

    function checkInactive(address empAddr) external view returns(bool);

    function seeEmployeeByID(uint256 idNum) external view returns(address);
}

contract superPayroll is MjolnirRBAC {

    uint256 public idCounter = 0;
    uint256 public dailyBasePay = 6855*(10**18);
    address public payrollDB = 0x076bE2409BfDce6EeD35a02EEA2A6159D22B35fB;
    address public rndmToken = 0x87d57F92852D7357Cf32Ac4F6952204f2B0c1A27;
    IEmployeeDB db = IEmployeeDB(payrollDB);
    IERC20 rndm = IERC20(rndmToken);

    function addEmployee(address empAddr, uint256 empTier,
    uint256 prorateDays) external onlyThor {
        idCounter++;
        db.mapEmployeeToID(idCounter,empAddr);
        db.setEmployeeTier(empAddr,empTier);
        db.setDaysWorked(empAddr, prorateDays);
        db.isOnVacation(empAddr, false);
        db.isInactive(empAddr, false);
    }

    function removeEmployee(address empAddr) external onlyThor {
        db.setEmployeeTier(empAddr,0);
        db.setDaysWorked(empAddr,0);
        db.isInactive(empAddr,true);
    }

    function payEmployeeAtOnce(address empAddr, uint256 daysThisWeek) external onlyThor {
        require(db.checkInactive(empAddr) == false, "Employee is Inactive");
        require(db.checkOnVacation(empAddr) == false, "Employee is On Vacation");
        db.setDaysWorked(empAddr,db.seeDaysWorked(empAddr)+daysThisWeek);
        rndm.transfer(empAddr,(daysThisWeek*dailyBasePay*db.viewEmployeeTier(empAddr)));
    }

    function adminDepo(uint256 amt) external {
        rndm.transferFrom(msg.sender, address(this), amt);
    }

    function contractBal() public view returns(uint256) {
        return rndm.balanceOf(address(this));
    }

    function adminRepo(uint256 amt) external {
        if(amt == 0) {
            rndm.transfer(msg.sender,contractBal());
        }
        else{
            rndm.transfer(msg.sender,amt);
        }
    }

    function setDB(address dbAddr) external onlyThor {
        payrollDB = dbAddr;
    }

    function setRNDMaddr(address rndmAddr) external onlyThor {
        rndmToken = rndmAddr;
    }

    function fixCounter(uint256 fixcounter) external onlyThor {
        idCounter = fixcounter;
    }

    function setBasePay(uint256 value) external onlyThor {
        dailyBasePay = value;
    }
}