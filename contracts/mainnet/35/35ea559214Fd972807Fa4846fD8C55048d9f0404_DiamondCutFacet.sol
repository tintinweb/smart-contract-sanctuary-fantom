// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { Decimal } from "./libraries/LibDecimal.sol";

library C {
    using Decimal for Decimal.D256;

    // Collateral
    address private constant COLLATERAL = 0x63618c1aB39a848a789b88599f88186A11F785A2; // TODO

    // System
    uint256 private constant PERCENT_BASE = 1e18;
    uint256 private constant PRECISION = 1e18;

    // Oracle
    address private constant MUON = 0xE4F8d9A30936a6F8b17a73dC6fEb51a3BBABD51A;
    uint16 private constant MUON_APP_ID = 0; // TODO
    uint8 private constant MIN_REQUIRED_SIGNATURES = 0; // TODO

    // Configuration
    uint256 private constant MARGIN_OVERHEAD = 0.5e18; // 50%
    uint256 private constant LIQUIDATION_FEE = 0.1e18; // 10%

    uint16 private constant MAX_LEVERAGE = 1000;

    uint256 private constant SOLVENCY_THRESHOLD_TRADE_USER = 0.3e18; // 30%
    uint256 private constant SOLVENCY_THRESHOLD_TRADE_HEDGER = 0; // 0%

    uint256 private constant SOLVENCY_THRESHOLD_REMOVE_USER = 1e18; // 30%
    uint256 private constant SOLVENCY_THRESHOLD_REMOVE_HEDGER = 0.5e18; // 0%

    uint256 private constant REQUEST_TIMEOUT = 1 minutes;

    function getCollateral() internal pure returns (address) {
        return COLLATERAL;
    }

    function getPrecision() internal pure returns (uint256) {
        return PRECISION;
    }

    function getMuon() internal pure returns (address) {
        return MUON;
    }

    function getMuonAppId() internal pure returns (uint16) {
        return MUON_APP_ID;
    }

    function getMinimumRequiredSignatures() internal pure returns (uint8) {
        return MIN_REQUIRED_SIGNATURES;
    }

    function getMaxLeverage() internal pure returns (uint16) {
        return MAX_LEVERAGE;
    }

    function getMarginOverhead() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(MARGIN_OVERHEAD, PERCENT_BASE);
    }

    function getLiquidationFee() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(LIQUIDATION_FEE, PERCENT_BASE);
    }

    function getSolvencyThresholdToTrade(bool isHedger) internal pure returns (Decimal.D256 memory) {
        return
            isHedger
                ? Decimal.ratio(SOLVENCY_THRESHOLD_TRADE_HEDGER, PERCENT_BASE)
                : Decimal.ratio(SOLVENCY_THRESHOLD_TRADE_USER, PERCENT_BASE);
    }

    function getSolvencyThresholdToRemoveLockedMargin(bool isHedger) internal pure returns (Decimal.D256 memory) {
        return
            isHedger
                ? Decimal.ratio(SOLVENCY_THRESHOLD_REMOVE_HEDGER, PERCENT_BASE)
                : Decimal.ratio(SOLVENCY_THRESHOLD_REMOVE_USER, PERCENT_BASE);
    }

    function getRequestTimeout() internal pure returns (uint256) {
        return REQUEST_TIMEOUT;
    }

    function getChainId() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant BASE = 10**18;

    // ============ Structs ============

    struct D256 {
        uint256 value;
    }

    // ============ Static Functions ============

    function zero() internal pure returns (D256 memory) {
        return D256({ value: 0 });
    }

    function one() internal pure returns (D256 memory) {
        return D256({ value: BASE });
    }

    function from(uint256 a) internal pure returns (D256 memory) {
        return D256({ value: a.mul(BASE) });
    }

    function ratio(uint256 a, uint256 b) internal pure returns (D256 memory) {
        return D256({ value: getPartial(a, BASE, b) });
    }

    // ============ Self Functions ============

    function add(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({ value: self.value.add(b.mul(BASE)) });
    }

    function sub(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({ value: self.value.sub(b.mul(BASE)) });
    }

    function sub(
        D256 memory self,
        uint256 b,
        string memory reason
    ) internal pure returns (D256 memory) {
        return D256({ value: self.value.sub(b.mul(BASE), reason) });
    }

    function mul(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({ value: self.value.mul(b) });
    }

    function div(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({ value: self.value.div(b) });
    }

    function pow(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        if (b == 0) {
            return one();
        }

        D256 memory temp = D256({ value: self.value });
        for (uint256 i = 1; i < b; ++i) {
            temp = mul(temp, self);
        }

        return temp;
    }

    function add(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({ value: self.value.add(b.value) });
    }

    function sub(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({ value: self.value.sub(b.value) });
    }

    function sub(
        D256 memory self,
        D256 memory b,
        string memory reason
    ) internal pure returns (D256 memory) {
        return D256({ value: self.value.sub(b.value, reason) });
    }

    function mul(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({ value: getPartial(self.value, b.value, BASE) });
    }

    function div(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({ value: getPartial(self.value, BASE, b.value) });
    }

    function equals(D256 memory self, D256 memory b) internal pure returns (bool) {
        return self.value == b.value;
    }

    function greaterThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 2;
    }

    function lessThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 0;
    }

    function greaterThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) > 0;
    }

    function lessThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) < 2;
    }

    function isZero(D256 memory self) internal pure returns (bool) {
        return self.value == 0;
    }

    function asUint256(D256 memory self) internal pure returns (uint256) {
        return self.value.div(BASE);
    }

    // ============ Core Methods ============

    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    ) private pure returns (uint256) {
        return target.mul(numerator).div(denominator);
    }

    function compareTo(D256 memory a, D256 memory b) private pure returns (uint256) {
        if (a.value == b.value) {
            return 1;
        }
        return a.value > b.value ? 2 : 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { AppStorage, RequestForQuote, Position, Fill } from "../../../libraries/LibAppStorage.sol";
import { LibMarkets } from "../../../libraries/LibMarkets.sol";
import { LibHedgers } from "../../../libraries/LibHedgers.sol";
import { LibMaster } from "../../../libraries/LibMaster.sol";
import { SchnorrSign } from "../../../interfaces/IMuonV02.sol";
import { MarketPrice } from "../../../interfaces/IOracle.sol";
import { C } from "../../../C.sol";
import "../../../libraries/LibEnums.sol";

contract OpenMarketSingleFacet {
    AppStorage internal s;

    function requestOpenMarketSingle(
        address partyB,
        uint256 marketId,
        Side side,
        uint256 usdAmount,
        uint16 leverage,
        uint8 marginRequiredPercentage,
        MarketPrice[] calldata marketPrices,
        bytes calldata reqId,
        SchnorrSign[] calldata sigs
    ) external returns (RequestForQuote memory rfq) {
        require(msg.sender != partyB, "Parties can not be the same");
        require(LibMarkets.isValidMarketId(marketId), "Invalid market");
        require(LibMaster.isValidLeverage(leverage), "Invalid leverage");
        (bool validHedger, ) = LibHedgers.isValidHedger(partyB);
        require(validHedger, "Invalid hedger");

        rfq = LibMaster.onRequestForQuote(
            msg.sender,
            partyB,
            marketId,
            OrderType.MARKET,
            HedgerMode.SINGLE,
            side,
            usdAmount,
            leverage,
            marginRequiredPercentage,
            marketPrices,
            reqId,
            sigs
        );

        // TODO: emit event
    }

    function cancelOpenMarketSingle(uint256 rfqId) external {
        RequestForQuote storage rfq = s.ma._requestForQuoteMap[msg.sender][rfqId];

        require(rfq.partyA == msg.sender, "Invalid party");
        require(rfq.hedgerMode == HedgerMode.SINGLE, "Invalid hedger mode");
        require(rfq.orderType == OrderType.MARKET, "Invalid order type");
        require(rfq.state == RequestForQuoteState.ORPHAN, "Invalid RFQ state");

        rfq.state = RequestForQuoteState.CANCELATION_REQUESTED;
        rfq.mutableTimestamp = block.timestamp;

        // TODO: emit the event
    }

    function forceCancelOpenMarketSingle(uint256 rfqId) public {
        RequestForQuote storage rfq = s.ma._requestForQuoteMap[msg.sender][rfqId];

        require(rfq.partyA == msg.sender, "Invalid party");
        require(rfq.hedgerMode == HedgerMode.SINGLE, "Invalid hedger mode");
        require(rfq.orderType == OrderType.MARKET, "Invalid order type");
        require(rfq.state == RequestForQuoteState.CANCELATION_REQUESTED, "Invalid RFQ state");
        require(rfq.mutableTimestamp + C.getRequestTimeout() < block.timestamp, "Request Timeout");

        // Update the RFQ state.
        rfq.state = RequestForQuoteState.CANCELED;
        rfq.mutableTimestamp = block.timestamp;

        // Return the collateral to partyA.
        s.ma._lockedMarginReserved[msg.sender] -= rfq.lockedMarginA;
        s.ma._marginBalances[msg.sender] += rfq.lockedMarginA;

        // TODO: emit event
    }

    function acceptCancelOpenMarketSingle(address partyA, uint256 rfqId) external {
        RequestForQuote storage rfq = s.ma._requestForQuoteMap[msg.sender][rfqId];

        require(rfq.partyB == msg.sender, "Invalid party");
        require(rfq.hedgerMode == HedgerMode.SINGLE, "Invalid hedger mode");
        require(rfq.orderType == OrderType.MARKET, "Invalid order type");
        require(rfq.state == RequestForQuoteState.CANCELATION_REQUESTED, "Invalid RFQ state");

        // Update the RFQ state.
        rfq.state = RequestForQuoteState.CANCELED;
        rfq.mutableTimestamp = block.timestamp;

        // Return the collateral to partyA.
        s.ma._lockedMarginReserved[partyA] -= rfq.lockedMarginA;
        s.ma._marginBalances[partyA] += rfq.lockedMarginA;
    }

    function rejectOpenMarketSingle(address partyA, uint256 rfqId) external {
        RequestForQuote storage rfq = s.ma._requestForQuoteMap[partyA][rfqId];

        require(rfq.partyB == msg.sender, "Invalid party");
        require(rfq.hedgerMode == HedgerMode.SINGLE, "Invalid hedger mode");
        require(rfq.orderType == OrderType.MARKET, "Invalid order type");
        require(
            rfq.state == RequestForQuoteState.ORPHAN || rfq.state == RequestForQuoteState.CANCELATION_REQUESTED,
            "Invalid RFQ state"
        );

        // Update the RFQ
        rfq.state = RequestForQuoteState.REJECTED;
        rfq.mutableTimestamp = block.timestamp;

        // Return the collateral to partyA
        s.ma._lockedMarginReserved[partyA] -= rfq.lockedMarginA;
        s.ma._marginBalances[partyA] += rfq.lockedMarginA;

        // TODO: emit event
    }

    function fillOpenMarketSingle(
        address partyA,
        uint256 rfqId,
        uint256 filledAmountUnits,
        uint256 initialNotionalUsd,
        uint256 avgPriceUsd
    ) external {
        RequestForQuote storage rfq = s.ma._requestForQuoteMap[partyA][rfqId];

        require(rfq.partyB == msg.sender, "Invalid party");
        require(rfq.hedgerMode == HedgerMode.SINGLE, "Invalid hedger mode");
        require(rfq.orderType == OrderType.MARKET, "Invalid order type");
        require(
            rfq.state == RequestForQuoteState.ORPHAN || rfq.state == RequestForQuoteState.CANCELATION_REQUESTED,
            "Invalid RFQ state"
        );

        // Update the RFQ
        rfq.state = RequestForQuoteState.ACCEPTED;
        rfq.mutableTimestamp = block.timestamp;

        // Create the Position
        uint256 currentPositionId = s.ma._allPositionsLength;
        Position memory position = Position(
            currentPositionId,
            PositionState.OPEN,
            rfq.marketId,
            partyA,
            msg.sender,
            rfq.lockedMarginA,
            rfq.lockedMarginB,
            rfq.leverageUsed,
            rfq.side,
            filledAmountUnits,
            initialNotionalUsd,
            block.timestamp,
            block.timestamp
        );

        // Create the first Fill
        s.ma._positionFills[currentPositionId].push(Fill(rfq.side, filledAmountUnits, avgPriceUsd, block.timestamp));

        // Update global mappings
        s.ma._allPositionsMap[currentPositionId] = position;
        s.ma._allPositionsLength++;

        // Update party mappings
        s.ma._openPositionsList[partyA].push(currentPositionId);
        s.ma._openPositionsList[msg.sender].push(currentPositionId);

        // Transfer partyA's collateral
        s.ma._lockedMarginReserved[partyA] -= rfq.lockedMarginA;
        s.ma._lockedMargin[partyA] += rfq.lockedMarginA;

        // Transfer partyB's collateral
        s.ma._marginBalances[msg.sender] -= rfq.lockedMarginB;
        s.ma._lockedMargin[msg.sender] += rfq.lockedMarginB;

        // TODO: emit event
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;
import "./LibEnums.sol";

struct Hedger {
    address addr;
    string[] pricingWssURLs;
    string[] marketsHttpsURLs;
    bool slippageControl;
}

struct Market {
    uint256 _marketId;
    string identifier;
    MarketType marketType;
    TradingSession tradingSession;
    bool active;
    string baseCurrency;
    string quoteCurrency;
    string symbol;
}

struct RequestForQuote {
    uint256 rfqId;
    RequestForQuoteState state;
    OrderType orderType;
    address partyA;
    address partyB;
    HedgerMode hedgerMode;
    uint256 marketId;
    Side side;
    uint256 notionalUsd;
    uint16 leverageUsed;
    uint256 marginRequiredPercentage;
    uint256 lockedMarginA;
    uint256 lockedMarginB;
    uint256 creationTimestamp;
    uint256 mutableTimestamp;
}

struct Fill {
    Side side;
    uint256 filledAmountUnits;
    uint256 avgPriceUsd;
    uint256 timestamp;
}

struct Position {
    uint256 positionId;
    PositionState state;
    uint256 marketId;
    address partyA;
    address partyB;
    uint256 lockedMarginA;
    uint256 lockedMarginB;
    uint16 leverageUsed;
    Side side;
    uint256 currentBalanceUnits;
    uint256 initialNotionalUsd;
    uint256 creationTimestamp;
    uint256 mutableTimestamp;
}

struct HedgersState {
    mapping(address => Hedger) _hedgerMap;
    Hedger[] _hedgerList;
}

struct MarketsState {
    mapping(uint256 => Market) _marketMap;
    Market[] _marketList;
}

struct MAState {
    mapping(address => mapping(uint256 => RequestForQuote)) _requestForQuoteMap;
    mapping(address => uint256) _requestForQuotesLength;
    mapping(address => uint256) _accountBalances;
    mapping(address => uint256) _marginBalances;
    mapping(address => uint256) _lockedMargin;
    mapping(address => uint256) _lockedMarginReserved;
    mapping(uint256 => Position) _allPositionsMap;
    uint256 _allPositionsLength;
    mapping(address => uint256[]) _openPositionsList;
    mapping(uint256 => Fill[]) _positionFills;
}

struct AppStorage {
    bool paused;
    uint128 pausedAt;
    uint256 reentrantStatus;
    address ownerCandidate;
    HedgersState hedgers;
    MarketsState markets;
    MAState ma;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { AppStorage, LibAppStorage } from "../libraries/LibAppStorage.sol";

library LibMarkets {
    function isValidMarketId(uint256 marketId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 length = s.markets._marketList.length;
        return marketId < length;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { LibDiamond } from "./LibDiamond.sol";
import { AppStorage, LibAppStorage, Hedger } from "../libraries/LibAppStorage.sol";

library LibHedgers {
    function isValidHedger(address partyB) internal view returns (bool, Hedger memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Hedger memory hedger = s.hedgers._hedgerMap[partyB];
        return hedger.addr == address(0) ? (false, hedger) : (true, hedger);
    }

    function getHedgerByAddressOrThrow(address partyB) internal view returns (Hedger memory) {
        (bool isValid, Hedger memory hedger) = isValidHedger(partyB);
        require(isValid, "Hedger is not valid");
        return hedger;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { AppStorage, LibAppStorage, RequestForQuote, Position, Fill } from "../libraries/LibAppStorage.sol";
import { Decimal } from "../libraries/LibDecimal.sol";
import { SchnorrSign } from "../interfaces/IMuonV02.sol";
import { LibOracle } from "../libraries/LibOracle.sol";
import { MarketPrice } from "../interfaces/IOracle.sol";
import { C } from "../C.sol";
import "../libraries/LibEnums.sol";

library LibMaster {
    using Decimal for Decimal.D256;

    // --------------------------------//
    //---- INTERNAL WRITE FUNCTIONS ---//
    // --------------------------------//

    function onRequestForQuote(
        address partyA,
        address partyB,
        uint256 marketId,
        OrderType orderType,
        HedgerMode hedgerMode,
        Side side,
        uint256 usdAmount,
        uint16 leverage,
        uint8 marginRequiredPercentage,
        MarketPrice[] calldata marketPrices,
        bytes calldata reqId,
        SchnorrSign[] calldata sigs
    ) internal returns (RequestForQuote memory rfq) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 lockedMarginA = calculateLockedMargin(usdAmount * leverage, marginRequiredPercentage, false);
        uint256 lockedMarginB = calculateLockedMargin(usdAmount * leverage, marginRequiredPercentage, true);
        require(lockedMarginA <= s.ma._marginBalances[partyA], "Insufficient margin balance");

        // Validate raw oracle signatures. Can be bypassed if a user has no open positions.
        if (s.ma._openPositionsList[partyA].length > 0) {
            bool valid = LibOracle.isValidMarketPrices(marketPrices, reqId, sigs);
            require(valid, "Invalid oracle inputs");
        }
        /**
         * Note: We don't have to guesstimate the solvency post-trade,
         * because the isolated marginHealth will be 100% at T=0. Thus,
         * it will have no effect on the cross margin health.
         */
        (int256 uPnLCrossA, ) = LibMaster.calculateUPnLCross(marketPrices, partyA);
        require(
            LibMaster.solvencySafeguardToTrade(s.ma._lockedMargin[partyA], uPnLCrossA, false),
            "PartyA fails solvency safeguard"
        );

        uint256 currentRfqId = s.ma._requestForQuotesLength[partyA];

        rfq = RequestForQuote(
            currentRfqId,
            RequestForQuoteState.ORPHAN,
            orderType,
            partyA,
            partyB,
            hedgerMode,
            marketId,
            side,
            usdAmount * leverage,
            leverage,
            marginRequiredPercentage,
            lockedMarginA,
            lockedMarginB,
            block.timestamp,
            block.timestamp
        );

        s.ma._requestForQuoteMap[partyA][currentRfqId] = rfq;
        s.ma._requestForQuotesLength[partyA]++;

        /// @notice We will only lock partyB's margin once he accepts the RFQ.
        s.ma._marginBalances[partyA] -= lockedMarginA;
        s.ma._lockedMarginReserved[partyA] += lockedMarginA;
    }

    function createFill(
        Side side,
        uint256 amountUnits,
        uint256 avgPriceUsd
    ) internal view returns (Fill memory fill) {
        fill = Fill(side == Side.BUY ? Side.SELL : Side.BUY, amountUnits, avgPriceUsd, block.timestamp);
    }

    function distributePnL(
        address partyA,
        address partyB,
        int256 pnlA
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        /**
         * Winning party receives the PNL.
         * Losing party pays for the PNL using his lockedMargin.
         *
         * Note: the winning party will NOT receive his lockedMargin back,
         * he'll have to withdraw it manually. This has to do with the
         * risk of liquidation + the fact that his initially lockedMargin
         * could be greater than what he currently has locked.
         */
        if (pnlA >= 0) {
            s.ma._marginBalances[partyA] += uint256(pnlA);
            s.ma._lockedMargin[partyB] -= uint256(pnlA);
        } else {
            s.ma._marginBalances[partyB] += uint256(pnlA);
            s.ma._lockedMargin[partyA] -= uint256(pnlA);
        }
    }

    function removeOpenPosition(address party, uint256 positionId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        int256 index = -1;
        for (uint256 i = 0; i < s.ma._openPositionsList[party].length; i++) {
            if (s.ma._openPositionsList[party][i] == positionId) {
                index = int256(i);
                break;
            }
        }
        require(index != -1, "Position not found");

        s.ma._openPositionsList[party][uint256(index)] = s.ma._openPositionsList[party][
            s.ma._openPositionsList[party].length - 1
        ];
        s.ma._openPositionsList[party].pop();
    }

    // --------------------------------//
    //---- INTERNAL VIEW FUNCTIONS ----//
    // --------------------------------//

    function getOpenPositions(address party) internal view returns (Position[] memory positions) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256[] memory positionIds = s.ma._openPositionsList[party];

        positions = new Position[](positionIds.length);
        for (uint256 i = 0; i < positionIds.length; i++) {
            positions[i] = s.ma._allPositionsMap[positionIds[i]];
        }
    }

    // TODO: upgrade to new 'realLeverage' system
    function calculateLockedMargin(
        uint256 notionalUsd,
        uint8 marginRequiredPercentage,
        bool isHedger // TODO: give this meaning
    ) internal pure returns (uint256) {
        Decimal.D256 memory multiplier = Decimal.one().add(C.getMarginOverhead()).add(C.getLiquidationFee());
        return Decimal.from(notionalUsd).mul(Decimal.ratio(marginRequiredPercentage, 100)).mul(multiplier).asUint256();
    }

    function calculateUPnLCross(MarketPrice[] memory marketPrices, address party)
        internal
        view
        returns (int256 uPnLCross, int256 notionalCross)
    {
        (uPnLCross, notionalCross) = _calculateUPnLCross(marketPrices, getOpenPositions(party));
    }

    /**
        Initial Units: 2
        Initial Price: 5
        Initial Notional: 2 * 5 = 10
        Current Price: 6

        Long: 
            Current Notional: 2 * 6 = 12
            PNL = CurrentNotional - InitialNotional 
                = 12 - 10 = +2 PROFIT
        Short:
            TEMP Current notional: 2 * 6 = 12
            PNL = InitialNotional - CurrentNotional
                = 10 - 12 = -2 LOSS
            Current Notional: VirtualNotional + (PNL * 2)
                = 12 + (-2 * 2) = 8
    */
    function calculateUPnLIsolated(
        Side side,
        uint256 currentBalanceUnits,
        uint256 initialNotionalUsd,
        uint256 bidPrice,
        uint256 askPrice
    ) internal pure returns (int256 uPnL, int256 notionalIsolated) {
        if (currentBalanceUnits == 0) return (0, 0);

        uint256 precision = C.getPrecision();

        if (side == Side.BUY) {
            require(bidPrice != 0, "Oracle bidPrice is invalid");
            notionalIsolated = int256((currentBalanceUnits * bidPrice) / precision);
            uPnL = notionalIsolated - int256(initialNotionalUsd);
        } else {
            require(askPrice != 0, "Oracle askPrice is invalid");
            int256 tempNotionalIsolated = int256((currentBalanceUnits * askPrice) / precision);
            uPnL = int256(initialNotionalUsd) - tempNotionalIsolated;
            notionalIsolated = tempNotionalIsolated + (uPnL * 2);
        }
    }

    function calculateCrossMarginHealth(uint256 _lockedMargin, int256 uPnLCross)
        internal
        pure
        returns (Decimal.D256 memory ratio)
    {
        int256 lockedMargin = int256(_lockedMargin);

        if (lockedMargin == 0) {
            return Decimal.ratio(1, 1);
        } else if (lockedMargin + uPnLCross <= 0) {
            return Decimal.zero();
        }

        ratio = Decimal.ratio(uint256(lockedMargin + uPnLCross), uint256(lockedMargin));
    }

    /**
     * A party (user and/or hedger) isn't allowed to open a trade if he's near insolvency.
     * This restriction is put in place to protect the hedger against concurrency
     * problematics. Instead, the party is encouraged to top-up his locked margin via addFreeMargin.
     */
    function solvencySafeguardToTrade(
        uint256 lockedMargin,
        int256 uPnLCross,
        bool isHedger
    ) internal pure returns (bool) {
        Decimal.D256 memory ratio = calculateCrossMarginHealth(lockedMargin, uPnLCross);
        Decimal.D256 memory threshold = C.getSolvencyThresholdToTrade(isHedger);
        return ratio.greaterThanOrEqualTo(threshold);
    }

    function solvencySafeguardToRemoveLockedMargin(
        uint256 lockedMargin,
        int256 uPnLCross,
        bool isHedger
    ) internal pure returns (bool) {
        Decimal.D256 memory ratio = calculateCrossMarginHealth(lockedMargin, uPnLCross);
        Decimal.D256 memory threshold = C.getSolvencyThresholdToRemoveLockedMargin(isHedger);
        return ratio.greaterThanOrEqualTo(threshold);
    }

    function isValidLeverage(uint16 leverage) internal pure returns (bool) {
        return leverage > 0 && leverage <= C.getMaxLeverage();
    }

    // --------------------------------//
    //----- PRIVATE VIEW FUNCTIONS ----//
    // --------------------------------//

    /**
     * Returns the UPnL of a party across all his open positions.
     *
     * @notice This function consumes a lot of gas, so make sure to limit `marketPrices`
     * strictly to the markets that the party has open positions with.
     *
     * @dev We assume the signature of `marketPrices` is already validated by parent caller.
     */
    function _calculateUPnLCross(MarketPrice[] memory marketPrices, Position[] memory positions)
        private
        pure
        returns (int256 uPnLCross, int256 notionalCross)
    {
        require(marketPrices.length <= positions.length, "Redundant marketPrices");
        if (positions.length == 0) {
            return (0, 0);
        }

        uint256 count;
        for (uint256 i = 0; i < marketPrices.length; i++) {
            uint256 marketId = marketPrices[i].marketId;
            uint256 bidPrice = marketPrices[i].bidPrice;
            uint256 askPrice = marketPrices[i].askPrice;

            for (uint256 j = 0; j < positions.length; j++) {
                if (positions[j].marketId == marketId) {
                    (int256 _uPnLIsolated, int256 _notionalIsolated) = calculateUPnLIsolated(
                        positions[j].side,
                        positions[j].currentBalanceUnits,
                        positions[j].initialNotionalUsd,
                        bidPrice,
                        askPrice
                    );
                    uPnLCross += _uPnLIsolated;
                    notionalCross += _notionalIsolated;
                    count++;
                }
            }
        }

        require(count == positions.length, "Incomplete price feeds");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

struct SchnorrSign {
    uint256 signature;
    address owner;
    address nonce;
}

interface IMuonV02 {
    function verify(
        bytes calldata reqId,
        uint256 hash,
        SchnorrSign[] calldata _sigs
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

struct MarketPrice {
    uint256 marketId;
    uint256 bidPrice;
    uint256 askPrice;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

enum MarketType {
    FOREX,
    CRYPTO,
    STOCK
}

enum TradingSession {
    _24_7,
    _24_5
}

enum Side {
    BUY,
    SELL
}

enum HedgerMode {
    SINGLE,
    HYBRID,
    AUTO
}

enum OrderType {
    LIMIT,
    MARKET
}

enum RequestForQuoteState {
    ORPHAN,
    CANCELATION_REQUESTED,
    CANCELED,
    REJECTED,
    ACCEPTED
}

enum PositionState {
    OPEN,
    MARKET_CLOSE_REQUESTED,
    MARKET_CLOSE_CANCELATION_REQUESTED,
    LIMIT_CLOSE_REQUESTED,
    LIMIT_CLOSE_CANCELATION_REQUESTED,
    LIMIT_CLOSE_ACTIVE,
    CLOSED,
    LIQUIDATED
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IERC165 } from "../interfaces/IERC165.sol";

library LibDiamond {
    bytes32 public constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsOwnerOrContract() internal view {
        require(
            msg.sender == diamondStorage().contractOwner || msg.sender == address(this),
            "LibDiamond: Must be contract or owner"
        );
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Add facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(
                _facetAddress,
                selectorCount
            );
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Replace facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Replace facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond
            require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
            // replace old facet address
            ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds
                .facetAddressAndSelectorPosition[selector];
            require(
                oldFacetAddressAndSelectorPosition.facetAddress != address(0),
                "LibDiamondCut: Can't remove function that doesn't exist"
            );
            // can't remove immutable functions -- functions defined directly in the diamond
            require(
                oldFacetAddressAndSelectorPosition.facetAddress != address(this),
                "LibDiamondCut: Can't remove immutable function."
            );
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition
                    .selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    // Add=0, Replace=1, Remove=2
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MarketPrice } from "../interfaces/IOracle.sol";
import { SchnorrSign, IMuonV02 } from "../interfaces/IMuonV02.sol";
import { C } from "../C.sol";

library LibOracle {
    using ECDSA for bytes32;

    function isValidMarketPrices(
        MarketPrice[] calldata marketPrices,
        bytes calldata reqId,
        SchnorrSign[] calldata sigs
    ) internal returns (bool) {
        require(sigs.length >= C.getMinimumRequiredSignatures(), "Insufficient signatures");

        bytes32 hash = keccak256(abi.encode(marketPrices, C.getChainId(), C.getMuonAppId()));
        IMuonV02 _muon = IMuonV02(C.getMuon());

        // bool valid = _muon.verify(reqId, uint256(hash), sigs);
        // TODO: return `valid` once we've integrated Muon.
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { AppStorage, RequestForQuote, Position } from "../../libraries/LibAppStorage.sol";
import { Decimal } from "../../libraries/LibDecimal.sol";
import { LibMaster } from "../../libraries/LibMaster.sol";
import { MarketPrice } from "../../interfaces/IOracle.sol";
import "../../libraries/LibEnums.sol";

contract MasterFacet {
    AppStorage internal s;

    function getRequestForQuotes(address party) external view returns (RequestForQuote[] memory rfqs) {
        uint256 len = s.ma._requestForQuotesLength[party];
        rfqs = new RequestForQuote[](len);

        for (uint256 i = 0; i < len; i++) {
            rfqs[i] = (s.ma._requestForQuoteMap[party][i]);
        }
    }

    function getRequestForQuote(address party, uint256 rfqId) external view returns (RequestForQuote memory) {
        return s.ma._requestForQuoteMap[party][rfqId];
    }

    function getOpenPositions(address partyA) external view returns (Position[] memory) {
        return LibMaster.getOpenPositions(partyA);
    }

    function calculateLockedMargin(
        uint256 notionalUsd,
        uint8 marginRequiredPercentage,
        bool isHedger
    ) external pure returns (uint256) {
        return LibMaster.calculateLockedMargin(notionalUsd, marginRequiredPercentage, isHedger);
    }

    function calculateUPnLCross(MarketPrice[] memory marketPrices, address party)
        external
        view
        returns (int256 uPnLCross, int256 notionalCross)
    {
        return LibMaster.calculateUPnLCross(marketPrices, party);
    }

    function calculateUPnLIsolated(
        Side side,
        uint256 currentBalanceUnits,
        uint256 initialNotionalUsd,
        uint256 bidPrice,
        uint256 askPrice
    ) external pure returns (int256 uPnL, int256 notionalIsolated) {
        return LibMaster.calculateUPnLIsolated(side, currentBalanceUnits, initialNotionalUsd, bidPrice, askPrice);
    }

    function calculateCrossMarginHealth(uint256 lockedMargin, int256 uPnLCross)
        external
        pure
        returns (Decimal.D256 memory ratio)
    {
        return LibMaster.calculateCrossMarginHealth(lockedMargin, uPnLCross);
    }

    function solvencySafeguardToTrade(
        uint256 lockedMargin,
        int256 uPnLCross,
        bool isHedger
    ) external pure returns (bool) {
        return LibMaster.solvencySafeguardToTrade(lockedMargin, uPnLCross, isHedger);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { AppStorage, LibAppStorage, Position, Fill } from "../../../libraries/LibAppStorage.sol";
import { LibMaster } from "../../../libraries/LibMaster.sol";
import { C } from "../../../C.sol";
import "../../../libraries/LibEnums.sol";

/**
 * Close a Position through a Market order.
 * @dev Can only be done via the original partyB (hedgerMode=Single).
 */
contract CloseMarketSingleFacet {
    AppStorage internal s;

    function requestCloseMarket(uint256 positionId) external {
        Position storage position = s.ma._allPositionsMap[positionId];

        require(position.partyA == msg.sender, "Invalid party");
        require(position.state == PositionState.OPEN, "Invalid position state");

        position.state = PositionState.MARKET_CLOSE_REQUESTED;
        position.mutableTimestamp = block.timestamp;

        // TODO: emit event
    }

    function cancelCloseMarket(uint256 positionId) external {
        Position storage position = s.ma._allPositionsMap[positionId];

        require(position.partyA == msg.sender, "Invalid party");
        require(position.state == PositionState.MARKET_CLOSE_REQUESTED, "Invalid position state");

        position.state = PositionState.MARKET_CLOSE_CANCELATION_REQUESTED;
        position.mutableTimestamp = block.timestamp;

        // TODO: emit event
    }

    function forceCancelCloseMarket(uint256 positionId) public {
        Position storage position = s.ma._allPositionsMap[positionId];

        require(position.partyA == msg.sender, "Invalid party");
        require(position.state == PositionState.MARKET_CLOSE_CANCELATION_REQUESTED, "Invalid position state");
        require(position.mutableTimestamp + C.getRequestTimeout() < block.timestamp, "Request Timeout");

        position.state = PositionState.OPEN;
        position.mutableTimestamp = block.timestamp;

        // TODO: emit event
    }

    function acceptCancelCloseMarket(uint256 positionId) external {
        Position storage position = s.ma._allPositionsMap[positionId];

        require(position.partyB == msg.sender, "Invalid party");
        require(position.state == PositionState.MARKET_CLOSE_CANCELATION_REQUESTED, "Invalid position state");

        position.state = PositionState.OPEN;
        position.mutableTimestamp = block.timestamp;

        // TODO: emit event
    }

    function rejectCloseMarket(uint256 positionId) external {
        Position storage position = s.ma._allPositionsMap[positionId];

        require(position.partyB == msg.sender, "Invalid party");
        require(position.state == PositionState.MARKET_CLOSE_REQUESTED, "Invalid position state");

        position.state = PositionState.OPEN;
        position.mutableTimestamp = block.timestamp;

        // TODO: emit event
    }

    function fillCloseMarket(uint256 positionId, uint256 avgPriceUsd) external {
        Position storage position = s.ma._allPositionsMap[positionId];

        require(position.partyB == msg.sender, "Invalid party");
        require(position.state == PositionState.MARKET_CLOSE_REQUESTED, "Invalid position state");

        // Add the Fill
        Fill memory fill = LibMaster.createFill(position.side, position.currentBalanceUnits, avgPriceUsd);
        s.ma._positionFills[positionId].push(fill);

        // Calculate the PnL of PartyA
        (int256 pnlA, ) = LibMaster.calculateUPnLIsolated(
            position.side,
            position.currentBalanceUnits,
            position.initialNotionalUsd,
            avgPriceUsd,
            avgPriceUsd
        );

        // Distribute the PnL accordingly
        LibMaster.distributePnL(position.partyA, position.partyB, pnlA);

        // Update Position
        position.state = PositionState.CLOSED;
        position.currentBalanceUnits = 0;
        position.mutableTimestamp = block.timestamp;

        // Update mappings
        LibMaster.removeOpenPosition(position.partyA, positionId);
        LibMaster.removeOpenPosition(position.partyB, positionId);

        // TODO: emit event
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { Ownable } from "../utils/Ownable.sol";
import { AppStorage } from "../libraries/LibAppStorage.sol";

contract OwnershipFacet is Ownable {
    AppStorage internal s;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function transferOwnership(address _newOwner) external onlyOwner {
        s.ownerCandidate = _newOwner;
    }

    function claimOwnership() external {
        require(s.ownerCandidate == msg.sender, "Ownership: Not candidate");
        LibDiamond.setContractOwner(msg.sender);
        delete s.ownerCandidate;
    }

    function owner() external view returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }

    function ownerCandidate() external view returns (address ownerCandidate_) {
        ownerCandidate_ = s.ownerCandidate;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { LibDiamond } from "../libraries/LibDiamond.sol";

abstract contract Ownable {
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlyOwnerOrContract() {
        LibDiamond.enforceIsOwnerOrContract();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { IERC165 } from "../interfaces/IERC165.sol";

contract DiamondInit {
    function init() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IERC165 } from "../interfaces/IERC165.sol";

contract DiamondLoupeFacet is IDiamondLoupe, IERC165 {
    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external view override returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        // create an array set to the maximum size possible
        facets_ = new Facet[](selectorCount);
        // create an array for counting the number of selectors for each facet
        uint8[] memory numFacetSelectors = new uint8[](selectorCount);
        // total number of facets
        uint256 numFacets;
        // loop through function selectors
        for (uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++) {
            bytes4 selector = ds.selectors[selectorIndex];
            address facetAddress_ = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            bool continueLoop = false;
            // find the functionSelectors array for selector and add selector to it
            for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                if (facets_[facetIndex].facetAddress == facetAddress_) {
                    facets_[facetIndex].functionSelectors[numFacetSelectors[facetIndex]] = selector;
                    // probably will never have more than 256 functions from one facet contract
                    require(numFacetSelectors[facetIndex] < 255);
                    numFacetSelectors[facetIndex]++;
                    continueLoop = true;
                    break;
                }
            }
            // if functionSelectors array exists for selector then continue loop
            if (continueLoop) {
                continueLoop = false;
                continue;
            }
            // create a new functionSelectors array for selector
            facets_[numFacets].facetAddress = facetAddress_;
            facets_[numFacets].functionSelectors = new bytes4[](selectorCount);
            facets_[numFacets].functionSelectors[0] = selector;
            numFacetSelectors[numFacets] = 1;
            numFacets++;
        }
        for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
            uint256 numSelectors = numFacetSelectors[facetIndex];
            bytes4[] memory selectors = facets_[facetIndex].functionSelectors;
            // setting the number of selectors
            assembly {
                mstore(selectors, numSelectors)
            }
        }
        // setting the number of facets
        assembly {
            mstore(facets_, numFacets)
        }
    }

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return _facetFunctionSelectors The selectors associated with a facet address.
    function facetFunctionSelectors(address _facet)
        external
        view
        override
        returns (bytes4[] memory _facetFunctionSelectors)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        uint256 numSelectors;
        _facetFunctionSelectors = new bytes4[](selectorCount);
        // loop through function selectors
        for (uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++) {
            bytes4 selector = ds.selectors[selectorIndex];
            address facetAddress_ = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            if (_facet == facetAddress_) {
                _facetFunctionSelectors[numSelectors] = selector;
                numSelectors++;
            }
        }
        // Set the number of selectors in the array
        assembly {
            mstore(_facetFunctionSelectors, numSelectors)
        }
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view override returns (address[] memory facetAddresses_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        // create an array set to the maximum size possible
        facetAddresses_ = new address[](selectorCount);
        uint256 numFacets;
        // loop through function selectors
        for (uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++) {
            bytes4 selector = ds.selectors[selectorIndex];
            address facetAddress_ = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            bool continueLoop = false;
            // see if we have collected the address already and break out of loop if we have
            for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                if (facetAddress_ == facetAddresses_[facetIndex]) {
                    continueLoop = true;
                    break;
                }
            }
            // continue loop if we already have the address
            if (continueLoop) {
                continueLoop = false;
                continue;
            }
            // include address
            facetAddresses_[numFacets] = facetAddress_;
            numFacets++;
        }
        // Set the number of facet addresses in the array
        assembly {
            mstore(facetAddresses_, numFacets)
        }
    }

    /// @notice Gets the facet address that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view override returns (address facetAddress_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = ds.facetAddressAndSelectorPosition[_functionSelector].facetAddress;
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceId) external view override returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.supportedInterfaces[_interfaceId];
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";

contract DiamondCutFacet is IDiamondCut {
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { LibDiamond } from "./libraries/LibDiamond.sol";
import { IDiamondCut } from "./interfaces/IDiamondCut.sol";
import { AppStorage } from "./libraries/LibAppStorage.sol";

contract Diamond {
    AppStorage internal s;

    receive() external payable {}

    constructor(address _contractOwner, address _diamondCutFacet) payable {
        LibDiamond.setContractOwner(_contractOwner);

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        LibDiamond.diamondCut(cut, address(0), "");
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.facetAddressAndSelectorPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { LibHedgers } from "../libraries/LibHedgers.sol";
import { AppStorage, Hedger } from "../libraries/LibAppStorage.sol";

contract HedgersFacet {
    AppStorage internal s;

    // --------------------------------//
    //----- PUBLIC WRITE FUNCTIONS ----//
    // --------------------------------//

    function enlist(
        string[] calldata pricingWssURLs,
        string[] calldata marketsHttpsURLs,
        bool slippageControl
    ) external returns (Hedger memory hedger) {
        require(msg.sender != address(0), "Invalid address");
        require(s.hedgers._hedgerMap[msg.sender].addr != msg.sender, "Hedger already exists");

        require(pricingWssURLs.length > 0, "pricingWebsocketURLs must be non-empty");
        require(marketsHttpsURLs.length > 0, "pricingWebsocketURLs must be non-empty");
        mustBeHTTPSOrThrow(marketsHttpsURLs);
        mustBeWSSOrThrow(pricingWssURLs);

        hedger = Hedger(msg.sender, pricingWssURLs, marketsHttpsURLs, slippageControl);
        s.hedgers._hedgerMap[msg.sender] = hedger;
        s.hedgers._hedgerList.push(hedger);

        // TODO: emit event
    }

    function updatePricingWssURLs(string[] calldata _pricingWssURLs) external {
        Hedger memory hedger = LibHedgers.getHedgerByAddressOrThrow(msg.sender);

        require(hedger.addr == msg.sender, "Access Denied");
        require(_pricingWssURLs.length > 0, "pricingWssURLs must be non-empty");
        mustBeWSSOrThrow(_pricingWssURLs);

        s.hedgers._hedgerMap[msg.sender].pricingWssURLs = _pricingWssURLs;

        // TODO: emit event
    }

    function updateMarketsHttpsURLs(string[] calldata _marketsHttpsURLs) external {
        Hedger memory hedger = LibHedgers.getHedgerByAddressOrThrow(msg.sender);

        require(hedger.addr == msg.sender, "Access Denied");
        require(_marketsHttpsURLs.length > 0, "marketsHttpsURLs must be non-empty");
        mustBeHTTPSOrThrow(_marketsHttpsURLs);

        s.hedgers._hedgerMap[msg.sender].marketsHttpsURLs = _marketsHttpsURLs;

        // TODO: emit event
    }

    function updateSlippageControl(bool _slippageControl) external {
        Hedger memory hedger = LibHedgers.getHedgerByAddressOrThrow(msg.sender);
        require(hedger.addr == msg.sender, "Access Denied");

        s.hedgers._hedgerMap[msg.sender].slippageControl = _slippageControl;

        // TODO: emit event
    }

    // --------------------------------//
    //----- PUBLIC VIEW FUNCTIONS -----//
    // --------------------------------//

    function getHedgerByAddress(address addr) external view returns (bool success, Hedger memory hedger) {
        hedger = s.hedgers._hedgerMap[addr];
        return hedger.addr == address(0) ? (false, hedger) : (true, hedger);
    }

    function getHedgers() external view returns (Hedger[] memory hedgerList) {
        return s.hedgers._hedgerList;
    }

    function getHedgersLength() external view returns (uint256 length) {
        return s.hedgers._hedgerList.length;
    }

    // --------------------------------//
    //----- PRIVATE VIEW FUNCTIONS ----//
    // --------------------------------//

    function substringASCII(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function mustBeWSSOrThrow(string[] calldata urls) private pure {
        for (uint256 i = 0; i < urls.length; i++) {
            require(compareStrings(substringASCII(urls[i], 0, 6), "wss://"), "websocketURLs must be secure");
        }
    }

    function mustBeHTTPSOrThrow(string[] calldata urls) private pure {
        for (uint256 i = 0; i < urls.length; i++) {
            require(compareStrings(substringASCII(urls[i], 0, 8), "https://"), "httpsURLs must be secure");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "../utils/ReentrancyGuard.sol";
import { C } from "../C.sol";
import { LibHedgers } from "../libraries/LibHedgers.sol";
import { LibOracle } from "../libraries/LibOracle.sol";
import { LibMaster } from "../libraries/LibMaster.sol";
import { SchnorrSign } from "../interfaces/IMuonV02.sol";
import { MarketPrice } from "../interfaces/IOracle.sol";

contract AccountFacet is ReentrancyGuard {
    // --------------------------------//
    //----- PUBLIC WRITE FUNCTIONS ----//
    // --------------------------------//

    function deposit(uint256 amount) external {
        _deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        _withdraw(msg.sender, amount);
    }

    function allocate(uint256 amount) external {
        _allocate(msg.sender, amount);
    }

    function deallocate(uint256 amount) external {
        _deallocate(msg.sender, amount);
    }

    function depositAndAllocate(uint256 amount) external {
        _deposit(msg.sender, amount);
        _allocate(msg.sender, amount);
    }

    function deallocateAndWithdraw(uint256 amount) external {
        _deallocate(msg.sender, amount);
        _withdraw(msg.sender, amount);
    }

    function addFreeMargin(uint256 amount) external {
        _addFreeMargin(msg.sender, amount);
    }

    function dangerouslyRemoveLockedMargin(
        uint256 amount,
        MarketPrice[] calldata marketPrices,
        bytes calldata reqId,
        SchnorrSign[] calldata sigs
    ) external {
        _dangerouslyRemoveLockedMargin(msg.sender, amount, marketPrices, reqId, sigs);
    }

    // --------------------------------//
    //----- PRIVATE WRITE FUNCTIONS ---//
    // --------------------------------//

    function _deposit(address party, uint256 amount) private nonReentrant {
        bool success = IERC20(C.getCollateral()).transferFrom(party, address(this), amount);
        require(success, "Failed to deposit collateral");
        s.ma._accountBalances[party] += amount;
        // TODO: emit event
    }

    function _withdraw(address party, uint256 amount) private nonReentrant {
        require(s.ma._accountBalances[party] >= amount, "Insufficient account balance");
        s.ma._accountBalances[party] -= amount;

        bool success = IERC20(C.getCollateral()).transfer(party, amount);
        require(success, "Failed to withdraw collateral");
        // TODO: emit event
    }

    function _allocate(address party, uint256 amount) private nonReentrant {
        require(s.ma._accountBalances[party] >= amount, "Insufficient account balance");

        s.ma._accountBalances[party] -= amount;
        s.ma._marginBalances[party] += amount;
        // TODO: emit event
    }

    function _deallocate(address party, uint256 amount) private nonReentrant {
        require(s.ma._marginBalances[party] >= amount, "Insufficient margin balance");

        s.ma._marginBalances[party] -= amount;
        s.ma._accountBalances[party] += amount;
        // TODO: emit event
    }

    function _addFreeMargin(address party, uint256 amount) private {
        require(s.ma._marginBalances[party] >= amount, "Insufficient margin balance");

        s.ma._marginBalances[party] -= amount;
        s.ma._lockedMargin[party] += amount;

        // TODO: emit event
    }

    function _dangerouslyRemoveLockedMargin(
        address party,
        uint256 amount,
        MarketPrice[] calldata marketPrices,
        bytes calldata reqId,
        SchnorrSign[] calldata sigs
    ) private {
        require(s.ma._lockedMargin[party] >= amount, "Insufficient lockedMargin balance");

        // Validate raw oracle signatures. Can be bypassed if a user has no open positions.
        if (s.ma._openPositionsList[party].length > 0) {
            bool valid = LibOracle.isValidMarketPrices(marketPrices, reqId, sigs);
            require(valid, "Invalid oracle inputs");
        }

        (int256 uPnLCross, ) = LibMaster.calculateUPnLCross(marketPrices, party);
        (bool isHedger, ) = LibHedgers.isValidHedger(party);
        require(
            LibMaster.solvencySafeguardToRemoveLockedMargin(s.ma._lockedMargin[party] - amount, uPnLCross, isHedger),
            "Party fails solvency safeguard"
        );

        s.ma._lockedMargin[party] -= amount;
        s.ma._marginBalances[party] += amount;
    }

    // --------------------------------//
    //----- PUBLIC VIEW FUNCTIONS -----//
    // --------------------------------//

    function getAccountBalance(address party) external view returns (uint256) {
        return s.ma._accountBalances[party];
    }

    function getMarginBalance(address party) external view returns (uint256) {
        return s.ma._marginBalances[party];
    }

    function getLockedMargin(address party) external view returns (uint256) {
        return s.ma._lockedMargin[party];
    }

    function getLockedMarginReserved(address party) external view returns (uint256) {
        return s.ma._lockedMarginReserved[party];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { AppStorage } from "../libraries/LibAppStorage.sol";

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    AppStorage internal s;

    modifier nonReentrant() {
        require(s.reentrantStatus != _ENTERED, "ReentrancyGuard: reentrant call");
        s.reentrantStatus = _ENTERED;
        _;
        s.reentrantStatus = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICollateral is IERC20 {
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { Ownable } from "../utils/Ownable.sol";
import { LibMarkets } from "../libraries/LibMarkets.sol";
import { AppStorage, Market } from "../libraries/LibAppStorage.sol";
import "../libraries/LibEnums.sol";

contract MarketsFacet is Ownable {
    AppStorage internal s;

    // --------------------------------//
    //----- PUBLIC WRITE FUNCTIONS ----//
    // --------------------------------//

    function createMarket(
        string memory identifier,
        MarketType marketType,
        TradingSession tradingSession,
        bool active,
        string memory baseCurrency,
        string memory quoteCurrency,
        string memory symbol
    ) external onlyOwner returns (Market memory market) {
        uint256 currentMarketId = s.markets._marketList.length;
        market = Market(
            currentMarketId,
            identifier,
            marketType,
            tradingSession,
            active,
            baseCurrency,
            quoteCurrency,
            symbol
        );

        s.markets._marketMap[currentMarketId] = market;
        s.markets._marketList.push(market);

        // TODO: emit event
    }

    function updateMarketStatus(uint256 marketId, bool status) external onlyOwner {
        s.markets._marketMap[marketId].active = status;
        // TODO: emit event
    }

    // --------------------------------//
    //----- PUBLIC VIEW FUNCTIONS -----//
    // --------------------------------//

    function getMarketById(uint256 marketId) external view returns (Market memory market) {
        return s.markets._marketMap[marketId];
    }

    function getMarkets() external view returns (Market[] memory markets) {
        return s.markets._marketList;
    }

    function getMarketsLength() external view returns (uint256 length) {
        return s.markets._marketList.length;
    }
}