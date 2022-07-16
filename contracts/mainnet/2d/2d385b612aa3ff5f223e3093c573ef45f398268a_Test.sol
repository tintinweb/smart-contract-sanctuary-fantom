/**
 *Submitted for verification at FtmScan.com on 2022-07-15
*/

pragma solidity ^0.8.1;

contract Test {
    struct User {
        uint256 amount;
    }

    mapping(uint256 => User) public users;
    uint256 public count = 0;
    constructor() {
        _add(10);
        _add(15);
        _add(20);
    }


    function _add(uint256 amount) public {
        users[count] = User(amount);
        count++;
    }


    function test() external {
        User storage user;
        for (uint256 i = 0; i < count; i++) {
            user = users[i];
            user.amount= i + 10;
        }
    }
}