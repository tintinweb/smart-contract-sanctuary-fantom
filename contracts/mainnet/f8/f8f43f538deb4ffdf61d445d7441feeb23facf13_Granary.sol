/**
 *Submitted for verification at FtmScan.com on 2022-03-20
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




					*************************
					**                     **
					**  GRANARY & WORKERS  **
					**                     **
					**    ftm.guru/GRAIN   **
					**                     **
					**                     **
					**  Compounding Vault  **
					**  for Solidex Farms  **
					**                     **
					** Lowest Fee: Just 1% **
					**                     **
					**Highest Worker Payout**
					**     Earn Full 1%    **
					**   on each Harvest!  **
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


*/
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

//ftm.guru's Universal On-chain TVL Calculator
//Source: https://ftm.guru/rawdata/tvl
interface ITVL {
	//Using Version = 6
	function p_lpt_coin_usd(address lp) external view returns(uint256);
	function p_lpt_usd(address u,address lp) external view returns(uint256);
}

interface ILpDepositor {
    struct Amounts {
        uint256 solid;
        uint256 sex;
    }
    function pendingRewards(address account, address[] calldata pools) external view returns (Amounts[] memory pending);
    function deposit(address pool, uint256 amount) external;
    function withdraw(address pool, uint256 amount) external;
    function getReward(address[] calldata pools) external;
	function userBalances(address owner, address pool) external view returns (uint256);
}

interface IERC20 {
	/**
	 * @dev Returns the number of token's Decimals.
	 */

	function decimals() external view returns (uint256);
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

