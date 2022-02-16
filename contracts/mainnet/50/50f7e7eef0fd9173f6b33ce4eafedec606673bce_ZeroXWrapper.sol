/**
 *Submitted for verification at FtmScan.com on 2022-02-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ZeroXWrapper {
        address payable public zeroXExchangeProxy;
        event Output(bytes data, uint256 rem);
        address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
        constructor () {
             zeroXExchangeProxy = payable(0xDEF189DeAEF76E379df891899eb5A00a94cBC250);
        }



    function sendTration(uint256 amount,  bytes memory swapExtraData ) external payable  {

            (, bytes memory result) = zeroXExchangeProxy.call{
                value: amount
            }(swapExtraData);

        (
    
            , 
            ,
            uint256 _deadline

        ) = abi.decode(result, (uint256, uint256, uint256));

            emit Output(result, _deadline);


    }
        // Function to receive Ether. msg.data must be empty
    receive() external payable {}
}