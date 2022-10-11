/**
 *Submitted for verification at FtmScan.com on 2022-10-11
*/

/**
 *Submitted for verification at FtmScan.com on 2022-10-11
*/

// The HyperZapper
// (C) Sam (543#3017) & Guru Network, 2022-9999
/*


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
					**  GRANARY & WORKERS  **
					**	  ftm.guru/GRAIN   **
					**  kcc.guru/kompound  **
					**	  mtv.guru/GRAIN   **
					**	  ech.guru/GRAIN   **
					**                     **
					*************************


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
		KUCINO CASINO - The First and Most used Casino of KCC
		fmc.guru - FantomMarketCap : On-Chain Data Aggregator
		ELITE - ftm.guru is an indie growth-hacker for Fantom
*/
/*

		FREQUENTLY ASKED QUESTIONS


	Q.1	WHY USE THIS VAULT?
	Ans	Most of the popular vaults' owners can switch "strategy" and steal (a.k.a. hard-rug) your valuable assets.
		Granaries or Kompound Protocol cannot change its own behaviour or strategy once its deployed on-chain.
		Our code uses unchangeable constants for tokens and external contracts. All fees & incentives are capped.
			Unlike the other (you-know-who) famous vaults.


	Q.2 WHAT IS ELITENESS?
	Ans	Simply holding ELITE (ftm.guru) token in your wallet ascribes you Eliteness.
		It is required to earn worker incentives from this Granary.
		Deposits incur nil fee if the user posseses adequate eliteness.
		 	ELITE has a fixed supply of 250.


*/
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;
interface IGrain {
	function deposit(uint) external;
	function totalSupply() external view returns(uint);
	function aum() external view returns(uint);
}


interface IWrap {
	function deposit(uint256 _amount) external;
}


interface IWFTM {
    function deposit() external payable returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external returns (uint);
}

interface IAsset {
    // IBX placeholder for address-type
}

interface IBX {

	enum SwapKind { GIVEN_IN, GIVEN_OUT }

	struct SingleSwap {
    	bytes32 poolid;
    	SwapKind kind;
    	address assetIn;
    	address assetOut;
    	uint256 amount;
    	bytes userData;	 // abi.encode(0)
	}

	struct FundManagement {
    	address sender;
    	bool fromInternalBalance;
    	address recipient;
    	bool toInternalBalance;
	}

    function swap(SingleSwap memory singleSwap, FundManagement memory funds, uint256 limit, uint256 deadline) external returns (uint256);


	enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT }
	//Can be overriden using index inside the userData param
	//0 instead of JoinKind.INIT, 1 for JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT ...

	struct JoinPoolRequest {
    	IAsset[] assets;
    	uint256[] maxAmountsIn;
    	bytes userData;	//	abi.encode ( enum JoinKind, uint[] amounts, uint minLP )
    	bool fromInternalBalance;
	}

	function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request) external payable;

	function getPoolTokens(bytes32 poolId) external view returns(address[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);



    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

}


interface IERC20 {
	/**
	 * @dev Returns the amount of tokens in existence.
	 */

	function totalSupply() external view returns (uint256);
	/**
	 * @dev Returns the amount of tokens owned by `account`.
	 */

	function balanceOf(address account) external view returns (uint256);
	/**
	 * @dev Moves `amount` tokens from the caller's account to `recipient`.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */

	function transfer(address recipient, uint256 amount) external returns (bool);
	/**
	 * @dev Returns the remaining number of tokens that `spender` will be
	 * allowed to spend on behalf of `owner` through {transferFrom}. This is
	 * zero by default.
	 *
	 * This value changes when {approve} or {transferFrom} are called.
	 */

	function allowance(address owner, address spender) external view returns (uint256);
	/**
	 * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * IMPORTANT: Beware that changing an allowance with this method brings the risk
	 * that someone may use both the old and the new allowance by unfortunate
	 * transaction ordering. One possible solution to mitigate this race
	 * condition is to first reduce the spender's allowance to 0 and set the
	 * desired value afterwards:
	 * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
	 *
	 * Emits an {Approval} event.
	 */

