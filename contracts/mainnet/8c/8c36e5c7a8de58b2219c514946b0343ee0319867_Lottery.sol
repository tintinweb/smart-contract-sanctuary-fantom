/**
 *Submitted for verification at FtmScan.com on 2022-03-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IRandomNumberOracle {
    event RandomNumberRequested(
        uint256 indexed requestId,
        uint8 nums,
        uint256 min,
        uint256 max
    );
    event RandomNumberAdded(uint256 indexed requestId);

    function getRandomNumbers(uint256 requestId)
        external
        view
        returns (uint256[] memory);
}

contract Lottery is Ownable {
    struct JackpotInfo {
        uint256 prizePool;
        address winner;
        uint256 started_ts;
        uint256 ended_ts;
        uint256 winnerPrize;
        bool withdrawn;
    }
    // current jackpot index, actually the total number of jackpots so far
    uint256 public currentJackpot;

    // if a jackpot in ongoing at the moment
    bool public ongoing;

    // All jackpots information
    mapping(uint256 => JackpotInfo) jackpots;

    // Amounts of all addresses that have been betting in each jackpot
    mapping(uint256 => mapping(address => uint256)) public entryAmounts;

    // The participants of each jackpot
    mapping(uint256 => address[]) participants;

    // min and max betting amounts
    uint256 public minimumInPerDeposit;
    uint256 public maximumInPerDraw;

    // integer fee percent
    uint256 public fee;
    address public feeAddress;

    event JackPotStart(uint256 indexed jackpotId);
    event JackPotEnd(uint256 indexed jackpotId);
    event EntryBuy(uint256 indexed jackpotId, address indexed user, uint256 amount);

    // random number oracle address
    IRandomNumberOracle internal randomOracle;

    function setAmountLimit(uint256 _minimumIn, uint256 _maximumIn)
        external
        onlyOwner
    {
        require(_minimumIn < _maximumIn, "invalid args");
        minimumInPerDeposit = _minimumIn;
        maximumInPerDraw = _maximumIn;
    }

    function setFee(uint256 _fee, address _feeAddress) external onlyOwner {
        require(_feeAddress != address(0), "zero address");
        fee = _fee;
        feeAddress = _feeAddress;
    }

    function setOracleAddress(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "invalid address");
        randomOracle = IRandomNumberOracle(_oracleAddress);
    }

    function startJackpot() external onlyOwner returns (uint256) {
        require(!ongoing, "already ongoing");

        currentJackpot = currentJackpot + 1;
        jackpots[currentJackpot] = JackpotInfo(
            0,
            address(0),
            block.timestamp,
            0,
            0,
            false
        );
        ongoing = true;

        emit JackPotStart(currentJackpot);

        return currentJackpot;
    }

    function selectWinner(uint256 randomNumber) private view returns (address) {
        uint256 runningTotal = 0;
        uint256[] memory totals = new uint256[](
            participants[currentJackpot].length
        );

        for (uint256 i = 0; i < totals.length; i++) {
            address participant = participants[currentJackpot][i];
            uint256 amountIn = entryAmounts[currentJackpot][participant];
            runningTotal += amountIn;
            totals[i] = runningTotal;
        }
        uint256 rnd = (randomNumber * runningTotal) / 100;

        for (uint256 i = 0; i < totals.length; i++) {
            if (rnd < totals[i]) {
                return participants[currentJackpot][i];
            }
        }
        return address(0);
    }

    function endJackpot(uint256 randomRequestId)
        external
        onlyOwner
        returns (address)
    {
        require(ongoing, "not started");

        uint256 prize = jackpots[currentJackpot].prizePool;
        uint256 feeAmount = (prize * fee) / 100;
        uint256 winnerPrize = prize - feeAmount;

        uint256[] memory randoms = randomOracle.getRandomNumbers(
            randomRequestId
        );
        uint256 randomNumber = randoms[0];
        address winner = selectWinner(randomNumber);

        jackpots[currentJackpot].winnerPrize = winnerPrize;
        jackpots[currentJackpot].ended_ts = block.timestamp;
        jackpots[currentJackpot].winner = winner;

        payable(feeAddress).transfer(feeAmount);

        ongoing = false;

        emit JackPotEnd(currentJackpot);

        return winner;
    }

    function buyEntry() external payable {
        require(ongoing, "not started yet");
        require(msg.value > minimumInPerDeposit, "less than minimum");

        uint256 currentEntryAmount = entryAmounts[currentJackpot][msg.sender];
        uint256 amount = currentEntryAmount + msg.value;

        require(amount <= maximumInPerDraw, "exceeds maximum");

        if (currentEntryAmount == 0) {
            participants[currentJackpot].push(msg.sender);
        }

        entryAmounts[currentJackpot][msg.sender] = amount;
        jackpots[currentJackpot].prizePool += msg.value;

        emit EntryBuy(currentJackpot, msg.sender, msg.value);
    }

    function withdrawPrize(uint256 jackpotId) external {
        require(jackpotId < currentJackpot, "invalid jackpot id");
        require(
            msg.sender == jackpots[jackpotId].winner,
            "you are not the winner"
        );
        require(!jackpots[jackpotId].withdrawn, "already claimed");

        payable(msg.sender).transfer(jackpots[jackpotId].winnerPrize);
        jackpots[jackpotId].withdrawn = true;
    }

    function getParticipants(uint256 jackpotId)
        external
        view
        onlyOwner
        returns (address[] memory)
    {
        return participants[jackpotId];
    }
}