/**
 *Submitted for verification at FtmScan.com on 2023-05-21
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
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
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: contracts/spank_lotto.sol


pragma solidity ^0.8.18;



interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract SpankLotto is Ownable  {
    IERC20 private _token;
    IERC721Enumerable private _nft;
    uint256 private _p;

    address[] private winners;

    uint256[] private winnersAmt;
    uint256[] private winnersRarity;
    uint256[] private winnersNFT;

    address[] private admins;

    bool private pausepayout = false;

    uint256 private roundId;
    uint256 private balance;
    uint256 private entries;
    uint256 private rarity;
    

    event WinnerPicked(
        address indexed winner,
        uint256 indexed tokensToWinner,
        uint256 indexed nft
    );

    event Log(
        uint256 indexed nft
    );

    constructor(
        address token,
        address nft
        ) {
        _token = IERC20(token);
        _nft = IERC721Enumerable(nft);
        _p = 10000000000000000000;
        roundId = 0;
        admins.push(msg.sender);
        entries = _nft.totalSupply();
    }

    function addAdmin(address a) public onlyOwner () {
        admins.push(a);
    }

    function clearAdmin() public onlyOwner () {
        admins = new address[](0);
        admins.push(msg.sender);
    }


    uint seed = 0;

    function generateRandomNumber(uint _modulus) internal returns(uint){
        seed++;
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender,seed))) % _modulus;
    }

    function randomNumber() internal view returns(uint256){
          return uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp)));
    }

    function st2num(string memory numString) internal pure returns(uint) {    
        uint  val=0;
        bytes   memory stringBytes = bytes(numString);
        for (uint  i =  0; i<stringBytes.length; i++) {
            uint exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
           uint jval = uval - uint(0x30);
   
           val +=  (uint(jval) * (10**(exp-1))); 
        }
      return val;
    }
    
    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory ) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    function drawWinner() public returns (address) {

        bool admin = false;
        for (uint256 x = 0; x < admins.length; x++) {
            if (admins[x] == msg.sender) {
                admin = true;
            }
        }
        if (!admin) {
            if (owner() == msg.sender) {
                admins.push(msg.sender);
                admin = true;
            }
        }
        require(admin, 'Must be admin to draw winner.');

        uint i = (randomNumber() % entries)+1;

        address winner = _nft.ownerOf(i);
        uint256 amount = _p;

        emit WinnerPicked(
            winner,
            amount, i);

        uint256 r = (i*3)-3;
        //check rarity, add bonus - hard coded as rarity is offchain
        string memory s = substring("60,60,60,60,60,00,00,10,00,25,40,10,60,00,10,10,40,10,25,00,00,00,00,00,10,00,25,00,00,00,00,00,10,00,25,10,00,00,10,10,25,40,00,00,10,10,00,25,00,00,00,10,00,10,25,00,25,00,25,10,40,00,00,10,00,00,00,10,25,00,60,10,10,00,00,00,00,00,00,25,00,25,10,40,00,00,00,00,25,00,25,40,10,00,10,25,00,10,10,10,00,00,00,25,10,00,00,00,25,10,10,00,00,00,00,10,10,40,00,00,00,10,10,00,10,10,00,00,10,25,00,10,25,25,25,00,00,10,00,10,25,10,00,00,10,10,00,00,10,10,25,40,25,25,25,25,10,10,00,25,00,25,00,40,00,25,00,60,00,40,10,10,00,25,00,00,25,00,00,10,00,40,00,00,10,10,00,00,10,00,25,00,00,00,10,00,00,10,00,00,00,00,40,00,10,25,00,00,40,25,00,00,00,60,40,10,00,00,40,00,25,00,00,00,00,00,10,40,00,00,10,00,00,00,10,10,00,10,10,00,10,40,40,00,10,00,00,25,40,00,00,10,40,25,00,00,00,00,10,10,00,10,00,00,00,25,25,00,00,00,00,00,10,00,00,00,25,10,00,00,10,40,00,10,10,00,00,00,10,00,00,10,25,00,10,00,00,00,40,00,00,10,00,10,10,25,10,25,00,00,00,00,00,00,00,40,25,00,10,40,00,00,40,25,00,00,40,00,00,25,10,25,00,25,40,10,00,00,00,00,00,00,10,00,10,00,40,25,00,25,00,10,00,00,00,00,00,10,10,00,25,10,00,00,00,00,10,10,25,00,00,40,10,00,00,00,40,10,00,10,00,00,25,00,10,25,10,00,10,10,10,25,00,00,40,00,00,10,00,25,40,10,10,25,00,10,10,00,25,00,00,10,25,25,10,25,10,60,00,25", r, r+2);
        rarity = st2num(s);
        amount = _p +  (_p  * rarity)/100;

        //make sure we have enought funds
        require(balance < amount, 'Insufficient funds to transfer.');
        
        //can pause payout if need to test
        if (!pausepayout) {
            IERC20(_token).transfer(winner, amount); 
        }
       
        winners.push(winner);
        winnersAmt.push(amount);
        winnersRarity.push(rarity);
        winnersNFT.push(i);

        roundId++;

        return winner;
    }
 


    function addFunds(uint256 n) public {
        IERC20(_token).transferFrom(msg.sender, address(this), n);
    }

    function isAdmin(address addy) public view returns (bool) {
        bool admin = false;
        for (uint256 x = 0; x < admins.length; x++) {
            if (admins[x] == addy) {
                admin = true;
            }
        }
        if (!admin) {
            if (owner() == msg.sender) {
                admin = true;
            }
        }

        return admin;
    }

    function withdrawFunds() external onlyOwner {
        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }

    function resetWinnersList() external onlyOwner {
        winners = new address[](0);
        winnersAmt = new uint256[](0);
        winnersRarity = new uint256[](0);
        winnersNFT = new uint256[](0);
        roundId = 1;
    }

    function isPayoutPaused() public view returns (bool) {
        return pausepayout;
    }

    function setPayoutPaused(bool _b) external onlyOwner {
        bool admin = false;
        for (uint256 x = 0; x < admins.length; x++) {
            if (admins[x] == msg.sender) {
                admin = true;
            }
        }
        if (!admin) {
            if (owner() == msg.sender) {
                admins.push(msg.sender);
                admin = true;
            }
        }

        require(admin, 'Must be admin to set prize amount.');        
        pausepayout = _b;
    }

    function setDrawPrize(uint256 n) external  {
        bool admin = false;
        for (uint256 x = 0; x < admins.length; x++) {
            if (admins[x] == msg.sender) {
                admin = true;
            }
        }
        if (!admin) {
            if (owner() == msg.sender) {
                admins.push(msg.sender);
                admin = true;
            }
        }

        require(admin, 'Must be admin to set prize amount.');
        _p = n;
    }

    function getDrawPrize() external view returns (uint256) {
       return _p;
    }

    function getTokenBalance() external view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }  

    function getRoundId() external view returns (uint256) {
        return roundId;
    }

    function getRoundWinner(uint256 _roundId) external view returns (address) {
        return winners[_roundId];
    }
    
    function getRoundWinnerAmount(uint256 _roundId) external view returns (uint256) {
        return winnersAmt[_roundId];
    }

    function getAllRoundWinnerRarity() external view returns (uint256[] memory) {
        return winnersRarity;
    }

    function getAllRoundWinnerNFT() external view returns (uint256[] memory) {
        return winnersNFT;
    }

    function getAllRoundWinner() external view returns (address[] memory) {
        return winners;
    }
    
    function getAllRoundWinnerAmount() external view returns (uint256[] memory) {
        return winnersAmt;
    }    

}