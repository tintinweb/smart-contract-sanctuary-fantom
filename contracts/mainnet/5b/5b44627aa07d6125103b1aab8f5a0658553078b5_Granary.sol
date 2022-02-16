/**
 *Submitted for verification at FtmScan.com on 2022-02-16
*/

//SPDX-License-Identifier: UNLICENSED
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




					*************************
					**                     **
					**  GRANARY & WORKERS  **
					**    ftm.guru/GRAIN   **
					**  kcc.guru/kompound  **
					**    mtv.guru/GRAIN   **
					**                     **
					*************************


Create a farm & vault for your own projects for free with ftm.guru

            			Contact us at:
			https://discord.com/invite/QpyfMarNrV
        			https://t.me/FTM1337

*/
/*
	- KOMPOUND PROTOCOL -
    https://kcc.guru/kompound
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
        https://t.me/kccguru
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


		*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*

		This is a special Contract from ftm.guru for OneRing.finance.
		+ Gas fee is not optimized, uses multiple external calls & transfers for ease of readability & understanding.
		+ Trade Value is Maximized
		+ Attempts 100% Efficieny by balancing fees paid instead of tokens added
		+ Net fee incurred at all 3-party contracts is 0.25% of Total
		+ Does psuedo-dex-aggregation to avoid paying 0.75% trade fee from hopping

*/


pragma solidity ^0.7.6;
pragma abicoder v2;

//ftm.guru's Universal On-chain TVL Calculator
//Source: https://ftm.guru/rawdata/tvl
interface ITVL {
	//Using Version = 6
	function p_lpt_coin_usd(address lp) external view returns(uint256);
	function p_lpt_usd(address u,address lp) external view returns(uint256);
}

interface IMasterchef {
    struct PoolInfo {
        // we have a fixed number of BEETS tokens released per block, each pool gets his fraction based on the allocPoint
        uint256 allocPoint; // How many allocation points assigned to this pool. the fraction BEETS to distribute per block.
        uint256 lastRewardBlock; // Last block number that BEETS distribution occurs.
        uint256 accBeetsPerShare; // Accumulated BEETS per LP share. this is multiplied by ACC_BEETS_PRECISION for more exact results (rounding errors)
    }
	// Info of each user.
	struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
	}

	function deposit(uint256 _pid, uint256 _amount, address _to) external;

	function withdrawAndHarvest(uint256 _pid, uint256 _amount, address _to) external;

	function emergencyWithdraw(uint256 _pid, address _to) external;

	function userInfo(uint256, address) external view returns (UserInfo memory);

	function poolInfo(uint256) external view returns (PoolInfo memory);

	function totalAllocPoint() external view returns (uint256);

	function pendingBeets(uint256 _pid, address _user) external view returns (uint256);

	function rewarder(uint256) external view returns (address);

	function harvest(uint256 _pid, address _to) external;
}

interface IRewarder {
	function pendingToken(uint256 _pid, address _user) external view returns (uint256);
}

interface IERC20 {
	/**
	 * @dev Returns the amount of token decimals.
	 */

	function decimals() external view returns (uint);
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

struct SingleSwap {
    bytes32 poolid;
    SwapKind kind;
    address assetIn;
    address assetOut;
    uint256 amount;
    bytes userData;
}

struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address recipient;
    bool toInternalBalance;
}
/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}
struct JoinPoolRequest {
    IAsset[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
}

enum SwapKind { GIVEN_IN, GIVEN_OUT }
enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT }

interface IBX {
    function swap(SingleSwap memory singleSwap, FundManagement memory funds, uint256 limit, uint256 deadline) external returns (uint256);
	function getPoolTokens(bytes32 poolId) external view returns(address[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);
	function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request) external payable;
}

interface IBPT {
	function getNormalizedWeights() external view returns(uint256[] memory);
}


