/**
 *Submitted for verification at FtmScan.com on 2022-06-04
*/

pragma solidity 0.8.13;

library AddressUpgradeable {
  function isContract(address account) internal view returns (bool) {
    return account.code.length > 0;
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    (bool success, ) = recipient.call{value: amount}("");
    require(
      success,
      "Address: unable to send value, recipient may have reverted"
    );
  }

  function functionCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
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
    return
      functionCallWithValue(
        target,
        data,
        value,
        "Address: low-level call with value failed"
      );
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(
      address(this).balance >= value,
      "Address: insufficient balance for call"
    );
    require(isContract(target), "Address: call to non-contract");

    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  function functionStaticCall(address target, bytes memory data)
    internal
    view
    returns (bytes memory)
  {
    return
      functionStaticCall(target, data, "Address: low-level static call failed");
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

  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
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

abstract contract Initializable {
  bool private _initialized;

  bool private _initializing;

  modifier initializer() {
    require(
      _initializing ? _isConstructor() : !_initialized,
      "Initializable: contract is already initialized"
    );

    bool isTopLevelCall = !_initializing;
    if (isTopLevelCall) {
      _initializing = true;
      _initialized = true;
    }

    _;

    if (isTopLevelCall) {
      _initializing = false;
    }
  }

  modifier onlyInitializing() {
    require(_initializing, "Initializable: contract is not initializing");
    _;
  }

  function _isConstructor() private view returns (bool) {
    return !AddressUpgradeable.isContract(address(this));
  }
}

abstract contract ContextUpgradeable is Initializable {
  function __Context_init() internal onlyInitializing {}

  function __Context_init_unchained() internal onlyInitializing {}

  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }

  uint256[50] private __gap;
}

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  function __Ownable_init() internal onlyInitializing {
    __Ownable_init_unchained();
  }

  function __Ownable_init_unchained() internal onlyInitializing {
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

  uint256[49] private __gap;
}

abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
  event Paused(address account);

  event Unpaused(address account);

  bool private _paused;

  function __Pausable_init() internal onlyInitializing {
    __Pausable_init_unchained();
  }

  function __Pausable_init_unchained() internal onlyInitializing {
    _paused = false;
  }

  function paused() public view virtual returns (bool) {
    return _paused;
  }

  modifier whenNotPaused() {
    require(!paused(), "Pausable: paused");
    _;
  }

  modifier whenPaused() {
    require(paused(), "Pausable: not paused");
    _;
  }

  function _pause() internal virtual whenNotPaused {
    _paused = true;
    emit Paused(_msgSender());
  }

  function _unpause() internal virtual whenPaused {
    _paused = false;
    emit Unpaused(_msgSender());
  }

  uint256[49] private __gap;
}

interface IERC165Upgradeable {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721Upgradeable is IERC165Upgradeable {
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );

  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );

  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

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

  function getApproved(uint256 tokenId)
    external
    view
    returns (address operator);

  function setApprovalForAll(address operator, bool _approved) external;

  function isApprovedForAll(address owner, address operator)
    external
    view
    returns (bool);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;
}

