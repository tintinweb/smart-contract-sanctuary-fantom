// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "rarity_extended_equipement_base.sol";

contract rarity_extended_equipement_secondary_weapon is rarity_extended_equipement_base {
	constructor(uint8 _equipementItemType, uint8 _slot, address _wrapper)
        rarity_extended_equipement_base(_equipementItemType, _slot, _wrapper) {
	}

	function name() override public pure returns (string memory) {
		return ("Rarity Extended Equipement Secondary Weapon");
	}

	/*******************************************************************************
    **  @dev Some equipements may require some specific verifications. Example are
    **  you cannot equip a shield if you already have two weapons, or a ranged
    **  weapon. You cannot equip a shield as an armor, or an armor as a shield. You
    **  cannot equipe a secondary weapon if you have a two handed weapon or a ranged
    **  weapon.
    **  This function MUST be modified to check the requirement for the specific
    **  slot of this contract.
    **  @notice :
    **  - Check if a equipement is not two handed/ranged
    **  - Check if a two handed primary weapon is equiped
    **  - Check if a ranged primary weapon is equiped
    **  - Check if a shield is already equiped
    **  @param _adventurer: tokenID of the adventurer to work with
    **  @param _codex: address of the Codex containing the read informations
    **	@param _item_type: type of item to check in the Codex
	*******************************************************************************/
    function _handle_specific_situations(uint _adventurer, address _codex, uint8 _item_type) override internal view {
        // Check that the item is not two handed/ranged
        IEquipementCodexType3.Item memory item = IEquipementCodexType3(_codex).item_by_id(_item_type);
        require(item.encumbrance < 4, '!encumbrance');

        // Check that no shield is equiped
        (,address registryShield,,,,) = IEquipementWrapper(equipementWrapper).getEquipementBySlot(_adventurer, 101);
        require(registryShield == address(0), '!shield');

        // Check that no primary twohanded/ranger weapon is equiped
        (,address registryPrimWeapon, address codexPrimWeapon,,uint8 item_type,) = IEquipementWrapper(equipementWrapper).getEquipementBySlot(_adventurer, 5);
        if (registryPrimWeapon != address(0)) {
            IEquipementCodexType3.Item memory _weapon = IEquipementCodexType3(codexPrimWeapon).item_by_id(item_type);
            require(_weapon.encumbrance < 4, "!primary_encumbrance");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "ERC721Holder.sol";
import "extended.sol";
import "rarity.sol";
import "IRarity.sol";
import "IERC721.sol";
import "IRarityEquipementCodexType2.sol";
import "IRarityEquipementCodexType3.sol";
import "IRarityEquipementSource.sol";
import "IRarityEquipementWrapper.sol";
import "IRarityEquipementBase.sol";

abstract contract rarity_extended_equipement_base is ERC721Holder, Extended, Rarity {
	address public equipementWrapper;
	uint8 public equipementItemType;
	uint8 public equipementSlot;
    
    event EquipementWrapperSet(address wrapper);
    event RegistrySet(address registry, address codex, address minter);
	
	//Registry -> codex, aka approved contract to get informations
    mapping(address => address) public codexes; //Registry -> codex, aka approved contract to get informations
    mapping(address => address) public minters; //Registry -> minter, aka contract from which the ERC721 or rERC721 are minted

	/*******************************************************************************
    **  @dev References aboute a specific equipement for an adventurer.
    **	@param __key__: TokenID of the adventurer
    **	@param tokenID: ID of the NFT
    **	@param registry: address of the NFT
    **	@param fromAdventurer: Is the owner an adventurer or a wallet
	*******************************************************************************/
    struct Equipement {
        uint tokenID;
        address registry;
        bool fromAdventurer;
    }
    mapping(uint => Equipement) public equipement;

	/*******************************************************************************
    **  @dev Register the abstract contract.
    **	@param _equipementItemType: Can be one of theses:
	**	- 1 for Goods
	**	- 2 for Armor
	**	- 3 for Weapons
	**	- 4 for Jewelries
    **	@param _slot: Slot to use
    **	@param _wrapper: Wrapper contract address
	*******************************************************************************/
	constructor(uint8 _equipementItemType, uint8 _slot, address _wrapper) Extended() Rarity(true) {
		equipementItemType = _equipementItemType;
		equipementSlot = _slot;
		equipementWrapper = _wrapper;
	}

	/*******************************************************************************
    **  @dev Assign an equipement to an adventurer. If the adventurer already has
	**	one, it will revert. The owner of the adventurer must be the owner of the
	**	equipement, or it must be an approve address.
    **  The ERC721 is transfered to this contract, aka locked. The player will have
	**	to unset the armor before it can be transfered to another player.
    **  @param _owner: current owner of the NFT
    **  @param _adventurer: TokenID of the adventurer we want to assign to
    **	@param _operator: Address in which name we are acting for.
    **	@param _registry: Address of the contract from which is generated the ERC721
    **	@param _tokenID: TokenID of equipement
	*******************************************************************************/
    function set_equipement(uint _adventurer, address _operator, address _registry, uint256 _tokenID) virtual public {
        address codex = codexes[_registry];
        require(codex != address(0), "!registered");
        address minter = minters[_registry];
        require(minter != address(0), "!minter");

        (uint8 base_type, uint8 item_type,,) = IEquipementSource(_registry).items(_tokenID);
        require(_isApprovedOrOwner(_adventurer, msg.sender), "!owner");
        require(_isApprovedOrOwnerOfItem(_tokenID, IERC721(minter), msg.sender), "!equipement"); 
		require(base_type == equipementItemType, "!base_type");
        require(equipement[_adventurer].registry == address(0), "!already_equiped");

        _handle_specific_situations(_adventurer, codex, item_type);
        equipement[_adventurer] = Equipement(_tokenID, minter, false);
        IERC721(minter).safeTransferFrom(_operator, address(this), _tokenID);
    }

	/*******************************************************************************
    **  @notice Assign an equipement to an adventurer. If the adventurer already has
	**	one, it will revert. The owner of the adventurer must be the owner of the
	**	equipement, or it must be an approve address.
    **  The ERC721 is transfered to this contract, aka locked. The player will have
	**	to unset the armor before it can be transfered to another player.
    **  @param _adventurer: the tokenID of the adventurer to assign the armor
    **	@param _operator: adventurer in which name we are acting for.
    **	@param _registry: address of the base contract for this item, aka with
    **  which we will interact to transfer the item
    **	@param _tokenID: the tokenID of the armor
	*******************************************************************************/
    function set_rEquipement(
        uint _adventurer,
        uint _operator,
        address _registry,
        uint256 _tokenID
    ) virtual public {
        address codex = codexes[_registry];
        require(codex != address(0), "!registered");
        address minter = minters[_registry];
        require(minter != address(0), "!minter");
        uint owner = IrERC721(minter).ownerOf(_tokenID);

        (uint8 base_type, uint8 item_type,,) = IEquipementSource(_registry).items(_tokenID);
        require(_isApprovedOrOwner(owner, msg.sender), "!owner");
        require(_isApprovedOrOwnerOfItem(_tokenID, IrERC721(minter), _operator), "!equipement");
		require(base_type == equipementItemType, "!base_type");
        require(equipement[_adventurer].registry == address(0), "!already_equiped");

        _handle_specific_situations(_adventurer, codex, item_type);

        IrERC721(minter).transferFrom(
            /* operator = */ RARITY_EXTENDED_NPC,
            /* from = */ owner,
            /* to = */ RARITY_EXTENDED_NPC,
            /* id = */ _tokenID
        );
        equipement[_adventurer] = Equipement(_tokenID, minter, true);
    }

    function set_rEquipement(
        uint _adventurer,
        uint _operator,
        address _registry,
        uint256 _tokenID,
        uint256 deadline,
        bytes calldata signature
    ) virtual public {
        address codex = codexes[_registry];
        require(codex != address(0), "!registered");
        address minter = minters[_registry];
        require(minter != address(0), "!minter");
        uint owner = IrERC721(minter).ownerOf(_tokenID);

        IrERC721(minter).permit(RARITY_EXTENDED_NPC, owner, RARITY_EXTENDED_NPC, _tokenID, deadline, signature);

        (uint8 base_type, uint8 item_type,,) = IEquipementSource(_registry).items(_tokenID);
        require(_isApprovedOrOwner(owner, msg.sender), "!owner");
        require(_isApprovedOrOwnerOfItem(_tokenID, IrERC721(minter), _operator), "!equipement");
		require(base_type == equipementItemType, "!base_type");
        require(equipement[_adventurer].registry == address(0), "!already_equiped");

        _handle_specific_situations(_adventurer, codex, item_type);

        IrERC721(minter).transferFrom(
            /* operator = */ RARITY_EXTENDED_NPC,
            /* from = */ owner,
            /* to = */ RARITY_EXTENDED_NPC,
            /* id = */ _tokenID
        );
        equipement[_adventurer] = Equipement(_tokenID, minter, true);
    }

	/*******************************************************************************
    **  @dev Some equipements may require some specific verifications. Example are
    **  you cannot equip a shield if you already have two weapons, or a ranged
    **  weapon. You cannot equip a shield as an armor, or an armor as a shield. You
    **  cannot equipe a secondary weapon if you have a two handed weapon or a ranged
    **  weapon.
    **  This function MUST be modified to check the requirement for the specific
    **  slot of this contract.
    **  @notice : List of checks
    **  @param _adventurer: tokenID of the adventurer to work with
    **  @param _codex: address of the Codex containing the read informations
    **	@param _item_type: type of item to check in the Codex
	*******************************************************************************/
	function _handle_specific_situations(uint _adventurer, address _codex, uint8 _item_type) virtual internal view {}

	/*******************************************************************************
    **  @dev Remove the equipement from the equiped slot and send back the NFT to
	**	the owner. The owner can be an address or an uint.
    **  @param _adventurer: tokenID of the adventurer to work with
	*******************************************************************************/
    function unset_equipement(uint _adventurer) public {
        require(_isApprovedOrOwner(_adventurer, msg.sender), "!owner");
		
		Equipement memory equipementInfo = equipement[_adventurer];
        require(equipementInfo.registry != address(0), "!noArmor");
        equipement[_adventurer] = Equipement(0, address(0), false);

        if (equipementInfo.fromAdventurer) {
            IrERC721(equipementInfo.registry).transferFrom(
                RARITY_EXTENDED_NPC,
                RARITY_EXTENDED_NPC,
                _adventurer,
                equipementInfo.tokenID
            );
        } else {
            IERC721(equipementInfo.registry).safeTransferFrom(
                address(this),
                _rm.ownerOf(_adventurer),
                equipementInfo.tokenID
            );
        }
    }

	function getEquipement(uint _adventurer) public view returns (uint, address, address, uint8, uint8, bool) {
		Equipement memory _equipement = equipement[_adventurer];
		uint8 base_type;
		uint8 item_type;
        if (_equipement.registry != address(0)) {
			(base_type, item_type,,) = IEquipementSource(_equipement.registry).items(_equipement.tokenID);
		}
		return (
			_equipement.tokenID,
			_equipement.registry,
			codexes[_equipement.registry],
			base_type,
			item_type,
			_equipement.fromAdventurer
		);
	}

	function name() virtual public pure returns (string memory) {
		return ("Rarity Extended Equipement");
	}

	// ADMIN FUNCTIONS
	function addRegistry(address _registry, address _minter, address _codex) public onlyExtended() {
		require(codexes[_registry] == address(0), "!assigned");
		codexes[_registry] = _codex;
		minters[_registry] = _minter;

		emit RegistrySet(_registry, _codex, _minter);
	}

	function removeRegistry(address _registry) public onlyExtended() {
		require(codexes[_registry] != address(0), "!assigned");
		codexes[_registry] = address(0);
		minters[_registry] = address(0);

		emit RegistrySet(_registry, address(0), address(0));
	}

	function setEquipementWrapper(address _wrapper) public onlyExtended() {
		equipementWrapper = _wrapper;
		emit EquipementWrapperSet(_wrapper);
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
pragma solidity 0.8.10;

abstract contract Extended {
    address public extended;
    address public pendingExtended;

    constructor() {
        extended = msg.sender;
    }

    modifier onlyExtended() {
        require(msg.sender == extended, "!owner");
        _;
    }
    modifier onlyPendingExtended() {
		require(msg.sender == pendingExtended, "!authorized");
		_;
	}

    /*******************************************************************************
	**	@notice
	**		Nominate a new address to use as Extended.
	**		The change does not go into effect immediately. This function sets a
	**		pending change, and the management address is not updated until
	**		the proposed Extended address has accepted the responsibility.
	**		This may only be called by the current Extended address.
	**	@param _extended The address requested to take over the role.
	*******************************************************************************/
	function setExtended(address _extended) public onlyExtended() {
		pendingExtended = _extended;
	}

	/*******************************************************************************
	**	@notice
	**		Once a new extended address has been proposed using setExtended(),
	**		this function may be called by the proposed address to accept the
	**		responsibility of taking over the role for this contract.
	**		This may only be called by the proposed Extended address.
	**	@dev
	**		setExtended() should be called by the existing extended address,
	**		prior to calling this function.
	*******************************************************************************/
    function acceptExtended() public onlyPendingExtended() {
		extended = msg.sender;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "IRarity.sol";
import "IERC721.sol";
import "IrERC721.sol";
import "IRandomCodex.sol";

abstract contract Rarity {
    IRarity constant _rm = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
    IRandomCodex constant _random = IRandomCodex(0x7426dBE5207C2b5DaC57d8e55F0959fcD99661D4);

	uint public RARITY_EXTENDED_NPC;

	constructor(bool requireSummoner) {
		if (requireSummoner) {
        	RARITY_EXTENDED_NPC = IRarity(_rm).next_summoner();
        	IRarity(_rm).summon(8);
		}
	}

	/*******************************************************************************
    **  @dev Check if the _owner has the autorization to act on this adventurer
    **	@param _adventurer: TokenID of the adventurer we want to check
    **	@param _operator: the operator to check
	*******************************************************************************/
    function _isApprovedOrOwner(uint _adventurer, address _operator) internal view returns (bool) {
        return (
			_rm.getApproved(_adventurer) == _operator ||
			_rm.ownerOf(_adventurer) == _operator ||
			_rm.isApprovedForAll(_rm.ownerOf(_adventurer), _operator)
		);
    }

	/*******************************************************************************
    **  @dev Check if the _owner has the autorization to act on this tokenID
    **	@param _tokenID: TokenID of the item we want to check
    **	@param _source: address of contract for tokenID 
    **	@param _operator: the operator to check
	*******************************************************************************/
    function _isApprovedOrOwnerOfItem(uint _tokenID, IERC721 _source, address _operator) internal view returns (bool) {
        return (
            _source.ownerOf(_tokenID) == _operator ||
            _source.getApproved(_tokenID) == _operator ||
            _source.isApprovedForAll(_source.ownerOf(_tokenID), _operator)
        );
    }
    function _isApprovedOrOwnerOfItem(uint256 _tokenID, IrERC721 _source, uint _operator) internal view returns (bool) {
        return (
            _source.ownerOf(_tokenID) == _operator ||
            _source.getApproved(_tokenID) == _operator ||
            _source.isApprovedForAll(_tokenID, _operator)
        );
    }

}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.2. SEE SOURCE BELOW. !!
pragma solidity ^0.8.10;

interface IRarity {
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
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event leveled(address indexed owner, uint256 level, uint256 summoner);
    event summoned(address indexed owner, uint256 class, uint256 summoner);

    function adventure(uint256 _summoner) external;

    function adventurers_log(uint256) external view returns (uint256);

    function approve(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function class(uint256) external view returns (uint256);

    function classes(uint256 id)
        external
        pure
        returns (string memory description);

    function getApproved(uint256 tokenId) external view returns (address);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function level(uint256) external view returns (uint256);

    function level_up(uint256 _summoner) external;

    function name() external view returns (string memory);

    function next_summoner() external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function spend_xp(uint256 _summoner, uint256 _xp) external;

    function summon(uint256 _class) external;

    function summoner(uint256 _summoner)
        external
        view
        returns (
            uint256 _xp,
            uint256 _log,
            uint256 _class,
            uint256 _level
        );

    function symbol() external view returns (string memory);

    function tokenURI(uint256 _summoner) external view returns (string memory);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function xp(uint256) external view returns (uint256);

    function xp_required(uint256 curent_level)
        external
        pure
        returns (uint256 xp_to_next_level);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"approved","type":"address"},{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"operator","type":"address"},{"indexed":false,"internalType":"bool","name":"approved","type":"bool"}],"name":"ApprovalForAll","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":false,"internalType":"uint256","name":"level","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"summoner","type":"uint256"}],"name":"leveled","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":false,"internalType":"uint256","name":"class","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"summoner","type":"uint256"}],"name":"summoned","type":"event"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"adventure","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"adventurers_log","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"approve","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"class","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"classes","outputs":[{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"getApproved","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"operator","type":"address"}],"name":"isApprovedForAll","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"level","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"level_up","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"next_summoner","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"ownerOf","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"bytes","name":"_data","type":"bytes"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"operator","type":"address"},{"internalType":"bool","name":"approved","type":"bool"}],"name":"setApprovalForAll","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"},{"internalType":"uint256","name":"_xp","type":"uint256"}],"name":"spend_xp","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_class","type":"uint256"}],"name":"summon","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"summoner","outputs":[{"internalType":"uint256","name":"_xp","type":"uint256"},{"internalType":"uint256","name":"_log","type":"uint256"},{"internalType":"uint256","name":"_class","type":"uint256"},{"internalType":"uint256","name":"_level","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"tokenURI","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"transferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"xp","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"curent_level","type":"uint256"}],"name":"xp_required","outputs":[{"internalType":"uint256","name":"xp_to_next_level","type":"uint256"}],"stateMutability":"pure","type":"function"}]
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IrERC721 {
    function ownerOf(uint256 tokenId) external view returns (uint);
    function approve(uint from, uint to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (uint);
    function isApprovedForAll(uint owner, uint operator) external view returns (bool);
    function transferFrom(uint operator, uint from, uint to, uint256 tokenId) external;
    function permit(
        uint operator,
        uint from,
		uint to,
        uint256 tokenId,
        uint256 deadline,
        bytes calldata signature
    ) external;
    function nonces(uint owner) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IRandomCodex {
    function dn(uint _summoner, uint _number) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IEquipementCodexType2 {
    function item_by_id(uint _id) external pure returns(
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IEquipementCodexType3 {
    struct Item {
        uint id;
        uint cost;
        uint proficiency;
        uint encumbrance;
        uint damage_type;
        uint weight;
        uint damage;
        uint critical;
        int critical_modifier;
        uint range_increment;
        string name;
        string description;
    }
    function item_by_id(uint _id) external pure returns(Item memory _weapon);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IEquipementSource {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function isValid(uint _base_type, uint _item_type) external pure returns (bool);
    function items(uint tokenID) external view returns (uint8 base_type, uint8 item_type, uint32 crafted, uint256 crafter);
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IEquipementWrapper {
    function getEquipementBySlot(uint _adventurer, uint _slot) external view returns (uint, address, address, uint8, uint8, bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IEquipementBase {
    function getEquipement(uint tokenId) external view returns (uint, address, address, uint8, uint8, bool);
    function equipementSlot() external view returns (uint8);
    function codexes(address) external view returns (address);
    function minters(address) external view returns (address);
    function set_equipement(
        uint _adventurer,
        address _operator,
        address _registry,
        uint256 _tokenID
    ) external;
    function set_rEquipement(
        uint _adventurer,
        uint _operator,
        address _registry,
        uint256 _tokenID
    ) external;
    function RARITY_EXTENDED_NPC() external view returns (uint);
}