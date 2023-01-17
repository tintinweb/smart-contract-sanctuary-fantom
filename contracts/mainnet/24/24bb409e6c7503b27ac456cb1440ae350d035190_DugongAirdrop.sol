/**
 *Submitted for verification at FtmScan.com on 2023-01-17
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract DugongAirdrop {
    event DropEnabled(bool isActive);
    event DropDisabled(bool isActive);
    event Airdrop(address indexed sender, address indexed recipient, uint256 amount);

    address private _owner_;
    address private _dugongTreasury_;
    IERC20 private _token_;
    uint256 private _drop_;
    bool public _isActive_;
    mapping(address => bool) public _claimedDrop_;

    constructor() {
        _owner_ = 0xC3c8159Dc7310d86322B3FA56487884130f8FB37;
        _dugongTreasury_ = 0x21ADA3c422e85640170a3D2e1ec7fc329d4f7dbB;
        _token_ = IERC20(0x3023DE5BC36281e1Fc55bDcC12C31A09a51e8AFb);
        _drop_ = (3/2) * (1 ether);
        _isActive_ = false;
    }

    modifier onlyOwner {
        require(msg.sender == _owner_, "Access Denied, You're not the Owner.");
        _;
    }

    modifier run {
        require(_isActive_, "Airdrop is Disabled.");
        _;
    }

    function enableDrop() onlyOwner external returns (bool) {
        require(!_isActive_, "Already Enabled.");
        _isActive_ = !_isActive_;
        emit DropEnabled(_isActive_);
        return true;
    }
    
    function disableDrop() onlyOwner external returns (bool) {
        require(_isActive_, "Already Disabled.");
        _isActive_ = !_isActive_;
        emit DropDisabled(_isActive_);
        return true;
    }

    function airdrop() run external returns (bool) {
        require(_token_.allowance(_dugongTreasury_, address(this)) >= _drop_, "Low Allowance");
        require(!_claimedDrop_[msg.sender], "Already Claimed.");
        _token_.transferFrom(_dugongTreasury_, msg.sender, _drop_);
        emit Airdrop(address(this), msg.sender, _drop_);
        _claimedDrop_[msg.sender] = true;
        return true;
    }

    function airdrop(address[] memory recipient) onlyOwner run external returns (bool) {
        require(recipient.length <= 2000, "Reached Limit (Max of 2000 addresses are allowed per transaction).");
        require(_token_.allowance(_dugongTreasury_, address(this)) >= recipient.length * _drop_, "Low Allowance");
        for(uint16 i=0; i<recipient.length; i++) {
            if(!_claimedDrop_[recipient[i]]) {
                _token_.transferFrom(_dugongTreasury_, recipient[i], _drop_);
                emit Airdrop(address(this), msg.sender, _drop_);
                _claimedDrop_[recipient[i]] = true;
            }
        }
        return true;
    }
}