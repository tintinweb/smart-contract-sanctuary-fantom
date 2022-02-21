/**
 *Submitted for verification at FtmScan.com on 2022-02-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract RandomNumberOracle is Ownable {
    mapping(uint256 => uint256[]) internal randomNumbers;

    uint256 requestN = 0;

    event RandomNumberRequested(
        uint256 indexed requestId,
        uint8 nums,
        uint256 min,
        uint256 max
    );
    event RandomNumberAdded(uint256 indexed requestId);

    function requestRandomNumbers(
        uint8 nums,
        uint256 min,
        uint256 max
    ) external returns (uint256) {
        requestN = requestN + 1;
        emit RandomNumberRequested(requestN, nums, min, max);
        return requestN;
    }

    function setRandomNumbers(uint256 requestId, uint256[] calldata randomNums)
        external
        onlyOwner
        returns (uint256)
    {
        randomNumbers[requestId] = randomNums;
        emit RandomNumberAdded(requestId);
        return requestId;
    }

    function getRandomNumbers(uint256 requestId)
        external
        view
        returns (uint256[] memory)
    {
        return randomNumbers[requestId];
    }
}