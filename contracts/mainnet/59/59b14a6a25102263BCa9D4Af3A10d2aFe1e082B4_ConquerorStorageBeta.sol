/**
 *Submitted for verification at FtmScan.com on 2022-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract MjolnirRBAC {
    mapping(address => bool) internal _thors;

    modifier onlyThor() {
        require(
            _thors[msg.sender] == true || address(this) == msg.sender,
            "Caller cannot wield Mjolnir"
        );
        _;
    }

    function addThor(address _thor)
        external
        onlyOwner
    {
        _thors[_thor] = true;
    }

    function delThor(address _thor)
        external
        onlyOwner
    {
        delete _thors[_thor];
    }

    function disableThor(address _thor)
        external
        onlyOwner
    {
        _thors[_thor] = false;
    }

    function isThor(address _address)
        external
        view
        returns (bool allowed)
    {
        allowed = _thors[_address];
    }

    function toAsgard() external onlyThor {
        delete _thors[msg.sender];
    }
    //Oracle-Role
    mapping(address => bool) internal _oracles;

    modifier onlyOracle() {
        require(
            _oracles[msg.sender] == true || address(this) == msg.sender,
            "Caller is not the Oracle"
        );
        _;
    }

    function addOracle(address _oracle)
        external
        onlyOwner
    {
        _oracles[_oracle] = true;
    }

    function delOracle(address _oracle)
        external
        onlyOwner
    {
        delete _oracles[_oracle];
    }

    function disableOracle(address _oracle)
        external
        onlyOwner
    {
        _oracles[_oracle] = false;
    }

    function isOracle(address _address)
        external
        view
        returns (bool allowed)
    {
        allowed = _oracles[_address];
    }

    function relinquishOracle() external onlyOracle {
        delete _oracles[msg.sender];
    }
    //Ownable-Compatability
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    //contextCompatability
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ConquerorStorageBeta is MjolnirRBAC {

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

function pushPrice(string memory _country, uint256 Newprice) public onlyThor {
    countries[_country].price = Newprice;
}

function pushMessage(string memory _country, string memory Newmessage) public onlyThor {
    countries[_country].message = Newmessage;
}

function pushOwner(string memory _country, address NewOwner) public onlyThor {
    countries[_country].owner = NewOwner;
}

function pushID(string memory _country) public onlyThor {
    countries[_country].id = _country;
}

function pushTime(string memory _country, uint256 Newtime) public onlyThor {
    countries[_country].time = Newtime;
}

function pushHighest(uint256 value) external onlyThor {
	highest = value;
}

function fullSet(string memory _country, 
uint256 Newprice, 
string memory Newmessage, 
address NewOwner, 
uint256 Newtime)
external onlyThor {
pushPrice(_country,Newprice);
pushMessage(_country,Newmessage);
pushOwner(_country,NewOwner);
pushID(_country);
pushTime(_country,Newtime);
}

  function addPrice(string memory _country) external onlyThor {
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