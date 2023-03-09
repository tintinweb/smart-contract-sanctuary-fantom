/**
 *Submitted for verification at FtmScan.com on 2023-03-09
*/

pragma solidity ^0.8.17;

// SPDX-License-Identifier: AGPL-3.0

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract NFTWallet {

    address public nft;
    uint256 public index;

    event Executed(address indexed caller, address indexed target, uint256 value, bytes data);

    function owner() public view returns (address) {
        return IERC721(nft).ownerOf(index);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "NFTWallet: caller is not the owner");
        _;
    }

    function initialize(address _nft, uint256 _index) external {
        require(nft == address(0), "NFTWallet: initialized");
        nft = _nft;
        index = _index;
    }

    /**
     * @notice Performs a transaction.
     * @param _target The address for the transaction.
     * @param _value The ETH value of the transaction.
     * @param _data The data of the transaction.
     */
    function execute(address _target, uint256 _value, bytes calldata _data) external onlyOwner returns (bytes memory _result) {
        bool success;
        (success, _result) = _target.call{value: _value}(_data);
        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        emit Executed(msg.sender, _target, _value, _data);
    }

    receive() external payable {
    }

    function isValidSignature(bytes32 _hash, bytes calldata _signature) external view returns (bytes4) {
        // Validate signatures
        if (recoverSigner(_hash, _signature) == owner()) {
            return 0x1626ba7e;
        } else {
            return 0xffffffff;
        }
    }

    /**
     * @notice Recover the signer of hash, assuming it's an EOA account
     * @dev Only for EthSign signatures
     * @param _hash             Hash of message that was signed
     * @param _signature    Signature encoded as (bytes32 r, bytes32 s, uint8 v)
     */
    function recoverSigner(bytes32 _hash, bytes memory _signature) internal pure returns (address signer) {
        require(_signature.length == 65, "NFTWallet: invalid signature length");

        // Variables are not scoped in Solidity.
        uint8 v;
        bytes32 r;
        bytes32 s;

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0)
            revert("NFTWallet: invalid signature 's' value");

        if (v != 27 && v != 28)
            revert("NFTWallet: invalid signature 'v' value");

        // Recover ECDSA signer
        signer = ecrecover(_hash, v, r, s);

        // Prevent signer from being 0x0
        require(signer != address(0x0), "NFTWallet: INVALID_SIGNER");
    }

}

contract NFTWalletFactory {

    struct WalletInfo {
        address nft;
        uint256 index;
    }

    // wallet address => (NFT contract, tokenId)
    mapping(address => WalletInfo) public getDeployedWalletInfo;

    event WalletCreated(address indexed nft, uint256 index);

    function getInitCodeHash() public pure returns (bytes32) {
        return keccak256(type(NFTWallet).creationCode);
    }

    function createWallet(address nft, uint256 index) external returns (address payable wallet) {
        require(nft != address(0), 'NFTWalletFactory: zero address');
        bytes32 salt = keccak256(abi.encodePacked(nft, index));
        wallet = payable(address(new NFTWallet{salt : salt}()));
        NFTWallet(wallet).initialize(nft, index);
        WalletInfo storage walletInfo = getDeployedWalletInfo[wallet];
        walletInfo.nft = nft;
        walletInfo.index = index;
        emit WalletCreated(nft, index);
    }

    function getWalletAddressByNFT(address nft, uint256 index) public view returns (address wallet) {
        wallet = address(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                address(this),
                keccak256(abi.encodePacked(nft, index)), //salt
                getInitCodeHash()
            )))));
    }

    function disperseToken(IERC20 token, address nft, uint256[] calldata tokenIds, uint256[] calldata values) external {
        uint256 total = 0;
        for (uint256 i = 0; i < tokenIds.length; i++)
            total += values[i];
        require(token.transferFrom(msg.sender, address(this), total));
        for (uint256 i = 0; i < tokenIds.length; i++)
            require(token.transfer(getWalletAddressByNFT(nft, tokenIds[i]), values[i]));
    }

    function disperseTokenSimple(IERC20 token, address nft, uint256[] calldata tokenIds, uint256[] calldata values) external {
        for (uint256 i = 0; i < tokenIds.length; i++)
            require(token.transferFrom(msg.sender, getWalletAddressByNFT(nft, tokenIds[i]), values[i]));
    }

}