/**
 *Submitted for verification at FtmScan.com on 2022-02-18
*/

// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

interface IEpsstaker{
    function mintLocked(address _address, uint _amount) external;
    function mintUnlocked(address _address, uint _amount) external;
    function mintVested(address _address, uint _amount) external;
}

contract MigratorMinter{
    address public dev = 0x1B5b5FB19d0a398499A9694AD823D786c24804CC;
    address public epsstaker;

    constructor(){
    }

    modifier onlyDev(){
        require(msg.sender == dev);
        _;
    }

    function setEpsStaker(address _epsStaker) external onlyDev{
        epsstaker = _epsStaker;
    }

    address[] public user;
    uint[] public staked;
    uint[] public vested;
    uint[] public locked;

    function lengthUsers() public view returns(uint){
        return(user.length);
    }

    function pushMembers(address[] memory _users, uint[] memory _staked, uint[] memory _vested, uint[] memory _locked) external onlyDev{
        require(_users.length == _staked.length && _staked.length == _vested.length && _vested.length == _locked.length);
        for(uint i; i<_users.length; i++){
            user.push(_users[i]);
            staked.push(_staked[i]);
            vested.push(_vested[i]);
            locked.push(_locked[i]);
        }
    }

    function refundNext() public onlyDev{
        uint length = user.length;
        address _user = user[length-1];
        uint _staked = staked[length-1];
        uint _vested = vested[length-1];
        uint _locked = locked[length-1];
        user.pop();
        staked.pop();
        vested.pop();
        locked.pop();
        if(_locked>0)
            IEpsstaker(epsstaker).mintLocked(_user,_locked);
        if(_staked>0)
            IEpsstaker(epsstaker).mintUnlocked(_user,_staked);
        IEpsstaker(epsstaker).mintVested(_user,_vested);
    }

    function refundN(uint _n) public onlyDev{
        for(uint i; i<_n; i++)
            refundNext();
    }
}