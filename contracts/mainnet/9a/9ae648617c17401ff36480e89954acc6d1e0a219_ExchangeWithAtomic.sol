/**
 *Submitted for verification at FtmScan.com on 2022-11-15
*/

// Sources flattened with hardhat v2.12.2 https://hardhat.org
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

// File contracts/interfaces/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}


// File contracts/utils/fromOZ/ECDSA.sol



/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}


// File contracts/PriceOracleDataTypes.sol



interface PriceOracleDataTypes {
    struct PriceDataOut {
        uint64 price;
        uint64 timestamp;
    }

}


// File contracts/PriceOracleInterface.sol



interface PriceOracleInterface is PriceOracleDataTypes {
    function assetPrices(address) external view returns (PriceDataOut memory);
    function givePrices(address[] calldata assetAddresses) external view returns (PriceDataOut[] memory);
}


// File contracts/libs/MarginalFunctionality.sol



library MarginalFunctionality {

    // We have the following approach: when liability is created we store
    // timestamp and size of liability. If the subsequent trade will deepen
    // this liability or won't fully cover it timestamp will not change.
    // However once outstandingAmount is covered we check whether balance on
    // that asset is positive or not. If not, liability still in the place but
    // time counter is dropped and timestamp set to `now`.
    struct Liability {
        address asset;
        uint64 timestamp;
        uint192 outstandingAmount;
    }

    enum PositionState {
        POSITIVE,
        NEGATIVE, // weighted position below 0
        OVERDUE,  // liability is not returned for too long
        NOPRICE,  // some assets has no price or expired
        INCORRECT // some of the basic requirements are not met: too many liabilities, no locked stake, etc
    }

    struct Position {
        PositionState state;
        int256 weightedPosition; // sum of weighted collateral minus liabilities
        int256 totalPosition; // sum of unweighted (total) collateral minus liabilities
        int256 totalLiabilities; // total liabilities value
    }

    // Constants from Exchange contract used for calculations
    struct UsedConstants {
        address user;
        address _oracleAddress;
        address _orionTokenAddress;
        uint64 positionOverdue;
        uint64 priceOverdue;
        uint8 stakeRisk;
        uint8 liquidationPremium;
    }


    /**
     * @dev method to multiply numbers with uint8 based percent numbers
     */
    function uint8Percent(int192 _a, uint8 b) internal pure returns (int192 c) {
        int a = int256(_a);
        int d = 255;
        c = int192((a>65536) ? (a/d)*b : a*b/d );
    }

    /**
     * @dev method to fetch asset prices in ORN tokens
     */
    function getAssetPrice(address asset, address oracle) internal view returns (uint64 price, uint64 timestamp) {
        PriceOracleInterface.PriceDataOut memory assetPriceData = PriceOracleInterface(oracle).assetPrices(asset);
        (price, timestamp) = (assetPriceData.price, assetPriceData.timestamp);
    }

    /**
     * @dev method to calc weighted and absolute collateral value
     * @notice it only count for assets in collateralAssets list, all other
               assets will add 0 to position.
     * @return outdated whether any price is outdated
     * @return weightedPosition in ORN
     * @return totalPosition in ORN
     */
    function calcAssets(
        address[] storage collateralAssets,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => uint8) storage assetRisks,
        address user,
        address orionTokenAddress,
        address oracleAddress,
        uint64 priceOverdue
    ) internal view returns (bool outdated, int192 weightedPosition, int192 totalPosition) {
        uint256 collateralAssetsLength = collateralAssets.length;
        for(uint256 i = 0; i < collateralAssetsLength; i++) {
            address asset = collateralAssets[i];
            if(assetBalances[user][asset]<0)
                continue; // will be calculated in calcLiabilities
            (uint64 price, uint64 timestamp) = (1e8, 0xfffffff000000000);

            if(asset != orionTokenAddress) {
                (price, timestamp) = getAssetPrice(asset, oracleAddress);
            }

            // balance: i192, price u64 => balance*price fits i256
            // since generally balance <= N*maxInt112 (where N is number operations with it),
            // assetValue <= N*maxInt112*maxUInt64/1e8.
            // That is if N<= 2**17 *1e8 = 1.3e13  we can neglect overflows here

            uint8 specificRisk = assetRisks[asset];
            int192 balance = assetBalances[user][asset];
            int256 _assetValue = int256(balance)*price/1e8;
            int192 assetValue = int192(_assetValue);

            // Overflows logic holds here as well, except that N is the number of
            // operations for all assets

            if(assetValue>0) {
                weightedPosition += uint8Percent(assetValue, specificRisk);
                totalPosition += assetValue;
                outdated = outdated || ((timestamp + priceOverdue) < block.timestamp);
            }

        }

        return (outdated, weightedPosition, totalPosition);
    }

    /**
     * @dev method to calc liabilities
     * @return outdated whether any price is outdated
     * @return overdue whether any liability is overdue
     * @return weightedPosition weightedLiability == totalLiability in ORN
     * @return totalPosition totalLiability in ORN
     */
    function calcLiabilities(
        mapping(address => Liability[]) storage liabilities,
        mapping(address => mapping(address => int192)) storage assetBalances,
        address user,
        address oracleAddress,
        uint64 positionOverdue,
        uint64 priceOverdue
    ) internal view returns  (bool outdated, bool overdue, int192 weightedPosition, int192 totalPosition) {
        uint256 liabilitiesLength = liabilities[user].length;

        for(uint256 i = 0; i < liabilitiesLength; i++) {
            Liability storage liability = liabilities[user][i];
            int192 balance = assetBalances[user][liability.asset];
            (uint64 price, uint64 timestamp) = getAssetPrice(liability.asset, oracleAddress);
            // balance: i192, price u64 => balance*price fits i256
            // since generally balance <= N*maxInt112 (where N is number operations with it),
            // assetValue <= N*maxInt112*maxUInt64/1e8.
            // That is if N<= 2**17 *1e8 = 1.3e13  we can neglect overflows here

            int192 liabilityValue = int192(int256(balance) * price / 1e8);
            weightedPosition += liabilityValue; //already negative since balance is negative
            totalPosition += liabilityValue;
            overdue = overdue || ((liability.timestamp + positionOverdue) < block.timestamp);
            outdated = outdated || ((timestamp + priceOverdue) < block.timestamp);
        }

        return (outdated, overdue, weightedPosition, totalPosition);
    }

    /**
     * @dev method to calc Position
     * @return result position structure
     */
    function calcPosition(
        address[] storage collateralAssets,
        mapping(address => Liability[]) storage liabilities,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => uint8) storage assetRisks,
        UsedConstants memory constants
    ) public view returns (Position memory result) {

        (bool outdatedPrice, int192 weightedPosition, int192 totalPosition) =
        calcAssets(
            collateralAssets,
            assetBalances,
            assetRisks,
            constants.user,
            constants._orionTokenAddress,
            constants._oracleAddress,
            constants.priceOverdue
        );

        (bool _outdatedPrice, bool overdue, int192 _weightedPosition, int192 _totalPosition) =
        calcLiabilities(
            liabilities,
            assetBalances,
            constants.user,
            constants._oracleAddress,
            constants.positionOverdue,
            constants.priceOverdue
        );

        weightedPosition += _weightedPosition;
        totalPosition += _totalPosition;
        outdatedPrice = outdatedPrice || _outdatedPrice;
        if(_totalPosition<0) {
            result.totalLiabilities = _totalPosition;
        }
        if(weightedPosition<0) {
            result.state = PositionState.NEGATIVE;
        }
        if(outdatedPrice) {
            result.state = PositionState.NOPRICE;
        }
        if(overdue) {
            result.state = PositionState.OVERDUE;
        }
        result.weightedPosition = weightedPosition;
        result.totalPosition = totalPosition;
    }

    /**
     * @dev method removes liability
     */
    function removeLiability(
        address user,
        address asset,
        mapping(address => Liability[]) storage liabilities
    ) public {
        uint256 length = liabilities[user].length;

        for (uint256 i = 0; i < length; i++) {
            if (liabilities[user][i].asset == asset) {
                if (length>1) {
                    liabilities[user][i] = liabilities[user][length - 1];
                }
                liabilities[user].pop();
                break;
            }
        }
    }

    /**
     * @dev method update liability
     * @notice implement logic for outstandingAmount (see Liability description)
     */
    function updateLiability(address user,
        address asset,
        mapping(address => Liability[]) storage liabilities,
        uint112 depositAmount,
        int192 currentBalance
    ) internal {
        if(currentBalance>=0) {
            removeLiability(user,asset,liabilities);
        } else {
            uint256 i;
            uint256 liabilitiesLength=liabilities[user].length;
            for(; i<liabilitiesLength-1; i++) {
                if(liabilities[user][i].asset == asset)
                    break;
            }
            Liability storage liability = liabilities[user][i];
            if(depositAmount>=liability.outstandingAmount) {
                liability.outstandingAmount = uint192(-currentBalance);
                liability.timestamp = uint64(block.timestamp);
            } else {
                liability.outstandingAmount -= depositAmount;
            }
        }
    }


    /**
     * @dev partially liquidate, that is cover some asset liability to get
            ORN from misbehavior broker
     */
    function partiallyLiquidate(address[] storage collateralAssets,
        mapping(address => Liability[]) storage liabilities,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => uint8) storage assetRisks,
        UsedConstants memory constants,
        address redeemedAsset,
        uint112 amount) public {
        //Note: constants.user - is broker who will be liquidated
        Position memory initialPosition = calcPosition(collateralAssets,
            liabilities,
            assetBalances,
            assetRisks,
            constants);
        require(initialPosition.state == PositionState.NEGATIVE ||
            initialPosition.state == PositionState.OVERDUE  , "E7");
        address liquidator = msg.sender;
        require(assetBalances[liquidator][redeemedAsset]>=amount,"E8");
        require(assetBalances[constants.user][redeemedAsset]<0,"E15");
        assetBalances[liquidator][redeemedAsset] -= amount;
        assetBalances[constants.user][redeemedAsset] += amount;

        if(assetBalances[constants.user][redeemedAsset] >= 0)
            removeLiability(constants.user, redeemedAsset, liabilities);

        (uint64 price, uint64 timestamp) = getAssetPrice(redeemedAsset, constants._oracleAddress);
        require((timestamp + constants.priceOverdue) > block.timestamp, "E9"); //Price is outdated

        reimburseLiquidator(
            amount,
            price,
            liquidator,
            assetBalances,
            constants.liquidationPremium,
            constants.user,
            constants._orionTokenAddress
        );

        Position memory finalPosition = calcPosition(collateralAssets,
            liabilities,
            assetBalances,
            assetRisks,
            constants);
        require( int(finalPosition.state)<3 && //POSITIVE,NEGATIVE or OVERDUE
            (finalPosition.weightedPosition>initialPosition.weightedPosition),
            "E10");//Incorrect state position after liquidation
        if(finalPosition.state == PositionState.POSITIVE)
            require (finalPosition.weightedPosition<10e8,"Can not liquidate to very positive state");

    }

    /**
     * @dev reimburse liquidator with ORN: first from stake, than from broker balance
     */
    function reimburseLiquidator(
        uint112 amount,
        uint64 price,
        address liquidator,
        mapping(address => mapping(address => int192)) storage assetBalances,
        uint8 liquidationPremium,
        address user,
        address orionTokenAddress
    ) internal {
        int192 _orionAmount = int192(int256(amount)*price/1e8);
        _orionAmount += uint8Percent(_orionAmount, liquidationPremium); //Liquidation premium
        // There is only 100m Orion tokens, fits i64
        require(_orionAmount == int64(_orionAmount), "E11");
        int192 onBalanceOrion = assetBalances[user][orionTokenAddress];

        require(onBalanceOrion >= _orionAmount, "E10");
        assetBalances[user][orionTokenAddress] -= _orionAmount;
        assetBalances[liquidator][orionTokenAddress] += _orionAmount;
    }
}


