/***
 * Written by MaxFlowO2, Senior Developer and Partner of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./eip/2981/ERC2981Collection.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./access/OwnableV2.sol";
import "./access/DeveloperV2.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interface/IMAX721.sol";
import "./modules/BAYC.sol";

contract AirFryer is DAO721, ERC2981Collection, BAYC, IMAX721, ReentrancyGuard, DeveloperV2, OwnableV2 {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;
  Counters.Counter private _teamMintCounter;
  uint private mintStartID;
  uint private mintSize;
  uint private teamMintSize;
  string private base;
  bool private enableMinter;
  bool private lockedProvenance;

  event UpdatedBaseURI(string _old, string _new);
  event UpdatedMintSize(uint _old, uint _new);
  event UpdatedMintStatus(bool _old, bool _new);
  event UpdatedTeamMintSize(uint _old, uint _new);
  event UpdatedRoyalties(address newRoyaltyAddress, uint256 newPercentage);
  event ProvenanceLocked(bool _status);

  constructor() DAO721("Dilly DAO", "DD") {}

/***
 *    ███╗   ███╗██╗███╗   ██╗████████╗
 *    ████╗ ████║██║████╗  ██║╚══██╔══╝
 *    ██╔████╔██║██║██╔██╗ ██║   ██║   
 *    ██║╚██╔╝██║██║██║╚██╗██║   ██║   
 *    ██║ ╚═╝ ██║██║██║ ╚████║   ██║   
 *    ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝   
 */

  function publicMint() external nonReentrant(){
    require(lockedProvenance, "Set Providence hashes");
    require(enableMinter, "Minter not active");
    require(_tokenIdCounter.current() < mintSize, "Can not mint that many");
    _safeMint(_msgSender(), mintID());
    _tokenIdCounter.increment();
  }


  function teamMint(address _address) public onlyOwner {
    require(lockedProvenance, "Set Providence hashes");
    require(teamMintSize != 0, "Team minting not enabled");
    require(_tokenIdCounter.current() < mintSize, "Can not mint that many");
    require(_teamMintCounter.current() < teamMintSize, "Can not team mint anymore");
    _safeMint(_address, mintID());
    _tokenIdCounter.increment();
    _teamMintCounter.increment();
  }

  // @notice this shifts the _tokenIdCounter to proper mint number
  function mintID() internal view returns (uint) {
    return (mintStartID + _tokenIdCounter.current()) % mintSize;
  }

  // Function to receive ether, msg.data must be empty
  receive() external payable {}

  // Function to receive ether, msg.data is not empty
  fallback() external payable {}

  function getBalance() external view returns (uint) {
    return address(this).balance;
  }

/***
 *     ██████╗ ██╗    ██╗███╗   ██╗███████╗██████╗ 
 *    ██╔═══██╗██║    ██║████╗  ██║██╔════╝██╔══██╗
 *    ██║   ██║██║ █╗ ██║██╔██╗ ██║█████╗  ██████╔╝
 *    ██║   ██║██║███╗██║██║╚██╗██║██╔══╝  ██╔══██╗
 *    ╚██████╔╝╚███╔███╔╝██║ ╚████║███████╗██║  ██║
 *     ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝
 * This section will have all the internals set to onlyOwner
 */

  // @notice this will use internal functions to set EIP 2981
  //  found in IERC2981.sol and used by ERC2981Collections.sol
  // @param address _royaltyAddress - Address for all royalties to go to
  // @param uint256 _percentage - Precentage in whole number of comission
  //  of secondary sales
  function setRoyaltyInfo(address _royaltyAddress, uint256 _percentage) public onlyOwner {
    _setRoyalties(_royaltyAddress, _percentage);
    emit UpdatedRoyalties(_royaltyAddress, _percentage);
  }

  // @notice this will enable publicMint()
  function enableMinting() public onlyOwner {
    bool old = enableMinter;
    enableMinter = true;
    emit UpdatedMintStatus(old, enableMinter);
  }

  // @notice this will disable publicMint()
  function disableMinting() public onlyOwner {
    bool old = enableMinter;
    enableMinter = false;
    emit UpdatedMintStatus(old, enableMinter);
  }


