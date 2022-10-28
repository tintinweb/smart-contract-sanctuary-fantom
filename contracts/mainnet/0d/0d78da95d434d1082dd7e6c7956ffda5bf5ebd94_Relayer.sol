/**
 *Submitted for verification at FtmScan.com on 2022-10-28
*/

contract Relayer{
    bool public status;

    function relay(address _target) external {
        (bool success,) = address(_target).call(abi.encodeWithSignature("execute()"));
        status = true;
    }
}