// File contracts/ExchangeStorage.sol




// Base contract which contain state variable of the first version of Exchange
// deployed on mainnet. Changes of the state variables should be introduced
// not in that contract but down the inheritance chain, to allow safe upgrades
// More info about safe upgrades here:
// https://blog.openzeppelin.com/the-state-of-smart-contract-upgrades/#upgrade-patterns

contract ExchangeStorage {

    //order -> filledAmount
    mapping(bytes32 => uint192) public filledAmounts;


    // Get user balance by address and asset address
    mapping(address => mapping(address => int192)) internal assetBalances;
    // List of assets with negative balance for each user
    mapping(address => MarginalFunctionality.Liability[]) public liabilities;
    // List of assets which can be used as collateral and risk coefficients for them
    address[] internal collateralAssets;
    mapping(address => uint8) public assetRisks;
    // Risk coefficient for locked ORN
    uint8 public stakeRisk;
    // Liquidation premium
    uint8 public liquidationPremium;
    // Delays after which price and position become outdated
    uint64 public priceOverdue;
    uint64 public positionOverdue;

    // Base orion tokens (can be locked on stake)
    IERC20 _orionToken;
    // Address of price oracle contract
    address _oracleAddress;
    // Address from which matching of orders is allowed
    address _allowedMatcher;

}


// File contracts/utils/Initializable.sol

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}


// File contracts/utils/Context.sol


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}


// File contracts/utils/Ownable.sol


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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

    }


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}


// File contracts/OrionVault.sol




abstract contract OrionVault is ExchangeStorage, OwnableUpgradeSafe {

    enum StakePhase{ NOTSTAKED, LOCKED, RELEASING, READYTORELEASE, FROZEN }

    struct Stake {
        uint64 amount; // 100m ORN in circulation fits uint64
        StakePhase phase;
        uint64 lastActionTimestamp;
    }

    uint64 constant releasingDuration = 3600*24;
    mapping(address => Stake) private stakingData;

    /**
     * @dev Returns locked or frozen stake balance only
     * @param user address
     */
    function getLockedStakeBalance(address user) public view returns (uint256) {
        return stakingData[user].amount;
    }

    /**
     * @dev Request stake unlock for msg.sender
     * @dev If stake phase is LOCKED, that changes phase to RELEASING
     * @dev If stake phase is READYTORELEASE, that withdraws stake to balance
     * @dev Note, both unlock and withdraw is impossible if user has liabilities
     */
    function requestReleaseStake() public {
        address user = _msgSender();
        Stake storage stake = stakingData[user];
        assetBalances[user][address(_orionToken)] += stake.amount;
        stake.amount = 0;
        stake.phase = StakePhase.NOTSTAKED;
    }

    /**
     * @dev Lock some orions from exchange balance sheet
     * @param amount orions in 1e-8 units to stake
     */
    function lockStake(uint64 amount) public {
        address user = _msgSender();
        require(assetBalances[user][address(_orionToken)]>amount, "E1S");
        Stake storage stake = stakingData[user];

        assetBalances[user][address(_orionToken)] -= amount;
        stake.amount += amount;
    }

}


// File contracts/interfaces/IERC20Simple.sol



interface IERC20Simple {
    function decimals() external view virtual returns (uint8);
}


// File contracts/utils/fromOZ/SafeMath.sol



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


// File contracts/libs/LibUnitConverter.sol




library LibUnitConverter {

    using SafeMath for uint;

    /**
        @notice convert asset amount from8 decimals (10^8) to its base unit
     */
    function decimalToBaseUnit(address assetAddress, uint amount) internal view returns(uint112 baseValue){
        uint256 result;

        if(assetAddress == address(0)){
            result =  amount.mul(1 ether).div(10**8); // 18 decimals
        } else {
            uint decimals = IERC20Simple(assetAddress).decimals();

            result = amount.mul(10**decimals).div(10**8);
        }

        require(result < uint256(type(int112).max), "E3U");
        baseValue = uint112(result);
    }

    /**
        @notice convert asset amount from its base unit to 8 decimals (10^8)
     */
    function baseUnitToDecimal(address assetAddress, uint amount) internal view returns(uint112 decimalValue){
        uint256 result;

        if(assetAddress == address(0)){
            result = amount.mul(10**8).div(1 ether);
        } else {
            uint decimals = IERC20Simple(assetAddress).decimals();

            result = amount.mul(10**8).div(10**decimals);
        }
        require(result < uint256(type(int112).max), "E3U");
        decimalValue = uint112(result);
    }
}


// File contracts/utils/ReentrancyGuard.sol



contract ReentrancyGuard {

    bytes32 private constant REENTRANCY_MUTEX_POSITION = 0xe855346402235fdd185c890e68d2c4ecad599b88587635ee285bce2fda58dacb;

    string private constant ERROR_REENTRANT = "REENTRANCY_REENTRANT_CALL";

    function getStorageBool(bytes32 position) internal view returns (bool data) {
        assembly { data := sload(position) }
    }

    function setStorageBool(bytes32 position, bool data) internal {
        assembly { sstore(position, data) }
    }


    modifier nonReentrant() {
        // Ensure mutex is unlocked
        require(!getStorageBool(REENTRANCY_MUTEX_POSITION), ERROR_REENTRANT);

        // Lock mutex before function call
        setStorageBool(REENTRANCY_MUTEX_POSITION,true);

        // Perform function call
        _;

        // Unlock mutex after function call
        setStorageBool(REENTRANCY_MUTEX_POSITION, false);
    }
}


