/**
 *Submitted for verification at FtmScan.com on 2022-06-29
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
pragma solidity ^0.8.15;

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}    

interface IMJOL1155 is IERC165 {

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
     function burn(address account, uint _id, uint _amount) external;
     function burnBatch(address account, uint[] memory _ids, uint[] memory _amounts) external;
     function burnForMint(address _from, uint[] memory _burnIds, uint[] memory _burnAmounts, uint[] memory _mintIds, uint[] memory _mintAmounts) external;
     function setURI(uint _id, string memory _uri) external;
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
	function burn(uint256 amount) external;
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract MjolnirRBAC {
    mapping(address => bool) internal _thors;

    modifier onlyThor() {
        require(
            _thors[msg.sender] == true || address(this) == msg.sender,
            "Caller cannot wield Mjolnir"
        );
        _;
    }

    function addThor(address _thor)
        external
        onlyOwner
    {
        _thors[_thor] = true;
    }

    function delThor(address _thor)
        external
        onlyOwner
    {
        delete _thors[_thor];
    }

    function disableThor(address _thor)
        external
        onlyOwner
    {
        _thors[_thor] = false;
    }

    function isThor(address _address)
        external
        view
        returns (bool allowed)
    {
        allowed = _thors[_address];
    }

    function toAsgard() external onlyThor {
        delete _thors[msg.sender];
    }
    //Oracle-Role
    mapping(address => bool) internal _oracles;

    modifier onlyOracle() {
        require(
            _oracles[msg.sender] == true || address(this) == msg.sender,
            "Caller is not the Oracle"
        );
        _;
    }

    function addOracle(address _oracle)
        external
        onlyOwner
    {
        _oracles[_oracle] = true;
    }

    function delOracle(address _oracle)
        external
        onlyOwner
    {
        delete _oracles[_oracle];
    }

    function disableOracle(address _oracle)
        external
        onlyOwner
    {
        _oracles[_oracle] = false;
    }

    function isOracle(address _address)
        external
        view
        returns (bool allowed)
    {
        allowed = _oracles[_address];
    }

    function relinquishOracle() external onlyOracle {
        delete _oracles[msg.sender];
    }
    //Ownable-Compatability
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
    //contextCompatability
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract LexBaseSetPurchase is MjolnirRBAC {

    address public base = 0xcE31D7B5F8486d0778A2C106C69D73648B8DcdEb;
    address public rndm = 0x87d57F92852D7357Cf32Ac4F6952204f2B0c1A27;
    address public saga = 0x2E292AF8E5B17C020Fa3c4511a58012b3Df84d46;
    address public devW = 0x564e9155Ff9268B4B7dA4F7b5fCa000Ea0f46Ebb;
    uint256 public packsLeft = 1998990;
    uint256 public ftmPrice = 20;
    uint256 public rndmPrice = 3541;
    uint256 public sagaPrice = 5;
    bool public powerOff = false;
    bool public rndmOff = false;
    bool public ftmOff = false;
    bool public sagaOff = false;
    IMJOL1155 bs = IMJOL1155(base);
    IERC20 rn = IERC20(rndm);
    IERC20 sg = IERC20(saga);

    function buyWithFTM(uint256 amount) external payable {
        require(powerOff == false);
        require(ftmOff == false);
        require(packsLeft - amount >= 0);
        if (msg.sender != owner()) {
        require(msg.value >= ftmPrice * (1e18) * amount);
    }
        bs.mint(msg.sender,1,amount);
        packsLeft = packsLeft - amount;
    }

    function buyWithRNDM(uint256 amount) external {
        require(powerOff == false);
        require(rndmOff == false);
        require(packsLeft - amount >= 0);
        rn.transferFrom(msg.sender, devW, amount * rndmPrice * (1e18));
        bs.mint(msg.sender,1,amount);
        packsLeft = packsLeft - amount;
    }

    function buyWithSAGA(uint256 amount) external {
        require(powerOff == false);
        require(sagaOff == false);
        require(packsLeft - amount >= 0);
        sg.transferFrom(msg.sender, devW, amount * sagaPrice * (1e18));
        bs.mint(msg.sender,1,amount);
        packsLeft = packsLeft - amount;
    }

    function buySmallBoxRNDM() external {
        require(powerOff == false);
        require(rndmOff == false);
        require(packsLeft - 50 >= 0);
        rn.transferFrom(msg.sender, devW, (50 * rndmPrice * (1e18))*95/100);
        bs.mint(msg.sender,1,50);
        packsLeft = packsLeft - 50;
    }    

    function buyLargeBoxRNDM() external {
        require(powerOff == false);
        require(rndmOff == false);
        require(packsLeft - 100 >= 0);
        rn.transferFrom(msg.sender, devW, (100 * rndmPrice * (1e18))*90/100);
        bs.mint(msg.sender,1,100);
        packsLeft = packsLeft - 100;
    }    

    function remoteMint(address account, uint256 amount) external onlyThor {
        require(packsLeft - amount >= 0);
        bs.mint(account, 1, amount);
        packsLeft = packsLeft - amount;
    }

    function setBase(address newBase) external onlyOwner {
        base = newBase;
    }

    function setRNDM(address newRNDM) external onlyOwner {
        rndm = newRNDM;
    }

    function setSAGA(address newSAGA) external onlyOwner {
        saga = newSAGA;
    }

    function setDEVW(address newDEVW) external onlyOwner {
        devW = newDEVW;
    }

    function setPackCounter(uint256 value) external onlyOwner {
        packsLeft = value;
    }

    function setFTMprice(uint256 value) external onlyOracle {
        ftmPrice = value;
    }

    function setRNDMprice(uint256 value) external onlyOracle {
        rndmPrice = value;
    }

    function setSAGAprice(uint256 value) external onlyOracle {
        sagaPrice = value;
    }

    function powerMain() external onlyOwner {
    if(powerOff == true){powerOff = false;}
    else{powerOff = true;}
    }  

    function powerFTM() external onlyOwner {
    if(ftmOff == true){ftmOff = false;}
    else{ftmOff = true;}
    }  

    function powerRNDM() external onlyOwner {
    if(rndmOff == true){rndmOff = false;}
    else{rndmOff = true;}
    }  

    function powerSAGA() external onlyOwner {
    if(sagaOff == true){sagaOff = false;}
    else{sagaOff = true;}
    }  

    function getBalance() public view returns(uint256) {
    return address(this).balance;
    }

    function withdrawAdmin() external onlyOwner {
    payable(owner()).transfer(getBalance());
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