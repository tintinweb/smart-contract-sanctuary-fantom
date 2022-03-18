/**
 *Submitted for verification at FtmScan.com on 2022-03-17
*/

pragma solidity >=0.4.24 <0.8.0;
pragma experimental ABIEncoderV2;


interface IBalance { 
    function balanceOf(address owner) external view returns (uint256); 
    }

contract ONCHAIN_DID_ALPHA_1 {

    address TEST_PASS_FTM = 0x3e3e660E23DCf096b2f35f78638c63F15a950b6D;

    
    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }

    struct authentication {
                        uint256 VERIFY_ONCHAIN;
                        address TOKEN_ADDRESS;
                        uint256 CHAIN_ID;
                        string VERSION;
                        string MESSAGE;
                        address WALLET;

                    }

    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    bytes32 constant AUTHENTICATION_TYPEHASH = keccak256("authentication(uint256 VERIFY_ONCHAIN, address TOKEN_ADDRESS, uint256 CHAIN_ID, string VERSION, string MESSAGE, address WALLET)");

    
    


    function hashEIP(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }

    

    function hashAUTH(authentication memory AUTH) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            AUTHENTICATION_TYPEHASH,
            AUTH.VERIFY_ONCHAIN,
            AUTH.TOKEN_ADDRESS,
            AUTH.CHAIN_ID,
            keccak256(bytes(AUTH.VERSION)),
            keccak256(bytes(AUTH.MESSAGE)),
            AUTH.WALLET
        ));
    }



    function verify(authentication memory AUTHX, uint8 v, bytes32 r, bytes32 s, address user) public  view returns (string memory) {
        // Note: we need to use `encodePacked` here instead of `encode`.
        bytes32 DOMAIN_SEPARATOR = hashEIP(EIP712Domain({
            name: "https://astroworld.io/Authentication",
            version: "GREASED_LIGHTNING",
            chainId: 250,
            verifyingContract: 0x3e3e660E23DCf096b2f35f78638c63F15a950b6D
        }));
        
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            hashAUTH(AUTHX)
        ));

        uint256 BAL_AMT = IBalance(TEST_PASS_FTM).balanceOf(user);

         address signer = ecrecover(digest, v, r, s);
     

    require(BAL_AMT >= 1, "Balance: Sender doesn't have a NFT");
    require(signer == user, "MyFunction: invalid signature");
    require(signer != address(0), "ECDSA: invalid signature");
     return "QmVd2Z5A58JWZjXXw2RfD8wv4rx3gXSH79KfjaUyjjSgmQ";

    }
    
}