interface IERC721ReceiverUpgradeable {
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

interface IERC721MetadataUpgradeable is IERC721Upgradeable {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function tokenURI(uint256 tokenId) external view returns (string memory);
}

library StringsUpgradeable {
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

  function toHexString(uint256 value, uint256 length)
    internal
    pure
    returns (string memory)
  {
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

abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
  function __ERC165_init() internal onlyInitializing {}

  function __ERC165_init_unchained() internal onlyInitializing {}

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
  {
    return interfaceId == type(IERC165Upgradeable).interfaceId;
  }

  uint256[50] private __gap;
}

contract ERC721Upgradeable is
  Initializable,
  ContextUpgradeable,
  ERC165Upgradeable,
  IERC721Upgradeable,
  IERC721MetadataUpgradeable
{
  using AddressUpgradeable for address;
  using StringsUpgradeable for uint256;

  string private _name;

  string private _symbol;

  mapping(uint256 => address) private _owners;

  mapping(address => uint256) private _balances;

  mapping(uint256 => address) private _tokenApprovals;

  mapping(address => mapping(address => bool)) private _operatorApprovals;

  function __ERC721_init(string memory name_, string memory symbol_)
    internal
    onlyInitializing
  {
    __ERC721_init_unchained(name_, symbol_);
  }

  function __ERC721_init_unchained(string memory name_, string memory symbol_)
    internal
    onlyInitializing
  {
    _name = name_;
    _symbol = symbol_;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165Upgradeable, IERC165Upgradeable)
    returns (bool)
  {
    return
      interfaceId == type(IERC721Upgradeable).interfaceId ||
      interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function balanceOf(address owner)
    public
    view
    virtual
    override
    returns (uint256)
  {
    require(owner != address(0), "ERC721: balance query for the zero address");
    return _balances[owner];
  }

  function ownerOf(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
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

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
  }

  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ERC721Upgradeable.ownerOf(tokenId);
    require(to != owner, "ERC721: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId);
  }

  function getApproved(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    require(_exists(tokenId), "ERC721: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override
  {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721: transfer caller is not owner nor approved"
    );

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
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721: transfer caller is not owner nor approved"
    );
    _safeTransfer(from, to, tokenId, _data);
  }

  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "ERC721: transfer to non ERC721Receiver implementer"
    );
  }

  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _owners[tokenId] != address(0);
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId)
    internal
    view
    virtual
    returns (bool)
  {
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    address owner = ERC721Upgradeable.ownerOf(tokenId);
    return (spender == owner ||
      getApproved(tokenId) == spender ||
      isApprovedForAll(owner, spender));
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

    _afterTokenTransfer(address(0), to, tokenId);
  }

  function _burn(uint256 tokenId) internal virtual {
    address owner = ERC721Upgradeable.ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId);

    _approve(address(0), tokenId);

    _balances[owner] -= 1;
    delete _owners[tokenId];

    emit Transfer(owner, address(0), tokenId);

    _afterTokenTransfer(owner, address(0), tokenId);
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {
    require(
      ERC721Upgradeable.ownerOf(tokenId) == from,
      "ERC721: transfer from incorrect owner"
    );
    require(to != address(0), "ERC721: transfer to the zero address");

    _beforeTokenTransfer(from, to, tokenId);

    _approve(address(0), tokenId);

    _balances[from] -= 1;
    _balances[to] += 1;
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);

    _afterTokenTransfer(from, to, tokenId);
  }

  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
  }

  function _setApprovalForAll(
    address owner,
    address operator,
    bool approved
  ) internal virtual {
    require(owner != operator, "ERC721: approve to caller");
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721ReceiverUpgradeable(to).onERC721Received(
          _msgSender(),
          from,
          tokenId,
          _data
        )
      returns (bytes4 retval) {
        return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
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

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}

  uint256[44] private __gap;
}

interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
  function totalSupply() external view returns (uint256);

  function tokenOfOwnerByIndex(address owner, uint256 index)
    external
    view
    returns (uint256);

  function tokenByIndex(uint256 index) external view returns (uint256);
}

