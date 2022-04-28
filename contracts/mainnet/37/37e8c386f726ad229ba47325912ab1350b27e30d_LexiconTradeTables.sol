/**
 *Submitted for verification at FtmScan.com on 2022-04-27
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

interface ITableDB {

    function pushCard(uint256 tnum, uint256 crd) external;
    function pushCode(uint256 tnum, string memory cde) external;
    function pushTrader(uint256 tnum, address trdr) external;
    function pushWanted(uint256 tnum, uint256 value) external;
    function pushId(address trdr, uint256 value) external;
    function pushTime(address trdr, uint256 value) external;	
    function getCard(uint256 tnum) external view returns(uint256);
    function getCode(uint256 tnum) external view returns(string memory);
    function getTrader(uint256 tnum) external view returns(address);
    function getWanted(uint256 tnum) external view returns(uint256);
    function getId(address trdr) external view returns(uint256);
    function getTime(address trdr) external view returns(uint256);
}

library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

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


interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1155Receiver is IERC165 {

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
}

abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
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

contract LexiconTradeTables is MjolnirRBAC, ERC1155Holder {

    bool public systemOn = false;
    uint256 public price = 1000;
    uint256 public counter = 4;
    address public publicDB = 0x7734A2EdCBEed93476cc09e2705A9317F5316050;
    address public rndmToken = 0x87d57F92852D7357Cf32Ac4F6952204f2B0c1A27;
    address public cards = 0xa95D7adEcb3349b9e98e87C14726aFa53511a38D;
    ITableDB db = ITableDB(publicDB);
    IERC20 rndm = IERC20(rndmToken);
    IERC1155 card = IERC1155(cards);

    function openTable() external {
    require(systemOn == true);
    rndm.transferFrom(msg.sender,address(this),price * 1e18);
    if(msg.sender != db.getTrader(db.getId(msg.sender))) {
    db.pushId(msg.sender,counter);
    db.pushCard(db.getId(msg.sender),0);
    db.pushTrader(db.getId(msg.sender),msg.sender);
    counter++;
     }
    db.pushTime(msg.sender,block.timestamp);
    }

    function startTrade(uint256 cardT, uint256 cardW, string memory cde) external {
    require(systemOn == true);
    require(tradeTimeLeft(msg.sender) != 0);
    card.safeTransferFrom(msg.sender,address(this),cardT,1,"");
    db.pushCard(db.getId(msg.sender),cardT);
    db.pushWanted(db.getId(msg.sender),cardW);
    db.pushCode(db.getId(msg.sender),cde);
    }

    function cancelTrade() external {
    require(db.getCard(db.getId(msg.sender)) != 0);
    require(db.getTrader(db.getId(msg.sender)) != 0x0000000000000000000000000000000000000000);
    card.safeTransferFrom(address(this),msg.sender,db.getCard(db.getId(msg.sender)),1,"");
    db.pushCard(db.getId(msg.sender),0);
    db.pushWanted(db.getId(msg.sender),0);
    db.pushCode(db.getId(msg.sender),"");
    }

    function trade(uint256 id, string memory cde) external {
    require(systemOn == true);
    require(db.getCard(id) != 0);
    require(compare(cde,db.getCode(db.getId(db.getTrader(id)))) == true);
    card.safeTransferFrom(msg.sender,db.getTrader(id),db.getWanted(id),1,"");
    card.safeTransferFrom(address(this),msg.sender,db.getCard(id),1,"");
    db.pushCard(id,0);
    db.pushWanted(id,0);
    }

    function tradeTimeLeft(address user) public view returns(uint256) {
    return (db.getTime(user) + (60*60)) - block.timestamp;
    }

    function compare(string memory a, string memory b) internal pure returns(bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function rndmBalance() public view returns(uint256) {
    return rndm.balanceOf(address(this));
    }

    function getMyID(address user) external view returns(uint256){
    return db.getId(user);
    }

    function checkTable(uint256 id) external view returns(uint256 trading,uint256 tradefor) {
    trading = db.getCard(id);
    tradefor = db.getWanted(id);
    }

    function setPrice(uint256 value) external onlyOwner {
    price = value;
    }

    function setDBaddr(address newDB) external onlyOwner {
    publicDB = newDB;
    }

    function setRNDMaddr(address newRNDM) external onlyOwner {
    rndmToken = newRNDM;
    }

    function fixCounter(uint256 value) external onlyOwner {
    counter = value;
    }

    function setCardaddr(address newCard) external onlyOwner {
    cards = newCard;
    }

    function systemPower(bool status) external onlyOwner {
    systemOn = status;
    }

    function adminWithdraw(uint256 value) external onlyOwner {
    rndm.transfer(msg.sender,value);
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