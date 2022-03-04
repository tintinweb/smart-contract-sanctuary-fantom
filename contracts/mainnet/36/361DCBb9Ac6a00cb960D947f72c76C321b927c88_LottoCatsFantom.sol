//SPDX-License-Identifier: MIT
/*
  ,,-,,        .'(  .-,.-.,-.    /(,-.     /`-.     .-./(     .-./(  
 /,--, \   ,') \  ) ) ,, ,. (  ,' _   )  ,' _  \  ,'     )  ,'     ) 
/ \  (  \ (  '/  /  \( |(  )/ (  '-' (  (  '-' ( (  .-, (  (  .-, (  
\  )  \ /  )     )     ) \     )  _   )  ) ,_ .'  ) '._\ )  ) '._\ ) 
 \ `--`(  (  .'\ \     \ (    (  '-' /  (  ' ) \ (  ,   (  (  ,   (  
  ``-`)/   )/   )/      )/     )/._.'    )/   )/  )/ ._.'   )/ ._.'  

https://twitter.com/0xtbroo
*/
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

import "./ERC2981PerTokenRoyalties.sol";
import "./Multisig.sol";

contract LottoCatsFantom is
    ERC721Enumerable,
    Ownable,
    Multisig(msg.sender),
    ERC2981PerTokenRoyalties
{
    using Strings for uint256;

    struct Winner {
        uint256 date;
        address winner;
        uint256 tokenId;
    }

    mapping(uint256 => address) private winner;

    string baseURI;
    string public baseExtension = ".json";
    string public pollName;
    uint256 public lotteryIntervalDays = 7;
    uint256 public epochDay = 86400;
    uint256 public cost = 99 ether;
    uint256 public maxSupply = 5000;
    uint256 public minSupplyLottery = 5000;
    uint256 public maxMintForTx = 10;
    uint256 public maxMintsForAddress = 10;
    uint256 private noFreeAddresses = 0;
    uint256 public drawNumber = 0;
    uint256 private contractRoyalties = 300;

    bool public paused = true;
    bool public lotteryActive = false;
    bool public airDropActive = false;
    bool public pollState = false;

    uint256[] public lotteryDates;
    address[] private airDropAddresses;
    string[] public pollOptions;

    mapping(string => bool) pollOptionsMap;
    mapping(string => uint256) public votes;
    mapping(address => bool) public whiteListAddresses;
    mapping(address => uint256) private addressMints;
    mapping(uint256 => Winner[]) public winnerLog;
    mapping(address => string) private votedAddresses;
    mapping(string => bool) private defaultpollOptions;
    mapping(address => uint256) private _winners;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    /*
    @function _baseURI()
    @description - Gets the current base URI for nft metadata
    @returns <string>
  */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981PerTokenRoyalties)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /*
    @function mint(_mintAmount)
    @description - Mints _mintAmount of NFTs for sender address.
    @param <uint256> _mintAmount - The number of NFTs to mint.
  */
    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        uint256 ownerCanMintCount = maxMintsForAddress -
            addressMints[msg.sender];

        require(
            ownerCanMintCount >= _mintAmount,
            "ERROR: You cant mint that many cats"
        );
        require(!paused, "ERROR: Contract paused. Please check discord.");
        require(
            _mintAmount <= maxMintForTx,
            "ERROR: The max no mints per transaction exceeded"
        );
        require(
            supply + _mintAmount <= maxSupply,
            "ERROR: Not enough cats left to mint!"
        );

        if (!whiteListAddresses[msg.sender]) {
            require(
                msg.value >= cost * _mintAmount,
                "ERROR: Please send more AVAX"
            );
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            uint256 tokenId = supply + 1;
            _safeMint(msg.sender, tokenId);
            _setTokenRoyalty(tokenId, owner(), contractRoyalties);

            addressMints[msg.sender]++;

            // activate lottery once all minted using lotteryIntervalDays
            if (tokenId >= minSupplyLottery && !lotteryActive) {
                activateLottery();
            }

            // This will have changes after a mint, so re-asign it
            supply = totalSupply();
        }
    }

    /*
    @function activateLottery(_owner)
    @description - Activates the lottery
    */
    function activateLottery() private {
        lotteryActive = true;
        lotteryDates.push(block.timestamp + (epochDay * lotteryIntervalDays));
        drawNumber++;
    }

    /*
    @function walletOfOwner(_owner)
    @description - Gets the list ok NFT tokenIds that owner has.
  */
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    /*
    @function tokenURL(tokenId)
    @description - Gets the metadata URI for a NFT tokenId
    @param <uint256> tokenId - The id ok the NFT token
    @returns <string> - The URI for the NFT metadata file
  */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    /*
    @function setCost(_newCost)
    @description - Sets the cost of a single NFT
    @param <uint256> _newCost - The cost of a single nft
  */
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    /*
    @function setMaxMintForTx
    @description - Sets the maximum mintable amount in 1 tx
    @param <uint256> amount - The number of mintable tokens in 1 tx
  */
    function setMaxMintForTx(uint256 amount) public onlySignatories {
        maxMintForTx = amount;
    }

    /*
    @function setMaxMintForAddress
    @description - Sets the maximum mintable amount for an address
    @param <uint256> amount - The number of mintable tokens in 1 tx
  */
    function setMaxMintForAddress(uint256 amount) public onlySignatories {
        maxMintsForAddress = amount;
    }

    /*
    @function setBaseURI(_newBaseURI)
    @description - Sets the base URI for the meta data files
    @param <string> _newBaseURI - The new base URI for the metadata files
  */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /*
    @function setBaseExtension(_newBaseExtension)
    @description - Sets the extension for the meta data file (default .json)
    @param <string> _newBaseExtension - The new file extension to use.
  */
    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    /*
    @function pause(_state)
    @description - Pauses the contract.
    @param <bool> _state - true/false
  */
    function pause(bool _state) public onlySignatories {
        paused = _state;
    }

    function setMinSupplyLottery(uint256 amount) public onlySignatories {
        minSupplyLottery = amount;
    }

    /*
    @function stakeToTime()
    @description - Sends contract balance to wallet for staking. Kept manual to prevent hacks.
    */
    function send_to_time() public payable onlySignatories {
        require(!paused, "ERROR: Contract paused!");
        require(isSignedTx(), "ERROR: Tx is not signed!");
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );

        resetSig();
        require(success);
    }

    /*
    @function selectWinner()
    @description - Selects a winner if the current date allows. Uses NFT id to select winner.
    @param <uint> no - The number of winners
    @returns <address> - The winner
    */
    function selectWinners(uint256 noOfWinners) public onlySignatories {
        require(!paused, "ERROR: Contract is paused");
        require(lotteryActive, "ERROR: Lottery not active yet");
        require(noOfWinners <= 50, "ERROR: Too many winners selected");

        uint256 epochNow = block.timestamp;
        uint256 nextLotteryDate = lotteryDates[lotteryDates.length - 1];

        require(
            epochNow >= nextLotteryDate,
            "ERROR: Cannot draw yet, too early"
        );

        for (uint256 i = 0; i < noOfWinners; i++) {
            selectAWinner(
                0,
                epochNow,
                msg.sender,
                nextLotteryDate,
                msg.sender,
                0
            );
        }

        lotteryDates.push(epochNow + (epochDay * lotteryIntervalDays));

        // increment draw
        drawNumber++;
    }

    /*
    @function selectAWinner()
    @description - Selects a winner and does not allow the same address to win more than once.
    @param <uint> no - The number of winners
    @returns <address> - The winner
    */
    function selectAWinner(
        uint256 it,
        uint256 epochNow,
        address sender,
        uint256 lotteryDate,
        address randomAddr,
        uint256 randomNo
    ) internal {
        // Generate random id between 1 - 5000 (corresponds to NFT id)

        uint256 winningToken = rand(randomAddr, randomNo);
        address winnerAddress = ERC721.ownerOf(winningToken);
        uint256 lastWon = _winners[winnerAddress];

        bool alreadyWon = (lastWon == lotteryDate);

        Winner memory win;

        if ((it < 5) && alreadyWon) {
            uint256 newIt = it + 1;
            return
                selectAWinner(
                    newIt,
                    epochNow,
                    sender,
                    lotteryDate,
                    winnerAddress,
                    winningToken
                );
        } else if ((it >= 5) && alreadyWon) {
            return;
        } else {
            win.date = lotteryDate;
            win.winner = winnerAddress;
            win.tokenId = winningToken;
            winnerLog[drawNumber].push(win);

            _winners[winnerAddress] = lotteryDate;
        }

        return;
    }

    function rand(address randomAddress, uint256 randomNo)
        internal
        view
        returns (uint256)
    {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    (block.timestamp - randomNo) +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(randomAddress)))) /
                            (block.timestamp)) +
                        block.number
                )
            )
        );

        return (seed - ((seed / maxSupply) * maxSupply)) + 1;
    }

    /*
    @function getRandomAddress()
    @description - Gets a random address
    @param <address> random address
    */
    function getRandomAddress() public view onlySignatories returns (address) {
        uint256 tokenId = rand(msg.sender, 0);
        return ownerOf(tokenId);
    }

    /*
    @function setLotteryState()
    @description - Sets the lottery state to active/not active (true/false)
    @param <address> state - The lottery state
    */
    function setLotteryState(bool state) public onlySignatories {
        lotteryActive = state;
    }

    /*
    @function setMaxSupply()
    @description - Sets the max supply that can be minted.
                   This will be useful if the project sells out super fast and
                   we want to add more mintable nfts.
    */
    function setMaxSupply(uint256 amount) public onlySignatories {
        require(
            amount > maxSupply,
            "ERROR: Max supply is currently smaller than new supply"
        );
        lotteryActive = false;
        maxSupply = amount;
    }

    /*
    @function removeFeesForAddress(addr)
    @description - Add an address to the freebie list
    @param <address> addr - The address to whitelist
    */
    function addToWhiteList(address addr) public onlySignatories {
        require(!paused, "ERROR: Contract paused!");
        require(
            noFreeAddresses < 10,
            "ERROR: MAX number of free addresses added"
        );
        whiteListAddresses[addr] = true;
        noFreeAddresses++;
    }

    /*
    @function setLotteryIntervalDays(noDays)
    @description - Set the number of days between each lottery draw.
    @param <uint256> noDays - The number of days.
    */
    function setLotteryIntervalDays(uint256 noDays) public onlySignatories {
        lotteryIntervalDays = noDays;
    }

    /*
    @function airDrop(to, amount)
    @description - Air drop an nft to address
    @param <address> to - The address to airdrop nft
    */
    function airDrop(address to) public onlySignatories {
        require(airDropActive, "ERROR: Air drop is not active");
        airDropAddresses.push(to);

        uint256 supply = totalSupply();
        uint256 tokenId = supply + 1;

        _safeMint(to, tokenId);
        (bool isContained, ) = containsSignatory(to);
        if (!isContained) {
            addressMints[to]++;
        }
    }

    /*
    @function setAirDropStatus(value)
    @description - Sets the status of airdrop to true/false
    @param <bool> value - true/false
    */
    function setAirDropStatus(bool value) public onlySignatories {
        airDropActive = value;
    }

    /*
    @function castVote(value)
    @description - Casts a vote if you own a cat
    @param <string> memory - The option chosen
    */
    function castVote(string memory option) public {
        require(!paused, "ERROR: Contract paused");
        require(pollState, "ERROR: No poll to vote on right now");
        require(pollOptionsMap[option], "ERROR: Invalid voting option");
        require(
            keccak256(abi.encodePacked(votedAddresses[msg.sender])) !=
                keccak256(abi.encodePacked(pollName)),
            "ERROR: You have already voted in this poll!"
        );

        uint256 noVotes = balanceOf(msg.sender);

        require(
            noVotes > 0,
            "ERROR: You have no voting rights. Get yourself a cat my fren!"
        );
        votes[option] += noVotes;
        votedAddresses[msg.sender] = pollName;
    }

    /*
    @function addPollOption(option)
    @description - Adds an option for voting
    @param <string> memory - The option to add
    */
    function addPollOption(string memory option) public onlySignatories {
        pollOptionsMap[option] = true;
        pollOptions.push(option);
    }

    /*
    @function clearPollOptions()
    @description - Clears the current poll
    */
    function clearPollOptions() public onlySignatories {
        for (uint256 i = 0; i < pollOptions.length; i++) {
            votes[pollOptions[i]] = 0;
            pollOptionsMap[pollOptions[i]] = false;
            delete pollOptions[i];
        }
    }

    /*
    @function setPollName(name)
    @description - Sets the poll name/quesstion
    @param <string> memory - The name/question of the poll
    */
    function setPollName(string memory name) public onlySignatories {
        pollName = name;
    }

    /*
    @function getVoteCountForOption(option)
    @description - Gets the number of votes for a poll option
    @param <string> memory - The option to get the poll counts for
    */
    function getVoteCountForOption(string memory option)
        public
        view
        returns (uint256)
    {
        return votes[option];
    }

    /*
    @function togglePollVoting(state)
    @description - Turns the poll on/off
    @param <string> memory - The value true/false
    */
    function setPollState(bool state) public onlySignatories {
        pollState = state;
    }

    /*
    @function getPollOptions(state)
    @description - returns the array of poll options
    */
    function getPollOptions() public view returns (string[] memory) {
        return pollOptions;
    }

    /*
    @function clearPoll()
    @description - clears poll, options and votes
    */
    function clearPoll() public onlySignatories {
        clearPollOptions();
        pollState = false;
        pollName = "";
    }

    /*
    @function isSignatory(addr)
    @description - checks if an address is a signatory
    @param <address> addr - The address to check
    */
    function getSignatories() public view returns (address[] memory) {
        return _signatoryAddresses;
    }

    /*
    @function getWinnersForDraw(drawNo)
    @description - Gets all the winners for a given draw
    */
    function getWinnersForDraw(uint256 drawNo)
        public
        view
        returns (Winner[] memory)
    {
        return winnerLog[drawNo];
    }

    /*
    @function clearWinnersForDraw(drawNo)
    @description - clears out all the winner logs for that draw. This is for when the array gets large!
    */
    function clearWinnersForDraw(uint256 drawNo) public onlyOwner {
        for (uint256 i = 0; i < 50; i++) {
            delete winnerLog[drawNo][i];
        }
    }

    /*
    @function noPollOptions()
    @description - Gets the current number of options for the poll
    */
    function noPollOptions() public view returns (uint256) {
        return pollOptions.length;
    }
}