/**
 *Submitted for verification at FtmScan.com on 2022-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IConqStorage {

	function pushPrice(string memory country, uint256 value) external;
	function pushMessage(string memory country, string memory message) external;
	function pushOwner(string memory country, address value) external;
	function pushID(string memory country) external;
	function pushTime(string memory country, uint256 value) external;
	function pushHighest(uint256 value) external;
    function fullSet(string memory country, uint256 price, string memory message, address owner, uint256 time) external;
	function addPrice(string memory country) external;
	function getHighestPrice() external view returns (uint256);
	function getCountryOwner(string memory country) external view returns (address);
	function getValueOfCountry(string memory country) external view returns (uint256);
	function getTime(string memory country) external view returns (uint256);
	function getID(string memory country) external view returns (string memory);
	
}

interface IitemLogic {
	
	function mintOffensive(address account) external;
	function mintDefensive(address account) external;
	function batchOffensive(address account) external;
	function batchDefensive(address account) external;
	function tradeWarMonger(uint256 item) external;
	function fullRangeRoll(address account) external;
}

interface ICHAMPION {

	function ownerOf(uint256 tokenId) external view returns (address owner);

    function totalSupply() external view returns (uint256);
}

interface ICHAMPLOGIC {

    function forgeChampion(address account) external;

    function nameChampion(uint256 id, string memory newName) external;

    function setBio(uint256 id, string memory newName) external;

}

interface I1155TRANS {

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

interface IRNDM {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
	function burn(uint256 amount) external;
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
  function _msgSender() internal view virtual returns(address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns(bytes memory) {
    this;
    return msg.data;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns(address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract ConquerorV2BETA is Context, Ownable {

//vars
	address public store = 0xe1b908cA84394F2D70A954ad46992d6e21Aed4dE;
	address private devW = 0x564e9155Ff9268B4B7dA4F7b5fCa000Ea0f46Ebb;
	address private rndm = 0x87d57F92852D7357Cf32Ac4F6952204f2B0c1A27;
	address public gameItems = 0xc05D8ec7e97a9d8450CF7C161c70A1D8860E5D2E;
	address public champBase = 0xc755D314359b8771C8853aca5C95908CD472327c;
    address public champLogic = 0xc755D314359b8771C8853aca5C95908CD472327c;
	address public itemBase = 0x45EB792b91aABE60bAa85c42b46E51E3239A0Ef6;
    IConqStorage db = IConqStorage(store);
    IitemLogic items = IitemLogic(gameItems);
    IRNDM tokenContract = IRNDM(rndm);
	uint256 public feeStep = 10000000000000000;
	uint256 public startStep = 12000000000000000;
	uint256 public attackMul = 10;
	uint256 public assistMul = 5;
	uint256 public tokenPrice = 1000;
	uint256 public feeBalance = 0;
    uint256 public warMongerPrice = 1000 * 1e18;

//PUBLIC
  function buyCountry(string memory _country, string memory _message) external payable {
    require(bytes(_message).length <= 140, "Message must be under 140 characters");
    if (db.getValueOfCountry(_country) > 0) {
      require(msg.value == db.getValueOfCountry(_country), "Too much money sent");
      uint256 transferAmount = db.getValueOfCountry(_country);
      payable(db.getCountryOwner(_country)).transfer(transferAmount*(110)/(120));
      uint256 feeAmount = db.getValueOfCountry(_country);
      feeBalance = feeBalance+(feeAmount*(10)/(120));
    } else {
      require(msg.value == feeStep, "Not enough sent");
      if(db.getCountryOwner(_country) != 0x0000000000000000000000000000000000000000) {
	  items.fullRangeRoll(db.getCountryOwner(_country));
      }
      feeBalance = feeBalance+(feeStep);
    }
    db.addPrice(_country);
    db.fullSet(_country, msg.value*(120)/(100), _message, msg.sender, block.timestamp);
    if (db.getValueOfCountry(_country) > db.getHighestPrice()) {
    db.pushHighest(db.getValueOfCountry(_country));
    }
	items.batchOffensive(msg.sender);
  }

  function hijackMessage(string memory _country,string memory _message) external {
    timeCheck(_country);
    require(db.getCountryOwner(_country) != 0x0000000000000000000000000000000000000000);
    require(tokenContract.transferFrom(
        msg.sender,
        address(this),
        tokenPrice
        ) == true,
        'Could not transfer tokens'
        );
	db.pushMessage(_country, _message);
	items.fullRangeRoll(msg.sender);
  }

  function attack(string memory _country) external {
    timeCheck(_country);
    require(db.getCountryOwner(_country) != 0x0000000000000000000000000000000000000000);
    require(db.getValueOfCountry(_country) > startStep);
	require(tokenContract.transferFrom(
        msg.sender,
        address(this),
        db.getValueOfCountry(_country) * attackMul
        ) == true,
        'Could not transfer tokens from your address to this contract'
        );
	  db.pushPrice(_country, db.getValueOfCountry(_country) - startStep);
	  items.mintOffensive(msg.sender);
	  items.mintDefensive(db.getCountryOwner(_country));
 }	  

  function assist(string memory _country) external {
    timeCheck(_country);
    require(db.getCountryOwner(_country) != 0x0000000000000000000000000000000000000000);
  	require(tokenContract.transferFrom(
        msg.sender,
        address(this),
        db.getValueOfCountry(_country) * assistMul
        ) == true,
        'Could not transfer tokens from your address to this contract'
        );
	  db.pushPrice(_country, db.getValueOfCountry(_country) + startStep);
	  items.mintDefensive(msg.sender);
	  items.mintOffensive(db.getCountryOwner(_country));
	  
 }

    function becomeGrandChampion() external {
    ICHAMPLOGIC champ = ICHAMPLOGIC(champLogic);
    senditems();
    champ.forgeChampion(msg.sender);
 }

  function timeCheck(string memory _country) public {
      if (db.getValueOfCountry(_country) > startStep + startStep) {
      timeCheckUtils(_country);
      }
  }

  function timeCheckUtils(string memory _country) internal {
    if (block.timestamp > db.getTime(_country) + (60*60*24*7)) {
            db.pushPrice(_country, db.getValueOfCountry(_country) - startStep);
            db.pushTime(_country, block.timestamp);    
    }
  }

  function withdrawAdmin() external onlyOwner {
    payable(owner()).transfer(feeBalance);
    feeBalance = 0;
  }
  
  function GrandReward() external payable {
	ICHAMPION champ = ICHAMPION(champBase);
	require(champ.ownerOf(champ.totalSupply()) == msg.sender);
    (bool hs, ) = payable(msg.sender).call{value: feeBalance * 5 / 100}("");
    require(hs);    
    (bool os, ) = payable(owner()).call{value: feeBalance}("");
    require(os);
    feeBalance = 0;
  }

  function senditems() internal {
        I1155TRANS ib = I1155TRANS(itemBase);
        uint8 totalIdAmount = 50;
        uint256[] memory iL = new uint256[](totalIdAmount);
        uint256[] memory iQ = new uint256[](totalIdAmount);
        for (uint256 i = 0; i < totalIdAmount; i++) {
            iL[i] = i + 1;
            iQ[i] = 1;
        }
        ib.safeBatchTransferFrom(msg.sender, devW, iL, iQ, "");
    }

//GETS

  function getBalance() public view returns(uint256) {
    return feeBalance;
  }

//ADMIN
  function giveCountry(uint256 value, string memory _country, address _target, string memory _message) external onlyOwner {
    db.pushPrice(_country, value);
    db.pushOwner(_country, _target);
    db.pushMessage(_country, _message);
  }
  
  function resetCountryAdmin(string memory _country, address _target, string memory _message) external onlyOwner {
    db.pushPrice(_country, startStep);
    db.pushOwner(_country, _target);
    db.pushMessage(_country, _message);
    db.addPrice(_country);
  }

  function adminDepo(uint256 amount) external onlyOwner {
    require(tokenContract.transferFrom(
        msg.sender,
        address(this),
        amount
        ) == true,
        'Could not transfer tokens from your address to this contract'
        );
    }

  function adminWithdraw(uint256 amount) external onlyOwner {
    require(tokenContract.transfer(
        msg.sender,
        amount
        ) == true,
        'Could not transfer tokens to your address from this contract'
        );
    }

  function warMonger(uint256 item) external {
    require(tokenContract.transferFrom(
        msg.sender,
        address(this),
        warMongerPrice
        ) == true,
        'Could not transfer tokens to your address from this contract'
        );
      items.tradeWarMonger(item);
  }

  function rndmBalance() public view returns (uint256) {
     return tokenContract.balanceOf(address(this));
  }
  function currentChampion() public view returns(address) {
  ICHAMPION champ = ICHAMPION(champBase);
    return champ.ownerOf(champ.totalSupply());
  }
  function currentChampID() public view returns(uint256) {
  ICHAMPION champ = ICHAMPION(champBase);
    return champ.totalSupply();
  }

  function setStore(address value) external onlyOwner {
	  store = value;
  }
  function setDevW(address value) external onlyOwner {
      devW = value;
  }
  function setToken(address value) external onlyOwner {
      rndm = value;
  }
  function setItems1155(address value) external onlyOwner {
      gameItems = value;
  }
  function setChamp721(address value) external onlyOwner {
      champBase = value;
  }
  function setChampLogic(address value) external onlyOwner {
      champLogic = value;
  }
  function setFeeStep(uint256 value) external onlyOwner {
      feeStep = value;
  }
  function setStartStep(uint256 value) external onlyOwner {
      startStep = value;
  }
  function setAttackMul(uint256 value) external onlyOwner {
      attackMul = value;
  }
  function setAssistMul(uint256 value) external onlyOwner {
      assistMul = value;
  }
  function setTokenPrice(uint256 value) external onlyOwner {
      tokenPrice = value;
  }
  function setWarMongerPrice(uint256 value) external onlyOwner {
	  warMongerPrice = value;
  }
}