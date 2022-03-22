# @version 0.2.7
"""
@title Fee Distribution
@author Author
@license MIT
"""

from vyper.interfaces import ERC20


interface VotingEscrow:
    def user_point_epoch(addr: address) -> uint256: view
    def epoch() -> uint256: view
    def user_point_history(addr: address, loc: uint256) -> Point: view
    def point_history(loc: uint256) -> Point: view
    def checkpoint(): nonpayable

interface FeeDistributor:
    def checkpoint_token(): nonpayable
    def claim(_addr: address) -> uint256: nonpayable
    def claim_many(_receivers: address[20]) -> bool: nonpayable
    def toggle_allow_checkpoint_token(): nonpayable


event CommitAdmin:
    admin: address

event ApplyAdmin:
    admin: address

event ToggleAllowCheckpointToken:
    toggle_flag: bool

event CheckpointToken:
    time: uint256
    tokens: uint256

event Claimed:
    recipient: indexed(address)
    amount: uint256
    claim_epoch: uint256
    max_epoch: uint256


struct Point:
    bias: int128
    slope: int128  # - dweight / dt
    ts: uint256
    blk: uint256  # block


DAY: constant(uint256) = 86400
N_COINS: constant(uint256) = 10

start_time: public(uint256)
time_cursor: public(uint256)
time_cursor_of: public(HashMap[address, uint256])
user_epoch_of: public(HashMap[address, uint256])

blocked_addr: public(HashMap[address, bool])
fee_receive_addr: public(HashMap[address, address])

last_token_times: public(uint256[N_COINS])
tokens_per_day: public(HashMap[uint256, uint256[N_COINS]])

voting_escrow: public(address)
tokens: public(address[N_COINS])
total_received: public(uint256)
token_last_balances: public(uint256[N_COINS])

ve_supply: public(uint256[1000000000000000])  # VE total supply at day bounds

admin: public(address)
future_admin: public(address)
can_checkpoint_token: public(bool)
emergency_return: public(address)
is_killed: public(bool)


@external
def __init__(
    _voting_escrow: address,
    _start_time: uint256,
    _token: address[N_COINS],
    _admin: address,
    _emergency_return: address
):
    """
    @notice Contract constructor
    @param _voting_escrow VotingEscrow contract address
    @param _start_time Epoch time for fee distribution to start
    @param _token Fee token address
    @param _admin Admin address
    @param _emergency_return Address to transfer `_token` balance to
                             if this contract is killed
    """
    t: uint256 = _start_time / DAY * DAY
    self.start_time = t

    self.time_cursor = t
    
    for i in range(N_COINS):
        self.tokens[i] = _token[i]
        self.last_token_times[i] = t
    self.voting_escrow = _voting_escrow
    self.admin = _admin
    self.emergency_return = _emergency_return
    self.can_checkpoint_token = True


@internal
def _checkpoint_token(index: uint256):
    token_balance: uint256 = ERC20(self.tokens[index]).balanceOf(self)
    to_distribute: uint256 = token_balance - self.token_last_balances[index]
    self.token_last_balances[index] = token_balance

    t: uint256 = self.last_token_times[index]
    since_last: uint256 = block.timestamp - t
    self.last_token_times[index] = block.timestamp
    this_day: uint256 = t / DAY * DAY
    next_day: uint256 = 0

    for i in range(140):
        next_day = this_day + DAY
        if block.timestamp < next_day:
            if since_last == 0 and block.timestamp == t:
                self.tokens_per_day[this_day][index] += to_distribute
            else:
                self.tokens_per_day[this_day][index] += to_distribute * (block.timestamp - t) / since_last
            break
        else:
            if since_last == 0 and next_day == t:
                self.tokens_per_day[this_day][index] += to_distribute
            else:
                self.tokens_per_day[this_day][index] += to_distribute * (next_day - t) / since_last
        t = next_day
        this_day = next_day

    log CheckpointToken(block.timestamp, to_distribute)


@external
def checkpoint_token():
    """
    @notice Update the token checkpoint
    @dev Calculates the total number of tokens to be distributed in a given day.
         During setup for the initial distribution this function is only callable
         by the contract owner. Beyond initial distro, it can be enabled for anyone
         to call.
    """
    assert (msg.sender == self.admin) or\
           (self.can_checkpoint_token and (block.timestamp > self.last_token_times[0]))

    for i in range(N_COINS):
        self._checkpoint_token(i)


@internal
def _find_timestamp_epoch(ve: address, _timestamp: uint256) -> uint256:
    _min: uint256 = 0
    _max: uint256 = VotingEscrow(ve).epoch()
    for i in range(128):
        if _min >= _max:
            break
        _mid: uint256 = (_min + _max + 2) / 2
        pt: Point = VotingEscrow(ve).point_history(_mid)
        if pt.ts <= _timestamp:
            _min = _mid
        else:
            _max = _mid - 1
    return _min


