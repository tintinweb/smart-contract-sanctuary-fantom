/**
 *Submitted for verification at FtmScan.com on 2022-09-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

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
        onlyOwner
    {
        _partners[_partner] = true;
    }

    function delpartner(address _partner)
        external
        onlyOwner
    {
        delete _partners[_partner];
    }

    function disablepartner(address _partner)
        external
        onlyOwner
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

interface IAffiliateDB {

    function addpartner(address _partner)
        external;

    function delpartner(address _partner)
        external;

    function disablepartner(address _partner)
        external;

    function ispartner(address _address)
        external
        view
        returns (bool allowed);

    function setPoints(address user, uint256 value) external;
    
    function getPoints(address user) external view returns(uint256);

    function setSpent(address user, uint256 value) external;
    
    function getSpent(address user) external view returns(uint256);

    function lifetime(address user) external view returns(uint256);
}

interface IPackbuy {

        function remoteMint(address account, uint256 amount) external;

}


interface ILIQUIDRNG {

	function random1(uint256 mod, uint256 demod) external view returns (uint256);
 	function requestMixup() external;
}

contract affiliateLogicV1 is MjolnirRBAC {

    address buyPacks = 0xa627CA964DC42AB46bF6ABc3B3bbBd292C864203;
    address randomizer = 0xb782EF2742611255e3876F91639e9412A36b3Da3;
    address affDB = 0xa577ceE35b0dfFc005a47Bc0f117711EC0A39e77;
    IAffiliateDB db = IAffiliateDB(affDB);
    ILIQUIDRNG rng = ILIQUIDRNG(randomizer);
    IPackbuy bp = IPackbuy(affDB);

//Admin

    function setRNG(address rngAddr) external onlyThor {
        randomizer = rngAddr;
    }

    function setDB(address dbAddr) external onlyThor {
        affDB = dbAddr;
    }

    function setPacks(address packAddr) external onlyThor {
        buyPacks = packAddr;
    }

//Partner Affiliate

    uint256 partPerc = 10;

    function newLexAffiliate(address user) external onlyThor {
        db.addpartner(user);
    }

    function removeLexAffiliate(address user) external onlyThor {
        db.disablepartner(user);
    }

    function deleteLexAffiliate(address user) external onlyThor {
        db.delpartner(user);
    }

    function setPartnerPercent(uint256 value) external onlyThor {
        partPerc = value;
    }

    function getPartnerPercent() external view returns(uint256) {
        return partPerc;
    }

    function getPartnerStatus(address user) external view returns(bool) {
        return db.ispartner(user);
    }

//Standard Affiliate
    
    uint256 public perBuy = 5;
    uint256 public perOpen = 1;
    uint256 public prizePrice = 100;

    function packBuyRew(address user, uint256 amt) external onlyThor {
        db.setPoints(user,db.getPoints(user) + (perBuy * amt));
    }

    function packOpenNew(address user, uint256 amt) external onlyThor {
        db.setPoints(user,db.getPoints(user) + (perOpen * amt));
    }

    function myPoints(address user) public view returns(uint256) {
        return db.getPoints(user);
    }

    function mySpentPoints(address user) public view returns(uint256) {
        return db.getSpent(user);
    }

    function lifetimeTotal(address user) public view returns(uint256) {
        return db.lifetime(user);
    }

    function rollForPrize() external {
    require(myPoints(msg.sender) >= prizePrice);
    rng.requestMixup();
    db.setPoints(msg.sender, db.getPoints(msg.sender) - 100);
    bp.remoteMint(msg.sender,rng.random1(5,1));
    }

    function setPointsPerBuy(uint256 value) external onlyThor {
        perBuy = value;
    }

    function setPointsPerOpen(uint256 value) external onlyThor {
        perOpen = value;
    }

    function setPrizePrice(uint256 value) external onlyThor {
        prizePrice = value;
    }
}