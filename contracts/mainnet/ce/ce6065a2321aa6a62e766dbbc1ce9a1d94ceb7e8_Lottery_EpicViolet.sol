/**
 *Submitted for verification at FtmScan.com on 2022-12-17
*/

// SPDX-License-Identifier: MIT
////////////////////////////////////////////////////////////
/////// The smart contract was developed by Magalico ///////
/////// EPICVIOLET.COM ////////  PROTOCOL AGREGGATOR ///////
//////////////////////////////////////////////////////////// 

pragma solidity 0.8.0;

contract Lottery_EpicViolet {
    //NO REENTRANT --SECURITY VAR`S--
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    modifier isOperator() {
        require((msg.sender == lotteryOperator),"Caller is not the lottery operator");
        _;
    }    

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;

        _;
        _status = _NOT_ENTERED;
    }

    modifier isWinner() {
        require(IsWinner(), "Caller is not a winner");
        _;
    }

    uint256 public constant ticketPrice = 1 ether; // 1 FTM
    uint256 public constant maxTickets = 100; // maximum tickets per lottery
    uint256 public constant ticketCommission = 0.1 ether; // commition per ticket --- 10%

    address public lotteryOperator; // the crator of the lottery
    uint256 public operatorTotalCommission = 0; // the total commission balance
    address public lastWinner; // the last winner of the lottery
    uint256 public lastWinnerAmount; // the last winner amount of the lottery

    uint256 public currentRound = 1;

    mapping(address => uint256) public winnings; // maps the winners to there winnings
    address[] public tickets; //array of purchased Tickets

    

    constructor() {
        lotteryOperator = msg.sender;
        _status = _NOT_ENTERED;
    }

    function getTickets() public view returns (address[] memory) {
        return tickets;
    }

    function getWinningsForAddress(address addr) public view returns (uint256) {
        return winnings[addr];
    }

    function BuyTickets() public payable notContract nonReentrant {
        require((msg.value % ticketPrice == 0), "the value must be multiple of ");        
        uint256 numOfTicketsToBuy = msg.value / ticketPrice;
        require(numOfTicketsToBuy <= RemainingTickets(),"Not enough tickets available.");        

        for (uint256 i = 0; i < numOfTicketsToBuy; i++) {
            tickets.push(msg.sender);
        }
        
        if(tickets.length >= maxTickets){
            DrawWinnerTicket();
        }
    }

    function DrawWinnerTicket() internal {
        require(tickets.length > 0);

        bytes32 blockHash = blockhash(block.number - tickets.length);
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, blockHash))
        );
        uint256 winningTicket = randomNumber % tickets.length;

        address winner = tickets[winningTicket];
        lastWinner = winner;
        winnings[winner] += (tickets.length * (ticketPrice - ticketCommission));
        lastWinnerAmount = winnings[winner];
        operatorTotalCommission += (tickets.length * ticketCommission);
        delete tickets;
        currentRound ++;
    }


    function checkWinningsAmount() public view returns (uint256) {
        address payable winner = payable(msg.sender);

        uint256 reward2Transfer = winnings[winner];

        return reward2Transfer;
    }

    function WithdrawWinnings() public isWinner notContract nonReentrant {
        address payable winner = payable(msg.sender);

        uint256 reward2Transfer = winnings[winner];
        winnings[winner] = 0;

        winner.transfer(reward2Transfer);
    }


    function WithdrawCommission() public isOperator notContract {
        address payable operator = payable(msg.sender);

        uint256 commission2Transfer = operatorTotalCommission;
        operatorTotalCommission = 0;

        operator.transfer(commission2Transfer);
    }

    function IsWinner() public view returns (bool) {
        return winnings[msg.sender] > 0;
    }

    function CurrentWinningReward() public view returns (uint256) {
        return tickets.length * ticketPrice;
    }

    function RemainingTickets() public view returns (uint256) {
        return maxTickets - tickets.length;
    }
}