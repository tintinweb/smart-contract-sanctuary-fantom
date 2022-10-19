# @version 0.3.6


event NewDepositAddress:
    user_id: bytes32
    deposit_address: address

event NewOwnerCommitted:
    owner: address
    new_owner: address

event NewOwnerAccepted:
    old_owner: address
    owner: address


sweeper_implementation: public(address)

owner: public(address)
future_owner: public(address)

approved_tokens: public(HashMap[address, bool])
payment_addresses: public(HashMap[bytes32, address])


@external
def __init__(_owner: address):
    self.owner = _owner


@external
def create_payment_address(_user_id: bytes32):
    assert self.payment_addresses[_user_id] == empty(address)
    sweeper: address = create_forwarder_to(self.sweeper_implementation)
    self.payment_addresses[_user_id] = sweeper

    log NewDepositAddress(_user_id, sweeper)


@external
def set_sweeper_implementation(_sweeper: address):
    assert msg.sender == self.owner

    self.sweeper_implementation = _sweeper


@external
def set_token_approvals(_tokens: DynArray[address, 100], _approved: bool):
    assert msg.sender == self.owner

    for token in _tokens:
        self.approved_tokens[token] = _approved


@external
def commit_transfer_ownership(_new_owner: address):
    """
    @notice Set a new contract owner
    """
    assert msg.sender == self.owner
    self.future_owner = _new_owner
    log NewOwnerCommitted(msg.sender, _new_owner)


@external
def accept_transfer_ownership():
    """
    @notice Accept transfer of contract ownership
    """
    assert msg.sender == self.future_owner
    log NewOwnerAccepted(self.owner, msg.sender)
    self.owner = msg.sender