// Contracts/RaidRewardsV2.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

interface IRaidersNFT {
    function getFaction(uint256 _raiderID) external view returns (uint256);

    function getClass(uint256 _raiderID) external view returns (uint256);

    function isOwner(address _owner, uint256 _raiderID)
        external
        view
        returns (bool);

    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);
}

interface GameContract {
	function raiderRaidCountNotRewarded(uint256) external view returns (uint256);
	function raiderRaidCountRewarded(uint256) external view returns (uint256);
	function factionRaidCount(uint256) external view returns (uint256);
	function factionGold(uint256) external view returns (uint256);
	function addressRewardedRaidsBasic(address) external view returns (uint256);
	function addressRaidsPerFaction(address, uint256) external view returns (uint256);
	function raiderRewards() external view returns (uint256);
	function winningsPool(uint256) external view returns (uint256);
	function goldPool() external view returns (uint256); //returns a NON-ETHER number
	function gameGoldPool() external view returns (uint256);
	function timeGameEnded() external view returns (uint256);
	function getFreeRewards() external view returns (uint256);
}

interface FactionRanking {
	function getRankings(uint256 _gameRound, uint256 faction) external view returns(uint256);
}

contract RaidRewardsV2 is Ownable, ReentrancyGuard {
    ERC20Burnable public raidToken;
	IRaidersNFT public raidersNFT;
	FactionRanking public factionRanking;
	
	address public tokenAddress = 0x70f52878ca86c5f03d603CDDA414295EE410E8f3;
	address public nftAddress = 0x65c4f2619BFE75215459d7e1f351833E7511290C;

	// FOR LOCAL TESTS >>>
	// address public tokenAddress;
	// address public nftAddress;
	// <<< FOR LOCAL TESTS

	address public rankingAddress;
	mapping(uint256 => address) public gameAddress;
	mapping(uint256 => uint256) public roundTokenBalance;

    mapping(uint256 => mapping(uint256 => uint256)) public raiderClaimedRewards; //round => raiderid => rewards claimed
	mapping(uint256 => mapping(address => uint256)) public addressClaimedRewards; //round => address => rewards claimed
	uint256 public claimID;
	uint256 public claimStatus;
	mapping(address => uint256) public lock; //to prevent re-entrancy issues

	event ClaimedByPlayerAddress(uint256 claimID, address indexed playerAddress, uint256 amount);
	event ClaimedByRaider(uint256 claimID, uint256 raiderID, uint256 amount);

	constructor() {
		raidToken = ERC20Burnable(tokenAddress);
		raidersNFT = IRaidersNFT(nftAddress);
	}

	// FOR LOCAL TESTS >>>
	// constructor(address _nftAddress, address _tokenAddress) {
	// 		raidToken = ERC20Burnable(_tokenAddress);
	// 		raidersNFT = IRaidersNFT(_nftAddress);
	// }
	// <<< FOR LOCAL TESTS

	function fundGameRoundRewards (uint256 _gameRound, uint256 _amount) public onlyOwner {
		raidToken.transferFrom(msg.sender, address(this), _amount);
		roundTokenBalance[_gameRound] += _amount;
	}

	function setClaimingStatus(uint256 _state) public onlyOwner {
		claimStatus = _state;
	}

	function setRankingAddress(address _rankingAddress) public onlyOwner {
		rankingAddress = _rankingAddress;
		factionRanking = FactionRanking(_rankingAddress);
	}

	function setGameAddress(uint256 _gameRound, address _address) public onlyOwner {
		gameAddress[_gameRound] = _address;
	}

	function claimUsingPlayerAddress(uint256 _gameRound) public returns (uint256){
		require(claimStatus == 1, "Claiming rewards is paused.");
		GameContract gameRound;
		gameRound = GameContract(gameAddress[_gameRound]);
		require(block.timestamp > gameRound.timeGameEnded(), "RaidersNFT: The game is still on-going.");
		uint256 grossRewards = getAddressClaimableRewards(_gameRound, msg.sender);
		uint256 netClaimableRewards = grossRewards - addressClaimedRewards[_gameRound][msg.sender];
		require(netClaimableRewards > 0, "RaidersNFT: No rewards to claim.");
		require(netClaimableRewards <= roundTokenBalance[_gameRound], "RaidersNFT: Not enough tokens available for this round.");
		claimID += 1;
		addressClaimedRewards[_gameRound][msg.sender] += netClaimableRewards;
		roundTokenBalance[_gameRound] -= netClaimableRewards;
		raidToken.transfer(msg.sender, netClaimableRewards);
		emit ClaimedByPlayerAddress(claimID, msg.sender, netClaimableRewards);
		return netClaimableRewards;
	}	

	//GETTERS BASED ON PLAYER ADDRESS

	function getAddressRewardsBalance(uint256 _gameRound, address _playerAddress) public view returns (uint256) {
		uint256 grossRewards = getAddressClaimableRewards(_gameRound, _playerAddress);
		uint256 netClaimableRewards = grossRewards - addressClaimedRewards[_gameRound][msg.sender];
		return netClaimableRewards;
	}

	function getAddressClaimableRewards(uint256 _gameRound, address _playerAddress) public view returns (uint256) {
		uint256 basicRewards = getAddressBasicRewards(_gameRound, _playerAddress);
		uint256 winnings = getWinnings(_gameRound, _playerAddress);
		uint256 gold = getGoldShare(_gameRound, _playerAddress);
		uint256 totalRewards = basicRewards + winnings + gold;
		uint256 claimableRewards = totalRewards - addressClaimedRewards[_gameRound][_playerAddress];
		return claimableRewards;
	}

	function getAddressBasicRewards(uint256 _gameRound, address _playerAddress) public view returns (uint256) {
		GameContract gameRound;
		gameRound = GameContract(gameAddress[_gameRound]);
		uint256 basicRaidsRewarded = gameRound.addressRewardedRaidsBasic(_playerAddress);
		uint256 basicRewardsRate = gameRound.raiderRewards();
		uint256 totalBasicRewards = basicRaidsRewarded * basicRewardsRate;
		return totalBasicRewards;
	}

	function getWinnings(uint256 _gameRound, address _playerAddress) public view returns (uint256) {
		GameContract gameRound;
		gameRound = GameContract(gameAddress[_gameRound]);
		uint256 deterraWinnings = getFactionWinnings(_gameRound, _playerAddress, 0);
		uint256 ramelanWinnings = getFactionWinnings(_gameRound, _playerAddress, 1);
		uint256 skouroWinnings = getFactionWinnings(_gameRound, _playerAddress, 2);
		uint256 thoriyonWinnings = getFactionWinnings(_gameRound, _playerAddress, 3);
		uint256 totalWinnings = deterraWinnings + ramelanWinnings + skouroWinnings + thoriyonWinnings;
		return totalWinnings;
	}

	function getGoldShare(uint256 _gameRound, address _playerAddress) public view returns (uint256) {
		GameContract gameRound;
		gameRound = GameContract(gameAddress[_gameRound]);
		uint256 deterraGold = getFactionGoldShare(_gameRound, _playerAddress, 0);
		uint256 ramelanGold = getFactionGoldShare(_gameRound, _playerAddress, 1);
		uint256 skouroGold = getFactionGoldShare(_gameRound, _playerAddress, 2);
		uint256 thoriyonGold = getFactionGoldShare(_gameRound, _playerAddress, 3);
		uint256 goldShare = deterraGold + ramelanGold + skouroGold + thoriyonGold;
		return goldShare;
	}

	function getFactionWinnings(uint256 _gameRound, address _playerAddress, uint256 _faction) public view returns (uint256){
		GameContract gameRound;
		gameRound = GameContract(gameAddress[_gameRound]);

		uint256 factionRank = factionRanking.getRankings(_gameRound, _faction);
		uint256 winningsPoolSlot = getWinningsPoolSlot(factionRank);
		uint256 addressRaidCount = gameRound.addressRaidsPerFaction(_playerAddress, _faction);
		uint256 factionRaidCount = gameRound.factionRaidCount(_faction);
		uint256 winningsForFaction = gameRound.winningsPool(winningsPoolSlot) + freeRewardsBonus(_gameRound, factionRank);
		uint256 winningsShare = (addressRaidCount * winningsForFaction) / factionRaidCount;
		return winningsShare;
	}

	function getFactionGoldShare(uint256 _gameRound, address _playerAddress, uint256 _faction) public view returns (uint256){
		GameContract gameRound;
		gameRound = GameContract(gameAddress[_gameRound]);
		uint256 factionGoldSupply = (gameRound.factionGold(_faction) * gameRound.goldPool()) / gameRound.gameGoldPool();
		uint256 addressRaidCount = gameRound.addressRaidsPerFaction(_playerAddress, _faction);
		uint256 factionRaidCount = gameRound.factionRaidCount(_faction);
		uint256 goldShare = ((addressRaidCount * factionGoldSupply) / factionRaidCount) * 1 ether;
		return goldShare;
	}

	//CLAIMING BASED ON RAIDERS (WILL BE DEPRECATED IN GAME V005)
	function claimUsingRaiders(uint256 _gameRound, uint256[] calldata _raiderIDs) public nonReentrant {
		require(lock[msg.sender] == 0, "RaidersNFT: There is a pending transaction from this address.");
		lock[msg.sender] = 1;
		GameContract gameRound;
		gameRound = GameContract(gameAddress[_gameRound]);
		require(block.timestamp > gameRound.timeGameEnded(), "RaidersNFT: The game is still on-going.");
		
        for (uint256 i = 0; i < _raiderIDs.length; i++) {
            raiderClaim(_gameRound, _raiderIDs[i]);
        }
		lock[msg.sender] = 0;
	}

	function claimUsingRaidersByIndex(uint256 _gameRound, uint256 _index, uint256 _raiderUnits) public nonReentrant {
		require(lock[msg.sender] == 0, "RaidersNFT: There is a pending transaction from this address.");
		lock[msg.sender] = 1;
		GameContract gameRound;
		gameRound = GameContract(gameAddress[_gameRound]);
		require(block.timestamp > gameRound.timeGameEnded(), "RaidersNFT: The game is still on-going.");
		uint256 ownedTokens = raidersNFT.balanceOf(msg.sender);
		uint256 trueIndex = _index - 1;
		uint256 upperLimit = trueIndex + _raiderUnits;
		require(trueIndex < ownedTokens, "RaidersNFT: The chosen index is out-of-bounds of the number of Raiders owned.");
		if(upperLimit > ownedTokens){
			upperLimit = ownedTokens;
		}
		for (uint256 i = trueIndex; i < upperLimit; i++) {
            uint256 tokenID = raidersNFT.tokenOfOwnerByIndex(msg.sender, i);
            raiderClaim(_gameRound, tokenID);
        }
		lock[msg.sender] = 0;
	}

	function raiderClaim(uint256 _gameRound, uint256 _raiderID) internal returns (uint256 netClaimable){
		require(claimStatus == 1, "Claiming rewards is paused.");
		require(raidersNFT.isOwner(msg.sender, _raiderID), "RaidersNFT: This raider is owned by someone else.");
		uint256 basicRewards = getRaiderBasicRewards(_gameRound, _raiderID);
		uint256 winnings = getRaiderWinnings(_gameRound, _raiderID);
		uint256 gold = getRaiderGold(_gameRound, _raiderID);
		uint256 grossClaimable = basicRewards + winnings + gold;
		netClaimable = grossClaimable - raiderClaimedRewards[_gameRound][_raiderID];
		if(netClaimable > 0){
			raiderClaimedRewards[_gameRound][_raiderID] += netClaimable;
			require(netClaimable <= roundTokenBalance[_gameRound], "RaidersNFT: Not enough tokens available for this round.");
			roundTokenBalance[_gameRound] -= netClaimable;
			claimID += 1;
			raidToken.transfer(msg.sender, netClaimable);
			emit ClaimedByRaider(claimID, _raiderID, netClaimable);
		}
	}

	function getRaiderBasicRewards(uint256 _gameRound, uint256 _raiderID) public view returns (uint256) {
		GameContract gameRound;
		gameRound = GameContract(gameAddress[_gameRound]);
		uint256 basicRaidsRewarded = gameRound.raiderRaidCountRewarded(_raiderID);
		uint256 basicRewardsRate = gameRound.raiderRewards();
		uint256 totalBasicRewards = basicRaidsRewarded * basicRewardsRate;
		return totalBasicRewards;
	}

	function getRaiderWinnings(uint256 _gameRound, uint256 _raiderID) public view returns (uint256){
		GameContract gameRound;
		gameRound = GameContract(gameAddress[_gameRound]);
		uint256 raiderFaction = raidersNFT.getFaction(_raiderID);
		uint256 factionRank = factionRanking.getRankings(_gameRound, raiderFaction);
		uint256 winningsPoolSlot = getWinningsPoolSlot(factionRank);
		uint256 raiderRaidCount = gameRound.raiderRaidCountRewarded(_raiderID) + gameRound.raiderRaidCountNotRewarded(_raiderID);
		uint256 factionRaidCount = gameRound.factionRaidCount(raiderFaction);
		uint256 winningsForFaction = gameRound.winningsPool(winningsPoolSlot) + freeRewardsBonus(_gameRound, factionRank);
		uint256 winningsShare = (raiderRaidCount * winningsForFaction) / factionRaidCount;
		return winningsShare;
	}

	function getRaiderGold(uint256 _gameRound, uint256 _raiderID) public view returns (uint256){
		GameContract gameRound;
		gameRound = GameContract(gameAddress[_gameRound]);
		uint256 raiderFaction = raidersNFT.getFaction(_raiderID);
		uint256 factionGoldSupply = (gameRound.factionGold(raiderFaction) * gameRound.goldPool()) / 320000;
		uint256 raiderRaidCount = gameRound.raiderRaidCountRewarded(_raiderID) + gameRound.raiderRaidCountNotRewarded(_raiderID);
		uint256 factionRaidCount = gameRound.factionRaidCount(raiderFaction);
		uint256 goldShare = ((raiderRaidCount * factionGoldSupply) / factionRaidCount) * 1 ether;
		return goldShare;
	}

	function getFactionRank(uint256 _gameRound, uint256 _faction) public view returns (uint256) {
		uint256 factionRank = factionRanking.getRankings(_gameRound, _faction);
		return factionRank;
	}

	function getWinningsPoolSlot(uint256 _rank) internal pure returns (uint256){
		if(_rank == 1){
			return 0;
		}else if(_rank == 2){
			return 1;
		}else if (_rank == 3){
			return 2;
		}else if (_rank ==4){
			return 3;
		}else{
			return 404;
		}
	}

	function getWinningsPoolOfFaction(uint256 _gameRound, uint256 _faction) public view returns (uint256){
		GameContract gameRound;
		gameRound = GameContract(gameAddress[_gameRound]);
		uint256 factionRank = getFactionRank(_gameRound, _faction);
		uint256 winningsSlot = getWinningsPoolSlot(factionRank);
		uint256 winnings = gameRound.winningsPool(winningsSlot);
		uint256 bonus = freeRewardsBonus(_gameRound, factionRank);
		uint256 totalWinnings = winnings + bonus;
		return totalWinnings;
	}

	function freeRewardsBonus(uint256 _gameRound, uint256 _factionRank) public view returns (uint256){
		GameContract gameRound;
		gameRound = GameContract(gameAddress[_gameRound]);
		uint256 bonus;
		if(_factionRank == 1){
			bonus = (gameRound.getFreeRewards() * 46) / 100;
		}else if(_factionRank == 2){
			bonus = (gameRound.getFreeRewards() * 31) / 100;
		}else if(_factionRank == 3){
			bonus = (gameRound.getFreeRewards() * 15) / 100;
		}else if(_factionRank == 4){
			bonus = (gameRound.getFreeRewards() * 8) / 100;
		}
		return bonus;
	}

	function safeWithdrawal(uint256 _gameRound) public onlyOwner { //In-case there is an unforeseen bug in the contract, withdraw the funds and create a new contract iteration with fix/es.
		raidToken.transfer(msg.sender, roundTokenBalance[_gameRound]);
		roundTokenBalance[_gameRound] = 0;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}