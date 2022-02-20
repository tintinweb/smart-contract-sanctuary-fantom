/**
 *Submitted for verification at FtmScan.com on 2022-02-20
*/

// SPDX-License-Identifier: GPL-3.0

// File: @openzeppelin/contracts/utils/Counters.sol



pragma solidity ^0.8.0;

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
    unchecked {
        counter._value += 1;
    }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
    unchecked {
        counter._value = value - 1;
    }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol



pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: contracts/access/Developer.sol


pragma solidity >=0.8.0 <0.9.0;


abstract contract Developer is Context {

    address private _developer;

    event DeveloperTransferred(address indexed previousDeveloper, address indexed newDeveloper);

    constructor() {
        _transferDeveloper(_msgSender());
    }


    function developer() public view virtual returns (address) {
        return _developer;
    }

    modifier onlyDev() {
        require(developer() == _msgSender(), "Developer: caller is not the developer");
        _;
    }

    function renounceDeveloper() public virtual onlyDev {
        _transferDeveloper(address(0));
    }

    function transferDeveloper(address newDeveloper) public virtual onlyDev {
        require(newDeveloper != address(0), "Developer: new developer is the zero address");
        _transferDeveloper(newDeveloper);
    }

    function _transferDeveloper(address newDeveloper) internal virtual {
        address oldDeveloper = _developer;
        _developer = newDeveloper;
        emit DeveloperTransferred(oldDeveloper, newDeveloper);
    }
}
// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity ^0.8.0;


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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// File: contracts/modules/PaymentSplitter.sol


pragma solidity >=0.8.0 <0.9.0;


abstract contract PaymentSplitter is Context {

    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;
    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    function claim() public virtual {
        require(_shares[msg.sender] > 0, "PaymentSplitter: msg.sender has no shares");

        uint256 totalReceived = address(this).balance + _totalReleased;
        uint256 payment = (totalReceived * _shares[msg.sender]) / _totalShares - _released[msg.sender];

        require(payment != 0, "PaymentSplitter: msg.sender is not due payment");

        _released[msg.sender] = _released[msg.sender] + payment;
        _totalReleased = _totalReleased + payment;

        Address.sendValue(payable(msg.sender), payment);
        emit PaymentReleased(msg.sender, payment);
    }

    function _addPayee(address account, uint256 shares_) internal {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;

        emit PayeeAdded(account, shares_);
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol



pragma solidity ^0.8.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



pragma solidity ^0.8.0;

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: contracts/interface/IMAX721.sol


pragma solidity >=0.8.0 <0.9.0;



interface IMAX721 is IERC165 {

    function minterStatus() external view returns (bool);

    function minterFees() external view returns (uint256);

    function minterMaximumCapacity() external view returns (uint256);

    function minterMaximumTeamMints() external view returns (uint256);

    function minterTeamMintsRemaining() external view returns (uint256);

    function minterTeamMintsCount() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}
// File: contracts/interface/IERC2981.sol


pragma solidity >=0.8.0 <0.9.0;



interface IERC2981 is IERC165 {

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);

}
// File: contracts/ERC2981Collection.sol


pragma solidity >=0.8.0 <0.9.0;


abstract contract ERC2981Collection is IERC2981 {

    address private royaltyAddress;
    uint256 private royaltyPercent;

    function _setRoyalties(address _receiver, uint256 _percentage) internal {
        royaltyAddress = _receiver;
        royaltyPercent = _percentage;
    }

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view override(IERC2981) returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        receiver = royaltyAddress;

        royaltyAmount = _salePrice * royaltyPercent / 100;
    }
}
// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol



pragma solidity ^0.8.0;


interface IERC721Metadata is IERC721 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol



pragma solidity ^0.8.0;

abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol



pragma solidity ^0.8.0;


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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: @openzeppelin/contracts/utils/introspection/ERC165Storage.sol



pragma solidity ^0.8.0;


