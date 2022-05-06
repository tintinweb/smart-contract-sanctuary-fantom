/**
 *Submitted for verification at FtmScan.com on 2022-05-06
*/

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}


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
    function transferFrom(
        address sender,
        address recipient,
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


pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

interface ERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}


contract WCGameServer is Ownable, ERC721Holder {

    address public Treasury = 0x3f6B955Bc6C879d00cEa84CFDc59c7091EA90720;

    address public server = 0xcE824b1dADaa23F76006315e18f596009De1bA63;

    ERC721 public constant _WC = ERC721(0xC031b7793F17100e9B7Ad369cA05e5ec8A0F5B5C);
    
    uint256 public _matchesCount = 0;
    uint256 public currentPlayers = 0;
    bool public serverStatus = false;
    uint256 public serverFee = 100000000000000000;

    mapping(address => uint256) public currentDuels;
    mapping(uint256 => MatchInfo) public _matchInfo;

    mapping(address => Record) public walletRecord;
    mapping(uint256 => Record) public cardRecord;

    mapping(uint256 => mapping (uint256 => QueueStruct)) public _queue;
    mapping(uint256 => Glossary) public queueGlossary;

    struct Record {
        uint256 wins;
        uint256 losses;
        uint256 elo;
        string name;
        string victoryLine;
    }

    struct QueueStruct {
        uint256[] TokenID;
        address Address;
        uint256 Weapon;
    }

    struct Glossary{
        uint256 price;
        address currency;
        bool enabled;
    }

    struct MatchInfo{
        uint256[] a;
        uint256[] b;
        address addressA;
        address addressB;
        uint256 matchType;
    }

    event QueueUp(address addressAddress, string addressName, uint256 queueType, uint256 matchSize); //Event for queue up
    event DuelStarted(MatchInfo info, string addressAName, string addressBName); //Event for Start of Duel
    event DuelEnded(MatchInfo info, string addressAName, string addressBName, uint8 winner); //Event for End of Duel

    function Queue(uint256[] memory tokenID, uint256 weaponChoice, uint256 queueType) payable public{
        require(serverStatus == true, "Server is under maintenance");
        require(queueGlossary[queueType].enabled == true, "This queueType is not enabled");
        require(tokenID.length <= 3, "Max of 3 WC allowed");
        for (uint i = 0; i < tokenID.length; i++) {
            require(msg.sender == _WC.ownerOf(tokenID[i]), "WC is not yours");
        }
        require(currentDuels[msg.sender] == 0, "Only one duel at a time per address");
        require(weaponChoice == 0 || weaponChoice == 1, "weaponChoice has to be left or right hand (0 or 1)");

        if(queueGlossary[queueType].currency != address(0)){
            bool transferComplete = IERC20(queueGlossary[queueType].currency).transferFrom(msg.sender, address(this), queueGlossary[queueType].price*tokenID.length);
            if(transferComplete == false){
                revert("Something bad happened with the ERC20");
            }
            if(serverFee*tokenID.length != msg.value){
                revert("Incorrect amount sent for this duel type");
            }
        }else{
            if((queueGlossary[queueType].price*tokenID.length)+(serverFee*tokenID.length) != msg.value){
                revert("Incorrect amount sent for this duel type");
            }
        }

        for (uint i = 0; i < tokenID.length; i++) {
            _WC.safeTransferFrom(msg.sender, address(this), tokenID[i]);
        }
        currentPlayers++;

        if(_queue[queueType][tokenID.length].TokenID[0] == 0){
            _queue[queueType][tokenID.length].TokenID = tokenID;
            _queue[queueType][tokenID.length].Address = msg.sender;
            _queue[queueType][tokenID.length].Weapon = weaponChoice;
            currentDuels[msg.sender] = 1;

            //Event
            emit QueueUp(msg.sender, walletRecord[msg.sender].name, queueType, tokenID.length);

        }else{
            uint256[] memory aTokenID = _queue[queueType][tokenID.length].TokenID;
            uint256[] memory bTokenID = tokenID;

            _matchesCount++;
            currentDuels[msg.sender] = _matchesCount + 2;
            currentDuels[_queue[queueType][tokenID.length].Address] = _matchesCount + 2;

            MatchInfo memory matchInfo;

            matchInfo.a = aTokenID;
            matchInfo.b = bTokenID;
            matchInfo.addressA = _queue[queueType][tokenID.length].Address;
            matchInfo.addressB = msg.sender;
            matchInfo.matchType = queueType;

            _matchInfo[_matchesCount] = matchInfo;

            // Remove WC from queue
            _queue[queueType][tokenID.length].TokenID[0] = 0;

            //Fee so server can end duel later
            payable(server).transfer(serverFee*2*tokenID.length);

            //Event
            emit DuelStarted(_matchInfo[_matchesCount], walletRecord[_queue[queueType][tokenID.length].Address].name, walletRecord[msg.sender].name);
        }
    }

    function removeFromQueue(uint256 queueType, uint256 matchSize) public{
        require(currentDuels[msg.sender] == 1, "Your WC isn't in queue");
        require(msg.sender == _queue[queueType][matchSize].Address, "Not your WC");

        currentDuels[msg.sender] = 0;
        currentPlayers--;
        for (uint i = 0; i < matchSize; i++) {
            _WC.safeTransferFrom(address(this), msg.sender, _queue[queueType][matchSize].TokenID[i]);
        }
        _queue[queueType][matchSize].TokenID[0] = 0;
        if(queueGlossary[queueType].currency != address(0)){
            bool transferComplete = IERC20(queueGlossary[queueType].currency).transfer(msg.sender, queueGlossary[queueType].price*matchSize);
            if(transferComplete == false){
                revert("Something bad happened with the ERC20");
            }
            payable(msg.sender).transfer(serverFee*matchSize);
        }else{
            payable(msg.sender).transfer((queueGlossary[queueType].price*matchSize)+(serverFee*matchSize));
        }
    }

    function getQueuedTokens(uint256 queueType, uint256 matchSize) public view returns(uint256[] memory){
        uint256[] memory result = new uint256[](matchSize);
        for (uint i = 0; i < matchSize; i++) {
                result[i] =  _queue[queueType][matchSize].TokenID[i];
        }
        return result;
    }

    function nameWallet(string memory newName) public{
        require(bytes(newName).length <= 42, "Address name has to be less than 42 characters");
        walletRecord[msg.sender].name = newName;
    }

    function setVictoryLine(string memory newVictoryLine) public{
        require(bytes(newVictoryLine).length <= 280, "Victory line has to be less than 280 characters");
        walletRecord[msg.sender].victoryLine = newVictoryLine;
    }

    function nameCard(string memory newName, uint256 tokenID) public{
        require(msg.sender == _WC.ownerOf(tokenID), "WC is not yours");
        require(bytes(newName).length <= 32, "Card name has to be less than 32 characters");
        cardRecord[tokenID].name = newName;
    }

    function addGlossaryPrice(uint256 _price, uint256 index) public onlyOwner {
        queueGlossary[index].price = _price;
        queueGlossary[index].enabled = false;
    }

    function addGlossaryCurrency(address _currency, uint256 index) public onlyOwner {
        queueGlossary[index].currency = _currency;
        queueGlossary[index].enabled = false;
    }

    function enableGlossary(uint256 index) public onlyOwner {
        if(_queue[index][1].TokenID.length == 0){
            for (uint i = 1; i <= 3; i++) {
                _queue[index][i].TokenID = [0];
            }
        }
        queueGlossary[index].enabled = true;
    }

    function changeTreasury(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        Treasury = newOwner;
    }

    function changeServerAddress(address newServer) public onlyOwner {
        require(newServer != address(0), "Ownable: new owner is the zero address");
        server = newServer;
    }

    function changeServerFee(uint256 newServerFee) public onlyOwner {
        serverFee = newServerFee;
    }

    function changeServerStatus() public onlyOwner {
        if(serverStatus == false){
            serverStatus = true;
        }else{
            serverStatus = false;
        }
    }

    //A winner == 0 , B winner == 1
    function endDuel(uint256 matchIndex, uint8 winner, uint256 winnerElo, uint256 loserElo) public {
        require(msg.sender == server || msg.sender == owner(), "Only server is allowed to end duel");
        address ownerA = _matchInfo[matchIndex].addressA;
        address ownerB = _matchInfo[matchIndex].addressB;

        address winnerOwner;
        address loserOwner;

        if(winner == 0){
            winnerOwner = ownerA;
            loserOwner = ownerB;
        }else{
            winnerOwner = ownerB;
            loserOwner = ownerA;
        }

        //Wallet wins/losses
        walletRecord[winnerOwner].wins++;
        walletRecord[loserOwner].losses++;

        walletRecord[winnerOwner].elo = winnerElo;
        walletRecord[loserOwner].elo = loserElo;

        //Card wins/losses
        if(winnerOwner == _matchInfo[matchIndex].addressA){
            for (uint256 i = 0; i < _matchInfo[matchIndex].a.length; i++) {
                cardRecord[_matchInfo[matchIndex].a[i]].wins++;
                cardRecord[_matchInfo[matchIndex].b[i]].losses++;
            }
        }else{
            for (uint256 i = 0; i < _matchInfo[matchIndex].a.length; i++) {
                cardRecord[_matchInfo[matchIndex].b[i]].wins++;
                cardRecord[_matchInfo[matchIndex].a[i]].losses++;
            }
        }

        //Transfer NFTs 
        for (uint i = 0; i < _matchInfo[matchIndex].a.length; i++) {
            _WC.safeTransferFrom(address(this), ownerA, _matchInfo[matchIndex].a[i]);
            _WC.safeTransferFrom(address(this), ownerB, _matchInfo[matchIndex].b[i]);
        }

        //Send prize
        uint256 prize = ((queueGlossary[_matchInfo[matchIndex].matchType].price)*(_matchInfo[matchIndex].a.length)*2)/10;
        if(queueGlossary[_matchInfo[matchIndex].matchType].currency != address(0)){
            bool transferCompleteWinner = IERC20(queueGlossary[_matchInfo[matchIndex].matchType].currency).transfer(address(winnerOwner), prize*9);
            bool transferCompleteTreasury = IERC20(queueGlossary[_matchInfo[matchIndex].matchType].currency).transfer(address(Treasury), prize);
            if(transferCompleteWinner == false || transferCompleteTreasury == false){
                revert("Something bad happened with the ERC20");
            }
        }else{
            payable(winnerOwner).transfer(prize*9);
            payable(Treasury).transfer(prize);
        }

        //reset variables
        currentDuels[ownerA] = 0;
        currentDuels[ownerB] = 0;
        
        currentPlayers = currentPlayers -2;

        //Event
        emit DuelEnded(_matchInfo[matchIndex], walletRecord[ownerA].name, walletRecord[ownerB].name, winner);
    }

    //Manual ending of duel
    function endDuelDraw(uint256 matchIndex) public onlyOwner {
        address ownerA = _matchInfo[matchIndex].addressA;
        address ownerB = _matchInfo[matchIndex].addressB;

        //Transfer NFTs 
        for (uint i = 0; i < _matchInfo[matchIndex].a.length; i++) {
            _WC.safeTransferFrom(address(this), ownerA, _matchInfo[matchIndex].a[i]);
            _WC.safeTransferFrom(address(this), ownerB, _matchInfo[matchIndex].b[i]);
        }

        //Send prize
        uint256 prize = ((queueGlossary[_matchInfo[matchIndex].matchType].price)*(_matchInfo[matchIndex].a.length)*2)/10;
        if(queueGlossary[_matchInfo[matchIndex].matchType].currency != address(0)){
            bool transferCompleteA = IERC20(queueGlossary[_matchInfo[matchIndex].matchType].currency).transfer(address(ownerA), prize*5);
            bool transferCompleteB = IERC20(queueGlossary[_matchInfo[matchIndex].matchType].currency).transfer(address(ownerB), prize*5);
            if(transferCompleteA == false || transferCompleteB == false){
                revert("Something bad happened with the ERC20");
            }
        }else{
            payable(ownerA).transfer(prize*5);
            payable(ownerB).transfer(prize*5);
        }

        //reset variables
        currentDuels[ownerA] = 0;
        currentDuels[ownerB] = 0;
        
        currentPlayers = currentPlayers -2;

        //Event
        emit DuelEnded(_matchInfo[matchIndex], walletRecord[ownerA].name, walletRecord[ownerB].name, 2);
    }
}