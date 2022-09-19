/**
 *Submitted for verification at FtmScan.com on 2022-09-19
*/

// ▄█          ▄████████ ▀████    ▐████▀  ▄█   ▄████████  ▄██████▄  ███▄▄▄▄   
//███         ███    ███   ███▌   ████▀  ███  ███    ███ ███    ███ ███▀▀▀██▄ 
//███         ███    █▀     ███  ▐███    ███▌ ███    █▀  ███    ███ ███   ███ 
//███        ▄███▄▄▄        ▀███▄███▀    ███▌ ███        ███    ███ ███   ███ 
//███       ▀▀███▀▀▀        ████▀██▄     ███▌ ███        ███    ███ ███   ███ 
//███         ███    █▄    ▐███  ▀███    ███  ███    █▄  ███    ███ ███   ███ 
//███▌    ▄   ███    ███  ▄███     ███▄  ███  ███    ███ ███    ███ ███   ███ 
//█████▄▄██   ██████████ ████       ███▄ █▀   ████████▀   ▀██████▀   ▀█   █▀  
//▀
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IAffliate {
//Standard Affiliate
    function packOpenNew(address user,uint256 amt) external;
}

interface IFractalRandom {

	function randomFeed() external view returns (uint256);
	function randomLex1() external view returns (uint256);
	function randomLex2() external view returns (uint256);
	function randomLex3() external view returns (uint256);
	function randomLex4() external view returns (uint256);
	function randomLex5() external view returns (uint256);
    function randomLex6() external view returns (uint256);
 	function requestMixup() external;
}

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}    

interface IERC1155 is IERC165 {

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

