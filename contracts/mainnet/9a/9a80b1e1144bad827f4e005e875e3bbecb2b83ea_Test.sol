/**
 *Submitted for verification at FtmScan.com on 2022-04-13
*/

pragma solidity 0.7.6;


interface IWETH  {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function balanceOf(address a) external returns(uint);
}

contract Test {
    address public weth = 0xAeaaf0e2c81Af264101B9129C00F4440cCF0F720;

    receive() external payable {
        // _require(msg.sender == address(_WETH()), Errors.ETH_TRANSFER);
    }

    function w() public {
        uint bal = IWETH(weth).balanceOf(address(this));
        IWETH(weth).withdraw(bal);
    }

    function test() public payable returns(uint){
        uint a = msg.value;
        return a;
    }
    function withdraw() public  {
       msg.sender.transfer(address(this).balance);
    }
}