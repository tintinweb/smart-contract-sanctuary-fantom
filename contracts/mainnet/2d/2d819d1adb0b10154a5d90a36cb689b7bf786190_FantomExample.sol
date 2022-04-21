/**
 *Submitted for verification at FtmScan.com on 2022-04-20
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

contract FantomExample {	

	function alwaysReverts() public {
		assert(1 == 2);
	}

	function addOne(uint256 value) public returns (uint256 sum) {
		sum = value + 1;
	}


	function badTransaction() public returns (uint256 three) {

		uint256 two = this.addOne(1);

		// trigger revert
		(bool success, bytes memory returnData) = 
			address(this).call(
				abi.encodePacked(this.alwaysReverts.selector)
			);
		
		three = this.addOne(two);
	}

}