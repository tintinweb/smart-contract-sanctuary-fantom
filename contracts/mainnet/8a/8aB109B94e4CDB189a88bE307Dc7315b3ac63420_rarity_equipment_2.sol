//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../library/Codex.sol";
import "../library/Combat.sol";
import "../library/Crafting.sol";
import "../library/Equipment.sol";
import "../library/ForItems.sol";
import "../library/ForSummoners.sol";
import "../library/Proficiency.sol";

contract rarity_equipment_2 is
    ERC721Holder,
    ReentrancyGuard,
    ForSummoners,
    ForItems
{
    address[2] public MINT_WHITELIST;

    mapping(uint256 => mapping(uint8 => Equipment.Slot)) public slots;
    mapping(uint256 => uint256) public encumberance;
    mapping(address => mapping(uint256 => address)) public codexes;
    mapping(address => mapping(uint256 => mapping(uint256 => mapping(uint8 => Equipment.Slot))))
        public snapshots;

    event Equip(
        address indexed owner,
        uint256 indexed summoner,
        uint8 slot_type,
        address mint,
        uint256 token
    );
    event Unequip(
        address indexed owner,
        uint256 indexed summoner,
        uint8 slot_type,
        address mint,
        uint256 token
    );

    function set_mint_whitelist(
        address common,
        address common_armor_codex,
        address common_weapon_codex,
        address masterwork,
        address masterwork_armor_codex,
        address masterwork_weapon_codex
    ) public {
        require(MINT_WHITELIST[0] == address(0), "already set");

        MINT_WHITELIST[0] = common;
        codexes[common][2] = common_armor_codex;
        codexes[common][3] = common_weapon_codex;

        MINT_WHITELIST[1] = masterwork;
        codexes[masterwork][2] = masterwork_armor_codex;
        codexes[masterwork][3] = masterwork_weapon_codex;
    }

    function whitelisted(address mint) internal view returns (bool) {
        return mint == MINT_WHITELIST[0] || mint == MINT_WHITELIST[1];
    }

    function equip(
        uint256 summoner,
        uint8 slot_type,
        address mint,
        uint256 token
    ) public approvedForSummoner(summoner) approvedForItem(token, mint) {
        require(whitelisted(mint), "!whitelisted");
        require(slot_type < 4, "!supported");
        require(
            slots[summoner][slot_type].mint == address(0),
            "!slotAvailable"
        );

        (uint8 base_type, uint8 item_type, , ) = ICrafting(mint).items(token);

        if (slot_type == 1) {
            require(base_type == 3, "!weapon");
            IWeapon.Weapon memory weapon = ICodexWeapon(
                codexes[mint][base_type]
            ).item_by_id(item_type);
            if (weapon.encumbrance == 5) revert("ranged weapon");
            if (weapon.encumbrance == 4) {
                Equipment.Slot memory shield_slot = slots[summoner][3];
                if (shield_slot.mint != address(0)) revert("shield equipped");
            }
        } else if (slot_type == 2) {
            require(base_type == 2 && item_type < 13, "!armor");
        } else if (slot_type == 3) {
            require(base_type == 2 && item_type > 12, "!shield");
            Equipment.Slot memory weapon_slot = slots[summoner][1];
            if (weapon_slot.mint != address(0)) {
                (, uint8 weapon_type, , ) = ICrafting(weapon_slot.mint).items(
                    weapon_slot.token
                );
                IWeapon.Weapon memory equipped_weapon = ICodexWeapon(
                    codexes[weapon_slot.mint][3]
                ).item_by_id(weapon_type);
                require(
                    equipped_weapon.encumbrance < 4,
                    "two-handed or ranged weapon equipped"
                );
            }
        }

        slots[summoner][slot_type] = Equipment.Slot(mint, token);
        encumberance[summoner] += weigh(mint, base_type, item_type);

        emit Equip(msg.sender, summoner, slot_type, mint, token);

        IERC721(mint).safeTransferFrom(msg.sender, address(this), token);
    }

    function unequip(uint256 summoner, uint8 slot_type)
        public
        nonReentrant
        approvedForSummoner(summoner)
    {
        require(slots[summoner][slot_type].mint != address(0), "slotAvailable");

        Equipment.Slot memory slot = slots[summoner][slot_type];
        (uint8 base_type, uint8 item_type, , ) = ICrafting(slot.mint).items(
            slot.token
        );
        encumberance[summoner] -= weigh(slot.mint, base_type, item_type);
        delete slots[summoner][slot_type];

        emit Unequip(msg.sender, summoner, slot_type, slot.mint, slot.token);

        IERC721(slot.mint).safeTransferFrom(
            address(this),
            msg.sender,
            slot.token
        );
    }

    function snapshot(uint256 token, uint256 summoner) public {
        snapshots[msg.sender][token][summoner][1] = slots[summoner][1];
        snapshots[msg.sender][token][summoner][2] = slots[summoner][2];
        snapshots[msg.sender][token][summoner][3] = slots[summoner][3];
    }

    function weigh(
        address mint,
        uint256 base_type,
        uint8 item_type
    ) internal view returns (uint256 weight) {
        if (base_type == 2) {
            return
                ICodexArmor(codexes[mint][base_type])
                    .item_by_id(item_type)
                    .weight;
        } else if (base_type == 3) {
            return
                ICodexWeapon(codexes[mint][base_type])
                    .item_by_id(item_type)
                    .weight;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IWeapon {
    struct Weapon {
        uint8 id;
        uint8 proficiency;
        uint8 encumbrance;
        uint8 damage_type;
        uint8 weight;
        uint8 damage;
        uint8 critical;
        int8 critical_modifier;
        uint8 range_increment;
        uint256 cost;
        string name;
        string description;
    }
}

interface ICodexWeapon {
    function item_by_id(uint256 id)
        external
        pure
        returns (IWeapon.Weapon memory);

    function get_proficiency_by_id(uint256 id)
        external
        pure
        returns (string memory);

    function get_encumbrance_by_id(uint256 id)
        external
        pure
        returns (string memory);

    function get_damage_type_by_id(uint256 id)
        external
        pure
        returns (string memory);

    function get_attack_bonus(uint256 id) external pure returns (int8);
}

interface IArmor {
    struct Armor {
        uint8 id;
        uint8 proficiency;
        uint8 weight;
        uint8 armor_bonus;
        uint8 max_dex_bonus;
        int8 penalty;
        uint8 spell_failure;
        uint256 cost;
        string name;
        string description;
    }
}

interface ICodexArmor {
    function item_by_id(uint256 id) external pure returns (IArmor.Armor memory);

    function get_proficiency_by_id(uint256 id)
        external
        pure
        returns (string memory);

    function armor_check_bonus(uint256 id) external pure returns (int8);
}

interface ITools {
    struct Tools {
        uint8 id;
        uint8 weight;
        uint256 cost;
        string name;
        string description;
        int8[36] skill_bonus;
    }
}

interface ICodexTools {
    function item_by_id(uint256 id) external pure returns (ITools.Tools memory);

    function get_skill_bonus(uint256 id, uint256 skill_id)
        external
        pure
        returns (int8);
}

interface ICodexSkills {
    function skill_by_id(uint256 _id)
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Roll.sol";

library Combat {
    uint256 internal constant ATTACK_STRIDE = 7;

    struct Combatant {
        uint8 initiative_roll;
        int8 initiative_score;
        uint8 armor_class;
        int16 hit_points;
        address mint;
        uint256 token;
        int8[28] attacks; // layout: [attack_bonus, critical_modifier, critical_multiplier, damage_dice_count, damage_dice_sides, damage_modifier, damage_type.. x4]
    }

    struct Attack {
        int8 attack_bonus;
        int8 critical_modifier;
        uint8 critical_multiplier;
        uint8 damage_dice_count;
        uint8 damage_dice_sides;
        int8 damage_modifier;
        uint8 damage_type;
    }

    function pack_attack(
        int8 attack_bonus,
        int8 critical_modifier,
        uint8 critical_multiplier,
        uint8 damage_dice_count,
        uint8 damage_dice_sides,
        int8 damage_modifier,
        uint8 damage_type,
        uint256 attack_number,
        int8[28] memory attacks
    ) internal pure {
        uint256 offset = attack_number * ATTACK_STRIDE;
        attacks[offset + 0] = attack_bonus;
        attacks[offset + 1] = critical_modifier;
        attacks[offset + 2] = int8(critical_multiplier);
        attacks[offset + 3] = int8(damage_dice_count);
        attacks[offset + 4] = int8(damage_dice_sides);
        attacks[offset + 5] = damage_modifier;
        attacks[offset + 6] = int8(damage_type);
    }

    function unpack_attack(int8[28] memory attacks, uint256 attack_number)
        internal
        pure
        returns (Attack memory attack)
    {
        uint256 offset = attack_number * ATTACK_STRIDE;
        attack.attack_bonus = attacks[offset + 0];
        attack.critical_modifier = attacks[offset + 1];
        attack.critical_multiplier = uint8(attacks[offset + 2]);
        attack.damage_dice_count = uint8(attacks[offset + 3]);
        attack.damage_dice_sides = uint8(attacks[offset + 4]);
        attack.damage_modifier = attacks[offset + 5];
        attack.damage_type = uint8(attacks[offset + 6]);
    }

    function has_attack(int8[28] memory attacks, uint256 attack_number)
        internal
        pure
        returns (bool)
    {
        return attacks[ATTACK_STRIDE * (attack_number + 1) - 1] > 0;
    }

    function order_by_initiative(Combatant[] memory combatants) internal pure {
        uint256 length = combatants.length;
        for (uint256 i = 0; i < length; i++) {
            for (uint256 j = i + 1; j < length; j++) {
                Combatant memory i_combatant = combatants[i];
                Combatant memory j_combatant = combatants[j];
                if (
                    i_combatant.initiative_score < j_combatant.initiative_score
                ) {
                    combatants[i] = j_combatant;
                    combatants[j] = i_combatant;
                } else if (
                    i_combatant.initiative_score == j_combatant.initiative_score
                ) {
                    if (
                        i_combatant.initiative_roll >
                        j_combatant.initiative_roll
                    ) {
                        combatants[i] = j_combatant;
                        combatants[j] = i_combatant;
                    }
                }
            }
        }
    }

    function attack_combatant(
        Combatant memory attacker,
        Combatant storage defender,
        uint256 attack_number
    )
        internal
        returns (
            bool hit,
            uint8 roll,
            int8 score,
            uint8 critical_confirmation,
            uint8 damage,
            uint8 damage_type
        )
    {
        Attack memory attack = unpack_attack(attacker.attacks, attack_number);

        AttackRoll memory attack_roll = Roll.attack(
            attacker.token + attack_number,
            attack.attack_bonus,
            attack.critical_modifier,
            attack.critical_multiplier,
            defender.armor_class
        );

        if (attack_roll.damage_multiplier == 0) {
            return (
                false,
                attack_roll.roll,
                attack_roll.score,
                attack_roll.critical_confirmation,
                0,
                0
            );
        } else {
            damage = Roll.damage(
                attacker.token + attack_number,
                attack.damage_dice_count,
                attack.damage_dice_sides,
                attack.damage_modifier,
                attack_roll.damage_multiplier
            );
            defender.hit_points -= int16(uint16(damage));
            return (
                true,
                attack_roll.roll,
                attack_roll.score,
                attack_roll.critical_confirmation,
                damage,
                attack.damage_type
            );
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ICrafting {
    function items(uint256 token)
        external
        view
        returns (
            uint8 base_type,
            uint8 item_type,
            uint32 crafted,
            uint256 crafter
        );
}

library Crafting {
    function isApprovedOrOwnerOfItem(uint256 token, address mint)
        public
        view
        returns (bool)
    {
        if (IERC721(mint).getApproved(token) == msg.sender) return true;
        address owner = IERC721(mint).ownerOf(token);
        return
            owner == msg.sender ||
            IERC721(mint).isApprovedForAll(owner, msg.sender);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IRarityEquipment {
    function slots(uint256 summoner, uint256 slot_type)
        external
        view
        returns (Equipment.Slot memory);

    function encumberance(uint256 summoner) external view returns (uint256);

    function codexes(address mint, uint256 base_type)
        external
        view
        returns (address);

    function equip(
        uint256 summoner,
        uint256 slot_type,
        address mint,
        address codex,
        uint256 token
    ) external;

    function unequip(uint256 summoner, uint256 slot_type) external;

    function snapshot(uint256 token, uint256 summoner) external;

    function snapshots(
        address encounter,
        uint256 token,
        uint256 summoner,
        uint8 slot_type
    ) external view returns (Equipment.Slot memory);
}

library Equipment {
    struct Slot {
        address mint;
        uint256 token;
    }

    uint8 public constant SLOT_TYPE_WEAPON_1 = 1;
    uint8 public constant SLOT_TYPE_ARMOR = 2;
    uint8 public constant SLOT_TYPE_SHIELD = 3;
    uint8 public constant SLOT_TYPE_WEAPON_2 = 4;
    uint8 public constant SLOT_TYPE_HANDS = 5;
    uint8 public constant SLOT_TYPE_RING_1 = 6;
    uint8 public constant SLOT_TYPE_RING_2 = 7;
    uint8 public constant SLOT_TYPE_HEAD = 8;
    uint8 public constant SLOT_TYPE_HEADBAND = 9;
    uint8 public constant SLOT_TYPE_EYES = 10;
    uint8 public constant SLOT_TYPE_NECK = 11;
    uint8 public constant SLOT_TYPE_SHOULDERS = 12;
    uint8 public constant SLOT_TYPE_CHEST = 13;
    uint8 public constant SLOT_TYPE_BELT = 14;
    uint8 public constant SLOT_TYPE_BODY = 15;
    uint8 public constant SLOT_TYPE_ARMS = 16;
    uint8 public constant SLOT_TYPE_FEET = 17;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Crafting.sol";

contract ForItems {
    modifier approvedForItem(uint256 token, address mint) {
        if (
            (mint == address(0)) ||
            Crafting.isApprovedOrOwnerOfItem(token, mint)
        ) {
            _;
        } else {
            revert("!approvedForItem");
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Rarity.sol";

contract ForSummoners {
    modifier approvedForSummoner(uint256 summoner) {
        if (Rarity.isApprovedOrOwnerOfSummoner(summoner)) {
            _;
        } else {
            revert("!approvedForSummoner");
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Rarity.sol";
import "./Feats.sol";

library Proficiency {
    function is_proficient_with_armor(
        uint256 summoner,
        uint256 proficiency,
        uint256 armor_type
    ) public view returns (bool) {
        uint256 class = Rarity.class(summoner);

        // Barbarian
        if (class == 1) {
            if (proficiency == 1 || proficiency == 2) {
                return true;
            } else if (
                proficiency == 3 && Feats.armor_proficiency_heavy(summoner)
            ) {
                return true;
            } else if (proficiency == 4) {
                if (armor_type == 18) {
                    return Feats.tower_shield_proficiency(summoner);
                } else {
                    return true;
                }
            }

            // Bard, Ranger
        } else if (class == 2 || class == 8) {
            if (proficiency == 1 || proficiency == 2) {
                return true;
            } else if (
                (Feats.armor_proficiency_medium(summoner)) ||
                (proficiency == 3 && Feats.armor_proficiency_heavy(summoner))
            ) {
                return true;
            } else if (proficiency == 4) {
                if (armor_type == 18) {
                    return Feats.tower_shield_proficiency(summoner);
                } else {
                    return true;
                }
            }

            // Cleric, Paladin
        } else if (class == 3 || class == 7) {
            if (proficiency == 4 && armor_type == 18) {
                return Feats.tower_shield_proficiency(summoner);
            }
            return true;

            // Druid
        } else if (class == 4) {
            if (proficiency == 1 || proficiency == 2) {
                return true;
            } else if (
                proficiency == 3 && Feats.armor_proficiency_heavy(summoner)
            ) {
                return true;
            } else if (proficiency == 4) {
                if (armor_type == 18) {
                    return Feats.tower_shield_proficiency(summoner);
                } else {
                    return true;
                }
            }

            // Fighter
        } else if (class == 5) {
            return true;

            // Rogue
        } else if (class == 9) {
            return
                (proficiency == 1) ||
                (proficiency == 2 &&
                    Feats.armor_proficiency_medium(summoner)) ||
                (proficiency == 3 && Feats.armor_proficiency_heavy(summoner)) ||
                (proficiency == 4 &&
                    armor_type == 18 &&
                    Feats.tower_shield_proficiency(summoner)) ||
                (proficiency == 4 && Feats.shield_proficiency(summoner));

            // Monk, Sorcerer, Wizard
        } else if (class == 6 || class == 10 || class == 11) {
            return
                (proficiency == 1 && Feats.armor_proficiency_light(summoner)) ||
                (proficiency == 2 &&
                    Feats.armor_proficiency_medium(summoner)) ||
                (proficiency == 3 && Feats.armor_proficiency_heavy(summoner)) ||
                (proficiency == 4 &&
                    armor_type == 18 &&
                    Feats.tower_shield_proficiency(summoner)) ||
                (proficiency == 4 && Feats.shield_proficiency(summoner));
        }

        return false;
    }

    function is_proficient_with_weapon(
        uint256 summoner,
        uint256 proficiency,
        uint256 weapon_type
    ) public view returns (bool) {
        uint256 class = Rarity.class(summoner);

        // Barbarian, Fighter, Paladin, Ranger
        if (class == 1 || class == 5 || class == 7 || class == 8) {
            if (proficiency == 1 || proficiency == 2) {
                return true;
            } else if (Feats.exotic_weapon_proficiency(summoner)) {
                return true;
            }

            // Bard
        } else if (class == 2) {
            if (proficiency == 1) {
                return true;
            } else if (
                (proficiency == 2 &&
                    Feats.martial_weapon_proficiency(summoner)) ||
                (proficiency == 3 && Feats.exotic_weapon_proficiency(summoner))
            ) {
                return true;
            } else if (
                weapon_type == 27 || // longsword
                weapon_type == 29 || // rapier
                weapon_type == 23 || // sap
                weapon_type == 24 || // short sword
                weapon_type == 46 // short bow
            ) {
                return true;
            }

            // Cleric, Sorcerer
        } else if (class == 3 || class == 10) {
            if (proficiency == 1) {
                return true;
            } else if (
                (proficiency == 2 &&
                    Feats.martial_weapon_proficiency(summoner)) ||
                (proficiency == 3 && Feats.exotic_weapon_proficiency(summoner))
            ) {
                return true;
            }

            // Druid, Monk, Wizard
        } else if (class == 4 || class == 6 || class == 11) {
            if (
                (proficiency == 1 &&
                    Feats.simple_weapon_proficiency(summoner)) ||
                (proficiency == 2 &&
                    Feats.martial_weapon_proficiency(summoner)) ||
                (proficiency == 3 && Feats.exotic_weapon_proficiency(summoner))
            ) {
                return true;

                // Druid
            } else if (
                class == 4 &&
                (weapon_type == 6 || // club
                    weapon_type == 2 || // dagger
                    weapon_type == 15 || // dart
                    weapon_type == 11 || // quarterstaff
                    weapon_type == 30 || // scimitar
                    weapon_type == 5 || // sickle
                    weapon_type == 9 || // shortspear
                    weapon_type == 17 || // sling
                    weapon_type == 12) // spear
            ) {
                return true;

                // Monk
            } else if (
                class == 6 &&
                (weapon_type == 6 || // club
                    weapon_type == 14 || // light crossbow
                    weapon_type == 13 || // heavy crossbow
                    weapon_type == 2 || // dagger
                    weapon_type == 20 || // hand axe
                    weapon_type == 16 || // javelin
                    weapon_type == 48 || // kama
                    weapon_type == 49 || // nunchaku
                    weapon_type == 11 || // quarterstaff
                    weapon_type == 50 || // sia
                    weapon_type == 51 || // siangham
                    weapon_type == 17) // sling
            ) {
                return true;

                // Rogue
            } else if (
                class == 9 &&
                (weapon_type <= 17 || // Simple weapons
                    weapon_type == 57 || // hand crossbow
                    weapon_type == 29 || // rapier
                    weapon_type == 23 || // sap
                    weapon_type == 46 || // shortbow
                    weapon_type == 24) // short sword
            ) {
                return true;

                // Wizard
            } else if (
                class == 11 &&
                (weapon_type == 6 || // club
                    weapon_type == 2 || // dagger
                    weapon_type == 13 || // heavy crossbow
                    weapon_type == 14 || // light crossbow
                    weapon_type == 11) // quarterstaff
            ) {
                return true;
            }
        }

        return false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/core/IRarityCommonCrafting.sol";
import "./Attributes.sol";
import "./CraftingSkills.sol";
import "./Feats.sol";
import "./Random.sol";
import "./Skills.sol";

struct AttackRoll {
    uint8 roll;
    int8 score;
    uint8 critical_roll;
    uint8 critical_confirmation;
    uint8 damage_multiplier;
}

library Roll {
    function appraise(uint256 summoner)
        public
        view
        returns (uint8 roll, int8 score)
    {
        roll = Random.dn(summoner, 838841482654980658, 20);
        score = int8(roll);
        score += Attributes.intelligence_modifier(summoner);
        score += int8(Skills.appraise(summoner));
        if (Feats.diligent(summoner)) score += 2;
    }

    function craft_bonus(uint256 summoner, uint8 specialization)
        public
        view
        returns (int8 bonus)
    {
        bonus += Attributes.intelligence_modifier(summoner);
        if (specialization == 0) {
            bonus += int8(Skills.craft(summoner));
        } else {
            bonus += int8(CraftingSkills.ranks(summoner, specialization));
        }
    }

    function craft(uint256 summoner, uint8 specialization)
        public
        view
        returns (uint8 roll, int8 score)
    {
        roll = Random.dn(summoner, 12171199555242019957, 20);
        score = int8(roll) + craft_bonus(summoner, specialization);
    }

    function initiative(uint256 summoner)
        public
        view
        returns (uint8 roll, int8 score)
    {
        return
            initiative(
                summoner,
                Attributes.dexterity_modifier(summoner),
                Feats.improved_initiative(summoner) ? int8(4) : int8(0)
            );
    }

    function initiative(
        uint256 token,
        int8 total_dex_modifier,
        int8 initiative_bonus
    ) public view returns (uint8 roll, int8 score) {
        roll = Random.dn(token, 11781769727069077443, 20);
        score = total_dex_modifier + int8(initiative_bonus) + int8(roll);
    }

    function search(uint256 summoner)
        public
        view
        returns (uint8 roll, int8 score)
    {
        roll = Random.dn(summoner, 12460038586674487978, 20);
        score = int8(roll);
        score += Attributes.intelligence_modifier(summoner);
        score += int8(Skills.search(summoner));
        if (Feats.investigator(summoner)) score += 2;
    }

    function sense_motive(uint256 summoner)
        public
        view
        returns (uint8 roll, int8 score)
    {
        roll = Random.dn(summoner, 3505325381439919961, 20);
        score = int8(roll);
        score += Attributes.wisdom_modifier(summoner);
        score += int8(Skills.sense_motive(summoner));
        if (Feats.negotiator(summoner)) score += 2;
    }

    function attack(
        uint256 seed,
        int8 total_bonus,
        int8 critical_modifier,
        uint8 critical_multiplier,
        uint8 target_armor_class
    ) public view returns (AttackRoll memory result) {
        result.roll = Random.dn(seed, 9807527763775093748, 20);
        if (result.roll == 1) return AttackRoll(1, 0, 0, 0, 0);
        result.score = int8(result.roll) + total_bonus;
        if (result.score >= int8(target_armor_class))
            result.damage_multiplier++;
        if (result.roll >= uint256(int256(int8(20) + critical_modifier))) {
            result.critical_roll = Random.dn(seed, 9809778455456300450, 20);
            result.critical_confirmation = uint8(
                int8(result.critical_roll) + total_bonus
            );
            if (result.critical_confirmation >= target_armor_class)
                result.damage_multiplier += critical_multiplier;
        }
    }

    function damage(
        uint256 seed,
        uint8 dice_count,
        uint8 dice_sides,
        int8 total_modifier,
        uint8 damage_multiplier
    ) public view returns (uint8 result) {
        for (uint256 i; i < damage_multiplier; i++) {
            int8 signed_result = int8(
                Random.dn(seed, 6459055441333536942 + i, dice_count, dice_sides)
            ) + total_modifier;
            if (signed_result < 1) {
                result += 1;
            } else {
                result += uint8(signed_result);
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IRarityCommonCrafting {
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
    event Crafted(
        address indexed owner,
        uint256 check,
        uint256 summoner,
        uint256 base_type,
        uint256 item_type,
        uint256 gold,
        uint256 craft_i
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    function SUMMMONER_ID() external view returns (uint256);

    function approve(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function craft(
        uint256 _summoner,
        uint8 _base_type,
        uint8 _item_type,
        uint256 _crafting_materials
    ) external;

    function craft_skillcheck(uint256 _summoner, uint256 _dc)
        external
        view
        returns (bool crafted, int256 check);

    function getApproved(uint256 tokenId) external view returns (address);

    function get_armor_dc(uint256 _item_id) external pure returns (uint256 dc);

    function get_dc(uint256 _base_type, uint256 _item_id)
        external
        pure
        returns (uint256 dc);

    function get_goods_dc() external pure returns (uint256 dc);

    function get_item_cost(uint256 _base_type, uint256 _item_type)
        external
        pure
        returns (uint256 cost);

    function get_token_uri_armor(uint256 _item)
        external
        view
        returns (string memory output);

    function get_token_uri_goods(uint256 _item)
        external
        view
        returns (string memory output);

    function get_token_uri_weapon(uint256 _item)
        external
        view
        returns (string memory output);

    function get_type(uint256 _type_id)
        external
        pure
        returns (string memory _type);

    function get_weapon_dc(uint256 _item_id) external pure returns (uint256 dc);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function isValid(uint256 _base_type, uint256 _item_type)
        external
        pure
        returns (bool);

    function items(uint256)
        external
        view
        returns (
            uint8 base_type,
            uint8 item_type,
            uint32 crafted,
            uint256 crafter
        );

    function modifier_for_attribute(uint256 _attribute)
        external
        pure
        returns (int256 _modifier);

    function name() external view returns (string memory);

    function next_item() external view returns (uint256);

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

    function simulate(
        uint256 _summoner,
        uint256 _base_type,
        uint256 _item_type,
        uint256 _crafting_materials
    )
        external
        view
        returns (
            bool crafted,
            int256 check,
            uint256 cost,
            uint256 dc
        );

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function tokenURI(uint256 _item) external view returns (string memory uri);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"approved","type":"address"},{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"operator","type":"address"},{"indexed":false,"internalType":"bool","name":"approved","type":"bool"}],"name":"ApprovalForAll","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":false,"internalType":"uint256","name":"check","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"summoner","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"base_type","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"item_type","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"gold","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"craft_i","type":"uint256"}],"name":"Crafted","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"Transfer","type":"event"},{"inputs":[],"name":"SUMMMONER_ID","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"approve","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"},{"internalType":"uint8","name":"_base_type","type":"uint8"},{"internalType":"uint8","name":"_item_type","type":"uint8"},{"internalType":"uint256","name":"_crafting_materials","type":"uint256"}],"name":"craft","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"},{"internalType":"uint256","name":"_dc","type":"uint256"}],"name":"craft_skillcheck","outputs":[{"internalType":"bool","name":"crafted","type":"bool"},{"internalType":"int256","name":"check","type":"int256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"getApproved","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_item_id","type":"uint256"}],"name":"get_armor_dc","outputs":[{"internalType":"uint256","name":"dc","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_base_type","type":"uint256"},{"internalType":"uint256","name":"_item_id","type":"uint256"}],"name":"get_dc","outputs":[{"internalType":"uint256","name":"dc","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"get_goods_dc","outputs":[{"internalType":"uint256","name":"dc","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_base_type","type":"uint256"},{"internalType":"uint256","name":"_item_type","type":"uint256"}],"name":"get_item_cost","outputs":[{"internalType":"uint256","name":"cost","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_item","type":"uint256"}],"name":"get_token_uri_armor","outputs":[{"internalType":"string","name":"output","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_item","type":"uint256"}],"name":"get_token_uri_goods","outputs":[{"internalType":"string","name":"output","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_item","type":"uint256"}],"name":"get_token_uri_weapon","outputs":[{"internalType":"string","name":"output","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_type_id","type":"uint256"}],"name":"get_type","outputs":[{"internalType":"string","name":"_type","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_item_id","type":"uint256"}],"name":"get_weapon_dc","outputs":[{"internalType":"uint256","name":"dc","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"operator","type":"address"}],"name":"isApprovedForAll","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_base_type","type":"uint256"},{"internalType":"uint256","name":"_item_type","type":"uint256"}],"name":"isValid","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"items","outputs":[{"internalType":"uint8","name":"base_type","type":"uint8"},{"internalType":"uint8","name":"item_type","type":"uint8"},{"internalType":"uint32","name":"crafted","type":"uint32"},{"internalType":"uint256","name":"crafter","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_attribute","type":"uint256"}],"name":"modifier_for_attribute","outputs":[{"internalType":"int256","name":"_modifier","type":"int256"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"next_item","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"ownerOf","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"bytes","name":"_data","type":"bytes"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"operator","type":"address"},{"internalType":"bool","name":"approved","type":"bool"}],"name":"setApprovalForAll","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"},{"internalType":"uint256","name":"_base_type","type":"uint256"},{"internalType":"uint256","name":"_item_type","type":"uint256"},{"internalType":"uint256","name":"_crafting_materials","type":"uint256"}],"name":"simulate","outputs":[{"internalType":"bool","name":"crafted","type":"bool"},{"internalType":"int256","name":"check","type":"int256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"dc","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes4","name":"interfaceId","type":"bytes4"}],"name":"supportsInterface","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"index","type":"uint256"}],"name":"tokenByIndex","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"uint256","name":"index","type":"uint256"}],"name":"tokenOfOwnerByIndex","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_item","type":"uint256"}],"name":"tokenURI","outputs":[{"internalType":"string","name":"uri","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"transferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"}]
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/core/IRarityAttributes.sol";

library Attributes {
    IRarityAttributes constant ATTRIBUTES =
        IRarityAttributes(0xB5F5AF1087A8DA62A23b08C00C6ec9af21F397a1);

    struct Abilities {
        uint32 strength;
        uint32 dexterity;
        uint32 constitution;
        uint32 intelligence;
        uint32 wisdom;
        uint32 charisma;
    }

    function strength_modifier(uint256 summoner) public view returns (int8) {
        (uint32 strength, , , , , ) = ATTRIBUTES.ability_scores(summoner);
        return compute_modifier(strength);
    }

    function dexterity_modifier(uint256 summoner) public view returns (int8) {
        (, uint32 dexterity, , , , ) = ATTRIBUTES.ability_scores(summoner);
        return compute_modifier(dexterity);
    }

    function constitution_modifier(uint256 summoner)
        public
        view
        returns (int8)
    {
        (, , uint32 constitution, , , ) = ATTRIBUTES.ability_scores(summoner);
        return compute_modifier(constitution);
    }

    function intelligence_modifier(uint256 summoner)
        public
        view
        returns (int8)
    {
        (, , , uint32 intelligence, , ) = ATTRIBUTES.ability_scores(summoner);
        return compute_modifier(intelligence);
    }

    function wisdom_modifier(uint256 summoner) public view returns (int8) {
        (, , , , uint32 wisdom, ) = ATTRIBUTES.ability_scores(summoner);
        return compute_modifier(wisdom);
    }

    function charisma_modifier(uint256 summoner) public view returns (int8) {
        (, , , , , uint32 charisma) = ATTRIBUTES.ability_scores(summoner);
        return compute_modifier(charisma);
    }

    function compute_modifier(uint32 ability) public pure returns (int8) {
        if (ability < 10) return -1;
        return (int8(int32(ability)) - 10) / 2;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/codex/IRarityCodexCraftingSkills.sol";
import "../interfaces/core/IRarityCraftingSkills.sol";

library CraftingSkills {
    IRarityCodexCraftingSkills constant CODEX =
        IRarityCodexCraftingSkills(0x808a03077aFc92B193fFb0b801956E416CCb2211);
    IRarityCraftingSkills constant SKILLS =
        IRarityCraftingSkills(0xf78c4A6e4F5fFE7b73d1c68B025540eBe5aE5743);

    function ranks(uint256 summoner, uint8 specialization)
        public
        view
        returns (uint8)
    {
        uint8[5] memory skills = SKILLS.get_skills(summoner);
        return skills[specialization - 1];
    }

    function get_specialization(uint8 base_type, uint8 item_type)
        public
        pure
        returns (uint8 result)
    {
        if (base_type == 2) {
            (result, , ) = CODEX.armorsmithing();
        } else if (base_type == 3) {
            if (item_type >= 44 && item_type <= 47) {
                (result, , ) = CODEX.bowmaking();
            } else {
                (result, , ) = CODEX.weaponsmithing();
            }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/codex/IRarityCodexFeats1.sol";
import "../interfaces/codex/IRarityCodexFeats2.sol";
import "../interfaces/core/IRarityFeats.sol";

library Feats {
    IRarityCodexFeats1 constant CODEX1 =
        IRarityCodexFeats1(0x88db734E9f64cA71a24d8e75986D964FFf7a1E10);
    IRarityCodexFeats2 constant CODEX2 =
        IRarityCodexFeats2(0x7A4Ba2B077CD9f4B13D5853411EcAE12FADab89C);
    IRarityFeats constant FEATS =
        IRarityFeats(0x4F51ee975c01b0D6B29754657d7b3cC182f20d8a);

    function has_feat(uint256 summoner, uint256 feat_id)
        internal
        view
        returns (bool)
    {
        bool[100] memory feats = FEATS.get_feats(summoner);
        return feats[feat_id - 1];
    }

    function improved_initiative(uint256 summoner) public view returns (bool) {
        (uint256 id, , , , , , ) = CODEX1.improved_initiative();
        return has_feat(summoner, id);
    }

    function armor_proficiency_light(uint256 summoner)
        public
        view
        returns (bool)
    {
        (uint256 id, , , , , , ) = CODEX1.armor_proficiency_light();
        return has_feat(summoner, id);
    }

    function armor_proficiency_medium(uint256 summoner)
        public
        view
        returns (bool)
    {
        (uint256 id, , , , , , ) = CODEX1.armor_proficiency_medium();
        return has_feat(summoner, id);
    }

    function armor_proficiency_heavy(uint256 summoner)
        public
        view
        returns (bool)
    {
        (uint256 id, , , , , , ) = CODEX1.armor_proficiency_heavy();
        return has_feat(summoner, id);
    }

    function shield_proficiency(uint256 summoner) public view returns (bool) {
        (uint256 id, , , , , , ) = CODEX1.shield_proficiency();
        return has_feat(summoner, id);
    }

    function tower_shield_proficiency(uint256 summoner)
        public
        view
        returns (bool)
    {
        (uint256 id, , , , , , ) = CODEX2.tower_shield_proficiency();
        return has_feat(summoner, id);
    }

    function simple_weapon_proficiency(uint256 summoner)
        public
        view
        returns (bool)
    {
        (uint256 id, , , , , , ) = CODEX2.simple_weapon_proficiency();
        return has_feat(summoner, id);
    }

    function martial_weapon_proficiency(uint256 summoner)
        public
        view
        returns (bool)
    {
        (uint256 id, , , , , , ) = CODEX2.martial_weapon_proficiency();
        return has_feat(summoner, id);
    }

    function exotic_weapon_proficiency(uint256 summoner)
        public
        view
        returns (bool)
    {
        (uint256 id, , , , , , ) = CODEX1.exotic_weapon_proficiency();
        return has_feat(summoner, id);
    }

    function negotiator(uint256 summoner) public view returns (bool) {
        (uint256 id, , , , , , ) = CODEX2.negotiator();
        return has_feat(summoner, id);
    }

    function investigator(uint256 summoner) public view returns (bool) {
        (uint256 id, , , , , , ) = CODEX2.investigator();
        return has_feat(summoner, id);
    }

    function diligent(uint256 summoner) public view returns (bool) {
        (uint256 id, , , , , , ) = CODEX1.diligent();
        return has_feat(summoner, id);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/codex/IRarityCodexBaseRandom2.sol";

library Random {
    IRarityCodexBaseRandom2 constant RANDOM =
        IRarityCodexBaseRandom2(0xCdf408Fc20f8Ea1AE841e3F68917e1eb06Aa1e3f);

    function dn(
        uint256 seed_a,
        uint256 seed_b,
        uint8 dice_sides
    ) public view returns (uint8) {
        return RANDOM.dn(seed_a, seed_b, dice_sides);
    }

    function dn(
        uint256 seed_a,
        uint256 seed_b,
        uint8 dice_count,
        uint8 dice_sides
    ) public view returns (uint8) {
        uint8 result = 0;
        for (uint256 i; i < dice_count; i++) {
            result += RANDOM.dn(seed_a + i, seed_b, dice_sides);
        }
        return result;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/codex/IRarityCodexSkills.sol";
import "../interfaces/core/IRaritySkills.sol";

library Skills {
    IRarityCodexSkills constant CODEX =
        IRarityCodexSkills(0x67ae39a2Ee91D7258a86CD901B17527e19E493B3);
    IRaritySkills constant SKILLS =
        IRaritySkills(0x51C0B29A1d84611373BA301706c6B4b72283C80F);

    function appraise(uint256 summoner) public view returns (uint8 ranks) {
        (uint256 id, , , , , , , ) = CODEX.appraise();
        uint8[36] memory skills = SKILLS.get_skills(summoner);
        ranks = skills[id - 1];
    }

    function craft(uint256 summoner) public view returns (uint8 ranks) {
        (uint256 id, , , , , , , ) = CODEX.craft();
        uint8[36] memory skills = SKILLS.get_skills(summoner);
        ranks = skills[id - 1];
    }

    function search(uint256 summoner) public view returns (uint8 ranks) {
        (uint256 id, , , , , , , ) = CODEX.search();
        uint8[36] memory skills = SKILLS.get_skills(summoner);
        ranks = skills[id - 1];
    }

    function sense_motive(uint256 summoner) public view returns (uint8 ranks) {
        (uint256 id, , , , , , , ) = CODEX.sense_motive();
        uint8[36] memory skills = SKILLS.get_skills(summoner);
        ranks = skills[id - 1];
    }
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IRarityAttributes {
    event Created(
        address indexed creator,
        uint256 summoner,
        uint32 strength,
        uint32 dexterity,
        uint32 constitution,
        uint32 intelligence,
        uint32 wisdom,
        uint32 charisma
    );
    event Leveled(
        address indexed leveler,
        uint256 summoner,
        uint32 strength,
        uint32 dexterity,
        uint32 constitution,
        uint32 intelligence,
        uint32 wisdom,
        uint32 charisma
    );

    function abilities_by_level(uint256 current_level)
        external
        pure
        returns (uint256);

    function ability_scores(uint256)
        external
        view
        returns (
            uint32 strength,
            uint32 dexterity,
            uint32 constitution,
            uint32 intelligence,
            uint32 wisdom,
            uint32 charisma
        );

    function calc(uint256 score) external pure returns (uint256);

    function calculate_point_buy(
        uint256 _str,
        uint256 _dex,
        uint256 _const,
        uint256 _int,
        uint256 _wis,
        uint256 _cha
    ) external pure returns (uint256);

    function character_created(uint256) external view returns (bool);

    function increase_charisma(uint256 _summoner) external;

    function increase_constitution(uint256 _summoner) external;

    function increase_dexterity(uint256 _summoner) external;

    function increase_intelligence(uint256 _summoner) external;

    function increase_strength(uint256 _summoner) external;

    function increase_wisdom(uint256 _summoner) external;

    function level_points_spent(uint256) external view returns (uint256);

    function point_buy(
        uint256 _summoner,
        uint32 _str,
        uint32 _dex,
        uint32 _const,
        uint32 _int,
        uint32 _wis,
        uint32 _cha
    ) external;

    function tokenURI(uint256 _summoner) external view returns (string memory);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"creator","type":"address"},{"indexed":false,"internalType":"uint256","name":"summoner","type":"uint256"},{"indexed":false,"internalType":"uint32","name":"strength","type":"uint32"},{"indexed":false,"internalType":"uint32","name":"dexterity","type":"uint32"},{"indexed":false,"internalType":"uint32","name":"constitution","type":"uint32"},{"indexed":false,"internalType":"uint32","name":"intelligence","type":"uint32"},{"indexed":false,"internalType":"uint32","name":"wisdom","type":"uint32"},{"indexed":false,"internalType":"uint32","name":"charisma","type":"uint32"}],"name":"Created","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"leveler","type":"address"},{"indexed":false,"internalType":"uint256","name":"summoner","type":"uint256"},{"indexed":false,"internalType":"uint32","name":"strength","type":"uint32"},{"indexed":false,"internalType":"uint32","name":"dexterity","type":"uint32"},{"indexed":false,"internalType":"uint32","name":"constitution","type":"uint32"},{"indexed":false,"internalType":"uint32","name":"intelligence","type":"uint32"},{"indexed":false,"internalType":"uint32","name":"wisdom","type":"uint32"},{"indexed":false,"internalType":"uint32","name":"charisma","type":"uint32"}],"name":"Leveled","type":"event"},{"inputs":[{"internalType":"uint256","name":"current_level","type":"uint256"}],"name":"abilities_by_level","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"ability_scores","outputs":[{"internalType":"uint32","name":"strength","type":"uint32"},{"internalType":"uint32","name":"dexterity","type":"uint32"},{"internalType":"uint32","name":"constitution","type":"uint32"},{"internalType":"uint32","name":"intelligence","type":"uint32"},{"internalType":"uint32","name":"wisdom","type":"uint32"},{"internalType":"uint32","name":"charisma","type":"uint32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"score","type":"uint256"}],"name":"calc","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_str","type":"uint256"},{"internalType":"uint256","name":"_dex","type":"uint256"},{"internalType":"uint256","name":"_const","type":"uint256"},{"internalType":"uint256","name":"_int","type":"uint256"},{"internalType":"uint256","name":"_wis","type":"uint256"},{"internalType":"uint256","name":"_cha","type":"uint256"}],"name":"calculate_point_buy","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"character_created","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"increase_charisma","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"increase_constitution","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"increase_dexterity","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"increase_intelligence","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"increase_strength","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"increase_wisdom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"level_points_spent","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"},{"internalType":"uint32","name":"_str","type":"uint32"},{"internalType":"uint32","name":"_dex","type":"uint32"},{"internalType":"uint32","name":"_const","type":"uint32"},{"internalType":"uint32","name":"_int","type":"uint32"},{"internalType":"uint32","name":"_wis","type":"uint32"},{"internalType":"uint32","name":"_cha","type":"uint32"}],"name":"point_buy","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"tokenURI","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"}]
*/

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IRarityCodexCraftingSkills {
    function alchemy()
        external
        pure
        returns (
            uint8 id,
            string memory name,
            string memory description
        );

    function armorsmithing()
        external
        pure
        returns (
            uint8 id,
            string memory name,
            string memory description
        );

    function bowmaking()
        external
        pure
        returns (
            uint8 id,
            string memory name,
            string memory description
        );

    function class() external view returns (string memory);

    function index() external view returns (string memory);

    function skill_by_id(uint256 _id)
        external
        pure
        returns (
            uint8 id,
            string memory name,
            string memory description
        );

    function trapmaking()
        external
        pure
        returns (
            uint8 id,
            string memory name,
            string memory description
        );

    function weaponsmithing()
        external
        pure
        returns (
            uint8 id,
            string memory name,
            string memory description
        );
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"name":"alchemy","outputs":[{"internalType":"uint8","name":"id","type":"uint8"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"armorsmithing","outputs":[{"internalType":"uint8","name":"id","type":"uint8"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"bowmaking","outputs":[{"internalType":"uint8","name":"id","type":"uint8"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"class","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"index","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_id","type":"uint256"}],"name":"skill_by_id","outputs":[{"internalType":"uint8","name":"id","type":"uint8"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"trapmaking","outputs":[{"internalType":"uint8","name":"id","type":"uint8"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"weaponsmithing","outputs":[{"internalType":"uint8","name":"id","type":"uint8"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"}]
*/

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IRarityCraftingSkills {
    function SKILL_SLOTS() external view returns (uint8);

    function crafting_skills(uint256, uint256) external view returns (uint8);

    function get_skills(uint256 summoner)
        external
        view
        returns (uint8[5] memory);

    function is_spell_caster(uint256 summoner) external view returns (bool);

    function set_skills(uint256 summoner, uint8[5] memory skills) external;
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"name":"SKILL_SLOTS","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"crafting_skills","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"summoner","type":"uint256"}],"name":"get_skills","outputs":[{"internalType":"uint8[5]","name":"","type":"uint8[5]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"summoner","type":"uint256"}],"name":"is_spell_caster","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"summoner","type":"uint256"},{"internalType":"uint8[5]","name":"skills","type":"uint8[5]"}],"name":"set_skills","outputs":[],"stateMutability":"nonpayable","type":"function"}]
*/

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IRarityCodexFeats1 {
    function acrobatic()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function agile()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function alertness()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function animal_affinity()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function armor_proficiency_heavy()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function armor_proficiency_light()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function armor_proficiency_medium()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function athletic()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function augment_summoning()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function blind_fight()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function brew_potion()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function class() external view returns (string memory);

    function cleave()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function combat_casting()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function combat_expertise()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function combat_reflexes()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function craft_magic_arms_and_armor()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function craft_rod()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function craft_staff()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function craft_wand()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function craft_wondrous_item()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function deceitful()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function deflect_arrows()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function deft_hands()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function diehard()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function diligent()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function dodge()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function empower_spell()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function endurance()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function enlarge_spell()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function eschew_materials()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function exotic_weapon_proficiency()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function extend_spell()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function extra_turning()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function far_shot()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function feat_by_id(uint256 _id)
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function forge_ring()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function great_cleave()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function great_fortitude()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function greater_spell_focus()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function greater_spell_peneratrion()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function greater_two_weapon_fighting()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function greater_weapon_focus()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function greater_weapon_specialization()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function heighten_spell()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_bull_rush()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_counterspell()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_critical()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_disarm()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_feint()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_grapple()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_initiative()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_overrun()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_precise_shot()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_shield_bash()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_two_weapon_fighting()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_unarmed_strike()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function index() external view returns (string memory);

    function point_blank_shot()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function power_attack()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function precise_shot()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function shield_proficiency()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function spell_focus()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function spell_penetration()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function two_weapon_fighting()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function weapon_focus()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function weapon_specialization()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"name":"acrobatic","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"agile","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"alertness","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"animal_affinity","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"armor_proficiency_heavy","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"armor_proficiency_light","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"armor_proficiency_medium","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"athletic","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"augment_summoning","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"blind_fight","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"brew_potion","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"class","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"cleave","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"combat_casting","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"combat_expertise","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"combat_reflexes","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"craft_magic_arms_and_armor","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"craft_rod","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"craft_staff","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"craft_wand","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"craft_wondrous_item","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"deceitful","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"deflect_arrows","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"deft_hands","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"diehard","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"diligent","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"dodge","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"empower_spell","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"endurance","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"enlarge_spell","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"eschew_materials","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"exotic_weapon_proficiency","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"extend_spell","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"extra_turning","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"far_shot","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_id","type":"uint256"}],"name":"feat_by_id","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"forge_ring","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"great_cleave","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"great_fortitude","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"greater_spell_focus","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"greater_spell_peneratrion","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"greater_two_weapon_fighting","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"greater_weapon_focus","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"greater_weapon_specialization","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"heighten_spell","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_bull_rush","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_counterspell","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_critical","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_disarm","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_feint","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_grapple","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_initiative","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_overrun","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_precise_shot","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_shield_bash","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_two_weapon_fighting","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_unarmed_strike","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"index","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"point_blank_shot","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"power_attack","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"precise_shot","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"shield_proficiency","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"spell_focus","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"spell_penetration","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"two_weapon_fighting","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"weapon_focus","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"weapon_specialization","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"}]
*/

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IRarityCodexFeats2 {
    function class() external view returns (string memory);

    function feat_by_id(uint256 _id)
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_sunder()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_trip()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_turning()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function index() external view returns (string memory);

    function investigator()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function iron_will()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function lightning_reflexes()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function magical_aptitude()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function manyshot()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function martial_weapon_proficiency()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function maximize_spell()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function mobility()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function mounted_archery()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function mounted_combat()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function negotiator()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function nimble_fingers()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function persuasive()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function quick_draw()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function quicken_spell()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function rapid_reload()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function rapid_shot()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function ride_by_attack()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function run()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function scribe_scroll()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function self_sufficient()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function silent_spell()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function simple_weapon_proficiency()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function spell_penetration()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function stealthy()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function still_spell()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function toughness()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function tower_shield_proficiency()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function two_weapon_defense()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function weapon_finesse()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function widen_spell()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"name":"class","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_id","type":"uint256"}],"name":"feat_by_id","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_sunder","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_trip","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_turning","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"index","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"investigator","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"iron_will","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"lightning_reflexes","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"magical_aptitude","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"manyshot","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"martial_weapon_proficiency","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"maximize_spell","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"mobility","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"mounted_archery","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"mounted_combat","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"negotiator","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"nimble_fingers","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"persuasive","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"quick_draw","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"quicken_spell","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"rapid_reload","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"rapid_shot","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"ride_by_attack","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"run","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"scribe_scroll","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"self_sufficient","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"silent_spell","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"simple_weapon_proficiency","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"spell_penetration","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"stealthy","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"still_spell","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"toughness","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"tower_shield_proficiency","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"two_weapon_defense","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"weapon_finesse","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"widen_spell","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"}]
*/

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IRarityFeats {
    function character_created(uint256) external view returns (bool);

    function feat_by_id(uint256 _id)
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function feats(uint256, uint256) external view returns (bool);

    function feats_by_id(uint256, uint256) external view returns (uint256);

    function feats_per_class(uint256 _class, uint256 _level)
        external
        pure
        returns (uint256 amount);

    function feats_per_level(uint256 _level)
        external
        pure
        returns (uint256 amount);

    function get_base_class_feats(uint256 _class)
        external
        pure
        returns (uint8[7] memory _feats);

    function get_feats(uint256 _summoner)
        external
        view
        returns (bool[100] memory _feats);

    function get_feats_by_id(uint256 _summoner)
        external
        view
        returns (uint256[] memory _feats);

    function get_feats_by_name(uint256 _summoner)
        external
        view
        returns (string[] memory _names);

    function is_valid(uint256 feat) external pure returns (bool);

    function is_valid_class(uint256 _flag, uint256 _class)
        external
        pure
        returns (bool);

    function select_feat(uint256 _summoner, uint256 _feat) external;

    function setup_class(uint256 _summoner) external;
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"character_created","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_id","type":"uint256"}],"name":"feat_by_id","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"feats","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"feats_by_id","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_class","type":"uint256"},{"internalType":"uint256","name":"_level","type":"uint256"}],"name":"feats_per_class","outputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_level","type":"uint256"}],"name":"feats_per_level","outputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_class","type":"uint256"}],"name":"get_base_class_feats","outputs":[{"internalType":"uint8[7]","name":"_feats","type":"uint8[7]"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"get_feats","outputs":[{"internalType":"bool[100]","name":"_feats","type":"bool[100]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"get_feats_by_id","outputs":[{"internalType":"uint256[]","name":"_feats","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"get_feats_by_name","outputs":[{"internalType":"string[]","name":"_names","type":"string[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"feat","type":"uint256"}],"name":"is_valid","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_flag","type":"uint256"},{"internalType":"uint256","name":"_class","type":"uint256"}],"name":"is_valid_class","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"},{"internalType":"uint256","name":"_feat","type":"uint256"}],"name":"select_feat","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"setup_class","outputs":[],"stateMutability":"nonpayable","type":"function"}]
*/

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IRarityCodexBaseRandom2 {
    function class() external view returns (string memory);

    function d10(uint256 a, uint256 b) external view returns (uint8);

    function d100(uint256 a, uint256 b) external view returns (uint8);

    function d12(uint256 a, uint256 b) external view returns (uint8);

    function d20(uint256 a, uint256 b) external view returns (uint8);

    function d4(uint256 a, uint256 b) external view returns (uint8);

    function d6(uint256 a, uint256 b) external view returns (uint8);

    function d8(uint256 a, uint256 b) external view returns (uint8);

    function dn(
        uint256 a,
        uint256 b,
        uint8 die_sides
    ) external view returns (uint8);

    function index() external view returns (string memory);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"name":"class","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"a","type":"uint256"},{"internalType":"uint256","name":"b","type":"uint256"}],"name":"d10","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"a","type":"uint256"},{"internalType":"uint256","name":"b","type":"uint256"}],"name":"d100","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"a","type":"uint256"},{"internalType":"uint256","name":"b","type":"uint256"}],"name":"d12","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"a","type":"uint256"},{"internalType":"uint256","name":"b","type":"uint256"}],"name":"d20","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"a","type":"uint256"},{"internalType":"uint256","name":"b","type":"uint256"}],"name":"d4","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"a","type":"uint256"},{"internalType":"uint256","name":"b","type":"uint256"}],"name":"d6","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"a","type":"uint256"},{"internalType":"uint256","name":"b","type":"uint256"}],"name":"d8","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"a","type":"uint256"},{"internalType":"uint256","name":"b","type":"uint256"},{"internalType":"uint8","name":"die_sides","type":"uint8"}],"name":"dn","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"index","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"}]
*/

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IRarityCodexSkills {
    function appraise()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function balance()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function bluff()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function class() external view returns (string memory);

    function climb()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function concentration()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function craft()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function decipher_script()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function diplomacy()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function disable_device()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function disguise()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function escape_artist()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function forgery()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function gather_information()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function get_attribute(uint256 id)
        external
        pure
        returns (string memory attribute);

    function handle_animal()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function heal()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function hide()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function index() external view returns (string memory);

    function intimidate()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function jump()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function knowledge()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function listen()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function move_silently()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function open_lock()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function perform()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function profession()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function ride()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function search()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function sense_motive()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function skill_by_id(uint256 _id)
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function sleight_of_hand()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function speak_language()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function spellcraft()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function spot()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function survival()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function swim()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function tumble()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function use_magic_device()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function use_rope()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"name":"appraise","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"balance","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"bluff","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"class","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"climb","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"concentration","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"craft","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"decipher_script","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"diplomacy","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"disable_device","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"disguise","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"escape_artist","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"forgery","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"gather_information","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"get_attribute","outputs":[{"internalType":"string","name":"attribute","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"handle_animal","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"heal","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"hide","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"index","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"intimidate","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"jump","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"knowledge","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"listen","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"move_silently","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"open_lock","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"perform","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"profession","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"ride","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"search","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"sense_motive","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_id","type":"uint256"}],"name":"skill_by_id","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"sleight_of_hand","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"speak_language","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"spellcraft","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"spot","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"survival","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"swim","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"tumble","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"use_magic_device","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"use_rope","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"}]
*/

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IRaritySkills {
    function base_per_class(uint256 _class)
        external
        pure
        returns (uint256 base);

    function calculate_points_for_set(uint256 _class, uint8[36] memory _skills)
        external
        pure
        returns (uint256 points);

    function class_skills(uint256 _class)
        external
        pure
        returns (bool[36] memory _skills);

    function class_skills_by_name(uint256 _class)
        external
        view
        returns (string[] memory);

    function get_skills(uint256 _summoner)
        external
        view
        returns (uint8[36] memory);

    function is_valid_set(uint256 _summoner, uint8[36] memory _skills)
        external
        view
        returns (bool);

    function modifier_for_attribute(uint256 _attribute)
        external
        pure
        returns (int256 _modifier);

    function set_skills(uint256 _summoner, uint8[36] memory _skills) external;

    function skills(uint256, uint256) external view returns (uint8);

    function skills_per_level(
        int256 _int,
        uint256 _class,
        uint256 _level
    ) external pure returns (uint256 points);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[{"internalType":"uint256","name":"_class","type":"uint256"}],"name":"base_per_class","outputs":[{"internalType":"uint256","name":"base","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_class","type":"uint256"},{"internalType":"uint8[36]","name":"_skills","type":"uint8[36]"}],"name":"calculate_points_for_set","outputs":[{"internalType":"uint256","name":"points","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_class","type":"uint256"}],"name":"class_skills","outputs":[{"internalType":"bool[36]","name":"_skills","type":"bool[36]"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_class","type":"uint256"}],"name":"class_skills_by_name","outputs":[{"internalType":"string[]","name":"","type":"string[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"get_skills","outputs":[{"internalType":"uint8[36]","name":"","type":"uint8[36]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"},{"internalType":"uint8[36]","name":"_skills","type":"uint8[36]"}],"name":"is_valid_set","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_attribute","type":"uint256"}],"name":"modifier_for_attribute","outputs":[{"internalType":"int256","name":"_modifier","type":"int256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"},{"internalType":"uint8[36]","name":"_skills","type":"uint8[36]"}],"name":"set_skills","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"skills","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"int256","name":"_int","type":"int256"},{"internalType":"uint256","name":"_class","type":"uint256"},{"internalType":"uint256","name":"_level","type":"uint256"}],"name":"skills_per_level","outputs":[{"internalType":"uint256","name":"points","type":"uint256"}],"stateMutability":"pure","type":"function"}]
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/core/IRarity.sol";
import "./Attributes.sol";

library Rarity {
    IRarity constant RARITY =
        IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);

    function level(uint256 summoner) public view returns (uint256) {
        return RARITY.level(summoner);
    }

    function class(uint256 summoner) public view returns (uint256) {
        return RARITY.class(summoner);
    }

    function isApprovedOrOwnerOfSummoner(uint256 summoner)
        public
        view
        returns (bool)
    {
        if (RARITY.getApproved(summoner) == msg.sender) return true;
        address owner = RARITY.ownerOf(summoner);
        return
            owner == msg.sender || RARITY.isApprovedForAll(owner, msg.sender);
    }
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

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

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function tokenURI(uint256 _summoner) external view returns (string memory);

    function totalSupply() external view returns (uint256);

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
[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"approved","type":"address"},{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"operator","type":"address"},{"indexed":false,"internalType":"bool","name":"approved","type":"bool"}],"name":"ApprovalForAll","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":false,"internalType":"uint256","name":"level","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"summoner","type":"uint256"}],"name":"leveled","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":false,"internalType":"uint256","name":"class","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"summoner","type":"uint256"}],"name":"summoned","type":"event"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"adventure","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"adventurers_log","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"approve","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"class","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"classes","outputs":[{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"getApproved","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"operator","type":"address"}],"name":"isApprovedForAll","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"level","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"level_up","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"next_summoner","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"ownerOf","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"bytes","name":"_data","type":"bytes"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"operator","type":"address"},{"internalType":"bool","name":"approved","type":"bool"}],"name":"setApprovalForAll","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"},{"internalType":"uint256","name":"_xp","type":"uint256"}],"name":"spend_xp","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_class","type":"uint256"}],"name":"summon","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"summoner","outputs":[{"internalType":"uint256","name":"_xp","type":"uint256"},{"internalType":"uint256","name":"_log","type":"uint256"},{"internalType":"uint256","name":"_class","type":"uint256"},{"internalType":"uint256","name":"_level","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"index","type":"uint256"}],"name":"tokenByIndex","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"uint256","name":"index","type":"uint256"}],"name":"tokenOfOwnerByIndex","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"tokenURI","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"transferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"xp","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"curent_level","type":"uint256"}],"name":"xp_required","outputs":[{"internalType":"uint256","name":"xp_to_next_level","type":"uint256"}],"stateMutability":"pure","type":"function"}]
*/