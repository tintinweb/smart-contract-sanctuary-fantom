/**
 *Submitted for verification at FtmScan.com on 2022-10-06
*/

/**
 *Submitted for verification at FtmScan.com on 2022-10-06
*/

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

//ftm.guru's Universal On-chain TVL Calculator
//Source: https://ftm.guru/rawdata/tvl
interface ITVL {
	//Using Version = 6
	function p_lpt_coin_usd(address lp) external view returns(uint256);
	function p_lpt_usd(address u,address lp) external view returns(uint256);
	function p_t_coin_usd(address lp) external view returns(uint256);
	function coinusd() external view returns(uint256);
}

interface IMasterchef {	//NeoPool

	// Info of each user.
	struct UserInfo {
		uint256 amountLP;   // How many mLQDR-LQDR LP tokens the user has provided.
		uint256 amount;	 // How many mLQDR tokens the user has provided.
		uint256 rewardDebt; // Reward debt. See explanation below.
		uint256 rewardDebtMorph; // Reward debt. See explanation below.
	}

	function userInfo(address) external view returns (UserInfo memory);

	function getRewardPerSec() external view returns (uint, uint);

	function getRewardRates() external view returns (uint wftmRewards, uint morphRewards);

	function pendingMorph(address _user) external view returns (uint256);

	function pendingReward(address _user) external view returns (uint256);

	function outstandingRewards() external view returns (uint256 outstandingWFTM, uint256 outstandingMorph);	//What the Neo Pool earned from the MorpheusChef

	function updatePool() external;	//Internal booking of Neo Pool

	function deposit(uint256 _amount) external;

	function withdraw(uint256 _amount) external;

}

interface IM2P {

	function getSwapRatio() external view returns (uint256);

	function swap(uint) external;

	function swapMax() external;
}