// File contracts/libs/LibValidator.sol



library LibValidator {

    using ECDSA for bytes32;

    string public constant DOMAIN_NAME = "Orion Exchange";
    string public constant DOMAIN_VERSION = "1";
    uint256 public constant CHAIN_ID = 250;
    bytes32 public constant DOMAIN_SALT = 0xf2d857f4a3edcb9b78b4d503bfe733db1e3f6cdc2b7971ee739626c97e86a557;

    bytes32 public constant EIP712_DOMAIN_TYPEHASH = keccak256(
        abi.encodePacked(
            "EIP712Domain(string name,string version,uint256 chainId,bytes32 salt)"
        )
    );
    bytes32 public constant ORDER_TYPEHASH = keccak256(
        abi.encodePacked(
            "Order(address senderAddress,address matcherAddress,address baseAsset,address quoteAsset,address matcherFeeAsset,uint64 amount,uint64 price,uint64 matcherFee,uint64 nonce,uint64 expiration,uint8 buySide)"
        )
    );

    bytes32 public constant DOMAIN_SEPARATOR = keccak256(
        abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes(DOMAIN_NAME)),
            keccak256(bytes(DOMAIN_VERSION)),
            CHAIN_ID,
            DOMAIN_SALT
        )
    );

    struct Order {
        address senderAddress;
        address matcherAddress;
        address baseAsset;
        address quoteAsset;
        address matcherFeeAsset;
        uint64 amount;
        uint64 price;
        uint64 matcherFee;
        uint64 nonce;
        uint64 expiration;
        uint8 buySide; // buy or sell
        bool isPersonalSign;
        bytes signature;
    }

    /**
     * @dev validate order signature
     */
    function validateV3(Order memory order) public pure returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                getTypeValueHash(order)
            )
        );

        return digest.recover(order.signature) == order.senderAddress;
    }

    /**
     * @return hash order
     */
    function getTypeValueHash(Order memory _order)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    _order.senderAddress,
                    _order.matcherAddress,
                    _order.baseAsset,
                    _order.quoteAsset,
                    _order.matcherFeeAsset,
                    _order.amount,
                    _order.price,
                    _order.matcherFee,
                    _order.nonce,
                    _order.expiration,
                    _order.buySide
                )
            );
    }

    /**
     * @dev basic checks of matching orders against each other
     */
    function checkOrdersInfo(
        Order memory buyOrder,
        Order memory sellOrder,
        address sender,
        uint256 filledAmount,
        uint256 filledPrice,
        uint256 currentTime,
        address allowedMatcher
    ) public pure returns (bool success) {
        buyOrder.isPersonalSign ? require(validatePersonal(buyOrder), "E2BP") : require(validateV3(buyOrder), "E2B");
        sellOrder.isPersonalSign ? require(validatePersonal(sellOrder), "E2SP") : require(validateV3(sellOrder), "E2S");

        // Same matcher address
        require(
            buyOrder.matcherAddress == sender &&
                sellOrder.matcherAddress == sender,
            "E3M"
        );

        if(allowedMatcher != address(0)) {
          require(buyOrder.matcherAddress == allowedMatcher, "E3M2");
        }


        // Check matching assets
        require(
            buyOrder.baseAsset == sellOrder.baseAsset &&
                buyOrder.quoteAsset == sellOrder.quoteAsset,
            "E3As"
        );

        // Check order amounts
        require(filledAmount <= buyOrder.amount, "E3AmB");
        require(filledAmount <= sellOrder.amount, "E3AmS");

        // Check Price values
        require(filledPrice <= buyOrder.price, "E3");
        require(filledPrice >= sellOrder.price, "E3");

        // Check Expiration Time. Convert to seconds first
        require(buyOrder.expiration/1000 >= currentTime, "E4B");
        require(sellOrder.expiration/1000 >= currentTime, "E4S");

        require( buyOrder.buySide==1 && sellOrder.buySide==0, "E3D");
        success = true;
    }

    function getEthSignedOrderHash(Order memory _order) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "order",
                    _order.senderAddress,
                    _order.matcherAddress,
                    _order.baseAsset,
                    _order.quoteAsset,
                    _order.matcherFeeAsset,
                    _order.amount,
                    _order.price,
                    _order.matcherFee,
                    _order.nonce,
                    _order.expiration,
                    _order.buySide
                )
            ).toEthSignedMessageHash();
    }

    function validatePersonal(Order memory order) public pure returns (bool) {

        bytes32 digest = getEthSignedOrderHash(order);
        return digest.recover(order.signature) == order.senderAddress;
    }

    function checkOrderSingleMatch(
        Order memory buyOrder,
        address sender,
        address allowedMatcher,
        uint112 filledAmount,
        uint256 currentTime,
        address asset_spend,
        address asset_receive
    ) internal pure {
        buyOrder.isPersonalSign ? require(validatePersonal(buyOrder), "E2BP") : require(validateV3(buyOrder), "E2B");
        require(buyOrder.matcherAddress == sender && buyOrder.matcherAddress == allowedMatcher, "E3M2");
        if(buyOrder.buySide==1){
            require(
                buyOrder.baseAsset == asset_receive &&
                buyOrder.quoteAsset == asset_spend,
                "E3As"
            );
        }else{
            require(
                buyOrder.quoteAsset == asset_receive &&
                buyOrder.baseAsset == asset_spend,
                "E3As"
            );
        }
        require(filledAmount <= buyOrder.amount, "E3AmB");
        require(buyOrder.expiration/1000 >= currentTime, "E4B");
    }
}


// File contracts/utils/fromOZ/Address.sol



/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File contracts/utils/fromOZ/SafeERC20.sol





/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/interfaces/IWETH.sol



interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


// File contracts/libs/SafeTransferHelper.sol






library SafeTransferHelper {

    function safeAutoTransferFrom(address weth, address token, address from, address to, uint value) internal {
        if (token == address(0)) {
            require(from == address(this), "TransferFrom: this");
            IWETH(weth).deposit{value: value}();
            assert(IWETH(weth).transfer(to, value));
        } else {
            if (from == address(this)) {
                SafeERC20.safeTransfer(IERC20(token), to, value);
            } else {
                SafeERC20.safeTransferFrom(IERC20(token), from, to, value);
            }
        }
    }

    function safeAutoTransferTo(address weth, address token, address to, uint value) internal {
        if (address(this) != to) {
            if (token == address(0)) {
                IWETH(weth).withdraw(value);
                Address.sendValue(payable(to), value);
            } else {
                SafeERC20.safeTransfer(IERC20(token), to, value);
            }
        }
    }

    function safeTransferTokenOrETH(address token, address to, uint value) internal {
        if (address(this) != to) {
            if (token == address(0)) {
                Address.sendValue(payable(to), value);
            } else {
                SafeERC20.safeTransfer(IERC20(token), to, value);
            }
        }
    }
}


// File contracts/libs/LibExchange.sol