	function approve(address spender, uint256 amount) external returns (bool);
	/**
	 * @dev Moves `amount` tokens from `sender` to `recipient` using the
	 * allowance mechanism. `amount` is then deducted from the caller's
	 * allowance.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */

	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	/**
	 * @dev Emitted when `value` tokens are moved from one account (`from`) to
	 * another (`to`).
	 *
	 * Note that `value` may be zero.
	 */
	event Transfer(address indexed from, address indexed to, uint256 value);
	/**
	 * @dev Emitted when the allowance of a `spender` for an `owner` is set by
	 * a call to {approve}. `value` is the new allowance.
	 */
	event Approval(address indexed owner, address indexed spender, uint256 value);
	//Uniswap-style Pair (LPT)

	function getReserves() external view returns (uint112, uint112, uint32);
}


interface IRouter {

	//UNISWAP
	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external;


	function addLiquidity(
		address tokenA,
		address tokenB,
		uint amountADesired,
		uint amountBDesired,
		uint amountAMin,
		uint amountBMin,
		address to,
		uint deadline
	) external returns (uint amountA, uint amountB, uint liquidity);

	//SOLIDLY
	struct route {
		address from;
		address to;
		bool stable;
	}
	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		route[] calldata routes,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);
}

library SafeMath {
	/**
	 * @dev Returns the addition of two unsigned integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `+` operator.
	 *
	 * Requirements:
	 * - Addition cannot overflow.
	 */

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
	}
	/**
	 * @dev Returns the subtraction of two unsigned integers, reverting on
	 * overflow (when the result is negative).
	 *
	 * Counterpart to Solidity's `-` operator.
	 *
	 * Requirements:
	 * - Subtraction cannot overflow.
	 */

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}
	/**
	 * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
	 * overflow (when the result is negative).
	 *
	 * Counterpart to Solidity's `-` operator.
	 *
	 * Requirements:
	 * - Subtraction cannot overflow.
	 */

	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;
		return c;
	}
	/**
	 * @dev Returns the multiplication of two unsigned integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `*` operator.
	 *
	 * Requirements:
	 * - Multiplication cannot overflow.
	 */

	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");
		return c;
	}
	/**
	 * @dev Returns the integer division of two unsigned integers. Reverts on
	 * division by zero. The result is rounded towards zero.
	 *
	 * Counterpart to Solidity's `/` operator. Note: this function uses a
	 * `revert` opcode (which leaves remaining gas untouched) while Solidity
	 * uses an invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 * - The divisor cannot be zero.
	 */

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(a, b, "SafeMath: division by zero");
	}
	/**
	 * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
	 * division by zero. The result is rounded towards zero.
	 *
	 * Counterpart to Solidity's `/` operator. Note: this function uses a
	 * `revert` opcode (which leaves remaining gas untouched) while Solidity
	 * uses an invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 * - The divisor cannot be zero.
	 */

	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		// Solidity only automatically asserts when dividing by 0
		require(b > 0, errorMessage);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold
		return c;
	}
	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * Reverts when dividing by zero.
	 *
	 * Counterpart to Solidity's `%` operator. This function uses a `revert`
	 * opcode (which leaves remaining gas untouched) while Solidity uses an
	 * invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 * - The divisor cannot be zero.
	 */

	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return mod(a, b, "SafeMath: modulo by zero");
	}
	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * Reverts with custom message when dividing by zero.
	 *
	 * Counterpart to Solidity's `%` operator. This function uses a `revert`
	 * opcode (which leaves remaining gas untouched) while Solidity uses an
	 * invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 * - The divisor cannot be zero.
	 */

	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}




