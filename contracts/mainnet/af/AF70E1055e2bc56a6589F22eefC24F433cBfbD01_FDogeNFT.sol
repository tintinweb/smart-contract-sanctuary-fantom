// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./token-ERC721-ERC721.sol";
import "./access-Ownable.sol";
import "./token-ERC721-extensions-ERC721Burnable.sol";
import "./token-ERC721-extensions-ERC721Enumerable.sol";
import "./FDogeNFTData.sol";

contract FDogeNFT is ERC721, Ownable, ERC721Burnable, ERC721Enumerable, FDogeNFTData{
	uint256 public tradeLockTime = 5 * 60; 
	bool private isEnableTrade = true;
	uint256 currentTokenId = 0;
	
	// Mapping from token ID to banstatus
	mapping(uint256 => uint256) private _bans;
	mapping(address => uint256) private _ownerbans;
	mapping(address => bool) private _authorizedAddresses;

	modifier onlyAuthorizedAccount() {
		require(_authorizedAddresses[msg.sender] || owner() == msg.sender, "NFT: Permission");
		_;
	}
	
	constructor() ERC721("NDoge", "NDoge") {
		_authorizedAddresses[msg.sender] = true;
	}
	
	function _beforeTokenTransfer(address from, address to, uint256 tokenId)
		internal
		override(ERC721, ERC721Enumerable)
	{
		require(_bans[tokenId] < block.timestamp, "NFT: baned");
		require(_ownerbans[from] < block.timestamp, "NFT: baned");
		
		super._beforeTokenTransfer(from, to, tokenId);
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		override(ERC721, ERC721Enumerable)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}
	
	function mintNFT( address _to, uint256[] memory _values) external onlyAuthorizedAccount returns( uint256 ){
		require(_values.length == 3,'NFT: INVALID');
		currentTokenId ++;
		super._safeMint(_to, currentTokenId);
		_initNFT(currentTokenId, _values);
		return currentTokenId;
	}
	/**
	 * @dev config.
	 */
	function grantPermission(address account) public onlyOwner {
		require(account != address(0));
		_authorizedAddresses[account] = true;
	}

	function revokePermission(address account) public onlyOwner {
		require(account != address(0));
		_authorizedAddresses[account] = false;
	}
	
	function updateBaseURI(string memory newBaseURI) external onlyOwner{
        super.setbaseURI(newBaseURI);
    }
	
	/**
	 * Ban case.
	 */
	function banOwner(address _owner, uint256 _days) external onlyAuthorizedAccount{
		_ownerbans[_owner] = block.timestamp + _days * 86400;
	}

	function unbanOwner(address _owner) external onlyAuthorizedAccount{
		_ownerbans[_owner] = block.timestamp - 60;
	}
	
	function banNFT(uint256 _tokenId, uint256 _days) external onlyAuthorizedAccount{
		_bans[_tokenId] = block.timestamp + _days * 86400;
	}

	function unbanNFT(uint256 _tokenId) external onlyAuthorizedAccount{
		_bans[_tokenId] = block.timestamp - 60;
	}

	function getOnwerBannedStatus(address _owner) external view returns (bool, uint256) {
		if(_ownerbans[_owner] > block.timestamp){
			return (true, _ownerbans[_owner]);
		}else{
			return (false, 0);
		}
	}

	function getNFTBannedStatus(uint256 _tokenId) external view returns (bool, uint256) {
		if(_bans[_tokenId] > block.timestamp){
			return (true, _bans[_tokenId]);
		}else{
			return (false, 0);
		}
	}

	/**
	 * Info case.
	 */
	function initAllAttribute(uint256 _tokenId, uint256[] memory _values) external onlyAuthorizedAccount{
		require(_values.length == 3,'itemdata: INVALID_VALUES');
		_initNFT(_tokenId, _values);
	}

	function updateAllAttribute(uint256 _tokenId, uint256[] memory _values) external onlyAuthorizedAccount{
		require(_values.length == 3,'itemdata: INVALID_VALUES');
		_updateNFT(_tokenId, _values);
	}

	function tokenURI(uint256 _tokenId) public view override(ERC721) returns (string memory){
		return super.tokenURI(_tokenId);
	}
}