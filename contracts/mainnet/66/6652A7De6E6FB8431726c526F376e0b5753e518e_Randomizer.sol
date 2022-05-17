// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Randomizer {
	uint256 public randomNumber;
    uint8 constant keyLengthForEachBuy = 15;
	uint8 constant _black_maxNumber = 52;
	uint64 public _maxNumber = 10;

	function randomNumberGenerate() external view returns (uint256[] memory)
	{
		uint256[] memory orgArr= new uint256[](52);
		for (uint256 i = 0; i < 52 ; i++) {
			orgArr[i] = i + 1;
		}
		for (uint256 j = 0; j < 51; j++) {
			uint256 n = j + uint256(keccak256(abi.encodePacked(block.timestamp))) % (orgArr.length - j);
			uint256 temp = orgArr[n];
			orgArr[n] = orgArr[j];
			orgArr[j] = temp;
		}

		return orgArr;
	}

	function generateNumberIndexKey(uint256 first, uint256 second, uint256 third, uint256 fourth) external view returns (uint64[keyLengthForEachBuy] memory) {
		uint64[4] memory tempNumber;
		tempNumber[0] = uint64(first);
		tempNumber[1] = uint64(second);
		tempNumber[2] = uint64(third);
		tempNumber[3] = uint64(fourth);

		uint64[keyLengthForEachBuy] memory result;
		result[0] = (tempNumber[0]*256*256*256*256*256*256 + 1*256*256*256*256*256 
		+ tempNumber[1]*256*256*256*256 + 2*256*256*256 + tempNumber[2]*256*256 + 3*256 + tempNumber[3])%_maxNumber;

		result[1] = (tempNumber[0]*256*256*256*256 + 1*256*256*256 + tempNumber[1]*256*256 + 2*256+ tempNumber[2])%_maxNumber;
		result[2] = (tempNumber[0]*256*256*256*256 + 1*256*256*256 + tempNumber[1]*256*256 + 3*256+ tempNumber[3])%_maxNumber;
		result[3] = (tempNumber[0]*256*256*256*256 + 2*256*256*256 + tempNumber[2]*256*256 + 3*256 + tempNumber[3])%_maxNumber;
		result[4] = (1*256*256*256*256*256 + tempNumber[1]*256*256*256*256 + 2*256*256*256 + tempNumber[2]*256*256 + 3*256 + tempNumber[3])%_maxNumber;

		result[5] = (tempNumber[0]*256*256 + 1*256+ tempNumber[1])%_maxNumber;
		result[6] = (tempNumber[0]*256*256 + 2*256+ tempNumber[2])%_maxNumber;
		result[7] = (tempNumber[0]*256*256 + 3*256+ tempNumber[3])%_maxNumber;
		result[8] = (1*256*256*256 + tempNumber[1]*256*256 + 2*256 + tempNumber[2])%_maxNumber;
		result[9] = (1*256*256*256 + tempNumber[1]*256*256 + 3*256 + tempNumber[3])%_maxNumber;
		result[10] = (2*256*256*256 + tempNumber[2]*256*256 + 3*256 + tempNumber[3])%_maxNumber;
		result[11] = (2*256*256*256 + tempNumber[2]*256*256 + 3*256 + tempNumber[3])%_maxNumber;
		result[12] = (4*256*256*256 + tempNumber[3]*256*256 + 3*256 + tempNumber[3])%_maxNumber;
		result[13] = (5*256*256*256 + tempNumber[3]*256*256 + 3*256 + tempNumber[3])%_maxNumber;
		result[14] = (6*256*256*256 + tempNumber[3]*256*256 + 3*256 + tempNumber[3])%_maxNumber;

		return result;
	}
}