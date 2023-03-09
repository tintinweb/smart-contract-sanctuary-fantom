/**
 *Submitted for verification at FtmScan.com on 2023-03-09
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
pragma solidity 0.8.9;

interface IR {
	function earned(address token, address account) external view returns (uint);
	function earned(address token, uint tokenId) external view returns (uint);
    function rewardsListLength() external view returns (uint);
    function rewards(uint) external view returns (address);
}

interface IV {
	function pools(uint) external view returns (address);
	function gauges(address) external view returns (address);
	function internal_bribes(address) external view returns (address);
	function external_bribes(address) external view returns (address);
	function bribes(address) external view returns (address);
	function length() external view returns (uint);
}

contract Equalens {

	struct R {
		address P;	//pair
		uint A;		//amount
		address C;	//contract
		address T;	//token
	}

	IV V;

	constructor(address _v) {
		V = IV(_v);
	}

	function pendingRewards(address who) public view returns (R[] memory) {
		uint l = V.length();
		uint f;
		R[] memory UR = new R[](l*48);	//16+16+16 max reward tokens per pair
		for(uint i; i < l; i++) {
			address p = V.pools(i);
			IR g = IR(V.gauges(p));
			uint lr = g.rewardsListLength();
			for(uint j; j < lr ; j++) {
				address rt = g.rewards(j);
				try g.earned(rt,who) returns(uint rta) {
					UR[++f] = R({P:p, A:rta, C:address(g), T:rt });
				}
				catch {
					UR[++f] = R({P:p, A:1, C:address(g), T:rt });
				}
			}
		}
		R[] memory RR = new R[](f);
		for(uint i=0;i<f;i++){
			RR[i] = UR[i+1];
		}
		return RR;
	}

	function pendingRewardsN(address who, uint si, uint fi) public view returns (R[] memory) {
		uint f;
		R[] memory UR = new R[]((fi-si)*16);	//16+16+16 max reward tokens per pair
		for(uint i=si; i < fi; i++) {
			address p = V.pools(i);
			IR g = IR(V.gauges(p));
			uint lr = g.rewardsListLength();
			for(uint j; j < lr ; j++) {
				address rt = g.rewards(j);
				try g.earned(rt,who) returns(uint rta) {
					UR[++f] = R({P:p, A:rta, C:address(g), T:rt });
				}
				catch {
					UR[++f] = R({P:p, A:1, C:address(g), T:rt });
				}
			}
		}
		R[] memory RR = new R[](f);
		for(uint i=0;i<f;i++){
			RR[i] = UR[i+1];
		}
		return RR;
	}



	function pendingBribes(uint who) public view returns (R[] memory) {
		uint l = V.length();
		uint f;
		R[] memory UR = new R[](l*48);	//16+16+16 max reward tokens per pair
		for(uint i; i < l; i++) {
			address p = V.pools(i);
			IR g = IR(V.gauges(p));
			IR bi = IR(V.internal_bribes(address(g)));
			IR be = IR(V.external_bribes(address(g)));
			uint lr = g.rewardsListLength();
			lr = bi.rewardsListLength();
			for(uint j; j < lr ; j++) {
				address rt = bi.rewards(j);
				try bi.earned(rt,who) returns(uint rta) {
					UR[++f] = R({P:p, A:rta, C:address(bi), T:rt });
				}
				catch {
					UR[++f] = R({P:p, A:1, C:address(bi), T:rt });
				}
			}
			lr = be.rewardsListLength();
			for(uint j; j < lr ; j++) {
				address rt = be.rewards(j);
				try be.earned(rt,who) returns(uint rta) {
					UR[++f] = R({P:p, A:rta, C:address(be), T:rt });
				}
				catch {
					UR[++f] = R({P:p, A:1, C:address(be), T:rt });
				}
			}
		}
		R[] memory RR = new R[](f);
		for(uint i=0;i<f;i++){
			RR[i] = UR[i+1];
		}
		return RR;
	}

	function pendingBribesN(uint who, uint si, uint fi) public view returns (R[] memory) {
		R[] memory UR = new R[]((fi-si)*32);	//16+16+16 max reward tokens per pair
		uint f;
		for(  ; si < fi; si++) {
			address p = V.pools(si);
			IR g = IR(V.gauges(p));
			IR bi = IR(V.internal_bribes(address(g)));
			IR be = IR(V.external_bribes(address(g)));
			uint lr = g.rewardsListLength();
			lr = bi.rewardsListLength();
			for(uint j; j < lr ; j++) {
				address rt = bi.rewards(j);
				try bi.earned(rt,who) returns(uint rta) {
					UR[++f] = R({P:p, A:rta, C:address(bi), T:rt });
				}
				catch {
					UR[++f] = R({P:p, A:1, C:address(bi), T:rt });
				}
			}
			lr = be.rewardsListLength();
			for(uint j; j < lr ; j++) {
				address rt = be.rewards(j);
				try be.earned(rt,who) returns(uint rta) {
					UR[++f] = R({P:p, A:rta, C:address(be), T:rt });
				}
				catch {
					UR[++f] = R({P:p, A:1, C:address(be), T:rt });
				}
			}
		}
		R[] memory RR = new R[](f);
		for(uint i=0;i<f;i++){
			RR[i] = UR[i+1];
		}
		return RR;
	}
}