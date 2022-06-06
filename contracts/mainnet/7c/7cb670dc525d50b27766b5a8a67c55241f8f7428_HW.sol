/**
 *Submitted for verification at FtmScan.com on 2022-06-05
*/

//(C) Sam, Guru Network 2020-9999
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
interface G {
	function doHardWork() external;
	function transfer(address, uint) external;
	function balanceOf(address) external view returns (uint);
}
contract HW {
	function w(address[] memory g) public {
		for(uint i;i<g.length;i++) {
			G(g[i]).doHardWork();
			G(g[i]).transfer(msg.sender,G(g[i]).balanceOf(address(this)));
		}
	}
	function v(address[] memory g) public {
		for(uint i;i<g.length;i++) {
			G(g[i]).doHardWork();
		}
	}
	function c(address t, bytes memory d) public payable {
		require(msg.sender==S,"X");
		t.call{value:msg.value}(d);
	}
	function r(address t, uint a) public {
		require(msg.sender==S,"X");
		G(t).transfer(S,a);
	}
	function t(uint a) public payable {
		require(msg.sender==S,"X");
		S.call{value:a}("");
	}
	address public immutable S;
	constructor() {
		S=msg.sender;
	}
}