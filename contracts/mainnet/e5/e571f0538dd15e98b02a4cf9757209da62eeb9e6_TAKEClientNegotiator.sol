/**
 *Submitted for verification at FtmScan.com on 2022-09-21
*/

// SPDX-License-Identifier: GPL-3.0

/*

This is the TAKE allocation / ANCAP refund distribution contract, deployed on FTM mainnet. You may now interact with it in order to officially submit your request for either a refund or your $TAKE allocation.

There are only 2 options available here - a refund and an allocation claim. You may choose only one, not both. The names of the functions of the contract you will be interacting with have been chosen to perfectly reflect their purpose so that everything is crystal clear and there are no misunderstandings.

They are: 

1. "requestTAKEAllocationAndForfeitANCAPRefund" (request TAKE allocation and forfeit ANCAP refund)

2. "requestANCAPRefundAndForfeitTAKEAllocation" (request ANCAP refund and forfeit TAKE allocation)

Choosing option 1 will entitle you to 100% of your $TAKE allocation and revoke your right to a refund. Choosing option 2 will entitle you to 100% of your proportional refund and revoke your right to a $TAKE allocation. 

By interacting with the contract and submitting your request to the blockchain in the form of one of the 2 functions listed above, you are irrevocably and irreversibly committing to one option (claim $TAKE allocation OR refund) and forfeiting the other (claim refund OR $TAKE allocation respectively).

You further acknowledge and confirm that you are not being influenced, incentivized, advised or otherwise requested to forfeit one in favor of the other. You are solely responsible for making your own decision. No one, including team members, in an official capacity or otherwise, can instruct or compel you to go for either option in any way.

*/

pragma solidity ^0.8.10;

interface IERC20 {

    function balanceOf(address to) external view returns (uint);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

interface TAKEMasterNegotiator {

    function requestANCAPRefundAndForfeitTAKEAllocation(address _participant) external;
    function requestTAKEAllocationAndForfeitANCAPRefund(address _participant) external;
    function claimTAKEAllocation(address _participant) external; 
    function claimANCAPRefund(address _participant) external;
    function base(address _participant) external view returns(uint256, uint256, bool, bool);
    function part(address _participant) external view returns(bool, bool, uint256, uint256, uint256, uint256);
    function nomics() external view returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256);
    function state() external view returns(bool, bool, bool, bool);

}

contract TAKEClientNegotiator {

    address owner;
    address masterNegotiator;

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Not owner!");
        _;
    }

    function configAddresses(address _masterNegotiator) public isOwner {
        masterNegotiator = _masterNegotiator;
    }

    function requestANCAPRefundAndForfeitTAKEAllocation(address _participant) public { 
        require(_participant == msg.sender);
        TAKEMasterNegotiator(masterNegotiator).requestANCAPRefundAndForfeitTAKEAllocation(msg.sender);
    }

    function requestTAKEAllocationAndForfeitANCAPRefund(address _participant) public {
        require(_participant == msg.sender);
        TAKEMasterNegotiator(masterNegotiator).requestTAKEAllocationAndForfeitANCAPRefund(msg.sender);
    }

    function claimTAKEAllocation(address _participant) public {
        require(_participant == msg.sender);
        TAKEMasterNegotiator(masterNegotiator).claimTAKEAllocation(msg.sender);
    }

    function claimANCAPRefund(address _participant) public {
        require(_participant == msg.sender);
        TAKEMasterNegotiator(masterNegotiator).claimANCAPRefund(msg.sender);
    }

    function base(address _participant) public view returns(uint256, uint256, bool, bool) {
        return TAKEMasterNegotiator(masterNegotiator).base(_participant);
    }

    function state() public view returns(bool, bool, bool, bool) {
        return TAKEMasterNegotiator(masterNegotiator).state();
    }

    function part(address _participant) public view returns(bool, bool, uint256, uint256, uint256, uint256) {
        return TAKEMasterNegotiator(masterNegotiator).part(_participant);
    }

    function nomics() public view returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return TAKEMasterNegotiator(masterNegotiator).nomics();
    }

    function withdrawTokenFromContract(address _token) public isOwner {
        IERC20(_token).transfer(owner, IERC20(_token).balanceOf(address(this)));
    }

    function withdrawFTMFromContract() public isOwner {          
        payable(owner).transfer(address(this).balance);
    }

    function getSelfAddress() public view returns(address) {
        return address(this);
    }

    receive() external payable { }
    fallback() external payable { }

}