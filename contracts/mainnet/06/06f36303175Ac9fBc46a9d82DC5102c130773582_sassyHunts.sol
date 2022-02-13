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

interface ISassySnakeEggs {
  function huntRewards(address wallet) external returns (uint256);
}

contract sassyHunts is IERC721Receiver, Ownable {
  using EnumerableSet for EnumerableSet.UintSet;

  address public ERC20_CONTRACT;
  address public ERC721_CONTRACT;
  address public ERC721_EGGS_CONTRACT;
  uint256 public huntWeek;
  uint256 public huntDuration;
  uint256 public numberEnlisted;
  uint256 public commencementTimestamp;
  uint256[] public huntCommencements;
  bool private pauseAdd;
  bool private pauseRemove;
  
  mapping(address => EnumerableSet.UintSet) private _deposits;
  mapping(address => mapping(uint256 => uint256)) public currentEnlistments; // owner => (tokenId => huntCommencementTimestamp)
  mapping(uint256 => uint256[]) public enlistmentHistory; // week => tokenIds    

  constructor(
    address _erc20,
    address _erc721,
    address _erc721Eggs,
    uint256 _huntDuration,
    uint256 _commencementTimestamp
  ) {
    ERC20_CONTRACT = _erc20;
    ERC721_CONTRACT = _erc721;
    ERC721_EGGS_CONTRACT = _erc721Eggs;
    // 432,000 seconds or 5 days
    huntDuration = _huntDuration;
    commencementTimestamp = _commencementTimestamp;
    huntWeek = 2;
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
    huntWeek = huntWeek + 1;      
  }

  // add snake -> add record to _deposits -> add to _currentEnlistments and set timestamp 
  function addSnakeToHunt(uint256 tokenId) public {
    require(ISassySnakeEggs(ERC721_EGGS_CONTRACT).huntRewards(msg.sender) == 0, "Hunt: You must claim all your egg rewards to add from this address");
    require(!pauseAdd, "Hunt: Adding to the hunt is currently paused");
    

    _deposits[msg.sender].add(tokenId);
    currentEnlistments[msg.sender][tokenId] = commencementTimestamp;
    enlistmentHistory[huntWeek].push(tokenId);
    _incrementNumberEnlisted();

    IERC721(ERC721_CONTRACT).safeTransferFrom(msg.sender, address(this), tokenId, '');
  }

  // remove snake -> remove record from deposits -> remove mapping from currentEnlistments
  function removeSnakeFromHunt(uint256 tokenId) public {
    require(!pauseRemove, "Hunt: Removing snakes from hunt is currently paused");      
    require(_deposits[msg.sender].contains(tokenId), "Hunt: Snake must be deposited for it to be removed");
    require(isTokenRemoveable(msg.sender, tokenId), "Hunt: You may only remove the snake after the hunt it was enlisted for has completed");

    _deposits[msg.sender].remove(tokenId);
    delete currentEnlistments[msg.sender][tokenId];
    _decrementNumberEnlisted();
    
    IERC721(ERC721_CONTRACT).safeTransferFrom(address(this), msg.sender, tokenId, '');
  }

  function reEnlistSnake(uint256 tokenId) public{
    require(_deposits[msg.sender].contains(tokenId), "Hunt: Snake must already be deposited to Re-enlist");
    require(block.timestamp > currentEnlistments[msg.sender][tokenId] + huntDuration, "Hunt: The hunt you enlisted for must be complete to re-enlist");
    require(ISassySnakeEggs(ERC721_EGGS_CONTRACT).huntRewards(msg.sender) == 0, "Hunt: You must claim all your egg rewards to re-enlist from this address");
    require(!pauseAdd, "Hunt: Adding to the hunt is currently paused");    

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

  function setHuntDuration(uint256 duration) public onlyOwner {
    huntDuration = duration;
  }

  function setCommencementTimestamp(uint256 timestamp) public onlyOwner {
    commencementTimestamp = timestamp;
  }  

  function setPauseAdd(bool lock) public onlyOwner {
    pauseAdd = lock;
  }

  function getPauseAdd() public view onlyOwner returns (bool) {
    return pauseAdd;
  }

  function setPauseRemove(bool lock) public onlyOwner {
    pauseRemove = lock;
  }

  function getPauseRemove() public view onlyOwner returns (bool) {
    return pauseRemove;
  }  

  function setHuntWeek(uint256 week) public onlyOwner {
    huntWeek = week;
  }

  function _incrementNumberEnlisted() private {
    numberEnlisted += 1;
  }

  function _decrementNumberEnlisted() private {
    numberEnlisted -= 1;
  }

}