     function mint(address _to, uint _id, uint _amount) external;
     function mintBatch(address _to, uint[] memory _ids, uint[] memory _amounts) external;
     function burn(uint _id, uint _amount) external;
     function burnBatch(uint[] memory _ids, uint[] memory _amounts) external;
     function burnForMint(address _from, uint[] memory _burnIds, uint[] memory _burnAmounts, uint[] memory _mintIds, uint[] memory _mintAmounts) external;
     function setURI(uint _id, string memory _uri) external;
}

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract lexLogicV3 is Ownable {

    event cardsOpened(uint256 c1, uint256 c2, uint256 c3, uint256 c4, uint256 c5);

    address public base = 0xa95D7adEcb3349b9e98e87C14726aFa53511a38D;
    address public setter = 0x564e9155Ff9268B4B7dA4F7b5fCa000Ea0f46Ebb;
    address public packs = 0xcE31D7B5F8486d0778A2C106C69D73648B8DcdEb;
    address public legacyPacks = 0x98C12b56258552F143d35be8983077eb6adBe9a4;
    address public void = 0x1fED77B0F7EF2addB8900DBe284B8ebA0cD5a1d9;
	address private randomizer = 0x69d646EeeE211Ee95A27436d9aaE4b08Bb9EA098;
    address public affiliate = 0x3cF885925CD9747977e9CcD7dbad9dc7f9c1c637;
    uint256 public modGlob = 62;
    uint256 public mintGate = 1;
    uint256 private CChance = 1;
    IERC1155 bs = IERC1155(base);
    IERC1155 pk = IERC1155(packs);
    IERC721 lpk = IERC721(legacyPacks);
    IFractalRandom rng = IFractalRandom(randomizer);
    IAffliate aff = IAffliate(affiliate);

  function batchOpen(uint256 amount) external {
        require(mintGate == 1);
        pk.safeTransferFrom(msg.sender, void, 1,amount,"");
        for (uint256 i = 0; i < amount; i++) {
        openPack();
        }
        aff.packOpenNew(msg.sender,amount);
  }

  function openPack() internal {
    CChance++;
    if (CChance == modGlob) {
        CChance = 0;
    }
      if (rngRemodGlob() == CChance) {
        openEX();
    } else {
        open();
    }
  }

  function legacyOpenPack(uint256 packID) external {
    require(mintGate == 1);
    lpk.safeTransferFrom(msg.sender, void, packID);
    CChance++;
    if (CChance == modGlob) {
        CChance = 0;
    }
      if (rngRemodGlob() == CChance) {
        openEX();
    } else {
        open();
    }
  }

  function open() internal {
        rng.requestMixup();
        uint256 r1 = rng.randomLex6();
        uint256 r2 = rng.randomLex2();
        uint256 r3 = rng.randomLex3();
        uint256 r4 = rng.randomLex4();
        uint256 r5 = rng.randomLex5();
        uint256[] memory rs = new uint[](5);
        uint256[] memory qs = new uint[](5);
        rs[0] = r1;
        rs[1] = r2;
        rs[2] = r3;
        rs[3] = r4;
        rs[4] = r5;
        qs[0] = 1;
        qs[1] = 1;
        qs[2] = 1;
        qs[3] = 1;
        qs[4] = 1;
        bs.mintBatch(
            tx.origin,
            rs,
            qs
        );    
    emit cardsOpened(r1,r2,r3,r4,r5);   
    }

  function openEX() internal {
        rng.requestMixup();
        uint256 r1 = rng.randomLex1();
        uint256 r2 = rng.randomLex2();
        uint256 r3 = rng.randomLex3();
        uint256 r4 = rng.randomLex4();
        uint256 r5 = rng.randomLex5();
        uint256[] memory rs = new uint[](5);
        uint256[] memory qs = new uint[](5);
        rs[0] = r1;
        rs[1] = r2;
        rs[2] = r3;
        rs[3] = r4;
        rs[4] = r5;
        qs[0] = 1;
        qs[1] = 1;
        qs[2] = 1;
        qs[3] = 1;
        qs[4] = 1;
        bs.mintBatch(
            tx.origin,
            rs,
            qs
        );    
    emit cardsOpened(r1,r2,r3,r4,r5);      
    }

    function rngRemodGlob() public view returns(uint256){
    return uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty, rng.randomFeed()
    ,msg.sender))) % modGlob;
    }
    function setRNG(address value) external onlyOwner {
    randomizer = value;
    }
    function setAffiliateConAddr(address value) external onlyOwner {
    affiliate = value;
    }
    function setBase(address value) external onlyOwner{
    base = value;
    }
    function setModGlob(uint256 value) external onlyOwner {
    modGlob = value;
    }
    function setCChance(uint256 value) external onlyOwner {
    CChance = value;
    }
    function setMintGate(uint256 value) external onlyOwner {
    mintGate = value;
    }
    function setPack(address value) external onlyOwner {
    packs = value;
    }
    function setLegacyPack(address value) external onlyOwner {
    legacyPacks = value;
    }
    function setVoid(address value) external onlyOwner {
    void = value;
    }
}
//                                             &
//                                            &&                                  
//                                          &#B&                                
//                                       &BP5G&                                 
//                                     &G555G                                   
//                                   &G5Y55P&                                   
//                           &G     B5Y5555B                                    
//                          &YY    GYYY5555#                                    
//                          P?JG  BJYYY5555&                                    
//                          YJJJP#YJYYY5555#                                    
//                          YJJJJJJYYYY5555B         &                          
//                          G?JJJJJYYYY5555P         #P#                        
//                   B&      5JJJJJYYYY55555#         GYG                       
//                  #PG       GJJJJYYYY55555P&        &55P&                     
//                  GPPP&      &PYJJYY5555555G         G55P                     
//                 &GPP55B       &G5YYY5555555#        B555B                    
//                 &GPP555PB        #PYY555555G        B555P                    
//                  GPP55555PB&       #P555555P&       B55PP&                   
//                  #PP555555Y5G&       #55555P#       P555G                    
//                   BP5555555YYYPB&     &P555PB      #5555B                    
//                    #P5555555YYYJYP#     P55P#      P555G                     
//                     &G555555YYYYJJJ5#   &55G      GY55P                      
//                       &G5555YYYYJJJJJP   GB      GYYYG                       
//                         &BPYYYYYJJJJJ?5   &     GJY5#                        
//                            #GYYYJJJJJJ?G      &PJ5B                          
//                              &GYJJJJJJJY&    &PG#                            
//                                &GYJJJJJJ#     &&                               
//                                  &GJJJJJ#     &                              
//                                    #YJJJ#                                    
//                                     #JJY                                     
//                                      G?G                                     
//                                      BY                                      
//                                      &&                                      
//                                                                               
//