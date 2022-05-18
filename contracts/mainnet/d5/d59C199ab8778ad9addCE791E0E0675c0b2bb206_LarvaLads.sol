/**
 *Submitted for verification at FtmScan.com on 2022-05-18
*/

/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

//SPDX-License-Identifier: Unlicense
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


//██///////█████//██████//██////██//█████//////██///////█████//██████//███████//
//██//////██///██/██///██/██////██/██///██/////██//////██///██/██///██/██///////
//██//////███████/██████//██////██/███████/////██//////███████/██///██/███████//
//██//////██///██/██///██//██//██//██///██/////██//////██///██/██///██//////██//
//███████/██///██/██///██///████///██///██/////███████/██///██/██████//███████//


contract LarvaLads is ERC721Enumerable, ReentrancyGuard, Ownable {

    uint256 public maxSupply = 5000;
    uint256 public price = 0.05 ether;
    uint256 public maxMint = 10;
    uint256 public numTokensMinted;

    // ATTRIBUTES START
    string[8] private baseColors = ['#AE8B61','#DBB181','#E8AA96','#FFC2C2','#EECFA0','#C9CDAF','#D5C6E1','#EAD9D9'];

    string[5] private skinToneNames = ['0', '1', '2', '3','4'];
    string[5] private skinToneLayers = [
        '<rect x="4" y="4" width="22" height="22" fill="#FFDBAC"/>',
        '<rect x="4" y="4" width="22" height="22" fill="#F1C27D"/>',
        '<rect x="4" y="4" width="22" height="22" fill="#E0AC69"/>',
        '<rect x="4" y="4" width="22" height="22" fill="#C68642"/>',
        '<rect x="4" y="4" width="22" height="22" fill="#8D5524"/>'
    ];

    string[4] private eyeColorNames = ['Black', 'Brown', 'Blue', 'Green'];
    string[4] private eyeColorLayers = [
        '<rect x="8" y="10" width="3" height="3" fill="#000000"/><rect x="19" y="10" width="3" height="3" fill="#000000"/>',
        '<rect x="8" y="10" width="3" height="3" fill="#634e34"/><rect x="19" y="10" width="3" height="3" fill="#634e34"/>',
        '<rect x="8" y="10" width="3" height="3" fill="#2e536f"/><rect x="19" y="10" width="3" height="3" fill="#2e536f"/>',
        '<rect x="8" y="10" width="3" height="3" fill="#3d671d"/><rect x="19" y="10" width="3" height="3" fill="#3d671d"/>'
    ];

    string[2] private glassesNames = ['None', 'Glasses'];
    string[2] private glassesLayers = [
        '',
        '<path class="cls-1" d="M24.44 10.93h.97v.96h-.97zM23.48 10.93h.96v.96h-.96zM22.51 13.84h.97v.97h-.97zM22.51 12.87h.97v.97h-.97z"/><path class="cls-1" d="M22.51 11.9h.97v.97h-.97zM22.51 10.93h.97v.96h-.97z"/><path class="cls-1" d="M22.51 9.96h.97v.97h-.97zM22.51 8.99h.97v.97h-.97zM22.51 8.02h.97v.97h-.97zM21.54 13.84h.97v.97h-.97zM21.54 8.02h.97v.97h-.97zM20.57 13.84h.97v.97h-.97zM20.57 8.02h.97v.97h-.97zM19.6 13.84h.97v.97h-.97zM19.6 8.02h.97v.97h-.97zM18.64 13.84h.96v.97h-.96zM18.64 8.02h.96v.97h-.96zM17.67 13.84h.97v.97h-.97zM17.67 8.02h.97v.97h-.97zM16.7 13.84h.97v.97h-.97zM16.7 12.87h.97v.97h-.97z"/><path class="cls-1" d="M16.7 11.9h.97v.97h-.97zM16.7 10.93h.97v.96h-.97z"/><path class="cls-1" d="M16.7 9.96h.97v.97h-.97zM16.7 8.99h.97v.97h-.97zM16.7 8.02h.97v.97h-.97zM15.73 10.93h.97v.96h-.97z"/><path class="cls-1" d="M14.77 10.93h.96v.96h-.96z"/><path class="cls-1" d="M13.8 10.93h.97v.96h-.97zM12.83 10.93h.97v.96h-.97zM11.86 13.84h.97v.97h-.97zM11.86 12.87h.97v.97h-.97z"/><path class="cls-1" d="M11.86 11.9h.97v.97h-.97zM11.86 10.93h.97v.96h-.97z"/><path class="cls-1" d="M11.86 9.96h.97v.97h-.97zM11.86 8.99h.97v.97h-.97zM11.86 8.02h.97v.97h-.97zM10.9 13.84h.96v.97h-.96zM10.9 8.02h.96v.97h-.96z"/><path class="cls-1" d="M9.93 13.84h.97v.97h-.97zM9.93 8.02h.97v.97h-.97z"/><path class="cls-1" d="M8.96 13.84h.97v.97h-.97zM8.96 8.02h.97v.97h-.97zM7.99 13.84h.97v.97h-.97zM7.99 8.02h.97v.97h-.97zM7.02 13.84h.97v.97h-.97zM7.02 8.02h.97v.97h-.97zM6.06 13.84h.96v.97h-.96zM6.06 12.87h.96v.97h-.96z"/><path class="cls-1" d="M6.06 11.9h.96v.97h-.96zM6.06 10.93h.96v.96h-.96z"/><path class="cls-1" d="M6.06 9.96h.96v.97h-.96zM6.06 8.99h.96v.97h-.96zM6.06 8.02h.96v.97h-.96zM5.09 10.93h.97v.96h-.97zM4.12 10.93h.97v.96h-.97z"/>'
    ];

    string[4] private mouthNames = ['Normal', 'Smile', 'Frown', 'Ooo'];
    string[4] private mouthLayers = [
        '<rect class="cls-1" x="17.67" y="20.64" width="0.97" height="0.97"/><rect class="cls-1" x="16.7" y="20.64" width="0.97" height="0.97"/><rect class="cls-1" x="15.73" y="20.64" width="0.97" height="0.97"/><rect class="cls-1" x="14.77" y="20.64" width="0.96" height="0.97"/><rect class="cls-1" x="13.8" y="20.64" width="0.97" height="0.97"/><rect class="cls-1" x="12.83" y="20.64" width="0.97" height="0.97"/><rect class="cls-1" x="11.86" y="20.64" width="0.97" height="0.97"/><rect class="cls-1" x="10.9" y="20.64" width="0.96" height="0.97"/>',
        '<rect class="cls-1" x="19.6" y="18.7" width="0.97" height="0.96"/><rect class="cls-1" x="9.93" y="18.7" width="0.97" height="0.96"/><rect class="cls-1" x="8.96" y="18.7" width="0.97" height="0.96"/><rect class="cls-1" x="18.64" y="18.7" width="0.96" height="0.96"/><rect class="cls-1" x="18.64" y="19.66" width="0.96" height="0.97"/><rect class="cls-1" x="17.67" y="19.66" width="0.97" height="0.97"/><rect class="cls-1" x="9.93" y="19.66" width="0.97" height="0.97"/><rect class="cls-1" x="10.9" y="19.66" width="0.96" height="0.97"/><rect class="cls-1" x="17.67" y="20.64" width="0.97" height="0.97"/><rect class="cls-1" x="16.7" y="20.64" width="0.97" height="0.97"/><rect class="cls-1" x="15.73" y="20.64" width="0.97" height="0.97"/><rect class="cls-1" x="14.77" y="20.64" width="0.96" height="0.97"/><rect class="cls-1" x="13.8" y="20.64" width="0.97" height="0.97"/><rect class="cls-1" x="12.83" y="20.64" width="0.97" height="0.97"/><rect class="cls-1" x="11.86" y="20.64" width="0.97" height="0.97"/><rect class="cls-1" x="10.9" y="20.64" width="0.96" height="0.97"/>',
        '<rect class="cls-1" x="19.6" y="22.58" width="0.97" height="0.97"/><rect class="cls-1" x="18.64" y="22.58" width="0.96" height="0.97"/><rect class="cls-1" x="18.64" y="21.61" width="0.96" height="0.97"/><rect class="cls-1" x="17.67" y="21.61" width="0.97" height="0.97"/><rect class="cls-1" x="9.93" y="22.58" width="0.97" height="0.97"/><rect class="cls-1" x="8.96" y="22.58" width="0.97" height="0.97"/><rect class="cls-1" x="9.93" y="21.61" width="0.97" height="0.97"/><rect class="cls-1" x="10.9" y="21.61" width="0.96" height="0.97"/><rect class="cls-1" x="17.67" y="20.64" width="0.97" height="0.97"/><rect class="cls-1" x="16.7" y="20.64" width="0.97" height="0.97"/><rect class="cls-1" x="15.73" y="20.64" width="0.97" height="0.97"/><rect class="cls-1" x="14.77" y="20.64" width="0.96" height="0.97"/><rect class="cls-1" x="13.8" y="20.64" width="0.97" height="0.97"/><rect class="cls-1" x="12.83" y="20.64" width="0.97" height="0.97"/><rect class="cls-1" x="11.86" y="20.64" width="0.97" height="0.97"/><rect class="cls-1" x="10.9" y="20.64" width="0.96" height="0.97"/>',
        '<rect class="cls-1" x="15.73" y="18.7" width="0.97" height="0.96"/><rect class="cls-1" x="16.7" y="18.7" width="0.97" height="0.96"/><rect class="cls-1" x="13.8" y="18.7" width="0.97" height="0.96"/><rect class="cls-1" x="12.83" y="18.7" width="0.97" height="0.96"/><rect class="cls-1" x="11.86" y="18.7" width="0.97" height="0.96"/><rect class="cls-1" x="14.77" y="18.7" width="0.96" height="0.96"/><rect class="cls-1" x="17.67" y="18.7" width="0.97" height="0.96"/><rect class="cls-1" x="18.64" y="19.66" width="0.96" height="0.97"/><rect class="cls-1" x="19.6" y="20.64" width="0.97" height="0.97"/><rect class="cls-1" x="18.64" y="21.61" width="0.96" height="0.97"/><rect class="cls-1" x="15.73" y="22.58" width="0.97" height="0.97"/><rect class="cls-1" x="16.7" y="22.58" width="0.97" height="0.97"/><rect class="cls-1" x="17.67" y="22.58" width="0.97" height="0.97"/><rect class="cls-1" x="11.86" y="22.58" width="0.97" height="0.97"/><rect class="cls-1" x="12.83" y="22.58" width="0.97" height="0.97"/><rect class="cls-1" x="14.77" y="22.58" width="0.96" height="0.97"/><rect class="cls-1" x="13.8" y="22.58" width="0.97" height="0.97"/><rect class="cls-1" x="10.9" y="22.58" width="0.96" height="0.97"/><rect class="cls-1" x="9.93" y="21.61" width="0.97" height="0.97"/><rect class="cls-1" x="10.9" y="18.7" width="0.96" height="0.96"/><rect class="cls-1" x="9.93" y="19.66" width="0.97" height="0.97"/><rect class="cls-1" x="8.96" y="20.64" width="0.97" height="0.97"/>'
    ];
    // ATTRIBUTES END

    struct LarvaObject {
        uint256 baseColor;
        uint256 skinTone;
        uint256 eyeColor;
        uint256 glasses;
        uint256 mouth;
    }

    function randomLarvaLad(uint256 tokenId) internal view returns (LarvaObject memory) {
        
        LarvaObject memory larvaLad;

        larvaLad.baseColor = getBaseColor(tokenId);
        larvaLad.skinTone = getSkinTone(tokenId);
        larvaLad.eyeColor = getEyeColor(tokenId);
        larvaLad.glasses = getGlasses(tokenId);
        larvaLad.mouth = getMouth(tokenId);

        return larvaLad;
    }
    
    function getTraits(LarvaObject memory larvaLad) internal view returns (string memory) {
        
        string[12] memory parts;
        
        parts[0] = ', "attributes": [';
        parts[1] = '{"trait_type": "Background Color","value": "';
        parts[2] = baseColors[larvaLad.baseColor];
        parts[3] = '"}, {"trait_type": "Skin Tone","value": "';
        parts[4] = skinToneNames[larvaLad.skinTone];
        parts[5] = '"}, {"trait_type": "Eye Color","value": "';
        parts[6] = eyeColorNames[larvaLad.eyeColor];
        parts[7] = '"}, {"trait_type": "Glasses","value": "';
        parts[8] = glassesNames[larvaLad.glasses];
        parts[9] = '"}, {"trait_type": "Mouth","value": "';
        parts[10] = mouthNames[larvaLad.mouth];
        parts[11] = '"}], ';
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7]));
                      output = string(abi.encodePacked(output, parts[8], parts[9], parts[10], parts[11]));
        return output;
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getBaseColor(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("BASE COLOR", toString(tokenId))));

        uint256 rn1 = rand % 79;
        uint256 bc = 0;

        if (rn1 >= 10 && rn1 < 20) { bc = 1; }
        if (rn1 >= 20 && rn1 < 30) { bc = 2; }
        if (rn1 >= 30 && rn1 < 40) { bc = 3; }
        if (rn1 >= 40 && rn1 < 50) { bc = 4; }
        if (rn1 >= 50 && rn1 < 60) { bc = 5; }
        if (rn1 >= 60 && rn1 < 70) { bc = 6; }
        if (rn1 >= 70) { bc = 7; }

        return bc;
    }

    function getSkinTone(uint256 tokenId) internal pure returns (uint256) { // 5
        uint256 rand = random(string(abi.encodePacked("SKIN TONE", toString(tokenId))));

        uint256 rn = rand % 1000;

        if (rn >= 800) {return 4;}
        if (rn >=600) {return 3;}
        if (rn >= 400) {return 2;}
        if (rn >= 200) {return 1;}
        return 0;
    }

    function getEyeColor(uint256 tokenId) internal pure returns (uint256) { //4
        uint256 rand = random(string(abi.encodePacked("LAYER FOUR", toString(tokenId))));

        uint256 rn = rand % 1000;

        if (rn >=750) {return 3;}
        if (rn >= 500) {return 2;}
        if (rn >= 250) {return 1;}
        return 0;
    }

    function getGlasses(uint256 tokenId) internal pure returns (uint256) { // 2
        uint256 rand = random(string(abi.encodePacked("LAYER FIVE", toString(tokenId))));

        uint256 rn = rand % 1000;

        if (rn >= 500) {return 1;}
        return 0;
    }

    function getMouth(uint256 tokenId) internal pure returns (uint256) { // 4
        uint256 rand = random(string(abi.encodePacked("LAYER SIX", toString(tokenId))));

        uint256 rn = rand % 1000;

        if (rn >=750) {return 3;}
        if (rn >= 500) {return 2;}
        if (rn >= 250) {return 1;}
        return 0;
    }

    function getSVG(LarvaObject memory larvaLad) internal view returns (string memory) {
        string[8] memory parts;

        parts[0] = '<svg id="x" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 30 30"><path fill="';
        parts[1] = baseColors[larvaLad.baseColor];
        parts[2]= '" d="M0 0h30v30H0z"/>';
        parts[3] = skinToneLayers[larvaLad.skinTone];
        parts[4] = eyeColorLayers[larvaLad.eyeColor];
        parts[5] = glassesLayers[larvaLad.glasses];
        parts[6] = mouthLayers[larvaLad.mouth];
        parts[7] = '<style>#x{shape-rendering: crispedges;}</style></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7]));

        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        LarvaObject memory larvaLad = randomLarvaLad(tokenId);
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Larva Lad #', toString(tokenId), '", "description": "Larva Lads are a play on the CryptoPunks and their creators, Larva Labs. The artwork and metadata are fully on-chain and were randomly generated at mint."', getTraits(larvaLad), '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(getSVG(larvaLad))), '"}'))));
        json = string(abi.encodePacked('data:application/json;base64,', json));
        return json;
    }

    function mint(address destination, uint256 amountOfTokens) private {
        require(totalSupply() < maxSupply, "All tokens have been minted");
        require(totalSupply() + amountOfTokens <= maxSupply, "Minting would exceed max supply");
        require(amountOfTokens <= maxMint, "Cannot purchase this many tokens in a transaction");
        require(amountOfTokens > 0, "Must mint at least one token");
        require(price * amountOfTokens == msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfTokens; i++) {
            uint256 tokenId = numTokensMinted + 1;
            _safeMint(destination, tokenId);
            numTokensMinted += 1;
        }
    }

    function mintForSelf(uint256 amountOfTokens) public payable virtual {
        mint(_msgSender(),amountOfTokens);
    }

    function mintForFriend(address walletAddress, uint256 amountOfTokens) public payable virtual {
        mint(walletAddress,amountOfTokens);
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function setMaxMint(uint256 newMaxMint) public onlyOwner {
        maxMint = newMaxMint;
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
    
    constructor() ERC721("Larva Lads", "LARVA") Ownable() {}
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