/**
 *Submitted for verification at FtmScan.com on 2022-09-18
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface SolidPair {
    function observationLength() external returns (uint256);
    function observations(uint256 index) external returns (uint256, uint256, uint256);
    function totalSupply() external returns (uint256);
    function token0() external returns(address);
    function token1() external returns(address);
    function getReserves() external view returns (uint _reserve0, uint _reserve1, uint _blockTimestampLast);
}

contract RadialVoting {
    struct Deposit {
        uint256 unlocked;
        uint256 locked;
        uint256 unlockWeek;
    }

    uint256 constant WEEK = 60*60*24*7;

    SolidPair immutable RDL_FTM_POOL;
    uint256 immutable START_TIME;
    address immutable RDL_MANAGER;
    address immutable LP_MANAGER;
    mapping(address => Deposit) lpDeposits;
    mapping(address => Deposit) rdlDeposits;


    constructor(address _rdlFtmPool, address _rdlManager, address _lpManager, uint256 _startTime) {
        RDL_FTM_POOL = SolidPair(_rdlFtmPool);
        RDL_MANAGER = _rdlManager;
        LP_MANAGER = _lpManager;
        START_TIME = _startTime;
    }

    modifier onlyLPManager {
        require(msg.sender == LP_MANAGER, "Not authorized");
        _;
    }

    modifier onlyRDLManager {
        require(msg.sender == RDL_MANAGER, "Not authorized");
        _;
    }

    function receiveLP(address _from, uint256 _amount) external onlyLPManager {
        lpDeposits[_from] = _deposit(lpDeposits[_from], _amount);
    }

    function receiveRDL(address _from, uint256 _amount) external onlyRDLManager {
        rdlDeposits[_from] = _deposit(rdlDeposits[_from], _amount);
    }

    // can't withdraw deposit in the same week
    function withdrawLP(address _from, uint256 _amount) external onlyLPManager {
        lpDeposits[_from] = _withdraw(lpDeposits[_from], _amount);
    }

    // can't withdraw deposit in the same week
    function withdrawRDL(address _from, uint256 _amount) external onlyRDLManager {
        rdlDeposits[_from] = _withdraw(rdlDeposits[_from], _amount);
    }

    function _deposit(Deposit memory _depositInfo, uint256 _amount) internal view returns(Deposit memory) {
        uint256 _currentWeek = getWeek();
        _depositInfo = _updateDeposit(_depositInfo, _currentWeek);
        _depositInfo.locked += _amount;
        _depositInfo.unlockWeek = _currentWeek + 1;
        return _depositInfo;
    }

    function _withdraw(Deposit memory _depositInfo, uint256 _amount) internal view returns(Deposit memory) {
        uint256 _currentWeek = getWeek();
        _depositInfo = _updateDeposit(_depositInfo, _currentWeek);
        // assuming unlock time is more than 1 week
        _depositInfo.unlocked -= _amount;
        return _depositInfo;
    }

    function _updateDeposit(Deposit memory _depositInfo, uint256 _currentWeek) internal pure returns(Deposit memory) {
        if(_depositInfo.unlockWeek <= _currentWeek) {
            _depositInfo.unlocked += _depositInfo.locked;
            delete _depositInfo.locked;
            delete _depositInfo.unlockWeek;
        }
        return _depositInfo;
    }

    function getVotingPower(address _user) external returns(uint256) {
        Deposit memory _lpDeposit = lpDeposits[_user];
        Deposit memory _rdlDeposit = rdlDeposits[_user];
        uint256 _currentWeek = getWeek();
        _lpDeposit = _updateDeposit(_lpDeposit, _currentWeek);
        _rdlDeposit = _updateDeposit(_rdlDeposit, _currentWeek);
        lpDeposits[_user] = _lpDeposit;
        rdlDeposits[_user] = _rdlDeposit;
        uint256 _lpVotingPower;
        if(_lpDeposit.unlocked != 0) {
            _lpVotingPower = getFairRDLReserve()*_lpDeposit.unlocked/RDL_FTM_POOL.totalSupply();
        }
        uint256 _rdlVotingPower = _rdlDeposit.unlocked;
        return (_lpVotingPower + _rdlVotingPower)/1e18;
    }

    function getFairRDLReserve() public returns(uint256) {
        uint256 _lastObsIndex = RDL_FTM_POOL.observationLength() - 1;
        (uint256 _t1Last, , uint256 _cr1Last) = RDL_FTM_POOL.observations(_lastObsIndex);
        (uint256 _t1Before, , uint256 _cr1Before) = RDL_FTM_POOL.observations(_lastObsIndex - 1);

        return (_cr1Last - _cr1Before)/(_t1Last - _t1Before);
    }

    function balanceOfLP(address _user) external view returns(uint256) {
        Deposit memory _lpDeposit = lpDeposits[_user];
        return _lpDeposit.locked + _lpDeposit.unlocked;
    }

    function getWeek() public view returns (uint256) {
        return (block.timestamp - START_TIME) / WEEK;
    }
}