contract Granary
{
	using SafeMath for uint256;

	constructor ()
	{
		want=IERC20(alladdr[6]);
		mc=IMasterchef(alladdr[0]);
		//allnums[0]=_p;
		//router = _R;
		//route = _r;
		//id=_id;//GRAIN#ID

		//doesnt use tvlGuru < v6, which was the latest version at the time of deployment of this GRAIN.
		//utvl=0x0786c3a78f5133F08C1c70953B8B10376bC6dCad;

		//Approvals
		//B-x.MC to take what it may want
		want.approve(address(mc),uint256(-1));
		//B-x to sell BEETS we earn
		IERC20(alladdr[3]).approve(alladdr[1],uint256(-1));
        //Spooky to sell USDC
		IERC20(alladdr[5]).approve(alladdr[2],uint256(-1));
        //Spooky to sell RING
		IERC20(alladdr[4]).approve(alladdr[2],uint256(-1));
		//B-x to join RING
		IERC20(alladdr[3]).approve(alladdr[1],uint256(-1));
		//B-x to join USDC
		IERC20(alladdr[5]).approve(alladdr[1],uint256(-1));
		dao = 0x167D87A906dA361A10061fe42bbe89451c2EE584;
		treasury = dao;
	}
	modifier DAO {require(msg.sender==dao,"Only E.L.I.T.E. D.A.O., please!");_;}
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
		if(Eliteness.length==0){return(true);}//When nobody is an Elite, everyone is an Elite.
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
	//Using getter functions instead of variables to circumvent "Stack too deep!" errors
	//string public id = "4801";
	function id() public pure returns(string memory){return("4801");}
	function name() public pure returns(string memory){return("ftm.guru/GRAIN/4801");}//string(abi.encodePacked("ftm.guru/GRAIN/", id)));}
	function symbol() public pure returns(string memory){return("GRAIN#4801");}//string(abi.encodePacked("GRAIN#", id)));}
	function decimals() public view returns(uint256){return want.decimals();}
	uint256 public totalSupply;
	//earn & want need to be kept independently readable for our Binary Options platform (ftm.guru/bo).
	function earn() public view returns(address,address){return(alladdr[3],alladdr[4]);}
	IERC20 public want;		//returns(address), setup in constructor
	IMasterchef public mc;	//returns(address), setup in constructor
	bool public emergency = false;
	address public dao;		//returns(address), setup in constructor
	address public treasury;//returns(address), setup in constructor
	//GRAIN#4801 doesnt use tvlGuru <= v6.3.0, which was the latest version at the time of deployment of this GRAIN.
	//address public utvl;
	/*
	uint8 public pid;
	uint256 public df = 1e3;//deposit fee = 0.1%, 1e6=100%
	uint256 public pf = 1e4;//performance fee to treasury, paid from profits = 1%, 1e6=100%
	uint256 public wi = 1e4;//worker incentive, paid from profits = 1%, 1e6=100%
	uint256 public mw;//Minimum earnings to reinvest
	uint64[3] ct;//Timestamp of first-ever & 2 latest Kompounds
	*/

	//Using arrays to avoid "Stack too deep!" errors
	bytes32 public BPT_RING = 0xc9ba718a71bfa34cedea910ac37b879e5913c14e0002000000000000000001ad;
	bytes32 public BPT_OPUS = 0x03c6b3f09d2504606936b1a4decefad204687890000200000000000000000015;// = [

    //no point in generalizing addressbook, since new strategies for other Granaries
	//would anyways employ different strategies whenever beethoven is involved with 2-8 tokens
	//rn, we're better off saving gas on deployment than making this too complex with more constructor modules
	address[8] public alladdr = [
		0x8166994d9ebBe5829EC86Bd81258149B87faCfd3,//0	BMC			.mc
		0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce,//1	B-x
		0xF491e7B69E4244ad4002BC14e878a34207E38c29,//2	Spooky		.router
		0xF24Bcf4d1e507740041C9cFd2DddB29585aDCe1e,//3	BEETS
		0x582423C10c9e83387a96d00A69bA3D11ee47B7b5,//4	RING
		0x04068DA6C83AFCFA0e13ba15A6696662335D5B75,//5	USDC
		0xC9Ba718A71bFA34cedEa910AC37B879e5913c14e,//6	BPT-RING	.
		0x03c6B3f09D2504606936b1A4DeCeFaD204687890 //7	BPT-10/138	.
	];
	//generic GRAIN variables, common to all Granaries
	uint256[7] public allnums = [
		42,		//pid		0       constant
		1e3,	//df		1       config, <= 10% (1e5), default 0.1%
		1e4,	//pf		2       config, <= 10% (1e5), default 1%
		1e4,	//wi		3       config, <= 10% (1e5), default 1%
		1e13,	//mw		4       config, default 1 (near zero)
		0,		//ct[0]		5       nonce, then constant (first work)
		0		//ct[1]		6       time, up only (last work)
		//0		//ct[2]		7       time, up only (2nd-last work)
	];
	event  Approval(address indexed src, address indexed guy, uint wad);
	event  Transfer(address indexed src, address indexed dst, uint wad);
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
		salvage();
		if(shouldWork()) {work(address(this));}

		//Some fancy math to take care of Fee-on-Transfer tokens
		uint256 vbb = want.balanceOf(address(this));
		uint256 mcbb = mc.userInfo(allnums[0],address(this)).amount;
		require(want.transferFrom(msg.sender,address(this),_amt), "Unable to onboard");
		uint256 vba = want.balanceOf(address(this));
		uint256 D = vba.sub(vbb,"Dirty deposit");
		mc.deposit(allnums[0],D,address(this));
		//Some more fancy math to take care of Deposit Fee
		uint256 mcba = mc.userInfo(allnums[0],address(this)).amount;
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
		emit Transfer(address(0), msg.sender, _mint.sub(_fee));
	}

	function withdraw(uint256 _amt) public rg
	{
		require(!emergency,"Its an emergency. Use emergencyWithdraw() please.");
		require(balanceOf[msg.sender] >= _amt,"Insufficient Balance");
		//Burn _amt of Vault Tokens
		balanceOf[msg.sender] -= _amt;
		uint256 ts = totalSupply;
		totalSupply -= _amt;
		emit Transfer(msg.sender, address(0), _amt);
		uint256 vbb = want.balanceOf(address(this));
		uint256 mcbb = mc.userInfo(allnums[0],address(this)).amount;
		// W  = DepositsPerShare * SharesBurnt
		uint256 W = ( _amt.mul(mcbb) ).div(ts);
		mc.withdrawAndHarvest(allnums[0],W,address(this));
		uint256 vba = want.balanceOf(address(this));
		uint256 D = vba.sub(vbb,"Dirty withdrawal");
	   	require(want.transfer(msg.sender,D), "Unable to deboard");
	   	//hardWork()
		if(shouldWork()) {work(address(this));}
	}

	function doHardWork() public rg
	{
		require(eliteness(msg.sender),"Elites only!");
		salvage();
		//require(earn.balanceOf(address(this)) > allnums[4], "Not much work to do!");
		work(msg.sender);
	}

	function salvage() public
	{
		//harvest()
		//mc.withdrawAndHarvest(allnums[0],0,address(this));
        IRewarder RR = IRewarder(mc.rewarder(allnums[0]));
		if(
            (RR.pendingToken(allnums[0],address(this)) > allnums[4] )
            || (mc.pendingBeets(allnums[0],address(this)) > allnums[4] )
        ){mc.harvest(allnums[0],address(this));}
	}

	function shouldWork() public view returns (bool could)
	{
		could = (
			(IERC20(alladdr[3]).balanceOf(address(this)) > allnums[4])
			|| (IERC20(alladdr[4]).balanceOf(address(this)) > allnums[4])
		);
	}

	function work(address ben) internal
	{
		require(!emergency,"Its an emergency. Use emergencyWithdraw() please.");
		//has inputs from salvage() if this work is done via doHardWork()

		require(shouldWork(), "Not much work to do!");
		//breaks only doHardWork(), as deposit() & withdraw() cannot reach work() unless we shouldWork()

        uint256 beetsEarned = IERC20(alladdr[3]).balanceOf(address(this));
		uint256 ringEarned = IERC20(alladdr[4]).balanceOf(address(this));


        if(beetsEarned > allnums[4])
        {
			//Sell 100% BEETS for USDC at Beethoven-x
			FundManagement memory FM = FundManagement({
				sender:             address(this),
				fromInternalBalance:false,
				recipient:          payable(address(this)),
				toInternalBalance:  false
			});
			SingleSwap memory B2U = SingleSwap({
				poolid: 	BPT_OPUS,
				kind:	    SwapKind.GIVEN_IN,
				assetIn:    alladdr[3],
				assetOut:   alladdr[5],
				amount:     beetsEarned,
				userData:   abi.encode(0)
			});
			IBX(alladdr[1]).swap(B2U, FM, 1, block.timestamp);

			//Buy RING with 80% of USDC at SpookySwap
			//Using Code Snippet from Kucino Casino (kcc.guru)
        	// generate the eliteDEX pair path of token -> weth
        	address[] memory path = new address[](2);
        	path[0] = alladdr[5];
        	path[1] = alladdr[4];
			IRouter(alladdr[2])
			.swapExactTokensForTokensSupportingFeeOnTransferTokens(
				((IERC20(alladdr[5]).balanceOf(address(this))).mul(4)).div(5),
				1,
                path,
                address(this),
                block.timestamp
			)
		;}


		if(ringEarned > allnums[4])	//Sell 20% RING to USDC at SpookySwap
		{

			//Using Code Snippet from Kucino Casino (kcc.guru)
        	// generate the eliteDEX pair path of token -> weth
        	address[] memory path = new address[](2);
        	path[0] = alladdr[4];
        	path[1] = alladdr[5];
            IRouter(alladdr[2])
			.swapExactTokensForTokensSupportingFeeOnTransferTokens(
				ringEarned.div(5),
                1,
                path,
                address(this),
                block.timestamp
			)
		;}


		//JoinPool: BPT-RING
		//Using Code Snippet from Kucino Casino (kcc.guru)
        // generate the eliteDEX pair path of token -> * -> target
        IAsset[] memory T = new IAsset[](2);
        T[0] = IAsset(alladdr[5]);
        T[1] = IAsset(alladdr[4]);
		uint256[] memory A = new uint256[](2);
        A[0] = IERC20(alladdr[5]).balanceOf(address(this));
        A[1] = IERC20(alladdr[4]).balanceOf(address(this));

		bytes memory U = abi.encode(1, A, 1);
		//EXACT_TOKENS_IN_FOR_BPT_OUT (=enum JoinKind @1) "+" amountsIn (=A) "+" minimumBPT (1 = 10^-18 BPT)

		JoinPoolRequest memory R = JoinPoolRequest({	//T,A,U, fib ==> R
			assets:	 			T,
			maxAmountsIn:		A,	//amounts=amounts since we want to give it ALL, no slippage
			userData:			U,
			fromInternalBalance:false
		});

		IBX(alladdr[1]).joinPool(BPT_RING, address(this), address(this), R);


		//executes the generic sub-routine of a Kompound Protocol worker, common across all Granaries
		uint256 D = want.balanceOf(address(this));
		uint256 mcbb = mc.userInfo(allnums[0],address(this)).amount;
		mc.deposit(allnums[0],D,address(this));
		uint256 mcba = mc.userInfo(allnums[0],address(this)).amount;
		uint256 M = mcba.sub(mcbb,"Dirty stake");
		//Performance Fee Mint, conserves TVL
		uint256 _mint = 0;
		//allnums[5] & allnums[6] are First & Latest Compound's timestamps. Used in info() for APY of AUM.
		if(allnums[5]==0){allnums[5]=uint64(block.timestamp);}//only on the first run
		allnums[6]=uint64(block.timestamp);
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
	}




	function declareEmergency() public DAO
	{
		require(!emergency,"Emergency already declared.");
		mc.emergencyWithdraw(allnums[0], address(this));
		emergency=true;
	}

	function revokeEmergency() public DAO
	{
		require(emergency,"Emergency not declared.");
		uint256 D = want.balanceOf(address(this));
		mc.deposit(allnums[0],D,address(this));
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
	function info() public view returns (uint256, uint256, uint256, IMasterchef.UserInfo memory, IMasterchef.PoolInfo memory, uint256, uint256, uint256)
	{
		uint256 aum = mc.userInfo(allnums[0],address(this)).amount + IERC20(want).balanceOf(address(this));
		uint256 roi = aum*1e18/totalSupply;//ROI: 1e18 === 1x
		uint256 apy = ((roi-1e18)*(365*86400)*100)/(allnums[6]-allnums[5]);//APY: 1e18 === 1%
		IRewarder RR = IRewarder(mc.rewarder(allnums[0]));
		return(
			aum,
			roi,
			apy,
			mc.userInfo(allnums[0],address(this)),
            mc.poolInfo(allnums[0]),
			mc.totalAllocPoint(),
			RR.pendingToken(allnums[0],address(this)),
			mc.pendingBeets(allnums[0],address(this))
		);
	}

	//TVL in USD, 1e18===$1.
	//Source code Derived from ftm.guru's Universal On-chain TVL Calculator: https://ftm.guru/rawdata/tvl
	function tvl() public view returns(uint256)
	{
		//doesnt use tvlGuru < v6, which was the latest version at the time of deployment of this GRAIN.
		//ITVL tc = ITVL(utvl);
		uint256 aum = mc.userInfo(allnums[0],address(this)).amount + IERC20(want).balanceOf(address(this));
		uint256[] memory w = IBPT(address(want)).getNormalizedWeights();
		(,uint256[] memory a,) = IBX(alladdr[1]).getPoolTokens(BPT_RING);
		uint256 ts_bpt =  want.totalSupply() ;
		uint256 tvl_bpt = ( (a[0] * 1e18 / w[0])) * (10**(18-IERC20(alladdr[5]).decimals()));	//$1 = 1e18
		uint256 p_bpt = tvl_bpt * 1e18 / ts_bpt;
		return (p_bpt * aum / 1e18);
	}

}