//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Insta dex simulation.
 * @dev swap.
 */

import { Events } from "./events.sol";
import "./helpers.sol";

abstract contract InstaDexSimulationResolver is Events, Helpers {
	/**
	 * @dev Simulation swap using Insta dex swap contract
	 * @param sellToken The token to sell/swap
	 * @param buyToken The token to buy
	 * @param sellAmount The sell token amount
	 * @param buyAmount The buy token amount
	 * @param setId Set token amount at this ID in `InstaMemory` Contract.
	 * @param getId Get token amount at this ID in `InstaMemory` Contract.
	 */
	function swap(
		address sellToken,
		address buyToken,
		uint256 sellAmount,
		uint256 buyAmount,
		uint256 setId,
		uint256 getId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		sellAmount = getUint(getId, sellAmount);
		uint256 nativeAmount;

		if (sellToken == ftmAddr) {
			sellAmount = sellAmount == uint256(-1)
				? address(this).balance
				: sellAmount;
			nativeAmount = sellAmount;
		} else {
			TokenInterface tokenContract = TokenInterface(sellToken);

			sellAmount = sellAmount == uint256(-1)
				? tokenContract.balanceOf(address(this))
				: sellAmount;

			approve(tokenContract, address(dexSimulation), sellAmount);
		}

		InstaDexSimulation(dexSimulation).swap{ value: nativeAmount }(
			sellToken,
			buyToken,
			sellAmount,
			buyAmount
		);

		setUint(setId, buyAmount);

		_eventName = "LogSimulateSwap(address,address,uint256,uint256)";
		_eventParam = abi.encode(sellToken, buyToken, sellAmount, buyAmount);
	}
}

contract ConnectV2InstaDexSimulationFantom is InstaDexSimulationResolver {
	string public name = "Instadapp-DEX-Simulation-v1";
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
	event LogSimulateSwap(
		address sellToken,
		address buyToken,
		uint256 sellAmount,
		uint256 buyAmount
	);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./interfaces.sol";
import { Basic } from "../../common/basic.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";

abstract contract Helpers is Stores, Basic {
	/**
	 * @dev dexSimulation Address
	 */
	address internal constant dexSimulation =
		0xbD07728E20c49F0Fa22c82915955fbeA5E203a6a;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface InstaDexSimulation {
	function swap(
		address sellToken,
		address buyToken,
		uint256 sellAmount,
		uint256 buyAmount
	) external payable;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { TokenInterface } from "./interfaces.sol";
import { Stores } from "./stores.sol";
import { DSMath } from "./math.sol";

abstract contract Basic is DSMath, Stores {
	function convert18ToDec(uint256 _dec, uint256 _amt)
		internal
		pure
		returns (uint256 amt)
	{
		amt = (_amt / 10**(18 - _dec));
	}

	function convertTo18(uint256 _dec, uint256 _amt)
		internal
		pure
		returns (uint256 amt)
	{
		amt = mul(_amt, 10**(18 - _dec));
	}

	function getTokenBal(TokenInterface token)
		internal
		view
		returns (uint256 _amt)
	{
		_amt = address(token) == ftmAddr
			? address(this).balance
			: token.balanceOf(address(this));
	}

	function getTokensDec(TokenInterface buyAddr, TokenInterface sellAddr)
		internal
		view
		returns (uint256 buyDec, uint256 sellDec)
	{
		buyDec = address(buyAddr) == ftmAddr ? 18 : buyAddr.decimals();
		sellDec = address(sellAddr) == ftmAddr ? 18 : sellAddr.decimals();
	}

	function encodeEvent(string memory eventName, bytes memory eventParam)
		internal
		pure
		returns (bytes memory)
	{
		return abi.encode(eventName, eventParam);
	}

	function approve(
		TokenInterface token,
		address spender,
		uint256 amount
	) internal {
		try token.approve(spender, amount) {} catch {
			token.approve(spender, 0);
			token.approve(spender, amount);
		}
	}

	function changeftmAddress(address buy, address sell)
		internal
		pure
		returns (TokenInterface _buy, TokenInterface _sell)
	{
		_buy = buy == ftmAddr ? TokenInterface(wftmAddr) : TokenInterface(buy);
		_sell = sell == ftmAddr
			? TokenInterface(wftmAddr)
			: TokenInterface(sell);
	}

	function convertFtmToWftm(
		bool isFtm,
		TokenInterface token,
		uint256 amount
	) internal {
		if (isFtm) token.deposit{ value: amount }();
	}

	function convertWftmToFtm(
		bool isFtm,
		TokenInterface token,
		uint256 amount
	) internal {
		if (isFtm) {
			approve(token, address(token), amount);
			token.withdraw(amount);
		}
	}
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
}

interface InstaConnectors {
	function isConnectors(string[] calldata)
		external
		returns (bool, address[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { MemoryInterface } from "./interfaces.sol";

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

contract DSMath {
	uint256 constant WAD = 10**18;
	uint256 constant RAY = 10**27;

	function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = SafeMath.add(x, y);
	}

	function sub(uint256 x, uint256 y)
		internal
		pure
		virtual
		returns (uint256 z)
	{
		z = SafeMath.sub(x, y);
	}

	function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = SafeMath.mul(x, y);
	}

	function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = SafeMath.div(x, y);
	}

	function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = SafeMath.add(SafeMath.mul(x, y), WAD / 2) / WAD;
	}

	function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = SafeMath.add(SafeMath.mul(x, WAD), y / 2) / y;
	}

	function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = SafeMath.add(SafeMath.mul(x, RAY), y / 2) / y;
	}

	function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = SafeMath.add(SafeMath.mul(x, y), RAY / 2) / RAY;
	}

	function toInt(uint256 x) internal pure returns (int256 y) {
		y = int256(x);
		require(y >= 0, "int-overflow");
	}

	function toRad(uint256 wad) internal pure returns (uint256 rad) {
		rad = mul(wad, 10**27);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}