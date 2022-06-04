// SPDX-License-Identifier: GPL v3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

interface MummyNftInterface {
    function getMummyNFTStats(uint _tokenId) external view returns (uint _chipsAvailable, uint _generatedAt);
    function setMummyAvailableChips(uint _tokenId, uint _availableChips) external;
    function walletOfOwner(address _owner) external view returns (uint256[] memory);
}

/* The Casino contract defines top-level Casino-related transactions that occur
*  within the casino. The main purpose for this contract is to provide a way 
*  for users to claim free utility tokens to use for the casino games, almost
*  like a "chip exchange".
*/
contract Casino is Ownable {

    // State variables
    MummyNftInterface private mummyNftContract;
    // address private deployerAddress;
    address[] private casinoGameAddresses;

    // Modifier to check if the calling address is a CasinoGame contract address
    modifier onlyCasinoGame {
        bool isAddr = false;
        for(uint i = 0; i < casinoGameAddresses.length; i++) {
            if(msg.sender == casinoGameAddresses[i]) {
                isAddr = true;
                break;
            }
        }
        require(isAddr, "Caller must be CasinoGame.");
        _;
    }

    // Sets the address of the Chip utility token contract
    function setMummyContractAddress(address _address) external onlyOwner {
        mummyNftContract = MummyNftInterface(_address);
    }

    // Add address of CasinoGame
    function addCasinoGameContractAddress(address _address) external onlyOwner {
        casinoGameAddresses.push(_address);
    }

    // Pays a certain amount of winnings to the specified address. If the Casino
    // contract does not have enough Chips, more are minted for the Casino.
    function payWinnings(address _to, uint256 _amount, uint256 _tokenId) external onlyCasinoGame {
        uint256[] memory ownerTokens = mummyNftContract.walletOfOwner(_to);
        uint256 ownerTokenCount = ownerTokens.length;
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            if (tokenIds[i] == _tokenId) {
                (uint chipsAvailableBefore, uint generatedAt) = mummyNftContract.getMummyNFTStats(_tokenId);
                mummyNftContract.setMummyAvailableChips(_tokenId, chipsAvailableBefore + _amount);
            }
        }
    }

    // Takes a certain amount from the paying wallet and transfers it to
    // the casino contract.
    function transferFrom(address _from, uint256 _amount, uint256 _tokenId) external onlyCasinoGame {
        uint256[] memory ownerTokens = mummyNftContract.walletOfOwner(_from);
        uint256 ownerTokenCount = ownerTokens.length;
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            (uint chipsAvailableBefore, uint generatedAt) = mummyNftContract.getMummyNFTStats(_tokenId);
            if (tokenIds[i] == _tokenId && chipsAvailableBefore >= _amount) {
                mummyNftContract.setMummyAvailableChips(_tokenId, chipsAvailableBefore - _amount);
            }
        }
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