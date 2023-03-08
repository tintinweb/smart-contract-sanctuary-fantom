// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IGatherGambit.sol";
import "./IBerries.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// ========================================
//
//     Enter, stranger, but take heed
//     Of what awaits the sin of greed,
//     For those who take, but do not earn,
//     Must pay most dearly in their turn.
//
// ========================================

/**
 * @title Berry Lands
 * @notice A part of Gather Gambit on-chain risk protocol,
 * @notice In Berry Lands, you collect $BERRIES!
 * @dev A contract for staking your Gather Gambit NFTs.
 */
contract BerryLands {
    // ========================================
    //     EVENT & ERROR DEFINITIONS
    // ========================================

    event StakedInBerryLands(
        uint256 indexed tokenId,
        address indexed owner,
        Location indexed location
    );
    event UnstakedFromBerryLands(
        uint256 indexed tokenId,
        address indexed owner,
        Location indexed location
    );
    event ProtectorAdded(
        uint256 indexed tokenId,
        uint256 indexed gathererId,
        address indexed owner,
        Location location
    );
    event ProtectorRemoved(
        uint256 indexed tokenId,
        uint256 indexed gathererId,
        address indexed owner,
        Location location
    );
    event AttackInitiated(
        uint256 indexed attackerId,
        address indexed owner,
        Location indexed location
    );
    event AttackResolved(
        uint256 indexed attackerId,
        address indexed owner,
        Location indexed location,
        uint256 stolenAmount,
        uint256 lootedGathererId,
        bool wasProtected,
        bool gathererKilled,
        bool wolfKilled
    );

    error NoPermission();
    error InvalidLocation();
    error NotAGatherer();
    error NotAProtector();
    error NotAWolf();
    error NotStaked();
    error AttackNotResolved();
    error NoTargets();

    // ========================================
    //     VARIABLE DEFINITIONS
    // ========================================

    enum Location {
        FertileFields,
        WhisperingWoods
    }

    struct StakedAsset {
        uint128 protectorId; // The token ID of the protector (0 if no protector)
        uint128 indexInGathArray; // The index of the token in the gatherers array
        uint64 initBlock; // The block at which was this token staked
        address owner; // The owner of the token
        uint256 claimableBerries; // The amount of berries that can be claimed
    }

    struct Attack {
        uint128 attackerId; // The token ID of the attacking wolf
        uint64 epochIndex; // The epoch index at which the attack was initiated
        uint8 location; // The location of the attack
        address owner; // The owner of the attacking wolf
    }

    IGatherGambit private _gambit;
    IBerries private _berries;
    uint128 private _stakedProtectors;
    uint16 private constant _denominator = 10000;

    uint128[] private _gatherersInFertileFields;
    uint128[] private _gatherersInWhisperingWoods;

    mapping(uint256 => StakedAsset) private _stakedInFertileFields;
    mapping(uint256 => StakedAsset) private _stakedInWhisperingWoods;
    mapping(uint256 => bool) private _isStakedProtector;
    mapping(uint256 => Attack) private _attacks;

    // ========================================
    //    CONSTRUCTOR AND CORE FUNCTIONS
    // ========================================

    constructor(address _gambitAddress, address _berriesAddress) {
        _gambit = IGatherGambit(_gambitAddress);
        _berries = IBerries(_berriesAddress);
    }

    /**
     * @notice Stakes a token in the Fertile Fields.
     * @param _tokenId The token ID to stake.
     */
    function enterBerryLands(uint256 _tokenId, Location _location) external {
        if (_gambit.getEntity(_tokenId) != IGatherGambit.Entity.Gatherer)
            revert NotAGatherer();

        if (_location == Location.FertileFields) {
            if (_stakedInFertileFields[_tokenId].owner != address(0))
                revert NoPermission();

            _gambit.transferFrom(msg.sender, address(this), _tokenId);

            uint256 newIndex = _gatherersInFertileFields.length;
            _gatherersInFertileFields.push(uint128(_tokenId));

            _stakedInFertileFields[_tokenId] = StakedAsset({
                protectorId: 0,
                indexInGathArray: uint128(newIndex),
                initBlock: uint64(block.number),
                owner: msg.sender,
                claimableBerries: 0
            });
        } else if (_location == Location.WhisperingWoods) {
            if (_stakedInWhisperingWoods[_tokenId].owner != address(0))
                revert NoPermission();

            uint256 newIndex = _gatherersInWhisperingWoods.length;
            _gatherersInWhisperingWoods.push(uint128(_tokenId));

            _gambit.transferFrom(msg.sender, address(this), _tokenId);
            _stakedInWhisperingWoods[_tokenId] = StakedAsset({
                protectorId: 0,
                indexInGathArray: uint128(newIndex),
                initBlock: uint64(block.number),
                owner: msg.sender,
                claimableBerries: 0
            });
        } else {
            revert InvalidLocation();
        }

        emit StakedInBerryLands(_tokenId, msg.sender, _location);
    }

    /**
     * @notice Unstakes a token from Berry Lands and claims $BERRIES.
     * @notice This also removes the protector if there is one.
     * @param _tokenId The token ID to unstake.
     * @param _location The location of where the token is staked.
     */
    function exitBerryLands(uint256 _tokenId, Location _location) external {
        if (_location == Location.FertileFields) {
            StakedAsset storage stakedAsset = _stakedInFertileFields[_tokenId];
            if (stakedAsset.owner != msg.sender) revert NoPermission();

            uint256 claimableBerries = getClaimableBerries(_tokenId, _location);

            // override the old position with the last element of the array, and then pop the last element
            // this clears the storage and saves gas
            uint256 index = stakedAsset.indexInGathArray;
            uint128 lastIndexValue = _gatherersInFertileFields[
                _gatherersInFertileFields.length - 1
            ];
            _gatherersInFertileFields[index] = lastIndexValue;
            _stakedInFertileFields[lastIndexValue].indexInGathArray = uint128(
                index
            );
            _gatherersInFertileFields.pop();

            uint128 protectorId = stakedAsset.protectorId;
            delete _stakedInFertileFields[_tokenId];
            _stakedInFertileFields[_tokenId] = stakedAsset;

            if (protectorId != 0) {
                _isStakedProtector[protectorId] = false;
                _stakedProtectors--;
                _gambit.transferFrom(address(this), msg.sender, protectorId);
                emit ProtectorRemoved(
                    protectorId,
                    _tokenId,
                    msg.sender,
                    _location
                );
            }

            _berries.mint(msg.sender, claimableBerries);
            _gambit.transferFrom(address(this), msg.sender, _tokenId);
        } else if (_location == Location.WhisperingWoods) {
            StakedAsset storage stakedAsset = _stakedInWhisperingWoods[
                _tokenId
            ];
            if (stakedAsset.owner != msg.sender) revert NoPermission();

            uint256 claimableBerries = getClaimableBerries(_tokenId, _location);

            // override the old position with the last element of the array, and then pop the last element
            // this clears the storage and saves gas
            uint256 index = stakedAsset.indexInGathArray;
            uint128 lastIndexValue = _gatherersInWhisperingWoods[
                _gatherersInWhisperingWoods.length - 1
            ];
            _gatherersInWhisperingWoods[index] = lastIndexValue;
            _stakedInWhisperingWoods[lastIndexValue].indexInGathArray = uint128(
                index
            );
            _gatherersInWhisperingWoods.pop();

            uint128 protectorId = stakedAsset.protectorId;
            delete _stakedInWhisperingWoods[_tokenId];
            _stakedInWhisperingWoods[_tokenId] = stakedAsset;

            if (protectorId != 0) {
                _isStakedProtector[protectorId] = false;
                _stakedProtectors--;
                _gambit.transferFrom(address(this), msg.sender, protectorId);
                emit ProtectorRemoved(
                    protectorId,
                    _tokenId,
                    msg.sender,
                    _location
                );
            }

            _berries.mint(msg.sender, claimableBerries);
            _gambit.transferFrom(address(this), msg.sender, _tokenId);
        } else {
            revert InvalidLocation();
        }

        emit UnstakedFromBerryLands(_tokenId, msg.sender, _location);
    }

    /**
     * @notice Adds a protector to a staked token.
     * @param _tokenId The token ID of the protector.
     * @param _gathererId The token ID of the gatherer.
     * @param _location The location of where the gatherer is staked.
     */
    function addProtector(
        uint256 _tokenId,
        uint256 _gathererId,
        Location _location
    ) external {
        if (_gambit.getEntity(_tokenId) != IGatherGambit.Entity.Protector)
            revert NotAProtector();

        if (_location == Location.FertileFields) {
            StakedAsset memory stakedAsset = _stakedInFertileFields[
                _gathererId
            ];
            if (stakedAsset.owner != msg.sender) revert NoPermission();

            _gambit.transferFrom(msg.sender, address(this), _tokenId);

            _isStakedProtector[_tokenId] = true;
            stakedAsset.protectorId = uint128(_tokenId);
            _stakedInFertileFields[_gathererId] = stakedAsset;
        } else if (_location == Location.WhisperingWoods) {
            StakedAsset memory stakedAsset = _stakedInWhisperingWoods[
                _gathererId
            ];
            if (stakedAsset.owner != msg.sender) revert NoPermission();

            _gambit.transferFrom(msg.sender, address(this), _tokenId);

            _isStakedProtector[_tokenId] = true;
            stakedAsset.protectorId = uint128(_tokenId);
            _stakedInWhisperingWoods[_gathererId] = stakedAsset;
        } else {
            revert InvalidLocation();
        }

        _stakedProtectors++;
        emit ProtectorAdded(_tokenId, _gathererId, msg.sender, _location);
    }

    /**
     * @notice Removes a protector from a staked token.
     * @param _gathererId The token ID of the gatherer.
     * @param _location The location of where the gatherer is staked.
     * @dev make sure to call this with gatherer ID, not protector ID
     */
    function removeProtector(uint256 _gathererId, Location _location) external {
        if (_location == Location.FertileFields) {
            StakedAsset memory stakedAsset = _stakedInFertileFields[
                _gathererId
            ];
            uint128 protectorId = stakedAsset.protectorId;
            if (stakedAsset.owner != msg.sender) revert NoPermission();
            if (!_isStakedProtector[protectorId]) revert NotStaked();

            _isStakedProtector[protectorId] = false;
            delete stakedAsset.protectorId;
            _stakedInFertileFields[_gathererId] = stakedAsset;
            _stakedProtectors--;
            _gambit.transferFrom(address(this), msg.sender, protectorId);
            emit ProtectorRemoved(
                protectorId,
                _gathererId,
                msg.sender,
                _location
            );
        } else if (_location == Location.WhisperingWoods) {
            StakedAsset memory stakedAsset = _stakedInWhisperingWoods[
                _gathererId
            ];
            uint128 protectorId = stakedAsset.protectorId;
            if (stakedAsset.owner != msg.sender) revert NoPermission();
            if (!_isStakedProtector[protectorId]) revert NotStaked();

            _isStakedProtector[protectorId] = false;
            delete stakedAsset.protectorId;
            _stakedInWhisperingWoods[_gathererId] = stakedAsset;
            _stakedProtectors--;
            _gambit.transferFrom(address(this), msg.sender, protectorId);
            emit ProtectorRemoved(
                protectorId,
                _gathererId,
                msg.sender,
                _location
            );
        } else {
            revert InvalidLocation();
        }
    }

    /**
     * @notice Initiates an attack.
     * @notice This locks your wolf until the attack is resolved.
     * @param _tokenId The token ID of the attacking Wolf.
     * @param _location The location of where the attacker is staked.
     */
    function initiateAttack(uint256 _tokenId, Location _location) external {
        if (_gambit.getEntity(_tokenId) != IGatherGambit.Entity.Wolf)
            revert NotAWolf();
        if (_gambit.ownerOf(_tokenId) != msg.sender) revert NoPermission();

        _gambit.resolveEpochIfNecessary();

        uint256 epochIndex = _gambit.getCurrentEpochIndex();

        _gambit.transferFrom(msg.sender, address(this), _tokenId);

        _attacks[_tokenId] = Attack({
            attackerId: uint128(_tokenId),
            epochIndex: uint64(epochIndex),
            location: uint8(_location),
            owner: msg.sender
        });

        emit AttackInitiated(_tokenId, msg.sender, _location);
    }

    /**
     * @notice Resolves an attack.
     * @param _tokenId The token ID of the attacking Wolf.
     */
    function resolveAttack(uint256 _tokenId) external {
        Attack memory attack = _attacks[_tokenId];
        address attacker = attack.owner;
        uint256 stolen;
        bool isProtected;
        bool wolfKilled;
        bool gathererKilled;
        uint256 gathererId;
        if (attacker != msg.sender) revert NoPermission();

        _gambit.resolveEpochIfNecessary();

        IGatherGambit.Epoch memory epoch = _gambit.getEpoch(attack.epochIndex);

        if (!epoch.resolved) revert AttackNotResolved();

        if (Location(attack.location) == Location.FertileFields) {
            if (_gatherersInFertileFields.length == 0) revert NoTargets();

            // get random index from staked gatherers, using randomness from resolved epoch
            uint256 index = uint256(
                keccak256(abi.encodePacked(epoch.randomness))
            ) % _gatherersInFertileFields.length;

            gathererId = _gatherersInFertileFields[index];

            StakedAsset memory stakedAsset = _stakedInFertileFields[
                _gatherersInFertileFields[index]
            ];

            if (stakedAsset.protectorId > 0) isProtected = true;

            // protected - in fertile fields
            if (isProtected) {
                // get total claimable berries
                uint256 claimable = getClaimableBerries(
                    gathererId,
                    Location(attack.location)
                );

                // keep 40% as a reward for wolf
                stolen = (claimable * (4000)) / _denominator;

                // keep 60% for gatherer
                claimable = claimable - stolen;

                // update state
                _stakedInFertileFields[gathererId] = StakedAsset({
                    protectorId: stakedAsset.protectorId,
                    indexInGathArray: stakedAsset.indexInGathArray,
                    initBlock: uint64(block.number),
                    owner: stakedAsset.owner,
                    claimableBerries: claimable
                });
                delete _attacks[_tokenId];
            }
            // not protected - in fertile fields
            else {
                // steal all claimable berries
                stolen = getClaimableBerries(
                    gathererId,
                    Location(attack.location)
                );

                // update state
                _stakedInFertileFields[gathererId] = StakedAsset({
                    protectorId: stakedAsset.protectorId,
                    indexInGathArray: stakedAsset.indexInGathArray,
                    initBlock: uint64(block.number),
                    owner: stakedAsset.owner,
                    claimableBerries: 0
                });
                delete _attacks[_tokenId];
            }
        } else if (attack.location == uint8(Location.WhisperingWoods)) {
            if (_gatherersInWhisperingWoods.length == 0) revert NoTargets();

            // get random index from staked gatherers, using randomness from resolved epoch
            uint256 index = uint256(
                keccak256(abi.encodePacked(epoch.randomness))
            ) % _gatherersInWhisperingWoods.length;

            gathererId = _gatherersInWhisperingWoods[index];

            StakedAsset memory stakedAsset = _stakedInWhisperingWoods[
                gathererId
            ];

            if (stakedAsset.protectorId > 0) isProtected = true;

            // protected - in whispering woods
            if (isProtected) {
                // get total claimable berries
                uint256 claimable = getClaimableBerries(
                    gathererId,
                    Location(attack.location)
                );

                // keep 70% as a reward for wolf
                stolen = (claimable * (7000)) / _denominator;

                // keep 30% for gatherer
                claimable = claimable - stolen;

                // update state
                _stakedInWhisperingWoods[gathererId] = StakedAsset({
                    protectorId: stakedAsset.protectorId,
                    indexInGathArray: stakedAsset.indexInGathArray,
                    initBlock: uint64(block.number),
                    owner: stakedAsset.owner,
                    claimableBerries: claimable
                });
                delete _attacks[_tokenId];

                // 5% chance to kill the wolf
                if (
                    (uint256(keccak256(abi.encodePacked(epoch.randomness))) %
                        100) +
                        1 <
                    5
                ) wolfKilled = true;
            }
            // not protected - in whispering woods
            else {
                // steal all claimable berries
                stolen = getClaimableBerries(
                    gathererId,
                    Location(attack.location)
                );

                // kill gatherer
                gathererKilled = true;
                delete _stakedInWhisperingWoods[gathererId];
                // remove gatherer from array
                uint128 lastIndexValue = _gatherersInWhisperingWoods[
                    _gatherersInWhisperingWoods.length - 1
                ];
                _gatherersInWhisperingWoods[index] = lastIndexValue;
                _stakedInWhisperingWoods[lastIndexValue]
                    .indexInGathArray = uint128(index);
                _gatherersInWhisperingWoods.pop();

                // update state
                delete _attacks[_tokenId];

                //burn gatherer
                _gambit.burn(gathererId);
            }
        } else {
            revert InvalidLocation();
        }

        if (stolen > 0) {
            // mint berries
            _berries.mint(msg.sender, stolen);
        }

        if (wolfKilled) {
            // burn wolf
            _gambit.burn(_tokenId);
        } else {
            // transfer Wolf back to attacker
            _gambit.transferFrom(address(this), attacker, _tokenId);
        }

        emit AttackResolved(
            _tokenId,
            attacker,
            Location(attack.location),
            stolen,
            gathererId,
            isProtected,
            gathererKilled,
            wolfKilled
        );
    }

    // ========================================
    //     GETTER FUNCTIONS
    // ========================================

    function getClaimableBerries(
        uint256 _tokenId,
        Location _location
    ) public view returns (uint256) {
        uint256 claimable;
        if (_location == Location.FertileFields) {
            StakedAsset memory stakedAsset = _stakedInFertileFields[_tokenId];

            uint256 DAILY_FERTILE_FIELDS_RATE = 1000 * (10 ** 18);

            claimable =
                ((block.number - stakedAsset.initBlock) *
                    DAILY_FERTILE_FIELDS_RATE) /
                1 days +
                stakedAsset.claimableBerries;
        } else if (_location == Location.WhisperingWoods) {
            StakedAsset memory stakedAsset = _stakedInWhisperingWoods[_tokenId];
            if (stakedAsset.owner != msg.sender) revert NoPermission();

            uint256 DAILY_WHISPERING_WOODS_RATE = 5000 * (10 ** 18);
            claimable =
                ((block.number - stakedAsset.initBlock) *
                    DAILY_WHISPERING_WOODS_RATE) /
                1 days +
                stakedAsset.claimableBerries;
        }

        return claimable;
    }

    function getStakedGatherer(
        uint256 _tokenId,
        Location _location
    ) external view returns (StakedAsset memory) {
        if (_location == Location.FertileFields) {
            StakedAsset memory stakedAsset = _stakedInFertileFields[_tokenId];
            return stakedAsset;
        } else if (_location == Location.WhisperingWoods) {
            StakedAsset memory stakedAsset = _stakedInWhisperingWoods[_tokenId];
            return stakedAsset;
        } else {
            revert InvalidLocation();
        }
    }

    /**
     * @notice Returns the address of the Gather Gambit contract
     */
    function getGambitContract() external view returns (address) {
        return address(_gambit);
    }

    /**
     * @notice Returns the address of the Berry contract
     */
    function getBerriesContract() external view returns (address) {
        return address(_berries);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBerries is IERC20 {
    event NewEpoch(uint256 indexed epochId, uint256 indexed revealBlock);

    enum Entity {
        Unrevealed,
        Gatherer,
        Protector,
        Wolf
    }

    struct Epoch {
        uint128 randomness; // The source of randomness for tokens from this epoch
        uint64 revealBlock; // The block at which this epoch was / is revealed
        bool committed; // Whether the epoch has been instantiated
        bool revealed; // Whether the epoch has been revealed
    }

    function mint(address _address, uint256 _amount) external;

    function burn(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "erc721a/contracts/IERC721A.sol";

interface IGatherGambit is IERC721A {
    event NewEpoch(uint256 indexed epochId, uint256 indexed revealBlock);

    enum Entity {
        Unrevealed,
        Gatherer,
        Protector,
        Wolf
    }

    struct Epoch {
        uint128 randomness; // The source of randomness for tokens from this epoch
        uint64 revealBlock; // The block at which this epoch was / is revealed
        bool committed; // Whether the epoch has been instantiated
        bool resolved; // Whether the epoch has been resolved
    }

    function mint(address _address) external;

    function burn(uint256 _tokenId) external;

    function burnBatch(uint256[] calldata _tokenIds) external;

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function resolveEpochIfNecessary () external;

    function setReproductionContract(address _stakingContractAddress) external;

    function getReproductionContract() external view returns (address);

    function getCurrentEpochIndex() external view returns (uint256);

    function getEpoch(uint256 _epochId) external view returns (Epoch memory);

    function getEntity(uint256 _tokenId) external view returns (Entity);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

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

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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