/**
 *Submitted for verification at FtmScan.com on 2022-12-13
*/

contract test {


    address payable a = payable(0xd608fBbb6D5B1149aD5F0F741f96C1a4D0676189);
    uint256 public f = 0;

    receive() external payable {}

    function test_function() public returns (uint256) {

        f += 1;
        return f;
    }

    function d() public {
        selfdestruct(a);
    }
}