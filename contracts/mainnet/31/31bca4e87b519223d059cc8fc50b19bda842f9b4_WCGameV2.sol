/**
 *Submitted for verification at FtmScan.com on 2022-04-05
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


contract WCGameStats {
    uint256[][] public _weaponsHeld;
    uint256[][] public _traitScoreStats;
}


contract gameConstants {
    uint256[] public timeArray = [100000,100180,100324,100583,101050,101890,103401,106122,111020,119836,133000];
    uint256 public _timer = 20000;

    //calculates damage multiplier based on type
    // 0 None, 1 Blunt, 2 Piercing, 3 Slashing
    uint256[] private DamageMultArray0 = [2,1,1,1];
    uint256[] private DamageMultArray1 = [4,2,1,4];
    uint256[] private DamageMultArray2 = [4,4,2,1];
    uint256[] private DamageMultArray3 = [4,1,4,2];
    uint256[][] public multArray = [DamageMultArray0,DamageMultArray1,DamageMultArray2,DamageMultArray3];

    function calculateDamageMult(uint256 x, uint256 y) public view returns (uint256) {
        return multArray[x][y];
    }

    function timer() public view returns (uint256) {
        return _timer;
    }

    function timeBuff(uint i) public view returns (uint256) {
        return timeArray[i];
    }
}



library gameStructs {
    struct MatchInfo{
        mapping(uint256 => Duelist) a;
        mapping(uint256 => Duelist) b;
        uint256 currentCardA;
        uint256 currentCardB;
        uint256 matchSize;
        uint256 matchType;
        uint256 startTime;
        uint256 startTimeUnix;
        bool matchOver;
    }

    struct Duelist{
        address Owner;
        uint256 TokenID;
        uint256 Hp;
        uint256 Att;
        uint256 Def;
        uint256 Spd;
        uint256[2] Weapons;
        uint256 Type;
        uint256 NextTurn;
    }

    struct History{
        uint256 duration;

        address winner;
        address loser;

        mapping(uint256 => Move) attacks;
        uint256 moveCount;
    }

    struct Move{
        uint256 attacker;
        uint256 defender;

        uint256 damage;
        uint256 advantage;

        uint256 timestamp;
    }

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
}


library EndLogic {
    function endGame(
        gameStructs.Record storage winnerRecord, 
        gameStructs.Record[3] storage winnerCardRecords,
        gameStructs.Record storage loserRecord,
        gameStructs.Record[3] storage loserCardRecords,
        uint256 matchSize
    ) public {
        winnerRecord.wins++;
        loserRecord.losses++;

        if(winnerRecord.elo == 0){
            winnerRecord.elo = 1000;
        }
        if(loserRecord.elo == 0){
            loserRecord.elo = 1000;
        }

        if(winnerRecord.elo > loserRecord.elo){
            uint256 Elo1 = winnerRecord.elo;
            uint256 Elo2 = loserRecord.elo;

            uint256 Ex1 = ((Elo1**7)*100)/((Elo1**7)+(Elo2**7));

            uint256 newElo = ((100-Ex1)*42)/100;

            winnerRecord.elo = Elo1 + newElo;
            loserRecord.elo = Elo2 - newElo;
        }else{
            uint256 Elo1 = loserRecord.elo;
            uint256 Elo2 = winnerRecord.elo;

            uint256 Ex1 = ((Elo2**7)*100)/((Elo1**7)+(Elo2**7));

            uint256 newElo = ((100-Ex1)*42)/100;

            winnerRecord.elo = Elo2 + newElo;
            loserRecord.elo = Elo1 - newElo;
        }

        for (uint256 i = 0; i < matchSize; i++) {
            winnerCardRecords[i].wins++;
            loserCardRecords[i].losses++;
        }
    }

    function sendPrize(
        uint256 price,
        uint256 matchSize,
        address winner,
        address treasury,
        address currency
    ) public {
        //Winner gets 90%, Treasury gets 10%
        uint256 prize = ((price)*(matchSize)*2)/10;
        if(currency != address(0)){
            bool transferCompleteWinner = IERC20(currency).transfer(address(winner), prize*9);
            bool transferCompleteTreasury = IERC20(currency).transfer(address(treasury), prize);
            if(transferCompleteWinner == false || transferCompleteTreasury == false){
                revert("Something bad happened with the ERC20");
            }
        }else{
            payable(winner).transfer(prize*9);
            payable(treasury).transfer(prize);
        }
    }

    function sendNFTs(
        uint256 matchSize,
        address ownerA,
        address ownerB,
        mapping(uint256 => gameStructs.Duelist) storage cardsA,
        mapping(uint256 => gameStructs.Duelist) storage cardsB,
        ERC721 NFT
    ) public {
        for (uint i = 0; i < matchSize; i++) {
            NFT.safeTransferFrom(address(this), ownerA, cardsA[i].TokenID);
            NFT.safeTransferFrom(address(this), ownerB, cardsB[i].TokenID);
        }
    }
}


library AttackLogic {
    struct attackResult {
        bool kill;
        address winner;
        address loser;
        uint8 winnerIndex;
    }

    function Attack(
        gameConstants _gameConstants,
        uint256 weaponChoice, 
        uint256 damageBase,
        gameStructs.MatchInfo storage matchData, gameStructs.History storage H
    ) public returns (attackResult memory) {

        if(msg.sender == matchData.a[0].Owner){
            require(matchData.a[matchData.currentCardA].NextTurn <= block.number, "you can't attack yet");

            uint256 delta = block.number - matchData.a[matchData.currentCardA].NextTurn;
            if(delta >= 15){
                delta = 15;
            }

            uint256 advantage = _gameConstants.calculateDamageMult(matchData.a[matchData.currentCardA].Weapons[weaponChoice],matchData.b[matchData.currentCardB].Type);
            uint256 damage = (((((matchData.a[matchData.currentCardA].Att*damageBase)/matchData.b[matchData.currentCardB].Def)*advantage)*_gameConstants.timeBuff(delta*2/3))/200000);

            if(damage > matchData.b[matchData.currentCardB].Hp){
                matchData.b[matchData.currentCardB].Hp = 0;
            }else{
                matchData.b[matchData.currentCardB].Hp = matchData.b[matchData.currentCardB].Hp - damage;
            }

            matchData.a[matchData.currentCardA].NextTurn = (_gameConstants.timer()/matchData.a[matchData.currentCardA].Spd) + 8 + block.number;
            matchData.a[matchData.currentCardA].Type = matchData.a[matchData.currentCardA].Weapons[weaponChoice];

            H.attacks[H.moveCount].attacker = matchData.a[matchData.currentCardA].TokenID;
            H.attacks[H.moveCount].defender = matchData.b[matchData.currentCardB].TokenID;
            H.attacks[H.moveCount].damage = damage;
            H.attacks[H.moveCount].advantage = advantage;
            H.attacks[H.moveCount].timestamp = block.number;

            H.moveCount++;

            if(matchData.b[matchData.currentCardB].Hp == 0){
                for (uint i = 0; i < matchData.matchSize; i++) {
                    if(matchData.b[i].Hp == 0){
                        continue;
                    }else{
                        matchData.currentCardB = i;
                        return attackResult(false,address(0),address(0),0);
                    }
                }
                matchData.matchOver = true;

                H.winner = matchData.a[0].Owner;
                H.loser = matchData.b[0].Owner;

                H.duration = block.timestamp - matchData.startTimeUnix;

                return attackResult(true,matchData.a[0].Owner,matchData.b[0].Owner,0);
            }

        }else{
            require(matchData.b[matchData.currentCardB].NextTurn <= block.number, "you can't attack yet");

            uint256 delta = block.number - matchData.b[matchData.currentCardB].NextTurn;
            if(delta >= 15){
                delta = 15;
            }

            uint256 advantage = _gameConstants.calculateDamageMult(matchData.b[matchData.currentCardB].Weapons[weaponChoice],matchData.a[matchData.currentCardA].Type);
            uint256 damage = (((((matchData.b[matchData.currentCardB].Att*damageBase)/matchData.a[matchData.currentCardA].Def)*advantage)*_gameConstants.timeBuff(delta*2/3))/200000);

            if(damage > matchData.a[matchData.currentCardA].Hp){
                matchData.a[matchData.currentCardA].Hp = 0;
            }else{
                matchData.a[matchData.currentCardA].Hp = matchData.a[matchData.currentCardA].Hp - damage;
            }

            matchData.b[matchData.currentCardB].NextTurn = (_gameConstants.timer()/matchData.b[matchData.currentCardB].Spd) + 8 + block.number;
            matchData.b[matchData.currentCardB].Type = matchData.b[matchData.currentCardB].Weapons[weaponChoice];

            H.attacks[H.moveCount].attacker = matchData.b[matchData.currentCardB].TokenID;
            H.attacks[H.moveCount].defender = matchData.a[matchData.currentCardA].TokenID;
            H.attacks[H.moveCount].damage = damage;
            H.attacks[H.moveCount].advantage = advantage;
            H.attacks[H.moveCount].timestamp = block.number;

            H.moveCount++;

            if(matchData.a[matchData.currentCardA].Hp == 0){
                for (uint i = 0; i < matchData.matchSize; i++) {
                    if(matchData.a[i].Hp == 0){
                        continue;
                    }else{
                        matchData.currentCardA = i;
                        return attackResult(false,address(0),address(0),0);
                    }
                }
                matchData.matchOver = true;

                H.winner = matchData.b[0].Owner;
                H.loser = matchData.a[0].Owner;

                H.duration = block.timestamp - matchData.startTimeUnix;

                return attackResult(true,matchData.b[0].Owner,matchData.a[0].Owner,1);
            }
        }

        attackResult memory temp;
        temp.kill = false;

        return temp;
    }
}


contract WCGameV2 is Ownable, ERC721Holder, gameConstants{

    address public Treasury = 0x3f6B955Bc6C879d00cEa84CFDc59c7091EA90720;

    ERC721 public constant _WC = ERC721(0xC031b7793F17100e9B7Ad369cA05e5ec8A0F5B5C);

    WCGameStats public constant CardStats = WCGameStats(0x19A76a66d74118Bbdd1e8d3412DEC18f0470A190);
    
    uint256 public damageBase = 1250;
    uint256 public healingBase = 10;
    uint256 public _matchesCount = 0;
    uint256 public currentPlayers = 0;

    mapping(uint256 => gameStructs.MatchInfo) public _matchInfo;
    mapping(address => uint256) public currentDuels;

    mapping(address => gameStructs.Record) public walletRecord;
    mapping(uint256 => gameStructs.Record) public cardRecord;
    mapping(uint256 => gameStructs.History) public history;

    mapping(uint256 => mapping (uint256 => gameStructs.QueueStruct)) public _queue;
    mapping(uint256 => gameStructs.Glossary) public queueGlossary;

    gameStructs.Record[3] winnerCardRecords;
    gameStructs.Record[3] loserCardRecords;

    event QueueUp(address addressAddress, string addressName, uint256 queueType, uint256 matchSize); //Event for queue up
    event DuelStarted(uint256 AtokenID, uint256 BtokenID, address addressAAddress, string addressAName, address addressBAddress, string addressBName, uint256 queueType, uint256 matchSize); //Event for Start of Duel
    event DuelEnded(gameStructs.Duelist[2][] tokenIDs, string addressAName, string addressBName, uint8 winner); //Event for End of Duel

    function Queue(uint256[] memory tokenID, uint256 weaponChoice, uint256 queueType) payable public{
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
        }else{
            if(queueGlossary[queueType].price*tokenID.length != msg.value){
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


            for (uint256 i = 0; i < tokenID.length; i++) {
                _matchInfo[_matchesCount].a[i].Owner = _queue[queueType][tokenID.length].Address;
                _matchInfo[_matchesCount].a[i].TokenID = aTokenID[i];
                _matchInfo[_matchesCount].a[i].Hp = CardStats._traitScoreStats(aTokenID[i],0);
                _matchInfo[_matchesCount].a[i].Att = CardStats._traitScoreStats(aTokenID[i],1);
                _matchInfo[_matchesCount].a[i].Def = CardStats._traitScoreStats(aTokenID[i],2);
                _matchInfo[_matchesCount].a[i].Spd = CardStats._traitScoreStats(aTokenID[i],3);
                _matchInfo[_matchesCount].a[i].Weapons = [CardStats._weaponsHeld(aTokenID[i],0), CardStats._weaponsHeld(aTokenID[i],1)];
                _matchInfo[_matchesCount].a[i].Type = _matchInfo[_matchesCount].a[i].Weapons[_queue[queueType][tokenID.length].Weapon];
                _matchInfo[_matchesCount].a[i].NextTurn = timer()/_matchInfo[_matchesCount].a[i].Spd + 8 + block.number;
            }
            _matchInfo[_matchesCount].currentCardA = 0;


            for (uint256 i = 0; i < tokenID.length; i++) {
                _matchInfo[_matchesCount].b[i].Owner = msg.sender;
                _matchInfo[_matchesCount].b[i].TokenID = bTokenID[i];
                _matchInfo[_matchesCount].b[i].Hp = CardStats._traitScoreStats(bTokenID[i],0);
                _matchInfo[_matchesCount].b[i].Att = CardStats._traitScoreStats(bTokenID[i],1);
                _matchInfo[_matchesCount].b[i].Def = CardStats._traitScoreStats(bTokenID[i],2);
                _matchInfo[_matchesCount].b[i].Spd = CardStats._traitScoreStats(bTokenID[i],3);
                _matchInfo[_matchesCount].b[i].Weapons = [CardStats._weaponsHeld(bTokenID[i],0),CardStats._weaponsHeld(bTokenID[i],1)];
                _matchInfo[_matchesCount].b[i].Type = _matchInfo[_matchesCount].b[i].Weapons[weaponChoice];
                _matchInfo[_matchesCount].b[i].NextTurn =  timer()/_matchInfo[_matchesCount].b[i].Spd + 8 + block.number;
            }
            _matchInfo[_matchesCount].currentCardB = 0;

            _matchInfo[_matchesCount].matchSize = tokenID.length;
            _matchInfo[_matchesCount].matchType = queueType;
            _matchInfo[_matchesCount].startTime = block.number;
            _matchInfo[_matchesCount].startTimeUnix = block.timestamp;
            _matchInfo[_matchesCount].matchOver = false;

            // Remove WC from queue
            _queue[queueType][tokenID.length].TokenID[0] = 0;

            //Event
            emit DuelStarted(aTokenID[0], bTokenID[0], _queue[queueType][tokenID.length].Address, walletRecord[_queue[queueType][tokenID.length].Address].name, msg.sender, walletRecord[msg.sender].name, queueType, tokenID.length);
        }
    }

    //weaponChoice: 0 is left arm, 1 is right arm. This determines trait
    function Attack(uint256 weaponChoice) public{
        uint256 matchIndex = currentDuels[msg.sender]-2;

        require(matchIndex >= 1, "no active match can be found with this WC");
        require(weaponChoice == 0 || weaponChoice == 1, "weaponChoice has to be left or right hand (0 or 1)");
        require(msg.sender == _matchInfo[matchIndex].a[0].Owner || msg.sender == _matchInfo[matchIndex].b[0].Owner, "you are not the owner of this WC");
        AttackLogic.attackResult memory result = AttackLogic.Attack(
            this,
            weaponChoice,
            damageBase,
            _matchInfo[matchIndex], history[matchIndex]
        );

        if (result.kill) {
            currentDuels[result.winner] = 0;
            currentDuels[result.loser] = 0;

            if (result.winnerIndex == 0){
                for (uint8 i = 0; i < _matchInfo[matchIndex].matchSize; i++) {
                    winnerCardRecords[i] = cardRecord[_matchInfo[matchIndex].a[i].TokenID];
                    loserCardRecords[i] = cardRecord[_matchInfo[matchIndex].b[i].TokenID];
                }
            } else {
                for (uint8 i = 0; i < _matchInfo[matchIndex].matchSize; i++) {
                    winnerCardRecords[i] = cardRecord[_matchInfo[matchIndex].b[i].TokenID];
                    loserCardRecords[i] = cardRecord[_matchInfo[matchIndex].a[i].TokenID];
                }
            }

            EndLogic.endGame(
                walletRecord[result.winner], 
                winnerCardRecords, 
                walletRecord[result.loser], 
                loserCardRecords, 
                _matchInfo[matchIndex].matchSize
            );
            EndLogic.sendNFTs(
                _matchInfo[matchIndex].matchSize,
                _matchInfo[matchIndex].a[0].Owner,
                _matchInfo[matchIndex].b[0].Owner,
                _matchInfo[matchIndex].a,
                _matchInfo[matchIndex].b,
                _WC
            );
            EndLogic.sendPrize(
                queueGlossary[_matchInfo[matchIndex].matchType].price,
                _matchInfo[matchIndex].matchSize,
                result.winner,
                Treasury,
                queueGlossary[_matchInfo[matchIndex].matchType].currency
            );

            currentPlayers = currentPlayers -2;
            emit DuelEnded(getDuelists(matchIndex), walletRecord[_matchInfo[matchIndex].a[0].Owner].name, walletRecord[_matchInfo[matchIndex].b[0].Owner].name, result.winnerIndex);
        }
    }

    function Heal(uint256 card) public{
        uint256 matchIndex = currentDuels[msg.sender]-2;
        address ownerA = _matchInfo[matchIndex].a[0].Owner;
        address ownerB = _matchInfo[matchIndex].b[0].Owner;
        uint256 currentCardA = _matchInfo[matchIndex].currentCardA;
        uint256 currentCardB = _matchInfo[matchIndex].currentCardB;

        require(matchIndex >= 1, "no active match can be found with this WC");
        require(card < _matchInfo[matchIndex].matchSize, "new card does not exist");
        require(msg.sender == ownerA || msg.sender == ownerB, "you are not the owner of this WC");

        if(msg.sender == ownerA){
            require(_matchInfo[matchIndex].a[currentCardA].Weapons[1] == 0, "card is not a healer");
            require(_matchInfo[matchIndex].a[card].Hp > 0, "card you're trying to heal is dead");
            require(_matchInfo[matchIndex].a[currentCardA].NextTurn <= block.number, "you can't attack yet");

            uint256 delta = block.number - _matchInfo[matchIndex].a[currentCardA].NextTurn;
            if(delta >= 15){
                delta = 15;
            }

            uint256 healing = (((((_matchInfo[matchIndex].a[currentCardA].Att+_matchInfo[matchIndex].a[currentCardA].Def)/2)*healingBase)*timeBuff(delta*2/3))/1000000);
            uint256 cardMaxHp = CardStats._traitScoreStats(_matchInfo[matchIndex].a[card].TokenID,0);

            if(_matchInfo[matchIndex].a[card].Hp + healing > cardMaxHp){
                _matchInfo[matchIndex].a[card].Hp = cardMaxHp;
            }else{
                _matchInfo[matchIndex].a[card].Hp += healing;
            }

            _matchInfo[matchIndex].a[currentCardA].NextTurn = (timer()/_matchInfo[matchIndex].a[currentCardA].Spd) + 8 + block.number;

            history[matchIndex].attacks[history[matchIndex].moveCount].attacker = _matchInfo[matchIndex].a[currentCardA].TokenID;
            history[matchIndex].attacks[history[matchIndex].moveCount].defender = _matchInfo[matchIndex].a[card].TokenID;
            history[matchIndex].attacks[history[matchIndex].moveCount].damage = healing;
            history[matchIndex].attacks[history[matchIndex].moveCount].advantage = 100;
            history[matchIndex].attacks[history[matchIndex].moveCount].timestamp = block.number;

            history[matchIndex].moveCount++;


        }else{
            require(_matchInfo[matchIndex].b[currentCardB].Weapons[1] == 0, "card is not a healer");
            require(_matchInfo[matchIndex].b[card].Hp > 0, "card you're trying to heal is dead");
            require(_matchInfo[matchIndex].b[currentCardB].NextTurn <= block.number, "you can't attack yet");

            uint256 delta = block.number - _matchInfo[matchIndex].b[currentCardB].NextTurn;
            if(delta >= 15){
                delta = 15;
            }

            uint256 healing = (((((_matchInfo[matchIndex].b[currentCardB].Att+_matchInfo[matchIndex].b[currentCardB].Def)/2)*healingBase)*timeBuff(delta*2/3))/1000000);
            uint256 cardMaxHp = CardStats._traitScoreStats(_matchInfo[matchIndex].b[card].TokenID,0);

            if(_matchInfo[_matchesCount].b[card].Hp + healing > cardMaxHp){
                _matchInfo[_matchesCount].b[card].Hp = cardMaxHp;
            }else{
                _matchInfo[_matchesCount].b[card].Hp += healing;
            }

            _matchInfo[matchIndex].b[currentCardB].NextTurn = (timer()/_matchInfo[matchIndex].b[currentCardB].Spd) + 13 + block.number;

            history[matchIndex].attacks[history[matchIndex].moveCount].attacker = _matchInfo[matchIndex].b[currentCardB].TokenID;
            history[matchIndex].attacks[history[matchIndex].moveCount].defender = _matchInfo[matchIndex].b[card].TokenID;
            history[matchIndex].attacks[history[matchIndex].moveCount].damage = healing;
            history[matchIndex].attacks[history[matchIndex].moveCount].advantage = 100;
            history[matchIndex].attacks[history[matchIndex].moveCount].timestamp = block.number;

            history[matchIndex].moveCount++;
        }

    }

    function Swap(uint256 newCard) public{
        uint256 matchIndex = currentDuels[msg.sender]-2;
        uint256 currentCardA = _matchInfo[matchIndex].currentCardA;
        uint256 currentCardB = _matchInfo[matchIndex].currentCardB;

        require(matchIndex >= 1, "no active match can be found with this WC");
        require(_matchInfo[matchIndex].matchSize > 1, "only card on the field");
        require(newCard < _matchInfo[matchIndex].matchSize, "new card does not exist");
        if(msg.sender == _matchInfo[matchIndex].a[0].Owner){
            require(newCard != _matchInfo[matchIndex].currentCardA, "new card is already in");
            require(_matchInfo[matchIndex].a[newCard].Hp > 0, "new card is already dead");
            _matchInfo[matchIndex].currentCardA = newCard;
            if( _matchInfo[matchIndex].a[currentCardA].NextTurn < 8 + block.number){
                _matchInfo[matchIndex].a[currentCardA].NextTurn = 8 + block.number;
            }

        }else if(msg.sender == _matchInfo[matchIndex].b[0].Owner){
            require(newCard != _matchInfo[matchIndex].currentCardB, "new card is already in");
            require(_matchInfo[matchIndex].b[newCard].Hp > 0, "new card is already dead");
            _matchInfo[matchIndex].currentCardB = newCard;
            if( _matchInfo[matchIndex].b[currentCardB].NextTurn < 8 + block.number){
                _matchInfo[matchIndex].b[currentCardB].NextTurn = 8 + block.number;
            }
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
        }else{
            payable(msg.sender).transfer(queueGlossary[queueType].price*matchSize);
        }


    }

    function getMoves(uint256 X) public view returns(gameStructs.Move[] memory){
        uint256 length = history[X].moveCount;
        gameStructs.Move[] memory result = new gameStructs.Move[](length);
        for (uint i = 0; i < length; i++) {
            result[i] = history[X].attacks[i];
        }
        return result;
    }

    function getDuelists(uint256 X) public view returns(gameStructs.Duelist[2][] memory){
        uint256 length = _matchInfo[X].matchSize;
        gameStructs.Duelist[2][] memory result = new gameStructs.Duelist[2][](length);
        for (uint i = 0; i < 2; i++) {
            if(i == 0){
                for (uint j = 0; j < length; j++) {
                    result[j][i] =  _matchInfo[X].a[j];
                }
            }else{
                for (uint j = 0; j < length; j++) {
                    result[j][i] =  _matchInfo[X].b[j];
                }
            }
        }
        return result;
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

    function changeHealing(uint256 newHealingBase) public onlyOwner {
        healingBase = newHealingBase;
    }

    function changeDamage(uint256 newDamageBase) public onlyOwner {
        damageBase = newDamageBase;
    }

    //This is for worst case scenario. Can only be used after a match has been in progress for more than an hour
    function endDuel(uint256 matchIndex) public onlyOwner {
        require((block.timestamp - _matchInfo[matchIndex].startTimeUnix) >= 3600);

        address ownerA = _matchInfo[matchIndex].a[0].Owner;
        address ownerB = _matchInfo[matchIndex].b[0].Owner;

        _matchInfo[matchIndex].matchOver = true;
        _matchInfo[matchIndex].matchType = 10000;

        currentDuels[ownerA] = 0;
        currentDuels[ownerB] = 0;
        currentPlayers = currentPlayers -2;

        for (uint i = 0; i < _matchInfo[matchIndex].matchSize; i++) {
            _WC.safeTransferFrom(address(this), ownerA, _matchInfo[matchIndex].a[i].TokenID);
            _WC.safeTransferFrom(address(this), ownerB, _matchInfo[matchIndex].b[i].TokenID);
        }

        uint256 prize = ((queueGlossary[_matchInfo[matchIndex].matchType].price)*(_matchInfo[matchIndex].matchSize)*2)/10;
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

        emit DuelEnded(getDuelists(matchIndex), walletRecord[ownerA].name, walletRecord[ownerB].name, 2);
    }
}