// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./BEP20.sol";

contract NTLY is BEP20 {

    uint16 public maxHoldingRate = 500;
    mapping(address => bool) private _includeToBlackList;
    address private _operator;

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    modifier blackList(address sender, address recipent) {
        if (_includeToBlackList[sender] == true || _includeToBlackList[recipent] == true) {
            require(_includeToBlackList[sender] == false, "blackList: you have been blacklisted as a bot");
            require(_includeToBlackList[recipent] == false, "blackList: you have been blacklisted as a bot");
        }
        _;
    }

    constructor () public BEP20("Natively", "NTLY") {
        _operator = msg.sender;
        _mint(msg.sender, 1600 ether);
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override blackList(sender, recipient) {
        super._transfer(sender, recipient, amount);
    }

    function maxHolding() public view returns (uint256) {
        return totalSupply().mul(maxHoldingRate).div(10000);
    }

    function setIncludeToBlackList(address _account) public onlyOperator {
        if (balanceOf(_account) > maxHolding()) {
            _includeToBlackList[_account] = true;
        } 
        else {
            _includeToBlackList[_account] = false;
        }
    }

    function operator() public view returns (address) {
        return _operator;
    }

    function transferOperator(address newOperator) public onlyOperator {
        require(newOperator != address(0), "transferOperator: new operator cannot be zero address");
        _operator = newOperator;
    }
}