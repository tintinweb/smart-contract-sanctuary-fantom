/**
 *Submitted for verification at FtmScan.com on 2022-03-15
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
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

contract Payroll is Ownable {
    struct Distribution {
        uint256 amount;
        uint256 lastAllocationTime;
    }

    struct Payment {
        uint256 lastPaymentTime;
    }

    struct Employee {
        address id;
        string name;
        uint256 weeklyRNDMSalary;
        uint256 totalReceivedRNDM;
        uint256 totalDistributed;
        mapping(address => Payment) payments;
        mapping(address => Distribution) distributions;
    }

    /* PAYROLL STATE */
    enum State {
        Allowed,
        Blocked
    }

    /* STATE VARIABLES */
    State public paymentsState;
    uint256 public employeeCount;
    address public tokenAddress = 0x87d57F92852D7357Cf32Ac4F6952204f2B0c1A27;
    mapping(address => Employee) private employeesMap;
    mapping(string => Employee) private employeesMapByName;

    uint256 private totalWeeklyRNDMSalary;

    /* @dev Changes the contract state to Allowed/Blocked, so employees are/won't be able to receive payments */
    function payrollInit(uint8 zeroOrOne) external onlyOwner {
        if (zeroOrOne == 0) {
            paymentsState = State.Blocked;
            emit LogPaymentsBlocked(block.timestamp);
        } else if (zeroOrOne == 1) {
            paymentsState = State.Allowed;
            emit LogPaymentsBlocked(block.timestamp);
        }
    }

    /* EVENTS */
    event LogEmployeeRemoved(address _employeeAddress);
    event LogEmployeeAdded(
        address _employeeAddress,
        uint256 _weeklyRNDMSalary,
        uint256 _totalWeeklyRNDMSalary
    );
    event LogEmployeeSalaryUpdated(
        address indexed _employeeAddress,
        uint256 _oldYWeeklyRNDMSalary,
        uint256 _newWeeklyRNDMSalary,
        uint256 _totalWeeklyRNDMSalary
    );
    event LogPaymentsAllowed(uint256 _time);
    event LogPaymentsBlocked(uint256 _time);
    event LogPaymentReceived(
        uint256 _time,
        address _employeeAddress,
        address _tokenAddress,
        uint256 _tokenPayment
    );
    event LogTokenFundsAdded(uint256 _time, address _token, uint256 _value);
    event LogPaymentDistributionUpdated(
        uint256 _time,
        address _employeeAddress,
        address _token,
        uint256 _totalDistributed
    );

    /* ACCESS RULES */

    modifier onlyByEmployee() {
        require(exists(msg.sender));
        _;
    }

    modifier onlyPositive(uint256 _value) {
        require(_value > 0);
        _;
    }
    modifier onlyRegistered(address _employeeAddress) {
        require(exists(_employeeAddress));
        _;
    }
    modifier onlyRegisteredCheckByName(string memory _employeeName) {
        require(existsByName(_employeeName));
        _;
    }
    modifier onlyNotRegistered(address _employeeAddress) {
        require(!exists(_employeeAddress));
        _;
    }
    modifier onlyIfPayments(State _state) {
        require(paymentsState == _state);
        _;
    }

    /* OWNER ONLY */

    /* @dev returns ERC20 tokens to contract owner */
    function claimTokenFunds() external onlyOwner {
        IERC20 rndm = IERC20(tokenAddress);
        require(
            rndm.transfer(msg.sender, rndm.balanceOf(address(this))) == true,
            "Could not transfer tokens from your address to this contract"
        );
    }

    /* @dev Calculates the monthly RNDM amount spent in salaries */
    function calculatePayrollBurnrate() public view returns (uint256) {
        return totalWeeklyRNDMSalary * 4;
    }

    /* @dev Calculates the days until the contract can run out of funds for the provided token */
    function calculatePayrollRunway() external view returns (uint256) {
        return ((IERC20(tokenAddress).balanceOf(address(this)) /
            calculatePayrollBurnrate()) * 12);
    }

    /* @dev Adds an employee into the payroll if it is not already registered and has valid tokens and salary */
    function addEmployee(
        address _employeeAddress,
        string memory _employeeName,
        uint256 _initialWeeklyRNDMSalary
    )
        external
        onlyNotRegistered(_employeeAddress)
        onlyPositive(_initialWeeklyRNDMSalary)
    {
        Employee storage employee = employeesMap[_employeeAddress];
        Payment storage payment = employee.payments[tokenAddress];
        Distribution storage distribution = employee.distributions[
            tokenAddress
        ];

        employeeCount++;
        totalWeeklyRNDMSalary =
            totalWeeklyRNDMSalary +
            (_initialWeeklyRNDMSalary);
        employee.id = _employeeAddress;
        employee.name = _employeeName;
        employee.weeklyRNDMSalary = _initialWeeklyRNDMSalary;
        employee.totalReceivedRNDM = 0;
        employee.totalDistributed = 0;
        payment.lastPaymentTime = block.timestamp;
        distribution.lastAllocationTime = block.timestamp;
        distribution.amount = 0;
        emit LogEmployeeAdded(
            _employeeAddress,
            _initialWeeklyRNDMSalary,
            totalWeeklyRNDMSalary
        );
    }

    /* @dev Gets the employee data if the employee is registered in the payroll */
    function getEmployee(address _employeeAddress)
        external
        view
        onlyRegistered(_employeeAddress)
        returns (uint256 _weeklyRNDMSalary, uint256 _totalReceivedRNDM)
    {
        return (
            employeesMap[_employeeAddress].weeklyRNDMSalary,
            employeesMap[_employeeAddress].totalReceivedRNDM
        );
    }

    /* @dev Gets the employee data if the employee is registered in the payroll (gets by name) */
    function getEmployeeByName(string memory _employeeName)
        external
        view
        onlyRegisteredCheckByName(_employeeName)
        returns (uint256 weeklyRNDMSalary, uint256 _totalReceivedRNDM)
    {
        return (
            employeesMapByName[_employeeName].weeklyRNDMSalary,
            employeesMapByName[_employeeName].totalReceivedRNDM
        );
    }

    /* @dev Removes the employee from the payroll if it is registered in the payroll */
    function removeEmployee(address _employeeAddress)
        external
        onlyOwner
        onlyRegistered(_employeeAddress)
    {
        employeeCount = employeeCount - 1;
        totalWeeklyRNDMSalary =
            totalWeeklyRNDMSalary -
            (employeesMap[_employeeAddress].weeklyRNDMSalary);
        delete employeesMap[_employeeAddress];
        emit LogEmployeeRemoved(_employeeAddress);
    }

    /* @dev Updated the employee annual salary if it is registered in the payroll */
    function setEmployeeSalary(
        address _employeeAddress,
        uint256 _newWeeklyRNDMSalary
    )
        external
        onlyOwner
        onlyRegistered(_employeeAddress)
        onlyPositive(_newWeeklyRNDMSalary)
    {
        uint256 oldSalary = employeesMap[_employeeAddress].weeklyRNDMSalary;
        totalWeeklyRNDMSalary =
            totalWeeklyRNDMSalary -
            (oldSalary) +
            (_newWeeklyRNDMSalary);
        employeesMap[_employeeAddress].weeklyRNDMSalary = _newWeeklyRNDMSalary;
        emit LogEmployeeSalaryUpdated(
            _employeeAddress,
            oldSalary,
            _newWeeklyRNDMSalary,
            totalWeeklyRNDMSalary
        );
    }

    /* @dev Gets the total number of employees registered in the payroll */
    function getEmployeeCount() external view returns (uint256) {
        return employeeCount;
    }

    /* @dev Gets the employee payment details */
    function getEmployeePayment(address _employeeAddress)
        external
        view
        onlyRegistered(_employeeAddress)
        returns (
            uint256 _lastAllocationTime,
            uint256 _lastPaymentTime,
            uint256 _distributedAmount
        )
    {
        Employee storage employee = employeesMap[_employeeAddress];
        Payment storage payment = employee.payments[tokenAddress];
        Distribution storage distribution = employee.distributions[
            tokenAddress
        ];

        return (
            distribution.lastAllocationTime,
            payment.lastPaymentTime,
            distribution.amount
        );
    }

    /* EMPLOYEE ONLY */

    /* @dev  Allows the employee to release the funds once a week*/
    function payday() external onlyByEmployee onlyIfPayments(State.Allowed) {
        IERC20 rndm = IERC20(tokenAddress);
        Employee storage employee = employeesMap[msg.sender];
        Payment storage payment = employee.payments[tokenAddress];
        require(block.timestamp - 1 weeks > payment.lastPaymentTime);

        uint256 tokenFunds = rndm.balanceOf(address(this));
        require(employee.weeklyRNDMSalary < tokenFunds);

        payment.lastPaymentTime = block.timestamp;
        emit LogPaymentReceived(
            block.timestamp,
            msg.sender,
            tokenAddress,
            employee.weeklyRNDMSalary
        );
        assert(rndm.transfer(msg.sender, employee.weeklyRNDMSalary));
    }

    /* HELPERS */

    /* @dev Checks if the employee is registered in the payroll */
    function exists(address _employeeAddress) internal view returns (bool) {
        return employeesMap[_employeeAddress].id != address(0x0);
    }

    /* @dev Checks if the employee is registered in the payroll (checks by name) */
    function existsByName(string memory _employeeName)
        internal
        view
        returns (bool)
    {
        return employeesMapByName[_employeeName].id != address(0x0);
    }
}