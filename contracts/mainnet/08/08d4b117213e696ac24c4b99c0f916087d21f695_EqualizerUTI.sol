/**
 *Submitted for verification at FtmScan.com on 2023-02-04
*/

/**
 *  EQUALIZER EXCHANGE
 *  The New Liquidity Hub of Fantom chain!
 *  https://equalizer.exchange  (Dapp)
 *  https://discord.gg/MaMhbgHMby   (Community)
 *
 *
 *  UTI - Unified Trading Interface
 *  - Cross-protocol liquidity aggregation
 *
 *
 *  Contributors:
 *   -   Sam 543#3017, Equalizer Team
 *
 *
 *   SPDX-License-Identifier: UNLICENSED
 *
*/

pragma solidity 0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IWrap {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

interface IClaims {
	function claim() external;
	function claim(address) external;
	function claim(address, address) external;
	function claim(bytes calldata) external;
}

contract EqualizerUTI {
	//This contract is the entry point. It has allowance from the Trader to spend their tokens.
	//This contract must NOT be behind a proxy!
	//This contract must NOT implement 'transferFrom()' in any form other than the main 'trade()' function.
	//This contract IS the UTI. Comparable to a Router contract.
	//This contract IS a Meta DEX-Aggregator.

	address public FTM = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
	address public WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
	address public MS;	///Team MultiSig

    /// simple re-entrancy check
    bool internal _locked;
    modifier lock() {
        require(!_locked, "No re-entrancy");
        _locked = true;
        _;
        _locked = false;
    }

	constructor() {
		MS = msg.sender;
	}

	event Trade(uint, address indexed, address indexed, address indexed, uint, uint, address, bytes);

	//Only when a user calls Trade, 'ain' amount of their 'tin' tokens will be taken.
	//If the User does not get back 'aou' amount of 'tou' tokens back, whole transaction MUST revert.
	function trade(
		address tin,
		address tou,
		uint256 ain,
		uint256 aou,
		address target,
		bytes calldata data
	) lock external payable {
		if(tin==FTM) {
			IWrap(WFTM).deposit{value:msg.value}();
		}
		else {
			IERC20(tin).transferFrom(msg.sender, address(this), ain);
		}
		IERC20 TIN = IERC20(tin);
		if(TIN.allowance(address(this), target) < ain) {
			TIN.approve(target, type(uint256).max);
		}
		target.call(data);
		///trade happens here
		if(tou==FTM) {
			IWrap W = IWrap(WFTM);
			IERC20 TOU = IERC20(tou);
			uint AOU = address(this).balance;
			require(AOU>aou, "Insufficient Output!");
			W.withdraw(AOU);
			payable(msg.sender).call{value:AOU}("");
		}
		else {
			IERC20 TOU = IERC20(tou);
			uint AOU = TOU.balanceOf(address(this));
			require(AOU>aou, "Insufficient Output!");
			TOU.transfer( msg.sender, AOU );
		}
		emit Trade(block.timestamp, msg.sender, tin, tou, ain, aou, target, data);
	}

	///veCRV-style basic claims
	function claim0(address rewarder, address[] memory rewards) lock external payable {
		require(msg.sender == MS );
		IClaims(rewarder).claim();
		for(uint i; i<rewards.length;i++) {
			IERC20 T = IERC20(rewards[i]);
			T.transfer(MS, T.balanceOf(address(this)));
		}
	}

	///veCRV-style token-based claims
	function claim1(address rewarder, address a1, address[] memory rewards) lock external payable {
		require(msg.sender == MS );
		IClaims(rewarder).claim(a1);
		for(uint i; i<rewards.length;i++) {
			IERC20 T = IERC20(rewards[i]);
			T.transfer(MS, T.balanceOf(address(this)));
		}
	}

	///Complex ve-style claims: claim(address,address)
	function claim2(address rewarder, address a1, address a2, address[] memory rewards) lock external payable {
		require(msg.sender == MS );
		IClaims(rewarder).claim(a1,a2);
		for(uint i; i<rewards.length;i++) {
			IERC20 T = IERC20(rewards[i]);
			T.transfer(MS, T.balanceOf(address(this)));
		}
	}

	///Custom claims: claim(bytes)
	function claim3(address rewarder, bytes calldata b1, address[] memory rewards) lock external payable {
		require(msg.sender == MS );
		IClaims(rewarder).claim(b1);
		for(uint i; i<rewards.length;i++) {
			IERC20 T = IERC20(rewards[i]);
			T.transfer(MS, T.balanceOf(address(this)));
		}
	}

	function changeMS(address ms) lock external {
		require(msg.sender == MS );
		MS = ms;
	}
}