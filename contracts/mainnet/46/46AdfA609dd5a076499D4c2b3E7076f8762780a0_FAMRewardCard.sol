/*
ஜ۩۞۩ஜ M̿͟͞a̿͟͞g̿͟͞i̿͟͞c̿͟͞ Reward Card ஜ۩۞۩ஜ
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol"; 
import "./IERC20.sol";
import "./Base64.sol";

contract FAMRewardCard is ERC721Enumerable, IERC721Receiver, Ownable {
    using Strings for uint256;

    //Card properties
    struct cardProperty {
        address cardOwner;
        uint256 balance;
        uint256 index;
        uint256 lastCollected;
    }

    //Per user address
    struct userHolding {
        uint256 tokenId;
        bool addressExits;
    }

    //FAM contracts, get IkthaMite based on #NFTs and weightX
    struct famContractsProperty {
        uint256 index;
        uint8 weight;
    }

    uint256 public mintCost = 3 ether;
    uint256 private ikthaMitePerFrequency = 1;
    uint256 public ikthaMiteCollectFrequencyInHours = 24;
    uint256 public totalIkthaMite;
    uint256[] private stakedCards; //All staked FAM Reward Card, one stake per user
    address[] private famContracts; //FAM projects NTS that are required to earn points

    mapping(address => famContractsProperty) private famContractsType;
    mapping(uint256 => cardProperty) private rewardCard; //Per each FAM Reward Card
    mapping(address => userHolding) private userStatus; //To keep track of user address

    event IkthaMiteTransfered( uint256 indexed fromTokenId,uint256 indexed toTokenId, uint256 amount);
    event FAMRewardStaked(uint256 indexed tokenId);
    event FAMRewardUnstaked(uint256 indexed tokenId);


    constructor() ERC721("FAM Reward Card", "FAMRC") {
        mint(2); //Mint 2 cards, #1 for rewards, social activities, #2 for games
        rewardCard[1].balance = 10000;
        rewardCard[2].balance = 10000;
        totalIkthaMite=20000;
    }

    //************* Read Functions *************

    function getCardStatus(uint256 _tokenId) public view returns (uint256 balance, string memory nextCollection, uint256 pointsToCollect)
    {
        require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
        if (address(this) != ownerOf(_tokenId)) {
            nextCollection="Card is not staked";
            pointsToCollect=0;
        }else{
            uint256 inHours=(uint256(block.timestamp)-rewardCard[_tokenId].lastCollected)/3600;
            if(inHours>=ikthaMiteCollectFrequencyInHours){
                nextCollection="Ready to collect";
            }else{
                inHours=ikthaMiteCollectFrequencyInHours-inHours;
                nextCollection = toString(inHours);
                nextCollection = string(abi.encodePacked("In ", nextCollection, " hours"));
            }
            pointsToCollect=calculateUserIkthaMite(rewardCard[_tokenId].cardOwner);
        }
        balance=rewardCard[_tokenId].balance;
        
    }

    function getStakedCard(address _address) public view returns (uint256 cardId)
    {
        return userStatus[_address].tokenId;
    }

    function getFamContracts() public view returns (address[] memory)
    {
       return famContracts;
    }

    function getWeight(address _famContract) public view returns (uint8 weight)
    {
        return (famContractsType[_famContract].weight);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory)
    {
        require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
        string memory output;
        string[7] memory item;

        item[0] = '<svg xmlns="http://www.w3.org/2000/svg" xml:space="preserve" viewBox="0 0 400 600">';

        item[1] = '<defs><linearGradient id="grad2" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="0%" style="stop-color:rgb(255,255,0);stop-opacity:0.5" /><stop offset="100%" style="stop-color:rgb(103, 62, 184);stop-opacity:0.9" /></linearGradient> <style>@import url("https://fonts.googleapis.com/css?family=Berkshire Swash:400,400i,700,700i")</style></defs>';

        item[2] = '<rect x="20" y="20" rx="20" ry="20" width="360" height="560" style="fill:url(#grad2);stroke:black;stroke-width:3" /><rect x="60" y="120" width="280" height="100" style="fill:#8e4bc9;stroke:black;stroke-width:3;fill-opacity:0.3;stroke-opacity:0.4" /> <rect x="40" y="50" rx="20" ry="20" width="320" height="500" style="fill:none;stroke:black;stroke-width:5;stroke-opacity:0.5" /> <rect x="60" y="300" width="280" height="180" style="fill:none;stroke:black;stroke-width:3;stroke-opacity:0.4" /> <line x1="60" y1="330" x2="340" y2="330" style="stroke:rgb(0,0,0);stroke-width:2;stroke-opacity:0.4" />';

        item[3] =  string(
            abi.encodePacked(
                '<rect x="60" y="300" width="280" height="180" style="fill:none;stroke:black;stroke-width:3;stroke-opacity:0.4" /> line x1="60" y1="330" x2="340" y2="330" style="stroke:rgb(0,0,0);stroke-width:2;stroke-opacity:0.4" /><text fill="#000000" font-size="30" font-family="Berkshire Swash" text-anchor="middle" x="200" y="90">FAM Reward Card<tspan font-size="15" text-anchor="middle" x="200" y="40">Fantom Academy of Magic</tspan><tspan font-size="25" text-anchor="middle" x="200" y="290">Card Stats #',
                toString(_tokenId),
                 ' </tspan>'
            )
        );

        item[4] = string(
            abi.encodePacked(
                '<tspan font-size="25" text-anchor="middle" x="200" y="150">Iktha-mite</tspan><tspan font-size="25" text-anchor="middle" x="200" y="200">',
                toString(rewardCard[_tokenId].balance),
                '</tspan>'
            )
        );


        //If Reward card is not staked, don't display cards stats
        if (address(this) == ownerOf(_tokenId)) {
            item[5] = '<tspan font-size="15" x="105" y="320">Contracts</tspan><tspan font-size="15" x="250" y="320"># NFTs</tspan><tspan font-size="15" x="310" y="320">Weight</tspan>';
            uint256 _mitePerFrequency=calculateUserIkthaMite(rewardCard[_tokenId].cardOwner);
            uint256 _yAxis = 350;
                
            for (uint8 i = 0; i < famContracts.length; i++) {
                uint256 _userNFTBalance = (IERC721(famContracts[i]).balanceOf(rewardCard[_tokenId].cardOwner));
                bytes memory bstr = new bytes(10);
                bstr[0]="1";
                item[5] = string(
                    abi.encodePacked(
                        item[5],
                        '<tspan font-family="Trebuchet MS" font-size="15" x="130" y="',toString(_yAxis),'">',
                        ERC721(famContracts[i]).name(),
                        "</tspan>",
                        '<tspan font-family="Trebuchet MS" font-size="15" x="250" y="',toString(_yAxis),'">',
                        toString(_userNFTBalance),
                        "</tspan>"
                    )
                );
                //Have to split to avoid "CompilerError: Stack too deep when compiling inline assembly: Variable pos is 2 slot(s) too deep inside the stack"
                item[5] = string(
                    abi.encodePacked(
                        item[5],
                        '<tspan font-family="Trebuchet MS" font-size="15" x="310" y="',toString(_yAxis),'">',
                        toString(famContractsType[famContracts[i]].weight),
                        "</tspan>"
                    )
                );
                _yAxis+=30;
            }

            item[5] = string(
                abi.encodePacked(
                    item[5],
                    '<tspan text-anchor="middle" font-size="15" x="200" y="520">Total Iktha-mite earn per ',
                    toString(ikthaMiteCollectFrequencyInHours),
                    ' hours:  ',
                    toString(_mitePerFrequency),
                    "</tspan>"
                )
            );
        } else {
            item[5] = '<tspan fill="#FF0000" font-size="30" text-anchor="middle" x="200" y="390">Card Not Staked</tspan>';
        }

        item[6] = "</text></svg>";

        output = string(abi.encodePacked(item[0],item[1],item[2],item[3],item[4],item[5],item[6]));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "FAM Reward Card #',toString(_tokenId),
                        '", "description": "FAM Reward Card lets you collect Iktha-mite by mining Iktha ore that is beneath the Academy Ground. Those who have been enrolled in Academy as Apprentice has mining rights and they collect Iktha-mite (a precious GEM) shown in Iktha-mite Card.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));
        return output;
    }

    //************* Write Functions *************

    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        if (msg.sender != owner()) {
            //Make sure caller's MM has FAM Project NFTs
            checkFamHolder();
            require(msg.value >= mintCost * _mintAmount, "Not enough FTM");
        }
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function transferIkthaMite(uint256 _fromTokenId,uint16 _toTokenId,uint256 _ikthaMite) public {
        require (_ikthaMite>0, "Need more than 0");
        require(msg.sender == ownerOf(_fromTokenId) ||msg.sender == rewardCard[_fromTokenId].cardOwner,"Address is not owner of FAM Reward Card");
        require(_ikthaMite<=rewardCard[_fromTokenId].balance, "Balance is not enough");
        rewardCard[_fromTokenId].balance -= _ikthaMite;
        rewardCard[_toTokenId].balance += _ikthaMite;
        emit IkthaMiteTransfered(_fromTokenId, _toTokenId, _ikthaMite);
    }

    //Stake FAM Reward Card to get IkthaMite (Points)
    function stakeRewardCard(uint256 _tokenId) public {
        //Make sure caller's MM has FAM Proejcts NFTs
        checkFamHolder();
        //Only one FAMR Card stake per address
        require(!(userStatus[msg.sender].addressExits),"One Reward Card per address");
        safeTransferFrom(msg.sender, address(this), _tokenId);
        stakedCards.push(_tokenId);
        rewardCard[_tokenId].cardOwner = msg.sender;
        rewardCard[_tokenId].lastCollected=block.timestamp;
        rewardCard[_tokenId].index = stakedCards.length - 1;
        userStatus[msg.sender].tokenId = _tokenId;
        userStatus[msg.sender].addressExits = true;
        emit FAMRewardStaked(_tokenId);
    }

    //Unstake FAM Reward Card, it won't get IkthaMite anymore
    function unstakeRewardCard(uint256 _tokenId) public {
        require(msg.sender == rewardCard[_tokenId].cardOwner && address(this) == ownerOf(_tokenId),"Address is not owner of FAM Reward Card or not staked");
        _transfer(address(this), msg.sender, _tokenId);
        uint256 indexRemovedCard = rewardCard[_tokenId].index;
        uint256 lastIndex = stakedCards.length - 1;
        stakedCards[indexRemovedCard] = stakedCards[lastIndex];
        rewardCard[stakedCards[lastIndex]].index = lastIndex;
        stakedCards.pop();
        userStatus[msg.sender].addressExits = false;
        emit FAMRewardUnstaked(_tokenId);
    }

    function collectIkthaMite() public {
        require(userStatus[msg.sender].addressExits,"No staked Reward card found");
        checkFamHolder();
        uint256 _tokenId = userStatus[msg.sender].tokenId;
        uint256 lastCollected = rewardCard[_tokenId].lastCollected;
        //Make sure user can only collect every defined in frequency hours
        require( block.timestamp>= lastCollected + (ikthaMiteCollectFrequencyInHours*3600),"Only collect per frequency hours");
        uint256 _totalIkthaMiteEarned=calculateUserIkthaMite(msg.sender);
        totalIkthaMite += _totalIkthaMiteEarned;
        rewardCard[_tokenId].balance += _totalIkthaMiteEarned;
        rewardCard[_tokenId].lastCollected = block.timestamp;
    }

    //************* Only owner *************

    // Set FAM (NFT) contract.
    function addFamContracts(address _contract, uint8 _weightX) public onlyOwner
    {
        require(_weightX > 0, "Weight can't be 0");
        famContracts.push(_contract);
        famContractsType[_contract].index = famContracts.length - 1;
        famContractsType[_contract].weight = _weightX;
    }

    function removeFamContracts(address _contract) public onlyOwner {
        uint256 indexRemovedCard = famContractsType[_contract].index;
        uint256 lastIndex = famContracts.length - 1;
        famContracts[indexRemovedCard] = famContracts[lastIndex];
        famContractsType[_contract].index = lastIndex;
        famContracts.pop();
    }

    //WEI format
    function setMintCost(uint256 _newMintCost) public onlyOwner {
        mintCost = _newMintCost;
    }

    //whole number
    function setIkthaMitePerFrequency(uint256 _newRate) public onlyOwner {
        ikthaMitePerFrequency = _newRate;
    }

    //In hours (whole number)
    function setFrequencyOfIkthaMiteCollect(uint256 _newFrequencyInHours) public onlyOwner{
        ikthaMiteCollectFrequencyInHours=_newFrequencyInHours;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    //************* Supporting fucntions *************

    //Calculate user's per day IkthaMite earning
    function calculateUserIkthaMite(address _userAddress) internal view returns (uint256 _totalIkthaMiteEarned) {
        //Check weight and #NFT holding
        for (uint8 i = 0; i < famContracts.length; i++) {
            uint256 userNFTBalance = (IERC721(famContracts[i]).balanceOf(_userAddress));
            uint256 _multiplier;
            if(userNFTBalance<1){
                _multiplier=0;
            }else if(userNFTBalance<3){
                _multiplier=1;
            }else if(userNFTBalance<6){
                _multiplier=2;
            }else if (userNFTBalance<10){
                _multiplier=3;
            }else{
                _multiplier=4;
            }
            _totalIkthaMiteEarned +=ikthaMitePerFrequency * _multiplier * (famContractsType[famContracts[i]].weight);
        }
    }

    // Checks FAM project contracts in user's wallet
    function checkFamHolder() internal view {
        require(famContracts.length > 0, "FAM NFT hasn't been added yet");
        bool isHolder;
        for (uint8 i = 0; i < famContracts.length; i++) {
            if (IERC721(famContracts[i]).balanceOf(msg.sender) >= 1) {
                isHolder = true;
                break;
            } else {
                isHolder = false;
            }
        }
        require(isHolder, "Need FAM project Holder");
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function onERC721Received(address,address,uint256,bytes calldata) public view override returns (bytes4) {
        return IERC721Receiver(this).onERC721Received.selector;
    }
}