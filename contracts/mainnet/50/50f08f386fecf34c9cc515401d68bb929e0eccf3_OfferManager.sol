// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/OfferLibrary.sol";
import "../libraries/RequestLibrary.sol";

interface IOfferManager {
    function createLendingOffer(
        address principalToken,
        uint256 principalAmount,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint16 daysToExpire,
        address[] memory collateralTokens,
        address lender
    ) external returns (uint256);

    function createLendingRequest(
        uint16 percentage,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint16 hoursToExpire,
        address lender,
        uint256 offerId
    ) external returns (uint256);

    function createBorrowingOffer(
        address principalToken,
        address collateralToken,
        uint256 collateralAmount,
        uint256 principalAmount,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint16 hoursToExpire,
        address borrower
    ) external returns (uint256);

    function createBorrowingRequest(
        uint16 percentage,
        address collateralToken,
        uint256 collateralAmount,
        uint256 collateralPriceInUSD,
        uint160 ltvUsed,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint16 hoursToExpire,
        address borrower,
        uint256 offerId
    ) external returns (uint256);

    function reActivateOffer(
        uint256 offerId,
        uint16 toExpire,
        address user
    ) external;

    function rejectRequest(uint256 requestId, address user) external;

    function acceptRequest(uint256 requestId, address user) external;

    function cancelRequest(uint256 requestId, address user) external;

    function removePrincipal(
        uint256 offerId,
        address user,
        uint256 amount
    ) external;

    function removeCollateral(
        uint256 offerId,
        address user,
        uint256 amount
    ) external;

    function isCollateralSupported(uint256 offerId, address token)
        external
        returns (bool);

    function afterBorrowingLoan(
        uint256 offerId,
        uint256 principalAmount,
        uint256 collateralAmount
    ) external;

    function afterLendingLoan(uint256 offerId, uint256 principalAmount)
        external;

    function getOffer(uint256 offerId)
        external
        view
        returns (OfferLibrary.Offer memory);

