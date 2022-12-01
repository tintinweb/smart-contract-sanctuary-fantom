# @version 0.3.7
"""
@license MIT
@author ren.meow
@notice
    If you happen to stumble into this contract, it is one my personal ERC-4626 auto compounding vaults.
    I made this cuz im too cheap to pay a performance fee to a third party, too lazy to compound manually... and just kinda bored 🤣
    My vaults are free for anyone to use.

    But! wanna ape in tho, BE AWARE THAT THERE IS HARD RUG CODE!!! AND THERE MAY BE MAJOR BUGS/VULNERABILITIES!!!
    I will not renounce ownership until im fully satisfied that the contract is bug free,
    and there is no situation where funds will get stuck.
    Tho im unlikely to actually rug it, DO NOT TRUST ANY RANDOM CONTRACT THAT YOU FIND!
    specially one created by an anonymous, horny asian male.
    Not responsible for any loss of funds

    This vault has 0 fees, 0 harvest bounty, i will be harvesting once a day.
    A harvest bounty can be introduced, but gib noods first.


"""


interface IScreamStaking:
    def deposit(_pid:uint256,_amount:uint256): nonpayable
    def withdraw(_pid:uint256,_amount:uint256): nonpayable
    def pendingRewards(_pid:uint256,_user:address) -> (DynArray[uint256, 5]): view

interface IRouter:
    def addLiquidity(
            tokenA:address,
            tokenB:address,
            amountADesired:uint256,
            amountBDesired:uint256,
            amountAMin:uint256,
            amountBMin:uint256,
            to:address,
            deadline:uint256
            ) -> (uint256,uint256,uint256): nonpayable
    
interface IPair:
    def swap(amount0Out: uint256, amount1Out: uint256, to: address, data: Bytes[32]): nonpayable
    def getReserves() -> (uint112, uint112, uint32): view
         

from vyper.interfaces import ERC20
from vyper.interfaces import ERC4626 as ERC4626
implements: ERC20
implements: ERC4626


event Approval:
    owner: indexed(address)
    spender: indexed(address)
    allowance: uint256
event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    amount: uint256

totalSupply: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
name: public(String[20])
symbol: public(String[10])
decimals:public(constant(uint8)) = 18


event Deposit:
    depositor: indexed(address)
    receiver: indexed(address)
    assets: uint256
    shares: uint256

event Withdraw:
    withdrawer: indexed(address)
    receiver: indexed(address)
    owner: indexed(address)
    assets: uint256
    shares: uint256

# misc params
staking:constant(address) = 0x5bC37CAAA3b490b65F5A50E2553f4312126A8b7e
pid:constant(uint256) = 4
# total assets deposited in farm
totalAssets:public(uint256)
rugoor: public(address)
asset:constant(address) = 0x30872e4fc4edbFD7a352bFC2463eb4fAe9C09086
scream:constant(address) = 0xe0654C8e6fd4D733349ac7E09f6f23DA256bF475
wftm:constant(address) = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83
OO_router:constant(address) = 0x6352a56caadC4F1E25CD6c75970Fa768A3304e64
router:constant(address) = 0x31F63A33141fFee63D4B26755430a390ACdD8a4d
bounty:public(bool)
fee:public(uint256)

event Reinvest:
    harvester: indexed(address)
    delta: uint256


@external
def __init__(_name:String[20],
            _symbol:String[10]):
    self.name=_name
    self.symbol=_symbol
    self.rugoor=msg.sender

    

@external
def set_approvals():
    
    ERC20(scream).approve(OO_router,max_value(uint256))
    ERC20(scream).approve(router,max_value(uint256))
    ERC20(wftm).approve(router,max_value(uint256))
    ERC20(asset).approve(staking,max_value(uint256))

    

@external
def approve(spender: address, amount: uint256) -> bool:
    self.allowance[msg.sender][spender] = amount
    log Approval(msg.sender, spender, amount)
    return True


@external
def transfer(receiver: address, amount: uint256) -> bool:
    self.balanceOf[msg.sender] -= amount
    self.balanceOf[receiver] += amount
    log Transfer(msg.sender, receiver, amount)
    return True


@external
def transferFrom(sender: address, receiver: address, amount: uint256) -> bool:
    self.allowance[sender][msg.sender] -= amount
    self.balanceOf[sender] -= amount
    self.balanceOf[receiver] += amount
    log Transfer(sender, receiver, amount)
    return True


@view
@internal
def _convertToShares(assets: uint256, to_round:bool=False) -> uint256: 
    totalSupply: uint256 = self.totalSupply
    totalAssets:uint256 = self.totalAssets
    if self.totalSupply == 0:
        return assets
    
    result:uint256 = assets * totalSupply / totalAssets

    if to_round and (assets*totalSupply) % totalAssets > 0:
        result += 1
    
    return result



@internal
def do_whatever_after_depositing_XD(assets:uint256):
    IScreamStaking(staking).deposit(pid,assets)
    self.totalAssets+=assets


