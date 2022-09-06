/**
 *Submitted for verification at FtmScan.com on 2022-09-06
*/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.7;

//블럭 타임은 UTC 목요일 오전 00시 이다
//하루는 86400 초
//UTC 화요일 00:00AM 은 PST 월요일 5:00 PM (써머타임 적용시) 
//block.timestamp % 604800 하고 나온 숫자는,
//UST 00:00 AM 목요일로 부터 지난 초를 의미함
//432,000 이 UTC 화요일 00:00AM 인것.
//432000 < (block.timestamp % 604800) < 446400 (+ 3600x4)
//UTC 화요일 00:00AM ~ 04:00AM 을 의미
//PST 월요일 5:00 PM ~ 9:00 PM 을 의미 (서머타임 시 1시간 차이)

contract withdraw {

    uint256 public timeNowDeposit;
    uint256 public timeNowBet;

    uint256 public testA;
    uint256 public testB;

    uint256 public timeNow = block.timestamp % 604800;

    //원래 withdraw 펑션은 그대로 둬서 오너가 언제든 열고 닫을 수 있게두고
    //
    function withdrawHouseAuto() public {
        timeNowDeposit = block.timestamp % 604800;
        // Requires now to be UTC Tuesday 00:00 ~ 04:00 AM
        require (432000 < timeNowDeposit && timeNowDeposit < 446400, "Withdrawal is only available UTC Tue 00:00 AM ~ 00:04 AM");
        testA += 1;
    }

    function betAuto() public {
        timeNowBet = block.timestamp % 604800;
        // Bet is disabled during Withdrawal is enabled + 5 minutes before and after
        require(timeNowBet < 431700 && timeNowBet > 446700, "Betting is disabled while withdrawal is enabled" );
        testB += 1;
    }
}