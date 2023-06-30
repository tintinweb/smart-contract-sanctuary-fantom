/**
 *Submitted for verification at FtmScan.com on 2023-06-30
*/

// File: contracts/base64.sol



pragma solidity ^0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}
// File: contracts/myPet.sol


pragma solidity ^0.8.0;

library A {

    // A struct to hold the attributes of a Pet
    struct attributes {
        uint8 happiness;   // The happiness level of the Pet (max 255)
        uint8 discipline;  // The discipline level of the Pet (max 255)
        uint16 id;         // The unique ID of the Pet, used to track the same token
        uint32 weight;     // The weight of the Pet in grams
        uint8 stage;       // The stage of the Pet's life cycle (0:Egg, 1:Youth, 2:Rookie, 3:Mature, 4:Perfect)
    }

    // A struct to hold the powers of a Pet
    struct powers {
        uint32 hitpoints;     // The ability of the Pet to take damage (max limit 9,999)
        uint16 strength;      // The strength of the Pet, affecting damage (max limit 999)
        uint16 agility;       // The agility of the Pet, affecting turns (max limit 999)
        uint16 intellegence;  // The intelligence of the Pet, affecting skill chances (max limit 999)
    }

    // A struct to hold the timings of a Pet
    struct timings {
        uint64 deadtime;       // The life cycle of the Pet
        uint64 endurance;      // The hunger/food level of the Pet
        uint64 frozentime;     // The time the Pet is frozen during an adventure
        uint64 stamina;        // The limit of activities the Pet can perform
        uint64 evolutiontime;  // The time when the Pet attempts to evolve
    }

    // A struct to hold the Pet's data
    struct Pets {
        uint8 species;       // The type of Pet
        uint256 gene;        // Each digit represents a type of Pet that has ever evolved
        attributes attribute;
        powers power;
        uint32 exp;          // The experience points gained from battles/evolutions, impacting evolution
        timings time;
        uint8[3] trait;      // The traits gained at every evolution
        uint8[3] skill;      // The skills gained at every evolution
        uint32 status;       // The status of the Pet
        uint16 family;       // The family of the Pet
        bool shinning;       // The shinning state of the Pet
    }
}
// File: contracts/Metadata.sol



pragma solidity ^0.8.2;


