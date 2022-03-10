/**
 *Submitted for verification at FtmScan.com on 2022-03-10
*/

pragma solidity >=0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

interface IBalance { 
    function balanceOf(address owner) external view returns (uint256); 
    }

contract ONCHAIN_DID_ALPHA {
    
     string MESSAGE;
    address WALLET;
    address TEST_PASS_FTM = 0x3e3e660E23DCf096b2f35f78638c63F15a950b6D;
    uint256 VERIFY_ONCHAIN;
    address TOKEN_ADDRESS;
    uint256 CHAIN_ID;
    string VERSION;
    struct identity {
                        string MESSAGE;
                        address WALLET;
                        }
        

struct authentication {
                        uint256 VERIFY_ONCHAIN;
                        address TOKEN_ADDRESS;
                        uint256 CHAIN_ID;
                        string VERSION;
                        identity IDENTITY;
                    }

        
        string private constant IDENTITY_TYPE = "Identity(string MESSAGE,address WALLET)";

        string private constant AUTHENTICATION_TYPE = "authentication(uint256 VERIFY_ONCHAIN,address TOKEN_ADDRESS, uint256 CHAIN_ID, string VERSION, struct identity) Identity(string MESSAGE,address WALLET)";

        bytes32 constant IDENTITY_TYPEHASH = keccak256(
            "Identity(string MESSAGE,address WALLET)");

         bytes32 constant AUTHENTICATION_TYPEHASH = keccak256(
            "authentication(uint256 VERIFY_ONCHAIN,address TOKEN_ADDRESS, uint256 CHAIN_ID, string VERSION, struct identity) Identity(string MESSAGE,address WALLET)");
        uint256 constant chainId = 250;
        address constant verifyingContract = 0xEf6D4c03723a75bA8214D72aa5CDeC3399eb5DFC;
        string private constant EIP712_DOMAIN = "EIP712Domain(uint256 chainId,string name,address verifyingContract,string version)";
        bytes32 private constant DOMAIN_SEPARATOR = keccak256(abi.encode(
        keccak256("https://astroworld.io/Authentication/"),
        keccak256("GREASED_LIGHTNING"),
        chainId,
        verifyingContract
        ));



    function hashIdentity(identity memory IDENTITY) private pure returns (bytes32) {
    return keccak256(abi.encode(
        IDENTITY_TYPEHASH,
        IDENTITY.MESSAGE,
        IDENTITY.WALLET
    ));
}
function hashAuth(authentication memory AUTHENTICATION) private pure returns (bytes32){


    return keccak256(abi.encodePacked(
        "\\x19\\x01",
       DOMAIN_SEPARATOR,
       keccak256(abi.encode(
           AUTHENTICATION_TYPEHASH,
           AUTHENTICATION.VERIFY_ONCHAIN,
           AUTHENTICATION.TOKEN_ADDRESS,
           AUTHENTICATION.CHAIN_ID,
           AUTHENTICATION.VERSION,
           hashIdentity(AUTHENTICATION.IDENTITY)
        ))
    ));

}


function balance_Of() private view returns (uint256) {
        return IBalance(TEST_PASS_FTM).balanceOf(msg.sender);

    }

function ENTRANCE(authentication memory AUTHENTICATION, uint8 v,
    bytes32 r,
    bytes32 s) public view returns (string memory) {
    
   
    address signer = ecrecover(hashAuth(AUTHENTICATION), v, r, s);

    uint256 BAL_AMT = IBalance(TEST_PASS_FTM).balanceOf(msg.sender);

    require(BAL_AMT >= 1, "Balance: Sender doesn't have a NFT");
    require(signer == msg.sender, "MyFunction: invalid signature");
    require(signer != address(0), "ECDSA: invalid signature");
     return "QmVd2Z5A58JWZjXXw2RfD8wv4rx3gXSH79KfjaUyjjSgmQ";

} 

   


}