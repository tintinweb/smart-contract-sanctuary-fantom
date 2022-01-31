/**
 *Submitted for verification at FtmScan.com on 2022-01-31
*/

/*
 $$$$$$\  $$\            $$\     $$\                                             
$$  __$$\ $$ |           $$ |    $$ |                                            
$$ /  \__|$$ | $$$$$$\ $$$$$$\   $$$$$$$\                                        
\$$$$$$\  $$ |$$  __$$\\_$$  _|  $$  __$$\                                       
 \____$$\ $$ |$$ /  $$ | $$ |    $$ |  $$ |                                      
$$\   $$ |$$ |$$ |  $$ | $$ |$$\ $$ |  $$ |                                      
\$$$$$$  |$$ |\$$$$$$  | \$$$$  |$$ |  $$ |                                      
 \______/ \__| \______/   \____/ \__|  \__|                                      
                                                                                 
                                                                                 
                                                                                 
             $$$$$$\                       $$\                                   
            $$  __$$\                      $$ |                                  
            $$ /  $$ |$$\    $$\ $$$$$$\ $$$$$$\    $$$$$$\   $$$$$$\   $$$$$$$\ 
            $$$$$$$$ |\$$\  $$  |\____$$\\_$$  _|   \____$$\ $$  __$$\ $$  _____|
            $$  __$$ | \$$\$$  / $$$$$$$ | $$ |     $$$$$$$ |$$ |  \__|\$$$$$$\  
            $$ |  $$ |  \$$$  / $$  __$$ | $$ |$$\ $$  __$$ |$$ |       \____$$\ 
            $$ |  $$ |   \$  /  \$$$$$$$ | \$$$$  |\$$$$$$$ |$$ |      $$$$$$$  |
            \__|  \__|    \_/    \_______|  \____/  \_______|\__|      \_______/ 
                                                                                 
                                                                                 
                                                                                 
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0;


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
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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


interface IERC721Metadata is IERC721 {
   
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}


library SlothHelper {
    function isContract(address account) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function toString(uint256 value) public pure returns (string memory) {
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
}


contract SlothAvatar is Ownable, ERC165, IERC721, IERC721Metadata {
    // Token name
    string private _name = "SlothAvatar";

    // Token symbol
    string private _symbol = "SlothAvatars";

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    uint256 private mintIndex = 1;
    uint256 private ownerMintIndex = 0;
    uint256 private constant baseCost = 1 ether;
    uint256 public constant maxSupply = 1466;
    uint256 public constant reservedSupply = 466;
    uint256 public constant mintCost = 50;
    string baseURL;
    string baseExtention = "";


    constructor(string memory _url, string memory _extention) {
        baseURL = _url;
        baseExtention = _extention;
    }

    function changeURLParams(string memory _nURL, string memory _nBaseExt) external onlyOwner {
        baseURL = _nURL;
        baseExtention = _nBaseExt;
    }

    function totalSupply() public view returns(uint256){
        return mintIndex;
    }

    function walletOfOwner(address wallet) public view returns(uint256[] memory walletNFTs){
        uint256 amnt = 0;
        for(uint256 i=1; i<mintIndex; i++){
            if(ownerOf(i) == wallet){
                amnt += 1;
            }
        }
        walletNFTs = new uint256[](amnt);
        uint256 _idx = 0;
        for(uint256 i=1; i<mintIndex; i++){
            if(ownerOf(i) == wallet){
                walletNFTs[_idx] = i;
                _idx += 1;
            }
        }
    }

    function mintAvatar(address to, uint256 amount) external payable {
        require(mintIndex <= maxSupply, "SlothAvatar: All the avatars are out minted!");
        if(msg.sender == owner()){
            require(ownerMintIndex+amount < reservedSupply, "SlothAvatar: All reserves have been minted!");
            for(uint256 i=0; i<amount; i++){
                _mint(to, mintIndex);
                mintIndex += 1;
            }
            ownerMintIndex += amount;
        }else{
            require(mintIndex <= (maxSupply - reservedSupply), "SlothAvatar: All avaliable avatars have been minted");
            require(amount == 1, "SlothAvatar: Can only mint 1 avatar at a time");
            require(msg.value >= mintCost*baseCost, "SlothAvatar: Need to pay minting fee");
            _mint(to, mintIndex);
            mintIndex += 1;
        }
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
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, SlothHelper.toString(tokenId), baseExtention)) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseURL;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
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
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }


    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);
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
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

   
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function withdraw() external onlyOwner {
        require(payable(owner()).send(address(this).balance));
    }

    function withdrawAmount(uint256 amnt) external onlyOwner {
        payable(owner()).transfer(amnt*baseCost);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (SlothHelper.isContract(to)) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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

}