/***
 *    ██████╗ ███████╗██╗   ██╗
 *    ██╔══██╗██╔════╝██║   ██║
 *    ██║  ██║█████╗  ██║   ██║
 *    ██║  ██║██╔══╝  ╚██╗ ██╔╝
 *    ██████╔╝███████╗ ╚████╔╝ 
 *    ╚═════╝ ╚══════╝  ╚═══╝  
 * This section will have all the internals set to onlyDev
 * also contains all overrides required for funtionality
 */

  // @notice will update _baseURI() by onlyDev role
  function setBaseURI(string memory _base) public onlyDev {
    string memory old = base;
    base = _base;
    emit UpdatedBaseURI(old, base);
  }

  // @notice will set "team minting" by onlyDev role
  function setTeamMinting(uint _amount) public onlyDev {
    uint old = teamMintSize;
    teamMintSize = _amount;
    emit UpdatedTeamMintSize(old, teamMintSize);
  }

  // @notice will set mint size by onlyDev role
  // @param uint256 _amount - set number to mint
  function setMintSize(uint256 _amount) public onlyDev {
    uint256 old = mintSize;
    mintSize = _amount;
    emit UpdatedMintSize(old, mintSize);
  }

  // @notice this will set the Provenance Hashes
  // This will also set the starting order as well!
  // Only one shot to do this, otherwise it shows as invalid
  function setProvenance(string memory _images, string memory _json) public onlyDev {
    require(!lockedProvenance, "Already Set!");
    // This is the initial setting
    _setProvenanceImages(_images);
    _setProvenanceJSON(_json);
    // Now to psuedo-random the starting number
    // Your API should be a random before this step!
    mintStartID = uint(keccak256(abi.encodePacked(block.timestamp, _msgSender(), _images, _json, block.difficulty))) % mintSize;
    _setStartNumber(mintStartID);
    // @notice Locks sequence
    lockedProvenance = true;
    emit ProvenanceLocked(lockedProvenance);
  }

  // @notice function useful for accidental ETH transfers to contract (to user address)
  // wraps _user in payable to fix address -> address payable
  // Set to onlyOwner, this is case of a foulup on PaymentSplitter or minting
  function sweepEthToAddress(address _user, uint _amount) public onlyOwner {
    payable(_user).transfer(_amount);
  }

  ///
  /// Developer, these are the overrides
  ///

  // @notice solidity required override for _baseURI()
  function _baseURI() internal view override returns (string memory) {
    return base;
  }

  // @notice solidity required override for supportsInterface(bytes4)
  function supportsInterface(bytes4 interfaceId) public view override(DAO721, IERC165) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  // @notice will return status of Minter
  function minterStatus() external view override(IMAX721) returns (bool) {
    return enableMinter;
  }

  // @notice will return minting fees
  function minterFees() external pure override(IMAX721) returns (uint) {
    return 0;
  }

  // @notice will return maximum mint capacity
  function minterMaximumCapacity() external view override(IMAX721) returns (uint) {
    return mintSize;
  }

  // @notice will return maximum "team minting" capacity
  function minterMaximumTeamMints() external view override(IMAX721) returns (uint) {
    return teamMintSize;
  }

  // @notice will return "team mints" left
  function minterTeamMintsRemaining() external view override(IMAX721) returns (uint) {
    return teamMintSize - _teamMintCounter.current();
  }

  // @notice will return "team mints" count
  function minterTeamMintsCount() external view override(IMAX721) returns (uint) {
    return _teamMintCounter.current();
  }

  // @notice will return current token count
  function totalSupply() external view override(IMAX721) returns (uint) {
    return _tokenIdCounter.current();
  }

}

/***
 *     ██████╗ ██████╗ ███╗   ██╗████████╗███████╗██╗  ██╗████████╗
 *    ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔════╝╚██╗██╔╝╚══██╔══╝
 *    ██║     ██║   ██║██╔██╗ ██║   ██║   █████╗   ╚███╔╝    ██║   
 *    ██║     ██║   ██║██║╚██╗██║   ██║   ██╔══╝   ██╔██╗    ██║   
 *    ╚██████╗╚██████╔╝██║ ╚████║   ██║   ███████╗██╔╝ ██╗   ██║   
 *     ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝   ╚═╝   
 * This is a re-write of @openzeppelin/contracts/utils/Context.sol
 * Rewritten by MaxFlowO2, Senior Developer and Partner of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 *
 * Upgraded with _msgValue() and _txOrigin() as ContextV2 on 31 Dec 2021
 */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract ContextV2 {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _msgValue() internal view virtual returns (uint) {
        return msg.value;
    }

    function _txOrigin() internal view virtual returns (address) {
        return tx.origin;
    }
}

