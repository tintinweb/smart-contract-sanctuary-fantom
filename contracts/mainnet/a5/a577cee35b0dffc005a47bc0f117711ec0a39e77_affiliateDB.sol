/**
 *Submitted for verification at FtmScan.com on 2022-09-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
        external
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
    //partner-Role
    mapping(address => bool) internal _partners;

    modifier onlyPartner() {
        require(
            _partners[msg.sender] == true || address(this) == msg.sender,
            "Caller is not an affiliate"
        );
        _;
    }

    function addpartner(address _partner)
        external
        onlyThor
    {
        _partners[_partner] = true;
    }

    function delpartner(address _partner)
        external
        onlyThor
    {
        delete _partners[_partner];
    }

    function disablepartner(address _partner)
        external
        onlyThor
    {
        _partners[_partner] = false;
    }

    function ispartner(address _address)
        external
        view
        returns (bool allowed)
    {
        allowed = _partners[_address];
    }

    function relinquishPartner() external onlyPartner {
        delete _partners[msg.sender];
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

contract affiliateDB is MjolnirRBAC {

//Partnership Level Affiliate

    struct PointTable {
        uint256 points;
        uint256 spent;
    }

    mapping(address => PointTable) point;

    function setPoints(address user, uint256 value) external onlyThor {
        point[user].points = value;
    }
    
    function getPoints(address user) public view returns(uint256) {
        return point[user].points;
    }

    function setSpent(address user, uint256 value) public onlyThor {
        point[user].spent = value;
    }
    
    function getSpent(address user) public view returns(uint256) {
        return point[user].spent;
    }

    function lifetime(address user) external view returns(uint256) {
        return getPoints(user) + getSpent(user);
    }
}