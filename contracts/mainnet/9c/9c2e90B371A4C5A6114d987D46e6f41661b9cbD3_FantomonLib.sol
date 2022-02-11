/**
 *Submitted for verification at FtmScan.com on 2022-01-28
*/

/*
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


/**************************************************************************
 * Library of core Fantomon functions
 **************************************************************************/
library FantomonLib {

    /**************************************************************************
     * Some common constants
     **************************************************************************/
    uint48 constant private ONE_MIL =         1000000;  // constant to avoid mistyping 1mil's #zeros
    uint48 constant private MAX_XP  =   1069420000000;  // XP at max level:         1069420 * 1E6
    uint48 constant private MAX_NUTRIENTS = 300000000;  // Max combined stat nutrients: 300 * 1E6
    uint48 constant private MAX_MASTERY   = 300000000;  // Max combined stat nutrients: 300 * 1E6

    /**************************************************************************
     * Core structs for storing Fantomon info
     **************************************************************************/
    struct Stats {
        uint48 hp;
        uint48 attack;
        uint48 defense;
        uint48 spAttack;
        uint48 spDefense;
    }
    struct Attributes {
        uint8 class;
        uint8 typ;
        uint8 species;
        uint8 mood;
        uint8 essence; // essence index
    }
    struct Modifiers {
        uint24 essence; // essence stat for scaling
        uint8 hpVariance;
        uint8 attackVariance;
        uint8 defenseVariance;
        uint8 spAttackVariance;
        uint8 spDefenseVariance;
    }
    struct Attacks {
        uint8 attack0;
        uint8 attack1;
        uint8 attack2;
        uint8 attack3;
    }

    struct Fmon {
        uint8  lvl;
        uint8  morph;
        uint48 xp;
        uint48 dmg;
        Stats      nutrients;
        Stats      mastery;
        Stats      base;
        Attributes attrs;
        Modifiers  modifiers;
        Attacks    attacks;
    }

    struct StatBoost {
        uint48 xp;
        uint48 hp;
        uint48 attack;
        uint48 defense;
        uint48 spAttack;
        uint48 spDefense;
    }

    /**************************************************************************
     * Getters - probe some information about an Fmon
     **************************************************************************/
    /* Did an Fmon faint? Is it's damage equal to its scaled HP
     */
    function fainted(Fmon memory _fmon) external pure returns (bool) {
        return _scaleHp(_fmon.base.hp, _fmon.nutrients.hp, _fmon.mastery.hp, _fmon.modifiers.hpVariance, _fmon.lvl) <= _fmon.dmg;
    }

    /* Serialize all attributes and stats of an Fmon into a single array
     */
    function serialize(Fmon calldata _fmon) external pure returns (uint256[36] memory _attrs) {
        Stats memory scaled = scale(_fmon);
        _attrs[ 0] = _fmon.lvl                           ;
        _attrs[ 1] = _fmon.morph                         ;
        _attrs[ 2] = _fmon.xp                  / ONE_MIL ;
        _attrs[ 3] = _fmon.base.hp             / ONE_MIL ;
        _attrs[ 4] = _fmon.base.attack         / ONE_MIL ;
        _attrs[ 5] = _fmon.base.defense        / ONE_MIL ;
        _attrs[ 6] = _fmon.base.spAttack       / ONE_MIL ;
        _attrs[ 7] = _fmon.base.spDefense      / ONE_MIL ;
        _attrs[ 8] = scaled.hp                 / ONE_MIL ;
        _attrs[ 9] = scaled.attack             / ONE_MIL ;
        _attrs[10] = scaled.defense            / ONE_MIL ;
        _attrs[11] = scaled.spAttack           / ONE_MIL ;
        _attrs[12] = scaled.spDefense          / ONE_MIL ;
        _attrs[13] = _fmon.nutrients.hp        / ONE_MIL ;
        _attrs[14] = _fmon.nutrients.attack    / ONE_MIL ;
        _attrs[15] = _fmon.nutrients.defense   / ONE_MIL ;
        _attrs[16] = _fmon.nutrients.spAttack  / ONE_MIL ;
        _attrs[17] = _fmon.nutrients.spDefense / ONE_MIL ;
        _attrs[18] = _fmon.mastery.hp          / ONE_MIL ;
        _attrs[19] = _fmon.mastery.attack      / ONE_MIL ;
        _attrs[20] = _fmon.mastery.defense     / ONE_MIL ;
        _attrs[21] = _fmon.mastery.spAttack    / ONE_MIL ;
        _attrs[22] = _fmon.mastery.spDefense   / ONE_MIL ;
        _attrs[23] = _fmon.modifiers.hpVariance          ;
        _attrs[24] = _fmon.modifiers.attackVariance      ;
        _attrs[25] = _fmon.modifiers.defenseVariance     ;
        _attrs[26] = _fmon.modifiers.defenseVariance     ;
        _attrs[27] = _fmon.modifiers.spAttackVariance    ;
        _attrs[28] = _fmon.modifiers.spDefenseVariance   ;
        _attrs[29] = _fmon.attrs.species                 ;
        _attrs[30] = _fmon.attrs.typ                     ;
        _attrs[31] = _fmon.attrs.class                   ;
        _attrs[32] = _fmon.attrs.mood                    ;
        _attrs[33] = _fmon.attrs.essence                 ;
        _attrs[34] = _fmon.attacks.attack0               ;
        _attrs[35] = _fmon.attacks.attack1               ;
    }

    /**************************************************************************
     * Math, Transform, and Memory Functions to check values of
     * Stats and Boosts after applying some transform
     * - All performed in memory
     **************************************************************************/
    /* Return an Fmon with its stats scaled */
    function scale(Fmon calldata _fmon) public pure returns (Stats memory _stats) {
        _stats.hp        =   _scaleHp(_fmon.base.hp,        _fmon.nutrients.hp,        _fmon.mastery.hp,        _fmon.modifiers.hpVariance,        _fmon.lvl);
        _stats.attack    = _scaleStat(_fmon.base.attack,    _fmon.nutrients.attack,    _fmon.mastery.attack,    _fmon.modifiers.attackVariance,    _fmon.lvl, _fmon.modifiers.essence);
        _stats.defense   = _scaleStat(_fmon.base.defense,   _fmon.nutrients.defense,   _fmon.mastery.defense,   _fmon.modifiers.defenseVariance,   _fmon.lvl, _fmon.modifiers.essence);
        _stats.spAttack  = _scaleStat(_fmon.base.spAttack,  _fmon.nutrients.spAttack,  _fmon.mastery.spAttack,  _fmon.modifiers.spAttackVariance,  _fmon.lvl, _fmon.modifiers.essence);
        _stats.spDefense = _scaleStat(_fmon.base.spDefense, _fmon.nutrients.spDefense, _fmon.mastery.spDefense, _fmon.modifiers.spDefenseVariance, _fmon.lvl, _fmon.modifiers.essence);
    }

    /* Functions to scale stats of an Fmon */
    function scaleHp(Fmon memory _fmon) internal pure returns (uint48) {
        return _scaleHp(_fmon.base.hp, _fmon.nutrients.hp, _fmon.mastery.hp, _fmon.modifiers.hpVariance, _fmon.lvl);
    }
    function scaleAttack(Fmon memory _fmon) internal pure returns (uint48) {
        return _scaleStat(_fmon.base.attack,    _fmon.nutrients.attack,    _fmon.mastery.attack,    _fmon.modifiers.attackVariance,    _fmon.lvl, _fmon.modifiers.essence);
    }
    function scaleDefense(Fmon memory _fmon) internal pure returns (uint48) {
        return _scaleStat(_fmon.base.defense,   _fmon.nutrients.defense,   _fmon.mastery.defense,   _fmon.modifiers.defenseVariance,   _fmon.lvl, _fmon.modifiers.essence);
    }
    function scaleSpAttack(Fmon memory _fmon) internal pure returns (uint48) {
        return _scaleStat(_fmon.base.spAttack,  _fmon.nutrients.spAttack,  _fmon.mastery.spAttack,  _fmon.modifiers.spAttackVariance,  _fmon.lvl, _fmon.modifiers.essence);
    }
    function scaleSpDefense(Fmon memory _fmon) internal pure returns (uint48) {
        return _scaleStat(_fmon.base.spDefense, _fmon.nutrients.spDefense, _fmon.mastery.spDefense, _fmon.modifiers.spDefenseVariance, _fmon.lvl, _fmon.modifiers.essence);
    }

    /* Mathematical formula to scale an Fmon's HP
       Returns scaled HP x 1E6
     */
    function _scaleHp(uint256 _baseHpX1M, uint256 _statNutrientsX1M, uint256 _statMasteryX1M, uint256 _variance, uint256 _level) internal pure returns (uint48) {
        return uint48((((2 * _baseHpX1M +  (_variance * 1000000) + (_statNutrientsX1M + _statMasteryX1M / 4)) * _level) / 100) + _level + 10000000);
    }

    /* Mathematical formula to scale an Fmon's other stats
       Returns scaled stat x 1E6
     */
    function _scaleStat(uint256 _baseStatX1M, uint256 _statNutrientsX1M, uint256 _statMasteryX1M, uint256 _variance, uint256 _level, uint256 _essenceX1M) internal pure returns (uint48) {
        // div by 1E6 because both stat and essence are scaled by 1E6,
        // so numerator here is 1E12 and we want return result to be 1E6
        return uint48((((((2 * _baseStatX1M + (_variance * 1000000) + (_statNutrientsX1M + _statMasteryX1M / 4)) * _level) / 100) + 5000000) * _essenceX1M) / 1000000);
    }
    /* Given a some stats, return those stats after applying a boost
     */
    function boost(Stats memory _stats, StatBoost memory _boost) external pure returns (Stats memory) {
        _stats.hp        += _boost.hp;
        _stats.attack    += _boost.attack;
        _stats.defense   += _boost.defense;
        _stats.spAttack  += _boost.spAttack;
        _stats.spDefense += _boost.spDefense;
        return _stats;
    }

    /* Given a Stat Boost, return that boost after multplying it by the provided ration (_numerator / _denominator).
       Useful when you fed too much, and can only apply a fraction of each stat boost.
     */
    function applyRatio(StatBoost memory _boost, uint256 _numerator, uint256 _denominator) external pure returns (StatBoost memory) {
        _boost.hp        = uint48((_numerator * _boost.hp)        / _denominator);
        _boost.attack    = uint48((_numerator * _boost.attack)    / _denominator);
        _boost.defense   = uint48((_numerator * _boost.defense)   / _denominator);
        _boost.spAttack  = uint48((_numerator * _boost.spAttack)  / _denominator);
        _boost.spDefense = uint48((_numerator * _boost.spDefense) / _denominator);
        return _boost;
    }
    /* Given a Stat Boost, return that boost after multplying all of its members by _amount.
       Useful when feeding an "amount" of food
     */
    function mul(StatBoost memory _boost, uint48 _amount) external pure returns (StatBoost memory) {
        _boost.xp        *= _amount;
        _boost.hp        *= _amount;
        _boost.attack    *= _amount;
        _boost.defense   *= _amount;
        _boost.spAttack  *= _amount;
        _boost.spDefense *= _amount;
        return _boost;
    }
    /* Given a Stat Boost, return that boost after multplying all of its members by _amount.
     */
    function div(StatBoost memory _boost, uint48 _amount) external pure returns (StatBoost memory) {
        _boost.xp        /= _amount;
        _boost.hp        /= _amount;
        _boost.attack    /= _amount;
        _boost.defense   /= _amount;
        _boost.spAttack  /= _amount;
        _boost.spDefense /= _amount;
        return _boost;
    }

    /* Sum all member Stats and return
     */
    function sum(Stats memory _stats) public pure returns (uint48) {
        return _stats.hp + _stats.attack + _stats.defense + _stats.spAttack + _stats.spDefense;
    }

    /* Sum all members of a Stat Boost, except XP, return
     */
    function sum(StatBoost memory _boost) external pure returns (uint48) {
        return _boost.hp + _boost.attack + _boost.defense + _boost.spAttack + _boost.spDefense;
    }
    /* Sum all members of a Stat Boost, return
     */
    function sumWithXp(StatBoost memory _boost) external pure returns (uint48) {
        return _boost.xp + _boost.hp + _boost.attack + _boost.defense + _boost.spAttack + _boost.spDefense;
    }

    /**************************************************************************
     * Storage Functions to update Fmons in Storage
     **************************************************************************/
    /* Given an Fmon in storage, boost its XP and Nutrients
       Applying the boost to storage
     */
    function commitXpNutrientBoost(Fmon storage _fmon, StatBoost memory _boost) external {
        _fmon.xp                  += _boost.xp;
        _fmon.nutrients.hp        += _boost.hp;
        _fmon.nutrients.attack    += _boost.attack;
        _fmon.nutrients.defense   += _boost.defense;
        _fmon.nutrients.spAttack  += _boost.spAttack;
        _fmon.nutrients.spDefense += _boost.spDefense;
        uint48 xp = _fmon.xp;
        require(xp <= MAX_XP && sum(_fmon.nutrients) <= MAX_NUTRIENTS, "Boost overflow");
        _fmon.lvl = xp2Lvl(xp);
    }
    /* Given an Fmon in storage, boost its XP and Mastery
       Applying the boost to storage
     */
    function commitXpMasteryBoost(Fmon storage _fmon, StatBoost memory _boost) external {
        _fmon.xp                += _boost.xp;
        _fmon.mastery.hp        += _boost.hp;
        _fmon.mastery.attack    += _boost.attack;
        _fmon.mastery.defense   += _boost.defense;
        _fmon.mastery.spAttack  += _boost.spAttack;
        _fmon.mastery.spDefense += _boost.spDefense;
        uint48 xp = _fmon.xp;
        require(xp <= MAX_XP && sum(_fmon.mastery) <= MAX_MASTERY, "Boost overflow");
        _fmon.lvl = xp2Lvl(xp);
    }
    /* Mock versions of the previous two functions that do not update storage,
       just return the updated Fmon. Useful for checking
       "how would this boost (feed/fight) affect my Fmon?"
     */
    function mockXpNutrientBoost(Fmon memory _fmon, StatBoost memory _boost) external pure returns (Fmon memory) {
        _fmon.xp                  += _boost.xp;
        _fmon.nutrients.hp        += _boost.hp;
        _fmon.nutrients.attack    += _boost.attack;
        _fmon.nutrients.defense   += _boost.defense;
        _fmon.nutrients.spAttack  += _boost.spAttack;
        _fmon.nutrients.spDefense += _boost.spDefense;
        require(_fmon.xp <= MAX_XP && sum(_fmon.nutrients) <= MAX_NUTRIENTS, "Boost overflow");
        _fmon.lvl = xp2Lvl(_fmon.xp);
        return _fmon;
    }
    function mockXpMasteryBoost(Fmon memory _fmon, StatBoost memory _boost) external pure returns (Fmon memory) {
        _fmon.xp                += _boost.xp;
        _fmon.mastery.hp        += _boost.hp;
        _fmon.mastery.attack    += _boost.attack;
        _fmon.mastery.defense   += _boost.defense;
        _fmon.mastery.spAttack  += _boost.spAttack;
        _fmon.mastery.spDefense += _boost.spDefense;
        require(_fmon.xp <= MAX_XP && sum(_fmon.mastery) <= MAX_MASTERY, "Boost overflow");
        _fmon.lvl = xp2Lvl(_fmon.xp);
        return _fmon;
    }
    /* Calculate Lvl given XP
     */
    function xp2Lvl(uint48 _xp) public pure returns (uint8) {
        uint48[100] memory XP_PER_LEVEL = [
                       0,
                 8000000,
                27000000,
                64000000,
               125000000,
               216000000,
               343000000,
               512000000,
               729000000,
              1000000000,
              1331000000,
              1728000000,
              2197000000,
              2744000000,
              3375000000,
              4096000000,
              4913000000,
              5832000000,
              6859000000,
              8000000000,
              9261000000,
             10648000000,
             12167000000,
             13824000000,
             15625000000,
             17576000000,
             19683000000,
             21952000000,
             24389000000,
             27000000000,
             29791000000,
             32768000000,
             35937000000,
             39304000000,
             42875000000,
             46656000000,
             50653000000,
             54872000000,
             59319000000,
             64000000000,
             68921000000,
             74088000000,
             79507000000,
             85184000000,
             91125000000,
             97336000000,
            103823000000,
            110592000000,
            117649000000,
            125000000000,
            132651000000,
            140608000000,
            148877000000,
            157464000000,
            166375000000,
            175616000000,
            185193000000,
            195112000000,
            205379000000,
            216000000000,
            226981000000,
            238328000000,
            250047000000,
            262144000000,
            274625000000,
            287496000000,
            300763000000,
            314432000000,
            328509000000,
            343000000000,
            357911000000,
            373248000000,
            389017000000,
            405224000000,
            421875000000,
            438976000000,
            456533000000,
            474552000000,
            493039000000,
            512000000000,
            531441000000,
            551368000000,
            571787000000,
            592704000000,
            614125000000,
            636056000000,
            658503000000,
            681472000000,
            704969000000,
            729000000000,
            753571000000,
            778688000000,
            804357000000,
            830584000000,
            857375000000,
            884736000000,
            912673000000,
            941192000000,
            970299000000,
                  MAX_XP
        ];
        for (uint8 lvl = 1; lvl <= 100; lvl++) {
            if (XP_PER_LEVEL[lvl-1] <= _xp && (lvl == 100 || XP_PER_LEVEL[lvl] > _xp)) {
                 return lvl;
            }
        }
        revert("Invalid XP");
    }
    /* What is the XP it takes to get to the given Lvl
     */
    function lvl2Xp(uint8 _lvl) public pure returns (uint48) {
        uint48[100] memory XP_PER_LEVEL = [
                       0,
                 8000000,
                27000000,
                64000000,
               125000000,
               216000000,
               343000000,
               512000000,
               729000000,
              1000000000,
              1331000000,
              1728000000,
              2197000000,
              2744000000,
              3375000000,
              4096000000,
              4913000000,
              5832000000,
              6859000000,
              8000000000,
              9261000000,
             10648000000,
             12167000000,
             13824000000,
             15625000000,
             17576000000,
             19683000000,
             21952000000,
             24389000000,
             27000000000,
             29791000000,
             32768000000,
             35937000000,
             39304000000,
             42875000000,
             46656000000,
             50653000000,
             54872000000,
             59319000000,
             64000000000,
             68921000000,
             74088000000,
             79507000000,
             85184000000,
             91125000000,
             97336000000,
            103823000000,
            110592000000,
            117649000000,
            125000000000,
            132651000000,
            140608000000,
            148877000000,
            157464000000,
            166375000000,
            175616000000,
            185193000000,
            195112000000,
            205379000000,
            216000000000,
            226981000000,
            238328000000,
            250047000000,
            262144000000,
            274625000000,
            287496000000,
            300763000000,
            314432000000,
            328509000000,
            343000000000,
            357911000000,
            373248000000,
            389017000000,
            405224000000,
            421875000000,
            438976000000,
            456533000000,
            474552000000,
            493039000000,
            512000000000,
            531441000000,
            551368000000,
            571787000000,
            592704000000,
            614125000000,
            636056000000,
            658503000000,
            681472000000,
            704969000000,
            729000000000,
            753571000000,
            778688000000,
            804357000000,
            830584000000,
            857375000000,
            884736000000,
            912673000000,
            941192000000,
            970299000000,
                  MAX_XP
        ];
        return XP_PER_LEVEL[_lvl];
    }
}