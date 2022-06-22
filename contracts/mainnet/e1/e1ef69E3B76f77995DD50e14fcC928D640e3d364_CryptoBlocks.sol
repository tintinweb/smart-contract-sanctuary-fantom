// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "../token/ERC2981/IERC2981.sol";
import "../access/RoleAccessControlUpgradeableV1.sol";
import "./lib/CryptoBlock.sol";
import "./ICryptoBlocks.sol";
import "./ICryptoBlocksAttributes.sol";
import "./ICryptoBlocksCrossChain.sol";
import "./ICryptoBlocksBridge.sol";

/** @title CryptoBlocks */
contract CryptoBlocks is Initializable, RoleAccessControlUpgradeableV1, ERC721EnumerableUpgradeable, PausableUpgradeable, UUPSUpgradeable, IERC2981, ICryptoBlocksAttributes, ICryptoBlocksCrossChain, ICryptoBlocksBridge, ICryptoBlocks {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;
    CountersUpgradeable.Counter private _tokenIdCounter;                        // id for this chain. Will be incremented with bridged tokens
    CountersUpgradeable.Counter private _masterIdCounter;                       // master id for this chain. Will not be incremented with bridged tokens
    mapping(uint256 => string) private _tokenURIs;                              // Optional mapping for token URIs
    mapping(uint256 => CryptoBlock.Block) private _blocks;                      // deprecated - tokenId => Block
    mapping(uint256 => mapping(uint256 => uint256)) _attributes;                // tokenId => attributeId => attributeValue
    mapping(uint256 => mapping(uint256 => string))  _attributesString;          // tokenId => attributeId => attributeString
    mapping(uint256 => mapping(uint256 => address)) _attributesAddress;         // tokenId => attributeId => attributeAddress
    mapping(uint256 => mapping(uint256 => uint256)) _masterMapping;             // chainId => masterId => tokenId
    mapping(uint256 => bool) _supportedChains;                                  // deprecated - supported chains for bridging
    mapping(address => uint256) _lastBuyBlockHeight;                            // deprecated - lastBuyBlockHeight for account
    mapping(address => bool) _blacklist;                                        // deprecated
    address private _dividendsReceiver;                                         // contract for dividends to receive minting fees
    address private _royaltyReceiver;                                           // address for receiver for royalties
    address private _bridgeAddress;                                             // deprecated - address for bridge
    uint256 private _chainId;                                                   // deprecated
    uint256 public maxSupply;
    uint256 public price;
    uint256 private _priceMax;
    uint256 private _priceIncrease;                                             // price increase percent per buy / 1000. ex: 1 = 0.001%
    uint256 private _amountPerTx;                                               // amount limit per buy
    uint256 private _coolDownPerBuy;                                            // coolDown between buys
    uint256 private _dividendsAmount;                                           // dividends amount to holders for mints / 1000. ex: 1 = 0.001%
    uint256 private _royaltyAmount;                                             // royalty percent of sale price / 1000. ex: 1 = 0.001%
    string public baseURI;
    mapping(uint256 => mapping(uint256 => uint256[])) _attributesArray;         // tokenId => attributeId => attributeArray
    mapping(uint256 => mapping(uint256 => bytes32[])) _attributesBytes;         // tokenId => attributeId => attributeBytes
    mapping(uint256 => mapping(address => uint256)) internal _tokenAddressData; // tokenId => address => data
    mapping(uint256 => mapping(address => uint256)) internal _addressData;      // id => address => data
    mapping(uint256 => address) internal _addressMapping;                       // id => stores contract addresses
    mapping(uint256 => uint256) internal _uintMapping;                          // id => uint256 value

    function initialize() initializer public {
        __RoleAccessControl_init_unchained();
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained("FantomBlocks", "FTMBLOCK");
        __ERC721Enumerable_init_unchained();
        __Pausable_init_unchained();
        __UUPSUpgradeable_init();
        __CryptoBlocks_init_unchained();
    }

    function __CryptoBlocks_init_unchained() internal initializer {
        _setupRole(ADMINS, _msgSender());
        maxSupply = 120;
        price = 550 * 1 ether;
        _priceMax = 1000 * 1 ether;
        _priceIncrease = 0;
        _amountPerTx = 3;
        _coolDownPerBuy = 50;
        _dividendsAmount = 0;
        _royaltyAmount = 50;
        _dividendsReceiver = _msgSender();
        _royaltyReceiver = _msgSender();
        _chainId = block.chainid;
    }

    function _authorizeUpgrade(address) internal override onlyRole(ADMINS) {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721EnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId) ||
        interfaceId == type(IERC2981).interfaceId ||
        interfaceId == type(ICryptoBlocksAttributes).interfaceId ||
        interfaceId == type(ICryptoBlocksCrossChain).interfaceId ||
        interfaceId == type(ICryptoBlocks).interfaceId;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        uint256 originChainId = _blocks[tokenId].originChainId;
        uint256 masterId = _blocks[tokenId].masterId;

        return bytes(base).length > 0 ? string(abi.encodePacked(base, originChainId.toString(), "/", masterId.toString())) : "";
    }

    function setTokenURI(uint256 tokenId_, string memory tokenURI_) public onlyRole(ADMINS) {
        require(_exists(tokenId_), "URI set of nonexistent token");
        _tokenURIs[tokenId_] = tokenURI_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function burn(uint256 tokenId) public onlyRole(OPERATORS) {
        _burn(tokenId);
    }

    function _burn(uint256 tokenId) internal override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    function pause() public onlyRole(ADMINS) {
        _pause();
    }

    function unpause() public onlyRole(ADMINS) {
        _unpause();
    }

    function withdraw() public onlyRole(ADMINS) {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function setBaseURI(string memory uri_) public onlyRole(ADMINS) {
        baseURI = uri_;
    }

    function setMaxSupply(uint256 maxSupply_) public onlyRole(ADMINS) {
        maxSupply = maxSupply_;
    }

    function setPrice(uint256 price_) public onlyRole(ADMINS) {
        price = price_;
    }

    function setPriceMax(uint256 priceMax_) public onlyRole(ADMINS) {
        _priceMax = priceMax_;
    }

    function getPriceMax() public view returns(uint256) {
        return _priceMax;
    }

    function setPriceIncrease(uint256 priceIncrease_) public onlyRole(ADMINS) {
        _priceIncrease = priceIncrease_;
    }

    function getPriceIncrease() public view returns(uint256) {
        return _priceIncrease;
    }

    function setAmountPerTx(uint256 amountPerTx_) public onlyRole(ADMINS) {
        _amountPerTx = amountPerTx_;
    }

    function getAmountPerTx() public view returns(uint256) {
        return _amountPerTx;
    }

    function setCoolDownPerBuy(uint256 coolDownPerBuy_) public onlyRole(ADMINS) {
        _coolDownPerBuy = coolDownPerBuy_;
    }

    function getCoolDownPerBuy() public view returns(uint256) {
        return _coolDownPerBuy;
    }

    function setLastBuyBlockHeight(address account_, uint256 lastBuyBlockHeight_) public onlyRole(ADMINS) {
        _lastBuyBlockHeight[account_] = lastBuyBlockHeight_;
    }

    function getLastBuyBlockHeight(address account_) public view returns(uint256) {
        return _lastBuyBlockHeight[account_];
    }

    function blacklistAddress(address account_) public onlyRole(ADMINS) {
        _blacklist[account_] = true;
    }

    function whitelistAddress(address account_) public onlyRole(ADMINS) {
        _blacklist[account_] = false;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Mint within maxSupply
     */
    function safeMint(address to_) internal {
        require(totalSupply() <= maxSupply, "Insufficient supply");
        _internalMint(to_);
    }

    /**
     * @dev Mint without paying fee
     */
    function freeMint(address to_, uint256 amount_) public onlyRole(MINTERS) {
        for(uint256 i = 0; i < amount_; i++) {
            safeMint(to_);
        }
    }

    /**
     * @dev Mint while increasing maxSupply
     */
    function extraMint(address to_, uint256 amount_) public onlyRole(MINTERS) {
        for(uint256 i = 0; i < amount_; i++) {
            _internalMint(to_);
            maxSupply++;
        }
    }

    function _internalMint(address to_) internal {
        _safeMint(to_, _tokenIdCounter.current());
        CryptoBlock.Block memory block_;
        block_.id = _tokenIdCounter.current();
        block_.chainId = getChainId();
        block_.originChainId = getChainId();
        block_.masterId = _masterIdCounter.current();
        // check for preexisting data
        if(_blocks[block_.id].categoryId != 0) {
            block_.categoryId = _blocks[block_.id].categoryId;
        }
        if(_blocks[block_.id].subcategoryId != 0) {
            block_.subcategoryId = _blocks[block_.id].subcategoryId;
        }
        _blocks[_tokenIdCounter.current()] = block_;
        _masterMapping[getChainId()][block_.masterId] = block_.id;
        _tokenIdCounter.increment();
        _masterIdCounter.increment();
        // set attributeAddressId 1 to original minter
        _attributesAddress[block_.id][1] = to_;
        emit SetBlockAttributeAddress(block_.id, 1, to_);
    }

    function buy(uint256 amount_) public payable whenNotPaused {
        require(msg.value >= price * amount_, "Insufficient fee paid");
        require(amount_ <= _amountPerTx, "Amount exceeded");
        require(block.number - _lastBuyBlockHeight[_msgSender()] >= _coolDownPerBuy, "CoolDown not met");
        require(!_blacklist[_msgSender()], "Blacklisted");
        for (uint256 i = 0; i < amount_; i++) {
            safeMint(_msgSender());
            price += (price * _priceIncrease) / 1000;
            if(price > _priceMax) {
                price = _priceMax;
            }
        }
        _lastBuyBlockHeight[_msgSender()] = block.number;

        // pay dividends
        uint256 dividends = (msg.value * _dividendsAmount) / 1000;
        if(dividends > 0) {
            payable(_dividendsReceiver).transfer(dividends);
        }
    }

    function royaltyInfo(uint256 tokenId_, uint256 salePrice_) public override view returns (address receiver, uint256 royaltyAmount) {
        uint256 royaltyOwed_ = (salePrice_ * _royaltyAmount) / 1000;
        return(_royaltyReceiver, royaltyOwed_);
    }

    function setRoyaltyAmount(uint256 royaltyAmount_) public onlyRole(ADMINS) {
        _royaltyAmount = royaltyAmount_;
    }

    function getRoyaltyAmount() public view returns(uint256) {
        return _royaltyAmount;
    }

    function setRoyaltyReceiver(address royaltyReceiver_) public onlyRole(ADMINS) {
        _royaltyReceiver = royaltyReceiver_;
    }

    function getRoyaltyReceiver() public view returns(address) {
        return _royaltyReceiver;
    }

    function setDividendsReceiver(address dividendsReceiver_) public onlyRole(ADMINS) {
        _dividendsReceiver = dividendsReceiver_;
    }

    function getDividendsReceiver() public view returns(address) {
        return _dividendsReceiver;
    }

    function setDividendsAmount(uint256 dividendsAmount_) public onlyRole(ADMINS) {
        _dividendsAmount = dividendsAmount_;
    }

    function getDividendsAmount() public view returns(uint256) {
        return _dividendsAmount;
    }

    /**
     * @dev Set block properties
     */
    function setBlock(uint256 id_, CryptoBlock.Block memory block_) public onlyRole(OPERATORS) {
        if(_blocks[id_].categoryId != block_.categoryId) {
            _blocks[id_].categoryId = block_.categoryId;
        }
        if(_blocks[id_].subcategoryId != block_.subcategoryId) {
            _blocks[id_].subcategoryId = block_.subcategoryId;
        }
        if(_blocks[id_].chainId != block_.chainId) {
            _blocks[id_].chainId = block_.chainId;
        }
        if(_blocks[id_].originChainId != block_.originChainId) {
            _blocks[id_].originChainId = block_.originChainId;
        }
        if(_blocks[id_].masterId != block_.masterId) {
            _blocks[id_].masterId = block_.masterId;
        }
        if(_blocks[id_].locked != block_.locked) {
            _blocks[id_].locked = block_.locked;
        }
    }

    /**
     * @dev Set block category properties
     */
    function setBlockCategory(uint256 id_, uint32 categoryId_, uint32 subcategoryId_) public onlyRole(OPERATORS) {
        if(_blocks[id_].categoryId != categoryId_) {
            _blocks[id_].categoryId = categoryId_;
        }
        if(_blocks[id_].subcategoryId != subcategoryId_) {
            _blocks[id_].subcategoryId = subcategoryId_;
        }
    }

    /**
     * @dev Set specific attribute of block
     */
    function setBlockAttribute(uint256 id_, uint256 attributeId_, uint256 attributeValue_) public override onlyRole(OPERATORS) {
        _attributes[id_][attributeId_] = attributeValue_;
        emit SetBlockAttribute(id_, attributeId_, attributeValue_);
    }

    /**
     * @dev Set specific attribute of block
     */
    function setBlockAttributeString(uint256 id_, uint256 attributeId_, string memory attributeValue_) public override onlyRole(OPERATORS) {
        _attributesString[id_][attributeId_] = attributeValue_;
        emit SetBlockAttributeString(id_, attributeId_, attributeValue_);
    }

    /**
     * @dev Set specific attributeAddress of block
     */
    function setBlockAttributeAddress(uint256 id_, uint256 attributeId_, address attributeAddressValue_) public override onlyRole(OPERATORS) {
        _attributesAddress[id_][attributeId_] = attributeAddressValue_;
        emit SetBlockAttributeAddress(id_, attributeId_, attributeAddressValue_);
    }

    /**
     * @dev Set specific attributeArray of block
     */
    function setBlockAttributeArray(uint256 id_, uint256 attributeId_, uint256[] memory attributeArrayValue_) public override onlyRole(OPERATORS) {
        _attributesArray[id_][attributeId_] = attributeArrayValue_;
        emit SetBlockAttributeArray(id_, attributeId_, attributeArrayValue_);
    }

    /**
     * @dev Set specific attributeBytes of block
     */
    function setBlockAttributeBytes(uint256 id_, uint256 attributeId_, bytes32[] memory attributeBytesValue_) public override onlyRole(OPERATORS) {
        _attributesBytes[id_][attributeId_] = attributeBytesValue_;
        emit SetBlockAttributeBytes(id_, attributeId_, attributeBytesValue_);
    }

    /**
  * @dev Set specific data for addresses of block
  */
    function setBlockTokenAddressData(uint256 id_, address address_, uint256 data_) public virtual override onlyRole(OPERATORS) {
        _tokenAddressData[id_][address_] = data_;
        emit SetBlockTokenAddressData(id_, address_, data_);
    }

    /**
     * @dev Set specific data for addresses of id
     */
    function setBlockAddressData(uint256 id_, address address_, uint256 data_) public virtual override onlyRole(OPERATORS) {
        _addressData[id_][address_] = data_;
        emit SetBlockAddressData(id_, address_, data_);
    }

    /**
     * @dev Set specific addresses of id such as contract addresses
     */
    function setBlockAddressMapping(uint256 id_, address address_) public virtual override onlyRole(OPERATORS) {
        _addressMapping[id_] = address_;
        emit SetBlockAddressMapping(id_, address_);
    }

    /**
     * @dev Set specific uint of id such as royalty amount or chainId
     */
    function setBlockUintMapping(uint256 id_, uint256 value_) public virtual override onlyRole(OPERATORS) {
        _uintMapping[id_] = value_;
        emit SetBlockUintMapping(id_, value_);
    }

    function getBlock(uint256 id_) public view returns(CryptoBlock.Block memory) {
        return _blocks[id_];
    }

    function getBlockAttribute(uint256 id_, uint256 attributeId_) public override view returns(uint256) {
        return _attributes[id_][attributeId_];
    }

    function getBlockAttributeString(uint256 id_, uint256 attributeId_) public override view returns(string memory) {
        return _attributesString[id_][attributeId_];
    }

    function getBlockAttributeAddress(uint256 id_, uint256 attributeId_) public override view returns(address) {
        return _attributesAddress[id_][attributeId_];
    }

    function getBlockAttributeArray(uint256 id_, uint256 attributeId_) public override view returns(uint256[] memory) {
        return _attributesArray[id_][attributeId_];
    }

    function getBlockAttributeBytes(uint256 id_, uint256 attributeId_) public override view returns(bytes32[] memory) {
        return _attributesBytes[id_][attributeId_];
    }

    function getBlockTokenAddressData(uint256 id_, address address_) public virtual override view returns(uint256) {
        return _tokenAddressData[id_][address_];
    }

    function getBlockAddressData(uint256 id_, address address_) public virtual override view returns(uint256) {
        return _addressData[id_][address_];
    }

    function getBlockAddressMapping(uint256 id_) public virtual override view returns(address) {
        return _addressMapping[id_];
    }

    function getBlockUintMapping(uint256 id_) public virtual override view returns(uint256) {
        return _uintMapping[id_];
    }

    /**
     * @dev Get tokenId of this chain from masterId
     */
    function getMasterMappingTokenId(uint256 chainId_, uint256 masterId_) public override view returns(uint256) {
        return _masterMapping[chainId_][masterId_];
    }

    function addSupportedChain(uint256 chainId_) public onlyRole(ADMINS) {
        _supportedChains[chainId_] = true;
    }

    function removeSupportedChain(uint256 chainId_) public onlyRole(ADMINS) {
        _supportedChains[chainId_] = false;
    }

    function setBridgeAddress(address bridgeAddress_) public onlyRole(ADMINS) {
        _bridgeAddress = bridgeAddress_;
    }

    function getBridgeAddress() public view override returns(address) {
        return _bridgeAddress;
    }

    /**
     * @dev Send token to bridge
     */
    function bridgeTransferOut(address from_, uint256 tokenId_, uint256 targetChainId_) public override onlyRole(OPERATORS) {
        require(ownerOf(tokenId_) != _bridgeAddress, "Exists in bridge");
        require(!_blocks[tokenId_].locked, "Locked");
        require(_supportedChains[targetChainId_] = true, "Chain not supported");
        require(!_blacklist[from_], "Blacklisted");

        _blocks[tokenId_].locked = true;
        _blocks[tokenId_].chainId = targetChainId_;
        safeTransferFrom(from_, _bridgeAddress, tokenId_);
        emit BridgeTransferOut(from_, tokenId_, targetChainId_);
    }

    /**
     * @dev Bridge called by server sends or mints the token
     * server has to set all attributes within same transaction
     * returns tokenId so server can use it to set attributes
     */
    function bridgeTransferIn(address to_, CryptoBlock.Block memory block_) public override onlyRole(MINTERS) returns(uint256) {
        require(!_blacklist[to_], "Blacklisted");

        // check if block exist if not create it
        uint256 tokenId_ = _masterMapping[block_.originChainId][block_.masterId];
        if(ownerOf(tokenId_) == _bridgeAddress && _blocks[tokenId_].chainId != 0) {
            // block exist so just transfer
            _safeTransfer(_bridgeAddress, to_, tokenId_, "");
            // set variables assuming bridge provides valid data
            _blocks[tokenId_] = block_;
            _blocks[tokenId_].id = tokenId_;
            _blocks[tokenId_].locked = false;
        } else {
            // block doesn't exist on this chain so create it
            _safeMint(to_, _tokenIdCounter.current());
            block_.id = _tokenIdCounter.current();
            block_.locked = false;

            _blocks[_tokenIdCounter.current()] = block_;
            _masterMapping[block_.originChainId][block_.masterId] = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            tokenId_ = block_.id;
        }
        emit BridgeTransferIn(to_, tokenId_, getChainId());
        return tokenId_;
    }

    function setChainId(uint256 chainId_) public onlyRole(ADMINS) {
        _chainId = chainId_;
    }

    function getChainId() public view returns (uint256) {
        return _chainId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC2981 {

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library CryptoBlock {
    struct Block {
        uint256 id;
        uint256 chainId;        // current chainId
        uint256 originChainId;  // chainId originated
        uint256 masterId;       // masterTokenId
        uint32 categoryId;      // unused
        uint32 subcategoryId;   // unused
        bool locked;            // unused. locked for bridge
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface ICryptoBlocksCrossChain {
    function getMasterMappingTokenId(uint256, uint256) external view returns(uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./lib/CryptoBlock.sol";

interface ICryptoBlocksBridge {
    function getBridgeAddress() external view returns(address);
    function bridgeTransferOut(address, uint256, uint256) external;
    function bridgeTransferIn(address, CryptoBlock.Block memory) external returns(uint256);

    event BridgeTransferOut(address indexed from, uint256 indexed tokenId, uint256 targetChainId);
    event BridgeTransferIn(address indexed to, uint256 indexed tokenId, uint256 targetChainId);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface ICryptoBlocksAttributes {
    function setBlockAttribute(uint256, uint256, uint256) external;
    function setBlockAttributeString(uint256, uint256, string calldata) external;
    function setBlockAttributeAddress(uint256, uint256, address) external;
    function setBlockAttributeArray(uint256, uint256, uint256[] calldata) external;
    function setBlockAttributeBytes(uint256, uint256, bytes32[] calldata) external;
    function setBlockTokenAddressData(uint256, address, uint256) external;
    function setBlockAddressData(uint256, address, uint256) external;
    function setBlockAddressMapping(uint256, address) external;
    function setBlockUintMapping(uint256, uint256) external;

    event SetBlockAttribute(uint256 indexed tokenId, uint256 indexed attributeId, uint256 attributeValue);
    event SetBlockAttributeString(uint256 indexed tokenId, uint256 indexed attributeId, string attributeStringValue);
    event SetBlockAttributeAddress(uint256 indexed tokenId, uint256 indexed attributeId, address attributeAddressValue);
    event SetBlockAttributeArray(uint256 indexed tokenId, uint256 indexed attributeId, uint256[] attributeArrayValue);
    event SetBlockAttributeBytes(uint256 indexed tokenId, uint256 indexed attributeId, bytes32[] attributeBytesValue);
    event SetBlockTokenAddressData(uint256 indexed tokenId, address indexed account, uint256 data);
    event SetBlockAddressData(uint256 indexed id, address indexed account, uint256 data);
    event SetBlockAddressMapping(uint256 indexed id, address account);
    event SetBlockUintMapping(uint256 indexed id, uint256 value);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface ICryptoBlocks {
    function getBlockAttribute(uint256, uint256) external view returns(uint256);
    function getBlockAttributeString(uint256, uint256) external view returns(string memory);
    function getBlockAttributeAddress(uint256, uint256) external view returns(address);
    function getBlockAttributeArray(uint256, uint256) external view returns(uint256[] memory);
    function getBlockAttributeBytes(uint256, uint256) external view returns(bytes32[] memory);
    function getBlockTokenAddressData(uint256, address) external view returns(uint256);
    function getBlockAddressData(uint256, address) external returns(uint256);
    function getBlockAddressMapping(uint256) external returns(address);
    function getBlockUintMapping(uint256) external returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

interface IRoleAccessControlUpgradeableV1 {
  function hasRole(uint32 role, address account) external view returns (bool);
  function grantRole(uint32 role, address account) external;
  function revokeRole(uint32 role, address account) external;
  function renounceRole(uint32 role, address account) external;
}

/**
 * @dev Access is based on hierarchy of power. Higher role number has authority over lower role number
 * ADMINS can manage OPERATORS but OPERATORS cannot manage ADMINS
 */
abstract contract RoleAccessControlUpgradeableV1 is Initializable, ContextUpgradeable, IRoleAccessControlUpgradeableV1 {
  uint32 public constant GUESTS = 0;      // Guests have no privileges
  uint32 public constant OPERATORS = 100; // Operators can use specific restricted functions of contracts
  uint32 public constant MINTERS = 500;   // Minters can mint tokens and manage operators
  uint32 public constant ADMINS = 1000;   // Admins can manage operators and minters
  event RoleGranted(uint32 indexed role, address indexed account, address indexed sender);
  event RoleRevoked(uint32 indexed role, address indexed account, address indexed send);

  struct Member {
    address account;
    uint32 role;
    bool visible;
  }
  mapping (address => Member) private _members; // stores members
  address[] private _membersList;               // for public viewing purpose

  function __RoleAccessControl_init() internal initializer {
    __Context_init_unchained();
    __RoleAccessControl_init_unchained();
  }

  function __RoleAccessControl_init_unchained() internal initializer {
    _setupRole(ADMINS, _msgSender());
  }

  /**
   * @dev Modifier that checks that an account has a specific role. Reverts
   * with a standardized message including the required role.
   */
  modifier onlyRole(uint32 role_) {
    if(!hasRole(role_,  _msgSender())) {
      revert(string(abi.encodePacked("Missing role ", StringsUpgradeable.toHexString(uint256(role_), 32))));
    }
    _;
  }

  /**
   * @dev Returns `true` if `account` has been granted `role`. or above
   */
  function hasRole(uint32 role_, address address_) public view override returns(bool) {
    if(_members[address_].role >= role_) return true;
    return false;
  }

  /**
   * @dev Required function to implement. Only called once at constructor or initializer
   */
  function _setupRole(uint32 role_, address address_) internal virtual {
    _members[address_] = Member(address_, role_, true);
    _membersList.push(address_);
  }

  function grantRole(uint32 role_, address address_) public virtual override onlyRole(OPERATORS) {
    _grantRole(role_, address_);
  }

  function _grantRole(uint32 role_, address address_) internal {

    // check if doesn't exist
    if(_members[address_].account != address_) {
      _membersList.push(address_);
    }

    require(!hasRole(role_, address_), "Account has role already");
    // grant if role <= sender _role
    require(role_ <= _members[_msgSender()].role, "Account is below required role");

    _members[address_] = Member(address_, role_, true);
    emit RoleGranted(role_, address_, _msgSender());
  }

  // Create new array of roles and assign to member
  function revokeRole(uint32 role_, address address_) public virtual override onlyRole(OPERATORS) {
    _revokeRole(role_, address_);
  }

  // Anyone can revoke their own role
  function renounceRole(uint32 role_, address address_) public virtual override {
    require(address_ == _msgSender(), "Address is not sender");
    _revokeRole(role_, address_);
  }

  function _revokeRole(uint32 role_, address address_) internal {
    require(hasRole(role_, address_), "Missing role");
    // revoke if role <= sender _role
    require(role_ <= _members[_msgSender()].role, "Account is below role");

    _members[address_].role = GUESTS;
    emit RoleRevoked(role_, address_, _msgSender());
  }

  function setMemberVisibility(address address_, bool visible_) public onlyRole(OPERATORS) {
    _members[address_].visible = visible_;
  }

  /**
   * @dev Get all members info
   */
  function getAllMembers() public view returns(Member[] memory) {
    Member[] memory members_ = new Member[](_membersList.length);
    for(uint256 i = 0; i < _membersList.length; i++) {
      if(_members[_membersList[i]].visible) {
        members_[i] = _members[_membersList[i]];
      }
    }
    return members_;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal initializer {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
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

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
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

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
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

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}