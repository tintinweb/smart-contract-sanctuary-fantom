/**
 *Submitted for verification at FtmScan.com on 2023-01-17
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface iDugongSale {
    function isActive() external view returns (bool);
    function price() external view returns (uint256);
    function goal() external view returns (uint256);
    function score() external view returns (uint256);
    function minBuy() external view returns (uint256);
    function maxBuy() external view returns (uint256);
}

contract DugongSale is iDugongSale {
    event SaleEnabled(bool isActive);
    event SaleDisabled(bool isActive);
    event BroughtTokens(address indexed sender, address indexed recipient, uint256 amount);

    address private _dugongTreasury_;
    address private _owner_;
    IERC20 private _token_;
    bool private _isActive_;
    uint256 private _reserve_;
    uint256 private _goal_;
    uint256 private _minBuy_;
    uint256 private _maxBuy_;
    uint256 private _score_;
    uint256 private _sold_;
    
    constructor() {
        _owner_ = 0xC3c8159Dc7310d86322B3FA56487884130f8FB37;
        _dugongTreasury_ = 0x21ADA3c422e85640170a3D2e1ec7fc329d4f7dbB;
        _token_ = IERC20(0x3023DE5BC36281e1Fc55bDcC12C31A09a51e8AFb);
        _isActive_ = false;
        _reserve_ = 300000 ether;
        _goal_ = 1000000 ether;
        _minBuy_ = 50 ether;
        _maxBuy_ = 5000 ether;
        _score_ = 0 ether;
        _sold_ = 0 ether;
    }
    
    modifier onlyOwner {
        require(msg.sender == _owner_, "Access Denied, You're not the Owner.");
        _;
    }

    modifier run {
        require(_isActive_, "Sale is Disabled.");
        _;
    }

    function enableSale() onlyOwner external returns (bool) {
        require(!_isActive_, "Sale is already Enabled.");
        _isActive_ = !_isActive_;
        emit SaleEnabled(_isActive_);
        return true;
    }

    function disableSale() onlyOwner external returns (bool) {
        require(_isActive_, "Sale is already Disabled.");
        _isActive_ = !_isActive_;
        emit SaleDisabled(_isActive_);
        return true;
    }

    function isActive() external view returns (bool) {
        return _isActive_;
    }

    function price() external view returns (uint256) {
        return (_reserve_ / _goal_) * (1 ether);
    }

    function goal() external view returns (uint256) {
        return _goal_;
    }

    function score() external view returns (uint256) {
        return _score_;
    }

    function minBuy() external view returns (uint256) {
        return _minBuy_;
    }

    function maxBuy() external view returns (uint256) {
        return _maxBuy_;
    }

    function buy() run public payable returns (bool) {
        require((msg.value >= _minBuy_) && (msg.value <= _maxBuy_), "5000 FTM >= Amount >= 50 FTM.");
        require(_token_.allowance(_dugongTreasury_, address(this)) >= msg.value * (_reserve_ / _goal_), "Low Allowance.");
        payable(_owner_).transfer(1 * msg.value / 10);
        payable(_dugongTreasury_).transfer(9 * msg.value / 10);
        _token_.transferFrom(_dugongTreasury_, msg.sender, msg.value * (_reserve_ / _goal_));
        emit BroughtTokens(address(this), msg.sender, msg.value * (_reserve_ / _goal_));
        _score_ += msg.value;
        _sold_ += (msg.value * (_reserve_ / _goal_));
        return true;
    }

    receive() external payable {
        buy();
    }
}