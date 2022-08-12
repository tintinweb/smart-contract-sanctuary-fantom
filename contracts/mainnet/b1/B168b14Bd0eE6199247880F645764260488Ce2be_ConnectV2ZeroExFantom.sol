//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title 0x.
 * @dev On-chain DEX Aggregator.
 */

import {TokenInterface, MemoryInterface} from "../../common/interfaces.sol";
import {Stores} from "../../common/stores.sol";
import {ZeroExData} from "./interface.sol";
import {Helpers} from "./helpers.sol";
import {Events} from "./events.sol";

abstract contract ZeroEx is Helpers {
    /**
     * @notice Swap tokens on 0x
     * @dev Sell ETH/ERC20_Token using 0x.
     * @param buyAddr The address of the token to buy.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr The address of the token to sell.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAmt The amount of the token to sell.
     * @param unitAmt The amount of buyAmt/sellAmt with slippage.
     * @param callData Data from 0x API.
     * @param setId ID stores the amount of token brought.
     */
    function swap(
        address buyAddr,
        address sellAddr,
        uint256 sellAmt,
        uint256 unitAmt,
        bytes calldata callData,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        ZeroExData memory zeroExData = ZeroExData({
            buyToken: TokenInterface(buyAddr),
            sellToken: TokenInterface(sellAddr),
            unitAmt: unitAmt,
            callData: callData,
            _sellAmt: sellAmt,
            _buyAmt: 0
        });

        zeroExData = _swap(zeroExData, setId);

        _eventName = "LogSwap(address,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            buyAddr,
            sellAddr,
            zeroExData._buyAmt,
            zeroExData._sellAmt,
            0,
            setId
        );
    }
}

contract ConnectV2ZeroExFantom is ZeroEx {
    string public name = "0x-V4";
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import {TokenInterface} from "../../common/interfaces.sol";

struct ZeroExData {
    TokenInterface sellToken;
    TokenInterface buyToken;
    uint256 _sellAmt;
    uint256 _buyAmt;
    uint256 unitAmt;
    bytes callData;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import {TokenInterface} from "../../common/interfaces.sol";
import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";
import {ZeroExData} from "./interface.sol";

contract Helpers is DSMath, Basic {
    /**
     * @dev 0x Address
     */
    address internal constant zeroExAddr =
        0xDEF189DeAEF76E379df891899eb5A00a94cBC250;

    function _swapHelper(ZeroExData memory zeroExData, uint256 ftmAmt)
        internal
        returns (uint256 buyAmt)
    {
        TokenInterface buyToken = zeroExData.buyToken;
        (uint256 _buyDec, uint256 _sellDec) = getTokensDec(
            buyToken,
            zeroExData.sellToken
        );
        uint256 _sellAmt18 = convertTo18(_sellDec, zeroExData._sellAmt);
        uint256 _slippageAmt = convert18ToDec(
            _buyDec,
            wmul(zeroExData.unitAmt, _sellAmt18)
        );

        uint256 initalBal = getTokenBal(buyToken);

        // solium-disable-next-line security/no-call-value
        (bool success, ) = zeroExAddr.call{value: ftmAmt}(zeroExData.callData);
        if (!success) revert("0x-swap-failed");

        uint256 finalBal = getTokenBal(buyToken);

        buyAmt = sub(finalBal, initalBal);

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }

    function _swap(ZeroExData memory zeroExData, uint256 setId)
        internal
        returns (ZeroExData memory)
    {
        TokenInterface _sellAddr = zeroExData.sellToken;

        uint256 ftmAmt;
        if (address(_sellAddr) == ftmAddr) {
            ftmAmt = zeroExData._sellAmt;
        } else {
            approve(
                TokenInterface(_sellAddr),
                zeroExAddr,
                zeroExData._sellAmt
            );
        }

        zeroExData._buyAmt = _swapHelper(zeroExData, ftmAmt);
        setUint(setId, zeroExData._buyAmt);

        return zeroExData;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
    event LogSwap(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );
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