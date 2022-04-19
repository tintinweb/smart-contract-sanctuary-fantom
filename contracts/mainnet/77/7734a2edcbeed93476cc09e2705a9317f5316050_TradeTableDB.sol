/**
 *Submitted for verification at FtmScan.com on 2022-04-19
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

contract TradeTableDB is MjolnirRBAC {

    struct TradeTable {
        uint256 card;
		uint256 wanted;
        string code;
        address trader;
    }
	
	struct TraderInfo {
		uint256 id;
		uint256 time;
	}
	
    mapping(uint256 => TradeTable) table;
	mapping(address => TraderInfo) info;
	
    function pushCard(uint256 tnum, uint256 crd) external onlyThor {
        table[tnum].card = crd;
    }

    function pushCode(uint256 tnum, string memory cde) external onlyThor {
        table[tnum].code = cde;
    }

    function pushTrader(uint256 tnum, address trdr) external onlyThor {
        table[tnum].trader = trdr;
    }

    function pushWanted(uint256 tnum, uint256 value) external onlyThor {
        table[tnum].wanted = value;
    }

    function pushId(address trdr, uint256 value) external onlyThor {
        info[trdr].id = value;
    }

    function pushTime(address trdr, uint256 value) external onlyThor {
        info[trdr].time = value;
    }
	
    function getCard(uint256 tnum) external view returns(uint256) {
        return table[tnum].card;
    }
	
    function getWanted(uint256 tnum) external view returns(uint256) {
        return table[tnum].wanted;
    }

    function getCode(uint256 tnum) external view returns(string memory)  {
        return table[tnum].code;
    }

    function getTrader(uint256 tnum) external view returns(address)  {
        return table[tnum].trader;
    }

    function getId(address trdr) external view returns(uint256)  {
        return info[trdr].id;
    }

    function getTime(address trdr) external view returns(uint256)  {
        return info[trdr].time;
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