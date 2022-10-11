/**
 *Submitted for verification at FtmScan.com on 2022-10-11
*/

/*

						Contact us at:
				https://discord.gg/QpyfMarNrV
					https://t.me/FTM1337

This contract is the best DEX-Aggregator to sell SOLID.
This contract will be used by Guru Network to acquire resources
 to buy the possible dip in price on the Etherside.
This contract is ideal for Selling a big amount without incurring
 high slippage with minimal Price Impact on SOLID.

If this contract helps you save money, consider buying some ELITE.

ELITE: The ftm.guru Token
 0xf43Cc235E686d7BC513F53Fbffb61F760c3a1882 (Fantom Opera Network)


			Join our Community & be a part of our DAO:
				https://discord.gg/QpyfMarNrV
					42 > 69 > 420 > 1337



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


contract sellSOLID {

	address public dao = 0x167D87A906dA361A10061fe42bbe89451c2EE584;

	address[17] public alladdr = [
		0x888EF71766ca594DED1F0FA3AE64eD2941740A20,	//	0	SOLID
		0xe4bc39fdD4618a76f6472079C329bdfa820afA75,	//	1	vamm-ftm @ solidli
		0xc8Cc1B89820791665b6f26b00b3111b00e021f19,	//	2	ftm @ spooki
		0x62E2819Dd417F3b430B6fa5Fd34a49A377A02ac8,	//	3	samm-solidsex @solidli
		0xabf18df0373749182aE2a15726D49452AFa78EEC,	//	4	vamm-solidsex @solidli
		0x547a85387Ec9Fc29eA8Df802BfcA948cDB45E187,	//	5	ftm @ protofi
		0xC6C22184ce4F2c2A83c8399a29184634Bf9E0514,	//	6	usdc @ spooki
		0xa3bf7336FDbCe054c4B5Bad4FF8d79539dB2a2b3,	//	7	vamm-oxsolid @ solidli
		0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce,	//	8	beets vault
		0xF02382e9c35D5043aA20855d1EeaA959E2FF6590, //	9	solidi router
		0xF4C587a0972Ac2039BFF67Bc44574bB403eF5235,	//	10	protofi router
		0xF491e7B69E4244ad4002BC14e878a34207E38c29,	//	11	spooki router
		0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83,	//	12	WFTM
		0x04068DA6C83AFCFA0e13ba15A6696662335D5B75,	//	13	USDC
		0xF24Bcf4d1e507740041C9cFd2DddB29585aDCe1e, //	14	BEETS
		0xDA0053F0bEfCbcaC208A3f867BB243716734D809,	//	15	oxSOLID
		0x41adAc6C1Ff52C5e27568f27998d747F7b69795B	//	16	SOLIDsex
	];

	bytes32[1] public allb32 = [
		bytes32(0xf2b2103e1351c4d47b27efc8100bb264364fa92c00020000000000000000025a)
	];

	IERC20 SOLID = IERC20(alladdr[0]);

	constructor() {
		SOLID.approve(alladdr[8],uint256(-1));
		SOLID.approve(alladdr[9],uint256(-1));
		SOLID.approve(alladdr[10],uint256(-1));
		SOLID.approve(alladdr[11],uint256(-1));
	}

	function depths() public view returns (uint[10] memory) {
		uint[10] memory amts;
		amts[0] = 1;
		amts[1] = SOLID.balanceOf(alladdr[1]);	//	vamm-ftm @ solidli
		amts[2] = SOLID.balanceOf(alladdr[2]);	//	ftm @ spooki
		amts[3] = SOLID.balanceOf(alladdr[3]);	//	samm-solidsex @solidli
		amts[4] = SOLID.balanceOf(alladdr[4]);	//	vamm-solidsex @solidli
		amts[5] = SOLID.balanceOf(alladdr[5]);	//	ftm @ protofi
		amts[6] = SOLID.balanceOf(alladdr[6]);	//	usdc @ spooki
		amts[7] = SOLID.balanceOf(alladdr[7]);	//	vamm-oxsolid @ solidli
		(,uint256[] memory _bxb,) = IBX(alladdr[8]).getPoolTokens(allb32[0]);
		amts[8] = _bxb[0];

		//depth sum
		amts[9] = amts[1] + amts[2] + amts[3] + amts[4] + amts[5] + amts[6] + amts[7] + amts[8];
		return amts;
	}


	function sell(uint AMT) public {
		//Caller of this function must have approved this contract to spend
		// at least <AMT> amount of SOLID. 10^18 means 1 SOLID.

		//	User deposits
		require(SOLID.transferFrom(msg.sender,address(this),AMT), "unable to onboard SOLID!");
		//	o.2% performance fee, paid in SOLID :)
		if(msg.sender != dao) {SOLID.transfer(dao, AMT/200);AMT=AMT-(AMT/200);}

		uint[10] memory DEP = depths();


		//	1	vamm-ftm @ solidli
		{
			IRouter.route[] memory r = new IRouter.route[](1);
			r[0] = IRouter.route({
				from: alladdr[0],
				to: alladdr[12],
				stable:false
			});
			IRouter(alladdr[9]).swapExactTokensForTokens(
				(AMT*DEP[1])/DEP[9],
				1,
				r,
				msg.sender,
				block.timestamp
			);
		}

		//	2	ftm @ spooki
		{
			address[] memory r = new address[](2);
			r[0] = alladdr[0];
			r[1] = alladdr[12];
			IRouter(alladdr[11])
			.swapExactTokensForTokensSupportingFeeOnTransferTokens(
				(AMT*DEP[2])/DEP[9],
				1,
				r,
				msg.sender,
				block.timestamp
			);
		}

		//	3	samm-solidsex @solidli
		{
			IRouter.route[] memory r = new IRouter.route[](1);
			r[0] = IRouter.route({
				from: alladdr[0],
				to: alladdr[16],
				stable:true
			});
			IRouter(alladdr[9]).swapExactTokensForTokens(
				(AMT*DEP[3])/DEP[9],
				1,
				r,
				msg.sender,
				block.timestamp
			);
		}


		//	4	vamm-solidsex @solidli
		{
			IRouter.route[] memory r = new IRouter.route[](1);
			r[0] = IRouter.route({
				from: alladdr[0],
				to: alladdr[16],
				stable:false
			});
			IRouter(alladdr[9]).swapExactTokensForTokens(
				(AMT*DEP[4])/DEP[9],
				1,
				r,
				msg.sender,
				block.timestamp
			);
		}


		//	5	ftm @ protofi
		{
			address[] memory r = new address[](2);
			r[0] = alladdr[0];
			r[1] = alladdr[12];
			IRouter(alladdr[10])
			.swapExactTokensForTokensSupportingFeeOnTransferTokens(
				(AMT*DEP[5])/DEP[9],
				1,
				r,
				msg.sender,
				block.timestamp
			);
		}


		//	6	usdc @ spooki
		{
			address[] memory r = new address[](2);
			r[0] = alladdr[0];
			r[1] = alladdr[13];
			IRouter(alladdr[11])
			.swapExactTokensForTokensSupportingFeeOnTransferTokens(
				(AMT*DEP[6])/DEP[9],
				1,
				r,
				msg.sender,
				block.timestamp
			);
		}


		//	7	vamm-solidsex @solidli
		{
			IRouter.route[] memory r = new IRouter.route[](1);
			r[0] = IRouter.route({
				from: alladdr[0],
				to: alladdr[15],
				stable:false
			});
			IRouter(alladdr[9]).swapExactTokensForTokens(
				(AMT*DEP[7])/DEP[9],
				1,
				r,
				msg.sender,
				block.timestamp
			);
		}


		{
			IBX.FundManagement memory FML = IBX.FundManagement({
				sender:             address(this),
				fromInternalBalance:false,
				recipient:          payable(address(msg.sender)),
				toInternalBalance:  false
			});
			IBX.SingleSwap memory F2L = IBX.SingleSwap({
				poolid: 	allb32[0],
				kind:	    IBX.SwapKind.GIVEN_IN,
				assetIn:    alladdr[0],
				assetOut:   alladdr[14],
				amount:     (AMT*DEP[8])/DEP[9],	//auto-floored
				userData:   abi.encode(0)
			});
			IBX(alladdr[8]).swap(F2L, FML, 1, block.timestamp);

		}

		{	//	Leftover Balances
			address left = alladdr[0];
			uint bal = IERC20(left).balanceOf(address(this));
			if(bal>0){IERC20(left).transfer(msg.sender,bal);}
		}
		{	//	Leftover Balances
			address left = alladdr[12];
			uint bal = IERC20(left).balanceOf(address(this));
			if(bal>0){IERC20(left).transfer(msg.sender,bal);}
		}
		{	//	Leftover Balances
			address left = alladdr[13];
			uint bal = IERC20(left).balanceOf(address(this));
			if(bal>0){IERC20(left).transfer(msg.sender,bal);}
		}
		{	//	Leftover Balances
			address left = alladdr[14];
			uint bal = IERC20(left).balanceOf(address(this));
			if(bal>0){IERC20(left).transfer(msg.sender,bal);}
		}
		{	//	Leftover Balances
			address left = alladdr[15];
			uint bal = IERC20(left).balanceOf(address(this));
			if(bal>0){IERC20(left).transfer(msg.sender,bal);}
		}
		{	//	Leftover Balances
			address left = alladdr[16];
			uint bal = IERC20(left).balanceOf(address(this));
			if(bal>0){IERC20(left).transfer(msg.sender,bal);}
		}


	}


	function rescue(address tokenAddress, uint256 tokens) public returns (bool success)
	{
        require(msg.sender==dao,"Only DAO can rescue things!");
		//Generally, there are not supposed to be any tokens in this contract itself:
		if(tokenAddress==address(0)) {(success, ) = dao.call{value:tokens}("");return success;}
		else if(tokenAddress!=address(0)) {return IERC20(tokenAddress).transfer(dao, tokens);}
		else return false;
	}
}