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

contract employeeDB is MjolnirRBAC {

    struct Employee {
        uint256 tierLevel;
        uint256 daysWorked;
        bool onVacation;
        bool inactive;
    }

    mapping(uint256 => address) employeeID;

    mapping(address => Employee) employees;

    function setEmployeeTier(address empAddr, uint256 tierLv) external onlyThor {
        employees[empAddr].tierLevel = tierLv;
    }

    function setDaysWorked(address empAddr, uint256 daysworked) external onlyThor {
        employees[empAddr].daysWorked = daysworked;
    }

    function isOnVacation(address empAddr, bool TorF) external onlyThor {
        employees[empAddr].onVacation = TorF;
    }

    function isInactive(address empAddr, bool TorF) external onlyThor {
        employees[empAddr].inactive = TorF;
    }

    function mapEmployeeToID(uint256 idNum, address empAddr) external onlyThor {
        employeeID[idNum] = empAddr;
    }

    function viewEmployeeTier(address empAddr) external view returns(uint256) {
        return employees[empAddr].tierLevel;
    }

    function seeDaysWorked(address empAddr) external view returns(uint256) {
        return employees[empAddr].daysWorked;
    }

    function checkOnVacation(address empAddr) external view returns(bool) {
        return employees[empAddr].onVacation;
    }

    function checkInactive(address empAddr) external view returns(bool) {
        return employees[empAddr].inactive;
    }

    function seeEmployeeByID(uint256 idNum) external view returns(address) {
        return employeeID[idNum];
    }
}