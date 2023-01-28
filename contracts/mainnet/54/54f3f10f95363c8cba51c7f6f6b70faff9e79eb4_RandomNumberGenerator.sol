/**
 *Submitted for verification at FtmScan.com on 2023-01-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract RandomNumberGenerator{

    //Will be used for randomness using balances
    address private spiritContract=0x5Cc61A78F164885776AA610fb0FE1257df78E59B;
    address private booContract=0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE;
    address private brushContract=0x85dec8c4B2680793661bCA91a8F129607571863d;

    function getRandomNumber() public view returns (uint256){
        uint256 _random = uint256(
                        keccak256(
                            abi.encodePacked(
                                getRandomBalances(),
                                msg.sender,
                                block.timestamp,
                                block.difficulty,
                                blockhash(block.number - 1)
                            )
                        )
                    );
        return _random;
    }

    function getRandomBalances() private view returns (uint256 balances) {
        IERC20 _spirit = IERC20(spiritContract);
        IERC20 _boo = IERC20(booContract);
        IERC20 _brush = IERC20(brushContract);
        //Get balances of each Masterchef/Pair
        balances = (_spirit.balanceOf(0x9083EA3756BDE6Ee6f27a6e996806FBD37F6F093) +_boo.balanceOf(0x2b2929E785374c651a81A63878Ab22742656DcDd) +_brush.balanceOf(0x452590b8Aa292b963a9d0f2B5E71bC7c927859b3));
    }
}