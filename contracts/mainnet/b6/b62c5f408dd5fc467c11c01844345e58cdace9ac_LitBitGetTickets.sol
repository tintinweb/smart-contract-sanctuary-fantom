/**
 *Submitted for verification at FtmScan.com on 2022-11-21
*/

/**
 *Submitted for verification at polygonscan.com on 2022-11-13
*/

/*  
 * LitBitGetTickets
 * 
 * Written by: MrGreenCrypto
 * Co-Founder of CodeCraftrs.com
 * 
 * SPDX-License-Identifier: None
 */
pragma solidity 0.8.17;

interface IStaking {
    function totalStakedInPool1(address) external view returns(uint256);
    function totalStakedInPool2(address) external view returns(uint256);
    function totalStakedInPool3(address) external view returns(uint256);
    function totalStakedInPool4(address) external view returns(uint256);
    function totalStakedInPool5(address) external view returns(uint256);
    function totalStakedInPool6(address) external view returns(uint256);
}

contract LitBitGetTickets {
    IStaking public stakingContract = IStaking(0x644229fb8dB1a4397cEFf38bb9F3F27858705B4B);
    uint256 freeTicketPermillePool1 = 150;
    uint256 freeTicketPermillePool2 = 70;
    uint256 freeTicketPermillePool3 = 33;
    uint256 freeTicketPermillePool4 = 15;
    uint256 freeTicketPermillePool5 = 0;
    uint256 freeTicketPermillePool6 = 0;
    uint256 tokensRequiredPerTicket = 2500 * 10**9;

    constructor() {}

    function calculateTickets(address player) public view returns(uint256) {
        uint256 ticketsOfPlayer = 0;
        uint256 calculationToken = 0;
        uint256 pool1 = stakingContract.totalStakedInPool1(player);
        uint256 pool2 = stakingContract.totalStakedInPool2(player);
        uint256 pool3 = stakingContract.totalStakedInPool3(player);
        uint256 pool4 = stakingContract.totalStakedInPool4(player);
        uint256 pool5 = stakingContract.totalStakedInPool5(player);
        uint256 pool6 = stakingContract.totalStakedInPool6(player);
        calculationToken += pool1 * (1000 + freeTicketPermillePool1) / 1000;
        calculationToken += pool2 * (1000 + freeTicketPermillePool2) / 1000;
        calculationToken += pool3 * (1000 + freeTicketPermillePool3) / 1000;
        calculationToken += pool4 * (1000 + freeTicketPermillePool4) / 1000;
        calculationToken += pool5 * (1000 + freeTicketPermillePool5) / 1000;
        calculationToken += pool6 * (1000 + freeTicketPermillePool6) / 1000;
        ticketsOfPlayer = calculationToken / tokensRequiredPerTicket;
        return ticketsOfPlayer;
    }
}