    struct route {
        address from;
        address to;
        bool stable;
    }

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint amountIn,
		uint amountOutMin,
        route[] calldata routes,
		address to,
		uint deadline
	) external;

	function addLiquidity(
		address tokenA,
        address tokenB,
        bool stable,
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


contract Granary
{
	using SafeMath for uint256;

	constructor (address _w, string memory _i,
        address[] memory _rd0f, address[] memory _rd0t, bool[] memory _rd0s,
        uint[4] memory _si
    ) public
	{
		want=IERC20(_w);
		id=_i;//GRAIN#ID

        for(uint i=0;i<_si[0];i++)
        {
            RD0.push(IRouter.route(
                {
                    from:   _rd0f[i],
                    to:     _rd0t[i],
                    stable: _rd0s[i]
                }
            ));
        }

        for(uint i=_si[0];i<(_si[0]+_si[1]);i++)
        {
            RD1.push(IRouter.route(
                {
                    from:   _rd0f[i],
                    to:     _rd0t[i],
                    stable: _rd0s[i]
                }
            ));
        }

        for(uint i=(_si[0]+_si[1]);i<(_si[0]+_si[1]+_si[2]);i++)
        {
            RX0.push(IRouter.route(
                {
                    from:   _rd0f[i],
                    to:     _rd0t[i],
                    stable: _rd0s[i]
                }
            ));
        }

        for(uint i=(_si[0]+_si[1]+_si[2]);i<(_si[0]+_si[1]+_si[2]+_si[3]);i++)
        {
            RX1.push(IRouter.route(
                {
                    from:   _rd0f[i],
                    to:     _rd0t[i],
                    stable: _rd0s[i]
                }
            ));
        }




		//Approvals
		//Solidex.MC to take what it may want
		want.approve(address(mc),uint256(-1));
		//Routers.FoT to sell SOLID we earn
		IERC20(SOLID).approve(router,uint256(-1));
		//Routers.FoT to sell SEX we earn
		IERC20(SEX).approve(router,uint256(-1));
		//Routers.FoT to add RX0[RX0.length-1].to
		IERC20(RX0[RX0.length-1].to).approve(router,uint256(-1));
		//Routers.FoT to add RX1[RX1.length-1].to
		IERC20(RX1[RX1.length-1].to).approve(router,uint256(-1));
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

    IRouter.route[] public RD0;
    IRouter.route[] public RD1;
    IRouter.route[] public RX0;
    IRouter.route[] public RX1;

	function isContract(address account) internal view returns (bool)
	{
		bytes32 codehash;
		bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
		assembly { codehash := extcodehash(account) }
		return (codehash != accountHash && codehash != 0x0);
	}
	//Using getter functions instead of variables to circumvent "Stack too deep!" errors
	string public id;
	function name() public view returns(string memory){return(string(abi.encodePacked("ftm.guru/GRAIN/", id)));}
	function symbol() public view returns(string memory){return(string(abi.encodePacked("GRAIN#", id)));}
	function decimals() public pure returns(uint256){return(18);}
	uint256 public totalSupply;

	ILpDepositor public mc=ILpDepositor(0x26E1A0d851CF28E697870e1b7F053B605C8b060F);
	address public router=0xF02382e9c35D5043aA20855d1EeaA959E2FF6590;
	address public SOLID=0x888EF71766ca594DED1F0FA3AE64eD2941740A20;
	address public WFTM=0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
	address public SEX=0xD31Fcd1f7Ba190dBc75354046F6024A9b86014d7;

	//earn & want need to be kept independently readable for our Binary Options platform (ftm.guru/bo).
	function earn() public view returns(address,address){return(SOLID,SEX);}
	IERC20 public want;		//returns(address), setup in constructor

	bool public emergency = false;
	address public dao = 0x167D87A906dA361A10061fe42bbe89451c2EE584;
	address public treasury = dao;
	address public utvl = 0x0786c3a78f5133F08C1c70953B8B10376bC6dCad;
	//This GRAIN#51XX uses tvlGuru <= v5, which was the latest version at the time of deployment of this GRAIN.
	//address public utvl;
	/*
	uint256 public df = 1e3;//deposit fee = 0.1%, 1e6=100%
	uint256 public pf = 1e4;//performance fee to treasury, paid from profits = 1%, 1e6=100%
	uint256 public wi = 1e4;//worker incentive, paid from profits = 1%, 1e6=100%
	uint256 public mw;//Minimum earnings to reinvest
	uint64[3] ct;//Timestamp of first-ever & 2 latest Kompounds
	*/
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
		//This could've been done at the end but done here since there's no auto-harvest.
		//Doing here could also help with kinky APR that could otherwise be deposit bonus.
		salvage();
		if(shouldWork()) {work(address(this));}

		//Some fancy math to take care of Fee-on-Transfer tokens
		uint256 vbb = want.balanceOf(address(this));
		uint256 mcbb = mc.userBalances(address(this),address(want));
		require(want.transferFrom(msg.sender,address(this),_amt), "Unable to onboard");
		uint256 vba = want.balanceOf(address(this));
		uint256 D = vba.sub(vbb,"Dirty deposit");
		mc.deposit(address(want),D);
		//Some more fancy math to take care of Deposit Fee
		uint256 mcba = mc.userBalances(address(this),address(want));
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
		//This shouldve been done at the end but done here since there's no auto-harvest.
		//It also saves gas, and does not forfeit user's interim rewards (no exit penalty).
	   	salvage();
		if(shouldWork()) {work(address(this));}
		//Burn _amt of Vault Tokens
		balanceOf[msg.sender] -= _amt;
		uint256 ts = totalSupply;
		totalSupply -= _amt;
		emit Transfer(msg.sender, address(0), _amt);
		uint256 vbb = want.balanceOf(address(this));
		uint256 mcbb = mc.userBalances(address(this),address(want));
		// W  = DepositsPerShare * SharesBurnt
		uint256 W = ( _amt.mul(mcbb) ).div(ts);
		mc.withdraw(address(want),W);
		uint256 vba = want.balanceOf(address(this));
		uint256 D = vba.sub(vbb,"Dirty withdrawal");
	   	require(want.transfer(msg.sender,D), "Unable to deboard");
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
		//harvest
        address[] memory p = new address[](2);
        p[0] = address(want);
        mc.getReward(p);
	}

	function shouldWork() public view returns (bool could)
	{
		could = (
			(IERC20(SOLID).balanceOf(address(this)) > allnums[4])
			|| (IERC20(SEX).balanceOf(address(this)) > allnums[4])
		);
	}

	function work(address ben) internal
	{
		require(!emergency,"Its an emergency. Use emergencyWithdraw() please.");
		//has inputs from salvage() if this work is done via doHardWork()

		require(shouldWork(), "Not much work to do!");
		//breaks only doHardWork(), as deposit() & withdraw() cannot reach work() unless we shouldWork()

        uint256 solidEarned = IERC20(SOLID).balanceOf(address(this));
		uint256 sexEarned = IERC20(SEX).balanceOf(address(this));


        if(solidEarned > allnums[4])
        {
			//Sell 50% SOLID for R0[R0.length-1].to
			IRouter(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
				solidEarned.div(2),
				1,
        		RD0,
				address(this),
				block.timestamp
			);
			//Sell 50% SOLID for R1[R1.length-1].to
			IRouter(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
				solidEarned.div(2),
				1,
        		RD1,
				address(this),
				block.timestamp
			);

		}


		if(sexEarned > allnums[4])
		{

			//Sell 50% SEX for R0[R0.length-1].to
			IRouter(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
				sexEarned.div(2),
				1,
        		RX0,
				address(this),
				block.timestamp
			);
			//Sell 50% SEX for R1[R1.length-1].to
			IRouter(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
				sexEarned.div(2),
				1,
        		RX1,
				address(this),
				block.timestamp
			);

		}


		//AddLiquidity
		IRouter(router).addLiquidity(
			RX0[RX0.length-1].to,
        	RX1[RX1.length-1].to,
        	false,
        	IERC20(RX0[RX0.length-1].to).balanceOf(address(this)),
        	IERC20(RX1[RX1.length-1].to).balanceOf(address(this)),
        	1,
        	1,
        	address(this),
        	block.timestamp
		);


		//executes the generic sub-routine of a Kompound Protocol worker, common across all Granaries
		uint256 D = want.balanceOf(address(this));
		uint256 mcbb = mc.userBalances(address(this),address(want));
		mc.deposit(address(want),D);
		uint256 mcba = mc.userBalances(address(this),address(want));
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
		mc.withdraw(address(want),mc.userBalances(address(this),address(want)));
		emergency=true;
	}

	function revokeEmergency() public DAO
	{
		require(emergency,"Emergency not declared.");
		uint256 D = want.balanceOf(address(this));
		mc.deposit(address(want),D);
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
	function info() public view returns (uint256, uint256, uint256, uint256, uint256, uint256)
	{
		uint256 aum = mc.userBalances(address(this),address(want)) + IERC20(want).balanceOf(address(this));
		uint256 roi = aum*1e18/totalSupply;//ROI: 1e18 === 1x
		uint256 apy = ((roi-1e18)*(365*86400)*100)/(allnums[6]-allnums[5]);//APY: 1e18 === 1%
        address[] memory pool;
        pool[0] = address(want);
        ILpDepositor.Amounts[] memory amt;
        amt = mc.pendingRewards(address(this),pool);
		return(
			aum,
			roi,
			apy,
			mc.userBalances(address(this),address(want)),
			amt[0].solid,
			amt[0].sex
		);
	}

	//TVL in USD, 1e18===$1.
	//Source code Derived from ftm.guru's Universal On-chain TVL Calculator: https://ftm.guru/rawdata/tvl
	function tvl() public view returns(uint256)
	{
		ITVL tc = ITVL(utvl);
		uint256 aum = mc.userBalances(address(this),address(want)) + IERC20(want).balanceOf(address(this));
		return ((tc.p_lpt_usd(RD0[RD1.length-1].to,address(want))).mul(aum)).div(1e18);
		//return ((tc.p_lpt_coin_usd(address(want))).mul(aum)).div(1e18);
	}

}