interface IWrap {
	function deposit(uint256 _amount) external;
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




contract Granary
{
	using SafeMath for uint256;

	constructor (string memory _id)
	{
		want=IERC20( alladdr[15] );
		mc=IMasterchef( alladdr[16] );
		earn.push( alladdr[1]) ;
		earn.push( alladdr[2]) ;

		id=_id;//GRAIN#ID
		utvl=alladdr[17];

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
		IERC20(address(want)).approve(address(mc),uint256(-1));

		dao = 0x167D87A906dA361A10061fe42bbe89451c2EE584;
		treasury = dao;
	}
	modifier DAO {require(msg.sender==dao,"Only E.L.I.T.E. D.A.O. Treasury can rescue treasures!");_;}
	struct Elites {
		address ELITE;
		uint256 ELITES;
	}
	Elites[] public Eliteness;

	function pushElite(address elite, uint256 elites) public DAO {
		Eliteness.push(Elites({ELITE:elite,ELITES:elites}));
	}

	function pullElite(uint256 n) public DAO {
		Eliteness[n]=Eliteness[Eliteness.length-1];Eliteness.pop();
	}
	//@xref takeFee=eliteness(msg.sender)?false:true;

	function eliteness(address u) public view returns(bool)
	{
		if(Eliteness.length==0){return(false);}//When nobody is an Elite, well.. then.. nobody is an Elite.
		for(uint i;i<Eliteness.length;i++){
			if(IERC20(Eliteness[i].ELITE).balanceOf(u)>=Eliteness[i].ELITES)
			{
				return(true);
			}
		}
		return(false);
	}

	function config(//address _w,
		uint256 _mw, uint256 _wi, uint256 _pf, address _t, uint256 _df) public DAO
	{
		allnums[4] = _mw;
		treasury = _t;
		//Max 10%, 1e6 = 100%
		require(_wi<1e5,"!wi: high");allnums[3] = _wi;
		require(_pf<1e5,"!pf: high");allnums[2] = _pf;
		require(_df<1e5,"!df: high");allnums[1] = _df;
	}
	uint8 RG = 0;
	modifier rg {
		require(RG == 0,"!RG");
		RG = 1;
		_;
		RG = 0;
	}

	function isContract(address account) internal view returns (bool)
	{
		bytes32 codehash;
		bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
		assembly { codehash := extcodehash(account) }
		return (codehash != accountHash && codehash != 0x0);
	}
	//Using getter functions to circumvent "Stack too deep!" errors
	string public id;
	/*
	string public name;
	string public symbol;
	uint8  public decimals = 18;
	*/
	function name() public view returns(string memory){return(string(abi.encodePacked("ftm.guru/GRAIN/", id)));}
	function symbol() public view returns(string memory){return(string(abi.encodePacked("GRAIN#", id)));}
	function decimals() public pure returns(uint256){return(18);}

	uint256 public totalSupply;
	IERC20 public want;
	address[] public earn;
	IMasterchef public mc;
	bool public emergency = false;
	address public dao;
	address public treasury;
	address public utvl;
	/*
	uint8 public pid;
	uint256 public df = 1e3;//deposit fee = 0.1%, 1e6=100%
	uint256 public pf = 1e4;//performance fee to treasury, paid from profits = 1%, 1e6=100%
	uint256 public wi = 1e4;//worker incentive, paid from profits = 1%, 1e6=100%
	uint256 public mw;//Minimum earnings to reinvest
	uint64[2] ct;//Timestamp of first & latest Kompound
	*/
	//Using array to avoid "Stack too deep!" errors
	uint256[10] public allnums = [
		0,	//pid		0	   constant
		1e3,//df		1	   config, <= 10% (1e5), default 0.1%
		1e4,//pf		2	   config, <= 10% (1e5), default 1%
		1e4,//wi		3	   config, <= 10% (1e5), default 1%
		1e10,//mw		4	   config, default 1 (near zero)
		0,	//ct[0]		5	   nonce, then constant
		0,	//ct[n]		6	   up only
		0,	//ct[n-1]	7	   up only
		0,	//aum[n]	8	   last
		0	//aum[n-1]	9	   previous
	];

	address[19] public alladdr = [
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
		0xe533779d1e6fF3D5cfCEeD3DE761852E6C93DC8b	//	18	vAMM-mLQDR/wFTM (Solidly)
	];

	//Using arrays to avoid "Stack too deep!" errors
	bytes32[2] public allb32 = [
		bytes32(0x5e02ab5699549675a6d3beeb92a62782712d0509000200000000000000000138),	//	0	BPT-Pirate
		0x85660a3538579fdd27dc77d0f22d0c42b92d8114000200000000000000000001				//	1	MPT-mLQDR-LQDR
	];

	event  Approval(address indexed src, address indexed guy, uint wad);
	event  Transfer(address indexed src, address indexed dst, uint wad);
	event	WorkDone(address indexed __ben, uint __tvl, uint __pf, uint __wi, uint __when, uint __aum, uint __ts, uint __price);
	event	Deposit(address indexed user, uint wants, uint grains);
	event	Withdraw(address indexed user, uint wants, uint grains);
	mapping (address => uint) public  balanceOf;
	mapping (address => mapping (address => uint)) public  allowance;

	function approve(address guy) public returns (bool) {
		return approve(guy, uint(-1));
	}

	function approve(address guy, uint wad) public returns (bool) {
		allowance[msg.sender][guy] = wad;
		emit Approval(msg.sender, guy, wad);
		return true;
	}

	function transfer(address dst, uint wad) public returns (bool) {
		return transferFrom(msg.sender, dst, wad);
	}

	function transferFrom(address src, address dst, uint wad) public returns (bool)
	{
		require(balanceOf[src] >= wad,"Insufficient Balance");
		if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
			require(allowance[src][msg.sender] >= wad);
			allowance[src][msg.sender] -= wad;
		}
		balanceOf[src] -= wad;
		balanceOf[dst] += wad;
		emit Transfer(src, dst, wad);
		return true;
	}

