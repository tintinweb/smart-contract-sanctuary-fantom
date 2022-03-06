/**
 *Submitted for verification at FtmScan.com on 2022-03-05
*/

//SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

interface ChainlinkOracle {
    function latestAnswer() external view returns (int256);
}

contract StablecoinIndexingLINK {


    ChainlinkOracle private USDCo = ChainlinkOracle(0x2553f4eeb82d5A26427b8d1106C51499CBa5D99c);
    ChainlinkOracle private USDTo = ChainlinkOracle(0xF64b636c5dFe1d3555A847341cDC449f612307d0);
    ChainlinkOracle private USTo = ChainlinkOracle(0x6F3DD0eC672871547Ea495DCF7aA963B8A179287);
    ChainlinkOracle private FRAXo = ChainlinkOracle(0xBaC409D670d996Ef852056f6d45eCA41A8D57FbD);
    ChainlinkOracle private DAIo = ChainlinkOracle(0x91d5DEFAFfE2854C7D02F50c80FA1fdc8A721e52);
    ChainlinkOracle private BUSDo = ChainlinkOracle(0xf8f57321c2e3E202394b0c0401FD6392C3e7f465);

    int256 public USDC = USDCo.latestAnswer();
    int256 public USDT = USDTo.latestAnswer();
    int256 public UST = USTo.latestAnswer();
    int256 public FRAX = FRAXo.latestAnswer();
    int256 public DAI = DAIo.latestAnswer();
    int256 public BUSD = BUSDo.latestAnswer();
}