abstract contract ERC721EnumerableUpgradeable is
  Initializable,
  ERC721Upgradeable,
  IERC721EnumerableUpgradeable
{
  function __ERC721Enumerable_init() internal onlyInitializing {}

  function __ERC721Enumerable_init_unchained() internal onlyInitializing {}

  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

  mapping(uint256 => uint256) private _ownedTokensIndex;

  uint256[] private _allTokens;

  mapping(uint256 => uint256) private _allTokensIndex;

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165Upgradeable, ERC721Upgradeable)
    returns (bool)
  {
    return
      interfaceId == type(IERC721EnumerableUpgradeable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    virtual
    override
    returns (uint256)
  {
    require(
      index < ERC721Upgradeable.balanceOf(owner),
      "ERC721Enumerable: owner index out of bounds"
    );
    return _ownedTokens[owner][index];
  }

  function totalSupply() public view virtual override returns (uint256) {
    return _allTokens.length;
  }

  function tokenByIndex(uint256 index)
    public
    view
    virtual
    override
    returns (uint256)
  {
    require(
      index < ERC721EnumerableUpgradeable.totalSupply(),
      "ERC721Enumerable: global index out of bounds"
    );
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
    uint256 length = ERC721Upgradeable.balanceOf(to);
    _ownedTokens[to][length] = tokenId;
    _ownedTokensIndex[tokenId] = length;
  }

  function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
    private
  {
    uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
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

  uint256[46] private __gap;
}

abstract contract ReentrancyGuardUpgradeable is Initializable {
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  function __ReentrancyGuard_init() internal onlyInitializing {
    __ReentrancyGuard_init_unchained();
  }

  function __ReentrancyGuard_init_unchained() internal onlyInitializing {
    _status = _NOT_ENTERED;
  }

  modifier nonReentrant() {
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

    _status = _ENTERED;

    _;

    _status = _NOT_ENTERED;
  }

  uint256[49] private __gap;
}

library SafeMathUpgradeable {
  function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      uint256 c = a + b;
      if (c < a) return (false, 0);
      return (true, c);
    }
  }

  function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (b > a) return (false, 0);
      return (true, a - b);
    }
  }

  function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (a == 0) return (true, 0);
      uint256 c = a * b;
      if (c / a != b) return (false, 0);
      return (true, c);
    }
  }

  function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (b == 0) return (false, 0);
      return (true, a / b);
    }
  }

  function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (b == 0) return (false, 0);
      return (true, a % b);
    }
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    return a + b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    return a * b;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return a % b;
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    unchecked {
      require(b <= a, errorMessage);
      return a - b;
    }
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    unchecked {
      require(b > 0, errorMessage);
      return a / b;
    }
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    unchecked {
      require(b > 0, errorMessage);
      return a % b;
    }
  }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address to, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IHonour is IERC20 {
  function transfer(address to, uint256 amount) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);
}

interface IHonourNode is IERC721Upgradeable {
  enum NodeType {
    BUKE,
    MONONOFU,
    MUSHA
  }

  struct HonourNodeState {
    string tier;
    uint256 rewardsRate;
  }

  struct HonourNode {
    NodeType tier;
    string name;
    string fantomRPC;
    string avalancheRPC;
    string polygonRPC;
    uint256 lastClaimTime;
    uint256 rewardsClaimed;
  }
}

interface IUniswapV2Router01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

interface ISamuraiLottery {
  function playTaxFree(uint256 seed, address player) external returns (bool);
}