contract HyperZapper {

	using SafeMath for uint256;
	address public dao;
	uint public feePerMillion = 1000;	//default of 0.1%


	modifier DAO {require(msg.sender==dao,"Only E.L.I.T.E. D.A.O. Treasury can rescue treasures!");_;}
	struct Elites {
		address ELITE;
		uint256 ELITES;
	}

	address[20] public alladdr = [
		0x85660a3538579fDd27DC77D0F22D0c42B92D8114,	//	0	MLP
		0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83,	//	1	WFTM
		0x0789fF5bA37f72ABC4D561D00648acaDC897b32d,	//	2	MORPH
		0xB66b5D38E183De42F21e92aBcAF3c712dd5d6286,	//	3	PILLS
		0x10b620b2dbAC4Faa7D7FFD71Da486f5D44cd86f9,	//	4	LQDR;
		0xCa3C69622E22524fF2b6cC24Ee7e654bbF91578a,	//	5	mLQDR
		0x0C35b3B57cDE4a3007398045B274548A6592E9d0,	//	6	MORPH to PILLS Swapper
		0x8aC868293D97761A1fED6d4A01E9FF17C5594Aa3,	//	7	MorpheusSwap (Pancake)
		0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52,	//	8	SpiritSwap (Pancake)
		0x09855B4ef0b9df961ED097EF50172be3e6F13665,	//	9	SpiritSwap V2 (Solidly)
		0xE5343E1eda3dc45E73468F9fa5417F0375f45127,	//	10	PILLS-FTM Morpheus LP
		0x9C775D3D66167685B2A3F4567B548567D2875350, //	11	PILLS-FTM Spirit LP
		0xE42Bb367c958e0E624C164f2491c37d8Fd713515,	//	12	LQDR-FTM Spirit V2 LP
		0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce,	//	13	Beethoven-x Vault (Balancer)
		0x4B69A8913A90cAB949218095717BAfCCeF6C39FC,	//	14	Morpheus Vault (Balancer)
		0x85660a3538579fDd27DC77D0F22D0c42B92D8114,	//	15	MPT-mLQDR-LQDR
		0x728A9227fFa9dea5E93D2AE5461D6e8B793D83A1,	//	16	Neo Pool
		0x0786c3a78f5133F08C1c70953B8B10376bC6dCad,	//	17	TvlGuru
		0xe533779d1e6fF3D5cfCEeD3DE761852E6C93DC8b,	//	18	vAMM-mLQDR/wFTM (Solidly)
		0x14C89E6aF2eACC0b9Ab3D5f2D98Db3B87ba50F3d	//	19	GRAIN#5400
	];

	//Using arrays to avoid "Stack too deep!" errors
	bytes32[2] public allb32 = [
		bytes32(0x5e02ab5699549675a6d3beeb92a62782712d0509000200000000000000000138),	//	0	BPT-Pirate
		0x85660a3538579fdd27dc77d0f22d0c42b92d8114000200000000000000000001				//	1	MPT-mLQDR-LQDR
	];

	constructor() {
		dao = 0x167D87A906dA361A10061fe42bbe89451c2EE584;
		//Approvals
		//Coverter to change Morph to Pills
		IERC20(alladdr[2]).approve(alladdr[6],uint256(-1));
		//Approved routes to peddle pills
		IERC20(alladdr[3]).approve( alladdr[7], uint256(-1));
		IERC20(alladdr[3]).approve( alladdr[8], uint256(-1));
		//Approved routes to enjoy the Opera
		IERC20(alladdr[1]).approve( alladdr[13], uint256(-1));
		IERC20(alladdr[1]).approve( alladdr[9], uint256(-1));
		//Approved MorpheuSS to Drink.. mmm.. LiquidS
		IERC20(alladdr[4]).approve( alladdr[14], uint256(-1));
		IERC20(alladdr[5]).approve( alladdr[14], uint256(-1));
		//Approved Pirate-morphing of Liquids
		IERC20(alladdr[4]).approve( alladdr[5], uint256(-1));
		//Approved Neo's Drive to the Matrix
		IERC20(alladdr[15]).approve(alladdr[19],uint256(-1));
	}

	function setFees(uint newfee) public DAO {
		require(newfee <= 50000, "Max fee can be 5% only!");
		feePerMillion = newfee;
	}

	function zapLQDR(uint amount, uint grains) public returns (uint grainz) {
		require(IERC20(alladdr[4]).transferFrom(msg.sender, address(this), amount), "Unable to take in LQDR!");

		//Below Code is from GRAIN#5400's work function
		// . . . . . . . . . . . . . . . . . . . .
		//	Wake up, Neo...  Make the choice!
		{
			(,uint256[] memory r,) = IBX(alladdr[14]).getPoolTokens(allb32[1]);
			uint L = IERC20(alladdr[4]).balanceOf(address(this));

			//The RED PILL : Buy some mLQDR from the StableSwap DEX
			if(r[0] < r[1]) {

				if( L < r[1]-r[0] ) {

        			IAsset[] memory T = new IAsset[](2);
        			T[0] = IAsset(alladdr[4]);
        			T[1] = IAsset(alladdr[5]);
					uint256[] memory A = new uint256[](2);
        			A[0] = L;
        			A[1] = 0;

					bytes memory U = abi.encode(1, A, 1);
					//EXACT_TOKENS_IN_FOR_BPT_OUT (=enum JoinKind @1) "+" amountsIn (=A) "+" minimumBPT (1 = 10^-18 BPT)

					IBX.JoinPoolRequest memory R = IBX.JoinPoolRequest({	//T,A,U, fib ==> R
						assets:	 			T,
						maxAmountsIn:		A,	//amounts=amounts since we want to give it ALL, no slippage
						userData:			U,
						fromInternalBalance:false
					});

					IBX(alladdr[14]).joinPool( allb32[1], address(this), address(this), R);
				}

				else if ( L > r[1]-r[0] ) {

					IWrap( alladdr[5] ).deposit( ( L - (r[1] - r[0]) ) / 2 );

        			IAsset[] memory T = new IAsset[](2);
        			T[0] = IAsset(alladdr[4]);
        			T[1] = IAsset(alladdr[5]);
					uint256[] memory A = new uint256[](2);
        			A[0] = IERC20( alladdr[4] ).balanceOf(address(this));
        			A[1] = IERC20( alladdr[5] ).balanceOf(address(this));

					bytes memory U = abi.encode(1, A, 1);
					//EXACT_TOKENS_IN_FOR_BPT_OUT (=enum JoinKind @1) "+" amountsIn (=A) "+" minimumBPT (1 = 10^-18 BPT)

					IBX.JoinPoolRequest memory R = IBX.JoinPoolRequest({	//T,A,U, fib ==> R
						assets:	 			T,
						maxAmountsIn:		A,	//amounts=amounts since we want to give it ALL, no slippage
						userData:			U,
						fromInternalBalance:false
					});

					IBX(alladdr[14]).joinPool( allb32[1], address(this), address(this), R);
					//pegged now
				}
			}


			//The Blue PILL : Mint some new mLQDR using the purchased LQDR
			if(r[0]>r[1]) {

				if(L < r[0]-r[1]) {

					IWrap( alladdr[5] ).deposit( L );

        			IAsset[] memory T = new IAsset[](2);
        			T[0] = IAsset(alladdr[4]);
        			T[1] = IAsset(alladdr[5]);
					uint256[] memory A = new uint256[](2);
        			A[0] = 0;
        			A[1] = IERC20( alladdr[5] ).balanceOf(address(this));

					bytes memory U = abi.encode(1, A, 1);
					//EXACT_TOKENS_IN_FOR_BPT_OUT (=enum JoinKind @1) "+" amountsIn (=A) "+" minimumBPT (1 = 10^-18 BPT)

					IBX.JoinPoolRequest memory R = IBX.JoinPoolRequest({	//T,A,U, fib ==> R
						assets:	 			T,
						maxAmountsIn:		A,	//amounts=amounts since we want to give it ALL, no slippage
						userData:			U,
						fromInternalBalance:false
					});

					IBX(alladdr[14]).joinPool( allb32[1], address(this), address(this), R);
				}

				else if(L > r[0]-r[1]) {

					IWrap( alladdr[5] ).deposit( (L + r[0]-r[1]) / 2 );

        			IAsset[] memory T = new IAsset[](2);
        			T[0] = IAsset(alladdr[4]);
        			T[1] = IAsset(alladdr[5]);
					uint256[] memory A = new uint256[](2);
        			A[0] = IERC20( alladdr[4] ).balanceOf(address(this));
        			A[1] = IERC20( alladdr[5] ).balanceOf(address(this));

					bytes memory U = abi.encode(1, A, 1);
					//EXACT_TOKENS_IN_FOR_BPT_OUT (=enum JoinKind @1) "+" amountsIn (=A) "+" minimumBPT (1 = 10^-18 BPT)

					IBX.JoinPoolRequest memory R = IBX.JoinPoolRequest({	//T,A,U, fib ==> R
						assets:	 			T,
						maxAmountsIn:		A,	//amounts=amounts since we want to give it ALL, no slippage
						userData:			U,
						fromInternalBalance:false
					});

					IBX(alladdr[14]).joinPool( allb32[1], address(this), address(this), R);
					//pegged now
				}
			}

		}

		//At this point, we have the MPT-mLQDR/LQDR tokens (Pirates in the Matrix)
		//They are ready to be deposited into the Granary
		uint amt_mpt = IERC20(alladdr[15]).balanceOf(address(this));
		IGrain(alladdr[19]).deposit(amt_mpt);

		uint amt_grainz = IERC20(alladdr[19]).balanceOf(address(this));

		uint fpm = feePerMillion;
		uint fee;
		if(fpm > 0) {
			fee = (amt_grainz*fpm)/1e6;
			IERC20(alladdr[19]).transfer(dao, fee);
		}
		grainz=amt_grainz-fee;
		require(grainz >= grains, "Insufficient Output of GRAIN#5400");
		IERC20(alladdr[19]).transfer(msg.sender, grainz);
	}



	function zapFTM(uint amount, uint grains) public payable returns (uint grainz) {
		if(msg.value>0) {
			require(msg.value==amount,"Insufficient Payment!");
			IWFTM(alladdr[1]).deposit{value:amount}();
		}
		else {
			require(IERC20(alladdr[1]).transferFrom(msg.sender, address(this), amount), "Unable to take in WFTM!");
		}

		//Below Code is from GRAIN#5400's work function
		//. . . . . . . . . . . . . . . . . . . . . . .
		//Get Drunk and Drive towards the shady farmers
		{
			//Doing JIT™ (Just-in-Time) Psuedo DEX-aggregation
			uint[3] memory dj_lqdr = [
				IERC20(alladdr[1]).balanceOf(address(this)),	//Current Prescribed Liquids
				IERC20(alladdr[1]).balanceOf( alladdr[12] ),	//The Driving Spirit
				1	//Inside Beethoven's Liquid Closet
			];

			(,uint256[] memory _bxb,) = IBX(alladdr[13]).getPoolTokens(allb32[0]);
			dj_lqdr[2] = _bxb[0];

			IRouter.route[] memory swapr = new IRouter.route[](1);
			swapr[0] = IRouter.route({
				from: alladdr[1],
				to: alladdr[4],
				stable:false
			});
			IRouter(alladdr[9])
			.swapExactTokensForTokens(
				( dj_lqdr[0] * dj_lqdr[1] ) / ( dj_lqdr[1] + dj_lqdr[2] ),	//auto-floored
				1,
				swapr,
				address(this),
				block.timestamp
			);

			IBX.FundManagement memory FML = IBX.FundManagement({
				sender:             address(this),
				fromInternalBalance:false,
				recipient:          payable(address(this)),
				toInternalBalance:  false
			});
			IBX.SingleSwap memory F2L = IBX.SingleSwap({
				poolid: 	allb32[0],
				kind:	    IBX.SwapKind.GIVEN_IN,
				assetIn:    alladdr[1],
				assetOut:   alladdr[4],
				amount:     ( dj_lqdr[0] * dj_lqdr[2] ) / ( dj_lqdr[1] + dj_lqdr[2] ),	//auto-floored
				userData:   abi.encode(0)
			});
			IBX(alladdr[13]).swap(F2L, FML, 1, block.timestamp);
		}


		//	Wake up, Neo...  Make the choice!
		{
			(,uint256[] memory r,) = IBX(alladdr[14]).getPoolTokens(allb32[1]);
			uint L = IERC20(alladdr[4]).balanceOf(address(this));

			//The RED PILL : Buy some mLQDR from the StableSwap DEX
			if(r[0] < r[1]) {

				if( L < r[1]-r[0] ) {

        			IAsset[] memory T = new IAsset[](2);
        			T[0] = IAsset(alladdr[4]);
        			T[1] = IAsset(alladdr[5]);
					uint256[] memory A = new uint256[](2);
        			A[0] = L;
        			A[1] = 0;

					bytes memory U = abi.encode(1, A, 1);
					//EXACT_TOKENS_IN_FOR_BPT_OUT (=enum JoinKind @1) "+" amountsIn (=A) "+" minimumBPT (1 = 10^-18 BPT)

					IBX.JoinPoolRequest memory R = IBX.JoinPoolRequest({	//T,A,U, fib ==> R
						assets:	 			T,
						maxAmountsIn:		A,	//amounts=amounts since we want to give it ALL, no slippage
						userData:			U,
						fromInternalBalance:false
					});

					IBX(alladdr[14]).joinPool( allb32[1], address(this), address(this), R);
				}

				else if ( L > r[1]-r[0] ) {

					IWrap( alladdr[5] ).deposit( ( L - (r[1] - r[0]) ) / 2 );

        			IAsset[] memory T = new IAsset[](2);
        			T[0] = IAsset(alladdr[4]);
        			T[1] = IAsset(alladdr[5]);
					uint256[] memory A = new uint256[](2);
        			A[0] = IERC20( alladdr[4] ).balanceOf(address(this));
        			A[1] = IERC20( alladdr[5] ).balanceOf(address(this));

					bytes memory U = abi.encode(1, A, 1);
					//EXACT_TOKENS_IN_FOR_BPT_OUT (=enum JoinKind @1) "+" amountsIn (=A) "+" minimumBPT (1 = 10^-18 BPT)

					IBX.JoinPoolRequest memory R = IBX.JoinPoolRequest({	//T,A,U, fib ==> R
						assets:	 			T,
						maxAmountsIn:		A,	//amounts=amounts since we want to give it ALL, no slippage
						userData:			U,
						fromInternalBalance:false
					});

					IBX(alladdr[14]).joinPool( allb32[1], address(this), address(this), R);
					//pegged now
				}
			}


			//The Blue PILL : Mint some new mLQDR using the purchased LQDR
			if(r[0]>r[1]) {

				if(L < r[0]-r[1]) {

					IWrap( alladdr[5] ).deposit( L );

        			IAsset[] memory T = new IAsset[](2);
        			T[0] = IAsset(alladdr[4]);
        			T[1] = IAsset(alladdr[5]);
					uint256[] memory A = new uint256[](2);
        			A[0] = 0;
        			A[1] = IERC20( alladdr[5] ).balanceOf(address(this));

					bytes memory U = abi.encode(1, A, 1);
					//EXACT_TOKENS_IN_FOR_BPT_OUT (=enum JoinKind @1) "+" amountsIn (=A) "+" minimumBPT (1 = 10^-18 BPT)

					IBX.JoinPoolRequest memory R = IBX.JoinPoolRequest({	//T,A,U, fib ==> R
						assets:	 			T,
						maxAmountsIn:		A,	//amounts=amounts since we want to give it ALL, no slippage
						userData:			U,
						fromInternalBalance:false
					});

					IBX(alladdr[14]).joinPool( allb32[1], address(this), address(this), R);
				}

				else if(L > r[0]-r[1]) {

					IWrap( alladdr[5] ).deposit( (L + r[0]-r[1]) / 2 );

        			IAsset[] memory T = new IAsset[](2);
        			T[0] = IAsset(alladdr[4]);
        			T[1] = IAsset(alladdr[5]);
					uint256[] memory A = new uint256[](2);
        			A[0] = IERC20( alladdr[4] ).balanceOf(address(this));
        			A[1] = IERC20( alladdr[5] ).balanceOf(address(this));

					bytes memory U = abi.encode(1, A, 1);
					//EXACT_TOKENS_IN_FOR_BPT_OUT (=enum JoinKind @1) "+" amountsIn (=A) "+" minimumBPT (1 = 10^-18 BPT)

					IBX.JoinPoolRequest memory R = IBX.JoinPoolRequest({	//T,A,U, fib ==> R
						assets:	 			T,
						maxAmountsIn:		A,	//amounts=amounts since we want to give it ALL, no slippage
						userData:			U,
						fromInternalBalance:false
					});

					IBX(alladdr[14]).joinPool( allb32[1], address(this), address(this), R);
					//pegged now
				}
			}
		}


		//At this point, we have the MPT-mLQDR/LQDR tokens (Pirates in the Matrix)
		//They are ready to be deposited into the Granary
		uint amt_mpt = IERC20(alladdr[15]).balanceOf(address(this));
		IGrain(alladdr[19]).deposit(amt_mpt);

		uint amt_grainz = IERC20(alladdr[19]).balanceOf(address(this));

		uint fpm = feePerMillion;
		uint fee;
		if(fpm > 0) {
			fee = (amt_grainz*fpm)/1e6;
			IERC20(alladdr[19]).transfer(dao, fee);
		}
		grainz=amt_grainz-fee;
		require(grainz >= grains, "Insufficient Output of GRAIN#5400");
		IERC20(alladdr[19]).transfer(msg.sender, grainz);

	}
}