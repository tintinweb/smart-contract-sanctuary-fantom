/**
 *Submitted for verification at FtmScan.com on 2022-04-30
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
pragma solidity ^0.8.13;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ILiquidRNG {

	function random1(uint256 mod, uint256 demod) external view returns(uint256);

    function random2(uint256 mod, uint256 demod) external view returns(uint256);

    function random3(uint256 mod, uint256 demod) external view returns(uint256);
	
    function random4(uint256 mod, uint256 demod) external view returns(uint256);

    function random5(uint256 mod, uint256 demod) external view returns(uint256);

    function random6(uint256 mod, uint256 demod) external view returns(uint256);
	
    function random7(uint256 mod, uint256 demod) external view returns(uint256);

    function random8(uint256 mod, uint256 demod) external view returns(uint256);

    function requestMixup() external;
}

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}    

interface ILexBase is IERC165 {

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

contract LexiconHourly is Ownable {
	
    uint256 private checkpoint = 0;
	uint256 private target = 134;
    uint256 public lv1Reward = 50;
    uint256 public lv2Reward = 75;
    uint256 public lv3Reward = 100;
    uint256 public lv4Reward = 250;
    uint256 public lv5Reward = 500;
    bool public systemOn = true;
	address public lexCards = 0xa95D7adEcb3349b9e98e87C14726aFa53511a38D;
    address public randomToken = 0x87d57F92852D7357Cf32Ac4F6952204f2B0c1A27;
	address private randomizer = 0x56a736f63dA4B11252c53EA53643174651995562;
	ILexBase cards = ILexBase(lexCards);
	IERC20 rndm = IERC20(randomToken);
	ILiquidRNG rng = ILiquidRNG(randomizer);
	
    function claim() external {
    require(systemOn == true);
	require(msg.sender == tx.origin);
    require(rewardReady() == true);
    require(cards.balanceOf(msg.sender,target) > 0);
    rollReward();
    checkpoint = block.timestamp;
  }

    function rollReward() internal {
    rng.requestMixup();
    uint256 reward = rng.random5(10000,1);
    if(reward >= 5000){rndm.transfer(msg.sender,lv1Reward * 1e18);}
    if(reward < 5000 && reward >= 2500){rndm.transfer(msg.sender,lv2Reward * 1e18);}
    if(reward < 2500 && reward >= 1250){rndm.transfer(msg.sender,lv3Reward * 1e18);}
    if(reward < 1250 && reward >= 500){rndm.transfer(msg.sender,lv4Reward * 1e18);}
    if(reward < 500 && reward >= 1){rndm.transfer(msg.sender,lv5Reward * 1e18);}
    rng.requestMixup();
    setNewTarget(rng.random1(236,1));
  }

	function setNewTarget(uint256 value) internal {
	target = value;
  }

    function adminSetTarget(uint256 value) external onlyOwner {
    setNewTarget(value);
  }

    function setCardAddr(address newCards) external onlyOwner {
    lexCards = newCards;
  }
    
    function setTokenAddr(address newToken) external onlyOwner {
    randomToken = newToken;
  }

    function setRngAddr(address newRNG) external onlyOwner {
    randomizer = newRNG;
  }

    function setRewards(uint256 lv1, uint256 lv2, uint256 lv3
    ,uint256 lv4, uint256 lv5) external onlyOwner {
    lv1Reward = lv1;
    lv2Reward = lv2;
    lv3Reward = lv3;
    lv4Reward = lv4;
    lv5Reward = lv5;
  }

    function timeLeft() public view returns(uint256) {
    if(checkpoint + (60*60) - block.timestamp > 0){
    return checkpoint + (60*60) - block.timestamp;}
    else{return 0;}
  }

    function rndmBalance() public view returns(uint256) {
    return rndm.balanceOf(address(this));
  }

    function currentCard() external view returns(uint256) {
    return target;
  }

    function depoRNDM(uint256 value) external onlyOwner {
    rndm.transferFrom(msg.sender,address(this),value);
  }

    function adminWithdraw(uint256 value) external onlyOwner {
    rndm.transfer(msg.sender,value);
  }

    function upgradePrep() external onlyOwner {
    systemOn = false;
    rndm.transfer(msg.sender,rndmBalance());
  }

    function rewardReady() public view returns(bool) {
    if(timeLeft() != 0){return false;}
    else{return true;}
  }

    function systemPower(bool value) external onlyOwner {
    systemOn = value;
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