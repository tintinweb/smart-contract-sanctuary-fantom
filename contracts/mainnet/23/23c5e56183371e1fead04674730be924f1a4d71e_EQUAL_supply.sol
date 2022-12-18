/**
 *Submitted for verification at FtmScan.com on 2022-12-18
*/

// SPDX-License-Identifier: Unlicensed
// (C) Sam, 543#3017, Guru Network, 2022-9999
// Contact: https://discord.gg/QpyfMarNrV
pragma solidity ^0.8.17;
interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function decimals() external view returns (uint8);
	function allowance(address, address) external view returns (uint256);
}
interface IVoter {
	function length() external view returns (uint256);
	function pools(uint256) external view returns (address);
	function gauges(address) external view returns (address);
}
interface IveNFT {
	function totalSupply() external view returns (uint256);
}
interface ItGURU {
	function p_t_coin_usd(address) external view returns (uint256);
}

contract EQUAL_supply {
	IERC20 public EQUAL = IERC20(0x3Fd3A0c85B70754eFc07aC9Ac0cbBDCe664865A6);
	IVoter public VOTER = IVoter(0x4bebEB8188aEF8287f9a7d1E4f01d76cBE060d5b);
	IveNFT public veNFT = IveNFT(0x8313f3551C4D3984FfbaDFb42f780D0c8763Ce94);
	ItGURU public tGURU = ItGURU(0x0786c3a78f5133F08C1c70953B8B10376bC6dCad);

	address[] public excluded = [
		address(0),
		0x000000000000000000000000000000000000dEaD,
		0xC424C343554aFd6CD270887D4232765850f5e93F,	//treasury
		0xaFf13732267e43a57a6c86AAC987f1fAB4961dBA,	//marketing fund
		0x6ef2Fa893319dB4A06e864d1dEE17A90fcC34130,	//unclaimed airdrop
		0x1633670d2Ae6ebe5FF7D9D9c24a8c59B617e4884	//veMoreEqual
	];
	address public pool2 = 0x3d6c56f6855b7Cc746fb80848755B0a9c3770122;
	address public owner;

    modifier oo {
        require(msg.sender == owner, "!owner");
        _;
    }

	constructor() {
		owner = msg.sender;
	}

	function addExcluded(address _e) public oo {
		excluded.push(_e);
	}

	function pullExcluded(uint n) public oo {
		excluded[n]=excluded[excluded.length-1];
		excluded.pop();
	}

	function name() public pure returns(string memory) {
		return "Equalizer.s";
	}

	function symbol() public pure returns(string memory) {
		return "EQUAL.s";
	}

	function decimals() public pure returns(uint8) {
		return 18;
	}

	function allowance(address _o, address _s) public view returns(uint256) {
		return EQUAL.allowance(_o, _s);
	}

	function balanceOf(address _o) public view returns(uint256) {
		return EQUAL.balanceOf(_o);
	}

	function inExcluded() public view returns(uint256 _t) {
		for(uint i;i<excluded.length;i++) {
			_t += EQUAL.balanceOf(excluded[i]);
		}
		return _t;
	}

	function inGauges() public view returns(uint256 _t) {
		uint _l = VOTER.length();
		for(uint i;i<_l;i++) {
			address _p = VOTER.pools(i);
			address _g = VOTER.gauges(_p);
			_t += EQUAL.balanceOf(_g);
		}
		return _t;
	}

	function inNFT() public view returns(uint256) {
		return EQUAL.balanceOf(address(veNFT));
	}

	function dilutedSupply() public view returns(uint256) {
		return EQUAL.totalSupply();
	}

	function outstandingSupply() public view returns(uint256) {
		return
			dilutedSupply()
			- inExcluded()
			- inGauges()
		;
	}

	function totalSupply() public view returns(uint256) {
		return circulatingSupply();
	}

	function circulatingSupply() public view returns(uint256) {
		return
			dilutedSupply()
			- inExcluded()
			- inGauges()
			- inNFT()
		;
	}

	function lockRatio() public view returns(uint256) {
		return ( inNFT() * 1e18 ) / ( circulatingSupply() + inNFT() );
	}

	function price() public view returns(uint256) {
		return tGURU.p_t_coin_usd(pool2);
	}

	function liquidity() public view returns(uint256) {
		return ( price() * EQUAL.balanceOf(pool2) * 2 ) / 1e18;
	}

	function circulatingMarketCap() public view returns(uint256) {
		return ( price() * circulatingSupply() ) / 1e18;
	}

	function marketCap() public view returns(uint256) {
		return ( price() * outstandingSupply() ) / 1e18;
	}

	function fdv() public view returns(uint256) {
		return ( price() * dilutedSupply() ) / 1e18;
	}

	function lockedMarketCap() public view returns(uint256) {
		return ( veNFT.totalSupply() * price() ) / 1e18;
	}

	function info() public view returns(uint256[14] memory) {
		uint256[14] memory _info = [
			uint256(0), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
		];
		_info[0] = price();
		_info[1] = circulatingSupply();
		_info[2] = outstandingSupply();
		_info[3] = dilutedSupply();
		_info[4] = inNFT();
		_info[5] = inGauges();
		_info[6] = inExcluded();
		_info[7] = veNFT.totalSupply();
		_info[8] = lockRatio();
		_info[9] = liquidity();
		_info[10] = circulatingMarketCap();
		_info[11] = marketCap();
		_info[12] = fdv();
		_info[13] = lockedMarketCap();
		return _info;
	}

}