	function deposit(uint256 _amt) public rg
	{
		require(!emergency,"Its an emergency. Please don't deposit.");
		//require(isContract(msg.sender)==false,"Humans only");
		//require(msg.sender==tx.origin,"Humans only");

		//hardWork()
		//allnums[4]===mw, min work : smallest harvest
		salvage();
		if(IERC20(earn[0]).balanceOf(address(this)) > allnums[4]) {work(address(this));}

		//Some fancy math to take care of Fee-on-Transfer tokens
		uint256 vbb = want.balanceOf(address(this));
		uint256 mcbb = mc.userInfo(address(this)).amount;
		require(want.transferFrom(msg.sender,address(this),_amt), "Unable to onboard");
		uint256 vba = want.balanceOf(address(this));
		uint256 D = vba.sub(vbb,"Dirty deposit");
		mc.deposit(D);
		//Some more fancy math to take care of Deposit Fee
		uint256 mcba = mc.userInfo(address(this)).amount;
		uint256 M = mcba.sub(mcbb,"Dirty stake");
		//require(M>mindep,"Deposit Too Low");
		uint256 _mint = 0;
		(totalSupply > 0)
			// k: SharePerDeposit should be constant before & after
			// Mint = SharesPerDeposit * IncreaseInDeposit
			// bal += (totalSupply / oldDeposits) * thisDeposit
			?	_mint = ( M.mul(totalSupply) ).div(mcbb)
			:	_mint = M;
		totalSupply += _mint;
		uint256 _fee;
		//allnums[1]===df, deposit fee
		if(allnums[1]>0){_fee = eliteness(msg.sender)? 0 : (_mint.mul(allnums[1])).div(1e6);}//gas savings
		if(_fee>0)//gas savings
		{
			balanceOf[treasury] += _fee;
			emit Transfer(address(0), treasury, _fee);
		}
		balanceOf[msg.sender] += _mint.sub(_fee);
		emit Deposit(msg.sender, _amt, _mint.sub(_fee));
		emit Transfer(address(0), msg.sender, _mint.sub(_fee));
	}

	function withdraw(uint256 _amt) public rg
	{
		require(!emergency,"Its an emergency. Use emergencyWithdraw() please.");
		require(balanceOf[msg.sender] >= _amt,"Insufficient Balance");

		//hardWork()
		//allnums[4]===mw, min work : smallest harvest
		salvage();
		if(IERC20(earn[0]).balanceOf(address(this)) > allnums[4]) {work(address(this));}

		//Burn _amt of Vault Tokens
		balanceOf[msg.sender] -= _amt;
		uint256 ts = totalSupply;	//cash for future needs
		totalSupply -= _amt;
		emit Transfer(msg.sender, address(0), _amt);
		uint256 vbb = want.balanceOf(address(this));
		uint256 mcbb = mc.userInfo(address(this)).amount;
		// W  = DepositsPerShare * SharesBurnt
		uint256 W = ( _amt.mul(mcbb) ).div(ts);
		mc.withdraw(W);
		uint256 vba = want.balanceOf(address(this));
		uint256 D = vba.sub(vbb,"Dirty withdrawal");
	   	require(want.transfer(msg.sender,D), "Unable to deboard");
		emit Withdraw(msg.sender, D, _amt);
	}

	function doHardWork() public rg
	{
		if(Eliteness.length > 0){require(eliteness(msg.sender),"Elites only!");}
		salvage();
		require(IERC20(earn[0]).balanceOf(address(this)) > allnums[4], "Not much work to do!");
		work(msg.sender);
	}

	function salvage() public
	{
		//harvest()
		mc.deposit(0);
	}

