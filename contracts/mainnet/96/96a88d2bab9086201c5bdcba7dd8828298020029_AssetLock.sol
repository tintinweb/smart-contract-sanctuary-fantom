/**
 *Submitted for verification at FtmScan.com on 2022-11-06
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract AssetLock{


    constructor(){admin = msg.sender;}

    ERC20 Token;
    address admin;

    modifier onlyAdmin{

        require(msg.sender == admin, "not admin");
        _;
    }

    function sweep() public onlyAdmin{

        (bool sent,) = admin.call{value: (address(this)).balance}("");
        require(sent, "transfer failed");
    }

    function sweepToken(ERC20 WhatToken) public onlyAdmin{

        WhatToken.transfer(admin, WhatToken.balanceOf(address(this)));
    }
}

interface ERC20{
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint);
}