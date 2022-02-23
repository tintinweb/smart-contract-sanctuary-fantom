/**
 *Submitted for verification at FtmScan.com on 2022-02-23
*/

pragma solidity 0.8.11;



interface IERC20 {
    function balanceOf(address) view external returns (uint256);
    function transferFrom(address,address,uint256) external;
}


// File: <stdin>.sol

contract Splitter {

    IERC20 constant sex = IERC20(0xD31Fcd1f7Ba190dBc75354046F6024A9b86014d7);

    address constant receiverA = 0x5515da0FB3a31f78795Bd112b2eC2CCba3Ba1197;
    address constant receiverB = 0xfC3d825761e2AbbeC865f8E95b409a306c9b2782;
    address constant receiverC = 0x8e4FDd1176486d89DE6A171b390cb2AEF7296ffd;
    address constant receiverD = 0xE94709CbF7B8a71B3Fc31D9615073CA14Cf2709E;

    function split() external {
        uint amount = sex.balanceOf(msg.sender);
        sex.transferFrom(msg.sender, receiverA, amount * 79 / 100); //79%
        sex.transferFrom(msg.sender, receiverB, amount * 7 / 100);
        sex.transferFrom(msg.sender, receiverC, amount * 7 / 100);
        sex.transferFrom(msg.sender, receiverD, amount * 7 / 100);

    }

}