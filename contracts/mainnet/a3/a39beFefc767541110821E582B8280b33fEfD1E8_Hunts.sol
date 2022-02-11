// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./Pausable.sol";

interface ISnakeskin {
  function bulkApprove(address[] memory spenders, uint256[] memory amounts) external returns (bool);
  function mint(address recipient, uint256 amount) external;
}

interface ISassySnakes {
  function snakeSize(uint256 tokenId) external view returns (uint256);
}

interface ISassySnakeEggs {
  function assignRewards(address[] memory winners, uint256[] memory amounts) external;
  function huntRewards(address wallet) external returns (uint256);
}

contract Hunts is IERC721Receiver, Ownable, Pausable {
  using EnumerableSet for EnumerableSet.UintSet;

  address public ERC20_CONTRACT;
  address public ERC721_CONTRACT;
  address public ERC721_EGGS_CONTRACT;
  uint256 public huntWeek; 
  uint256 public baseSkinReward;
  uint256 public huntDuration;
  uint256 public numberEnlisted;
  address[] public uniqueAddresses;
  address[] public addressPool; // includes repeated entries for multiple tokens and snake size > 1 (used for rewards)
  uint256 public commencementTimestamp;
  uint256[] public huntCommencements;
  uint256 private _eggWinnerDivisor;
  address[] public eggWinners;

  struct History{
    uint256 week;
    uint256 eggsWon;
    uint256 skinWon;
  }

  mapping(address => EnumerableSet.UintSet) private _deposits;
  mapping(address => mapping(uint256 => uint256)) public currentEnlistments; // owner => (tokenId => huntCommencementTimestamp)
  mapping(uint256 => uint256[]) public enlistmentHistory; // week => tokenIds  
  mapping(address => History[]) public historicalRewards;
  mapping(address => bool) public addressExists;
  mapping(address => bool) public isEggWinner;
  mapping(address => bool) public isSkinWinner;
  mapping(address => uint256) public eggsWon;
  mapping(address => uint256) public skinWon;
  

  constructor(
    address _erc20,
    address _erc721,
    address _erc721Eggs,
    uint256 _huntDuration,
    uint256 _baseSkinReward,
    uint256 _commencementTimestamp
  ) {
    ERC20_CONTRACT = _erc20;
    ERC721_CONTRACT = _erc721;
    ERC721_EGGS_CONTRACT = _erc721Eggs;
    // 432,000 seconds or 5 days
    huntDuration = _huntDuration;
    baseSkinReward = _baseSkinReward;
    commencementTimestamp = _commencementTimestamp;
    huntWeek = 1;
    _eggWinnerDivisor = 3;
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }

  function depositsOf(address account) public view returns (uint256[] memory) {
    EnumerableSet.UintSet storage depositSet = _deposits[account];
    uint256[] memory tokenIds = new uint256[](depositSet.length());

    for (uint256 i; i < depositSet.length(); i++) {
        tokenIds[i] = depositSet.at(i);
    }

    return tokenIds;
  }

  function getRemoveableTokens(address account) external view returns (uint256[] memory) {
    uint256[] memory deposits = depositsOf(account);

    uint256 counter = 0;
    for (uint256 i = 0; i < deposits.length; i++) {
      if (isTokenRemoveable(account, deposits[i])) {
        counter++;
      } else {
        deposits[i] = 0;
      }
    }

    uint256[] memory removeableTokens = new uint256[](counter);
    counter = 0;

    for (uint256 i = 0; i < deposits.length; i++) {
      if (deposits[i] != 0) {
        removeableTokens[counter++] = deposits[i];
      }
    }

    return removeableTokens;
  }

  function isTokenRemoveable(address owner, uint256 tokenId) public view returns (bool) {
    uint256 endTimestamp = currentEnlistments[owner][tokenId] + huntDuration;

    if (block.timestamp >= endTimestamp) {
      return true;
    }

    return false;
  }

  function commenceHunt() public onlyOwner(){   
    huntCommencements.push(commencementTimestamp);  
  }

  function endHunt() public onlyOwner {
    designateRewards();
    delete addressPool;
    commencementTimestamp = block.timestamp + 172800; // 48 hours
    huntWeek = huntWeek + 1;      
  }

  function designateRewards() private {
    uint256 totalSkin = 0;

    for (uint256 i = 0; i < addressPool.length; i++) {

      // addressPool contains 1 address per size, e.g. 2 snakes entered with size 4 and size 2, address will appear here 6 times
      if (i <= addressPool.length / _eggWinnerDivisor){

        if(eggsWon[addressPool[i]] > 0){
          eggsWon[addressPool[i]] = eggsWon[addressPool[i]] + 1;
        } else {
          eggsWon[addressPool[i]] = 1;
          eggWinners.push(addressPool[i]);
        }

        uint256 reward = baseSkinReward*3;
        _addSkinWon(addressPool[i], reward);  
        totalSkin+=reward;
      }

      if (i > addressPool.length / _eggWinnerDivisor && i <= addressPool.length - (addressPool.length / _eggWinnerDivisor)) {
        uint256 reward = baseSkinReward*5;
        _addSkinWon(addressPool[i], reward);  
        totalSkin+=reward;        
      }

      if (i > addressPool.length - (addressPool.length / _eggWinnerDivisor)){
        uint256 reward = baseSkinReward*7;
        _addSkinWon(addressPool[i], reward); 
        totalSkin+=reward;               
      }
      
    }

    uint256[] memory eggRewards = new uint256[](eggWinners.length); 
    uint256[] memory skinRewards = new uint256[](uniqueAddresses.length); 

    for (uint256 k = 0; k < eggWinners.length; k++){
      eggRewards[k] = eggsWon[eggWinners[k]];
    }

    for (uint256 j = 0; j < skinRewards.length; j++){
      skinRewards[j] = skinWon[uniqueAddresses[j]];
    }    

    ISnakeskin(ERC20_CONTRACT).mint(address(this), totalSkin);
    ISnakeskin(ERC20_CONTRACT).bulkApprove(uniqueAddresses, skinRewards);
    ISassySnakeEggs(ERC721_EGGS_CONTRACT).assignRewards(eggWinners, eggRewards);

    // addHistory and delete mappings
    for (uint l = 0; l < uniqueAddresses.length; l++){
      _addHistory(uniqueAddresses[l]);
      delete isEggWinner[uniqueAddresses[l]];
      delete isSkinWinner[uniqueAddresses[l]];
      delete skinWon[uniqueAddresses[l]];
      delete eggsWon[uniqueAddresses[l]];   
      delete addressExists[uniqueAddresses[l]];
    }
    delete uniqueAddresses;
  }
  // add snake -> add deposit address -> add record to _deposits -> add to _currentEnlistments and set timestamp 
  function addSnakeToHunt(uint256 tokenId) public whenNotPaused {
    require(ISassySnakeEggs(ERC721_EGGS_CONTRACT).huntRewards(msg.sender) == 0, "Hunt: You must claim all your egg rewards to add from this address");

    uint256 snakeSize = ISassySnakes(ERC721_CONTRACT).snakeSize(tokenId);

    for (uint256 i=0; i< snakeSize; i++){
      if (!addressExists[msg.sender]){
        uniqueAddresses.push(msg.sender);
      }

      if (addressPool.length > 2){
        uint256 index = _getRandomIndex();
        _insertAddress(msg.sender, index);
      } else {
        addressPool.push(msg.sender);
      }  

    }

    _deposits[msg.sender].add(tokenId);
    currentEnlistments[msg.sender][tokenId] = commencementTimestamp;
    enlistmentHistory[huntWeek].push(tokenId);
    _incrementNumberEnlisted();

    IERC721(ERC721_CONTRACT).safeTransferFrom(msg.sender, address(this), tokenId, '');
  }

  // remove snake -> remove record from deposits -> remove mapping from currentEnlistments
  function removeSnakeFromHunt(uint256 tokenId) public whenNotPaused {
    require(_deposits[msg.sender].contains(tokenId), "Hunt: Snake must be deposited for it to be removed");
    require(block.timestamp > currentEnlistments[msg.sender][tokenId] + huntDuration, "Hunt: You may only remove the snake after the hunt it was enlisted for has completed");

    _deposits[msg.sender].remove(tokenId);
    delete currentEnlistments[msg.sender][tokenId];
    _decrementNumberEnlisted();
    
    IERC721(ERC721_CONTRACT).safeTransferFrom(address(this), msg.sender, tokenId, '');
  }

  function reEnlistSnake(uint256 tokenId) public whenNotPaused{
    require(_deposits[msg.sender].contains(tokenId), "Hunt: Snake must already be deposited to Re-enlist");
    require(block.timestamp > currentEnlistments[msg.sender][tokenId] + huntDuration, "Hunt: The hunt you enlisted for must be complete to re-enlist");
    require(ISassySnakeEggs(ERC721_EGGS_CONTRACT).huntRewards(msg.sender) == 0, "Hunt: You must claim all your egg rewards to re-enlist from this address");

    uint256 index = _getRandomIndex();
    _insertAddress(msg.sender, index);
    currentEnlistments[msg.sender][tokenId] = commencementTimestamp;
    enlistmentHistory[huntWeek].push(tokenId);
  }

  function bulkEnlistSnakes(uint256[] calldata tokenIds) external {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      addSnakeToHunt(tokenIds[i]);
    }
  }

  function bulkRemoveSnakes(uint256[] calldata tokenIds) external {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      removeSnakeFromHunt(tokenIds[i]);
    }  
  }  

  function bulkReEnlistSnakes(uint256[] calldata tokenIds) external {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      reEnlistSnake(tokenIds[i]);
    }
  }  

  function huntDurationRemaining() external view returns (uint256) {
    return (commencementTimestamp + huntDuration) - block.timestamp;
  }

  function isDeposited(uint256 tokenId, address snakeOwner) external view returns (bool) {
    return _deposits[snakeOwner].contains(tokenId);
  }

  function getCurrentEnlistment(address wallet, uint256 token) public view returns (uint256) {
    uint256 timestamp = currentEnlistments[wallet][token];
    return timestamp;
  }

  function setBaseSkinReward(uint256 amount) public onlyOwner{
    baseSkinReward = amount;
  }

  function _setHuntDuration(uint256 duration) public onlyOwner {
    huntDuration = duration;
  }

  function setCommencementTimestamp(uint256 timestamp) public onlyOwner {
    commencementTimestamp = timestamp;
  }  

  function addressPoolLength() public view onlyOwner returns (uint256) {
    return addressPool.length;
  }

  function setEggWinnerDivisor(uint256 divisor) public onlyOwner{
    require(divisor > 0, "Divisor must be great than 0");
    _eggWinnerDivisor = divisor;
  }

  function _getRandomIndex() private view returns (uint256){
    if (addressPool.length > 0){
      uint256 index = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, addressPool))) % addressPool.length;
      return index;   
    } else {
      return 0;
    }
  }

  function _insertAddress(address enlister, uint256 index) private{
    if (index == addressPool.length){
      addressPool.push(enlister);
    } else {
      addressPool.push(addressPool[index]);
      addressPool[index] = enlister;
    }
  }

  function _addSkinWon(address winner, uint256 skin) private {
    if (isSkinWinner[winner]){
      skinWon[winner] = skinWon[winner] + skin;
    } else {
      isSkinWinner[winner] = true;
      skinWon[winner] = skin;
    }
  }

  function _addHistory(address wallet) private {
    History memory history = History({
      week: huntWeek,
      eggsWon: eggsWon[wallet],
      skinWon: skinWon[wallet]
    });

    historicalRewards[msg.sender].push(history);
  }

  function _incrementNumberEnlisted() private {
    numberEnlisted += 1;
  }

  function _decrementNumberEnlisted() private {
    numberEnlisted -= 1;
  }

}