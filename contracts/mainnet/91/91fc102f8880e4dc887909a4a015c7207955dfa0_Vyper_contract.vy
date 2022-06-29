from vyper.interfaces import ERC721

#VARIABLE DEFINITIONS
owner: address
owner_mapping: HashMap[uint256, address]

HIVE_REINVESTMENT_CONTRACT: constant(address) = 0xF5bF2F606090EA96196d1535927ADD33ea3eDbc1
CAPSULE_FEEDING_COMPOUNDING_CONTRACT: constant(address) = 0x9fF0436D1F44a965A7E9a5Ed2d5C2AEFE93f6AdF

BEARISHPOD_NFT_CONTRACT: constant(address) = 0xbAc40dc5168D2f109dFAD164af438d6b9C078254 #capsule NFT address
BEARISHHIVE_NFT_CONTRACT: constant(address) = 0xF0f8F779F2510eD7f6869dC811D6fBd84b1D1045 #hive NFT address

ZCOMB_LIQUIDATOR: constant(address) = 0x71c22fac22d18353A9AaE279Ce34dde84Cf653F2

#ToDO
#deploy contract and test moving hive and capsule back and forth. try non owner address
#deploy contract with 1494  then txf hives and capsule & set up gelato cron 

#EVENTS

#INTERFACES
##used for moving both capsules and hives back to deployer's wallet
#interface Erc721: #contract address: 0xbAc40dc5168D2f109dFAD164af438d6b9C078254 and 0xf0f8f779f2510ed7f6869dc811d6fbd84b1d1045
#    def transferFrom(_from: address, _to: address, _tokenId: uint256): nonpayable
#    def safeTransferFrom(_from: address, _to: address, _tokenId: uint256, _data: Bytes[1024]): nonpayable

#(Hives) interface with reinvesting hive rewards into capsules #zComb_wallet is contract wallet that hold's the capsule's zComb
interface Hive: #contract address 0xf5bf2f606090ea96196d1535927add33ea3edbc1
    def claimAndFundLockTo(_tokenIds:uint256[50], zComb_wallet:address) -> uint256: nonpayable 

#(Capsules) interface with feeding and compounding
interface Capsule: #contract address: 0x9ff0436d1f44a965a7e9a5ed2d5c2aefe93f6adf
    def feedAll(_tokenIds:uint256[5]): nonpayable
    def claimPod(_tokenId:uint256, zcomb_liquidator:address, zComb_wallet:address): nonpayable

#FUNCTIONS
@external
def __init__():
    #address that deploys is only one who can transfer nfts from contract
    self.owner = msg.sender

@external
def checkowner() -> address:
    return self.owner

@external 
def feedCapsules(_tokenIds:uint256[5]): 
    Capsule(CAPSULE_FEEDING_COMPOUNDING_CONTRACT).feedAll(_tokenIds)

@external
def compoundCapsule(_tokenId:uint256, zComb_wallet:address):
    Capsule(CAPSULE_FEEDING_COMPOUNDING_CONTRACT).claimPod(_tokenId, ZCOMB_LIQUIDATOR, zComb_wallet)

@external
def compoundHiveRewards(_tokenIds:uint256[50], zComb_wallet:address):
    Hive(HIVE_REINVESTMENT_CONTRACT).claimAndFundLockTo(_tokenIds, zComb_wallet)


#################################################################################

@external
def transferCapsule(_from: address, _to: address, _tokenId: uint256, ):
    #transfer capsule from contract to original deployer's wallet
    #throw if msg.sender is not the deployer of the contract
    assert (self.owner == msg.sender)
    ERC721(BEARISHPOD_NFT_CONTRACT).transferFrom(_from, _to, _tokenId)

@external
def transferHive(_from: address, _to: address, _tokenId: uint256, ):
    #transfer hive from contract to original deployer's wallet
    #throw if msg.sender is not the deployer of the contract
    assert (self.owner == msg.sender)
    ERC721(BEARISHHIVE_NFT_CONTRACT).transferFrom(_from, _to, _tokenId)