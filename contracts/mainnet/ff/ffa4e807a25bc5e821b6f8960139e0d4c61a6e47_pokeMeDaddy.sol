/**
 *Submitted for verification at FtmScan.com on 2022-08-21
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPoke{

    function pokeGauge(address gauge, uint256 batch) external;

}

contract pokeMeDaddy{

//oxDAO pokegauge implementation source:
    address constant pokefunc = 0xDA0027f2368bA3cb65a494B1fc7EA7Fd05AB42DD;

    IPoke func = IPoke(pokefunc);

//List of Addresses with high vote emissions
    address constant solidSex=0x4435Ea1DD7b7BEeEf25AfE3C12f697F55F83B54B;
    address constant ftmsolidsex=0xE3aa48b9D7F371F10c335Ad243156c35065D9887;
    address constant pFTM=0x7A2Ee34556eDC2EeF9f76a856ca97029c2A565De;
    address constant wFTMUsd=0x9bF747D6Cb36C80Fe64d4F9A7B748a9D9CAe8eCD;
    address constant ftmdeus=0xe9a4f6614F137A55D2aCa2BF17396AA6BF78907d;
    address constant solidDEI=0x4127992F9A603436c636B2317a966E3BbB02AFAA;
    address constant wFTMETH=0xf810a139e8CbAC66Db206E1A5e3792C4E8245612;
    address constant oxdOxSolid=0xE9F6F70913F459364b8Bf923DE352874CA37E595;
    address constant elite=0xCF6fB564468309ED0B95aa1f3167Db9Ff695414b;
    address constant yfi=0x5473DE6376A5DA114DE21f63E673fE76e509e55C;
    address constant mim=0x4aBA91239ea58A0D13cA0660C5b7E794F4284030;
    address constant dai=0x08C22282AB89b66E953c3e7297DAba29404aC8dE;
    address constant sex=0xbDc1e88eE931A1526DF7F1E31052BDEcA56d3770;
    address constant oxd=0xE639ee165859d83029e5832fCa93C5CEbA863d15;
    address constant solidoxsolid=0xd9AC00684B69b25A8f64891A06C6f7e574d2C63b;
    address constant usdcdei=0x248B17FFA182fbb83F7a1D67a7cd36Ec23d10619;
    address constant kp3r=0xA1Ef6e79E9e6850d0052f5e68a99220F771660d6;
    address constant pae=0xBa4ad0c2AE77CC83eC474317084bD25c92767F5f;
    address constant tomb=0x46632E2568e7d24fF5CaCC116E661A8c36132E2C;
    address constant mai=0x9B1d6d2eaAdBc241c9944c6b9fe9CD26b35f0A6f;
    address constant bomb=0x353424484B6F64a7C5f4987ce60C7C535df1e8D5;
    address constant usdcelite=0x3d1b418A3B0f6676cdd34aB8FF1F5b92a461a5Ac;
    address constant syn=0x651A28DDf02528adBbC36fC6CBF78f5ad7Edd4c5;
    address constant scream=0x634F3D933f0048F80e5Ec0C16bE98be091918a3E;
    address constant pots=0xeA709058f033711DDF397d719520BE6026E8FD54;
    address constant pills=0xF450e1D7959548B6B65A84389c61f67cbe9ca602;
    address constant g3crv=0x635aCA013D698aE971e4Fc42e8768D6226CCc7d6;
    address constant panic=0xd30172E668D6e45639C50E88a0dA06D7066B808a;
    address constant beluga=0xD9EE91776ad2118aaDBcCe40258250d23f6a0a72;
    address constant sinspirit=0x5615cf2Fc369E3031c6665064A52FA4fd00e1C27;
    address constant vsinspirit=0x72cBA1C989a22F7e14ad1Db1ca120fA17C91d169;
    address constant rainspirit=0xB547Fe0742C358aFE7C6D9Cd9aA515dee138a852;
    address constant linspirit=0x215d955730BBf251BB0897F86E9A06347a79651f;
//poke functions in batches of 3 to prevent OOG errors
    function cuckold() external{
        func.pokeGauge(solidSex,200);
        func.pokeGauge(sex,200);
        func.pokeGauge(ftmsolidsex,200);
}
    function virgins() external{
        func.pokeGauge(solidoxsolid,200);
        func.pokeGauge(oxdOxSolid,200);
        func.pokeGauge(oxd,200);
}
    function wagie() external{
        func.pokeGauge(ftmdeus,200);
        func.pokeGauge(solidDEI,200);
        func.pokeGauge(usdcdei,200);
}
    function andrew() external{
        func.pokeGauge(yfi,200);
        func.pokeGauge(kp3r,200);
        func.pokeGauge(g3crv,200);
}
    function cancer() external{
        func.pokeGauge(wFTMUsd,200);
        func.pokeGauge(wFTMETH,200);
        func.pokeGauge(syn,200);
}
    function rugme() external {
        func.pokeGauge(pFTM,200);
        func.pokeGauge(pae,200);
        func.pokeGauge(tomb,200);
    }
    function stablecons() external{
        func.pokeGauge(mim,200);
        func.pokeGauge(dai,200);
        func.pokeGauge(mai,200);
    }
    function titties() external{
        func.pokeGauge(elite,200);
        func.pokeGauge(bomb,200);
        func.pokeGauge(usdcelite,200);
    }
    function blart() external{
        func.pokeGauge(scream,200);
        func.pokeGauge(pots,200);
        func.pokeGauge(pills,200);
    }
    function nofap() external{
        func.pokeGauge(panic,200);
        func.pokeGauge(beluga,200);
        func.pokeGauge(linspirit,200);
    }
    function rektspirits() external{
        func.pokeGauge(sinspirit,200);
        func.pokeGauge(rainspirit,200);
        func.pokeGauge(vsinspirit,200);
    }
}