pragma solidity >=0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./ECDSA.sol";


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
        /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private  _CACHED_DOMAIN_SEPARATOR;
    uint256 private  _CACHED_CHAIN_ID;
    address private  _CACHED_THIS;
    bytes32 private  _HASHED_NAME;
    bytes32 private  _HASHED_VERSION;
    bytes32 private  _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version)  public {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = 250;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

 
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

        
        string private constant IDENTITY_TYPE = "identity(string MESSAGE,address WALLET)";
        string private constant AUTHENTICATION_TYPE = "authentication(uint256 VERIFY_ONCHAIN,address TOKEN_ADDRESS, uint256 CHAIN_ID, string VERSION, struct identity) identity(string MESSAGE,address WALLET)";

        bytes32 constant IDENTITY_TYPEHASH = keccak256("identity(string MESSAGE, address WALLET)");
        bytes32 constant AUTHENTICATION_TYPEHASH = keccak256("authentication(uint256 VERIFY_ONCHAIN, address TOKEN_ADDRESS, uint256 CHAIN_ID, string VERSION, struct identity) identity(string MESSAGE,address WALLET)");

        uint256 constant chainId = 250;
        address constant verifyingContract = 0x3e3e660E23DCf096b2f35f78638c63F15a950b6D;
      
         /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, 250, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }


    function hashIdentity(identity memory IDENTITY) private pure returns (bytes32) {
    return keccak256(abi.encode(
        IDENTITY_TYPEHASH,
        IDENTITY.MESSAGE,
        IDENTITY.WALLET
    ));
}


function balance_Of(address user) public view returns (uint256) {
        return IBalance(TEST_PASS_FTM).balanceOf(user);

    }

function ENTRANCE(authentication memory AUTHENTICATION,
    bytes memory signature) public view returns (string memory) {
    
    uint256 BAL_AMT = IBalance(TEST_PASS_FTM).balanceOf(msg.sender);

    bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            AUTHENTICATION_TYPEHASH,
            AUTHENTICATION.VERIFY_ONCHAIN,
            AUTHENTICATION.TOKEN_ADDRESS,
            AUTHENTICATION.CHAIN_ID,
            AUTHENTICATION.VERSION,
            hashIdentity(AUTHENTICATION.IDENTITY)
        )));
      address signer = ECDSA.recover(digest, signature);
     

    require(BAL_AMT >= 1, "Balance: Sender doesn't have a NFT");
    require(signer == msg.sender, "MyFunction: invalid signature");
    require(signer != address(0), "ECDSA: invalid signature");
     return "QmVd2Z5A58JWZjXXw2RfD8wv4rx3gXSH79KfjaUyjjSgmQ";

} 

   


}