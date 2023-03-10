/**
 *Submitted for verification at FtmScan.com on 2023-03-10
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

interface IF {
	function allPairsLength() external view returns (uint);
	function allPairs(uint) external view returns (address);
}

interface IP {
	function token0() external view returns (address);
	function token1() external view returns (address);
	function balanceOf(address) external view returns (uint);
	function claimable0(address) external view returns (uint);
	function claimable1(address) external view returns (uint);
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

	struct B {
		address P;	//pair
		uint A;		//amount
	}

	IV V;
	IF F;

	constructor(address _v, address _f) {
		V = IV(_v);
		F = IF(_f);
	}

	function balancesUnstaked(address who) public view returns (B[] memory) {
		uint l = F.allPairsLength();
		uint f;
		B[] memory UB = new B[](l);	//2 max reward tokens per pair
		for(uint i; i < l; i++) {
			IP p = IP( F.allPairs(i) );
			try p.balanceOf(who) returns(uint rta) {
				if(rta>0) UB[++f] = B({P:address(p), A:rta });
			}
			catch {
				//UB[++f] = B({P:address(p), A:1 });
			}
		}
		return UB;
	}

	function balancesUnstakedN(address who, uint si, uint fi) public view returns (B[] memory) {
		uint f;
		B[] memory UB = new B[](fi-si);	//2 max reward tokens per pair
		for(uint i=si; i < fi; i++) {
			IP p = IP( F.allPairs(i) );
			try p.balanceOf(who) returns(uint rta) {
				if(rta>0) UB[++f] = B({P:address(p), A:rta });
			}
			catch {
				//UB[++f] = B({P:address(p), A:1 });
			}
		}
		return UB;
	}

	function balancesDeposited(address who) public view returns (B[] memory) {
		uint l = V.length();
		uint f;
		B[] memory UB = new B[](l);	//1 max balance per pair
		for(uint i; i < l; i++) {
			IP p = IP( V.pools(i) );
			IP g = IP( V.gauges(address(p)) );
			try g.balanceOf(who) returns(uint rta) {
				if(rta>0) UB[++f] = B({P:address(p), A:rta });
			}
			catch {
				//UB[++f] = B({P:address(p), A:1 });
			}
		}
		return UB;
	}

	function balancesDepositedN(address who, uint si, uint fi) public view returns (B[] memory) {
		uint f;
		B[] memory UB = new B[](fi-si);	//1 max balance per pair
		for(uint i=si; i < fi; i++) {
			IP p = IP( V.pools(i) );
			IP g = IP( V.gauges(address(p)) );
			try g.balanceOf(who) returns(uint rta) {
				if(rta>0) UB[++f] = B({P:address(p), A:rta });
			}
			catch {
				//UB[++f] = B({P:address(p), A:1 });
			}
		}
		return UB;
	}

	function pendingFees(address who) public view returns (R[] memory) {
		uint l = F.allPairsLength();
		uint f;
		R[] memory UR = new R[](l*2);	//2 max reward tokens per pair
		for(uint i; i < l; i++) {
			IP p = IP( F.allPairs(i) );

			try p.claimable0(who) returns(uint rta) {
				if(rta>0) UR[++f] = R({P:address(p), A:rta, C:address(p), T:p.token0() });
			}
			catch {
				//UR[++f] = R({P:address(p), A:1, C:address(p), T:p.token0() });
			}

			try p.claimable1(who) returns(uint rta) {
				if(rta>0) UR[++f] = R({P:address(p), A:rta, C:address(p), T:p.token1() });
			}
			catch {
				//UR[++f] = R({P:address(p), A:1, C:address(p), T:p.token1() });
			}

		}
		return UR;
	}

	function pendingFeesN(address who, uint si, uint fi) public view returns (R[] memory) {
		uint f;
		R[] memory UR = new R[]((fi-si)*2);	//2 max reward tokens per pair
		for(uint i=si; i < fi; i++) {
			IP p = IP( F.allPairs(i) );

			try p.claimable0(who) returns(uint rta) {
				if(rta>0) UR[++f] = R({P:address(p), A:rta, C:address(p), T:p.token0() });
			}
			catch {
				//UR[++f] = R({P:address(p), A:1, C:address(p), T:p.token0() });
			}

			try p.claimable1(who) returns(uint rta) {
				if(rta>0) UR[++f] = R({P:address(p), A:rta, C:address(p), T:p.token1() });
			}
			catch {
				//UR[++f] = R({P:address(p), A:1, C:address(p), T:p.token1() });
			}

		}
		return UR;
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
					if(rta>0) UR[++f] = R({P:p, A:rta, C:address(g), T:rt });
				}
				catch {
					//UR[++f] = R({P:p, A:1, C:address(g), T:rt });
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
					if(rta>0) UR[++f] = R({P:p, A:rta, C:address(g), T:rt });
				}
				catch {
					//UR[++f] = R({P:p, A:1, C:address(g), T:rt });
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
					if(rta>0) UR[++f] = R({P:p, A:rta, C:address(bi), T:rt });
				}
				catch {
					//UR[++f] = R({P:p, A:1, C:address(bi), T:rt });
				}
			}
			lr = be.rewardsListLength();
			for(uint j; j < lr ; j++) {
				address rt = be.rewards(j);
				try be.earned(rt,who) returns(uint rta) {
					if(rta>0) UR[++f] = R({P:p, A:rta, C:address(be), T:rt });
				}
				catch {
					//UR[++f] = R({P:p, A:1, C:address(be), T:rt });
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
					if(rta>0) UR[++f] = R({P:p, A:rta, C:address(bi), T:rt });
				}
				catch {
					//UR[++f] = R({P:p, A:1, C:address(bi), T:rt });
				}
			}
			lr = be.rewardsListLength();
			for(uint j; j < lr ; j++) {
				address rt = be.rewards(j);
				try be.earned(rt,who) returns(uint rta) {
					if(rta>0) UR[++f] = R({P:p, A:rta, C:address(be), T:rt });
				}
				catch {
					//UR[++f] = R({P:p, A:1, C:address(be), T:rt });
				}
			}
		}
		R[] memory RR = new R[](f);
		for(uint i=0;i<f;i++){
			RR[i] = UR[i+1];
		}
		return RR;
	}


/*

	///////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////// Unfiltered (with 0-amounts included) /////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////

	function _balancesUnstaked(address who) public view returns (B[] memory) {
		uint l = F.allPairsLength();
		uint f;
		B[] memory UB = new B[](l);	//2 max reward tokens per pair
		for(uint i; i < l; i++) {
			IP p = IP( F.allPairs(i) );
			try p.balanceOf(who) returns(uint rta) {
				UB[++f] = B({P:address(p), A:rta });
			}
			catch {
				UB[++f] = B({P:address(p), A:1 });
			}
		}
		return UB;
	}

	function _balancesUnstakedN(address who, uint si, uint fi) public view returns (B[] memory) {
		uint f;
		B[] memory UB = new B[](fi-si);	//2 max reward tokens per pair
		for(uint i=si; i < fi; i++) {
			IP p = IP( F.allPairs(i) );
			try p.balanceOf(who) returns(uint rta) {
				UB[++f] = B({P:address(p), A:rta });
			}
			catch {
				UB[++f] = B({P:address(p), A:1 });
			}
		}
		return UB;
	}

	function _balancesDeposited(address who) public view returns (B[] memory) {
		uint l = V.length();
		uint f;
		B[] memory UB = new B[](l);	//1 max balance per pair
		for(uint i; i < l; i++) {
			IP p = IP( V.pools(i) );
			IP g = IP( V.gauges(address(p)) );
			try g.balanceOf(who) returns(uint rta) {
				UB[++f] = B({P:address(p), A:rta });
			}
			catch {
				UB[++f] = B({P:address(p), A:1 });
			}
		}
		return UB;
	}

	function _balancesDepositedN(address who, uint si, uint fi) public view returns (B[] memory) {
		uint f;
		B[] memory UB = new B[](fi-si);	//1 max balance per pair
		for(uint i=si; i < fi; i++) {
			IP p = IP( V.pools(i) );
			IP g = IP( V.gauges(address(p)) );
			try g.balanceOf(who) returns(uint rta) {
				UB[++f] = B({P:address(p), A:rta });
			}
			catch {
				UB[++f] = B({P:address(p), A:1 });
			}
		}
		return UB;
	}

	function _pendingFees(address who) public view returns (R[] memory) {
		uint l = F.allPairsLength();
		uint f;
		R[] memory UR = new R[](l*2);	//2 max reward tokens per pair
		for(uint i; i < l; i++) {
			IP p = IP( F.allPairs(i) );

			try p.claimable0(who) returns(uint rta) {
				UR[++f] = R({P:address(p), A:rta, C:address(p), T:p.token0() });
			}
			catch {
				UR[++f] = R({P:address(p), A:1, C:address(p), T:p.token0() });
			}

			try p.claimable1(who) returns(uint rta) {
				UR[++f] = R({P:address(p), A:rta, C:address(p), T:p.token1() });
			}
			catch {
				UR[++f] = R({P:address(p), A:1, C:address(p), T:p.token1() });
			}

		}
		return UR;
	}

	function _pendingFeesN(address who, uint si, uint fi) public view returns (R[] memory) {
		uint f;
		R[] memory UR = new R[]((fi-si)*2);	//2 max reward tokens per pair
		for(uint i=si; i < fi; i++) {
			IP p = IP( F.allPairs(i) );

			try p.claimable0(who) returns(uint rta) {
				UR[++f] = R({P:address(p), A:rta, C:address(p), T:p.token0() });
			}
			catch {
				UR[++f] = R({P:address(p), A:1, C:address(p), T:p.token0() });
			}

			try p.claimable1(who) returns(uint rta) {
				UR[++f] = R({P:address(p), A:rta, C:address(p), T:p.token1() });
			}
			catch {
				UR[++f] = R({P:address(p), A:1, C:address(p), T:p.token1() });
			}

		}
		return UR;
	}

	function _pendingRewards(address who) public view returns (R[] memory) {
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

	function _pendingRewardsN(address who, uint si, uint fi) public view returns (R[] memory) {
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



	function _pendingBribes(uint who) public view returns (R[] memory) {
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

	function _pendingBribesN(uint who, uint si, uint fi) public view returns (R[] memory) {
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
*/
}