@internal
def do_whatever_after_withdraw(assets:uint256):
    IScreamStaking(staking).withdraw(pid,assets)
    self.totalAssets-=assets

@external
def deposit(assets:uint256,receiver: address=msg.sender)->uint256:
    shares: uint256 = self._convertToShares(assets)
    assert shares != 0 # Can't deposit 0!
    ERC20(asset).transferFrom(msg.sender,self,assets)
    self.totalSupply+=shares
    self.balanceOf[receiver]+=shares
    self.do_whatever_after_depositing_XD(assets)
    log Deposit(msg.sender, receiver, assets, shares)
    log Transfer(empty(address),msg.sender,shares)
    return shares


@view
@external
def maxDeposit(owner: address) -> uint256:

    return ERC20(asset).balanceOf(owner)


@view
@external
def maxMint(owner: address) -> uint256:
    
    shares:uint256 = self._convertToShares(ERC20(asset).balanceOf(owner))
    return shares


@view
@external
def maxRedeem(owner: address) -> uint256:
    """
    @notice returns the max number of shares user can redeem
    """
    return self.balanceOf[owner] 


@view
@external
def maxWithdraw(owner: address) -> uint256:
    """
    @notice returns the max number of assets the user can withdraw, does not round up!
    """
    return self._convertToAssets(self.balanceOf[owner])


@view
@external
def previewDeposit(assets: uint256) -> uint256:
    return self._convertToShares(assets)


@view
@internal
def _convertToAssets(shares: uint256, to_round:bool = False) -> uint256:
    totalSupply: uint256 = self.totalSupply
    totalAssets:uint256 = self.totalAssets
    if totalSupply == 0:
        return 0
    
    result:uint256 = shares * totalAssets / totalSupply

    if to_round and (shares * totalAssets) % totalSupply > 0:
        result += 1

    return result


@external
def mint(shares: uint256, receiver: address=msg.sender) -> uint256:
    assert shares != 0 # Can't mint 0!
    assets: uint256 = self._convertToAssets(shares,True)
    if assets == 0 and ERC20(asset).balanceOf(self) == 0:
        assets = shares  

    ERC20(asset).transferFrom(msg.sender, self, assets)
    self.do_whatever_after_depositing_XD(assets)
    self.totalSupply += shares
    self.balanceOf[receiver] += shares
    log Deposit(msg.sender, receiver, assets, shares)
    log Transfer(empty(address),msg.sender,shares)
    return assets


@view
@external
def previewWithdraw(assets: uint256) -> uint256:
    """
    @dev returns shares + 1 if (assets * totalSupply) mod  totalAssets > 0.
    """
    shares: uint256 = self._convertToShares(assets,True)
    if shares == assets and self.totalSupply == 0:
        return 0

    return shares


@external
def redeem(shares: uint256, receiver: address=msg.sender, owner: address=msg.sender) -> uint256:
    assert shares !=0 # Can't redeem 0!
    if owner != msg.sender:
        self.allowance[owner][msg.sender] -= shares

    assets: uint256 = self._convertToAssets(shares)
    if shares == assets and self.totalSupply == 0:
        raise  # Nothing to redeem

    self.totalSupply -= shares
    self.balanceOf[owner] -= shares
    self.do_whatever_after_withdraw(assets)
    ERC20(asset).transfer(receiver, assets)
    log Withdraw(msg.sender, receiver, owner, assets, shares)
    log Transfer(msg.sender,empty(address),shares)
    return assets


@external
def withdraw(assets: uint256, receiver: address=msg.sender, owner: address=msg.sender) -> uint256:
    assert assets != 0 # Can't withdraw 0!
    shares: uint256 = self._convertToShares(assets,True)
    if shares == assets and self.totalSupply == 0:
        raise  # Nothing to redeem

    if owner != msg.sender:
        self.allowance[owner][msg.sender] -= shares

    self.totalSupply -= shares
    self.balanceOf[owner] -= shares
    self.do_whatever_after_withdraw(assets)
    ERC20(asset).transfer(receiver, assets)
    log Withdraw(msg.sender, receiver, owner, assets, shares)
    log Transfer(msg.sender,empty(address),shares)
    return shares


@view
@external
def convertToAssets(shareAmount: uint256) -> uint256:
    
    return self._convertToAssets(shareAmount)


@view
@external
def convertToShares(assetAmount: uint256) -> uint256:
    
    return self._convertToShares(assetAmount)


@view
@external
def previewMint(shares: uint256) -> uint256:
    """
    @dev returns assets + 1 if (assets * totalAssets) mod  totalSupply > 0.
    
    """
    assets:uint256=self._convertToAssets(shares,True)
    if assets == 0 and ERC20(asset).balanceOf(self) == 0:
        return shares

    return assets


@view
@external
def previewRedeem(shares: uint256) -> uint256:
    return self._convertToAssets(shares)


