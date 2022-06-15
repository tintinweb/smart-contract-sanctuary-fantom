# @version ^0.3.0

from vyper.interfaces import ERC165
from vyper.interfaces import ERC721

implements: ERC721
implements: ERC165

owner: address

tokenName: String[64]
tokenSymbol: String[32]
tokenCount: uint256
burntCount: uint256

interface ERC721Receiver:
    def onERC721Received(
            _operator: address,
            _from: address,
            _tokenId: uint256,
            _data: Bytes[1024]
        ) -> bytes32: view

interface ERC721Metadata:
	def name() -> String[64]: view
	def symbol() -> String[32]: view
	def tokenURI(_tokenId: uint256) -> String[128]: view

interface ERC721Enumerable:
	def totalSupply() -> uint256: view
	def tokenByIndex(_index: uint256) -> uint256: view
	def tokenOfOwnerByIndex(_address: address, _index: uint256) -> uint256: view

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    tokenId: indexed(uint256)

event Approval:
    owner: indexed(address)
    approved: indexed(address)
    tokenId: indexed(uint256)

event ApprovalForAll:
    owner: indexed(address)
    operator: indexed(address)
    approved: bool

idToOwner: HashMap[uint256, address]
idToURI: HashMap[uint256, String[100]]
idToApprovals: HashMap[uint256, address]

ownerToNFTokenCount: HashMap[address, uint256]
ownerToOperators: HashMap[address, HashMap[address, bool]]

baseURI: String[53]

SUPPORTED_INTERFACES: constant(bytes4[6]) = [
    0x01ffc9a7, # ERC165
    0x80ac58cd, # ERC721
    0x150b7a02, # ERC721 Token Reciever
    0x5b5e139f, # ERC721 Metadata
    0x780e9d63, # ERC721 Enumerable
    0x2a55205a  # ERC2981
]

@external
def __init__():
    self.owner = msg.sender
    self.tokenName = "Pizzacoin Collective"
    self.tokenSymbol = "PZCC"

@pure
@external
def supportsInterface(interfaceId: bytes4) -> bool:
    return interfaceId in SUPPORTED_INTERFACES

@view
@external
def name() -> String[64]:
	return self.tokenName

@view
@external
def symbol() -> String[32]:
	return self.tokenSymbol

@view
@internal
def _totalSupply() -> uint256:
	return self.tokenCount - self.burntCount

@view
@external
def totalSupply() -> uint256:
	return self._totalSupply()

@internal
def _setTokenURI(_tokenId: uint256, _tokenURI: String[100]):
    assert self.tokenCount >= _tokenId and _tokenId != 0
    assert self.idToOwner[_tokenId] == self.owner
    assert self.idToOwner[_tokenId] != ZERO_ADDRESS
    self.idToURI[_tokenId] = _tokenURI
    
@view
@external
def tokenURI(_tokenId: uint256) -> String[100]:
    return self.idToURI[_tokenId]

@view
@internal
def _balanceOf(_owner: address) -> uint256:
	assert _owner != ZERO_ADDRESS
	return self.ownerToNFTokenCount[_owner]

@view
@external
def balanceOf(_owner: address) -> uint256:
    assert _owner != ZERO_ADDRESS, "No Owner!"
    return self.ownerToNFTokenCount[_owner]

@view
@external
def ownerOf(_tokenId: uint256) -> address:
    owner: address = self.idToOwner[_tokenId]
    assert owner != ZERO_ADDRESS, "No Owner!"
    return owner

@view
@external
def getApproved(_tokenId: uint256) -> address:
    assert self.idToOwner[_tokenId] != ZERO_ADDRESS
    return self.idToApprovals[_tokenId]

@view
@external
def isApprovedForAll(_owner: address, _operator: address) -> bool:
    return (self.ownerToOperators[_owner])[_operator]