library Meta {

    uint64 private constant FULL_STAMINA = 40 minutes; //core has record too
  
    function buildURIbased64(A.Pets memory _Pet, string memory _imageURI, string memory _imageExt,uint64 _timenow,bool _namebyID) 
    external pure returns (string memory metadata) {
        string memory _name;
        string memory _imagelinkfull;
        string memory _description;
        string memory _attribute1;
        string memory _attribute2;
        string memory _attribute3;
        string memory _attribute4;
        (_name,_description) = _getNameDescription(_Pet.species);
        _attribute1 = _getAttribute1(_Pet,_timenow);
        _attribute2 = _getAttribute2(_Pet);
        _attribute3 = _getAttribute3(_Pet);
        _attribute4 = _getAttribute4(_Pet);
        _imagelinkfull = string(abi.encodePacked(_imageURI,_toString(_Pet.species),_imageExt));
        if (_namebyID == true) {
             metadata = string(abi.encodePacked("data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            "{\"name\": \"#",_toString(_Pet.attribute.id)," ",_name,
                            "\",\"description\": \"",_description,
                            "\",\"image\": \"",
                            _imagelinkfull,
                            _attribute1,_attribute2,_attribute3,_attribute4     
                        )
                    )
                )
            ));
        } else {
            metadata = string(abi.encodePacked("data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            "{\"name\": \"",_name,
                            "\",\"description\": \"",_description,
                            "\",\"image\": \"",
                            _imagelinkfull,
                            _attribute1,_attribute2,_attribute3,_attribute4     
                        )
                    )
                )
            ));
        }
    }



    function _toString(uint _i) private pure returns (bytes memory convString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return bstr;
    }
    function sqrt32b(uint32 y) private pure returns (uint32 z) {
        if (y > 3) {
            z = y;
            uint32 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
    function _returnLevel(uint32 _exp) private pure returns (uint32 _level){
        _level= sqrt32b(_exp)/258 + 1; //min level 1 - max level 255
        
    }

    function _getAttribute1(A.Pets memory _Pet, uint64 _timenow) private pure returns (string memory attribute){
        
        string memory _stage;
        
        
        uint64 _endurance;
      
        uint64 _stamina;
        uint64 _diffTime;

       
        if (_Pet.attribute.stage == 0) {_stage = "Egg"; }
        else if (_Pet.attribute.stage == 1) {_stage = "Youth"; }
        else if (_Pet.attribute.stage == 2) {_stage = "Rookie"; }
        else if (_Pet.attribute.stage == 3) {_stage = "Matured"; }
            else {_stage = "Perfect"; }
        
        if (_Pet.status == 1) { /*frozen Pet time has to offset*/
            _diffTime = _timenow-_Pet.time.frozentime;
            _Pet.time.endurance = _Pet.time.endurance+(_diffTime);
            _Pet.time.evolutiontime = _Pet.time.evolutiontime+(_diffTime);
            _Pet.time.deadtime = _Pet.time.deadtime+(_diffTime);
            _Pet.time.stamina = _Pet.time.stamina+(_diffTime);
        }

        if (_Pet.time.endurance <= _timenow) {  _endurance=0; }
            else {_endurance = _Pet.time.endurance - _timenow; }
        
        if (_Pet.time.stamina >= _timenow) {  _stamina=0; }
            else {_stamina = _timenow - _Pet.time.stamina ; 
                    if (_stamina > FULL_STAMINA){_stamina = FULL_STAMINA;}
                    
                }
        attribute = string(abi.encodePacked(
            "\",   \"attributes\": [{\"trait_type\": \"'Stage\",\"value\": \"",bytes(_stage),
 //               \"trait_type\": \"Status\",\"value\": \"",bytes(_status),   //cut feature due to time line for hackathon
 //           "\"}, {\"trait_type\": \"Shinning\",\"value\": \"",bytes(_shinning),   //cut feature due to time line for hackathon
 //           "\"}, {
             "\"}, {\"trait_type\": \"'Species\",\"value\": \"",_toString(_Pet.species),   
            "\"}, {\"trait_type\": \"'Family\",\"value\": \"",_getFamily(_Pet.family),   //cut feature due to time line for hackathon
            "\"}, {\"trait_type\": \"_Endurance\",\"value\": \"",_getDayHrsMin(_endurance),
            "\"}, {\"trait_type\": \"_Stamina\",\"value\": \"",_getDayHrsMin(_stamina)
            
        ));
    } //divided into function2 as stack too deep.
     function _getAttribute2(A.Pets memory _Pet) private pure returns (string memory attribute){
        attribute = string(abi.encodePacked(
            "\"}, {\"trait_type\": \":::Level\",\"value\": \"",_toString(_returnLevel(_Pet.exp)),
            "\"}, {\"trait_type\": \"::HP\",\"value\": \"",_toString(_Pet.power.hitpoints),
            "\"}, {\"trait_type\": \"::STR\",\"value\": \"",_toString(_Pet.power.strength),
            "\"}, {\"trait_type\": \":AGI\",\"value\": \"",_toString(_Pet.power.agility),
            "\"}, {\"trait_type\": \":INT\",\"value\": \"",_toString(_Pet.power.intellegence),     
            "\"}, {\"trait_type\": \"Happiness\",\"value\": \"",_toString(_Pet.attribute.happiness)
            
        ));
    }//divided into function3 as stack too deep.
    function _getAttribute3(A.Pets memory _Pet) private pure returns (string memory attribute){      
        attribute = string(abi.encodePacked(       
            "\"}, {\"trait_type\": \"Discipline\",\"value\": \"",_toString(_Pet.attribute.discipline),
            "\"}, {\"trait_type\": \"Weight(g)\",\"value\": \"",_toString(_Pet.attribute.weight),          
            "\"}, {\"trait_type\": \"_Trait1\",\"value\": \"",_getTraits(_Pet.trait[0]),
            "\"}, {\"trait_type\": \"_Trait2\",\"value\": \"",_getTraits(_Pet.trait[1]),
            "\"}, {\"trait_type\": \"_Trait3\",\"value\": \"",_getTraits(_Pet.trait[2])
        ));
    }//divided into function4 as stack too deep.
    function _getAttribute4(A.Pets memory _Pet) private pure returns (string memory attribute){      
        attribute = string(abi.encodePacked(                 
            "\"}, {\"trait_type\": \"_Skill1\",\"value\": \"",_getSkills(_Pet.skill[0]),
            "\"}, {\"trait_type\": \"_Skill2\",\"value\": \"",_getSkills(_Pet.skill[1]),
            "\"}, {\"trait_type\": \"_Skill3\",\"value\": \"",_getSkills(_Pet.skill[2]),
//            "\"}, {\"trait_type\": \"Genetic\",\"value\": \"",_toString(_Pet.gene),  //cut feature due to time line for hackathon
            "\"}]}" 
        ));
    }

    function _getFamily(uint16 _family) private pure returns (bytes memory family){
        string memory familytemp;
        if (_family == 0) {familytemp = "Distinction"; }
        else if (_family == 1) {familytemp = "Celestial"; }
        else if (_family == 2) {familytemp = "Verdant"; }
        else if (_family == 3) {familytemp = "Fantasy"; }
        else if (_family == 4) {familytemp = "Abyss"; }
        family = bytes(familytemp);
    }
    function _getTraits(uint8 _trait) private pure returns (bytes memory trait){
        string memory traittemp;
        if (_trait == 0) {traittemp = "none"; }
        else if (_trait == 1) {traittemp = "Tough"; }
        else if (_trait == 2) {traittemp = "Brawler"; }
        else if (_trait == 3) {traittemp = "Nimble"; }
        else if (_trait == 4) {traittemp = "Smart"; }
        else if (_trait == 5) {traittemp = "Pride"; }
        else if (_trait == 6) {traittemp = "Resilient"; }
        else if (_trait == 7) {traittemp = "Hardworking"; }
        else if (_trait == 8) {traittemp = "Serious"; }
        else if (_trait == 9) {traittemp = "Creative"; }
        else if (_trait == 10) {traittemp = "Ambitious"; }
        else if (_trait == 11) {traittemp = "Multitasking"; }
        else if (_trait == 12) {traittemp = "Lonely"; }
        else if (_trait == 13) {traittemp = "Bashful"; }
        else if (_trait == 14) {traittemp = "Adamant"; }
        else if (_trait == 15) {traittemp = "Naughty"; }
        else if (_trait == 16) {traittemp = "Brave"; }
        else if (_trait == 17) {traittemp = "Timid"; }
        else if (_trait == 18) {traittemp = "Hasty"; }
        else if (_trait == 19) {traittemp = "Jolly"; }
        else if (_trait == 20) {traittemp = "Naive"; }
        else if (_trait == 21) {traittemp = "Quirky"; }
        else if (_trait == 22) {traittemp = "Mild"; }
        else if (_trait == 23) {traittemp = "Quiet"; }
        else if (_trait == 24) {traittemp = "Rash"; }
        else if (_trait == 25) {traittemp = "Modest"; }
        else if (_trait == 26) {traittemp = "Docile"; }
        else if (_trait == 27) {traittemp = "Relaxed"; }
        else if (_trait == 28) {traittemp = "Bold"; }
        else if (_trait == 29) {traittemp = "Impish"; }
        else if (_trait == 30) {traittemp = "Lax"; }
        else if (_trait == 31) {traittemp = "Careful";}
        else {traittemp = "none";}
        trait = bytes(traittemp);
    }
    function _getSkills(uint8 _skill) private pure returns (bytes memory skill){
        string memory skilltemp;
        //skill start at Rookie
        if (_skill == 10) {skilltemp = "Air Wave - X"; }
        else if (_skill == 11) {skilltemp = "Force Palm"; }
        else if (_skill == 12) {skilltemp = "Rock Throw"; }
        else if (_skill == 13) {skilltemp = "Fur Sting"; }
        else if (_skill == 14) {skilltemp = "Fire Ball"; }
        else if (_skill == 15) {skilltemp = "Gust"; }
        else if (_skill == 16) {skilltemp = "Air Wave - Y"; }
        else if (_skill == 17) {skilltemp = "Air Wave - Z"; }
        else if (_skill == 18) {skilltemp = "Metal Scale"; }
        else if (_skill == 19) {skilltemp = "Blade Energy"; }
        else if (_skill == 20) {skilltemp = "Fire Tornado"; }
        else if (_skill == 21) {skilltemp = "Shadowball"; }
        else if (_skill == 22) {skilltemp = "Leaf Blade"; }
        else if (_skill == 23) {skilltemp = "Flame Thrower - X"; }
        else if (_skill == 24) {skilltemp = "Wicked Slash"; }
        else if (_skill == 25) {skilltemp = "Discharge"; }
        else if (_skill == 26) {skilltemp = "Frost Blast"; }
        else if (_skill == 27) {skilltemp = "Buble Wrap"; }
        else if (_skill == 28) {skilltemp = "Spinning Slash"; }
        else if (_skill == 29) {skilltemp = "Echo scream"; }
        else if (_skill == 30) {skilltemp = "Flame Thrower - Y"; }
        else if (_skill == 31) {skilltemp = "Petal Blade"; }
        else if (_skill == 32) {skilltemp = "Crunch"; }
        else if (_skill == 33) {skilltemp = "Surprise"; }
        else if (_skill == 34) {skilltemp = "Pressure Smash"; }
        else if (_skill == 35) {skilltemp = "Take Down"; }
        else if (_skill == 36) {skilltemp = "Sparkly Swirl"; }
        else if (_skill == 37) {skilltemp = "Flame Thrower - Z"; }
        else if (_skill == 38) {skilltemp = "Sing a Song"; }
        else if (_skill == 39) {skilltemp = "Spirit Slash"; }
        else if (_skill == 40) {skilltemp = "Aimshot"; }
        else if (_skill == 41) {skilltemp = "Rainbow Force"; }
        else if (_skill == 42) {skilltemp = "Dark Swipes"; }
        else if (_skill == 43) {skilltemp = "Beat Up"; }
        else if (_skill == 44) {skilltemp = "Mega Flare - X"; }
        else if (_skill == 45) {skilltemp = "Toxic Bite"; }
        else if (_skill == 46) {skilltemp = "Sonicboom"; }
        else if (_skill == 47) {skilltemp = "Ancient Power"; }
        else if (_skill == 48) {skilltemp = "Bee Missle"; }
        else if (_skill == 49) {skilltemp = "Disaster"; }
        else if (_skill == 50) {skilltemp = "Line Wind"; }
        else if (_skill == 51) {skilltemp = "Crystal Lance"; }
        else if (_skill == 52) {skilltemp = "Hydro Pressure"; }
        else if (_skill == 53) {skilltemp = "Searing Blade"; }
        else if (_skill == 54) {skilltemp = "Mega Flare - Z"; }
        else if (_skill == 55) {skilltemp = "Explosive Smoke"; }
        else if (_skill == 56) {skilltemp = "Air Strike"; }
        else if (_skill == 57) {skilltemp = "Mega Flare - Y"; }
        else if (_skill == 58) {skilltemp = "Shadow Cut"; }
        else if (_skill == 59) {skilltemp = "Starfall"; }
        else if (_skill == 60) {skilltemp = "Earth Shake"; }
        else if (_skill == 61) {skilltemp = "Psycodamage"; }
        else if (_skill == 62) {skilltemp = "Sunraze Slash"; }
        else if (_skill == 63) {skilltemp = "Giga Blast"; }
        else {skilltemp = "none";}
        skill = bytes(skilltemp);
    }

    function _getNameDescription(uint8 _species) private pure returns (string memory name, string memory description) {
        //---
        description = "Experience the transformative Pet NFT in Fantom Adventure RPG, an immersive on-chain game. Watch it evolve through gameplay. Refresh the metadata for the latest status since it will evolve and bring it to explore the captivating world of Fantom Adventure RPG.";
        if        (_species==0) {
            name = "Mystery Box - X";
         } else if (_species==2) {
            name = "Mystery Box - Y";
        } else if (_species==3) {
            name = "Mystery Box - Z";
        } else if (_species==5) {
            name = "Youpling - X";
        } else if (_species==7) {
            name = "Youpling - Y";
        } else if (_species==8) {
            name = "Youpling - Z";
        } else if (_species==10) {
            name = "Youpling - X";
 
        } else if (_species==16) {
            name = "Wingoid";
 
        } else if (_species==17) {
            name = "IO-der";
 
        } else if (_species==23) {
            name = "Steelhead";
 
        } else if (_species==30) {
            name = "Birdori";
 
        } else if (_species==37) {
            name = "Ointank";
 
        } else if (_species==44) {
            name = "Solanake";
 
        } else if (_species==54) {
            name = "Mechindragon";
 
        } else if (_species==57) {
            name = "Feroth";
 
        }
        //---  
    }

    function _getDayHrsMin(uint64 _time) private pure returns (string memory timeDHM) {
        uint64 _day;
        uint64 _hour;
        uint64 _minute;
        uint64 _temp;
        _temp = _time;
        _day = _temp / 86400; _temp = _temp - _day*86400;
        _hour = _temp / 3600; _temp = _temp - _hour*3600;
        _minute = _temp / 60;
        timeDHM = string(abi.encodePacked(_toString(_day),"d ",_toString(_hour),"h ",_toString(_minute),"m"));
    }
   
}
// File: contracts/evolution.sol



pragma solidity ^0.8.0;

library EVO {
    //---------CONSTANT -----------------------------
    uint64 private constant lifeGainRookie = 365 days; 
    uint64 private constant lifeGainMature = 365 days; 
    uint64 private constant lifeGainPerfect = 365 days; 
    //evolution requirement from
    uint64 private constant RookietoMatureTime = 10 seconds; 
    uint64 private constant MaturetoPerfectTime = 10 seconds; 
    uint64 private constant PerfecttoUnknownTime = 365 days; 
    //--------------- private functions----------------

    function _RandNumb(uint _rand, uint32 _maxRand, uint32 _offset) private pure returns (uint32) {
        return uint32(_rand % (_maxRand-_offset) + _offset);
    }
    
    //--------------MATHS----------------- SATURATED--------
    function sqrt32b(uint32 y) private pure returns (uint32 z) {
        if (y > 3) {
            z = y;
            uint32 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
    function sub64b(uint64 a, uint64 b) private pure returns (uint64) {
    uint64 c;
        if (b <= a){
        c = a - b;
        } else {
        c = 0;
        }
        return c;
    }

    function add64b(uint64 a, uint64 b) private pure returns (uint64) {
        uint64 c; 
        unchecked {c= a + b;}
        if (c < a){
        c = 18446744073709551615;
        }
        return c;
    }
    function sub32b(uint32 a, uint32 b) private pure returns (uint32) {
    uint32 c;
        if (b <= a){
        c = a - b;
        } else {
        c = 0;
        }
        return c;
    }

    function add32b(uint32 a, uint32 b) private pure returns (uint32) {
        uint32 c; 
        unchecked {c= a + b;}
        if (c < a){
        c = 4294967295;
        }
        return c;
    }
    function sub8b(uint8 a, uint8 b) private pure returns (uint8) {
    uint8 c;
        if (b <= a){
        c = a - b;
        } else {
        c = 0;
        }
        return c;
    }
    function add8b(uint8 a, uint8 b) private pure returns (uint8) {
        uint8 c; 
        unchecked {c= a + b;}
        if (c < a){
        c = 255;
        }
        return c;
    }
    function add9L(uint8 a, uint8 b) private pure returns (uint8) {
        uint8 c; 
        unchecked {c= a + b;}
        if (c < a || c>9){
        c = 9;
        }
        return c;
    }
    function add16B999L(uint16 a, uint16 b) private pure returns (uint16) {
        uint16 c; 
        unchecked {c= a + b;}
        if (c < a || c>999){
        c = 999;
        }
        return c;
    }
    function add32B999999L(uint32 a, uint32 b) private pure returns (uint32) {
        uint32 c; 
        unchecked {c= a + b;}
        if (c < a || c>999999){
        c = 999999;
        }
        return c;
    }
    //-----------------------------------------------------
    function _returnLevel(uint32 _exp) private pure returns (uint32 _level){
        _level= sqrt32b(_exp)/258 + 1; //min level 1 - max level 255
        
    }

    function _getGene(uint256 _gene, uint8 _order) private pure returns (uint8) { 
        //order position count from 1 from LSB
        //e.g. gene 1335745, order 2, returns 4 
        return uint8((_gene/10**(_order-1)) - (_gene / 10**(_order))*10);
    }
    function _setGene(uint256 _gene, uint8 _order, uint8 _setNum) private pure returns (uint256 gene) { 
        //order position count from 1 from LSB
        //e.g. gene 1335745, order 2, setNum 9 returns 1335795
        
        uint x = _gene - (_gene/(10**(_order-1))*(10**(_order-1))); //xxX45
        uint y = (_gene/(10**(_order))*(10**(_order))); //123Xxx
        gene = _setNum*10**(_order-1) + x + y;    
    }

    function _ShinningGive(uint _rand, uint32 _exp) private pure returns (bool){
        if( _RandNumb(_rand,255,0)<= _returnLevel(_exp) ){return true;} else {return false;}
    }
//-------------------------------------------------------------------------------
//-----------EXTERNAL ------------v

    function checkEvolve(A.Pets memory _Pet) external view returns (A.Pets memory){
        uint64 timenow= uint64(block.timestamp);
        //evolved to rookie lvl 14, to mature lvl18, to perfect lvl 20
        uint8 species = _Pet.species;
        if (_Pet.attribute.stage == 1 && (_returnLevel(_Pet.exp) >= 14) && _Pet.time.evolutiontime < timenow) { //youth to rookie and reach level 14
            if        (species == 5){
                (_Pet,) = _EvolveID10RQ(1,_Pet);
  //          } else if (species == 6) {
  //              (_Pet,) = _EvolveID14RQ(1,_Pet);  //Cut feature due to timeline for Hackathon
            } else if (species == 7) {
                (_Pet,) = _EvolveID16RQ(1,_Pet);
            } else if (species == 8) {
                (_Pet,) = _EvolveID17RQ(1,_Pet);
    //        } else if (species == 9) {
    //            (_Pet,) = _EvolveID19RQ(1,_Pet);
            }
            
        } else if (_Pet.attribute.stage == 2 && (_returnLevel(_Pet.exp) >= 18) && _Pet.time.evolutiontime < timenow) { //rookie to mature and reach level 18
            if        (species == 10){ //link to above
                (_Pet,) = _EvolveID23RQ(1,_Pet);
    //        } else if (species == 14) {
    //            (_Pet,) = _EvolveID32RQ(1,_Pet); //Cut feature due to timeline for Hackathon
            } else if (species == 16) {
                (_Pet,) = _EvolveID30RQ(1,_Pet);
            } else if (species == 17) {
                (_Pet,) = _EvolveID37RQ(1,_Pet);
    //        } else if (species == 19) {
    //            (_Pet,) = _EvolveID27RQ(1,_Pet);
            }
            
        } else if (_Pet.attribute.stage == 3 && (_returnLevel(_Pet.exp) >= 20) && _Pet.time.evolutiontime < timenow) { //mature to perfect and reach level 20
            if        (species == 23){ //link to above
                (_Pet,) = _EvolveID44RQ(1,_Pet);
    //        } else if (species == 32) {
    //            (_Pet,) = _EvolveID53RQ(1,_Pet);  //Cut feature due to timeline for Hackathon
            } else if (species == 30) {
                (_Pet,) = _EvolveID57RQ(1,_Pet);
            } else if (species == 37) {
                (_Pet,) = _EvolveID54RQ(1,_Pet);
    //        } else if (species == 27) {
    //            (_Pet,) = _EvolveID49RQ(1,_Pet);
            }
        }
        return _Pet;
    }


    //------------- Evolution Requirement -------------------
    //------ Start from 10, 0 to 9 are basic and fixed via hatchegg function------
//--------------- 10 to 22, 13 Rookies -----------------  20 Mature, 21 Perfect later
//----------------  R O O K I E ----------------------------//
           function _EvolveID10RQ(uint rand, A.Pets memory _Pet) private view //Wiggle
                                returns (A.Pets memory, bool MeetRQ){
        //if (_RandNumb(rand<<1,4,0) < 3 && //60% chance to evolve to this
          //  _Pet.attribute.weight<1600   ) { //check meet evolve condition?
         //   MeetRQ = true;
            _Pet.species = 10; //set to new species
            //uint8 geneSynapse = add9L(_getGene(_Pet.gene,_Pet.species),1); //increase the geneSynapse based on new species
            //_Pet.gene = _setGene(_Pet.gene,_Pet.species+1,geneSynapse); //order always +1 from Species(start with 0), set it    
            //----evolve bonus
            _Pet.power.hitpoints = add32b(_Pet.power.hitpoints,60000);
            _Pet.power.strength = add16B999L(_Pet.power.strength,55);
            _Pet.power.agility = add16B999L(_Pet.power.agility,235);
            _Pet.power.intellegence = add16B999L(_Pet.power.intellegence,50);
            _Pet.time.deadtime = add64b(_Pet.time.deadtime,lifeGainRookie);
            _Pet.time.evolutiontime = add64b(uint64(block.timestamp),RookietoMatureTime);
            _Pet.attribute.stage = 2; 
            _Pet.trait[0] = uint8(_RandNumb(rand<<6,31,1));      //evolve gain 1 random trait
            _Pet.skill[0] = _Pet.species;      //evolve gain 1 skill/////////////////////////<----- which is its own ID example 10
        //} else { //evolve fail
         //   MeetRQ = false;
 //       }
        return (_Pet,MeetRQ);
    }
      
      function _EvolveID16RQ(uint rand, A.Pets memory _Pet) private view //Wingoid
                                returns (A.Pets memory, bool MeetRQ){
        //if (_RandNumb(rand<<13,4,0) < 3 && //60% chance to evolve to this
          //  _Pet.attribute.weight<2500   ) { //check meet evolve condition?
         //   MeetRQ = true;
            _Pet.species = 16; //set to new species
            //uint8 geneSynapse = add9L(_getGene(_Pet.gene,_Pet.species),1); //increase the geneSynapse based on new species
            //_Pet.gene = _setGene(_Pet.gene,_Pet.species+1,geneSynapse); //order always +1 from Species(start with 0), set it    
            //----evolve bonus
            _Pet.power.hitpoints = add32b(_Pet.power.hitpoints,60000);
            _Pet.power.strength = add16B999L(_Pet.power.strength,80);
            _Pet.power.agility = add16B999L(_Pet.power.agility,144);
            _Pet.power.intellegence = add16B999L(_Pet.power.intellegence,112);
            _Pet.time.deadtime = add64b(_Pet.time.deadtime,lifeGainRookie);
            _Pet.time.evolutiontime = add64b(uint64(block.timestamp),RookietoMatureTime);
            _Pet.attribute.stage = 2; 
            _Pet.trait[0] = uint8(_RandNumb(rand<<6,31,1));      //evolve gain 1 random trait
            _Pet.skill[0] = _Pet.species;      //evolve gain 1 skill/////////////////////////<----- which is its own ID example 10
        //} else { //evolve fail
         //   MeetRQ = false;
 //       }
        return (_Pet,MeetRQ);
    }
      function _EvolveID17RQ(uint rand, A.Pets memory _Pet) private view //IO-der
                                returns (A.Pets memory, bool MeetRQ){
        //if (_RandNumb(rand<<15,4,0) < 3 && //60% chance to evolve to this
          //  _Pet.attribute.discipline>=150   ) { //check meet evolve condition?
         //   MeetRQ = true;
            _Pet.species = 17; //set to new species
            //uint8 geneSynapse = add9L(_getGene(_Pet.gene,_Pet.species),1); //increase the geneSynapse based on new species
            //_Pet.gene = _setGene(_Pet.gene,_Pet.species+1,geneSynapse); //order always +1 from Species(start with 0), set it    
            //----evolve bonus
            _Pet.power.hitpoints = add32b(_Pet.power.hitpoints,140000);
            _Pet.power.strength = add16B999L(_Pet.power.strength,100);
            _Pet.power.agility = add16B999L(_Pet.power.agility,80);
            _Pet.power.intellegence = add16B999L(_Pet.power.intellegence,100);
            _Pet.time.deadtime = add64b(_Pet.time.deadtime,lifeGainRookie);
            _Pet.time.evolutiontime = add64b(uint64(block.timestamp),RookietoMatureTime);
            _Pet.attribute.stage = 2; 
            _Pet.trait[0] = uint8(_RandNumb(rand<<6,31,1));      //evolve gain 1 random trait
            _Pet.skill[0] = _Pet.species;      //evolve gain 1 skill/////////////////////////<----- which is its own ID example 10
        //} else { //evolve fail
         //   MeetRQ = false;
 //       }
        return (_Pet,MeetRQ);
    }
      function _EvolveID23RQ(uint rand, A.Pets memory _Pet) private view //Steelhead
                                returns (A.Pets memory, bool MeetRQ){
        //if (_RandNumb(rand<<27,4,0) < 3 && //60% chance to evolve to this
          //  _Pet.power.agility>=180 &&
     //       _Pet.attribute.happiness<=100   ) { //check meet evolve condition?
         //   MeetRQ = true;
            _Pet.species = 23; //set to new species
            //uint8 geneSynapse = add9L(_getGene(_Pet.gene,_Pet.species),1); //increase the geneSynapse based on new species
            //_Pet.gene = _setGene(_Pet.gene,_Pet.species+1,geneSynapse); //order always +1 from Species(start with 0), set it    
            //----evolve bonus
            _Pet.power.hitpoints = add32b(_Pet.power.hitpoints,180000);
            _Pet.power.strength = add16B999L(_Pet.power.strength,120);
            _Pet.power.agility = add16B999L(_Pet.power.agility,220);
            _Pet.power.intellegence = add16B999L(_Pet.power.intellegence,800);
            _Pet.time.deadtime = add64b(_Pet.time.deadtime,lifeGainMature);
            _Pet.time.evolutiontime = add64b(uint64(block.timestamp),MaturetoPerfectTime);
            _Pet.attribute.stage = 3; 
            _Pet.trait[1] = uint8(_RandNumb(rand<<6,31,1));      //evolve gain 1 random trait
            _Pet.skill[1] = _Pet.species;      //evolve gain 1 skill/////////////////////////<----- which is its own ID example 10
        //} else { //evolve fail
         //   MeetRQ = false;
 //       }
        return (_Pet,MeetRQ);
    }
      function _EvolveID30RQ(uint rand, A.Pets memory _Pet) private view //Birdori
                                returns (A.Pets memory, bool MeetRQ){
        //if (_RandNumb(rand<<41,4,0) < 3 && //60% chance to evolve to this
          //  _Pet.power.agility>=180 &&
     //       _Pet.attribute.happiness>120 &&
    //        _Pet.attribute.weight<7000   ) { //check meet evolve condition?
         //   MeetRQ = true;
            _Pet.species = 30; //set to new species
            //uint8 geneSynapse = add9L(_getGene(_Pet.gene,_Pet.species),1); //increase the geneSynapse based on new species
            //_Pet.gene = _setGene(_Pet.gene,_Pet.species+1,geneSynapse); //order always +1 from Species(start with 0), set it    
            //----evolve bonus
            _Pet.power.hitpoints = add32b(_Pet.power.hitpoints,180000);
            _Pet.power.strength = add16B999L(_Pet.power.strength,200);
            _Pet.power.agility = add16B999L(_Pet.power.agility,200);
            _Pet.power.intellegence = add16B999L(_Pet.power.intellegence,120);
            _Pet.time.deadtime = add64b(_Pet.time.deadtime,lifeGainMature);
            _Pet.time.evolutiontime = add64b(uint64(block.timestamp),MaturetoPerfectTime);
            _Pet.attribute.stage = 3; 
            _Pet.trait[1] = uint8(_RandNumb(rand<<6,31,1));      //evolve gain 1 random trait
            _Pet.skill[1] = _Pet.species;      //evolve gain 1 skill/////////////////////////<----- which is its own ID example 10
        //} else { //evolve fail
         //   MeetRQ = false;
 //       }
        return (_Pet,MeetRQ);
    }
      function _EvolveID37RQ(uint rand, A.Pets memory _Pet) private view //Ointank
                                returns (A.Pets memory, bool MeetRQ){
        //if (_RandNumb(rand<<55,4,0) < 3 && //60% chance to evolve to this
          //  _Pet.power.hitpoints>=180000   ) { //check meet evolve condition?
         //   MeetRQ = true;
            _Pet.species = 37; //set to new species
            //uint8 geneSynapse = add9L(_getGene(_Pet.gene,_Pet.species),1); //increase the geneSynapse based on new species
            //_Pet.gene = _setGene(_Pet.gene,_Pet.species+1,geneSynapse); //order always +1 from Species(start with 0), set it    
            //----evolve bonus
            _Pet.power.hitpoints = add32b(_Pet.power.hitpoints,300000);
            _Pet.power.strength = add16B999L(_Pet.power.strength,150);
            _Pet.power.agility = add16B999L(_Pet.power.agility,107);
            _Pet.power.intellegence = add16B999L(_Pet.power.intellegence,124);
            _Pet.time.deadtime = add64b(_Pet.time.deadtime,lifeGainMature);
            _Pet.time.evolutiontime = add64b(uint64(block.timestamp),MaturetoPerfectTime);
            _Pet.attribute.stage = 3; 
            _Pet.trait[1] = uint8(_RandNumb(rand<<6,31,1));      //evolve gain 1 random trait
            _Pet.skill[1] = _Pet.species;      //evolve gain 1 skill/////////////////////////<----- which is its own ID example 10
        //} else { //evolve fail
         //   MeetRQ = false;
 //       }
        return (_Pet,MeetRQ);
    }
      function _EvolveID44RQ(uint rand, A.Pets memory _Pet) private view //Solanake
                                returns (A.Pets memory, bool MeetRQ){
        //if (_RandNumb(rand<<69,4,0) < 3 && //60% chance to evolve to this
          //  _Pet.power.hitpoints>300000 &&
    //        _Pet.power.agility>400 &&
     //       _Pet.power.intellegence>200 &&
     //       _Pet.attribute.discipline<50 &&
     //       _Pet.attribute.weight>60000   ) { //check meet evolve condition?
         //   MeetRQ = true;
            _Pet.species = 44; //set to new species
            //uint8 geneSynapse = add9L(_getGene(_Pet.gene,_Pet.species),1); //increase the geneSynapse based on new species
            //_Pet.gene = _setGene(_Pet.gene,_Pet.species+1,geneSynapse); //order always +1 from Species(start with 0), set it    
            //----evolve bonus
            _Pet.power.hitpoints = add32b(_Pet.power.hitpoints,176000);
            _Pet.power.strength = add16B999L(_Pet.power.strength,198);
            _Pet.power.agility = add16B999L(_Pet.power.agility,220);
            _Pet.power.intellegence = add16B999L(_Pet.power.intellegence,200);
            _Pet.time.deadtime = add64b(_Pet.time.deadtime,lifeGainPerfect);
            _Pet.time.evolutiontime = add64b(uint64(block.timestamp),PerfecttoUnknownTime);
            _Pet.attribute.stage = 4; 
            _Pet.trait[2] = uint8(_RandNumb(rand<<6,31,1));      //evolve gain 1 random trait
            _Pet.skill[2] = _Pet.species;      //evolve gain 1 skill/////////////////////////<----- which is its own ID example 10
        //} else { //evolve fail
         //   MeetRQ = false;
 //       }
        return (_Pet,MeetRQ);
    }
      function _EvolveID54RQ(uint rand, A.Pets memory _Pet) private view //Mechindragon
                                returns (A.Pets memory, bool MeetRQ){
        //if (_RandNumb(rand<<89,4,0) < 3 && //60% chance to evolve to this
          //  _Pet.power.hitpoints>500000 &&
     //       _Pet.power.strength>400 &&
     //       _returnLevel(_Pet.exp)>40 &&
     //       _Pet.attribute.weight>140000   ) { //check meet evolve condition?
         //   MeetRQ = true;
            _Pet.species = 54; //set to new species
            //uint8 geneSynapse = add9L(_getGene(_Pet.gene,_Pet.species),1); //increase the geneSynapse based on new species
            //_Pet.gene = _setGene(_Pet.gene,_Pet.species+1,geneSynapse); //order always +1 from Species(start with 0), set it    
            //----evolve bonus
            _Pet.power.hitpoints = add32b(_Pet.power.hitpoints,245000);
            _Pet.power.strength = add16B999L(_Pet.power.strength,209);
            _Pet.power.agility = add16B999L(_Pet.power.agility,178);
            _Pet.power.intellegence = add16B999L(_Pet.power.intellegence,200);
            _Pet.time.deadtime = add64b(_Pet.time.deadtime,lifeGainPerfect);
            _Pet.time.evolutiontime = add64b(uint64(block.timestamp),PerfecttoUnknownTime);
            _Pet.attribute.stage = 4; 
            _Pet.trait[2] = uint8(_RandNumb(rand<<6,31,1));      //evolve gain 1 random trait
            _Pet.skill[2] = _Pet.species;      //evolve gain 1 skill/////////////////////////<----- which is its own ID example 10
        //} else { //evolve fail
         //   MeetRQ = false;
 //       }
        return (_Pet,MeetRQ);
    }
      function _EvolveID57RQ(uint rand, A.Pets memory _Pet) private view //Feroth
                                returns (A.Pets memory, bool MeetRQ){
        //if (_RandNumb(rand<<95,4,0) < 3 && //60% chance to evolve to this
          //  _Pet.power.hitpoints>400000 &&
     //       _Pet.power.strength>300 &&
      //      _Pet.power.intellegence>350 &&
      //      _returnLevel(_Pet.exp)>23 &&
      //      _Pet.attribute.happiness<50   ) { //check meet evolve condition?
         //   MeetRQ = true;
            _Pet.species = 57; //set to new species
            //uint8 geneSynapse = add9L(_getGene(_Pet.gene,_Pet.species),1); //increase the geneSynapse based on new species
            //_Pet.gene = _setGene(_Pet.gene,_Pet.species+1,geneSynapse); //order always +1 from Species(start with 0), set it    
            //----evolve bonus
            _Pet.power.hitpoints = add32b(_Pet.power.hitpoints,190000);
            _Pet.power.strength = add16B999L(_Pet.power.strength,233);
            _Pet.power.agility = add16B999L(_Pet.power.agility,166);
            _Pet.power.intellegence = add16B999L(_Pet.power.intellegence,233);
            _Pet.time.deadtime = add64b(_Pet.time.deadtime,lifeGainPerfect);
            _Pet.time.evolutiontime = add64b(uint64(block.timestamp),PerfecttoUnknownTime);
            _Pet.attribute.stage = 4; 
            _Pet.trait[2] = uint8(_RandNumb(rand<<6,31,1));      //evolve gain 1 random trait
            _Pet.skill[2] = _Pet.species;      //evolve gain 1 skill/////////////////////////<----- which is its own ID example 10
        //} else { //evolve fail
         //   MeetRQ = false;
 //       }
        return (_Pet,MeetRQ);
    }
  


}
// File: contracts/core.sol



pragma solidity ^0.8;



library core {
    uint64 private constant FULL_ENDURANCE = 24 hours;
    uint64 private constant INITIAL_STAMINA = 40 minutes;
    uint64 private constant FULL_STAMINA = 40 minutes;
    uint64 private constant INITIAL_ENDURANCE = 6 hours;
    uint64 private constant lifeGainYouth = 365 days; 
    uint64 private constant YouthtoRookieTime = 10 seconds;



    function _RandNumb(uint _rand, uint32 _maxRand, uint32 _offset) private pure returns (uint32) {
        return uint32(_rand % (_maxRand+1-_offset) + _offset); // e.g. max 7, offset 2, means will get 2~7 randomly
    }
    
    //--------------MATHS----------------- SATURATED--------
    function sqrt32b(uint32 y) private pure returns (uint32 z) {
        if (y > 3) {
            z = y;
            uint32 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
    function sub64b(uint64 a, uint64 b) private pure returns (uint64) {
    uint64 c;
        if (b <= a){
        c = a - b;
        } else {
        c = 0;
        }
        return c;
    }

    function add64b(uint64 a, uint64 b) private pure returns (uint64) {
        uint64 c; 
        unchecked {c= a + b;}
        if (c < a){
        c = 18446744073709551615;
        }
        return c;
    }
    function sub32b(uint32 a, uint32 b) private pure returns (uint32) {
    uint32 c;
        if (b <= a){
        c = a - b;
        } else {
        c = 0;
        }
        return c;
    }

    function add32b(uint32 a, uint32 b) private pure returns (uint32) {
        uint32 c; 
        unchecked {c= a + b;}
        if (c < a){
        c = 4294967295;
        }
        return c;
    }
    function sub8b(uint8 a, uint8 b) private pure returns (uint8) {
    uint8 c;
        if (b <= a){
        c = a - b;
        } else {
        c = 0;
        }
        return c;
    }
    function add8b(uint8 a, uint8 b) private pure returns (uint8) {
        uint8 c; 
        unchecked {c= a + b;}
        if (c < a){
        c = 255;
        }
        return c;
    }
    function add9L(uint8 a, uint8 b) private pure returns (uint8) {
        uint8 c; 
        unchecked {c= a + b;}
        if (c < a || c>9){
        c = 9;
        }
        return c;
    }
    function add16B999L(uint16 a, uint16 b) private pure returns (uint16) {
        uint16 c; 
        unchecked {c= a + b;}
        if (c < a || c>999){
        c = 999;
        }
        return c;
    }
    function add32B999999L(uint32 a, uint32 b) private pure returns (uint32) {
        uint32 c; 
        unchecked {c= a + b;}
        if (c < a || c>999999){
        c = 999999;
        }
        return c;
    }
    //-----------------------------------------------------
    /**
    * @dev Mint a Pet egg based on a given random number.
    * @param _deRand The random number used to generate the Pet.
    * @return Pet The newly minted Pet.
    */
    function mintEgg(uint _deRand) external pure returns (A.Pets memory Pet) {
        uint8 _randegg = uint8(_RandNumb(_deRand,2,0));
        if (_randegg >0) {_randegg = _randegg + 1;}
        //33% for each egg
        Pet = A.Pets(
            _randegg, // type of Pet species (egg 0 to 4)
            10**_randegg, // gene
            A.attributes(
                uint8(_RandNumb((_deRand>>8)+(_deRand>>1),150,50)), // happiness
                uint8(_RandNumb((_deRand>>16)+(_deRand>>1),150,50)), // discipline
                0, // id (will be replaced in main function)
                100, // weight
                0 // stage
            ),
            A.powers(
                1, // hitpoints
                1, // strength
                1, // agility
                1 // intellegence
            ),
            0, // exp
            A.timings(
                0, // deadtime
                0, // endurance
                0, // outgoingtime
                0, // stamina
                0 // evolutiontime
            ),
            [0,0,0], // trait
            [0,0,0], // skill
            0, // status (0 = active)
            uint16(_RandNumb((_deRand>>24)+(_deRand>>1),4,0)), // family
            false // shinning (only for evolve, revive reset to false)
        ); 
    }

    function HatchEgg(A.Pets memory _Egg, address _ownerof) //due to story change in last minutes, change into BOX
    external view returns(A.Pets memory Pet) {
        Pet = _Egg;
        require(msg.sender == _ownerof, "xPermission");
        
        require ((Pet.species <=4 ) 
                , "xPetStatusVspecies"); 
        A.powers memory _pwrs;
        uint64 timenow = uint64(block.timestamp);
        if      (Pet.species==4)   {_pwrs = A.powers(28000,76,26,26);}
        else if (Pet.species==3)   {_pwrs = A.powers(47000,85,9,20);} 
        else if (Pet.species==2)   {_pwrs = A.powers(23000,65,38,24);} 
        else if (Pet.species==1)   {_pwrs = A.powers(26000,95,19,10);} 
        else   /*Pet.species==0*/  {_pwrs = A.powers(24000,68,18,40);} 
        Pet.species = Pet.species + 5;
        Pet.attribute.stage = 1;
        Pet.power = _pwrs;
        Pet.time = A.timings (      timenow+lifeGainYouth, //deadtime
                                        timenow+INITIAL_ENDURANCE, //endurance
                                        0, //frozen time
                                        timenow-INITIAL_STAMINA, //stamina
                                        timenow+YouthtoRookieTime //evolutiontime
                                    ); 
    }

    function FeedPet(A.Pets memory _Pet, uint8 _foodtype,address _ownerof) 
    external view returns(A.Pets memory Pet) { //Foodtype 0 to 5
        Pet = _Pet;
        require (Pet.species >4  //not an egg
                , "xPetStatusVspecies"); 
        require(msg.sender == _ownerof, "xPermission");
        uint64 _timenow = uint64(block.timestamp);
        uint64 _full;
        uint32 _weight;
        uint8 _happy;
        if (Pet.time.endurance<_timenow) { //if Pet die of hunger but still has life time
            Pet.time.endurance = _timenow; //revive from hunger then..
        }
        uint64 _enduranceleft = Pet.time.endurance-_timenow;
        if (Pet.time.deadtime >= _timenow && Pet.time.endurance >= _timenow) { //Alive & Active
            //Choose Your Food :p
            if (_foodtype==6){_full = 9 hours; _weight = 9440; _happy = 10;}
            else if (_foodtype==5){_full = 11 hours; _weight = 3135; _happy = 9;} 
            else if (_foodtype==4){_full = 7 hours; _weight = 1662; _happy = 6;} 
            else if (_foodtype==3){_full = 3 hours; _weight = 570; _happy = 3;} 
            else if (_foodtype==2){_full = 12 hours; _weight = 25200; _happy = 11;} 
            else if (_foodtype==1){_full = 8 hours; _weight = 12700; _happy = 8;} 
            else {_full = 4 hours; _weight = 5000; _happy = 5;} 
            //Eating
            Pet.attribute.weight = add32b(Pet.attribute.weight,_weight);
            Pet.time.endurance = add64b(Pet.time.endurance,_full);
            if (Pet.time.endurance-_timenow > FULL_ENDURANCE){ //Your Pet has too full
                Pet.time.endurance = _timenow+FULL_ENDURANCE; //cap at FULL_ENDURANCE
                Pet.attribute.happiness = sub8b(Pet.attribute.happiness,1);
            }else { // normal hours, :) happy
                Pet.attribute.happiness = add8b(Pet.attribute.happiness,_happy);
                //Pet.exp = Pet.exp + uint32(10*(_full));
            }
            Pet.exp = Pet.exp + 170*uint32((Pet.time.endurance-_timenow-_enduranceleft));
        } 
        Pet = EVO.checkEvolve(Pet);
    }

    function trainPet(A.Pets memory _Pet, uint8 _traintype,address _ownerof) 
        external view returns(A.Pets memory Pet) { //TrainType 0 to 7
        Pet = _Pet;
        require (Pet.species >4  //not an egg
                , "xPetStatusVspecies"); 
        require(msg.sender == _ownerof, "xPermission");
        uint64 _timenow = uint64(block.timestamp);
        //trait start first to prevent stack too deep, limitation of Solidity
        if (Pet.time.deadtime > _timenow && Pet.time.endurance > _timenow //Pet still alive
            && Pet.status == 0) { //Alive & Active
            uint64 _stamina = sub64b(_timenow,Pet.time.stamina);
            uint64 _tiredness;
            uint32 _weightloss;
            uint8 _happy;
            uint8 _discipline;
            
            A.powers memory _pwrstemp;
            //Choose Your training routing :p
            if      (_traintype==13){_tiredness = 2 minutes; _weightloss = 600; _happy = 1; _discipline = 3; //reduce HAP, gain DIS
                 _pwrstemp.hitpoints=4000; _pwrstemp.intellegence=30;}//Exercises
            else if (_traintype==12){_tiredness = 2 minutes; _weightloss = 2100; _happy = 1; _discipline = 3; //reduce HAP, gain DIS
                  _pwrstemp.strength=4; _pwrstemp.agility=30;}//Exercises
            else if (_traintype==11){_tiredness = 2 minutes; _weightloss = 1520; _happy = 1; _discipline = 3; //reduce HAP, gain DIS
                 _pwrstemp.strength=30; _pwrstemp.agility=2; _pwrstemp.intellegence=2;}//Exercises
            else if (_traintype==10){_tiredness = 2 minutes; _weightloss = 1920; _happy = 1; _discipline = 3; //reduce HAP, gain DIS
                 _pwrstemp.hitpoints=30000; _pwrstemp.strength=2; _pwrstemp.intellegence=2;}//Exercises
            else if (_traintype==9){_tiredness = 0 minutes; _weightloss = 0; _happy = 0; _discipline = 0; //nothing
                    }
            else if (_traintype==8){_tiredness = 0 minutes; _weightloss = 0; _happy = 0; _discipline = 0; //nothing
                    }
            else if (_traintype==7){_tiredness = 25 minutes; _weightloss = 6251; _happy = 12; _discipline = 26; //reduce HAP, gain DIS
                 _pwrstemp.hitpoints=145000; _pwrstemp.intellegence=280;}//Courses
            else if (_traintype==6){_tiredness = 25 minutes; _weightloss = 23814; _happy = 12; _discipline = 25; //reduce HAP, gain DIS
                  _pwrstemp.strength=100; _pwrstemp.agility=325;}//Running Machine
            else if (_traintype==5){_tiredness = 25 minutes; _weightloss = 17320; _happy = 12; _discipline = 25; //reduce HAP, gain DIS
                 _pwrstemp.strength=305; _pwrstemp.agility=55; _pwrstemp.intellegence=65;}//Wooden Dummy
            else if (_traintype==4){_tiredness = 25 minutes; _weightloss = 11753; _happy = 13; _discipline = 25; //reduce HAP, gain DIS
                  _pwrstemp.hitpoints=305000; _pwrstemp.strength=65; _pwrstemp.intellegence=55;}//sit under waterfall
            else if (_traintype==3){_tiredness = 8 minutes; _weightloss = 2000; _happy = 2; _discipline = 10; //reduce HAP, gain DIS
                 _pwrstemp.hitpoints=36000; _pwrstemp.intellegence=100;}//black board
            else if (_traintype==2){_tiredness = 8 minutes; _weightloss = 7200; _happy = 2; _discipline = 9; //reduce HAP, gain DIS
                  _pwrstemp.strength=26; _pwrstemp.agility=110;}//Sprint
            else if (_traintype==1){_tiredness = 8 minutes; _weightloss = 5420; _happy = 2; _discipline = 9; //reduce HAP, gain DIS
                 _pwrstemp.strength=115; _pwrstemp.agility=5; _pwrstemp.intellegence=16;}//Punching bag
            else /*if (_traintype==0)*/{_tiredness = 8 minutes; _weightloss = 7600; _happy = 3; _discipline = 9; //reduce HAP, gain DIS
                 _pwrstemp.hitpoints=116000; _pwrstemp.strength=10; _pwrstemp.intellegence=10;}//Push bolder
            require(_stamina >= _tiredness, "too tired");
            //traits affect
            (_pwrstemp, _happy, _discipline) = traitAddStateTraining(_tiredness, Pet.trait,_pwrstemp, _happy, _discipline);

            //training 
            Pet.power.hitpoints = add32B999999L(Pet.power.hitpoints,_pwrstemp.hitpoints );
            Pet.power.strength = add16B999L(Pet.power.strength,_pwrstemp.strength );
            Pet.power.agility = add16B999L(Pet.power.agility,_pwrstemp.agility );
            Pet.power.intellegence = add16B999L(Pet.power.intellegence,_pwrstemp.intellegence );
            Pet.attribute.happiness = sub8b(Pet.attribute.happiness,_happy);
            Pet.attribute.discipline = add8b(Pet.attribute.discipline,_discipline);
            Pet.attribute.weight = sub32b(Pet.attribute.weight,_weightloss);
            if (Pet.attribute.weight == 0) {Pet.attribute.weight = 100;} //minimum weight
            //EXP
            Pet.exp = Pet.exp + 320000*uint32(_tiredness/1 minutes);
            //=======capped by FULL STAMINA=======//
            _stamina = sub64b(_stamina, _tiredness);
            if ( _stamina > (FULL_STAMINA-_tiredness)) { 
                Pet.time.stamina = _timenow - FULL_STAMINA+_tiredness;
            } else if (_stamina == 0) {//=0 in unsigned data = stamina go negative! TOO TIRED!
                Pet.time.stamina = add64b(Pet.time.stamina,_tiredness);
            } else {
                Pet.time.stamina = add64b(Pet.time.stamina,_tiredness);
            }
            //============
        }
        Pet = EVO.checkEvolve(Pet);
    }

    function traitAddStateTraining(uint64 _tiredness, uint8[3] memory _traits, A.powers memory _pwrstemp, uint8 _happy, uint8 _discipline) 
    private pure returns(A.powers memory pwrstemp, uint8 happy, uint8 discipline){
        pwrstemp = _pwrstemp;
        happy = _happy;
        discipline = _discipline;
        uint16 _bonushr =  uint16(_tiredness/1 minutes); //tireness from Praise and Scold is 0, so Traits wont adds anything
        for (uint256 i; i < 3; i++) {
                if      (_traits[i] == 1) {pwrstemp.hitpoints = pwrstemp.hitpoints + 800*_bonushr;} //Tough
                else if (_traits[i] == 2) {pwrstemp.strength= pwrstemp.strength +(8*_bonushr)/10;} //Brawler
                else if (_traits[i] == 3) {pwrstemp.agility =pwrstemp.agility +(8*_bonushr)/10;} //Nimble
                else if (_traits[i] == 4) {pwrstemp.intellegence = _pwrstemp.intellegence+(8*_bonushr)/10;} //Smart
                //battletrait 5,6
                else if (_traits[i] == 7) {happy = happy+(15*uint8(_bonushr))/10;} //Hardworking
                else if (_traits[i] == 8) {discipline = discipline+(15*uint8(_bonushr))/10;} //Serious
                //battletrait 9,10,11
                else if (_traits[i] == 12) {pwrstemp.strength = pwrstemp.strength +(3*_bonushr)/10;} //Lonely
                else if (_traits[i] == 13) {pwrstemp.strength = pwrstemp.strength +(4*_bonushr)/10;} //Bashful
                else if (_traits[i] == 14) {pwrstemp.strength = pwrstemp.strength +(5*_bonushr)/10;} //Adamant
                else if (_traits[i] == 15) {pwrstemp.strength = pwrstemp.strength +(6*_bonushr)/10;} //Naughty
                else if (_traits[i] == 16) {pwrstemp.strength = pwrstemp.strength +(7*_bonushr)/10;} //Brave
                else if (_traits[i] == 17) {pwrstemp.agility = pwrstemp.agility +(3*_bonushr)/10;} //Timid
                else if (_traits[i] == 18) {pwrstemp.agility = pwrstemp.agility +(4*_bonushr)/10;} //Hasty
                else if (_traits[i] == 19) {pwrstemp.agility = pwrstemp.agility +(5*_bonushr)/10;} //Jolly
                else if (_traits[i] == 20) {pwrstemp.agility = pwrstemp.agility +(6*_bonushr)/10;} //Naive
                else if (_traits[i] == 21) {pwrstemp.agility = pwrstemp.agility +(7*_bonushr)/10;} //Quirky
                else if (_traits[i] == 22) {pwrstemp.intellegence = pwrstemp.intellegence +(3*_bonushr)/10;} //Mild
                else if (_traits[i] == 23) {pwrstemp.intellegence = pwrstemp.intellegence +(4*_bonushr)/10;} //Quiet
                else if (_traits[i] == 24) {pwrstemp.intellegence = pwrstemp.intellegence +(5*_bonushr)/10;} //Rash
                else if (_traits[i] == 25) {pwrstemp.intellegence = pwrstemp.intellegence +(6*_bonushr)/10;} //Modest
                else if (_traits[i] == 26) {pwrstemp.intellegence = pwrstemp.intellegence +(7*_bonushr)/10;} //Docile
                else if (_traits[i] == 27) {pwrstemp.hitpoints = pwrstemp.hitpoints + 300*_bonushr;} //Relaxed
                else if (_traits[i] == 28) {pwrstemp.hitpoints = pwrstemp.hitpoints + 400*_bonushr;} //Bold
                else if (_traits[i] == 29) {pwrstemp.hitpoints = pwrstemp.hitpoints + 500*_bonushr;} //Impish
                else if (_traits[i] == 30) {pwrstemp.hitpoints = pwrstemp.hitpoints + 600*_bonushr;} //Lax
                else if (_traits[i] == 31) {pwrstemp.hitpoints = pwrstemp.hitpoints + 700*_bonushr;} //Careful
            }
    }

    function battlingPet(uint8 rank, uint rand) external pure returns(A.Pets memory _BattlingPet) {
        //rank 0 = stage1, 1= stage2, 2= stage3, 3=stage4 3->8->17->37
        _BattlingPet.attribute.id = 10001;
        _BattlingPet.attribute.stage = rank+1;
        _BattlingPet.family = uint16(_RandNumb((rand>>4)+(rand>>1),4,0));
        if (rank ==0 ) { 
            _BattlingPet.species = 8;
            _BattlingPet.attribute.weight = _RandNumb((rand>>5)+(rand>>1),2500,1000);
            _BattlingPet.power.hitpoints = _RandNumb((rand>>21)+(rand>>1),40000,10000);
            _BattlingPet.power.strength = uint16(_RandNumb((rand>>41)+(rand>>1),50,40));
            _BattlingPet.power.agility = uint16(_RandNumb((rand>>51)+(rand>>1),50,10));
            _BattlingPet.power.intellegence = uint16(_RandNumb((rand>>61)+(rand>>1),50,10));
        } else if (rank == 1) {
            _BattlingPet.species = 17;
            _BattlingPet.attribute.weight = _RandNumb((rand>>5)+(rand>>1),4500,1500);
            _BattlingPet.power.hitpoints = _RandNumb((rand>>21)+(rand>>1),130000,5000);
            _BattlingPet.power.strength = uint16(_RandNumb((rand>>41)+(rand>>1),130,95));
            _BattlingPet.power.agility = uint16(_RandNumb((rand>>51)+(rand>>1),130,55));
            _BattlingPet.power.intellegence = uint16(_RandNumb((rand>>61)+(rand>>1),130,55));
            _BattlingPet.skill = [17,0,0];
        } else if (rank == 2) {
            _BattlingPet.species = 37; 
            _BattlingPet.attribute.weight = _RandNumb((rand>>5)+(rand>>1),17500,1500);
            _BattlingPet.power.hitpoints = _RandNumb((rand>>21)+(rand>>1),420000,145000);
            _BattlingPet.power.strength = uint16(_RandNumb((rand>>41)+(rand>>1),350,195));
            _BattlingPet.power.agility = uint16(_RandNumb((rand>>51)+(rand>>1),350,155));
            _BattlingPet.power.intellegence = uint16(_RandNumb((rand>>61)+(rand>>1),450,155));
            _BattlingPet.skill = [17,37,0];    
        } else /*if (rank == 3)*/{
            _BattlingPet.species = 54;
            _BattlingPet.attribute.weight = _RandNumb((rand>>5)+(rand>>1),25000,1500);
            _BattlingPet.power.hitpoints = _RandNumb((rand>>21)+(rand>>1),800000,275000);
            _BattlingPet.power.strength = uint16(_RandNumb((rand>>41)+(rand>>1),590,295));
            _BattlingPet.power.agility = uint16(_RandNumb((rand>>51)+(rand>>1),590,275));
            _BattlingPet.power.intellegence = uint16(_RandNumb((rand>>61)+(rand>>1),790,275));
            _BattlingPet.skill = [17,37,54];   
        }
    }

    function TowerPet(uint32 TowerLevel, uint _deRand) external pure returns(A.Pets memory _TowerPet, uint8[4] memory _chances, uint8 _nextTowerLevel) {
        //rank 0 = stage1, 1= stage2, 2= stage3, 3=stage4
        _TowerPet.attribute.id = 10001;
        //TowerLevel 1~20 = level1, 10 level max. so stage 1 to 4, 2.5 stage each.
        //Towerlevel/41 = stage, max TowerLevel 200, = stage 4 (rounded)
        //e.g. level 1 and 2 = stage 1, 
        _TowerPet.attribute.stage = uint8(((TowerLevel*10)+801)/601); //stage: 1 1 2 2 2 3 3 3 4 4 
        _TowerPet.family = uint8(TowerLevel%5); //0 to 4
        /* chances for 30 Artifact according to rarity
        stage   ratio   15  9   6   30
        1       1       8   1   0   
        2       1       7   2   0   
        3       1       6   2   1   
        4       1       6   2   1   
        5       1       5   3   1   
        6       0       5   4   1   
        7       0       4   4   2   
        8       0       1   6   3   
        9       0       0   5   5   
        sum		        42	29	24	95
	    ratio	       13.2 9.1 7.5	 common chances is low by assuming most people cant reach level 10
        */
        if (TowerLevel <= 20 ) { //level1 stage 1
            _TowerPet.species = 5;
            _TowerPet.power.hitpoints = 15000+TowerLevel*700;
            _TowerPet.power.strength = uint16(10+((TowerLevel*75)%50));
            _TowerPet.power.agility = uint16(10+((TowerLevel*88)%50));
            _TowerPet.power.intellegence = uint16(10+((TowerLevel*33)%50));
            _chances = [1,8,1,0];
            _nextTowerLevel = uint8(_RandNumb(_deRand,60,41)); //intentionally skip
        } else if (TowerLevel <= 40 ) { //level2 stage 1
            _TowerPet.species = 7;
            _TowerPet.power.hitpoints = 18000+((TowerLevel*900)%18000);
            _TowerPet.power.strength = uint16(30+((TowerLevel*75)%50));
            _TowerPet.power.agility = uint16(30+((TowerLevel*88)%50));
            _TowerPet.power.intellegence = uint16(30+((TowerLevel*33)%50));
            _chances = [1,7,2,0];
            _nextTowerLevel = uint8(_RandNumb(_deRand,80,41));
        } else if (TowerLevel <= 60 ) { //level3 stage 2
            _TowerPet.species = 10;
            _TowerPet.power.hitpoints = 35000+((TowerLevel*1900)%30000);
            _TowerPet.power.strength = uint16(70+((TowerLevel*75)%70));
            _TowerPet.power.agility = uint16(70+((TowerLevel*88)%70));
            _TowerPet.power.intellegence = uint16(70+((TowerLevel*33)%70));
            _TowerPet.skill = [10,0,0]; 
            _chances = [1,6,2,1];
            _nextTowerLevel = uint8(_RandNumb(_deRand,100,81)); //skip
        } else if (TowerLevel <= 80 ) { //level4 stage 2
            _TowerPet.species = 16;
            _TowerPet.power.hitpoints = 70000+((TowerLevel*1900)%70000);
            _TowerPet.power.strength = uint16(100+((TowerLevel*75)%100));
            _TowerPet.power.agility = uint16(100+((TowerLevel*88)%100));
            _TowerPet.power.intellegence = uint16(120+((TowerLevel*33)%120));
            _TowerPet.skill = [16,0,0]; 
            _chances = [1,6,2,1];
            _nextTowerLevel = uint8(_RandNumb(_deRand,120,81));
        } else if (TowerLevel <= 100 ) { //level5 stage 2
            _TowerPet.species = 17;
            _TowerPet.power.hitpoints = 100000+((TowerLevel*1900)%70000);
            _TowerPet.power.strength = uint16(150+((TowerLevel*75)%100));
            _TowerPet.power.agility = uint16(150+((TowerLevel*88)%100));
            _TowerPet.power.intellegence = uint16(180+((TowerLevel*33)%120));
            _TowerPet.skill = [17,0,0]; 
            _chances = [1,5,3,1];
            _nextTowerLevel = uint8(_RandNumb(_deRand,140,121));
        } else if (TowerLevel <= 120 ) { //level6 stage 3
            _TowerPet.species = 23;
            _TowerPet.power.hitpoints = 250000+((TowerLevel*1900)%130000);
            _TowerPet.power.strength = uint16(220+((TowerLevel*75)%100));
            _TowerPet.power.agility = uint16(220+((TowerLevel*88)%100));
            _TowerPet.power.intellegence = uint16(350+((TowerLevel*33)%120));
            _TowerPet.skill = [10,23,0]; 
            _chances = [0,5,4,1];
            _nextTowerLevel = uint8(_RandNumb(_deRand,160,121));
        } else if (TowerLevel <= 140 ) { //level7 stage 3
            _TowerPet.species = 30;
            _TowerPet.power.hitpoints = 350000+((TowerLevel*1900)%170000);
            _TowerPet.power.strength = uint16(350+((TowerLevel*75)%100));
            _TowerPet.power.agility = uint16(350+((TowerLevel*88)%100));
            _TowerPet.power.intellegence = uint16(550+((TowerLevel*33)%120));
            _TowerPet.skill = [16,30,0];
            _chances = [0,4,4,2]; 
            _nextTowerLevel = uint8(_RandNumb(_deRand,180,161));
        } else if (TowerLevel <= 160 ) { //level8 stage 3
            _TowerPet.species = 37;
            _TowerPet.power.hitpoints = 450000+((TowerLevel*1900)%270000);
            _TowerPet.power.strength = uint16(450+((TowerLevel*75)%150));
            _TowerPet.power.agility = uint16(450+((TowerLevel*88)%150));
            _TowerPet.power.intellegence = uint16(660+((TowerLevel*33)%120));
            _TowerPet.skill = [17,37,0]; 
            _chances = [0,1,6,3];
            _nextTowerLevel = uint8(_RandNumb(_deRand,200,161));
        } else if (TowerLevel <= 180 ) { //level9 stage 4
            _TowerPet.species = 44;
            _TowerPet.power.hitpoints = 600000+((TowerLevel*1900)%300000);
            _TowerPet.power.strength = uint16(600+((TowerLevel*75)%150));
            _TowerPet.power.agility = uint16(600+((TowerLevel*88)%150));
            _TowerPet.power.intellegence = uint16(730+((TowerLevel*33)%120));
            _TowerPet.skill = [10,23,44]; 
            _chances = [0,0,5,5];
            _nextTowerLevel = uint8(_RandNumb(_deRand,200,181));
        } else if (TowerLevel <= 200 ) { //level10 stage 4
            _TowerPet.species = 54;
            _TowerPet.power.hitpoints = 900000+((TowerLevel*1900)%100000);
            _TowerPet.power.strength = uint16(900+((TowerLevel*75)%100));
            _TowerPet.power.agility = uint16(900+((TowerLevel*88)%100));
            _TowerPet.power.intellegence = uint16(900+((TowerLevel*33)%100));
            _TowerPet.skill = [17,37,54]; 
            _chances = [0,0,0,10];
            _nextTowerLevel = uint8(_RandNumb(_deRand,20,1));
        }
    }

    function battlePet(uint _deRand, A.Pets memory _Pet1, A.Pets memory _Pet2) 
    //check owner at main, because simulation need permissionless
    external pure returns(bool Mon1Win, uint BattleRhythm, uint8 bit, uint64 OppoDamage) { 
        //---- The BattleRythm is 256 bits encoded 85 actions(3bits [1bit attacker, 2bits skill]), 
        // ---- so the battle ended after 85 turns or either one has 0 HP---------------- 
        //whoever has more HP left win, if same HP, Pet2 win. NO DRAW -----------//
        uint32 damage;
        uint32 effort;
        uint32 actionpoints1 = _Pet2.power.agility; //reverse, Pet2 slow, means Pet1 attack more times
        uint32 actionpoints2 = _Pet1.power.agility;
        uint8 weakness; //0 = nothing, 1 = more damage on Pet1, 2= more daamge on Pet2
                //0 = Red, 1=Yellow, 2=Green, 3=Blue, 4=Purple
        //Yellow==Purple==Red==Green==Blue
        //1.2x against
	    //Blue==Yellow==Green==Purple==Red
        if ( (_Pet1.family == 3 && _Pet2.family == 1) //Blue weaks against Yellow
           ||(_Pet1.family == 1 && _Pet2.family == 4) //Yellow weaks against Purple
           ||(_Pet1.family == 2 && _Pet2.family == 0) //Green weaks against Red
           ||(_Pet1.family == 4 && _Pet2.family == 2) //Purple weaks against Green
           ||(_Pet1.family == 0 && _Pet2.family == 3) //Red weaks against Blue
        ) 
        {weakness = 1;}
        //---
        if ( (_Pet2.family == 3 && _Pet1.family == 1) //Blue weaks against Yellow
           ||(_Pet2.family == 1 && _Pet1.family == 4) //Yellow weaks against Purple
           ||(_Pet2.family == 2 && _Pet1.family == 0) //Green weaks against Red
           ||(_Pet2.family == 4 && _Pet1.family == 2) //Purple weaks against Green
           ||(_Pet2.family == 0 && _Pet1.family == 3) //Red weaks against Blue
        ) 
        {weakness = 2;}
        // because who has less actionpoints move next
        //while<= 253 bit 1round 3 bit 15 rounds, means 45 bit
        while (bit<=253 && _Pet1.power.hitpoints > 0 && _Pet2.power.hitpoints > 0 ){
            if (actionpoints1 <= actionpoints2) { //Pet1 move
                bit++; //bit ++ first, means set '0'
                _deRand = (_deRand>>3)+(_deRand>>1);
                (BattleRhythm,effort,damage)=_chooseSkill(_deRand,_Pet1,BattleRhythm,bit);
                bit=bit+2; //2bits has set in the function above for skill.
                actionpoints1 = actionpoints1 + effort +  _Pet2.power.agility; // purposely reverse Pet2 agi to action 1
                if (weakness == 2) {damage = damage*2;}
                _Pet2.power.hitpoints = sub32b(_Pet2.power.hitpoints,damage);
                OppoDamage += damage;
            } else { //Pet2 move
                BattleRhythm = BattleRhythm + 2**bit; //encode who attack, 1 = Pet2 attack
                bit++; //bit++ before set, means set '1'
                _deRand = (_deRand>>3)+(_deRand>>1);
                (BattleRhythm,effort,damage)=_chooseSkill(_deRand,_Pet2,BattleRhythm,bit);
                bit=bit+2; //2bits has set in the function above.
                actionpoints2 = actionpoints2 + effort +  _Pet1.power.agility; // purposely reverse Pet1 agi to action 2
                if (weakness == 1) {damage = damage*2;}
                _Pet1.power.hitpoints = sub32b(_Pet1.power.hitpoints,damage);
            }
        }
        if (_Pet1.power.hitpoints >= _Pet2.power.hitpoints) {Mon1Win = true;} else {Mon1Win = false;}
        
    }
    function _chooseSkill(uint _deRand, A.Pets memory _Pet, uint _BattleRhythm, uint8 _bit)
    private pure returns( uint BattleRhythm, uint32 effort, uint32 damage) {
        uint8 skill;
        BattleRhythm = _BattleRhythm;
        if (_RandNumb(_deRand,1300,1) <= 301+uint16(_Pet.power.intellegence)) { //use skills based 23% chances
            skill = uint8(_RandNumb((_deRand>>3)+(_deRand>>1),2,0)); //translate to skill array 0 1 2
            //skill == 0 means no need to set anything on skill (00)
            if (skill == 1) {BattleRhythm = BattleRhythm + 2**_bit;} //binary 00 (01) 10, set LSB
            _bit++;
            if (skill == 2) {BattleRhythm = BattleRhythm + 2**_bit;} //binary 00 01 (10), set MSB
            //no need _bit++ as _bit won't return
            (damage,effort) = _SkillsState(_Pet.power,_Pet.attribute, _Pet.skill[skill]);
        } else {//normal attack, also encoded as skill array (11), Skill[3] always normal attack
            BattleRhythm = BattleRhythm + 2**_bit;
            _bit++;
            BattleRhythm = BattleRhythm + 2**_bit;
            damage = _Pet.power.strength;
            damage = damage * 50;
            effort = 100;
        } 
        
    }
    function _SkillsState(A.powers memory _powers, A.attributes memory _attributes, uint8 SkillNumber)
    private pure returns(uint32 damage, uint32 effort) {
        // you won't get a skill before Stage 2
        uint64 HP = _powers.hitpoints;
        uint32 STR = _powers.strength;
        uint32 AGI = _powers.agility;
        uint32 INT = _powers.intellegence;
        uint32 HAPPINESS = _attributes.happiness;
        uint32 DISCIPLINE = _attributes.discipline;
        if (SkillNumber == 0) {damage=STR*50; effort = 100;}
        else if (SkillNumber == 10) {damage= 50*STR + 35*AGI ; effort = 160;}   ///------- use this
        else if (SkillNumber == 11) {damage= 85*STR + 15*INT ; effort = 155;}
        else if (SkillNumber == 12) {damage= 115*STR ; effort = 200;}
        else if (SkillNumber == 13) {damage= 30*STR + 30*AGI + 30*INT ; effort = 150;}
        else if (SkillNumber == 14) {damage= 105*STR ; effort = 190;}
        else if (SkillNumber == 15) {damage= 40*STR + 63*AGI ; effort = 160;}
        else if (SkillNumber == 16) {damage= 40*STR + 60*AGI ; effort = 170;}   ///------- use this
        else if (SkillNumber == 17) {damage= 80*STR + 35*INT ; effort = 195;}   ///------- use this
        else if (SkillNumber == 18) {damage= 90*STR + 40*INT ; effort = 220;}
        else if (SkillNumber == 19) {damage= 50*STR + 100*INT ; effort = 230;}
        else if (SkillNumber == 20) {damage= 150*STR ; effort = 230;}
        else if (SkillNumber == 21) {damage= 50*STR + 100*AGI ; effort = 230;}
        else if (SkillNumber == 22) {damage= 50*STR + 50*AGI + 50*INT ; effort = 230;}
        else if (SkillNumber == 23) {damage= 75*STR + 125*AGI ; effort = 265;}   ///------- use this
        else if (SkillNumber == 24) {damage= 135*STR + 75*AGI ; effort = 270;}
        else if (SkillNumber == 25) {damage= 200*AGI ; effort = 266;}
        else if (SkillNumber == 26) {damage= uint32((14*HP)/100) + 125*STR ; effort = 287;}
        else if (SkillNumber == 27) {damage= 90*STR + 90*AGI + 90*INT ; effort = 330;}
        else if (SkillNumber == 28) {damage= 225*STR ; effort = 290;}
        else if (SkillNumber == 29) {damage= 50*STR + 125*AGI ; effort = 258;}
        else if (SkillNumber == 30) {damage= 90*STR + 110*AGI ; effort = 277;}   ///------- use this
        else if (SkillNumber == 31) {damage= 150*STR + 50*AGI ; effort = 302;}
        else if (SkillNumber == 32) {damage= 165*STR + 175*DISCIPLINE ; effort = 298;}
        else if (SkillNumber == 33) {damage= 185*INT ; effort = 244;}
        else if (SkillNumber == 34) {damage= 55*STR + 140*INT ; effort = 280;}
        else if (SkillNumber == 35) {damage= 250*STR ; effort = 295;}
        else if (SkillNumber == 36) {damage= 210*STR ; effort = 300;}
        else if (SkillNumber == 37) {damage= uint32((15*HP)/100) + 125*STR ; effort = 310;}   ///------- use this
        else if (SkillNumber == 38) {damage= 125*STR + 40*AGI + 40*INT ; effort = 275;}
        else if (SkillNumber == 39) {damage= 185*STR + 50*AGI ; effort = 295;}
        else if (SkillNumber == 40) {damage= 158*STR + 50*AGI + 25*INT ; effort = 287;}
        else if (SkillNumber == 41) {damage= 160*STR + 50*INT + 175*HAPPINESS ; effort = 320;}
        else if (SkillNumber == 42) {damage= 160*STR +50*INT + 175*DISCIPLINE ; effort = 315;}
        else if (SkillNumber == 43) {damage= 185*STR + 100*AGI ; effort = 380;}
        else if (SkillNumber == 44) {damage= 170*STR + 170*INT ; effort = 395;}   ///------- use this
        else if (SkillNumber == 45) {damage= uint32((25*HP)/100) + 100*STR ; effort = 376;}
        else if (SkillNumber == 46) {damage= 150*STR + 150*INT ; effort = 380;}
        else if (SkillNumber == 47) {damage= 325*STR ; effort = 400;}
        else if (SkillNumber == 48) {damage= 150*STR + 125*AGI + 50*INT ; effort = 375;}
        else if (SkillNumber == 49) {damage= 125*STR + 125*AGI + 125*INT ; effort = 450;}
        else if (SkillNumber == 50) {damage= 175*AGI + 100*INT + 200*HAPPINESS ; effort = 380;}
        else if (SkillNumber == 51) {damage= 75*STR + 200*INT + 250*DISCIPLINE ; effort = 385;}
        else if (SkillNumber == 52) {damage= 150*STR + 125*AGI + 175*HAPPINESS ; effort = 370;}
        else if (SkillNumber == 53) {damage= 175*STR + 700*DISCIPLINE ; effort = 395;}
        else if (SkillNumber == 54) {damage= 200*STR + 150*INT ; effort = 450;}   ///------- use this
        else if (SkillNumber == 55) {damage= 115*STR + 115*AGI + 115*INT ; effort = 400;}
        else if (SkillNumber == 56) {damage= 150*STR + 150*INT ; effort = 375;}
        else if (SkillNumber == 57) {damage= 125*STR + 100*STR + 100*INT ; effort = 360;}   ///------- use this
        else if (SkillNumber == 58) {damage= 60*STR + 75*INT + 750*HAPPINESS ; effort = 380;}
        else if (SkillNumber == 59) {damage= 345*INT ; effort = 400;}
        else if (SkillNumber == 60) {damage= 225*STR + 85*AGI ; effort = 360;}
        else if (SkillNumber == 61) {damage= 160*STR + 160*INT ; effort = 380;}
        else if (SkillNumber == 62) {damage= 125*STR + 200*INT ; effort = 385;}
        else if (SkillNumber == 63) {damage= 125*STR + 125*AGI + 125*INT ; effort = 400;}
    }

    function battlewinlosereward(A.Pets memory _Pet, bool _win, uint8 _rank) external view 
    returns (A.Pets memory Pet){
        Pet = _Pet;
        uint32 _exp;
        A.powers memory _pwrstemp;
        uint8 _happy;
        uint8 _discipline;
        uint32 _weight;
        if ( _rank >= 4 ) { //means not fight training
            if (_win == true) { // if won
            
                _exp = 1620000;
                _pwrstemp.hitpoints =15000;
                _pwrstemp.strength =15;
                _pwrstemp.agility =15;
                _pwrstemp.intellegence =15;
                Pet.attribute.happiness = add8b(Pet.attribute.happiness,10);
                _discipline =5;
                _weight =3815;
                
            } else { //lose...
                _exp = 950000;
                _pwrstemp.hitpoints =6000;
                _pwrstemp.strength =6;
                _pwrstemp.agility =6;
                _pwrstemp.intellegence =6;
                Pet.attribute.happiness = sub8b(Pet.attribute.happiness,10);
                _discipline =5;
                _weight =3815;
            }
            (_pwrstemp, _happy, _discipline) = traitAddStateBattle(2 minutes, Pet.trait,_pwrstemp, _happy, _discipline);
        
            Pet.exp = add32b(Pet.exp,_exp); 
            Pet.power.hitpoints = add32B999999L(Pet.power.hitpoints,_pwrstemp.hitpoints);
            Pet.power.strength = add16B999L(Pet.power.strength,_pwrstemp.strength);
            Pet.power.agility = add16B999L(Pet.power.agility,_pwrstemp.agility);
            Pet.power.intellegence = add16B999L(Pet.power.intellegence,_pwrstemp.intellegence);
            Pet.attribute.happiness = add8b(Pet.attribute.happiness,_happy);
            Pet.attribute.discipline = add8b(Pet.attribute.discipline,_discipline);
            Pet.attribute.weight = sub32b(Pet.attribute.weight,_weight);
        }
        Pet = EVO.checkEvolve(Pet);
    }

    function traitAddStateBattle(uint64 _tiredness, uint8[3] memory _traits, A.powers memory _pwrstemp, uint8 _happy, uint8 _discipline) 
    private pure returns(A.powers memory pwrstemp, uint8 happy, uint8 discipline){
        pwrstemp = _pwrstemp;
        happy = _happy;
        discipline = _discipline;
        uint16 _bonushr =  uint16(_tiredness/1 minutes);
        for (uint256 i; i < 3; i++) {
                //training trait 1 to 4
                if      (_traits[i] == 5) { pwrstemp.hitpoints = pwrstemp.hitpoints + 100; //Pride
                                            pwrstemp.strength= pwrstemp.strength + 2;
                                            pwrstemp.agility = pwrstemp.agility + 2;
                                            pwrstemp.intellegence = pwrstemp.intellegence + 2;
                                        } 
                else if (_traits[i] == 6) { pwrstemp.hitpoints = pwrstemp.hitpoints + 1000; //Resilient
                                            pwrstemp.strength= pwrstemp.strength + 1;
                                            pwrstemp.agility = pwrstemp.agility + 1;
                                            pwrstemp.intellegence = pwrstemp.intellegence + 1;
                                        }  
                else if (_traits[i] == 7) {happy = happy+(15*uint8(_bonushr))/10;} //Hardworking
                else if (_traits[i] == 8) {discipline = discipline+(15*uint8(_bonushr))/10;} //Serious
                
                else if (_traits[i] == 9) {pwrstemp.intellegence = pwrstemp.intellegence +_bonushr;} //Creative
                else if (_traits[i] == 10) {pwrstemp.strength = pwrstemp.strength +_bonushr;} //Ambitious
                else if (_traits[i] == 11) {pwrstemp.agility = pwrstemp.agility +_bonushr;} //Multitasking

                else if (_traits[i] == 12) {pwrstemp.strength = pwrstemp.strength +(3*_bonushr)/10;} //Lonely
                else if (_traits[i] == 13) {pwrstemp.strength = pwrstemp.strength +(4*_bonushr)/10;} //Bashful
                else if (_traits[i] == 14) {pwrstemp.strength = pwrstemp.strength +(5*_bonushr)/10;} //Adamant
                else if (_traits[i] == 15) {pwrstemp.strength = pwrstemp.strength +(6*_bonushr)/10;} //Naughty
                else if (_traits[i] == 16) {pwrstemp.strength = pwrstemp.strength +(7*_bonushr)/10;} //Brave
                else if (_traits[i] == 17) {pwrstemp.agility = pwrstemp.agility +(3*_bonushr)/10;} //Timid
                else if (_traits[i] == 18) {pwrstemp.agility = pwrstemp.agility +(4*_bonushr)/10;} //Hasty
                else if (_traits[i] == 19) {pwrstemp.agility = pwrstemp.agility +(5*_bonushr)/10;} //Jolly
                else if (_traits[i] == 20) {pwrstemp.agility = pwrstemp.agility +(6*_bonushr)/10;} //Naive
                else if (_traits[i] == 21) {pwrstemp.agility = pwrstemp.agility +(7*_bonushr)/10;} //Quirky
                else if (_traits[i] == 22) {pwrstemp.intellegence = pwrstemp.intellegence +(3*_bonushr)/10;} //Mild
                else if (_traits[i] == 23) {pwrstemp.intellegence = pwrstemp.intellegence +(4*_bonushr)/10;} //Quiet
                else if (_traits[i] == 24) {pwrstemp.intellegence = pwrstemp.intellegence +(5*_bonushr)/10;} //Rash
                else if (_traits[i] == 25) {pwrstemp.intellegence = pwrstemp.intellegence +(6*_bonushr)/10;} //Modest
                else if (_traits[i] == 26) {pwrstemp.intellegence = pwrstemp.intellegence +(7*_bonushr)/10;} //Docile
                else if (_traits[i] == 27) {pwrstemp.hitpoints = pwrstemp.hitpoints + 300*_bonushr;} //Relaxed
                else if (_traits[i] == 28) {pwrstemp.hitpoints = pwrstemp.hitpoints + 400*_bonushr;} //Bold
                else if (_traits[i] == 29) {pwrstemp.hitpoints = pwrstemp.hitpoints + 500*_bonushr;} //Impish
                else if (_traits[i] == 30) {pwrstemp.hitpoints = pwrstemp.hitpoints + 600*_bonushr;} //Lax
                else if (_traits[i] == 31) {pwrstemp.hitpoints = pwrstemp.hitpoints + 700*_bonushr;} //Careful
            }
    }


}





// File: @openzeppelin/[email protected]/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: @openzeppelin/[email protected]/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/[email protected]/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/[email protected]/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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

// File: @openzeppelin/[email protected]/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/[email protected]/utils/introspection/IERC165.sol


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

// File: @openzeppelin/[email protected]/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/[email protected]/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/[email protected]/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/[email protected]/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/[email protected]/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

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
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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
        address owner = ERC721.ownerOf(tokenId);

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
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

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
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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

// File: @openzeppelin/[email protected]/token/ERC721/extensions/ERC721Burnable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;



/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }
}

// File: @openzeppelin/[email protected]/token/ERC721/extensions/ERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
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
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
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
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
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
        uint256 length = ERC721.balanceOf(to);
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

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
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
}

// File: contracts/Main.sol


pragma solidity ^0.8.9;








/**
 * @title IERC2981
 * @dev Interface for the ERC2981: NFT Royalty Standard extension, which extends the ERC721 standard.
 */
interface IERC2981 is IERC165 {

  /**
   * @notice Called with the sale price to determine how much royalty is owed and to whom.
   * @param _tokenId - The ID of the NFT asset queried for royalty information.
   * @param _salePrice - The sale price of the NFT asset specified by _tokenId.
   * @return receiver - Address of who should be sent the royalty payment.
   * @return royaltyAmount - The royalty payment amount for _salePrice.
   */
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view
    returns (address receiver, uint256 royaltyAmount);
} 

interface ContractArtifactInterface {
    function rewardSystem (uint8[4] calldata , address , uint) external;
    function getEquipedArtifactsEffects(address) external view returns (uint32[4] memory);
}





contract Main is ERC721Enumerable, ERC721Burnable, Ownable {
    constructor() ERC721("FantomAdventureRPG", "FARPG") {
        setImageURL("https://ipfs.io/ipfs/QmTuURiwRkvk6CSLGDphTcTVqjhVNyz2yfPzcdBkzGNmvY/");
        setImageExtension(".gif");
    
    }
    
   //----------------------- Overribes Functions ---------------------------------------
    /**
    * @dev Overrides the _beforeTokenTransfer function from ERC721 and ERC721Enumerable.
    * @param from - The address from which the token will be transferred.
    * @param to - The address to which the token will be transferred.
    * @param tokenId - The ID of the token to be transferred.
    */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) 
        internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
    * @dev Checks if the contract implements the ERC2981 interface and returns true if it does.
    * @param interfaceId - The interface ID to check for support.
    * @return A boolean indicating whether the contract supports the ERC2981 interface or not.
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) 
        returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
    //----------------------------------------------------------------------------

    uint16 private constant MAX_MINTABLE = 9999;
    uint16 private constant MAX_PER_ATTEMPT = 5;
    uint16 private constant MINTPRICE = 0;
    
    uint16 private constant BATTLESTAMINA = 2 minutes;
    

    uint256 private tokenIdTracker;

    string public baseTokenURI; //in case metadata server/IPFS dead before FTM
    string public imageURL; //in case image server/IPFS dead before FTM
    string public imageExtension;
    bool public namebyID = true;
    
    //TowerLevel 0 is havent start. 1 to 20 is level one.
    // 21 to 40 is level two, and so on. to 181 to 200 for level 10. 
    mapping (address => uint8) public TowerLevel; 
    mapping (address => uint32) public TowerResetCd; 
    mapping (uint => uint8) public DailyMaxReward;
    mapping (uint => uint64) public RewardLimitTimer;
    A.Pets[MAX_MINTABLE] public Pet;

    // artifact contract, that can be used to reward players from this contract
    ContractArtifactInterface ArtifactContract; //need global, other functions need it.
    bool confirmed;


    event Result(uint256 indexed id, bool won, uint256 hash, A.Pets selfOrBefore, A.Pets opponOrAfter, uint64 damage, uint bit);
    event StatChangedResult(A.Pets AfterMon);

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }
    //--------------------------------- MINTING FUNCTIONS ------------------------------------
    /**
    * @dev Mints a new Pet to the specified address.
    *
    * @param _to The address to mint the Pet to.
    */
    function _mint(address _to) private {
        // Get the next available token ID.
        uint id = tokenIdTracker;
        tokenIdTracker++;

        // Generate a random number for the Pet's attributes.
        uint _rand = uint(keccak256(abi.encodePacked(msg.sender, block.timestamp,block.coinbase)));

        // Mint the Pet.
        Pet[id] = core.mintEgg(_rand >> ((tokenIdTracker % 50) * 3)); //>>((tokenIdTracker%15)*3)
        Pet[id].attribute.id = uint16(id);
        _safeMint(_to, id);

        // Emit a StatChangedResult event.
        emit StatChangedResult(Pet[id]);
    }

    function isContractAddress(address _address) internal view returns (bool) {
        uint32 size;
        assembly {
         size := extcodesize(_address)
        }
        return (size > 0);
    }

    function mint(address _to, uint256 _count) public payable {
    // Check that the total number of Pets to mint does not exceed the maximum.
        require(!isContractAddress(msg.sender), "Contract addresses are not allowed");
        require(balanceOf(_to) <= 20, "MAXIMUM MINT 20 EGGS PER ADDRESS FOR NOW");
        require((tokenIdTracker + _count <= MAX_MINTABLE) && //error.exceed total MAX mintable
                (_count <= MAX_PER_ATTEMPT) && //error.exceed multi-mint max limit
                (msg.value >= _count * MINTPRICE)); //error.less than needed total mint cost

        // Mint the Pets.
        for (uint256 i = 0; i < _count; i++) {
            _mint(_to);
        }
    }

    //----------------------- Raise Functions ---------------------------------------
    function HatchEgg(uint _id) public { //owner,trainer check in function
        Pet[_id] = core.HatchEgg(Pet[_id], ownerOf(_id));
    }
    function feedsPet(uint _id, uint8 _foodtype) public payable { //owner,trainer check in function
        Pet[_id] = core.FeedPet(Pet[_id], _foodtype,ownerOf(_id)); //requirement check on lib
        emit StatChangedResult(Pet[_id]);
    }
    function trainsPet(uint _id, uint8 _trainingtype) public { //owner,trainer check in function
        Pet[_id] = core.trainPet(Pet[_id], _trainingtype,ownerOf(_id)); //requirement check on lib
        emit StatChangedResult(Pet[_id]);
    }
    struct cc {
        uint8[4] _chances; 
        uint32[4] ABCD;
        uint BattleRhythm;
        uint64 damage; //dealt total damage to Mon2
         uint8 bit; // how many bit has been filled for Rythm
    }
    function BattlePet(uint _id, uint8 _rank) public {
        //_rank 0~3 is AI based on self CP. 
        //_rank 4 = mysterious tower has 10 level.
        require(!isContractAddress(msg.sender), "Contract addresses are not allowed");
        A.Pets memory OwnerPet = Pet[_id];
        uint64 _timenow = uint64(block.timestamp);
        require(msg.sender == ownerOf(_id)  &&
                _timenow - OwnerPet.time.stamina >= BATTLESTAMINA && 
                OwnerPet.time.deadtime > _timenow && OwnerPet.time.endurance > _timenow ); //Alive
        bool Mon1Win;
        cc memory C;
 //       uint BattleRhythm;
 //       uint8 bit; // how many bit has been filled for Rythm
 //       uint64 damage; //dealt total damage to Mon2
 //       uint8[4] memory _chances;
 //       uint32[4] memory ABCD;
        uint8 _nextTowerLevel;
        uint rand = uint(keccak256(abi.encodePacked(msg.sender, block.timestamp)));
        A.Pets memory BattlingPet;
        C.ABCD = ArtifactContract.getEquipedArtifactsEffects(msg.sender);
        if (_rank <= 3) { //tag along with Mon1Win to reduce stack
            BattlingPet = core.battlingPet(_rank,rand);
        } else {
            require(TowerLevel[msg.sender] > 0, "TowerLevel 0");
            (BattlingPet,C._chances,_nextTowerLevel) = core.TowerPet(TowerLevel[msg.sender], rand);
        }
        OwnerPet.power.hitpoints = OwnerPet.power.hitpoints + (C.ABCD[0]*1000);
        OwnerPet.power.strength = OwnerPet.power.strength + uint16(C.ABCD[1]);
        OwnerPet.power.agility = OwnerPet.power.agility + uint16(C.ABCD[2]);
        OwnerPet.power.intellegence = OwnerPet.power.intellegence+ uint16(C.ABCD[3]);
        (Mon1Win,C.BattleRhythm, C.bit, C.damage) = core.battlePet(rand, OwnerPet, BattlingPet);
        
        if (_rank >3 && Mon1Win == true) {
        TowerLevel[msg.sender] = _nextTowerLevel; //win go to next
        //Give reward with chances if win here!
            if (DailyMaxReward[_id] > 0) { //reach reward limit?
                ArtifactContract.rewardSystem(C._chances, msg.sender, rand);
                DailyMaxReward[_id] = DailyMaxReward[_id] -1;
            } else if( _timenow - RewardLimitTimer[_id] > 82800 ) {//23hours //help reset limit and use it
                ArtifactContract.rewardSystem(C._chances, msg.sender, rand);
                DailyMaxReward[_id] = 9;
                RewardLimitTimer[_id] = _timenow;
            } //otherwise, no reward.
        }
        
        Pet[_id] = core.battlewinlosereward(Pet[_id], Mon1Win, _rank); //exp stars gain   
        Pet[_id].time.stamina += BATTLESTAMINA; // take up stamina
        emit Result(_id, Mon1Win, C.BattleRhythm, Pet[_id], BattlingPet,C.damage, C.bit); //done battle
        
    }
    
    function resetTowerLevel() public {
        if (block.timestamp - TowerResetCd[msg.sender] > 50) { //50s cooldown for reset the level to prevent spam
            TowerLevel[msg.sender] = (uint8(uint(keccak256(abi.encodePacked(msg.sender, block.timestamp,block.coinbase))))%20)+1;
            TowerResetCd[msg.sender] = uint32(block.timestamp);
        } else {
            revert();
        }
    }
    
    function setArtifactContract (address _artifact) public onlyOwner {
        if (confirmed == false) {
            ArtifactContract = ContractArtifactInterface(_artifact);
        }
    }
     
    function confirmArtifactContract () public onlyOwner {
        confirmed = true;
    }



    //----------------------- Owner function ---------------------------------
    function withdraw(address payable _to) external { //incase someone want to donate to me? who knows. haha
        require(_to == owner());
        (bool sent,) = _to.call{value: address(this).balance}("");
        require(sent);
    }
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI; //IPFS/server is less realiable than FTM IMO. The states are safe in FTM. Only URI link is upgradable.
        //URI is just for marketplace to display.
    }
    function setImageURL(string memory URL) public onlyOwner {
        imageURL = URL;//IPFS/server is less realiable, Only URI link is upgradable.
        //URI is just for marketplace to display.
    }
    function setImageExtension(string memory ext) public onlyOwner {
        imageExtension = ext; //IPFS/server is less realiable, Only URI link is upgradable.
        //URI is just for marketplace to display.
    }
    function setnamebyID(bool TF) public onlyOwner {
        namebyID = TF; //IPFS/server is less realiable, Only URI link is upgradable.
        //URI is just for marketplace to display.
    }
    //----------------------- Free read Functions ---------------------------------------
    function royaltyInfo(uint, uint _salePrice) external view returns (address, uint) {
        uint royalty = 500;
        address receiver = owner();
        return (receiver, (_salePrice * royalty) / 10000);
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    function _imageURI() internal view returns (string memory) {
        return imageURL;
    }
    function viewNFT(uint256 _tokenId) external view returns (A.Pets memory) {
        return Pet[_tokenId];
    }
    function getPetsByOwner(address _owner) public view returns(uint[] memory) {
        uint[] memory result = new uint[](balanceOf(_owner));
        uint counter = 0;
        for (uint i = 0; i < tokenIdTracker; i++) {
            if (ownerOf(i) == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }
    function getPetsByOwnerByBatch (address _owner) external view returns(A.Pets[] memory) {
        uint[] memory ids = getPetsByOwner(_owner);
        A.Pets[] memory PetsInfo = new A.Pets[](balanceOf(_owner));
        for (uint i = 0; i < balanceOf(_owner); i++) {
            PetsInfo[i] = Pet[ids[i]];
        }
        return PetsInfo;
    }
    
    function tokenURI(uint256 tokenId) public view override virtual returns (string memory) {
        _requireMinted(tokenId);
        //E.toString(tokenId)
        return Meta.buildURIbased64(Pet[tokenId],imageURL, imageExtension,uint64(block.timestamp),namebyID);
    } //I wish Marketplaces able to comply to this...
    function viewTowerMonster(address _owner) public view returns (A.Pets memory APet, uint8[4] memory _chances){
        (APet,_chances,) = core.TowerPet(TowerLevel[_owner],0);
    }
    function DailyRewardLimit (uint _id) public view returns(uint8 Limit, uint64 resettimer) {
        if (DailyMaxReward[_id] > 0) {
                Limit = DailyMaxReward[_id];
                resettimer = RewardLimitTimer[_id];
            } else if( block.timestamp - RewardLimitTimer[_id] > 82800 ) {//23hours
                Limit = 10;
                resettimer = uint64(block.timestamp);
            } else {
                Limit = DailyMaxReward[_id];
                resettimer = RewardLimitTimer[_id];
            }
    }



}