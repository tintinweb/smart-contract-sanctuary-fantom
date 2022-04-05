// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./ITarotRouter.sol";
import "./IERC20.sol";


contract Vault {
   
   address constant public TAROT_ROUTER = 0x283e62CFe14b352dB8e30A9575481DCbf589Ad98;
   address constant public WBTC = 0x321162Cd933E2Be498Cd2267a90534A804051b11;
   address constant public LENDING_POOL = 0x9800ac596E345E6a7179B33DeeaE2eFaf7C9B8E7;


    constructor() public {
        IERC20(LENDING_POOL).approve(TAROT_ROUTER, uint256(-1));
    }



   function deposit(uint256 _amount) public returns(uint256) { 
       IERC20(WBTC).transfer(address(this), _amount); 
       IRouter02(TAROT_ROUTER).mint(LENDING_POOL, _amount, msg.sender, block.timestamp);
   }

   function withdraw(uint256 _amount) public returns(uint256){  
       bytes memory callData = "";
       IRouter02(TAROT_ROUTER).redeem(LENDING_POOL, _amount, msg.sender, block.timestamp, callData);   
       }

}