    function getRequest(uint256 requestId)
        external
        view
        returns (RequestLibrary.Request memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library OfferLibrary {
    enum Type {
        LENDING_OFFER,
        BORROWING_OFFER
    }

    enum State {
        DEFAULT,
        CANCELLED
    }

    event OfferCreated(
        uint256 offerId,
        State state,
        address principalToken,
        uint256 currentPrincipal,
        uint256 initialPrincipal,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint expiresAt,
        uint createdAt,
        address creator,
        address[] collateralTokens,
        address collateralToken,
        uint256 currentCollateral,
        uint256 initialCollateral,
        OfferLibrary.Type offerType
    );

    struct Offer {
        // shared attributes
        uint256 offerId;
        State state;
        address principalToken;
        uint256 currentPrincipal;
        uint256 initialPrincipal;
        uint256 interestRate;
        uint16 daysToMaturity;
        uint expiresAt;
        uint createdAt;
        address creator;
        // related to lending offers only
        address[] collateralTokens;
        // related to borrowing offers only
        address collateralToken;
        uint256 currentCollateral;
        uint256 initialCollateral;
        // type
        Type offerType;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library RequestLibrary {
    enum Type {
        LENDING_REQUEST,
        BORROWING_REQUEST
    }

    enum State {
        PENDING,
        ACCEPTED,
        REJECTED,
        CANCELLED
    }

    event RequestCreated(
        uint256 requestId,
        State state,
        uint16 percentage,
        uint16 daysToMaturity,
        uint256 interestRate,
        uint expiresAt,
        uint createdAt,
        address creator,
        uint256 offerId,
        address collateralToken,
        uint256 collateralAmount,
        uint256 collateralPriceInUSD,
        uint160 ltvUsed,
        RequestLibrary.Type requestType
    );

    struct Request {
        // shared
        uint256 requestId;
        State state;
        uint16 percentage;
        uint16 daysToMaturity;
        uint256 interestRate;
        uint expiresAt;
        uint createdAt;
        address creator;
        uint256 offerId;
        // related to borrowing request only
        address collateralToken;
        uint256 collateralAmount;
        uint256 collateralPriceInUSD;
        uint160 ltvUsed;
        // type
        Type requestType;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/OfferLibrary.sol";
import "../libraries/RequestLibrary.sol";

import "../interfaces/IOfferManager.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/*
    The OfferManager contract is responsible for bookeeping
    the offers and requests made.

    It can be only modified by the LendingPool contract,
    but can be read from external sources.

    Any OfferManager contract must inherite the IOfferManager interface.
*/

contract OfferManager is IOfferManager, Ownable2Step {
    uint256 public constant ONE_DAY = 60 * 60 * 24;
    uint256 public constant ONE_HOUR = 60 * 60;

    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // offers
    Counters.Counter private offerIdTracker;
    mapping(uint256 => OfferLibrary.Offer) public offers;

    // request
    Counters.Counter private requestIdTracker;
    mapping(uint256 => RequestLibrary.Request) public requests;

    address lendingPool;

    constructor() Ownable2Step() {}

    // creates a new lending offer
    function createLendingOffer(
        address principalToken,
        uint256 principalAmount,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint16 daysToExpire,
        address[] memory collateralTokens,
        address lender
    ) public override onlyLendingPool returns (uint256) {
        offerIdTracker.increment();
        uint256 offerId = offerIdTracker.current();

        uint256 createdAt = block.timestamp;
        uint256 duration = ONE_DAY.mul(daysToExpire);
        uint256 expiresAt = createdAt.add(duration);

        require(collateralTokens.length > 0, "ERR_NO_COLLATERAL_TYPES");

        offers[offerId] = OfferLibrary.Offer(
            // shared
            offerId,
            OfferLibrary.State.DEFAULT,
            principalToken,
            principalAmount, // currentPrincipal
            principalAmount, // initialPrincipal
            interestRate,
            daysToMaturity,
            expiresAt,
            createdAt,
            lender,
            // related to lending offers only
            collateralTokens,
            // related to borrowing offers only
            address(0),
            0,
            0,
            // type
            OfferLibrary.Type.LENDING_OFFER
        );

        _emitOffer(offerId, offers[offerId]);
        return offerId;
    }

    function reActivateOffer(
        uint256 offerId,
        uint16 toExpire,
        address user
    ) public override onlyLendingPool {
        OfferLibrary.Offer memory offer = offers[offerId];

        require(offer.creator == user, "ERR_ONLY_CREATOR");
        require(offer.initialCollateral == offer.currentCollateral);

        uint256 createdAt = block.timestamp;
        require(createdAt > offer.expiresAt, "ERR_NOT_EXPIRED");

        offerIdTracker.increment();

        uint256 duration;
        if (offer.offerType == OfferLibrary.Type.LENDING_OFFER) {
            duration = ONE_DAY.mul(toExpire);
        } else {
            duration = ONE_HOUR.mul(toExpire);
        }

        offer.expiresAt = createdAt + duration;
        offer.offerId = offerIdTracker.current();

        _emitOffer(offerId, offer);
    }

    // creates a new lending request
    function createLendingRequest(
        uint16 percentage,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint16 hoursToExpire,
        address lender,
        uint256 offerId
    ) public override onlyLendingPool returns (uint256) {
        requestIdTracker.increment();
        uint256 requestId = requestIdTracker.current();

        uint256 createdAt = block.timestamp;
        uint256 duration = ONE_HOUR.mul(hoursToExpire);
        uint256 expiresAt = createdAt.add(duration);

        OfferLibrary.Offer memory offer = offers[offerId];

        require(
            offer.offerType == OfferLibrary.Type.BORROWING_OFFER,
            "ERR_OFFER_TYPE"
        );

        if (offer.initialCollateral == offer.currentCollateral) {
            require(createdAt < offers[offerId].expiresAt, "ERR_OFFER_EXPIRED");
        }

        requests[requestId] = RequestLibrary.Request(
            // shared
            requestId,
            RequestLibrary.State.PENDING,
            percentage,
            daysToMaturity,
            interestRate,
            expiresAt,
            createdAt,
            lender,
            offerId,
            // related to borrowing request only
            address(0),
            0,
            0,
            0,
            // type
            RequestLibrary.Type.LENDING_REQUEST
        );

        _emitRequest(requestId, requests[requestId]);
        return requestId;
    }

    // creates a new borrowing offer
    function createBorrowingOffer(
        address principalToken,
        address collateralToken,
        uint256 collateralAmount,
        uint256 principalAmount,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint16 hoursToExpire,
        address borrower
    ) public override onlyLendingPool returns (uint256) {
        offerIdTracker.increment();
        uint256 offerId = offerIdTracker.current();

        uint256 createdAt = block.timestamp;
        uint256 duration = ONE_HOUR.mul(hoursToExpire);
        uint256 expiresAt = createdAt.add(duration);

        offers[offerId] = OfferLibrary.Offer(
            offerId,
            OfferLibrary.State.DEFAULT,
            principalToken,
            principalAmount, // currentPrincipal
            principalAmount, // initialPrincipal
            interestRate,
            daysToMaturity,
            expiresAt,
            createdAt,
            borrower,
            // related to lending offers only
            new address[](0),
            // related to borrowing offers only
            collateralToken,
            collateralAmount, // currentCollateral
            collateralAmount, //  initialCollateral
            // type
            OfferLibrary.Type.BORROWING_OFFER
        );

        _emitOffer(offerId, offers[offerId]);
        return offerId;
    }

    // creates a new borrowing request
    function createBorrowingRequest(
        uint16 percentage,
        address collateralToken,
        uint256 collateralAmount,
        uint256 collateralPriceInUSD,
        uint160 ltvUsed,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint16 hoursToExpire,
        address borrower,
        uint256 offerId
    ) public override onlyLendingPool returns (uint256) {
        requestIdTracker.increment();
        uint256 requestId = requestIdTracker.current();

        uint256 createdAt = block.timestamp;
        uint256 duration = ONE_HOUR.mul(hoursToExpire);
        uint256 expiresAt = createdAt.add(duration);

        OfferLibrary.Offer memory offer = offers[offerId];

        require(
            offer.offerType == OfferLibrary.Type.LENDING_OFFER,
            "ERR_OFFER_TYPE"
        );

        if (offer.initialCollateral == offer.currentCollateral) {
            require(createdAt < offers[offerId].expiresAt, "ERR_OFFER_EXPIRED");
        }

        requests[requestId] = RequestLibrary.Request(
            // shared
            requestId,
            RequestLibrary.State.PENDING,
            percentage,
            daysToMaturity,
            interestRate,
            expiresAt,
            createdAt,
            borrower,
            offerId,
            // related to borrowing request only
            collateralToken,
            collateralAmount,
            collateralPriceInUSD,
            ltvUsed,
            RequestLibrary.Type.BORROWING_REQUEST
        );

        _emitRequest(requestId, requests[requestId]);
        return requestId;
    }

    function rejectRequest(uint256 requestId, address user)
        public
        override
        onlyLendingPool
    {
        RequestLibrary.Request storage request = requests[requestId];
        OfferLibrary.Offer memory offer = offers[request.offerId];
        require(offer.creator == user, "ERR_ONLY_CREATOR");
        require(
            request.state == RequestLibrary.State.PENDING,
            "ERR_OFFER_STATE"
        );
        request.state = RequestLibrary.State.REJECTED;
        _emitRequest(requestId, request);
    }

    function acceptRequest(uint256 requestId, address user)
        public
        override
        onlyLendingPool
    {
        RequestLibrary.Request storage request = requests[requestId];
        OfferLibrary.Offer memory offer = offers[request.offerId];
        require(offer.creator == user, "ERR_ONLY_CREATOR");
        request.state = RequestLibrary.State.ACCEPTED;
        _emitRequest(requestId, request);
    }

    function cancelRequest(uint256 requestId, address user)
        public
        override
        onlyLendingPool
    {
        RequestLibrary.Request storage request = requests[requestId];
        require(request.creator == user, "ERR_ONLY_CREATOR");
        require(
            request.state != RequestLibrary.State.ACCEPTED,
            "ERR_ALREADY_USED"
        );
        require(
            request.state != RequestLibrary.State.CANCELLED,
            "ERR_ALREADY_CANCELLED"
        );
        request.state = RequestLibrary.State.CANCELLED;
        _emitRequest(requestId, request);
    }

    function removePrincipal(
        uint256 offerId,
        address user,
        uint256 amount
    ) public override onlyLendingPool {
        OfferLibrary.Offer storage offer = offers[offerId];
        require(
            offer.offerType == OfferLibrary.Type.LENDING_OFFER,
            "ERR_OFFER_TYPE"
        );
        require(offer.currentPrincipal >= amount, "INSUFICIENT_AMOUNT");
        require(offer.creator == user, "ERR_ONLY_LENDER");

        offer.currentPrincipal -= amount;

        if (amount == offer.initialPrincipal) {
            offer.state = OfferLibrary.State.CANCELLED;
        }

        _emitOffer(offerId, offer);
    }

    function removeCollateral(
        uint256 offerId,
        address user,
        uint256 amount
    ) public override onlyLendingPool {
        OfferLibrary.Offer storage offer = offers[offerId];
        require(
            offer.offerType == OfferLibrary.Type.BORROWING_OFFER,
            "ERR_OFFER_TYPE"
        );
        require(offer.currentCollateral >= amount, "INSUFICIENT_AMOUNT");
        require(offer.creator == user, "ERR_ONLY_LENDER");

        offer.currentCollateral -= amount;

        if (amount == offer.initialCollateral) {
            offer.state = OfferLibrary.State.CANCELLED;
        }

        _emitOffer(offerId, offer);
    }

    // events
    function _emitOffer(uint256 offerId, OfferLibrary.Offer memory offer)
        private
    {
        emit OfferLibrary.OfferCreated(
            offerId,
            offer.state,
            offer.principalToken,
            offer.currentPrincipal,
            offer.initialPrincipal,
            offer.interestRate,
            offer.daysToMaturity,
            offer.expiresAt,
            offer.createdAt,
            offer.creator,
            offer.collateralTokens,
            offer.collateralToken,
            offer.currentCollateral,
            offer.initialCollateral,
            offer.offerType
        );
    }

    function _emitRequest(
        uint256 requestId,
        RequestLibrary.Request memory request
    ) private {
        emit RequestLibrary.RequestCreated(
            requestId,
            request.state,
            request.percentage,
            request.daysToMaturity,
            request.interestRate,
            request.expiresAt,
            request.createdAt,
            request.creator,
            request.offerId,
            request.collateralToken,
            request.collateralAmount,
            request.collateralPriceInUSD,
            request.ltvUsed,
            request.requestType
        );
    }

    // called after a lending offer loan is executed
    function afterLendingLoan(uint256 offerId, uint256 principalAmount)
        public
        override
        onlyLendingPool
    {
        OfferLibrary.Offer storage offer = offers[offerId];
        require(
            offer.currentPrincipal >= principalAmount,
            "ERR_INSUFFICIENT_PRINCIPAL"
        );

        if (offer.initialCollateral == offer.currentCollateral) {
            require(offer.expiresAt > block.timestamp, "ERR_OFFER_EXPIRED");
        }

        offers[offerId].currentPrincipal -= principalAmount;

        _emitOffer(offerId, offer);
    }

    // called after a borrowing offer loan is executed
    function afterBorrowingLoan(
        uint256 offerId,
        uint256 principalAmount,
        uint256 collateralAmount
    ) public override onlyLendingPool {
        OfferLibrary.Offer storage offer = offers[offerId];
        require(
            offer.currentPrincipal >= principalAmount,
            "ERR_INSUFFICIENT_PRINCIPAL"
        );
        require(
            offer.currentCollateral >= collateralAmount,
            "ERR_INSUFFICIENT_COLLATERAL"
        );

        if (offer.initialCollateral == offer.currentCollateral) {
            require(offer.expiresAt > block.timestamp, "ERR_OFFER_EXPIRED");
        }

        offer.currentPrincipal -= principalAmount;
        offer.currentCollateral -= collateralAmount;

        _emitOffer(offerId, offer);
    }

    // checks if a offer support collateral token
    function isCollateralSupported(uint256 offerId, address token)
        public
        view
        override
        returns (bool)
    {
        OfferLibrary.Offer memory offer = offers[offerId];
        bool supported = false;
        for (
            uint256 index = 0;
            index < offer.collateralTokens.length;
            index++
        ) {
            if (offer.collateralTokens[index] == token) {
                supported = true;
                break;
            }
        }
        return supported;
    }

    // getters
    function getOffer(uint256 offerId)
        public
        view
        override
        returns (OfferLibrary.Offer memory)
    {
        return offers[offerId];
    }

    function getRequest(uint256 requestId)
        public
        view
        override
        returns (RequestLibrary.Request memory)
    {
        return requests[requestId];
    }

    function setLendingPool(address address_) public onlyOwner {
        lendingPool = address_;
    }

    modifier onlyLendingPool() {
        require(msg.sender == lendingPool);
        _;
    }
}