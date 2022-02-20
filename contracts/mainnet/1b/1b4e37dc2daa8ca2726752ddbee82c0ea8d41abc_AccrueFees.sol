/**
 *Submitted for verification at FtmScan.com on 2022-02-20
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface ICook{
    function suckFees(uint pid) external;
    function masterchef() view external returns(address);
}

interface IMasterchef{
    function poolLength() external view returns(uint);
}

contract AccrueFees{
    address public cook = 0xED335Fc47eba20E1DB475911570a3a9334583311;
    uint public i;

    function exec() public{
        address chef = ICook(cook).masterchef();
        uint length = IMasterchef(chef).poolLength();
        if(i == length) i = 0;
        try ICook(cook).suckFees(i){
            i++;
        }catch{
            i++;
            exec();
        }
    }
}