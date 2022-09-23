/**
 *Submitted for verification at FtmScan.com on 2022-09-22
*/

/*  
 * TestWinningTicket
 * 
 * Written by: MrGreenCrypto
 * Co-Founder of CodeCraftrs.com
 * 
 * SPDX-License-Identifier: None
 */
pragma solidity 0.8.17;


contract TestWinningTicket {
    
    constructor() {}

    uint256[] public winners;
    uint256 public totalTickets;
    uint256[] public addedTickets;
    uint256[] public idTicketIndex;
    uint256 public alreadyMinted;


    function addLotsOfTickets(uint256 howMany) public {
        uint256 start = alreadyMinted;
        for (uint256 i=start; i<alreadyMinted + howMany; i++){
            addTicketsToList(i);
        }
        alreadyMinted += howMany;
    }

    function getARandomWinnerId(uint256 randomNumber) public returns(uint256) {
        uint256  winningAddress = idTicketIndex[findIdOfWinningTicket(randomNumber % totalTickets)];
        winners.push(winningAddress);
        return winningAddress;
    }

    function addTicketsToList(uint256 id) public {
        totalTickets += getTicketsOfId(id);
        addedTickets.push(totalTickets);
        idTicketIndex.push(id);
    }

    function getTicketsOfId(uint256 id) public pure returns(uint256) {
        uint256 rank = id % 100;
        if(rank > 50 || rank == 0) return 1;
        if(rank > 25) return 2;
        if(rank > 5) return 5;
        return 20;
    }
        
    function findIdOfWinningTicket(uint256 winningTicket) public view returns(uint256) {
        uint256 low;
        uint256 high = addedTickets.length;

        while(low < high) {
            uint256 mid = (low & high) + (low ^ high) / 2;
            if(addedTickets[mid] > winningTicket) high = mid;
            else low = mid + 1;
        }

        if(low > 0 && addedTickets[low-1] == winningTicket) return low - 1;
        else return low;
    }


}