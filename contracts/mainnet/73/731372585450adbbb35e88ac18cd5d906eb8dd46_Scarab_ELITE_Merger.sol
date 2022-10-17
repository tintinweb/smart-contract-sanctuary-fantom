/**
 *Submitted for verification at FtmScan.com on 2022-10-17
*/

// (C) Sam (543#3017), 2022-9999
// (C) Guru Network, 2022-9999
/*

Scarab.finance is now a part of the Guru Network (🦾,🚀)
Merge your SCARAB, gSCARAB & SINSPIRIT tokens into ELITE!

Migrating starts a stream of ELITE tokens, powered by LlamaPay.io

Ascend.sol - v2.0.0
Changelog:
- Ascend partial balances



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
                    **    SCARAB ⇢ ELITE   **
                    **                     **
                    ** Migrate your SCARAB **
                    ** GSCARAB & SINSPIRIT **
                    ** tokens to get ELITE **
                    **                     **
                    **    ftm.guru/ascend  **
                    **                     **
                    *************************

@notice Deposit Scarab tokens to start a new stream of ELITE.

*/
/*

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
        Kucino - The First and Most used Casino of KCC
        fmc.guru - FantomMarketCap : On-Chain Data Aggregator
        ELITE - ftm.guru is an indie growth-hacker for Fantom
        Lockless Protocol - Liquid Staking for Cosmos-SDK chains
        Kompound Protocol - The only immutable yield-compounder
*/
//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;




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

interface ILPF {
    function deploy_vesting_contract(
        address token,
        address recipient,
        uint256 amount,
        uint256 duration,
        uint256 start,
        uint256 cliff
    ) external returns(address);
}

interface ILPV {
    //  Stops further vesting & returns reward back to Funder
    function rug_pull() external;
}

interface iELITE is IERC20 {
    function taxPerM() external view returns(uint);
}


