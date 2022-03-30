// Be name Khoda
// Bime Abolfazl
// SPDX-License-Identifier: MIT

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ================== DEUS Partner Manager ================
// ========================================================
// DEUS Finance: https://github.com/deusfinance

// Primary Author(s)
// Vahid: https://github.com/vahid-dev
// M.R.M: https://github.com/mrmousavi78

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPartnerManager.sol";

/// @title Partner Manager
/// @author DEUS Finance
/// @notice Partner manager for the Synchronizer
contract PartnerManager is IPartnerManager, Ownable {
    uint256 public scale = 1e18; // used for math
    address public platformFeeCollector; // platform multisig address
    uint256[] public minPlatformFee; // minimum platform fee set by DEUS DAO
    uint256[] public minTotalFee;  // minimum trading fee (total fee) set by DEUS DAO
    mapping(address => uint256[]) public partnerFee; // partnerId => [stockFee, cryptoFee, forexFee, commodityFee, miscFee, ...]
    mapping(address => bool) public isPartner; // partnership of address
    mapping(address => int256) public maxCap; // maximum cap of open positions volume

    constructor(address owner, address platformFeeCollector_, uint256[] memory minPlatformFee_, uint256[] memory minTotalFee_) {
        platformFeeCollector = platformFeeCollector_;
        minPlatformFee = minPlatformFee_;
        minTotalFee = minTotalFee_;
        transferOwnership(owner);
    }

    /// @notice become a partner of DEUS DAO
    /// @dev fees (18 decimals) are expressed as multipliers, e.g. 1% should be inserted as 0.01
    /// @param registrarType list of registrar types
    /// @param partnerFee_ list of fee amounts of registrars
    function addRegistrarFee(uint256[] memory registrarType, uint256[] memory partnerFee_) external {
        isPartner[msg.sender] = true;
        partnerFee[msg.sender] = new uint256[](registrarType.length);
        for (uint i = 0; i < registrarType.length; i++) {
            require(partnerFee_[registrarType[i]] + minPlatformFee[registrarType[i]] < scale, "PartnerManager: INVALID_TOTAL_FEE");
            partnerFee[msg.sender][registrarType[i]] = partnerFee_[registrarType[i]];
        }

        emit RegistrarFeeAdded(msg.sender, registrarType, partnerFee_);
    }

    /// @notice add new registrars to the platform
    /// @dev fees (18 decimals) are expressed as multipliers, e.g. 1% should be inserted as 0.01
    /// @param registrarType list of registrar types
    /// @param minPlatformFee_ list of minimum platform fee
    /// @param minTotalFee_ list of minimum trading fee
    function addPlatformFee(uint256[] memory registrarType, uint256[] memory minPlatformFee_, uint256[] memory minTotalFee_) external onlyOwner {
        minPlatformFee = new uint256[](registrarType.length);
        minTotalFee = new uint256[](registrarType.length);
        for (uint i = 0; i < registrarType.length; i++) {
            minPlatformFee[registrarType[i]] = minPlatformFee_[registrarType[i]];
            minTotalFee[registrarType[i]] = minTotalFee_[registrarType[i]];
        }

        emit PlatformFeeAdded(registrarType, minPlatformFee_, minTotalFee_);
    }

    /// @notice sets maximum cap for partner
    /// @param partnerId Address of partner
    /// @param cap Maximum cap of partner
    /// @param isNegative Is true when you want to set negative cap
    function setCap(address partnerId, int256 cap, bool isNegative) external onlyOwner {
        if (!isNegative) { require(cap >= 0, "ParnerManager: INVALID_CAP"); }
        maxCap[partnerId] = cap;
        emit SetCap(partnerId, cap);
    }
}

//Dar panah khoda

// SPDX-License-Identifier: MIT

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IPartnerManager {
    event RegistrarFeeAdded(address owner, uint256[] registrarType, uint256[] partnerFee);
    event PlatformFeeAdded(uint256[] registrarType, uint256[] minPlatformFee, uint256[] minTotalFee);
    event SetCap(address partnerId, int256 cap);

    function minPlatformFee(uint256 index) external view returns (uint256);

    function minTotalFee(uint256 index) external view returns (uint256);

    function partnerFee(address partner, uint256 index) external view returns (uint256);

    function platformFeeCollector() external view returns (address);

    function scale() external view returns (uint256);

    function isPartner(address partner) external view returns (bool);

    function maxCap(address partner) external view returns (int256);

    function addRegistrarFee(uint256[] memory registrarType, uint256[] memory partnerFee_) external;

    function addPlatformFee(
        uint256[] memory registrarType,
        uint256[] memory minPlatformFee_,
        uint256[] memory minTotalFee_
    ) external;

    function setCap(address partnerId, int256 cap, bool isNegative) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}