/***
 *    ███████╗██████╗  ██████╗███████╗██████╗  ██╗
 *    ██╔════╝██╔══██╗██╔════╝╚════██║╚════██╗███║
 *    █████╗  ██████╔╝██║         ██╔╝ █████╔╝╚██║
 *    ██╔══╝  ██╔══██╗██║        ██╔╝ ██╔═══╝  ██║
 *    ███████╗██║  ██║╚██████╗   ██║  ███████╗ ██║
 *    ╚══════╝╚═╝  ╚═╝ ╚═════╝   ╚═╝  ╚══════╝ ╚═╝
 * This is a re-write of @openzeppelin/contracts/token/ERC721/ERC721.sol
 * @title DAO721 (for the 21st.DAO project)
 * @author @MaxFlowO2 (yes on Twitter/GitHub)
 *
 * Change Log:
 * Updated to ContextV2, and removed ERC165 calculations on 31 Dec 2021
 * Explicitly rewritten to have a balance of 1 total for 21st.NFT protocol
 *
 * Effected functions:
 * _mint(address,uint256) internal
 * _transfer(address,address,uint256) internal
 *
 * By modifying those two I have effectively made this holds one token ever
 * logos.
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../utils/ContextV2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */

contract DAO721 is ContextV2, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
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
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = DAO721.ownerOf(tokenId);
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
        _setApprovalForAll(_msgSender(), operator, approved);
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
        address owner = DAO721.ownerOf(tokenId);
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
     * - `to` must have 0 tokens only one per wallet
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        require(DAO721.balanceOf(to) < 1, "DAO721: Can only have one!");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
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
        address owner = DAO721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `to` must have 0 tokens only one per wallet
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(DAO721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(DAO721.balanceOf(to) < 1, "DAO721: Can only have one!");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(DAO721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

/***
 *    ██████╗  █████╗ ██╗   ██╗ ██████╗
 *    ██╔══██╗██╔══██╗╚██╗ ██╔╝██╔════╝
 *    ██████╔╝███████║ ╚████╔╝ ██║     
 *    ██╔══██╗██╔══██║  ╚██╔╝  ██║     
 *    ██████╔╝██║  ██║   ██║   ╚██████╗
 *    ╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝
 * Written by MaxFlowO2, Senior Developer and Partner of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 *
 * Purpose: Insipired by BAYC on Ethereum, Sets Provential Hashes and More
 * Source: https://etherscan.io/address/0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d#code
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../interface/IBAYC.sol";

abstract contract BAYC is IBAYC {

  // ERC165
  // RevealTimestamp() => 0x83ba7c1d
  // RevealProvenanceImages() => 0xd792d2a0
  // RevealProvenanceJSON() => 0x94352676
  // RevealStartNumber() => 0x1efb051a
  // BAYC => 0xdee68dd1

  event SetProvenanceImages(string _old, string _new);
  event SetProvenanceJSON(string _old, string _new);
  event SetTimestamp(uint _old, uint _new);
  event SetStartNumber(uint _old, uint _new);

  uint256 private timestamp;
  uint256 private startNumber;
  string private ProvenanceImages;
  string private ProvenanceJSON;

  // @notice will set reveal timestamp
  // _setRevealTimestamp(uint256) => 0x20add1a4
  function _setRevealTimestamp(uint256 _timestamp) internal {
    uint256 old = timestamp;
    timestamp = _timestamp;
    emit SetTimestamp(old, timestamp);
  }

  // @notice will set start number
  // _setStartNumber(uint256) => 0x4266377e
  function _setStartNumber(uint256 _startNumber) internal {
    uint256 old = startNumber;
    startNumber = _startNumber;
    emit SetStartNumber(old, startNumber);
  }

  // @notice will set JSON Provenance
  // _setProvenanceJSON(string) => 0xf3808eb1
  function _setProvenanceJSON(string memory _ProvenanceJSON) internal {
    string memory old = ProvenanceJSON;
    ProvenanceJSON = _ProvenanceJSON;
    emit SetProvenanceJSON(old, ProvenanceJSON);
  }

  // @notice will set Images Provenance
  // _setProvenanceImages(string) => 0x1ef799c6
  function _setProvenanceImages(string memory _ProvenanceImages) internal {
    string memory old = ProvenanceImages;
    ProvenanceImages = _ProvenanceImages;
    emit SetProvenanceImages(old, ProvenanceImages);
  }

  // @notice will return timestamp of reveal
  // RevealTimestamp() => 0x83ba7c1d
  function RevealTimestamp() external view override(IBAYC) returns (uint256) {
    return timestamp;
  }

  // @notice will return Provenance hash of images
  // RevealProvenanceImages() => 0xd792d2a0
  function RevealProvenanceImages() external view override(IBAYC) returns (string memory) {
    return ProvenanceImages;
  }

  // @notice will return Provenance hash of metadata
  // RevealProvenanceJSON() => 0x94352676
  function RevealProvenanceJSON() external view override(IBAYC) returns (string memory) {
    return ProvenanceJSON;
  }

  // @notice will return starting number for mint
  // RevealStartNumber() => 0x1efb051a
  function RevealStartNumber() external view override(IBAYC) returns (uint256) {
    return startNumber;
  }
}

/***
 *    ██╗███╗   ██╗████████╗███████╗██████╗ ███████╗ █████╗  ██████╗███████╗
 *    ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝
 *    ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝█████╗  ███████║██║     █████╗  
 *    ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██╔══╝  ██╔══██║██║     ██╔══╝  
 *    ██║██║ ╚████║   ██║   ███████╗██║  ██║██║     ██║  ██║╚██████╗███████╗
 *    ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝
 *                                                                          
 *    ███╗   ███╗ █████╗ ██╗  ██╗  ███████╗██████╗  ██╗                     
 *    ████╗ ████║██╔══██╗╚██╗██╔╝  ╚════██║╚════██╗███║                     
 *    ██╔████╔██║███████║ ╚███╔╝█████╗ ██╔╝ █████╔╝╚██║                     
 *    ██║╚██╔╝██║██╔══██║ ██╔██╗╚════╝██╔╝ ██╔═══╝  ██║                     
 *    ██║ ╚═╝ ██║██║  ██║██╔╝ ██╗     ██║  ███████╗ ██║                     
 *    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝     ╚═╝  ╚══════╝ ╚═╝                     
 * Written by MaxFlowO2, Senior Developer and Partner of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

  ///
  /// Developer this is the standard interface for all ERC721's written by myself
  ///

interface IMAX721 is IERC165 {

  // ERC165 data
  // minterStatus() => 0x2ecd28ab
  // minterFees() => 0xd95ae162
  // minterMaximumCapacity() => 0x78c5939b
  // minterMaximumTeamMints() => 0x049157bb
  // minterTeamMintsRemaining() => 0x5c17e370
  // minterTeamMintsCount() => 0xe68b7961
  // totalSupply() => 0x18160ddd
  // IMAX721 => 0x29499a25

  // @notice will return status of Minter
  // minterStatus() => 0x2ecd28ab
  function minterStatus() external view returns (bool);

  // @notice will return minting fees
  // minterFees() => 0xd95ae162
  function minterFees() external view returns (uint256);

  // @notice will return maximum mint capacity
  // minterMaximumCapacity() => 0x78c5939b
  function minterMaximumCapacity() external view returns (uint256);

  // @notice will return maximum "team minting" capacity
  // minterMaximumTeamMints() => 0x049157bb
  function minterMaximumTeamMints() external view returns (uint256);

  // @notice will return "team mints" left
  // minterTeamMintsRemaining() => 0x5c17e370
  function minterTeamMintsRemaining() external view returns (uint256);

  // @notice will return "team mints" count
  // minterTeamMintsCount() => 0xe68b7961
  function minterTeamMintsCount() external view returns (uint256);

  // @notice will return current token count
  // totalSupply() => 0x18160ddd
  function totalSupply() external view returns (uint256);
}

/***
 *    ██╗██████╗  █████╗ ██╗   ██╗ ██████╗
 *    ██║██╔══██╗██╔══██╗╚██╗ ██╔╝██╔════╝
 *    ██║██████╔╝███████║ ╚████╔╝ ██║     
 *    ██║██╔══██╗██╔══██║  ╚██╔╝  ██║     
 *    ██║██████╔╝██║  ██║   ██║   ╚██████╗
 *    ╚═╝╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝
 * Written by MaxFlowO2, Senior Developer and Partner of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 *
 * Purpose: Insipired by BAYC on Ethereum, Sets Provential Hashes and More
 * Source: https://etherscan.io/address/0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d#code
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IBAYC is IERC165{

  // ERC165
  // RevealTimestamp() => 0x83ba7c1d
  // RevealProvenanceImages() => 0xd792d2a0
  // RevealProvenanceJSON() => 0x94352676
  // RevealStartNumber() => 0x1efb051a
  // IBAYC => 0x515a7c7c

  // @notice will return timestamp of reveal
  // RevealTimestamp() => 0x83ba7c1d
  function RevealTimestamp() external view returns (uint256);

  // @notice will return Provenance hash of images
  // RevealProvenanceImages() => 0xd792d2a0
  function RevealProvenanceImages() external view returns (string memory);

  // @notice will return Provenance hash of metadata
  // RevealProvenanceJSON() => 0x94352676
  function RevealProvenanceJSON() external view returns (string memory);

  // @notice will return starting number for mint
  // RevealStartNumber() => 0x1efb051a
  function RevealStartNumber() external view returns (uint256);
}

/***
 *    ███████╗██╗██████╗       ██████╗  █████╗  █████╗  ██╗
 *    ██╔════╝██║██╔══██╗      ╚════██╗██╔══██╗██╔══██╗███║
 *    █████╗  ██║██████╔╝█████╗ █████╔╝╚██████║╚█████╔╝╚██║
 *    ██╔══╝  ██║██╔═══╝ ╚════╝██╔═══╝  ╚═══██║██╔══██╗ ██║
 *    ███████╗██║██║           ███████╗ █████╔╝╚█████╔╝ ██║
 *    ╚══════╝╚═╝╚═╝           ╚══════╝ ╚════╝  ╚════╝  ╚═╝                                                        
 * Zach Burks, James Morgan, Blaine Malone, James Seibel,
 * "EIP-2981: NFT Royalty Standard,"
 * Ethereum Improvement Proposals, no. 2981, September 2020. [Online serial].
 * Available: https://eips.ethereum.org/EIPS/eip-2981.
 *
 * Minor edit on comments to mirror the rest of the interfaces
 * by @MaxFlowO2 on 29 Dec 2021 for v2.1
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

///
/// @dev Interface for the NFT Royalty Standard
///

interface IERC2981 is IERC165 {

  // ERC165
  // royaltyInfo(uint256,uint256) => 0x2a55205a
  // IERC2981 => 0x2a55205a

  // @notice Called with the sale price to determine how much royalty
  //  is owed and to whom.
  // @param _tokenId - the NFT asset queried for royalty information
  // @param _salePrice - the sale price of the NFT asset specified by _tokenId
  // @return receiver - address of who should be sent the royalty payment
  // @return royaltyAmount - the royalty payment amount for _salePrice
  // ERC165 datum royaltyInfo(uint256,uint256) => 0x2a55205a
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);

}

/***
 *    ███████╗██████╗  ██████╗██████╗  █████╗  █████╗  ██╗                            
 *    ██╔════╝██╔══██╗██╔════╝╚════██╗██╔══██╗██╔══██╗███║                            
 *    █████╗  ██████╔╝██║      █████╔╝╚██████║╚█████╔╝╚██║                            
 *    ██╔══╝  ██╔══██╗██║     ██╔═══╝  ╚═══██║██╔══██╗ ██║                            
 *    ███████╗██║  ██║╚██████╗███████╗ █████╔╝╚█████╔╝ ██║                            
 *    ╚══════╝╚═╝  ╚═╝ ╚═════╝╚══════╝ ╚════╝  ╚════╝  ╚═╝                            
 *                                                                                    
 *     ██████╗ ██████╗ ██╗     ██╗     ███████╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗
 *    ██╔════╝██╔═══██╗██║     ██║     ██╔════╝██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║
 *    ██║     ██║   ██║██║     ██║     █████╗  ██║        ██║   ██║██║   ██║██╔██╗ ██║
 *    ██║     ██║   ██║██║     ██║     ██╔══╝  ██║        ██║   ██║██║   ██║██║╚██╗██║
 *    ╚██████╗╚██████╔╝███████╗███████╗███████╗╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║
 *     ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
 * Written by MaxFlowO2, Senior Developer and Partner of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./IERC2981.sol";

abstract contract ERC2981Collection is IERC2981 {

  // ERC165
  // royaltyInfo(uint256,uint256) => 0x2a55205a
  // ERC2981Collection => 0x2a55205a

  address private royaltyAddress;
  uint256 private royaltyPercent;

  // Set to be internal function _setRoyalties
  function _setRoyalties(address _receiver, uint256 _percentage) internal {
    royaltyAddress = _receiver;
    royaltyPercent = _percentage;
  }

  // Override for royaltyInfo(uint256, uint256)
  // royaltyInfo(uint256,uint256) => 0x2a55205a
  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external view override(IERC2981) returns (
    address receiver,
    uint256 royaltyAmount
  ) {
    receiver = royaltyAddress;

    // This sets percentages by price * percentage / 100
    royaltyAmount = _salePrice * royaltyPercent / 100;
  }
}

/***
 *     ██████╗ ██╗    ██╗███╗   ██╗ █████╗ ██████╗ ██╗     ███████╗
 *    ██╔═══██╗██║    ██║████╗  ██║██╔══██╗██╔══██╗██║     ██╔════╝
 *    ██║   ██║██║ █╗ ██║██╔██╗ ██║███████║██████╔╝██║     █████╗  
 *    ██║   ██║██║███╗██║██║╚██╗██║██╔══██║██╔══██╗██║     ██╔══╝  
 *    ╚██████╔╝╚███╔███╔╝██║ ╚████║██║  ██║██████╔╝███████╗███████╗
 *     ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝
 * This is a re-write of @openzeppelin/contracts/access/Ownable.sol
 * Rewritten by MaxFlowO2, Senior Developer and Partner of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 *
 * Upgraded to push/pull and decline by @MaxFlowO2 on 31 Dec 2021
 * Updated to ContextV2, and removed ERC165 calculations on 31 Dec 2021
 */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2
// Rewritten for onlyOwner modifier

pragma solidity >=0.8.0 <0.9.0;

import "../utils/ContextV2.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (a owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the Owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwner}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the Owner.
 */

abstract contract OwnableV2 is ContextV2 {

    address private _Owner;
    address private _newOwner;

    event OwnerTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial Owner.
     */
    constructor() {
        _transferOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current Owner.
     */
    function owner() public view virtual returns (address) {
        return _Owner;
    }

    /**
     * @dev Throws if called by any account other than the Owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Owner: caller is not the Owner");
        _;
    }

    /**
     * @dev Leaves the contract without Owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current Owner.
     *
     * NOTE: Renouncing Ownership will leave the contract without an Owner,
     * thereby removing any functionality that is only available to the Owner.
     */
    function renounceOwner() public virtual onlyOwner {
        _transferOwner(address(0));
    }

    /**
     * @dev Transfers Owner of the contract to a new account (`newOwner`).
     * Can only be called by the current Owner. Now push/pull.
     */
    function transferOwner(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Owner: new Owner is the zero address");
        _newOwner = newOwner;
    }

    /**
     * @dev Accepts Transfer Owner of the contract to a new account (`newOwner`).
     * Can only be called by the new Owner. Pull Accepted.
     */
    function acceptOwner() public virtual {
        require(_newOwner == _msgSender(), "New Owner: new Owner is the only caller");
        _transferOwner(_newOwner);
    }

    /**
     * @dev Declines Transfer Owner of the contract to a new account (`newOwner`).
     * Can only be called by the new Owner. Pull Declined.
     */
    function declineOwner() public virtual {
        require(_newOwner == _msgSender(), "New Owner: new Owner is the only caller");
        _newOwner = address(0);
    }

    /**
     * @dev Transfers Owner of the contract to a new account (`newOwner`).
     * Can only be called by the current Owner. Now push only. Orginal V1 style
     */
    function pushOwner(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Owner: new Owner is the zero address");
        _transferOwner(newOwner);
    }

    /**
     * @dev Transfers Owner of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwner(address newOwner) internal virtual {
        address oldOwner = _Owner;
        _Owner = newOwner;
        emit OwnerTransferred(oldOwner, newOwner);
    }
}

/***
 *    ██████╗ ███████╗██╗   ██╗███████╗██╗      ██████╗ ██████╗ ███████╗██████╗ 
 *    ██╔══██╗██╔════╝██║   ██║██╔════╝██║     ██╔═══██╗██╔══██╗██╔════╝██╔══██╗
 *    ██║  ██║█████╗  ██║   ██║█████╗  ██║     ██║   ██║██████╔╝█████╗  ██████╔╝
 *    ██║  ██║██╔══╝  ╚██╗ ██╔╝██╔══╝  ██║     ██║   ██║██╔═══╝ ██╔══╝  ██╔══██╗
 *    ██████╔╝███████╗ ╚████╔╝ ███████╗███████╗╚██████╔╝██║     ███████╗██║  ██║
 *    ╚═════╝ ╚══════╝  ╚═══╝  ╚══════╝╚══════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝
 * This is a re-write of @openzeppelin/contracts/access/Ownable.sol
 * Rewritten by MaxFlowO2, Senior Developer and Partner of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 *
 * Upgraded to push/pull and decline by @MaxFlowO2 on 29 Dec 2021
 * Updated to ContextV2, and removed ERC165 calculations on 31 Dec 2021
 */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2
// Rewritten for onlyDev modifier

pragma solidity >=0.8.0 <0.9.0;

import "../utils/ContextV2.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (a developer) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the developer account will be the one that deploys the contract. This
 * can later be changed with {transferDeveloper}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyDev`, which can be applied to your functions to restrict their use to
 * the developer.
 */

abstract contract DeveloperV2 is ContextV2 {

    address private _developer;
    address private _newDeveloper;

    event DeveloperTransferred(address indexed previousDeveloper, address indexed newDeveloper);

    /**
     * @dev Initializes the contract setting the deployer as the initial developer.
     */
    constructor() {
        _transferDeveloper(_msgSender());
    }

    /**
     * @dev Returns the address of the current developer.
     */
    function developer() public view virtual returns (address) {
        return _developer;
    }

    /**
     * @dev Throws if called by any account other than the developer.
     */
    modifier onlyDev() {
        require(developer() == _msgSender(), "Developer: caller is not the developer");
        _;
    }

    /**
     * @dev Leaves the contract without developer. It will not be possible to call
     * `onlyDev` functions anymore. Can only be called by the current developer.
     *
     * NOTE: Renouncing developership will leave the contract without an developer,
     * thereby removing any functionality that is only available to the developer.
     */
    function renounceDeveloper() public virtual onlyDev {
        _transferDeveloper(address(0));
    }

    /**
     * @dev Transfers Developer of the contract to a new account (`newDeveloper`).
     * Can only be called by the current developer. Now push/pull.
     */
    function transferDeveloper(address newDeveloper) public virtual onlyDev {
        require(newDeveloper != address(0), "Developer: new developer is the zero address");
        _newDeveloper = newDeveloper;
    }

    /**
     * @dev Accepts Transfer Developer of the contract to a new account (`newDeveloper`).
     * Can only be called by the new developer. Pull Accepted.
     */
    function acceptDeveloper() public virtual {
        require(_newDeveloper == _msgSender(), "New Developer: new developer is the only caller");
        _transferDeveloper(_newDeveloper);
    }

    /**
     * @dev Declines Transfer Developer of the contract to a new account (`newDeveloper`).
     * Can only be called by the new developer. Pull Declined
     */
    function declineDeveloper() public virtual {
        require(_newDeveloper == _msgSender(), "New Developer: new developer is the only caller");
        _newDeveloper = address(0);
    }

    /**
     * @dev Transfers Developer of the contract to a new account (`newDeveloper`).
     * Can only be called by the current developer. Now push only. Orginal V1 style
     */
    function pushDeveloper(address newDeveloper) public virtual onlyDev {
        require(newDeveloper != address(0), "Developer: new developer is the zero address");
        _transferDeveloper(newDeveloper);
    }

    /**
     * @dev Transfers Developer of the contract to a new account (`newDeveloper`).
     * Internal function without access restriction.
     */
    function _transferDeveloper(address newDeveloper) internal virtual {
        address oldDeveloper = _developer;
        _developer = newDeveloper;
        emit DeveloperTransferred(oldDeveloper, newDeveloper);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
interface IERC165 {
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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}