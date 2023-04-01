/**
 *Submitted for verification at FtmScan.com on 2023-03-28
*/

/*

FFFFF  TTTTTTT  M   M         GGGGG  U    U  RRRRR     U    U
FF       TTT   M M M M       G       U    U  RR   R    U    U
FFFFF    TTT   M  M  M      G  GGG   U    U  RRRRR     U    U
FF       TTT   M  M  M   O  G    G   U    U  RR R      U    U
FF       TTT   M     M       GGGGG    UUUU   RR  RRR    UUUU



            			Contact us at:
			https://discord.com/invite/QpyfMarNrV
        			https://t.me/FTM1337

    Community Mediums:
        https://medium.com/@ftm1337
        https://twitter.com/ftm1337
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
interface IVe {/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
	function create_lock_for(uint _value, uint _lock_duration, address _to) external;/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
}/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
pragma solidity 0.8.9;/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!

interface IERC20 {/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
    function approve(address spender, uint value) external returns (bool);/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
}/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
contract VEEEEEEQUAL_MINTERRR_GO_BRRRRRRRRRRRRRR {/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
	constructor() {/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
        IERC20(0x3Fd3A0c85B70754eFc07aC9Ac0cbBDCe664865A6)/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
        .approve(0x8313f3551C4D3984FfbaDFb42f780D0c8763Ce94, type(uint256).max);/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
    }/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
    function mint(uint _n, uint _value, uint _lock_duration, address _to) public {/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
		IERC20(0x3Fd3A0c85B70754eFc07aC9Ac0cbBDCe664865A6)/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
        .transferFrom(msg.sender, address(this), _n * _value);/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
		for(uint i=0; i<_n; i++) {/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
            IVe(0x8313f3551C4D3984FfbaDFb42f780D0c8763Ce94)/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
            .create_lock_for(_value, _lock_duration, _to);/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
		}/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
	}/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
}/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!
/////////////////////// VEEEEEEQUAL MINTERRR GO BRRRRRRRRRRRRRR!!!!!!!!!!!!