	function work(address ben) internal
	{
		require(!emergency,"Its an emergency. Use emergencyWithdraw() please.");
		//has inputs from salvage() if this work is done via doHardWork()

		//Convert all MORPH to PILLS
		IM2P(alladdr[6]).swapMax();

		//Take Pills to hallucinate upon Fantom of the Opera
		{
			//Doing JIT™ (Just-in-Time) Psuedo DEX-aggregation
			uint[3] memory dj_morph = [
				IERC20(alladdr[3]).balanceOf(address(this)),	//Current Prescribed Dosage
				IERC20(alladdr[3]).balanceOf( alladdr[10] ),	//PILLS offered by Morpheus
				IERC20(alladdr[3]).balanceOf( alladdr[11] )     //Smells like Pill Spirit
			];

			address[] memory swapt;
			swapt[0] = alladdr[3];
			swapt[1] = alladdr[1];
			IRouter(alladdr[7])
			.swapExactTokensForTokensSupportingFeeOnTransferTokens(
				( dj_morph[0] * dj_morph[1] ) / ( dj_morph[1] + dj_morph[2] ),	//auto-floored
				1,
				swapt,
				address(this),
				block.timestamp
			);

			IRouter(alladdr[8])
			.swapExactTokensForTokensSupportingFeeOnTransferTokens(
				( dj_morph[0] * dj_morph[2] ) / ( dj_morph[1] + dj_morph[2] ),	//auto-floored
				1,
				swapt,
				address(this),
				block.timestamp
			);
		}

		//Get Drunk and Drive towards the shady farmer
		{
			//Doing JIT™ (Just-in-Time) Psuedo DEX-aggregation
			uint[3] memory dj_lqdr = [
				IERC20(alladdr[4]).balanceOf(address(this)),	//Current Prescribed Liquids
				IERC20(alladdr[4]).balanceOf( alladdr[12] ),	//The Driving Spirit
				1	//Inside Beethoven's Liquid Closet
			];

			(,uint256[] memory _bxb,) = IBX(alladdr[13]).getPoolTokens(allb32[0]);
			dj_lqdr[2] = _bxb[0];

			IRouter.route[] memory swapr;
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




		uint256 D = want.balanceOf(address(this));
		uint256 mcbb = mc.userInfo(address(this)).amount;
		mc.deposit(D);
		uint256 mcba = mc.userInfo(address(this)).amount;
		uint256 M = mcba.sub(mcbb,"Dirty stake");
		//Performance Fee Mint, conserves TVL
		uint256 _mint = 0;
		//allnums[5] & allnums[6] are First & Latest Compound's timestamps. Used in info() for APY of AUM.
		if(allnums[5]==0){allnums[5]=uint64(block.timestamp);allnums[8]=aum();}//only on the first run
		allnums[7]=allnums[6];allnums[6]=uint64(block.timestamp);
		allnums[9]=allnums[8];allnums[8]=aum();
		(totalSupply > 0)
			// k: SharePerDeposit should be constant before & after
			// Mint = SharesPerDeposit * IncreaseInDeposit
			// bal += (totalSupply / oldDeposits) * thisDeposit
			?	_mint = ( M.mul(totalSupply) ).div(mcbb)
			:	_mint = M;
		//allnums[2] === pf, Performance Fee
		balanceOf[treasury] += (_mint.mul(allnums[2])).div(1e6);
		//Worker Incentive Mint, conserves TVL
		address worker = ben == address(this) ? treasury : ben;
		//allnums[3] === wi, Worker Incentive
		balanceOf[worker] += (_mint.mul(allnums[3])).div(1e6);
		totalSupply += ((_mint.mul(allnums[2])).div(1e6)).add( (_mint.mul(allnums[3])).div(1e6) );
		emit Transfer(address(0), treasury, (_mint.mul(allnums[2])).div(1e6));
		emit Transfer(address(0), worker, (_mint.mul(allnums[3])).div(1e6));


		uint _aum_ = aum();
		uint _tvl_ = tvl();
		uint _ts_ = totalSupply;
		if (block.timestamp >= harvestLog[harvestLog.length - 1].timestamp + 60) {
            harvestLog.push(
                Harvest({
                    timestamp: block.timestamp,
                    //assets: _aum_,
                    //shares: ts,
                    price: (_aum_*1e18) / _ts_
                    //tvl: _tvl_
                })
            );
        }

		//To paint them nice cHaRtZ_/^.^/`-*
		emit WorkDone(
			ben, //Benefeciary
			_tvl_,
			(_mint.mul(allnums[2])).div(1e6),	//Performace fee
			(_mint.mul(allnums[3])).div(1e6),	//Worker Incentive
			block.timestamp,	//Harvest({W,A,S,P})
			_aum_,
			_ts_,
			(_aum_*1e18) / _ts_
		);

	}





	function declareEmergency() public DAO {
		require(!emergency,"Emergency already declared.");
		//Neo Pool does not support emergencyWithdraw
		//mc.emergencyWithdraw(allnums[0]);
		mc.withdraw( mc.userInfo(address(this)).amount );
		emergency=true;
	}

	function revokeEmergency() public DAO
	{
		require(emergency,"Emergency not declared.");
		uint256 D = want.balanceOf(address(this));
		mc.deposit(D);
		emergency=false;
	}

	function emergencyWithdraw(uint256 _amt) public rg
	{
		require(emergency,"Its not an emergency. Use withdraw() instead.");
		require(balanceOf[msg.sender] >= _amt,"Insufficient Balance");
		uint256 ts = totalSupply;
		//Burn _amt of Vault Tokens
		balanceOf[msg.sender] -= _amt;
		totalSupply -= _amt;
		emit Transfer(msg.sender, address(0), _amt);
		uint256 vbb = want.balanceOf(address(this));
		uint256 W = ( _amt.mul(vbb) ).div(ts);
	   	require(want.transfer(msg.sender,W), "Unable to deboard");
	}




	function rescue(address tokenAddress, uint256 tokens) public DAO returns (bool success)
	{
		//Generally, there are not supposed to be any tokens in this contract itself:
		//Upon Deposits, the assets go from User to the MasterChef of Strategy,
		//Upon Withdrawals, the assets go from MasterChef of Strategy to the User, and
		//Upon HardWork, the harvest is reconverted to want and sent to MasterChef of Strategy.
		//Never allow draining main "want" token from the Granary:
		//Main token can only be withdrawn using the EmergencyWithdraw
		require(tokenAddress != address(want), "Funds are Safu in emergency!");
		if(tokenAddress==address(0)) {(success, ) = dao.call{value:tokens}("");return success;}
		else if(tokenAddress!=address(0)) {return IERC20(tokenAddress).transfer(dao, tokens);}
		else return false;
	}

	//Read-Only Functions
	//Useful for performance analysis
	function info() public view returns (uint256, uint256, uint256, uint256, uint256[] memory, IMasterchef.UserInfo memory, uint256, uint256) {
		//uint256 aum = mc.userInfo(allnums[0],address(this)).amount + IERC20(want).balanceOf(address(this));
		uint256 roi = aum()*1e18/totalSupply;//ROI: 1e18 === 1x
		uint256 rrr = ((roi-1e18)*(365*86400)*100)/(allnums[6]-allnums[5]);//APY: 1e18 === 1%
		(uint rf, uint rm) = mc.getRewardRates();
		//uint assets = ( aum() * tvl() ) / 1e18;
		uint[] memory aprs;
		aprs[0] = ( (rf*ITVL(utvl).coinusd() * 86400 * 365) / 1e18 );
		aprs[1] = ( ( ( rm*ITVL(utvl).p_t_coin_usd(alladdr[10]) * 86400 * 365 * 100) / IM2P( alladdr[6] ).getSwapRatio() ) / 1e18 );
		return(
			aum(),
			roi,
			rrr,
			aprs[0] + aprs[1],
			aprs,
			mc.userInfo(address(this)),
			mc.pendingReward(address(this)),
			mc.pendingMorph(address(this))
		);
	}

	function aum() public view returns (uint256) {
		return mc.userInfo(address(this)).amount + IERC20(want).balanceOf(address(this));
	}

	function apyr() public view returns (uint256,uint256,uint256,uint256,uint256)
	{
		uint256 elapsed = allnums[6]-allnums[7];
		uint256 gained	= allnums[8]-allnums[9];
		uint256 apr = ( ( (gained * 1e18 * 365 days) / elapsed) / allnums[9] );
		//uint256 apy = (1 + apr * elapsed / 365 days) ** (365 days / elapsed) - 1;
		//uint256 apy = ( (1 + (gained / allnums[9])) ** (365 days / elapsed) ) - 1;
		return(apr,allnums[6],allnums[7],allnums[8],allnums[9]);
	}

	//TVL in USD, 1e18===$1.
	//Source code Derived from ftm.guru's Universal On-chain TVL Calculator: https://ftm.guru/rawdata/tvl
	function tvl() public view returns(uint256)
	{
		ITVL tc = ITVL(utvl);
		//uint256 aum = mc.userInfo(allnums[0],address(this)).amount + IERC20(want).balanceOf(address(this));
		//return ((tc.coinusd()).mul(aum)).div(1e18);
		(, uint256[] memory tn, ) = IBX( alladdr[14] ).getPoolTokens(allb32[1]);
		uint _ts = IERC20(alladdr[15]).totalSupply();

		return (
			( ( tn[0] * aum() / _ts ) * tc.p_t_coin_usd(alladdr[12]) ) / 1e18
			+
			( ( tn[1] * aum() / _ts ) * tc.p_t_coin_usd(alladdr[18]) ) / 1e18
		);
	}


	//Using Reaper.Farm's implementation as example for moving-average APR calculations
	//This is a secondary estimate based on storing harvest data on-chain
	//Primary APR & APY figure are still provided by old "apyr()" & "info()" functions of Kompound Protocol

	struct Harvest {
		uint timestamp;
		//uint assets;
		//uint share;
		uint price;
	}

	Harvest[] public harvestLog;

	function harvestLogLength() external view returns (uint256) {
		return harvestLog.length;
	}

	/**
	 * @dev Traverses the harvest log backwards _n items,
	 *	  and returns the average APR calculated across all the included
	 *	  log entries. APR is multiplied by PERCENT_DIVISOR to retain precision.
	 */
	function averageAPRAcrossLastNHarvests(int256 _n) external view returns (int256) {
		require(harvestLog.length >= 2);

		int256 runningAPRSum;
		int256 numLogsProcessed;

		for (uint256 i = harvestLog.length - 1; i > 0 && numLogsProcessed < _n; i--) {
			runningAPRSum += calculateAPRUsingLogs(i - 1, i);
			numLogsProcessed++;
		}

		return runningAPRSum / numLogsProcessed;
	}
	 /**
	 * @dev Project an APR using the vault share price change between harvests at the provided indices.
	 */
	function calculateAPRUsingLogs(uint256 _startIndex, uint256 _endIndex) public view returns (int256) {
		Harvest storage start = harvestLog[_startIndex];
		Harvest storage end = harvestLog[_endIndex];
		bool increasing = true;
		if (end.price < start.price) {
			increasing = false;	//should not be possible, but still...
		}

		uint256 unsignedSharePriceChange;
		if (increasing) {
			unsignedSharePriceChange = end.price - start.price;
		} else {
			unsignedSharePriceChange = start.price - end.price;
		}

		uint256 unsignedPercentageChange = (unsignedSharePriceChange * 1e18) / start.price;
		uint256 timeDifference = end.timestamp - start.timestamp;

		uint256 yearlyUnsignedPercentageChange = (unsignedPercentageChange * (364 days)) / timeDifference;
		//We use full ^18 precision
		//yearlyUnsignedPercentageChange /= 1e14; // restore basis points precision

		if (increasing) {
			return int256(yearlyUnsignedPercentageChange);
		}

		return -int256(yearlyUnsignedPercentageChange);
	}

	//Extension
	//Allows this Granary to leverage its position of LQDR via mLQDR deposits
	//Useful if in future Morpheus implements voting. Then our depositors could have voting rights!
	//Also allows for a bribe-layer based on the Votium-model, and many other things.
	mapping (address=>bool) public isExtensionContract;
	function setExtensions(address[] memory _a, bool[] memory _b) public DAO {
		for(uint i;i<_a.length;i++) {
			isExtensionContract[_a[i]] =  _b[i];
		}
	}

	//Code borrowed from our buckets project!
    function customCall(address _to, bytes calldata _data) public payable returns(bytes memory) {return customCall(_to, 0, _data) ;}
    function customCall(address[] memory _tos, uint256[] memory _amounts, bytes[] calldata _datas) public payable returns(bytes[] memory retdata)
    {
    	require(_tos.length==_amounts.length&&_tos.length==_datas.length,"Args Mismatch");
    	for(uint i=0;i<_tos.length;i++)
    	{
    		retdata[i] = customCall(_tos[i],_amounts[i],_datas[i]);
    	}
    }
    function customCall(address to, uint256 amount, bytes calldata _data) public rg payable returns(bytes memory)
    {
    	//rg: reentrency guard. no funny business allowed c(0>0)e
		require(msg.sender==dao || isExtensionContract[msg.sender],"Ser you are NOT authorized!!");
		require(to != address(mc), "Sorry, touching our user's position is prohibited.");
		require(to != address(want), "Sorry, touching user's LP is prohibited as well.");
		require(to != address(this), "Sorry, touching yourself from the back is gross.");
        (bool success, bytes memory returndata) = to.call{value:amount}(_data);
        if (!success) {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("CC: Failed!");
            }
        } else {
            return returndata;
        }
    }




}