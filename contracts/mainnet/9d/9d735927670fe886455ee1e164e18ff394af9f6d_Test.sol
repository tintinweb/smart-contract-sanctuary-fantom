/**
 *Submitted for verification at FtmScan.com on 2023-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}


interface IWooStakingProxy {
    /* ----- Events ----- */

    event StakeOnProxy(address indexed user, uint256 amount);

    event WithdrawOnProxy(address indexed user, uint256 amount);

    event CompoundOnProxy(address indexed user);

    /* ----- State Variables ----- */

    function controllerChainId() external view returns (uint16);

    function controller() external view returns (address);

    function balances(address user) external view returns (uint256 balance);

    /* ----- Functions ----- */

    function estimateFees(uint8 _action, uint256 _amount) external view returns (uint256 messageFee);

    function stake(uint256 _amount) external payable;

    function stake(address _user, uint256 _amount) external payable;

    function unstake(uint256 _amount) external payable;

    function unstakeAll() external payable;

    function compound() external payable;
}



contract Test {

    IWooStakingProxy public stakingProxy;
    address public immutable woo;

    constructor() {
        woo = 0x6626c47c00F1D87902fc13EECfaC3ed06D5E8D8a;
        stakingProxy = IWooStakingProxy(0x749AcadA4dF3907629054d533207EB5CFb2B7d5C);
    }

    function compoundRewards1() public {
        address _user = 0x7C8A5d20b22Ce9b369C043A3E0091b5575B732d9;
        uint256 wooAmount = 100000;
        TransferHelper.safeApprove(woo, address(stakingProxy), wooAmount);
        stakingProxy.stake(_user, wooAmount);
    }

    function compoundRewards2() public payable {
        address _user = 0x7C8A5d20b22Ce9b369C043A3E0091b5575B732d9;
        uint256 wooAmount = 100000;
        TransferHelper.safeApprove(woo, address(stakingProxy), wooAmount);
        stakingProxy.stake{value: msg.value}(_user, wooAmount);
    }   

}