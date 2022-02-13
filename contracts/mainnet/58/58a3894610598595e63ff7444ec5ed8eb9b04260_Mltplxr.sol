/**
 *Submitted for verification at FtmScan.com on 2022-02-13
*/

pragma solidity ^0.4.16;

contract ERC20 {
  function transferFrom( address from, address to, uint value) returns (bool ok);
}

contract Mltplxr {

	function sendEth(address[] _to, uint256[] _value) payable returns (bool _success) {
		assert(_to.length == _value.length);
		assert(_to.length <= 255);
		uint256 beforeValue = msg.value;
		uint256 afterValue = 0;
		for (uint8 i = 0; i < _to.length; i++) {
			afterValue = afterValue + _value[i];
			assert(_to[i].send(_value[i]));
		}
		uint256 remainingValue = beforeValue - afterValue;
		if (remainingValue > 0) {
			assert(msg.sender.send(remainingValue));
		}
		return true;
	}
}