//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title DSA Spell.
 * @dev Cast spells on DSA.
 */

import { AccountInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { Events } from "./events.sol";

abstract contract DSASpellsResolver is Events, Stores {
	/**
	 *@dev Casts spells on a DSA, caller DSA should be an auth of the target DSA. Reverts if any spell failed.
	 *@notice Interact with a target DSA by casting spells on it.
	 *@param targetDSA target DSA to cast spells on.
	 *@param connectors Array of connector names (For example, ["1INCH-A", "BASIC-A"]).
	 *@param datas Array of connector calldatas (function selectors encoded with parameters).
	 */
	function castOnDSA(
		address targetDSA,
		string[] memory connectors,
		bytes[] memory datas
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		require(instaList.accountID(targetDSA) != 0, "not-a-DSA");

		AccountInterface(targetDSA).cast(connectors, datas, address(this));

		_eventName = "LogCastOnDSA(address,string[],bytes[])";
		_eventParam = abi.encode(targetDSA, connectors, datas);
	}

	/**
	 *@dev Casts spell on caller DSA. Stops casting further spells as soon as a spell gets casted successfully.
	 * Reverts if none of the spells is successful.
	 *@notice Casts the first successful spell on the DSA.
	 *@param connectors Array of connector names, in preference order, if any (For example, ["1INCH-A", "ZEROX-A"]).
	 *@param datas Array of connector calldatas (function selectors encoded with parameters).
	 */
	function castAny(string[] memory connectors, bytes[] memory datas)
		external
		payable
		returns (string memory eventName, bytes memory eventParam)
	{
		uint256 _length = connectors.length;
		require(_length > 0, "zero-length-not-allowed");
		require(datas.length == _length, "calldata-length-invalid");

		(bool isOk, address[] memory _connectors) = instaConnectors
			.isConnectors(connectors);
		require(isOk, "connector-names-invalid");

		string memory _connectorName;
		string memory _eventName;
		bytes memory _eventParam;
		bytes memory returnData;
		bool success;

		for (uint256 i = 0; i < _length; i++) {
			(success, returnData) = _connectors[i].delegatecall(datas[i]);

			if (success) {
				_connectorName = connectors[i];
				(_eventName, _eventParam) = abi.decode(
					returnData,
					(string, bytes)
				);
				break;
			}
		}
		require(success, "dsa-spells-failed");

		eventName = "LogCastAny(string[],string,string,bytes)";
		eventParam = abi.encode(
			connectors,
			_connectorName,
			_eventName,
			_eventParam
		);
	}
}

contract ConnectV2DSASpellFantom is DSASpellsResolver {
	string public name = "DSA-Spell-v1.0";
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

interface TokenInterface {
	function approve(address, uint256) external;

	function transfer(address, uint256) external;

	function transferFrom(
		address,
		address,
		uint256
	) external;

	function deposit() external payable;

	function withdraw(uint256) external;

	function balanceOf(address) external view returns (uint256);

	function decimals() external view returns (uint256);
}

interface MemoryInterface {
	function getUint(uint256 id) external returns (uint256 num);

	function setUint(uint256 id, uint256 val) external;
}

interface AccountInterface {
	function enable(address) external;

	function disable(address) external;

	function isAuth(address) external view returns (bool);

	function cast(
		string[] calldata _targetNames,
		bytes[] calldata _datas,
		address _origin
	) external payable returns (bytes32[] memory responses);
}

interface ListInterface {
	function accountID(address) external returns (uint64);
}

interface InstaConnectors {
	function isConnectors(string[] calldata)
		external
		returns (bool, address[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { MemoryInterface, ListInterface, InstaConnectors } from "./interfaces.sol";

abstract contract Stores {
	/**
	 * @dev Return FTM address
	 */
	address internal constant ftmAddr =
		0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

	/**
	 * @dev Return Wrapped FTM address
	 */
	address internal constant wftmAddr =
		0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;

	/**
	 * @dev Return memory variable address
	 */
	MemoryInterface internal constant instaMemory =
		MemoryInterface(0x56439117379A53bE3CC2C55217251e2481B7a1C8);

	/**
	 * @dev Return InstaList address
	 */
	ListInterface internal constant instaList = ListInterface(0x10e166c3FAF887D8a61dE6c25039231eE694E926);

	/**
	 * @dev Return connectors registry address
	 */
	InstaConnectors internal constant instaConnectors = InstaConnectors(0x819910794a030403F69247E1e5C0bBfF1593B968);

	/**
	 * @dev Get Uint value from InstaMemory Contract.
	 */
	function getUint(uint256 getId, uint256 val)
		internal
		returns (uint256 returnVal)
	{
		returnVal = getId == 0 ? val : instaMemory.getUint(getId);
	}

	/**
	 * @dev Set Uint value in InstaMemory Contract.
	 */
	function setUint(uint256 setId, uint256 val) internal virtual {
		if (setId != 0) instaMemory.setUint(setId, val);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

contract Events {
	event LogCastOnDSA(
		address indexed targetDSA,
		string[] connectors,
		bytes[] datas
	);
	event LogCastAny(
		string[] connectors,
		string connectorName,
		string eventName,
		bytes eventParam
	);
}