// SPDX-License-Identifier: MIT

//    //   / /                                 //   ) )
//   //____     ___      ___                  //___/ /  //  ___      ___     / ___
//  / ____    //   ) ) ((   ) ) //   / /     / __  (   // //   ) ) //   ) ) //\ \
// //        //   / /   \ \    ((___/ /     //    ) ) // //   / / //       //  \ \
////____/ / ((___( ( //   ) )      / /     //____/ / // ((___/ / ((____   //    \ \
// Developed by Dogu Deniz UGUR (https://github.com/DoguD)

pragma solidity ^0.8.0;

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

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

library Strings {

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

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
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {

        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED; _; _status = _NOT_ENTERED;

    }

}

interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);

}

interface IERC721Metadata is IERC721 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);

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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }

}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {

    using Address for address;
    using Strings for uint256;

    string private _name;
    string private _symbol;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

interface IERC721Enumerable is IERC721 {

    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);

}

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {

    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;

    uint256[] private _allTokens;

    mapping(uint256 => uint256) private _allTokensIndex;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;

        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// EasyBlock Interfaces START
interface EasyAvatarsRewards {
    function setNFTIndex(uint256 _tokenId) external;

    function getSingleReward(uint256 _tokenId) external view returns(uint256);
}

interface EasyBlock {
    function shareCount(address _target) external view returns(uint256);

    function decreaseShareCount(address _target, uint256 _amount) external;
}

interface EasyAvatarsSVG {
    function skinToneNames(uint) external view returns(string memory);
    function skinToneLayers(uint) external view returns(string memory);

    function eyeColorNames(uint) external view returns(string memory);
    function eyeColorLayers(uint) external view returns(string memory);

    function glassesNames(uint) external view returns(string memory);
    function glassesLayers(uint) external view returns(string memory);

    function mouthNames(uint) external view returns(string memory);
    function mouthLayers(uint) external view returns(string memory);

    function mouthPieceNames(uint) external view returns(string memory);
    function mouthPieceLayers(uint) external view returns(string memory);
}
// EasyBlock Interfaces END


contract EasyAvatars is ERC721Enumerable, ReentrancyGuard, Ownable {

    uint256 public maxSupply = 5000;
    uint256 public price = 20 ether;
    uint256 public maxMint = 20;
    uint256 public numTokensMinted;
    bool public isFTMMintable = true;
    // Reward Related
    bool private showClaimableReward = true;
    bool private showShareCount = true;
    uint256 public priceFtm = 100 ether;
    uint256 public numTokensMintedFtm;
    mapping(uint256 => bool) public tokenIncludesShare;

    EasyAvatarsRewards easyAvatarsRewardsContract;
    function setEasyAvatarsRewardsContract(address _target) external onlyOwner{
        easyAvatarsRewardsContract = EasyAvatarsRewards(_target);
    }

    EasyBlock easyBlockContract;
    function setEasyBlockContract(address _target) external onlyOwner{
        easyBlockContract = EasyBlock(_target);
    }

    EasyAvatarsSVG easyAvatarsSVGContract;
    function setEasyAvatarsSVGContract(address _target) external onlyOwner{
        easyAvatarsSVGContract = EasyAvatarsSVG(_target);
    }

    struct EasyAvatarObject {
        uint256 skinTone;
        uint256 eyeColor;
        uint256 glasses;
        uint256 mouth;
        uint256 mouthPiece;
    }

    function randomEasyAvatar(uint256 tokenId) internal view returns (EasyAvatarObject memory) {
        
        EasyAvatarObject memory easyAvatar;

        easyAvatar.skinTone = getSkinTone(tokenId);
        easyAvatar.eyeColor = getEyeColor(tokenId);
        easyAvatar.glasses = getGlasses(tokenId);
        easyAvatar.mouth = getMouth(tokenId);
        easyAvatar.mouthPiece = getMouthPiece(tokenId, easyAvatar.mouth);

        return easyAvatar;
    }
    
    function getTraits(EasyAvatarObject memory easyAvatar, uint256 tokenId) internal view returns (string memory) {
        
        string[26] memory parts;
        
        parts[0] = ', "attributes": [';
        parts[1] = '{"trait_type": "Skin Tone","value": "';
        parts[2] = easyAvatarsSVGContract.skinToneNames(easyAvatar.skinTone);
        parts[3] = '"}, {"trait_type": "Eye Color","value": "';
        parts[4] = easyAvatarsSVGContract.eyeColorNames(easyAvatar.eyeColor);
        parts[5] = '"}, {"trait_type": "Glasses","value": "';
        parts[6] = easyAvatarsSVGContract.glassesNames(easyAvatar.glasses);
        parts[7] = '"}, {"trait_type": "Mouth","value": "';
        parts[8] = easyAvatarsSVGContract.mouthNames(easyAvatar.mouth);
        parts[9] = '"}, {"trait_type": "Accessory","value": "';
        parts[10] = easyAvatarsSVGContract.mouthPieceNames(easyAvatar.mouthPiece);
        // TYPES
        // Invisible
        parts[11] = '"}, {"trait_type": "Type: Invisible","value": "';
        if(easyAvatar.skinTone == 16) {
            parts[12] = 'Yes';
        } else {
            parts[12] = 'No';
        }
        // Zombie
        parts[13] = '"}, {"trait_type": "Type: Zombie","value": "';
        if(easyAvatar.skinTone == 18 || easyAvatar.mouth == 6) {
            parts[14] = 'Yes';
        } else {
            parts[14] = 'No';
        }
        // Alien
        parts[15] = '"}, {"trait_type": "Type: Alien","value": "';
        if (easyAvatar.skinTone == 17 || easyAvatar.eyeColor == 14) {
            parts[16] = "Yes";
        } else {
            parts[16] = "No";
        }
        // Vampire
        parts[17] = '"}, {"trait_type": "Type: Vampire","value": "';
        if(easyAvatar.eyeColor == 15 || easyAvatar.mouth == 7) {
            parts[18] = 'Yes';
        } else {
            parts[18] = "No";
        }
        // GENERATIONS
        parts[19] = '"}, {"trait_type": "Generation","value": "';
        if (tokenId < 101) {
            parts[20] = "0";
        } else {
            parts[20] = toString(tokenId / 1001 + 1);
        }
        // Reward related info
        if(tokenIncludesShare[tokenId]) {
            if(showClaimableReward) {
                parts[21] = '"}, {"trait_type": "Claimable Reward","value": "';
                parts [22] = getClaimableReward(tokenId);
            }
            if(showShareCount) {
                parts[23] = '"}, {"trait_type": "EasyBlock Strong Shares Included","value": "';
                if(tokenIncludesShare[tokenId]) {
                    parts[24] = '50';
                } else {
                    parts[24] = '0';
                }
            }
        }
        parts[25] = '"}], ';
        
        
        
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7]));
                      output = string(abi.encodePacked(output, parts[8], parts[9], parts[10], parts[11], parts[12], parts[13], parts[14]));
                      output = string(abi.encodePacked(output, parts[15], parts[16], parts[17], parts[18], parts[19], parts[20]));
                      output = string(abi.encodePacked(output, parts[21], parts[22], parts[23], parts[24], parts[25]));
        return output;
    }

    function getClaimableReward(uint256 _tokenId) internal view returns (string memory) {
        string[4] memory parts;
        uint256 _reward = easyAvatarsRewardsContract.getSingleReward(_tokenId);
        parts[0] = toString(_reward/1000000);
        parts[1] = '.';
        parts[2] = toString(_reward % 1000000);
        parts[3] = ' $USDC';
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3]));
        return output;
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getSkinTone(uint256 tokenId) internal pure returns (uint256) { // 5
        uint256 rand = random(string(abi.encodePacked("SKIN TONE", toString(tokenId))));

        uint256 rn = rand % 1000;
        // Specials (50% chance)
        if (rn>= 500) {return rn % 19;}
        // Normal
        else {return rn % 16;}
    }

    function getEyeColor(uint256 tokenId) internal pure returns (uint256) { //4
        uint256 rand = random(string(abi.encodePacked("EYE COLOR", toString(tokenId))));

        uint256 rn = rand % 1000;
        // Specials (50% chance)
        if(rn >=500) {return rn % 16;}
        else {return rn % 14;}
    }

    function getGlasses(uint256 tokenId) internal pure returns (uint256) { // 2
        uint256 rand = random(string(abi.encodePacked("GLASSES", toString(tokenId))));

        uint256 rn = rand % 1000;
        // Specials (50% chance)
        if (rn >= 500) {return rn % 10; }// Includes the glasses
        else {return 0; }// No glasses
    }

    function getMouth(uint256 tokenId) internal pure returns (uint256) { // 4
        uint256 rand = random(string(abi.encodePacked("MOUTH", toString(tokenId))));

        uint256 rn = rand % 1000;
        // With Special (50% chance)
        if(rn >= 500) {return rn % 8;}
        else {return rn % 6;}
    }

    function getMouthPiece(uint256 tokenId, uint256 mouthType) internal pure returns(uint256) {
        if(mouthType == 1 || mouthType == 2 || mouthType == 3) {
            return 0;
        }
        uint256 rand = random(string(abi.encodePacked("MOUTH PIECE", toString(tokenId))));

        uint256 rn = rand % 1000;
        // With Special (50% chance)
        if(rn >= 900) {return rn % 4;}
        else {return 0;}
    }

    function getSVG(EasyAvatarObject memory easyAvatar) internal view returns (string memory) {
        string[13] memory parts;

        parts[0] = '<svg id="x" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 30 30">';

        // Skin Tone
        if(easyAvatar.skinTone > 15) {
            parts[1] = easyAvatarsSVGContract.skinToneLayers(easyAvatar.skinTone);
        }
        else {
            parts[1] = '<path d="M4 4h22v22H4z" fill="';
            parts[2] = easyAvatarsSVGContract.skinToneLayers(easyAvatar.skinTone);
            parts[3] = '"/>';
        }
        // Outline
        parts[4] = '<path d="M4 4.5h1m5 0h1m5 0h1m5 0h1m-19 1h1m20 1h1m-22 2h1m-1 1h1m20 1h1m-1 2h1m-22 1h1m20 0h1m-1 2h1m-1 1h1m-22 1h1m-1 2h1m-1 1h1m20 0h1m-1 1h1m-22 1h1m-1 1h1m-1 1h1m2 1h1m2 0h1m2 0h1m8 0h1m2 0h1M5 4.5h1m2 0h1m6 0h1m-10 21h1m5 0h1m5 0h1m5 0h1M6 4.5h1m2 0h1m8 0h1m2 21h1M7 4.5h1m4 0h2m5 0h3m1 0h3m-1 1h1m-22 1h1m-1 1h1m20 0h1m-1 1h1m-1 1h1m-22 1h1m-1 1h1m20 0h1m-22 1h1m-1 2h1m20 0h1m-22 1h1m-1 1h1m20 1h1m-22 1h1m20 0h1m-1 1h1m-22 2h1m20 1h1m-1 1h1m-1 1h1m-22 1h2m3 0h1m4 0h3m2 0h1m3 0h1m-13-21h1m2 0h1m2 0h1m-10 21h1m2 0h1m5 0h1m2 0h1" stroke="#000"/>';
        // Eye Color
        parts[5] = '<path d="M8 10h3v3H8zm11 0h3v3h-3z" fill="';
        parts[6] = easyAvatarsSVGContract.eyeColorLayers(easyAvatar.eyeColor);
        parts[7] = '"/>';
        // Pupil
        parts[8] = '<path fill="#000" d="M9 11h1v1H9zm11 0h1v1h-1z"/>';
        parts[9] = easyAvatarsSVGContract.glassesLayers(easyAvatar.glasses);
        parts[10] = easyAvatarsSVGContract.mouthLayers(easyAvatar.mouth);
        parts[11] = easyAvatarsSVGContract.mouthPieceLayers(easyAvatar.mouthPiece);
        parts[12] = '<style>#x{shape-rendering: crispedges;}</style></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7]));
                      output = string(abi.encodePacked(output, parts[8],parts[9],parts[10], parts[11], parts[12]));

        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(tokenId <= numTokensMinted);
        EasyAvatarObject memory easyAvatar = randomEasyAvatar(tokenId);
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "The Easy Club #', toString(tokenId), '", "description": "Official EasyBlock Genesis NFTs | 5000 Limited. All artwork and metadata are fully on-chain and randomly generated at mint. Each NFT grants many communal and financial benefits under the EasyBlock ecosystem."', getTraits(easyAvatar, tokenId), '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(getSVG(easyAvatar))), '"}'))));
        json = string(abi.encodePacked('data:application/json;base64,', json));
        return json;
    }

    function mint(address destination, uint256 amountOfTokens, uint256 targetShareCount) private {
        require(totalSupply() < maxSupply, "All tokens have been minted");
        require(totalSupply() + amountOfTokens <= maxSupply, "Minting would exceed max supply");

        require(amountOfTokens <= maxMint, "Cannot purchase this many tokens in a transaction");
        require(amountOfTokens > 0, "Must mint at least one token");
        require(price * amountOfTokens == msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfTokens; i++) {
            uint256 tokenId = numTokensMinted + 1;
            _safeMint(destination, tokenId);
            numTokensMinted += 1;
            tokenIncludesShare[tokenId] = true;
            // Set reward index
            easyAvatarsRewardsContract.setNFTIndex(tokenId);
            // Decrease Share Count
            easyBlockContract.decreaseShareCount(_msgSender(), 5000);
        }
        // Safety check for share count
        require(easyBlockContract.shareCount(_msgSender()) == targetShareCount, "Share count is not true.");
    }

    function mintWithFTM(address destination, uint256 amountOfTokens) private {
        require(totalSupply() < maxSupply, "All tokens have been minted");
        require(totalSupply() + amountOfTokens <= maxSupply, "Minting would exceed max supply");

        require(amountOfTokens <= maxMint, "Cannot purchase this many tokens in a transaction");
        require(amountOfTokens > 0, "Must mint at least one token");
        require(priceFtm * amountOfTokens == msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfTokens; i++) {
            uint256 tokenId = numTokensMinted + 1;
            _safeMint(destination, tokenId);
            numTokensMinted += 1;
            numTokensMintedFtm += 1;
        }
    }

    function mintForSelf(uint256 amountOfTokens) public payable virtual {
        require(amountOfTokens * 5000 <= easyBlockContract.shareCount(_msgSender()), "Not enough shares");
        mint(_msgSender(),amountOfTokens, easyBlockContract.shareCount(_msgSender())-amountOfTokens*5000);
    }

    function mintForFriend(address walletAddress, uint256 amountOfTokens) public payable virtual {
        require(amountOfTokens * 5000 <= easyBlockContract.shareCount(_msgSender()), "Not enough shares");
        mint(walletAddress,amountOfTokens, easyBlockContract.shareCount(_msgSender())-amountOfTokens*5000);
    }

    function mintForSelfFtm(uint256 amountOfTokens) public payable virtual {
        require(isFTMMintable, "Can't mint with FTM.");
        mintWithFTM(_msgSender(), amountOfTokens);
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function setPriceFtm(uint256 newPrice) public onlyOwner {
        priceFtm = newPrice;
    }

    function setMaxMint(uint256 newMaxMint) public onlyOwner {
        maxMint = newMaxMint;
    }

    function setFTMMintable(bool newFTMMintable) public onlyOwner {
        isFTMMintable = newFTMMintable;
    }

    function setShowClaimableReward(bool newShowClaimableReward) public onlyOwner {
        showClaimableReward = newShowClaimableReward;
    }

    function setShowShareCount(bool newShowShareCount) public onlyOwner {
        showShareCount = newShowShareCount;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }

    function toString(uint256 value) internal pure returns (string memory) {

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    constructor() ERC721("The Easy Club", "EASY") Ownable() {}
}

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        uint256 encodedLen = 4 * ((len + 2) / 3);

        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}