library LibExchange {
    using SafeERC20 for IERC20;

    //  Flags for updateOrders
    //      All flags are explicit
    uint8 public constant kSell = 0;
    uint8 public constant kBuy = 1; //  if 0 - then sell
    uint8 public constant kCorrectMatcherFeeByOrderAmount = 2;

    event NewTrade(
        address indexed buyer,
        address indexed seller,
        address baseAsset,
        address quoteAsset,
        uint64 filledPrice,
        uint192 filledAmount,
        uint192 amountQuote
    );

    function _updateBalance(address user, address asset, int amount,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) internal returns (uint tradeType) { // 0 - in contract, 1 - from wallet
        int beforeBalance = int(assetBalances[user][asset]);
        int afterBalance = beforeBalance + amount;
        require((amount >= 0 && afterBalance >= beforeBalance) || (amount < 0 && afterBalance < beforeBalance), "E11");

        if (amount > 0 && beforeBalance < 0) {
            MarginalFunctionality.updateLiability(user, asset, liabilities, uint112(amount), int192(afterBalance));
        } else if (beforeBalance >= 0 && afterBalance < 0){
            if (asset != address(0)) {
                afterBalance += int(_tryDeposit(asset, uint(-1*afterBalance), user));
            }

            // If we failed to deposit balance is still negative then we move user into liability
            if (afterBalance < 0) {
                setLiability(user, asset, int192(afterBalance), liabilities);
            } else {
                tradeType = beforeBalance > 0 ? 0 : 1;
            }
        }

        if (beforeBalance != afterBalance) {
            require(afterBalance >= type(int192).min && afterBalance <= type(int192).max, "E11");
            assetBalances[user][asset] = int192(afterBalance);
        }
    }

    /**
     * @dev method to add liability
     * @param user - user which created liability
     * @param asset - liability asset
     * @param balance - current negative balance
     */
    function setLiability(address user, address asset, int192 balance,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) internal {
        liabilities[user].push(
            MarginalFunctionality.Liability({
                asset : asset,
                timestamp : uint64(block.timestamp),
                outstandingAmount : uint192(- balance)
            })
        );
    }

    function _tryDeposit(
        address asset,
        uint amount,
        address user
    ) internal returns(uint) {
        uint256 amountInBase = uint256(LibUnitConverter.decimalToBaseUnit(asset, amount));

        // Query allowance before trying to transferFrom
        if (IERC20(asset).balanceOf(user) >= amountInBase && IERC20(asset).allowance(user, address(this)) >= amountInBase) {
            SafeERC20.safeTransferFrom(IERC20(asset), user, address(this), amountInBase);
            return amount;
        } else {
            return 0;
        }
    }

    function creditUserAssets(uint tradeType, address user, int amount, address asset,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) internal {
        int beforeBalance = int(assetBalances[user][asset]);
        int remainingAmount = amount + beforeBalance;
        require((amount >= 0 && remainingAmount >= beforeBalance) || (amount < 0 && remainingAmount < beforeBalance), "E11");
        int sentAmount = 0;

        if (tradeType == 0 && asset == address(0) && user.balance < 1e16) {
            tradeType = 1;
        }

        if (tradeType == 1 && amount > 0 && remainingAmount > 0) {
            uint amountInBase = uint(LibUnitConverter.decimalToBaseUnit(asset, uint(amount)));
            uint contractBalance = asset == address(0) ? address(this).balance : IERC20(asset).balanceOf(address(this));
            if (contractBalance >= amountInBase) {
                SafeTransferHelper.safeTransferTokenOrETH(asset, user, amountInBase);
                sentAmount = amount;
            }
        }
        int toUpdate = amount - sentAmount;
        if (toUpdate != 0) {
            _updateBalance(user, asset, toUpdate, assetBalances, liabilities);
        }
    }

    struct SwapBalanceChanges {
        int amountOut;
        address assetOut;
        int amountIn;
        address assetIn;
    }

    /**
     *  @notice update user balances and send matcher fee
     *  @param flags uint8, see constants for possible flags of order
     */
    function updateOrderBalanceDebit(
        LibValidator.Order memory order,
        uint112 amountBase,
        uint112 amountQuote,
        uint8 flags,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) internal returns (uint tradeType, int actualIn) {
        bool isSeller = (flags & kBuy) == 0;

        {
            //  Stack too deep
            bool isCorrectFee = ((flags & kCorrectMatcherFeeByOrderAmount) != 0);

            if (isCorrectFee) {
                // matcherFee: u64, filledAmount u128 => matcherFee*filledAmount fit u256
                // result matcherFee fit u64
                order.matcherFee = uint64(
                    (uint256(order.matcherFee) * amountBase) / order.amount
                ); //rewrite in memory only
            }
        }

        if (amountBase > 0) {
            SwapBalanceChanges memory swap;

            (swap.amountOut, swap.amountIn) = isSeller
            ? (-1*int(amountBase), int(amountQuote))
            : (-1*int(amountQuote), int(amountBase));

            (swap.assetOut, swap.assetIn) = isSeller
            ? (order.baseAsset, order.quoteAsset)
            : (order.quoteAsset, order.baseAsset);


            uint feeTradeType = 1;
            if (order.matcherFeeAsset == swap.assetOut) {
                swap.amountOut -= order.matcherFee;
            } else if (order.matcherFeeAsset == swap.assetIn) {
                swap.amountIn -= order.matcherFee;
            } else {
                feeTradeType = _updateBalance(order.senderAddress, order.matcherFeeAsset, -1*int256(order.matcherFee),
                    assetBalances, liabilities);
            }

            tradeType = feeTradeType & _updateBalance(order.senderAddress, swap.assetOut, swap.amountOut, assetBalances, liabilities);

            actualIn = swap.amountIn;

            _updateBalance(order.matcherAddress, order.matcherFeeAsset, order.matcherFee, assetBalances, liabilities);
        }

    }

}


// File contracts/Exchange.sol











/**
 * @title Exchange
 * @dev Exchange contract for the Orion Protocol
 * @author @wafflemakr
 */

