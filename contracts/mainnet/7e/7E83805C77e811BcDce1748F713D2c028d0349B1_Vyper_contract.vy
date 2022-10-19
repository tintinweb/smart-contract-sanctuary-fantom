# @version 0.3.6

from vyper.interfaces import ERC20

interface Factory:
    def approved_tokens(token: ERC20) -> bool: view
    def owner() -> address: view


event PaymentReceived:
    token: ERC20
    amount: uint256


FACTORY: immutable(Factory)


@external
def __init__(_factory: Factory):
    FACTORY = _factory


@external
def send_token(_token: ERC20, _amount: uint256):
    assert FACTORY.approved_tokens(_token), "Not an approved payment token"
    assert _amount > 0
    _token.transferFrom(msg.sender, self, _amount)
    receiver: address = FACTORY.owner()
    _token.transfer(receiver, _amount)

    log PaymentReceived(_token, _amount)


@external
def sweep_token_balance(_token: ERC20):
    assert FACTORY.approved_tokens(_token), "Not an approved payment token"
    receiver: address = FACTORY.owner()
    amount: uint256 = _token.balanceOf(self)
    if amount > 0:
        _token.transfer(receiver, amount)
        log PaymentReceived(_token, amount)


@external
def recover_token_balance(_token: ERC20):
    assert msg.sender == FACTORY.owner()
    amount: uint256 = _token.balanceOf(self)
    _token.transfer(msg.sender, amount)