abstract contract ERC165Storage is ERC165 {

    mapping(bytes4 => bool) private _supportedInterfaces;


    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: contracts/ERC721v2Collection.sol


pragma solidity >=0.8.0 <0.9.0;


contract ESADFlat is ERC721, ERC2981Collection, IMAX721, ERC165Storage, PaymentSplitter, Developer, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _teamMintCounter;
    uint256 private mintFees;
    uint256 private mintSize;
    uint256 private teamMintSize;
    string private base;
    string private baseExtension = ".json";
    bool private enableMinter;

    event UpdatedBaseURI(string _old, string _new);
    event UpdatedMintFees(uint256 _old, uint256 _new);
    event UpdatedMintSize(uint256 _old, uint256 _new);
    event UpdatedMintStatus(bool _old, bool _new);
    event UpdatedRoyalties(address newRoyaltyAddress, uint256 newPercentage);
    event UpdatedTeamMintSize(uint256 _old, uint256 _new);


    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_IERC2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ERC2981Collection = 0x6af56a00;
    bytes4 private constant _INTERFACE_ID_IMAX721 = 0x29499a25;
    bytes4 private constant _INTERFACE_ID_Developer = 0x538a50ce;
    bytes4 private constant _INTERFACE_ID_PaymentSplitter = 0x20998aed;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {

        // ECR165 Interfaces Supported
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_IERC2981);
        _registerInterface(_INTERFACE_ID_ERC2981Collection);
        _registerInterface(_INTERFACE_ID_IMAX721);
        _registerInterface(_INTERFACE_ID_Developer);
        _registerInterface(_INTERFACE_ID_PaymentSplitter);
    }


    function publicMint(uint256 amount) public payable {
        require(enableMinter, "Minter not active");
        require(msg.value == mintFees * amount, "Wrong amount of Native Token");
        require(_tokenIdCounter.current() + amount < mintSize, "Can not mint that many");

        for (uint i = 0; i < amount; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function teamMint(address _address) public onlyOwner {
        require(teamMintSize != 0, "Team minting not enabled");
        require(_tokenIdCounter.current() < mintSize, "Can not mint that many");
        require(_teamMintCounter.current() < teamMintSize, "Can not team mint anymore");
        _safeMint(_address, _tokenIdCounter.current());
        _tokenIdCounter.increment();
        _teamMintCounter.increment();
    }


    receive() external payable {
        // From PaymentSplitter.sol
        emit PaymentReceived(msg.sender, msg.value);
    }


    fallback() external payable {
        // From PaymentSplitter.sol
        emit PaymentReceived(msg.sender, msg.value);
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }


    function setRoyaltyInfo(address _royaltyAddress, uint256 _percentage) public onlyOwner {
        _setRoyalties(_royaltyAddress, _percentage);
        emit UpdatedRoyalties(_royaltyAddress, _percentage);
    }

    function setMintFees(uint256 _newFee) public onlyOwner {
        uint256 oldFee = mintFees;
        mintFees = _newFee;
        emit UpdatedMintFees(oldFee, mintFees);
    }

    function enableMinting() public onlyOwner {
        bool old = enableMinter;
        enableMinter = true;
        emit UpdatedMintStatus(old, enableMinter);
    }

    function disableMinting() public onlyOwner {
        bool old = enableMinter;
        enableMinter = false;
        emit UpdatedMintStatus(old, enableMinter);
    }

    function setBaseURI(string memory _base) public onlyDev {
        string memory old = base;
        base = _base;
        emit UpdatedBaseURI(old, base);
    }

    function setTeamMinting(uint256 _amount) public onlyDev {
        uint256 old = teamMintSize;
        teamMintSize = _amount;
        emit UpdatedTeamMintSize(old, teamMintSize);
    }

    function setMintSize(uint256 _amount) public onlyDev {
        uint256 old = mintSize;
        mintSize = _amount;
        emit UpdatedMintSize(old, mintSize);
    }

    function addPayee(address addy, uint256 shares) public onlyDev {
        _addPayee(addy, shares);
    }

    function sweepEthToAddress(address _user, uint256 _amount) public onlyDev {
        payable(_user).transfer(_amount);
    }

 

    function _baseURI() internal view override returns (string memory) {
        return base;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC165Storage, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function minterStatus() external view override(IMAX721) returns (bool) {
        return enableMinter;
    }

    function minterFees() external view override(IMAX721) returns (uint256) {
        return mintFees;
    }

    function minterMaximumCapacity() external view override(IMAX721) returns (uint256) {
        return mintSize;
    }

    function minterMaximumTeamMints() external view override(IMAX721) returns (uint256) {
        return teamMintSize;
    }
    function minterTeamMintsRemaining() external view override(IMAX721) returns (uint256) {
        return teamMintSize - _teamMintCounter.current();
    }

    function minterTeamMintsCount() external view override(IMAX721) returns (uint256) {
        return _teamMintCounter.current();
    }

    function totalSupply() external view override(IMAX721) returns (uint256) {
        return _tokenIdCounter.current();
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        uint256 _newTokenId = tokenId + 1;
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _newTokenId.toString(), baseExtension))
        : "";
    }
}