/*

  Overflow safety:
  We do not use SafeMath and control overflows by
  not accepting large ints on input.

  Balances inside contract are stored as int192.

  Allowed input amounts are int112 or uint112: it is enough for all
  practically used tokens: for instance if decimal unit is 1e18, int112
  allow to encode up to 2.5e15 decimal units.
  That way adding/subtracting any amount from balances won't overflow, since
  minimum number of operations to reach max int is practically infinite: ~1e24.

  Allowed prices are uint64. Note, that price is represented as
  price per 1e8 tokens. That means that amount*price always fit uint256,
  while amount*price/1e8 not only fit int192, but also can be added, subtracted
  without overflow checks: number of malicion operations to overflow ~1e13.
*/
contract Exchange is OrionVault, ReentrancyGuard {
    using LibValidator for LibValidator.Order;
    using SafeERC20 for IERC20;

    //  Flags for updateOrders
    //      All flags are explicit
    uint8 constant kSell = 0;
    uint8 constant kBuy = 1; //  if 0 - then sell
    uint8 constant kCorrectMatcherFeeByOrderAmount = 2;

    // EVENTS
    event NewAssetTransaction(
        address indexed user,
        address indexed assetAddress,
        bool isDeposit,
        uint112 amount,
        uint64 timestamp
    );

    event NewTrade(
        address indexed buyer,
        address indexed seller,
        address baseAsset,
        address quoteAsset,
        uint64 filledPrice,
        uint192 filledAmount,
        uint192 amountQuote
    );

    // MAIN FUNCTIONS

    /**
     * @dev Since Exchange will work behind the Proxy contract it can not have constructor
     */
    function initialize() public payable initializer {
        OwnableUpgradeSafe.__Ownable_init();
    }

    /**
     * @dev set marginal settings
     * @param _collateralAssets - list of addresses of assets which may be used as collateral
     * @param _stakeRisk - risk coefficient for staken orion as uint8 (0=0, 255=1)
     * @param _liquidationPremium - premium for liquidator as uint8 (0=0, 255=1)
     * @param _priceOverdue - time after that price became outdated
     * @param _positionOverdue - time after that liabilities became overdue and may be liquidated
     */

    function updateMarginalSettings(
        address[] calldata _collateralAssets,
        uint8 _stakeRisk,
        uint8 _liquidationPremium,
        uint64 _priceOverdue,
        uint64 _positionOverdue
    ) public onlyOwner {
        collateralAssets = _collateralAssets;
        stakeRisk = _stakeRisk;
        liquidationPremium = _liquidationPremium;
        priceOverdue = _priceOverdue;
        positionOverdue = _positionOverdue;
    }

    /**
     * @dev set risk coefficients for collateral assets
     * @param assets - list of assets
     * @param risks - list of risks as uint8 (0=0, 255=1)
     */
    function updateAssetRisks(address[] calldata assets, uint8[] calldata risks)
        public onlyOwner {
        for (uint256 i; i < assets.length; i++)
            assetRisks[assets[i]] = risks[i];
    }

    /**
     * @dev Deposit ERC20 tokens to the exchange contract
     * @dev User needs to approve token contract first
     * @param amount asset amount to deposit in its base unit
     */
    function depositAsset(address assetAddress, uint112 amount) external {
        uint256 actualAmount = IERC20(assetAddress).balanceOf(address(this));
        IERC20(assetAddress).safeTransferFrom(
            msg.sender,
            address(this),
            uint256(amount)
        );
        actualAmount = IERC20(assetAddress).balanceOf(address(this)) - actualAmount;
        generalDeposit(assetAddress, uint112(actualAmount));
    }

    /**
     * @notice Deposit ETH to the exchange contract
     * @dev deposit event will be emitted with the amount in decimal format (10^8)
     * @dev balance will be stored in decimal format too
     */
    function deposit() external payable {
        generalDeposit(address(0), uint112(msg.value));
    }

    /**
     * @dev internal implementation of deposits
     */
    function generalDeposit(address assetAddress, uint112 amount) internal {
        address user = msg.sender;
        bool wasLiability = assetBalances[user][assetAddress] < 0;
        uint112 safeAmountDecimal = LibUnitConverter.baseUnitToDecimal(
            assetAddress,
            amount
        );
        assetBalances[user][assetAddress] += safeAmountDecimal;
        if (amount > 0)
            emit NewAssetTransaction(
                user,
                assetAddress,
                true,
                safeAmountDecimal,
                uint64(block.timestamp)
            );
        if (wasLiability)
            MarginalFunctionality.updateLiability(
                user,
                assetAddress,
                liabilities,
                uint112(safeAmountDecimal),
                assetBalances[user][assetAddress]
            );
    }

    /**
     * @dev Withdrawal of remaining funds from the contract back to the address
     * @param assetAddress address of the asset to withdraw
     * @param amount asset amount to withdraw in its base unit
     */
    function withdraw(address assetAddress, uint112 amount)
        external nonReentrant {
        uint112 safeAmountDecimal = LibUnitConverter.baseUnitToDecimal(
            assetAddress,
            amount
        );
        address user = msg.sender;

        assetBalances[user][assetAddress] -= safeAmountDecimal;
        require(assetBalances[user][assetAddress] >= 0, "E1w1"); //TODO
        require(checkPosition(user), "E1w2"); //TODO

        if (assetAddress == address(0)) {
            (bool success, ) = user.call{value: amount}("");
            require(success, "E6w");
        } else {
            IERC20(assetAddress).safeTransfer(user, amount);
        }

        emit NewAssetTransaction(
            user,
            assetAddress,
            false,
            safeAmountDecimal,
            uint64(block.timestamp)
        );
    }

    /**
     * @dev Get asset balance for a specific address
     * @param assetAddress address of the asset to query
     * @param user user address to query
     */
    function getBalance(address assetAddress, address user)
        public view returns (int192) {
        return assetBalances[user][assetAddress];
    }

    /**
     * @dev Batch query of asset balances for a user
     * @param assetsAddresses array of addresses of the assets to query
     * @param user user address to query
     */
    function getBalances(address[] memory assetsAddresses, address user)
        public view returns (int192[] memory balances) {
        balances = new int192[](assetsAddresses.length);
        for (uint256 i; i < assetsAddresses.length; i++) {
            balances[i] = assetBalances[user][assetsAddresses[i]];
        }
    }

    /**
     * @dev Batch query of asset liabilities for a user
     * @param user user address to query
     */
    function getLiabilities(address user)
        public view returns (MarginalFunctionality.Liability[] memory liabilitiesArray) {
        return liabilities[user];
    }

    /**
     * @dev Return list of assets which can be used for collateral
     */
    function getCollateralAssets() public view returns (address[] memory) {
        return collateralAssets;
    }

    /**
     * @dev get hash for an order
     * @dev we use order hash as order id to prevent double matching of the same order
     */
    function getOrderHash(LibValidator.Order memory order)
        public pure returns (bytes32) {
        return order.getTypeValueHash();
    }

    /**
     * @dev get filled amounts for a specific order
     */

    function getFilledAmounts(
        bytes32 orderHash,
        LibValidator.Order memory order
    ) public view returns (int192 totalFilled, int192 totalFeesPaid) {
        totalFilled = int192(filledAmounts[orderHash]); //It is safe to convert here: filledAmounts is result of ui112 additions
        totalFeesPaid = int192(
            (uint256(order.matcherFee) * uint112(totalFilled)) / order.amount
        ); //matcherFee is u64; safe multiplication here
    }

    /**
     * @notice Settle a trade with two orders, filled price and amount
     * @dev 2 orders are submitted, it is necessary to match them:
        check conditions in orders for compliance filledPrice, filledAmountbuyOrderHash
        change balances on the contract respectively with buyer, seller, matcbuyOrderHashher
     * @param buyOrder structure of buy side orderbuyOrderHash
     * @param sellOrder structure of sell side order
     * @param filledPrice price at which the order was settled
     * @param filledAmount amount settled between orders
     */
    struct UpdateOrderBalanceData {
        uint buyType;
        uint sellType;
        int buyIn;
        int sellIn;
    }

    function fillOrders(
        LibValidator.Order memory buyOrder,
        LibValidator.Order memory sellOrder,
        uint64 filledPrice,
        uint112 filledAmount
    ) public nonReentrant {
        // --- VARIABLES --- //
        // Amount of quote asset
        uint256 _amountQuote = (uint256(filledAmount) * filledPrice) / (10**8);
        require(_amountQuote < type(uint112).max, "E12G");
        uint112 amountQuote = uint112(_amountQuote);

        // Order Hashes
        bytes32 buyOrderHash = buyOrder.getTypeValueHash();
        bytes32 sellOrderHash = sellOrder.getTypeValueHash();

        // --- VALIDATIONS --- //

        // Validate signatures using eth typed sign V1
        require(
            LibValidator.checkOrdersInfo(
                buyOrder,
                sellOrder,
                msg.sender,
                filledAmount,
                filledPrice,
                block.timestamp,
                _allowedMatcher
            ),
            "E3G"
        );

        // --- UPDATES --- //

        //updateFilledAmount
        filledAmounts[buyOrderHash] += filledAmount; //it is safe to add ui112 to each other to get i192
        filledAmounts[sellOrderHash] += filledAmount;
        require(filledAmounts[buyOrderHash] <= buyOrder.amount, "E12B");
        require(filledAmounts[sellOrderHash] <= sellOrder.amount, "E12S");


        // Update User's balances
        UpdateOrderBalanceData memory data;
        (data.buyType, data.buyIn) = LibExchange.updateOrderBalanceDebit(
            buyOrder,
            filledAmount,
            amountQuote,
            kBuy | kCorrectMatcherFeeByOrderAmount,
            assetBalances,
            liabilities
        );
        (data.sellType, data.sellIn) = LibExchange.updateOrderBalanceDebit(
            sellOrder,
            filledAmount,
            amountQuote,
            kSell | kCorrectMatcherFeeByOrderAmount,
            assetBalances,
            liabilities
        );

        LibExchange.creditUserAssets(data.buyType, buyOrder.senderAddress, data.buyIn, buyOrder.baseAsset, assetBalances, liabilities);
        LibExchange.creditUserAssets(data.sellType, sellOrder.senderAddress, data.sellIn, sellOrder.quoteAsset, assetBalances, liabilities);

        require(checkPosition(buyOrder.senderAddress), "E1PB");
        require(checkPosition(sellOrder.senderAddress), "E1PS");

        emit NewTrade(
            buyOrder.senderAddress,
            sellOrder.senderAddress,
            buyOrder.baseAsset,
            buyOrder.quoteAsset,
            filledPrice,
            filledAmount,
            amountQuote
        );
    }

    /**
     * @dev wrapper for LibValidator methods, may be deleted.
     */
    function validateOrder(LibValidator.Order memory order)
        public pure returns (bool isValid) {
        isValid = order.isPersonalSign
        ? LibValidator.validatePersonal(order)
        : LibValidator.validateV3(order);
    }

    /**
     * @dev check user marginal position (compare assets and liabilities)
     * @return isPositive - boolean whether liabilities are covered by collateral or not
     */
    function checkPosition(address user) public view returns (bool) {
        if (liabilities[user].length == 0) return true;
        return calcPosition(user).state == MarginalFunctionality.PositionState.POSITIVE;
    }

    /**
     * @dev internal methods which collect all variables used by MarginalFunctionality to one structure
     * @param user user address to query
     * @return UsedConstants - MarginalFunctionality.UsedConstants structure
     */
    function getConstants(address user)
        internal view returns (MarginalFunctionality.UsedConstants memory) {
        return
        MarginalFunctionality.UsedConstants(
            user,
            _oracleAddress,
            address(_orionToken),
            positionOverdue,
            priceOverdue,
            stakeRisk,
            liquidationPremium
        );
    }

    /**
     * @dev calc user marginal position (compare assets and liabilities)
     * @param user user address to query
     * @return position - MarginalFunctionality.Position structure
     */
    function calcPosition(address user)
        public view returns (MarginalFunctionality.Position memory) {
        MarginalFunctionality.UsedConstants memory constants = getConstants(
            user
        );

        return MarginalFunctionality.calcPosition(
            collateralAssets,
            liabilities,
            assetBalances,
            assetRisks,
            constants
        );
    }

    /**
     * @dev method to cover some of overdue broker liabilities and get ORN in exchange
            same as liquidation or margin call
     * @param broker - broker which will be liquidated
     * @param redeemedAsset - asset, liability of which will be covered
     * @param amount - amount of covered asset
     */

    function partiallyLiquidate(
        address broker,
        address redeemedAsset,
        uint112 amount
    ) public {
        MarginalFunctionality.UsedConstants memory constants = getConstants(
            broker
        );
        MarginalFunctionality.partiallyLiquidate(
            collateralAssets,
            liabilities,
            assetBalances,
            assetRisks,
            constants,
            redeemedAsset,
            amount
        );
    }

    /**
     *  @dev  revert on fallback function
     */
    fallback() external {
        revert("E6");
    }

    /* Error Codes
        E1: Insufficient Balance, flavor S - stake, L - liabilities, P - Position, B,S - buyer, seller
        E2: Invalid Signature, flavor B,S - buyer, seller
        E3: Invalid Order Info, flavor G - general, M - wrong matcher, M2 unauthorized matcher, As - asset mismatch,
            AmB/AmS - amount mismatch (buyer,seller), PrB/PrS - price mismatch(buyer,seller), D - direction mismatch,
            U - Unit Converter Error, C - caller mismatch
        E4: Order expired, flavor B,S - buyer,seller
        E5: Contract not active,
        E6: Transfer error
        E7: Incorrect state prior to liquidation
        E8: Liquidator doesn't satisfy requirements
        E9: Data for liquidation handling is outdated
        E10: Incorrect state after liquidation
        E11: Amount overflow
        E12: Incorrect filled amount, flavor G,B,S: general(overflow), buyer order overflow, seller order overflow
        E14: Authorization error, sfs - seizeFromStake
        E15: Wrong passed params
        E16: Underlying protection mechanism error, flavor: R, I, O: Reentrancy, Initialization, Ownable
    */
}