@view
@internal
def _isApprovedOrOwner(_spender: address, _tokenId: uint256) -> bool:
    owner: address = self.idToOwner[_tokenId]
    spenderIsOwner: bool = owner == _spender
    spenderIsApproved: bool = _spender == self.idToApprovals[_tokenId]
    spenderIsApprovedForAll: bool = (self.ownerToOperators[owner])[_spender]
    return (spenderIsOwner or spenderIsApproved) or spenderIsApprovedForAll

@internal
def _addTokenTo(_to: address, _tokenId: uint256):
    assert self.idToOwner[_tokenId] == ZERO_ADDRESS
    self.idToOwner[_tokenId] = _to
    self.ownerToNFTokenCount[_to] += 1

@internal
def _removeTokenFrom(_from: address, _tokenId: uint256):
    assert self.idToOwner[_tokenId] == _from
    self.idToOwner[_tokenId] = ZERO_ADDRESS
    self.ownerToNFTokenCount[_from] -= 1

@internal
def _clearApproval(_owner: address, _tokenId: uint256):
    assert self.idToOwner[_tokenId] == _owner
    if self.idToApprovals[_tokenId] != ZERO_ADDRESS:
        self.idToApprovals[_tokenId] = ZERO_ADDRESS

@internal
def _transferFrom(_from: address, _to: address, _tokenId: uint256, _sender: address):
    assert self._isApprovedOrOwner(_sender, _tokenId)
    assert _to != ZERO_ADDRESS
    self._clearApproval(_from, _tokenId)
    self._removeTokenFrom(_from, _tokenId)
    self._addTokenTo(_to, _tokenId)
    log Transfer(_from, _to, _tokenId)

@external
def transferFrom(_from: address, _to: address, _tokenId: uint256):
    self._transferFrom(_from, _to, _tokenId, msg.sender)

@external
def safeTransferFrom(
        _from: address,
        _to: address,
        _tokenId: uint256,
        _data: Bytes[1024]=b""
    ):
    self._transferFrom(_from, _to, _tokenId, msg.sender)
    if _to.is_contract:
        returnValue: bytes32 = ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data)
        assert returnValue == method_id("onERC721Received(address,address,uint256,bytes)", output_type=bytes32)

@external
def approve(_approved: address, _tokenId: uint256):
    owner: address = self.idToOwner[_tokenId]
    assert owner != ZERO_ADDRESS
    assert _approved != owner
    senderIsOwner: bool = self.idToOwner[_tokenId] == msg.sender
    senderIsApprovedForAll: bool = (self.ownerToOperators[owner])[msg.sender]
    assert (senderIsOwner or senderIsApprovedForAll)
    self.idToApprovals[_tokenId] = _approved
    log Approval(owner, _approved, _tokenId)

@external
def setApprovalForAll(_operator: address, _approved: bool):
    assert _operator != msg.sender
    self.ownerToOperators[msg.sender][_operator] = _approved
    log ApprovalForAll(msg.sender, _operator, _approved)

@external
def mint(_to: address) -> bool:
    assert msg.sender == self.owner, "Not the contract owner!"
    assert _to != ZERO_ADDRESS, "Cannot send to the zero address!"
    _newTokenId: uint256 = self.tokenCount + 1
    self.tokenCount +=1
    self._addTokenTo(_to, _newTokenId)
    log Transfer(ZERO_ADDRESS, _to, _newTokenId)
    return True

@external
def burn(_tokenId: uint256):
    assert self._isApprovedOrOwner(msg.sender, _tokenId)
    owner: address = self.idToOwner[_tokenId]
    assert owner != ZERO_ADDRESS
    self._clearApproval(owner, _tokenId)
    self._removeTokenFrom(owner, _tokenId)
    self.burntCount += 1
    log Transfer(owner, ZERO_ADDRESS, _tokenId)

@external
def withdraw():
    send(self.owner, self.balance)

@external
def transferContractOwner(_to: address):
    assert self.owner == msg.sender, "Do not have ownership!"
    self.owner = _to

@payable
@external
def __default__():
    pass