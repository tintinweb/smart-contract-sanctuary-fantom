//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

interface GameContract {
    function getTotalFactionPoints(uint256 _faction)
        external
        view
        returns (uint256);
}

contract FactionRankingV2 is Ownable{
    mapping(uint256 => address) public roundToGameContract;

    constructor() {
    }

    function setRoundContract(uint256 _round, address _gameContract) public onlyOwner {
        roundToGameContract[_round] = _gameContract;
    }

    function getScores(uint256 _round)
        public
        view
        returns (uint256[4] memory)
    {
        GameContract game;
        game = GameContract(roundToGameContract[_round]);

        uint256[4] memory factionPoints;
        for (uint256 i = 0; i < 4; i++) {
            factionPoints[i] = game.getTotalFactionPoints(i);
        }
        return factionPoints;
    }

    function getRankings(uint256 _round, uint256 _faction) public view returns(uint256){
        (, uint256[4] memory sortedFactions) = getSortedScoresAndRanks(_round);
        for(uint256 i = 0; i < 4; i++){
            if(sortedFactions[i] == _faction){
                return (i + 1);
            }
        }
    }

    function getSortedScoresAndRanks(uint256 _round) public view returns(uint256[4] memory, uint256[4] memory){
        uint256 factionIndex = 0;
        uint256[4] memory scores = getScores(_round);
        uint256[4] memory factions = [factionIndex, factionIndex + 1, factionIndex + 2, factionIndex +3];
        (uint256[4] memory sortedScores, uint256[4] memory sortedFactions) = sortFactionScores(scores, factions);
        return(sortedScores, sortedFactions);
    }

    function sortFactionScores(uint256[4] memory _scores, uint256[4] memory _factions) public pure returns (uint256[4] memory, uint256[4] memory) {
    uint256 l = _scores.length;
    for(uint i = 0; i < l; i++) {
        for(uint j = i+1; j < l ;j++) {
            if(_scores[i] < _scores[j]) {
                uint256 temp = _scores[i];
                uint256 temp2 = _factions[i];
                _scores[i] = _scores[j];
                _factions[i] = _factions[j];
                _scores[j] = temp;
                _factions[j] = temp2;
            }
        }
    }
    return (_scores, _factions);
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