@external
def reinvest():
    """
    @notice
        did it this way in hopes of making it more gas efficient by not using the router...
        but now idk if the effort was worth the gas savings (if any at all lol), live and learn ig :(
        maybe if it was solidly the difference might not be negligible...
        i planned on also bypassing the router when adding liquidity, but im too lazy now...
        maybe if someone motivates me ill do it
        gib head to bypass router
    
    """

    IScreamStaking(staking).deposit(pid,0)
    bal:uint256 = ERC20(scream).balanceOf(self)
    
    if self.bounty:
        fee:uint256 = self.fee
        _bounty:uint256 = bal * fee / 10000
        bal -= bal * fee / 10000
        ERC20(scream).transfer(msg.sender,_bounty)
    
    pair :IPair = IPair(asset)
    reserveIn:uint112 = 0
    reserveOut:uint112 = 0
    blockTimestampLast:uint32 = 0
    # already sorted
    (reserveOut,reserveIn,blockTimestampLast) = pair.getReserves()
    bal = bal / 2
    amountIn:uint256 = bal * 998
    numerator:uint256 = amountIn * convert(reserveOut,uint256)
    denominator:uint256 = convert(reserveIn,uint256) * 1000 + amountIn
    amountOut:uint256 = numerator / denominator
    # flash swaps make me hard for some reason, im hard.
    ERC20(scream).transfer(asset,bal)
    pair.swap(amountOut,0,self,empty(Bytes[32]))
     
    liquidity:uint256 = IRouter(router).addLiquidity(scream,wftm,bal,amountOut,0,0,self,block.timestamp)[2]
    
    IScreamStaking(staking).deposit(pid,liquidity)
    self.totalAssets += liquidity
    log Reinvest(msg.sender, liquidity)



@external
def reinvest_with_OpenOcean(data:Bytes[10000]):
    """
    @notice
        experimental, lacks some safety checks. might be an attack vector... needs improvement idk, test current iteration in prod first kek
        how to use:
        call openocean api with params: inTokenAddress = scream, outTokenAddress = wftm, account = this contract, amount = total_pending() / 2
        pass data field of result as input param.
        good job! *clap* *clap* *clap*

        maybe could just unpack the data and iterate through the calls, ensure amountin is right, slip in referral code 😏, etc.
        basically only need the route
    @param data must be <= 10000 bytes long!
    """

    IScreamStaking(staking).deposit(pid,0)
    bal: uint256 = ERC20(scream).balanceOf(self)

    if self.bounty:
        fee:uint256 = self.fee
        _bounty:uint256 = bal * fee / 10000
        bal -= bal * fee / 10000
        ERC20(scream).transfer(msg.sender,_bounty)

    raw_call(OO_router, data)
    wftm_balance:uint256 = ERC20(wftm).balanceOf(self)
    liquidity:uint256 = IRouter(router).addLiquidity(wftm,scream,wftm_balance,bal/2,0,0,self,block.timestamp)[2]
    IScreamStaking(staking).deposit(pid,liquidity)
    self.totalAssets+=liquidity
    log Reinvest(msg.sender,liquidity)


@view
@external
def total_pending() -> uint256:
    """
    @notice returns pending rewards from scream and whatever tokens are in the contract, useful for bots.
    """
    pending:uint256 = IScreamStaking(staking).pendingRewards(pid,self)[3]
    bal:uint256 = ERC20(scream).balanceOf(self)
    return pending + bal


@external
def set_bounty(_fee:uint256):
    assert msg.sender == self.rugoor # Not rugoor, fucku

    self.bounty = True
    self.fee = _fee

    if _fee == 0:
        self.bounty = False

     
# rug code starts here...
@external
def sweepERC20(_token: address):
    """
    @notice In case rewards get stuck, excess balance, someone sends the contract tokens, or other unforseen events (or if i just wanna rug :p).
    """
    assert msg.sender == self.rugoor # Not rugoor, fucku
    assert msg.sender != empty(address)
    token: ERC20 = ERC20(_token)
    bal: uint256 = token.balanceOf(self)
    
    token.transfer(msg.sender,bal)


@external
def emergencyWithdraw(amount:uint256):
    """
    @notice unstakes lp token and sends to rugoor, in case withdraw/redeem shits itself or... i just wanna rug
    """

    assert msg.sender == self.rugoor # Not rugoor, fucku
    assert msg.sender != empty(address) 
    IScreamStaking(staking).withdraw(pid,amount)
    
    ERC20(asset).transfer(msg.sender,amount)


@external
def renounce_ownership():
    assert msg.sender == self.rugoor # Not rugoor, fucku

    self.rugoor = empty(address)


@external
def kill():
    assert msg.sender == self.rugoor # Not rugoor, fucku
    assert msg.sender != empty(address)
    selfdestruct(msg.sender)


# https://youtu.be/dQw4w9WgXcQ
# blart