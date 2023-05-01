/**
 *Submitted for verification at FtmScan.com on 2023-05-01
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

/*


  /$$$$$$  /$$                                         /$$           /$$
 /$$__  $$|__/                                        |__/          | $$
| $$  \__/ /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$ /$$  /$$$$$$ | $$
| $$$$    | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/| $$ |____  $$| $$
| $$_/    | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$  /$$$$$$$| $$
| $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$ /$$__  $$| $$
| $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$| $$|  $$$$$$$| $$
|__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/|__/ \_______/|__/
                                                                        
                                                                        
                                                                        
  /$$$$$$                                    /$$                        
 /$$__  $$                                  | $$                        
| $$  \__//$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$$  /$$$$$$  /$$$$$$/$$$$ 
| $$$$   /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$| $$_  $$_  $$
| $$_/  | $$  \__/| $$$$$$$$| $$$$$$$$| $$  | $$| $$  \ $$| $$ \ $$ \ $$
| $$    | $$      | $$_____/| $$_____/| $$  | $$| $$  | $$| $$ | $$ | $$
| $$    | $$      |  $$$$$$$|  $$$$$$$|  $$$$$$$|  $$$$$$/| $$ | $$ | $$
|__/    |__/       \_______/ \_______/ \_______/ \______/ |__/ |__/ |__/
                                                                                                                                         
                                                                        
*/


contract Microdose {
    string public name = "Microdose";
    string public symbol = "mDose";
    uint256 public decimals = 18;
    uint256 public totalSupply = 400000000 * (10**decimals);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(_to != address(0));
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_from != address(0));
        require(_to != address(0));
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        
        return true;
    }
}