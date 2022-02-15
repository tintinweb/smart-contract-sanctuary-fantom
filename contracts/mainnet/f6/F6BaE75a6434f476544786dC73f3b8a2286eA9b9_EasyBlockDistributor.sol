/**
 *Submitted for verification at FtmScan.com on 2022-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Easyblock {
    function holders(uint _index) external view returns(address);
    function shareCount(address _address) external view returns(uint);
    function totalShareCount() external view returns(uint);
}

contract EasyBlockDistributor {
    address public easyBlockContract;
    address public owner;

    constructor (address _easyBlockContract) {
        easyBlockContract = _easyBlockContract;
        owner = msg.sender;
    }

    function distribute(uint32 _start, uint32 _end, uint64 _rewardAmount) external view returns(uint) {
        // Access the contract
        Easyblock _easyContract;
        _easyContract = Easyblock(easyBlockContract);
        // Total share count
        uint _totalShareCount = _easyContract.totalShareCount();
        
        for(uint32 _i = _start; _i < _end; _i++) {
            address _currentHolder = _easyContract.holders(_i);
            uint _shareCount = _easyContract.shareCount(_currentHolder);
            return _rewardAmount * _shareCount / _totalShareCount;
        }
    }

    // Modifiers
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
}