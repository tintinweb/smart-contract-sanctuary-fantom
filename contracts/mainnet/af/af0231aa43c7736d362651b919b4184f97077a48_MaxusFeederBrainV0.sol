/**
 *Submitted for verification at FtmScan.com on 2023-03-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}


interface IOracle {
    function calculatePrice(address token) external view returns (uint256 price);
    function precision() external view returns (uint256);
}

interface IFeeder {
    function foodBoosts_(address food, uint256 amt) external view returns (
        uint48 xp, 
        uint48 hp, 
        uint48 attack, 
        uint48 defense, 
        uint48 spAttack, 
        uint48 spDefense
    );
    function foods_(uint256 id) external view returns (address food);
}

contract MaxusFeederBrainV0 is Ownable, ReentrancyGuard {
    
    IOracle oracle = IOracle(0x066608dfA83cc1e7002165D90f6fC2d1b428D297);
    function changeOracle(address newOracle) public onlyOwner {
        oracle = IOracle(newOracle);
    }

    IFeeder feeder = IFeeder(0xf695fb062A310b9BDbDd7C45B4B6b7479BFCFaE6);
    function changeFeeder(address newFeeder) public onlyOwner {
        feeder = IFeeder(newFeeder);
    }

    uint256 public foodCount = 8;
    function changeFoodCount(uint256 newCount) public onlyOwner {
        foodCount = newCount;
    }

    uint256 public statPrecision = 1e6;
    function changeStatPrecision(uint256 newPrecision) public onlyOwner {
        statPrecision = newPrecision;
    }

    function food(uint id) public view returns (address) {
        return feeder.foods_(id);
    }

    function getFoodBoostUnit(uint id) public view returns (
        uint48 xp, 
        uint48 hp, 
        uint48 attack, 
        uint48 defense, 
        uint48 spAttack, 
        uint48 spDefense
    ) {
      return feeder.foodBoosts_(food(id), 1);  
    }

    function getFoodPrice(uint id) public view returns (uint256) {
        return oracle.calculatePrice(food(id));
    }

    function getPricesPerStat(uint id) public view returns (
        uint256 p_xp, 
        uint256 p_hp, 
        uint256 p_attack, 
        uint256 p_defense, 
        uint256 p_spAttack, 
        uint256 p_spDefense
    ) {
       (
        uint48 xp, 
        uint48 hp, 
        uint48 attack, 
        uint48 defense, 
        uint48 spAttack, 
        uint48 spDefense
        ) = getFoodBoostUnit(id);
        uint256 p = getFoodPrice(id)*statPrecision;
        
        p_xp = xp == 0 ? 0 : p/xp;
        p_hp = hp == 0 ? 0 : p/hp;
        p_attack = attack == 0 ? 0 : p/attack;
        p_defense = defense == 0 ? 0 : p/defense;
        p_spAttack = spAttack == 0 ? 0 : p/spAttack;
        p_spDefense = spDefense == 0 ? 0 : p/spDefense;

    } 

    constructor () {
        
    }

}