@view
@internal
def _find_timestamp_user_epoch(ve: address, user: address, _timestamp: uint256, max_user_epoch: uint256) -> uint256:
    _min: uint256 = 0
    _max: uint256 = max_user_epoch
    for i in range(128):
        if _min >= _max:
            break
        _mid: uint256 = (_min + _max + 2) / 2
        pt: Point = VotingEscrow(ve).user_point_history(user, _mid)
        if pt.ts <= _timestamp:
            _min = _mid
        else:
            _max = _mid - 1
    return _min


@view
@external
def ve_for_at(_user: address, _timestamp: uint256) -> uint256:
    """
    @notice Get the xLQDR balance for `_user` at `_timestamp`
    @param _user Address to query balance for
    @param _timestamp Epoch time
    @return uint256 xLQDR balance
    """
    ve: address = self.voting_escrow
    max_user_epoch: uint256 = VotingEscrow(ve).user_point_epoch(_user)
    epoch: uint256 = self._find_timestamp_user_epoch(ve, _user, _timestamp, max_user_epoch)
    pt: Point = VotingEscrow(ve).user_point_history(_user, epoch)
    return convert(max(pt.bias - pt.slope * convert(_timestamp - pt.ts, int128), 0), uint256)


@internal
def _checkpoint_total_supply():
    ve: address = self.voting_escrow
    t: uint256 = self.time_cursor
    rounded_timestamp: uint256 = block.timestamp / DAY * DAY
    VotingEscrow(ve).checkpoint()

    for i in range(140):
        if t > rounded_timestamp:
            break
        else:
            epoch: uint256 = self._find_timestamp_epoch(ve, t)
            pt: Point = VotingEscrow(ve).point_history(epoch)
            dt: int128 = 0
            if t > pt.ts:
                # If the point is at 0 epoch, it can actually be earlier than the first deposit
                # Then make dt 0
                dt = convert(t - pt.ts, int128)
            self.ve_supply[t] = convert(max(pt.bias - pt.slope * dt, 0), uint256)
        t += DAY

    self.time_cursor = t


@external
def checkpoint_total_supply():
    """
    @notice Update the xLQDR total supply checkpoint
    @dev The checkpoint is also updated by the first claimant each
         new epoch day. This function may be called independently
         of a claim, to reduce claiming gas costs.
    """
    self._checkpoint_total_supply()


@external
def block_address(_blocked_addr: address, _fee_receive_addr: address):
    assert msg.sender == self.admin  # dev: access denied
    self.blocked_addr[_blocked_addr] = True
    self.fee_receive_addr[_blocked_addr] = _fee_receive_addr


@internal
def _claim(addr: address, ve: address, _last_token_time: uint256) -> uint256[N_COINS]:
    # Minimal user_epoch is 0 (if user had no point)
    user_epoch: uint256 = 0
    to_distribute: uint256[N_COINS] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    max_user_epoch: uint256 = VotingEscrow(ve).user_point_epoch(addr)
    _start_time: uint256 = self.start_time

    if max_user_epoch == 0:
        # No lock = no fees
        return to_distribute

    day_cursor: uint256 = self.time_cursor_of[addr]
    if day_cursor == 0:
        # Need to do the initial binary search
        user_epoch = self._find_timestamp_user_epoch(ve, addr, _start_time, max_user_epoch)
    else:
        user_epoch = self.user_epoch_of[addr]

    if user_epoch == 0:
        user_epoch = 1

    user_point: Point = VotingEscrow(ve).user_point_history(addr, user_epoch)

    if day_cursor == 0:
        day_cursor = (user_point.ts + DAY - 1) / DAY * DAY

    if day_cursor >= _last_token_time:
        return to_distribute

    if day_cursor < _start_time:
        day_cursor = _start_time
    old_user_point: Point = empty(Point)

    # Iterate over days
    for i in range(150):
        if day_cursor >= _last_token_time:
            break

        if day_cursor >= user_point.ts and user_epoch <= max_user_epoch:
            user_epoch += 1
            old_user_point = user_point
            if user_epoch > max_user_epoch:
                user_point = empty(Point)
            else:
                user_point = VotingEscrow(ve).user_point_history(addr, user_epoch)

        else:
            # Calc
            # + i * 2 is for rounding errors
            dt: int128 = convert(day_cursor - old_user_point.ts, int128)
            balance_of: uint256 = convert(max(old_user_point.bias - dt * old_user_point.slope, 0), uint256)
            if balance_of == 0 and user_epoch > max_user_epoch:
                break
            if balance_of > 0:
                for j in range(N_COINS):
                    to_distribute[j] += balance_of * self.tokens_per_day[day_cursor][j] / self.ve_supply[day_cursor]

            day_cursor += DAY

    user_epoch = min(max_user_epoch, user_epoch - 1)
    self.user_epoch_of[addr] = user_epoch
    self.time_cursor_of[addr] = day_cursor

    _fee_receiver: address = addr

    if self.blocked_addr[addr] == True:
        _fee_receiver = self.fee_receive_addr[addr]

    for i in range(N_COINS):
        if to_distribute[i] != 0:
            token: address = self.tokens[i]
            assert ERC20(token).transfer(_fee_receiver, to_distribute[i])
            self.token_last_balances[i] -= to_distribute[i]
        log Claimed(addr, to_distribute[i], user_epoch, max_user_epoch)

    return to_distribute


