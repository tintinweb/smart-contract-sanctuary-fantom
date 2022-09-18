/**
 *Submitted for verification at FtmScan.com on 2022-09-18
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IRDL {
    function mint(address to, uint256 amount) external;
}

contract RDLInflationManager {
    uint256 constant SCALING_FACTOR = 1e18;
    uint256 constant WEEK = 60*60*24*7;
    uint256 constant YEAR = 60*60*24*365;
    uint256 constant TOTAL_SUPPLY = 100000000 ether;
    uint256 immutable START_TIME;
    IRDL immutable RDL;
    address immutable POOL_BRIBE_MANAGER;
    address immutable DEPOSITOR;

    uint256 totalInflationLeft;
    mapping(uint256 => bool) isRDLClaimed;

    event RDLDispersedForWeek(uint256 indexed week, uint256 amount);

    modifier onlyPoolBribeManager {
        require(msg.sender == POOL_BRIBE_MANAGER, "unauthorized");
        _;
    }

    modifier onlyDepositor {
        require(msg.sender == DEPOSITOR, "only depositor contract");
        _;
    }

    constructor(uint256 _startTime, address _rdl, address _poolBribeManager, address _depositor) {
        RDL = IRDL(_rdl);
        POOL_BRIBE_MANAGER = _poolBribeManager;
        START_TIME = _startTime;
        DEPOSITOR = _depositor;
        totalInflationLeft = TOTAL_SUPPLY*70/100;
    }

    function getRDLForWeek(uint256 _week) external onlyPoolBribeManager returns(uint256) {
        uint256 _inflation = getRDLInflation(_week);
        if(_inflation == 0 || isRDLClaimed[_week]) return _inflation;
        require(_week < getWeek(), "only for past weeks");
        isRDLClaimed[_week] = true;
        totalInflationLeft -= _inflation;
        RDL.mint(POOL_BRIBE_MANAGER, _inflation);
        emit RDLDispersedForWeek(_week, _inflation);
        return _inflation;
    }

    function getRDLInflation(uint256 _week) public pure returns(uint256) {
        uint256 _weekStartTime = _week*WEEK;
        uint256 _weekEndTime = _week*WEEK + WEEK;
        uint256 _startTimeYear = getYear(_weekStartTime);
        uint256 _endTimeYear = getYear(_weekEndTime);
        uint256 _inflation;
        if(_startTimeYear != _endTimeYear) {
            uint256 _yearEndTime = YEAR*_startTimeYear;
            _inflation = (_yearEndTime - _weekStartTime)*getScaledInflationRate(_startTimeYear) + (_weekEndTime - _yearEndTime)*getScaledInflationRate(_endTimeYear);
        } else {
            _inflation = (_weekEndTime - _weekStartTime)*getScaledInflationRate(_startTimeYear);
        }
        _inflation = _inflation*TOTAL_SUPPLY/YEAR/SCALING_FACTOR;
        return _inflation;
    }

    function getYear(uint256 _time) public pure returns(uint256) {
        return _time/YEAR + 1;
    }

    function getScaledInflationRate(uint256 year) public pure returns(uint256) {
        if(year > 20) return 0;
        return 111740849000000000 + 1055000000000000*(year**2) + 1100000000000*(year**4) - 15550000000000000*year - 44000000000000*(year**3) - 12300000000*(year**5);
    }

    function getWeek() public view returns (uint256) {
        return (block.timestamp - START_TIME) / WEEK;
    }
}