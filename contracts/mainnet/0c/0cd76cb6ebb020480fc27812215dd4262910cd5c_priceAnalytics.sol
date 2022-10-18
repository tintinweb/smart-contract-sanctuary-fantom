/**
 *Submitted for verification at FtmScan.com on 2022-10-18
*/

// (C) Sam (543#3017), 2022-9999
// (C) Guru Network, 2022-9999
/*

Scarab.finance is now a part of the Guru Network (🦾,🚀)
Merge your SCARAB, gSCARAB & SINSPIRIT tokens into ELITE!

Migrating starts a stream of ELITE tokens, powered by LlamaPay.


FFFFF  TTTTTTT  M   M         GGGGG  U    U  RRRRR     U    U
FF       TTT   M M M M       G       U    U  RR   R    U    U
FFFFF    TTT   M  M  M      G  GGG   U    U  RRRRR     U    U
FF       TTT   M  M  M   O  G    G   U    U  RR R      U    U
FF       TTT   M     M       GGGGG    UUUU   RR  RRR    UUUU


FFFFF    M   M    CCCCC       GGGGG  U    U  RRRRR     U    U
FF      M M M M  CC          G       U    U  RR   R    U    U
FFFFF   M  M  M  CC         G  GGG   U    U  RRRRR     U    U
FF      M  M  M  CC      O  G    G   U    U  RR R      U    U
FF      M     M  CCCCCC      GGGGG    UUUU   RR  RRR    UUUU


KK   KK   CCCCC   CCCCC       GGGGG  U    U  RRRRR     U    U
KK KKK   CC      CC          G       U    U  RR   R    U    U
KKKK     CC      CC         G  GGG   U    U  RRRRR     U    U
KK KK    CC      CC      O  G    G   U    U  RR R      U    U
KK  KKK  CCCCCC  CCCCCC      GGGGG    UUUU   RR  RRR    UUUU


 M   M  TTTTTTT  V     V      GGGGG  U    U  RRRRR     U    U
M M M M   TTT    V     V     G       U    U  RR   R    U    U
M  M  M   TTT     V   V     G  GGG   U    U  RRRRR     U    U
M     M   TTT      V V   O  G    G   U    U  RR R      U    U
M     M   TTT       V        GGGGG    UUUU   RR  RRR    UUUU


EEEEEEE   CCCCC  H    H       GGGGG  U    U  RRRRR     U    U
EE       CC      H    H      G       U    U  RR   R    U    U
EEEEEE   CC      HHHHHH     G  GGG   U    U  RRRRR     U    U
EE       CC      H    H  O  G    G   U    U  RR R      U    U
EEEEEEE  CCCCCC  H    H      GGGGG    UUUU   RR  RRR    UUUU




                    *************************
                    **                     **
                    **    SCARAB ⇢ ELITE   **
                    **                     **
                    ** Migrate your SCARAB **
                    ** GSCARAB & SINSPIRIT **
                    ** tokens to get ELITE **
                    **                     **
                    **    ftm.guru/ascend  **
                    **                     **
                    *************************

@notice Deposit Scarab tokens to start a new stream of ELITE.

*/
/*

Create a farm & vault for your own projects for free with ftm.guru

                        Contact us at:
            https://discord.com/invite/QpyfMarNrV
                    https://t.me/FTM1337

*/
/*
    - KOMPOUND PROTOCOL -
    - GRANARY & WORKERS -
    https://ftm.guru/GRAIN

    Yield Compounding Service
    Created by Guru Network

    Community Mediums:
        https://discord.com/invite/QpyfMarNrV
        https://medium.com/@ftm1337
        https://twitter.com/ftm1337
        https://twitter.com/kucino
        https://t.me/ftm1337

    Other Products:
        Kucino - The First and Most used Casino of KCC
        fmc.guru - FantomMarketCap : On-Chain Data Aggregator
        ELITE - ftm.guru is an indie growth-hacker for Fantom
        Lockless Protocol - Liquid Staking for Cosmos-SDK chains
        Kompound Protocol - The only immutable yield-compounder
*/
//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;


interface ITVL {
	function coinusd() external view returns(uint256);
	function p_t_coin_usd(address) external view returns(uint256);
}

interface IAsc {
	function rS() external view returns (uint256);
	function rG() external view returns (uint256);
	function rI() external view returns (uint256);
}


contract priceAnalytics {

	ITVL TG = ITVL(0x0786c3a78f5133F08C1c70953B8B10376bC6dCad);
	IAsc ASC = IAsc(0x731372585450ADBBB35e88aC18Cd5d906eb8dd46);

	function getAllPrices() external view returns(
		uint256,	//	TimeStamp
		uint256,	//	price of ELITE in USD
		uint256,	//	price of SCARAB in USD
		uint256,	//	price of GSCARAB in USD
		uint256,	//	price of SINSPIRIT in USD
		uint256,	//	Floor-price of SCARAB in USD
		uint256,	//	Floor-price of GSCARAB in USD
		uint256,	//	Floor-price of SINSPIRIT in USD
		uint256,	//	Target-price of SCARAB in USD
		uint256		//	Target-price of SINSPIRIT in USD
	) {
		uint256 ftm = TG.coinusd();
		uint256 p_e = TG.p_t_coin_usd(0xEA035A13B64cB49D85E2f0a2736c9604CB21599C);
		uint256 p_s = TG.p_t_coin_usd(0x78e70eF4eE5cc72FC25A8bDA4519c45594CcD8d4);
		uint256 p_g = TG.p_t_coin_usd(0x27228140D72a7186F70eD3052C3318f2D55c404d);
		uint256 p_i = TG.p_t_coin_usd(0xDCb0276e6F5c12033233cEb9857F39b9DEf0293c);
		uint256 spi = TG.p_t_coin_usd(0x30748322B6E34545DBe0788C421886AEB5297789);


		return (
			block.timestamp,
			p_e,
			p_s,
			p_g,
			p_i,
			(p_e * ASC.rS() ) / 1e18,
			(p_e * ASC.rG() ) / 1e18,
			(p_e * ASC.rI() ) / 1e18,
			ftm,
			spi
		);
	}
}