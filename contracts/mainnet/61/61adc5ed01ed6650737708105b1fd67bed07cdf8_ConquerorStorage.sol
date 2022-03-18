/**
 *Submitted for verification at FtmScan.com on 2022-03-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


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

abstract contract Controllable is Ownable {
    mapping(address => bool) internal _controllers;

    modifier onlyController() {
        require(
            _controllers[msg.sender] == true || address(this) == msg.sender,
            "Controllable: caller is not a controller"
        );
        _;
    }

    function addController(address _controller)
        external
        onlyOwner
    {
        _controllers[_controller] = true;
    }

    function delController(address _controller)
        external
        onlyOwner
    {
        delete _controllers[_controller];
    }

    function disableController(address _controller)
        external
        onlyOwner
    {
        _controllers[_controller] = false;
    }

    function isController(address _address)
        external
        view
        returns (bool allowed)
    {
        allowed = _controllers[_address];
    }

    function relinquishControl() external onlyController {
        delete _controllers[msg.sender];
    }
}

contract ConquerorStorage is Controllable {

  struct Country {
    uint256 price;
    uint256 time;
    string message;
    string id;
    address owner;
  }

  mapping(string => Country) countries;

  struct leaderboardCountry {
    uint256 price;
    string country;
  }

  leaderboardCountry[5] topCountriesPrice;

  uint256 highest;

  constructor(){
    topCountriesPrice[0].country = "N/A";
    topCountriesPrice[1].country = "N/A";
    topCountriesPrice[2].country = "N/A";
    topCountriesPrice[3].country = "N/A";
    topCountriesPrice[4].country = "N/A";
  }
//SETS

function pushPrice(string memory _country, uint256 Newprice) public onlyController {
    countries[_country].price = Newprice;
}

function pushMessage(string memory _country, string memory Newmessage) public onlyController {
    countries[_country].message = Newmessage;
}

function pushOwner(string memory _country, address NewOwner) public onlyController {
    countries[_country].owner = NewOwner;
}

function pushID(string memory _country) public onlyController {
    countries[_country].id = _country;
}

function pushTime(string memory _country, uint256 Newtime) public onlyController {
    countries[_country].time = Newtime;
}

function fullSet(string memory _country, 
uint256 Newprice, 
string memory Newmessage, 
address NewOwner, 
uint256 Newtime)
external onlyController {
pushPrice(_country,Newprice);
pushMessage(_country,Newmessage);
pushOwner(_country,NewOwner);
pushID(_country);
pushTime(_country,Newtime);
}

  function addPrice(string memory _country) internal {
    uint listingNr = 0;
    for (uint i = 4; i > 0; i--) {
      string memory otherCountry = topCountriesPrice[i].country;
      if (compareStrings(otherCountry, _country)) {
        listingNr = i;
        break;
      }
    }

    uint256 price = countries[_country].price;
    for (uint i = 4; i > 0; i--) {
      if (price > topCountriesPrice[i].price ) {
        leaderboardCountry memory info;
        info.price = price;
        info.country = _country;
        topCountriesPrice[listingNr] = info;

        bool swapped;
        uint k;
        uint j;
        uint n = topCountriesPrice.length;
        for (k = 0; k < n - 1; k++) {
          swapped = false;
          for (j = 0; j < n - k - 1; j++) {
            if (topCountriesPrice[j].price > topCountriesPrice[j + 1].price) {
              (topCountriesPrice[j].price, topCountriesPrice[j + 1].price) = (topCountriesPrice[j + 1].price, topCountriesPrice[j].price);
              string memory nextCountry = topCountriesPrice[j + 1].country;
              topCountriesPrice[j + 1].country = topCountriesPrice[j].country;
              topCountriesPrice[j].country = nextCountry;
              swapped = true;
            }
          }
          if (swapped == false) break;
        }

        return;
      }
    }
  }

//GETS
 
  function compareStrings(string memory a, string memory b) public pure returns(bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }
  function getTopCountriesPrices() public view returns(leaderboardCountry[5] memory) {
    return topCountriesPrice;
  }
  function getMessage(string memory _country) public view returns(string memory) {
    return countries[_country].message;
  }
  function getHighestPrice() public view returns(uint256) {
    return highest;
  }
  function getCountryOwner(string memory _country) public view returns(address) {
    return countries[_country].owner;
  }
  function getValueOfCountry(string memory _country) public view returns(uint256) {
    return countries[_country].price;
  }
  function getTime(string memory _country) public view returns(uint256) {
	return countries[_country].time;
  }
  function getID(string memory _country) public view returns(string memory) {
	return countries[_country].id;
}
}