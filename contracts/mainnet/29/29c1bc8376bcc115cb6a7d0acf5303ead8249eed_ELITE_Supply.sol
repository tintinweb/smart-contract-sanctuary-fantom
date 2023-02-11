/**
 *Submitted for verification at FtmScan.com on 2023-02-11
*/

/*SPDX-License-Identifier: UNLICENSED
Guru Network (🦾 , 🚀)
https://ftm.guru
https://eliteness.network
https://discord.gg/QpyfMarNrV

FFFFF  TTTTTTT  M   M         GGGGG  U    U  RRRRR     U    U
FF       TTT   M M M M       G       U    U  RR   R    U    U
FFFFF    TTT   M  M  M      G  GGG   U    U  RRRRR     U    U
FF       TTT   M  M  M   O  G    G   U    U  RR R      U    U
FF       TTT   M     M       GGGGG    UUUU   RR  RRR    UUUU
*/

pragma solidity ^0.8.9;

interface UI {
	function balanceOf(address) external view returns(uint);
	function totalSupply() external view returns(uint);
	function p_t_coin_usd(address) external view returns(uint);
	function coinusd() external view returns(uint);
	function ELITEForxELITE(uint) external view returns(uint);
}

contract ELITE_Supply {

	UI public ELITE =	UI(0xf43Cc235E686d7BC513F53Fbffb61F760c3a1882);
	UI public XELITE =	UI(0x1BE23c78038B6057172848534AcD62667fA2620d);
	UI public TvlGuru =	UI(0x0786c3a78f5133F08C1c70953B8B10376bC6dCad);
	address public pool2 = 0xEA035A13B64cB49D85E2f0a2736c9604CB21599C;	//SpookyLP (Burned)

	function info() public view returns(uint256[17] memory) {
		uint256[17] memory _info = [
			uint256(0), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
		];

		_info[0] = block.timestamp;
		_info[1] = TvlGuru.p_t_coin_usd(pool2);
		_info[2] = TvlGuru.p_t_coin_usd(pool2)*1e18/TvlGuru.coinusd();
		_info[3] = 1337e18;
		_info[4] = ELITE.totalSupply();
		_info[5] = ELITE.balanceOf(0x0000000000000000000000000000000000000000);
		_info[6] = ELITE.balanceOf(0x000000000000000000000000000000000000dEaD);
		_info[7] = ELITE.balanceOf(0x00000000000000000000000000000000DEAD1337);
		_info[8] = ELITE.balanceOf(0x74BFb7E94bEf5767F5F6Ace2D0df73a224ADB689);		//Infinitely-extensible Public Timelock
		_info[9] = ELITE.balanceOf(0x167D87A906dA361A10061fe42bbe89451c2EE584);		//Treasury
		_info[10] = ELITE.balanceOf(0x5C146cd18fa53914580573C9b9604588529406Ca);	//Development Reserve
		_info[11] = ELITE.balanceOf(0xbab9645d1B78425A7e4e9e78E8DD32aAbd800a16);	//Future Expansion Reserve
		_info[12] = ELITE.balanceOf(0x1BE23c78038B6057172848534AcD62667fA2620d);	//XELITE (Staked)
		_info[13] = XELITE.totalSupply();											//XELITE (Total Supply)
		_info[14] = XELITE.ELITEForxELITE(1e18);									//1 ELITE = ? XELITE
		_info[15] = XELITE.balanceOf(0x167D87A906dA361A10061fe42bbe89451c2EE584);	//Treasury
		_info[16] = XELITE.balanceOf(0x5C146cd18fa53914580573C9b9604588529406Ca);	//Development Reserve
		return _info;
	}
}