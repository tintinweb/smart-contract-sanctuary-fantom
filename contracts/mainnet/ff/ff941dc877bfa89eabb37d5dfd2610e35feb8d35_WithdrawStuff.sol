/**
 *Submitted for verification at FtmScan.com on 2022-03-15
*/

pragma solidity ^0.6.7;

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract WithdrawStuff {

    function withdrawAll() external {
        address wftm = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
        address tarot = 0xC5e2B037D30a390e62180970B3aa4E91868764cD;
        address governance = 0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C;

        IERC20(tarot).transfer(
            governance,
            IERC20(tarot).balanceOf(address(this))
        );

        IERC20(wftm).transfer(
            governance,
            IERC20(wftm).balanceOf(address(this))
        );
    }
}