// File contracts/interfaces/IPoolFunctionality.sol



interface IPoolFunctionality {

    struct SwapData {
        uint112     amount_spend;
        uint112     amount_receive;
        address     orionpool_router;
        bool        is_exact_spend;
        bool        supportingFee;
        bool        isInContractTrade;
        bool        isSentETHEnough;
        bool        isFromWallet;
        address     asset_spend;
        address[]   path;
    }

    struct InternalSwapData {
        address user;
        uint256 amountIn;
        uint256 amountOut;
        address asset_spend;
        address[] path;
        bool isExactIn;
        address to;
        address curFactory;
        FactoryType curFactoryType;
        bool supportingFee;
    }

    enum FactoryType {
        UNSUPPORTED,
        UNISWAPLIKE,
        CURVE
    }

    function doSwapThroughOrionPool(
        address user,
        address to,
        IPoolFunctionality.SwapData calldata swapData
    ) external returns (uint amountOut, uint amountIn);

    function getWETH() external view returns (address);

    function addLiquidityFromExchange(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function isFactory(address a) external view returns (bool);
}


// File contracts/interfaces/IPoolSwapCallback.sol



interface IPoolSwapCallback {
    function safeAutoTransferFrom(address token, address from, address to, uint value) external;
}


// File contracts/libs/LibPool.sol








library LibPool {

    function updateFilledAmount(
        LibValidator.Order memory order,
        uint112 filledBase,
        mapping(bytes32 => uint192) storage filledAmounts
    ) internal {
        bytes32 orderHash = LibValidator.getTypeValueHash(order);
        uint192 total_amount = filledAmounts[orderHash];
        total_amount += filledBase; //it is safe to add ui112 to each other to get i192
        require(total_amount >= filledBase, "E12B_0");
        require(total_amount <= order.amount, "E12B");
        filledAmounts[orderHash] = total_amount;
    }

    function refundChange(uint amountOut) internal {
        uint actualOutBaseUnit = uint(LibUnitConverter.decimalToBaseUnit(address(0), amountOut));
        if (msg.value > actualOutBaseUnit) {
            SafeTransferHelper.safeTransferTokenOrETH(address(0), msg.sender, msg.value - actualOutBaseUnit);
        }
    }

    function retrieveAssetSpend(address pf, address[] memory path) internal view returns (address) {
        return path.length > 2 ? (IPoolFunctionality(pf).isFactory(path[0]) ? path[1] : path[0]) : path[0];
    }

    function doSwapThroughOrionPool(
        IPoolFunctionality.SwapData memory d,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) public returns(bool) {

        require(d.is_exact_spend || !d.supportingFee, "FNS");

        d.asset_spend = retrieveAssetSpend(d.orionpool_router, d.path);
        d.isInContractTrade = assetBalances[msg.sender][d.asset_spend] > 0 && !d.supportingFee;

        if (msg.value > 0) {
            uint112 eth_sent = uint112(LibUnitConverter.baseUnitToDecimal(address(0), msg.value));
            if (d.asset_spend == address(0) && eth_sent >= d.amount_spend) {
                d.isSentETHEnough = true;
                d.isInContractTrade = false;
            } else {
                LibExchange._updateBalance(msg.sender, address(0), eth_sent, assetBalances, liabilities);
            }
        }

        d.isFromWallet = assetBalances[msg.sender][d.asset_spend] < d.amount_spend;
        if (d.isInContractTrade) {
            LibExchange._updateBalance(msg.sender, d.asset_spend, -1*int(d.amount_spend), assetBalances, liabilities);
            require(assetBalances[msg.sender][d.asset_spend] >= 0, "E1S");
        }

        (uint amountOut, uint amountIn) = IPoolFunctionality(d.orionpool_router).doSwapThroughOrionPool(
            d.isInContractTrade || d.isSentETHEnough ? address(this) : msg.sender,
            d.isInContractTrade ? address(this) : msg.sender,
            d
        );

        if (d.isSentETHEnough) {
            refundChange(amountOut);
        } else if (d.isInContractTrade) {
            if (d.amount_spend > amountOut) { //Refund
                LibExchange._updateBalance(msg.sender, d.asset_spend, int(d.amount_spend) - int(amountOut), assetBalances, liabilities);
            }
            LibExchange.creditUserAssets(d.isFromWallet ? 1 : 0, msg.sender, int(amountIn), d.path[d.path.length-1], assetBalances, liabilities);
            return true;
        }

        return false;
    }

    //  Just to avoid stack too deep error;
    struct OrderExecutionData {
        LibValidator.Order order;
        uint filledAmount;
        uint blockchainFee;
        address[] path;
        address allowedMatcher;
        address orionpoolRouter;
        uint amount_spend;
        uint amount_receive;
        uint amountQuote;
        uint filledBase;
        uint filledQuote;
        uint filledPrice;
        uint amountOut;
        uint amountIn;
        bool isInContractTrade;
        bool isRetainFee;
        bool isFromWallet;
        address to;
        address asset_spend;
    }

    function calcAmounts(
        OrderExecutionData memory d,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) internal {
        d.amountQuote = uint(d.filledAmount) * d.order.price / (10**8);
        (d.amount_spend, d.amount_receive) = d.order.buySide == 0 ? (d.filledAmount, d.amountQuote)
            : (d.amountQuote, d.filledAmount);

        d.asset_spend = retrieveAssetSpend(d.orionpoolRouter, d.path);
        d.isFromWallet = int(assetBalances[d.order.senderAddress][d.asset_spend]) < int(d.amount_spend);
        d.isInContractTrade = d.asset_spend == address(0) || assetBalances[d.order.senderAddress][d.asset_spend] > 0;

        if (d.blockchainFee > d.order.matcherFee)
            d.blockchainFee = d.order.matcherFee;

        if (d.isInContractTrade) {
            LibExchange._updateBalance(d.order.senderAddress, d.asset_spend, -1*int(d.amount_spend), assetBalances, liabilities);
            require(assetBalances[d.order.senderAddress][d.asset_spend] >= 0, "E1S");
        }

        if (d.order.matcherFeeAsset != d.path[d.path.length-1]) {
            _payMatcherFee(d.order, d.blockchainFee, assetBalances, liabilities);
        } else {
            d.isRetainFee = true;
        }

        d.to = (d.isRetainFee || !d.isFromWallet) ? address(this) : d.order.senderAddress;
    }

    function calcAmountInOutAfterSwap(
        OrderExecutionData memory d,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) internal {

        (d.filledBase, d.filledQuote) = d.order.buySide == 0 ? (d.amountOut, d.amountIn) : (d.amountIn, d.amountOut);
        d.filledPrice = d.filledBase > 0 ? d.filledQuote * (10**8) / d.filledBase : 0;

        if (d.order.buySide == 0 && d.filledBase > 0) {
            require(d.filledPrice >= d.order.price, "EX");
        } else {
            require(d.filledPrice <= d.order.price, "EX");
        }

        if (d.isInContractTrade && d.amount_spend > d.amountOut) { //Refund
            LibExchange._updateBalance(d.order.senderAddress, d.asset_spend, int(d.amount_spend) - int(d.amountOut),
                assetBalances, liabilities);
        }

        if (d.isRetainFee) {
            uint actualFee = d.amountIn >= d.blockchainFee ? d.blockchainFee : d.amountIn;
            d.amountIn -= actualFee;
            // Pay to matcher
            LibExchange._updateBalance(d.order.matcherAddress, d.order.matcherFeeAsset, int(actualFee), assetBalances, liabilities);
            if (actualFee < d.blockchainFee) {
                _payMatcherFee(d.order, d.blockchainFee - actualFee, assetBalances, liabilities);
            }
        }

        if (d.to == address(this) && d.amountIn > 0) {
            LibExchange.creditUserAssets(d.isFromWallet ? 1 : 0, d.order.senderAddress, int(d.amountIn),
                d.path[d.path.length-1], assetBalances, liabilities);
        }
    }

    function doFillThroughOrionPool(
        OrderExecutionData memory d,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities,
        mapping(bytes32 => uint192) storage filledAmounts
    ) public {
        calcAmounts(d, assetBalances, liabilities);

        LibValidator.checkOrderSingleMatch(d.order, msg.sender, d.allowedMatcher, uint112(d.filledAmount), block.timestamp,
            d.asset_spend, d.path[d.path.length - 1]);

        IPoolFunctionality.SwapData memory swapData;
        swapData.amount_spend = uint112(d.amount_spend);
        swapData.amount_receive = uint112(d.amount_receive);
        swapData.path = d.path;
        swapData.is_exact_spend = d.order.buySide == 0;
        swapData.supportingFee = false;

        try IPoolFunctionality(d.orionpoolRouter).doSwapThroughOrionPool(
            d.isInContractTrade ? address(this) : d.order.senderAddress,
            d.to,
            swapData
        ) returns(uint amountOut, uint amountIn) {
            d.amountOut = amountOut;
            d.amountIn = amountIn;
        } catch(bytes memory reason) {
            d.amountOut = 0;
            d.amountIn = 0;
        }

        calcAmountInOutAfterSwap(d, assetBalances, liabilities);

        updateFilledAmount(d.order, uint112(d.filledBase), filledAmounts);

        emit LibExchange.NewTrade(
            d.order.senderAddress,
            address(1),
            d.order.baseAsset,
            d.order.quoteAsset,
            uint64(d.filledPrice),
            uint192(d.filledBase),
            uint192(d.filledQuote)
        );
    }

    function _payMatcherFee(
        LibValidator.Order memory order,
        uint blockchainFee,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) internal {
        LibExchange._updateBalance(order.senderAddress, order.matcherFeeAsset, -1*int(blockchainFee), assetBalances, liabilities);
        require(assetBalances[order.senderAddress][order.matcherFeeAsset] >= 0, "E1F");
        LibExchange._updateBalance(order.matcherAddress, order.matcherFeeAsset, int(blockchainFee), assetBalances, liabilities);
    }

    function doWithdrawToPool(
        address assetA,
        address asseBNotETH,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities,
        address _orionpoolRouter
    ) public returns(uint amountA, uint amountB) {
        require(asseBNotETH != address(0), "TokenBIsETH");

        if (msg.value > 0) {
            uint112 eth_sent = uint112(LibUnitConverter.baseUnitToDecimal(address(0), msg.value));
            LibExchange._updateBalance(msg.sender, address(0), eth_sent, assetBalances, liabilities);
        }

        LibExchange._updateBalance(msg.sender, assetA, -1*int256(amountADesired), assetBalances, liabilities);
        require(assetBalances[msg.sender][assetA] >= 0, "E1w1A");

        LibExchange._updateBalance(msg.sender, asseBNotETH, -1*int256(amountBDesired), assetBalances, liabilities);
        require(assetBalances[msg.sender][asseBNotETH] >= 0, "E1w1B");

        (amountA, amountB, ) = IPoolFunctionality(_orionpoolRouter).addLiquidityFromExchange(
            assetA,
            asseBNotETH,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            msg.sender
        );

        // Refund
        if (amountADesired > amountA) {
            LibExchange._updateBalance(msg.sender, assetA, int(amountADesired - amountA), assetBalances, liabilities);
        }

        if (amountBDesired > amountB) {
            LibExchange._updateBalance(msg.sender, asseBNotETH, int(amountBDesired - amountB), assetBalances, liabilities);
        }
    }

}


// File contracts/ExchangeWithOrionPool.sol








contract ExchangeWithOrionPool is Exchange, IPoolSwapCallback {

    using SafeERC20 for IERC20;

    address public _orionpoolRouter;
    mapping (address => bool) orionpoolAllowances;

    address public WETH;

    modifier initialized {
        require(address(_orionToken)!=address(0), "E16I");
        require(_oracleAddress!=address(0), "E16I");
        require(_allowedMatcher!=address(0), "E16I");
        require(_orionpoolRouter!=address(0), "E16I");
        _;
    }

    /**
     * @dev set basic Exchange params
     * @param orionToken - base token address
     * @param priceOracleAddress - adress of PriceOracle contract
     * @param allowedMatcher - address which has authorization to match orders
     * @param orionpoolRouter - OrionPool Functionality contract address for changes through orionpool
     */
    function setBasicParams(
        address orionToken,
        address priceOracleAddress,
        address allowedMatcher,
        address orionpoolRouter
    ) public onlyOwner {
        _orionToken = IERC20(orionToken);
        _oracleAddress = priceOracleAddress;
        _allowedMatcher = allowedMatcher;
        _orionpoolRouter = orionpoolRouter;
        WETH = IPoolFunctionality(_orionpoolRouter).getWETH();
    }

    //Important catch-all a function that should only accept ethereum and don't allow do something with it
    //We accept ETH there only from out router or wrapped ethereum contract.
    //If router sends some ETH to us - it's just swap completed, and we don't need to do something
    receive() external payable {
        require(msg.sender == _orionpoolRouter || msg.sender == WETH, "NPF");
    }

    function safeAutoTransferFrom(address token, address from, address to, uint value) override external {
        require(msg.sender == _orionpoolRouter, "Only _orionpoolRouter allowed");
        SafeTransferHelper.safeAutoTransferFrom(WETH, token, from, to, value);
    }

    /**
     * @notice (partially) settle buy order with OrionPool as counterparty
     * @dev order and orionpool path are submitted, it is necessary to match them:
        check conditions in order for compliance filledPrice and filledAmount
        change tokens via OrionPool
        check that final price after exchange not worse than specified in order
        change balances on the contract respectively
     * @param order structure of buy side orderbuyOrderHash
     * @param filledAmount amount of purchaseable token
     * @param path array of assets addresses (each consequent asset pair is change pair)
     */
    function fillThroughOrionPool(
        LibValidator.Order memory order,
        uint112 filledAmount,
        uint64 blockchainFee,
        address[] calldata path
    ) public nonReentrant {
        LibPool.OrderExecutionData memory d;
        d.order = order;
        d.filledAmount = filledAmount;
        d.blockchainFee = blockchainFee;
        d.path = path;
        d.allowedMatcher = _allowedMatcher;
        d.orionpoolRouter = _orionpoolRouter;

        LibPool.doFillThroughOrionPool(
            d,
            assetBalances,
            liabilities,
            filledAmounts
        );
        require(checkPosition(order.senderAddress), order.buySide == 0 ? "E1PS" : "E1PB");
    }

    function swapThroughOrionPool(
        uint112     amount_spend,
        uint112     amount_receive,
        address[]   calldata path,
        bool        is_exact_spend
    ) public payable nonReentrant {
        bool isCheckPosition = LibPool.doSwapThroughOrionPool(
            IPoolFunctionality.SwapData({
                amount_spend: amount_spend,
                amount_receive: amount_receive,
                is_exact_spend: is_exact_spend,
                supportingFee: false,
                path: path,
                orionpool_router: _orionpoolRouter,
                isInContractTrade: false,
                isSentETHEnough: false,
                isFromWallet: false,
                asset_spend: address(0)
            }),
            assetBalances, liabilities);
        if (isCheckPosition) {
            require(checkPosition(msg.sender), "E1PS");
        }
    }

    function swapThroughOrionPoolSupportingFee(
        uint112     amount_spend,
        uint112     amount_receive,
        address[]   calldata path
    ) public payable nonReentrant {
        bool isCheckPosition = LibPool.doSwapThroughOrionPool(
            IPoolFunctionality.SwapData({
                amount_spend: amount_spend,
                amount_receive: amount_receive,
                is_exact_spend: true,
                supportingFee: true,
                path: path,
                orionpool_router: _orionpoolRouter,
                isInContractTrade: false,
                isSentETHEnough: false,
                isFromWallet: false,
                asset_spend: address(0)
            }),
            assetBalances, liabilities);
        if (isCheckPosition) {
            require(checkPosition(msg.sender), "E1PS");
        }
    }

    /**
     * @notice ZERO_ADDRESS can only be used for asset A - not for asset B
     * @dev adds Liquidity to the Orion Pool from User's deposits
     * @param assetA address of token A or Eth
     * @param asseBNotETH address of token B. Cannot be Eth
     * @param amountADesired The amount of tokenA to add as liquidity if the B/A price is <= amountBDesired/amountADesired (A depreciates).
     * @param amountBDesired The amount of tokenB to add as liquidity if the A/B price is <= amountADesired/amountBDesired (B depreciates).
     * @param amountAMin Bounds the extent to which the B/A price can go up before the transaction reverts. Must be <= amountADesired.
     * @param amountBMin Bounds the extent to which the A/B price can go up before the transaction reverts. Must be <= amountBDesired.
     */
    function withdrawToPool(
        address assetA,
        address asseBNotETH,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) external payable{
        (uint amountA, uint amountB) = LibPool.doWithdrawToPool(assetA, asseBNotETH, amountADesired, amountBDesired,
            amountAMin, amountBMin, assetBalances, liabilities, _orionpoolRouter);

        require(checkPosition(msg.sender), "E1w2");

        emit NewAssetTransaction(
            msg.sender,
            assetA,
            false,
            uint112(amountA),
            uint64(block.timestamp)
        );

        emit NewAssetTransaction(
            msg.sender,
            asseBNotETH,
            false,
            uint112(amountB),
            uint64(block.timestamp)
        );
    }
}


// File contracts/libs/LibAtomic.sol




library LibAtomic {
    using ECDSA for bytes32;

    struct LockOrder {
        address sender;
        uint64 expiration;
        address asset;
        uint64 amount;
        uint24 targetChainId;
        bytes32 secretHash;
    }

    struct LockInfo {
        address sender;
        uint64 expiration;
        bool used;
        address asset;
        uint64 amount;
        uint24 targetChainId;
    }

    struct ClaimOrder {
        address receiver;
        bytes32 secretHash;
    }

    struct RedeemOrder {
        address sender;
        address receiver;
        address claimReceiver;
        address asset;
        uint64 amount;
        uint64 expiration;
        bytes32 secretHash;
        bytes signature;
    }

    function doLockAtomic(LockOrder memory swap,
        mapping(bytes32 => LockInfo) storage atomicSwaps,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) public {
        require(swap.expiration/1000 >= block.timestamp, "E17E");
        require(atomicSwaps[swap.secretHash].sender == address(0), "E17R");

        int remaining = swap.amount;
        if (msg.value > 0) {
            require(swap.asset == address(0), "E17ETH");
            uint112 eth_sent = uint112(LibUnitConverter.baseUnitToDecimal(address(0), msg.value));
            if (eth_sent < swap.amount) {
                remaining = int(swap.amount) - eth_sent;
            } else {
                swap.amount = uint64(eth_sent);
                remaining = 0;
            }
        }

        if (remaining > 0) {
            LibExchange._updateBalance(msg.sender, swap.asset, -1*remaining, assetBalances, liabilities);
            require(assetBalances[msg.sender][swap.asset] >= 0, "E1A");
        }

        atomicSwaps[swap.secretHash] = LockInfo(swap.sender, swap.expiration, false, swap.asset, swap.amount, swap.targetChainId);
    }

    function doRedeemAtomic(
        LibAtomic.RedeemOrder calldata order,
        bytes calldata secret,
        mapping(bytes32 => bool) storage secrets,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) public {
        require(!secrets[order.secretHash], "E17R");
        require(getEthSignedAtomicOrderHash(order).recover(order.signature) == order.sender, "E2");
        require(order.expiration/1000 >= block.timestamp, "E4A");
        require(order.secretHash == keccak256(secret), "E17");

        LibExchange._updateBalance(order.sender, order.asset, -1*int(order.amount), assetBalances, liabilities);

        LibExchange._updateBalance(order.receiver, order.asset, order.amount, assetBalances, liabilities);
        secrets[order.secretHash] = true;
    }

    function doClaimAtomic(
        address receiver,
        bytes calldata secret,
        bytes calldata matcherSignature,
        address allowedMatcher,
        mapping(bytes32 => LockInfo) storage atomicSwaps,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) public returns (LockInfo storage swap) {
        bytes32 secretHash = keccak256(secret);
        bytes32 coHash = getEthSignedClaimOrderHash(ClaimOrder(receiver, secretHash));
        require(coHash.recover(matcherSignature) == allowedMatcher, "E2");

        swap = atomicSwaps[secretHash];
        require(swap.sender != address(0), "E17NF");
        //  require(swap.expiration/1000 >= block.timestamp, "E17E");
        require(!swap.used, "E17U");

        swap.used = true;
        LibExchange._updateBalance(receiver, swap.asset, swap.amount, assetBalances, liabilities);
    }

    function doRefundAtomic(
        bytes32 secretHash,
        mapping(bytes32 => LockInfo) storage atomicSwaps,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) public returns(LockInfo storage swap) {
        swap = atomicSwaps[secretHash];
        require(swap.sender != address(0x0), "E17NF");
        require(swap.expiration/1000 < block.timestamp, "E17NE");
        require(!swap.used, "E17U");

        swap.used = true;
        LibExchange._updateBalance(swap.sender, swap.asset, int(swap.amount), assetBalances, liabilities);
    }

    function getEthSignedAtomicOrderHash(RedeemOrder calldata _order) internal view returns (bytes32) {
        uint256 chId;
        assembly {
            chId := chainid()
        }
        return keccak256(
            abi.encodePacked(
                "atomicOrder",
                chId,
                _order.sender,
                _order.receiver,
                _order.claimReceiver,
                _order.asset,
                _order.amount,
                _order.expiration,
                _order.secretHash
            )
        ).toEthSignedMessageHash();
    }

    function getEthSignedClaimOrderHash(ClaimOrder memory _order) internal pure returns (bytes32) {
        uint256 chId;
        assembly {
            chId := chainid()
        }
        return keccak256(
            abi.encodePacked(
                "claimOrder",
                chId,
                _order.receiver,
                _order.secretHash
            )
        ).toEthSignedMessageHash();
    }
}


// File contracts/ExchangeWithAtomic.sol

contract ExchangeWithAtomic is ExchangeWithOrionPool {
    mapping(bytes32 => LibAtomic.LockInfo) public atomicSwaps;
    mapping(bytes32 => bool) public secrets;

    event AtomicLocked(
        address sender,
        address asset,
        bytes32 secretHash
    );

    event AtomicRedeemed(
        address sender,
        address receiver,
        address asset,
        bytes secret
    );

    event AtomicClaimed(
        address receiver,
        address asset,
        bytes secret
    );

    event AtomicRefunded(
        address receiver,
        address asset,
        bytes32 secretHash
    );

    function lockAtomic(LibAtomic.LockOrder memory swap) payable public {
        LibAtomic.doLockAtomic(swap, atomicSwaps, assetBalances, liabilities);

        require(checkPosition(msg.sender), "E1PA");

        emit AtomicLocked(swap.sender, swap.asset, swap.secretHash);
    }

    function redeemAtomic(LibAtomic.RedeemOrder calldata order, bytes calldata secret) public {
        LibAtomic.doRedeemAtomic(order, secret, secrets, assetBalances, liabilities);
        require(checkPosition(order.sender), "E1PA");

        emit AtomicRedeemed(order.sender, order.receiver, order.asset, secret);
    }

    function redeem2Atomics(LibAtomic.RedeemOrder calldata order1, bytes calldata secret1, LibAtomic.RedeemOrder calldata order2, bytes calldata secret2) public {
        redeemAtomic(order1, secret1);
        redeemAtomic(order2, secret2);
    }

    function claimAtomic(address receiver, bytes calldata secret, bytes calldata matcherSignature) public {
        LibAtomic.LockInfo storage swap = LibAtomic.doClaimAtomic(
                receiver,
                secret,
                matcherSignature,
                _allowedMatcher,
                atomicSwaps,
                assetBalances,
                liabilities
        );

        emit AtomicClaimed(receiver, swap.asset, secret);
    }

    function refundAtomic(bytes32 secretHash) public {
        LibAtomic.LockInfo storage swap = LibAtomic.doRefundAtomic(secretHash, atomicSwaps, assetBalances, liabilities);

        emit AtomicRefunded(swap.sender, swap.asset, secretHash);
    }

    /* Error Codes
        E1: Insufficient Balance, flavor A - Atomic, PA - Position Atomic
        E17: Incorrect atomic secret, flavor: U - used, NF - not found, R - redeemed, E/NE - expired/not expired, ETH
   */
}