contract Scarab_ELITE_Merger {

    using SafeMath for uint256;

    //  Admins
    address public dao = 0x167D87A906dA361A10061fe42bbe89451c2EE584;
    address public dev = 0x5C146cd18fa53914580573C9b9604588529406Ca;
    modifier DAO {require(msg.sender==dao || msg.sender==dev,"E.L.I.T.E. D.A.O. Only!");_;}

    //  Tokens
    iELITE public tE = iELITE(0xf43Cc235E686d7BC513F53Fbffb61F760c3a1882);  //  $ELITE
    IERC20 public tS = IERC20(0x2e79205648B85485731CFE3025d66cF2d3B059c4);  //  $SCARAB
    IERC20 public tG = IERC20(0x6ab5660f0B1f174CFA84e9977c15645e4848F5D6);  //  $GSCARAB
    IERC20 public tI = IERC20(0x749F2B95f950c4f175E17aa80aa029CC69a30f09);  //  $SINSPIRIT

    //  Rates
    uint256 public rS = 13427645151783;    //  ELITE per SCARAB
    uint256 public rG = 237665782493368;    //  ELITE per GSCARAB
    uint256 public rI = 241674034777;    //  ELITE per SINSPIRIT

    //  Conversion Counts
    uint256 public allocated;   //  ELITE Allocated
    uint256 public cS;  //  SCARAB Converted
    uint256 public cG;  //  GSCARAB Converted
    uint256 public cI;  //  SINSPIRIT Converted
    mapping(address=>uint256) public uE;    //  ELITE Allocated to user
    mapping(address=>uint256) public uS;    //  SCARAB Converted by user
    mapping(address=>uint256) public uG;    //  GSCARAB Converted by user
    mapping(address=>uint256) public uI;    //  SINSPIRIT Converted by user


    //  Vesting
    uint256 public time = 6 weeks;
    ILPF public LPF = ILPF(0xB93427b83573C8F27a08A909045c3e809610411a); //  LlamaPay Factory

    event Ascended(
        address indexed who,
        address escrow,
        uint when,
        uint eliteness,
        uint scarabs,
        uint gscarabs,
        uint sinspirit
    );

    constructor() {
        tE.approve(address(LPF),uint(-1));
    }

    function ascend() public returns(address) {
        uint bS = tS.balanceOf(msg.sender);
        uint bG = tG.balanceOf(msg.sender);
        uint bI = tI.balanceOf(msg.sender);
        require(tS.transferFrom(msg.sender, dao, bS), "SCARAB Deposit Failed!");
        require(tG.transferFrom(msg.sender, dao, bG), "GSCARAB Deposit Failed!");
        require(tI.transferFrom(msg.sender, dao, bI), "SINSPIRIT Deposit Failed!");

        uint amount =
            (bS.mul(rS).div(1e18))
            .add(bG.mul(rG).div(1e18))
            .add(bI.mul(rI).div(1e18))
        ;

        uint txtax = tE.taxPerM();  //  ELITE: Tax per Million (default=13370)

        if(txtax > 0) { //  implies taxation will occur in future
            uint diff = (amount*txtax)/1e6;
            uint adj = ( ( diff * 1e6 ) / ( 1e6 - txtax ) ) + 1337;   //  +1337 extra to suppress rounding-errors
            tE.transfer(address(LPF), adj);
        }

        address escrow = LPF.deploy_vesting_contract(
            address(tE),
            msg.sender,
            amount,
            time,
            block.timestamp,
            0
        );

        if(txtax > 0) { //  implies taxation will occur in future
            uint bE = tE.balanceOf(escrow);
            uint diff = amount - bE;
            uint adj = ( ( diff * 1e6 ) / ( 1e6 - txtax ) ) + 1337;   //  +1337 extra to suppress rounding-errors
            tE.transfer(escrow, adj);
        }

        cS += bS;
        cG += bG;
        cI += bI;
        allocated += amount;

        uS[msg.sender] += bS;
        uG[msg.sender] += bG;
        uI[msg.sender] += bI;
        uE[msg.sender] += amount;

        emit Ascended(msg.sender,escrow,block.timestamp,amount,bS,bG,bI);
        return escrow;
    }
    
    
    function ascend(uint256 bS, uint256 bG, uint256 bI) public returns(address) {
       
        require(tS.transferFrom(msg.sender, dao, bS), "SCARAB Deposit Failed!");
        require(tG.transferFrom(msg.sender, dao, bG), "GSCARAB Deposit Failed!");
        require(tI.transferFrom(msg.sender, dao, bI), "SINSPIRIT Deposit Failed!");

        uint amount =
            (bS.mul(rS).div(1e18))
            .add(bG.mul(rG).div(1e18))
            .add(bI.mul(rI).div(1e18))
        ;

        uint txtax = tE.taxPerM();  //  ELITE: Tax per Million (default=13370)

        if(txtax > 0) { //  implies taxation will occur in future
            uint diff = (amount*txtax)/1e6;
            uint adj = ( ( diff * 1e6 ) / ( 1e6 - txtax ) ) + 1337;   //  +1337 extra to suppress rounding-errors
            tE.transfer(address(LPF), adj);
        }

        address escrow = LPF.deploy_vesting_contract(
            address(tE),
            msg.sender,
            amount,
            time,
            block.timestamp,
            0
        );

        if(txtax > 0) { //  implies taxation will occur in future
            uint bE = tE.balanceOf(escrow);
            uint diff = amount - bE;
            uint adj = ( ( diff * 1e6 ) / ( 1e6 - txtax ) ) + 1337;   //  +1337 extra to suppress rounding-errors
            tE.transfer(escrow, adj);
        }

        cS += bS;
        cG += bG;
        cI += bI;
        allocated += amount;

        uS[msg.sender] += bS;
        uG[msg.sender] += bG;
        uI[msg.sender] += bI;
        uE[msg.sender] += amount;

        emit Ascended(msg.sender,escrow,block.timestamp,amount,bS,bG,bI);
        return escrow;
    }


    //  Rate configurations
    function rate(uint _rs, uint _rg, uint _ri, uint _time) public DAO {
        rS = _rs;
        rG = _rg;
        rI = _ri;
        time = _time;
    }

    //  Stops further vesting in VestingEscrow[i] & returns unvested ELITE back to this contract
    function stop(address[] memory escrows) public DAO {
        for(uint256 i; i<escrows.length; i++) {
            ILPV(escrows[i]).rug_pull();
        }
    }

    //  Rescue tokens and dust that might accumulate inside this contract
    function rescue(address tokenAddress, uint tokens) public DAO returns(bool success) {
        if(tokenAddress==address(0)) {(success, ) = dao.call{value:tokens}("");return success;}
        else if(tokenAddress!=address(0)) {return IERC20(tokenAddress).transfer(dao, tokens);}
        else return false;
    }

}