@external
@nonreentrant('lock')
def claim(_addr: address = msg.sender) -> (uint256[N_COINS]):
    """
    @notice Claim fees for `_addr`
    @dev Each call to claim look at a maximum of 50 user xLQDR points.
         For accounts with many xLQDR related actions, this function
         may need to be called more than once to claim all available
         fees. In the `Claimed` event that fires, if `claim_epoch` is
         less than `max_epoch`, the account may claim again.
    @param _addr Address to claim fees for
    @return uint256 Amount of fees claimed in the call
    """
    assert not self.is_killed

    if block.timestamp >= self.time_cursor:
        self._checkpoint_total_supply()

    last_token_time: uint256 = self.last_token_times[0]

    if self.can_checkpoint_token and (block.timestamp > last_token_time):
        for i in range(N_COINS):
            self._checkpoint_token(i)
        last_token_time = block.timestamp

    last_token_time = last_token_time / DAY * DAY

    return self._claim(_addr, self.voting_escrow, last_token_time)



@external
@nonreentrant('lock')
def claim_many(_receivers: address[20]) -> bool:
    """
    @notice Make multiple fee claims in a single call
    @dev Used to claim for many accounts at once, or to make
         multiple claims for the same address when that address
         has significant xLQDR history
    @param _receivers List of addresses to claim for. Claiming
                      terminates at the first `ZERO_ADDRESS`.
    @return bool success
    """
    assert not self.is_killed

    if block.timestamp >= self.time_cursor:
        self._checkpoint_total_supply()

    last_token_time: uint256 = self.last_token_times[0]

    if self.can_checkpoint_token and (block.timestamp > last_token_time):
        for i in range(N_COINS):
            self._checkpoint_token(i)
        last_token_time = block.timestamp

    last_token_time = last_token_time / DAY * DAY
    voting_escrow: address = self.voting_escrow

    for addr in _receivers:
        if addr == ZERO_ADDRESS:
            break

        self._claim(addr, voting_escrow, last_token_time)

    return True


@external
def burn(_coin: address) -> bool:
    """
    @notice Receive LQDR into the contract and trigger a token checkpoint
    @param _coin Address of the coin being received (must be LQDR)
    @return bool success
    """
    assert not self.is_killed

    amount: uint256 = ERC20(_coin).balanceOf(msg.sender)
    if amount != 0:
        ERC20(_coin).transferFrom(msg.sender, self, amount)
        if self.can_checkpoint_token and (block.timestamp > self.last_token_times[0]):
            for i in range(N_COINS):
                self._checkpoint_token(i)

    return True


@external
def commit_admin(_addr: address):
    """
    @notice Commit transfer of ownership
    @param _addr New admin address
    """
    assert msg.sender == self.admin  # dev: access denied
    self.future_admin = _addr
    log CommitAdmin(_addr)


@external
def apply_admin():
    """
    @notice Apply transfer of ownership
    """
    assert msg.sender == self.admin
    assert self.future_admin != ZERO_ADDRESS
    future_admin: address = self.future_admin
    self.admin = future_admin
    log ApplyAdmin(future_admin)


@external
def toggle_allow_checkpoint_token():
    """
    @notice Toggle permission for checkpointing by any account
    """
    assert msg.sender == self.admin
    flag: bool = not self.can_checkpoint_token
    self.can_checkpoint_token = flag
    log ToggleAllowCheckpointToken(flag)


@external
def kill_me():
    """
    @notice Kill the contract
    @dev Killing transfers the entire LQDR balance to the emergency return address
         and blocks the ability to claim or burn. The contract cannot be unkilled.
    """
    assert msg.sender == self.admin

    self.is_killed = True

    for i in range(N_COINS):
        token: address = self.tokens[i]
        assert ERC20(token).transfer(self.emergency_return, ERC20(token).balanceOf(self))


@external
def recover_balance(_coin: address) -> bool:
    """
    @notice Recover ERC20 tokens from this contract
    @dev Tokens are sent to the emergency return address.
    @param _coin Token address
    @return bool success
    """
    assert msg.sender == self.admin

    amount: uint256 = ERC20(_coin).balanceOf(self)
    response: Bytes[32] = raw_call(
        _coin,
        concat(
            method_id("transfer(address,uint256)"),
            convert(self.emergency_return, bytes32),
            convert(amount, bytes32),
        ),
        max_outsize=32,
    )
    if len(response) != 0:
        assert convert(response, bool)

    return True


@external
def set_emergency_return(_addr: address) -> bool:
    """
    @notice Set emergency return address
    @dev Set emergency return address.
    @param _addr New emergency address
    @return bool success
    """
    assert msg.sender == self.admin

    self.emergency_return = _addr

    return True

# for test purpose

@view
@external
def get_timestamp() -> uint256:
    """
    @notice Get current timestamp
    @return uint256 timestamp
    """
    return block.timestamp