contract HonourNodes is
  Initializable,
  IHonourNode,
  ERC721EnumerableUpgradeable,
  OwnableUpgradeable,
  PausableUpgradeable,
  ReentrancyGuardUpgradeable
{
  using SafeMathUpgradeable for uint256;
  using StringsUpgradeable for *;

  uint256 public nodeCap;
  uint256 public minted;
  uint256 public bukeMinted;
  uint256 public mononofuMinted;
  uint256 public mushaMinted;
  uint256 public totalRewardsStaked;

  string public rpcURI;
  string public baseURI;
  string public baseExtension;

  IHonour public HNR;
  IUniswapV2Router02 public uniswapV2Router;
  address public distributionPool;
  address public futurePool;
  bool public swapLiquify;
  uint256 public claimFee;

  mapping(uint256 => HonourNode) public nodeTraits;
  mapping(NodeType => HonourNodeState) public nodeInfo;

  uint256 public timestamp;
  bool public isClaimEnabled;
  ISamuraiLottery public samuraiLottery;
  uint256 public lotteryEntry;

  event PaymentReceived(address from, uint256 amount);
  event HNRTokenAddressChanged(address from, address to);
  event UniswapRouterChanged(address from, address to);
  event DistributionPoolChanged(address from, address to);
  event FuturePoolChanged(address from, address to);

  function initialize(
    address _hnr,
    address _distributionPool,
    address _futurePool,
    address _uniswapV2Router,
    string memory _setBaseURI,
    string memory _rpcURI
  ) public initializer {
    __ERC721_init("Honour Nodes", "HONOUR");
    OwnableUpgradeable.__Ownable_init();
    PausableUpgradeable.__Pausable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    nodeCap = 200_000;
    minted = 0;
    bukeMinted = 0;
    mononofuMinted = 0;
    mushaMinted = 0;

    rpcURI = _rpcURI;
    baseURI = _setBaseURI;
    baseExtension = ".json";

    HNR = IHonour(_hnr);
    distributionPool = _distributionPool;
    futurePool = _futurePool;
    claimFee = 10;
    swapLiquify = true;
    uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);

    nodeInfo[NodeType.BUKE] = HonourNodeState("BUKE", 17500000000000000);
    nodeInfo[NodeType.MONONOFU] = HonourNodeState(
      "MONONOFU",
      140000000000000000
    );
    nodeInfo[NodeType.MUSHA] = HonourNodeState("MUSHA", 525000000000000000);
  }

  receive() external payable virtual {
    emit PaymentReceived(_msgSender(), msg.value);
  }

  function mintBuke(uint256 amount, string memory name)
    external
    onlyOwner
    whenNotPaused
  {
    require(minted + amount <= nodeCap, "Node Amount Exceeded");

    for (uint256 i = 0; i < amount; i++) {
      minted++;
      bukeMinted++;
      uint256 mintTimestamp = block.timestamp;
      nodeTraits[minted] = HonourNode(
        NodeType.BUKE,
        resolveName(name, minted),
        resolveRPC("ftm", minted),
        resolveRPC("avax", minted),
        resolveRPC("matic", minted),
        mintTimestamp,
        mintTimestamp
      );
      _safeMint(_msgSender(), minted);
    }
  }

  function mintMononofu(uint256 amount, string memory name)
    external
    onlyOwner
    whenNotPaused
  {
    require(minted + amount <= nodeCap, "Node Amount Exceeded");

    for (uint256 i = 0; i < amount; i++) {
      minted++;
      mononofuMinted++;
      uint256 mintTimestamp = block.timestamp;
      nodeTraits[minted] = HonourNode(
        NodeType.MONONOFU,
        resolveName(name, minted),
        resolveRPC("ftm", minted),
        resolveRPC("avax", minted),
        resolveRPC("matic", minted),
        mintTimestamp,
        mintTimestamp
      );
      _safeMint(_msgSender(), minted);
    }
  }

  function mintMusha(uint256 amount, string memory name)
    external
    onlyOwner
    whenNotPaused
  {
    require(minted + amount <= nodeCap, "Node Amount Exceeded");

    for (uint256 i = 0; i < amount; i++) {
      minted++;
      mushaMinted++;
      uint256 mintTimestamp = block.timestamp;
      nodeTraits[minted] = HonourNode(
        NodeType.MUSHA,
        resolveName(name, minted),
        resolveRPC("ftm", minted),
        resolveRPC("avax", minted),
        resolveRPC("matic", minted),
        mintTimestamp,
        mintTimestamp
      );
      _safeMint(_msgSender(), minted);
    }
  }

  function batchTransfer(address recipient, uint256[] calldata tokenIds)
    external
  {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      transferFrom(_msgSender(), recipient, tokenIds[i]);
    }
  }

  function _batchTransfer(address recipient, uint256[] memory tokenIds)
    private
  {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      transferFrom(_msgSender(), recipient, tokenIds[i]);
    }
  }

  function resolveRPC(string memory chain, uint256 tokenId)
    internal
    view
    returns (string memory)
  {
    return string(abi.encodePacked(rpcURI, chain, "/nft/", tokenId.toString()));
  }

  function resolveName(string memory name, uint256 tokenId)
    internal
    view
    returns (string memory)
  {
    return string(abi.encodePacked(name, " #", tokenId.toString()));
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(tokenId), "ERC721: Nonexistent token");

    HonourNode memory _node = nodeTraits[tokenId];
    string memory currentBaseURI = _baseURI();

    return
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(
            currentBaseURI,
            nodeInfo[_node.tier].tier,
            "/",
            tokenId.toString(),
            baseExtension
          )
        )
        : "";
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function getTierRewardRate(NodeType tier) external view returns (uint256) {
    if (tier == NodeType.BUKE) {
      return nodeInfo[NodeType.BUKE].rewardsRate;
    } else if (tier == NodeType.MONONOFU) {
      return nodeInfo[NodeType.MONONOFU].rewardsRate;
    } else {
      return nodeInfo[NodeType.MUSHA].rewardsRate;
    }
  }

  function getNodeTrait(uint256 tokenId)
    external
    view
    returns (HonourNode memory)
  {
    require(_exists(tokenId), "HonourNode: nonexistent token");
    return nodeTraits[tokenId];
  }

  function calculateDynamicRewards(uint256 tokenId)
    public
    view
    returns (uint256)
  {
    require(_exists(tokenId), "HonourNode: nonexistent token");
    HonourNode memory nodeTrait = nodeTraits[tokenId];
    return (((block.timestamp - nodeTrait.lastClaimTime) *
      nodeInfo[nodeTrait.tier].rewardsRate) / 86400);
  }

  function calculateDynamicRewards(uint256 lastClaimTime, NodeType tier)
    private
    view
    returns (uint256)
  {
    return (((block.timestamp - lastClaimTime) * nodeInfo[tier].rewardsRate) /
      86400);
  }

  function calculateTotalDynamicRewards(uint256[] calldata tokenIds)
    external
    view
    returns (uint256)
  {
    uint256 totalRewards = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      totalRewards += calculateDynamicRewards(tokenIds[i]);
    }
    return totalRewards;
  }

  function syncNodeReward(uint256 tokenId) private returns (uint256) {
    uint256 blocktime = block.timestamp;
    HonourNode storage nodeTrait = nodeTraits[tokenId];
    if (nodeTrait.lastClaimTime < timestamp) {
      nodeTrait.lastClaimTime = blocktime;
      nodeTrait.rewardsClaimed = 0;
      return (0);
    }
    uint256 calculatedRewards = calculateDynamicRewards(
      nodeTrait.lastClaimTime,
      nodeTrait.tier
    );

    nodeTrait.lastClaimTime = blocktime;
    nodeTrait.rewardsClaimed += calculatedRewards;
    totalRewardsStaked += calculatedRewards;
    return (calculatedRewards);
  }

  function claimRewards(uint256 tokenId) external nonReentrant {
    require(isClaimEnabled, "HonourNode: Claims are not enabled");
    require(_exists(tokenId), "HonourNode: nonexistent token");
    address sender = _msgSender();
    require(sender == ownerOf(tokenId), "HonourNode: Not an NFT owner");
    require(sender != address(0));
    uint256 taxRate = calculateSlidingTaxRate(tokenId);
    uint256 rewardAmount = syncNodeReward(tokenId);
    if (rewardAmount > 0) {
      uint256 feeAmount = rewardAmount.mul(taxRate).div(100);
      if (swapLiquify && feeAmount > 0) {
        swapAndSendToFee(futurePool, feeAmount);
      }

      rewardAmount -= feeAmount;
      HNR.approve(address(distributionPool), rewardAmount);
      HNR.transferFrom(distributionPool, sender, rewardAmount);
    }
  }

  function claimAllRewards(uint256[] memory tokenIds) external nonReentrant {
    require(isClaimEnabled, "HonourNode: Claims are not enabled");
    require(tokenIds.length > 0, "HonourNode: no tokens to redeem");
    address sender = _msgSender();
    uint256 rewardAmount = 0;
    uint256 feeAmount = 0;
    require(sender != address(0));
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      if (_exists(tokenId) && (sender == ownerOf(tokenId))) {
        uint256 taxRate = calculateSlidingTaxRate(tokenId);
        uint256 nodeRewardAmount = syncNodeReward(tokenId);
        rewardAmount += nodeRewardAmount;
        feeAmount += nodeRewardAmount.mul(taxRate).div(100);
      }
    }
    if (rewardAmount > 0) {
      if (swapLiquify && feeAmount > 0) {
        swapAndSendToFee(futurePool, feeAmount);
      }

      rewardAmount -= feeAmount;
      HNR.approve(address(distributionPool), rewardAmount);
      HNR.transferFrom(distributionPool, sender, rewardAmount);
    }
  }

  function calculateSlidingTaxRate(uint256 tokenId)
    public
    view
    returns (uint256)
  {
    uint256 blocktime = block.timestamp;
    HonourNode storage nodeTrait = nodeTraits[tokenId];
    uint256 numDays = (blocktime - nodeTrait.lastClaimTime).div(86400);
    if (numDays < 7) {
      return 50;
    } else if (numDays < 14) {
      return 40;
    } else if (numDays < 21) {
      return 30;
    } else if (numDays < 28) {
      return 20;
    } else {
      if (nodeTrait.tier == NodeType.BUKE) {
        return 5;
      } else if (nodeTrait.tier == NodeType.MONONOFU) {
        return 8;
      } else {
        return 10;
      }
    }
  }

  function playTaxFree(uint256 seed, uint256[] memory tokenIds)
    external
    whenNotPaused
    nonReentrant
    returns (bool)
  {
    address player = _msgSender();
    require(tokenIds.length > 0);
    require(player != address(0));
    require(this.balanceOf(player) >= 1);

    uint256 unclaimedBalance = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      require(_exists(tokenId));
      require(player == ownerOf(tokenId));
      unclaimedBalance += calculateDynamicRewards(tokenId);
      if (unclaimedBalance >= lotteryEntry) {
        break;
      }
    }

    require(unclaimedBalance >= lotteryEntry);

    uint256 accumulator = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      uint256 tokenRewards = calculateDynamicRewards(tokenId);
      if (accumulator == lotteryEntry) {
        break;
      } else if (accumulator + tokenRewards < lotteryEntry) {
        accumulator += syncNodeReward(tokenId);
      } else {
        uint256 leftOver = lotteryEntry - accumulator;
        if (leftOver > 0) {
          HonourNode storage nodeTrait = nodeTraits[tokenId];
          uint256 timeDifference = ((leftOver * 86400) /
            nodeInfo[nodeTrait.tier].rewardsRate);
          nodeTrait.lastClaimTime += timeDifference;
          nodeTrait.rewardsClaimed += leftOver;
          totalRewardsStaked += leftOver;
          accumulator += leftOver;
        } else if (leftOver == 0) {
          break;
        }
      }
    }

    return samuraiLottery.playTaxFree(seed, player);
  }

  function debugTaxFee(uint256[] calldata tokenIds)
    external
    view
    returns (uint256)
  {
    uint256 rewardAmount = 0;
    uint256 feeAmount = 0;

    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      if (_exists(tokenId)) {
        HonourNode storage nodeTrait = nodeTraits[tokenId];
        uint256 nodeRewardAmount = calculateDynamicRewards(
          nodeTrait.lastClaimTime,
          nodeTrait.tier
        );
        rewardAmount += nodeRewardAmount;
        uint256 taxRate = calculateSlidingTaxRate(tokenId);
        feeAmount += nodeRewardAmount.mul(taxRate).div(100);
      }
    }

    rewardAmount -= feeAmount;
    return (rewardAmount);
  }

  function swapAndSendToFee(address destination, uint256 tokens) private {
    uint256 initialETHBalance = address(this).balance;

    swapTokensForEth(tokens);
    uint256 newBalance = (address(this).balance).sub(initialETHBalance);
    payable(destination).transfer(newBalance);
  }

  function swapTokensForEth(uint256 tokenAmount) private {
    address[] memory path = new address[](2);
    path[0] = address(HNR);
    path[1] = uniswapV2Router.WETH();

    HNR.approve(address(uniswapV2Router), tokenAmount);

    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0,
      path,
      address(this),
      block.timestamp
    );
  }

  function release(address _receiver) external onlyOwner {
    payable(_receiver).transfer(address(this).balance);
  }

  function releaseToken(address _tokenAddress, uint256 _amountTokens)
    external
    onlyOwner
    returns (bool success)
  {
    return IERC20(_tokenAddress).transfer(msg.sender, _amountTokens);
  }

  function setPause(bool _pauseState) external onlyOwner {
    _pauseState ? _pause() : _unpause();
  }

  function setBukeRewardRate(uint256 rate) external onlyOwner {
    HonourNodeState storage bukeNode = nodeInfo[NodeType.BUKE];
    bukeNode.rewardsRate = rate;
  }

  function setMononofuRewardRate(uint256 rate) external onlyOwner {
    HonourNodeState storage mononofuNode = nodeInfo[NodeType.MONONOFU];
    mononofuNode.rewardsRate = rate;
  }

  function setMushaRewardRate(uint256 rate) external onlyOwner {
    HonourNodeState storage mushaNode = nodeInfo[NodeType.MUSHA];
    mushaNode.rewardsRate = rate;
  }

  function setURIForRPC(string memory uri) external onlyOwner {
    rpcURI = uri;
  }

  function setURIForBase(string memory uri) external onlyOwner {
    baseURI = uri;
  }

  function setFileTypeForExtension(string memory extension) external onlyOwner {
    baseExtension = extension;
  }

  function setHNR(address _hnr) external onlyOwner {
    emit HNRTokenAddressChanged(address(HNR), _hnr);
    HNR = IHonour(_hnr);
  }

  function setUniswap(address _uniswap) external onlyOwner {
    emit UniswapRouterChanged(address(uniswapV2Router), _uniswap);
    uniswapV2Router = IUniswapV2Router02(_uniswap);
  }

  function setDistributionPool(address _distributionPool) external onlyOwner {
    emit DistributionPoolChanged(distributionPool, _distributionPool);
    distributionPool = _distributionPool;
  }

  function setFuturePool(address _futurePool) external onlyOwner {
    emit FuturePoolChanged(futurePool, _futurePool);
    futurePool = _futurePool;
  }

  function setSwapLiquify(bool swapState) external onlyOwner {
    swapLiquify = swapState;
  }

  function setClaimFee(uint256 _fee) external onlyOwner {
    claimFee = _fee;
  }

  function setNodeCap(uint256 _cap) external onlyOwner {
    nodeCap = _cap;
  }

  function setTimestamp() external onlyOwner {
    timestamp = block.timestamp;
  }

  function setIsClaimEnabled(bool _isEnabled) external onlyOwner {
    isClaimEnabled = _isEnabled;
  }

  function debug(uint256 tokenId, uint256 blocktime) external onlyOwner {
    HonourNode storage nodeTrait = nodeTraits[tokenId];
    nodeTrait.lastClaimTime = blocktime;
  }

  function getBlocktime() external view returns (uint256) {
    return block.timestamp;
  }

  function setSamuraiLottery(address _lottery) external onlyOwner {
    samuraiLottery = ISamuraiLottery(_lottery);
  }

  function setLotteryEntry(uint256 _lotteryEntry) external onlyOwner {
    lotteryEntry = _lotteryEntry * 10**18;
  }
}