/**
 *Submitted for verification at FtmScan.com on 2023-01-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface ISvg {

    function begin(
        string memory aspectRatio, 
        string memory viewBox) 
        external 
        pure 
        returns (string memory);
    function b() external pure returns (string memory);
    function end() external pure returns (string memory);
    function head() external pure returns (string memory);
    function headEnd() external pure returns (string memory);
    function link(
        string memory rel, 
        string memory href, 
        bool isCrossOrigin) 
    external 
    pure 
    returns (string memory);
    function links_GoogleFont(string memory family) external pure returns (string memory);
    function filter(string memory id) external pure returns (string memory);
    function filterEnd() external pure returns (string memory);
    function feTurbulence(
        string memory _type,
        string memory baseFrequency,
        string memory numOctaves,
        string memory result
        ) 
    external pure returns (string memory);
    function turb(string memory baseFrequency) external pure returns (string memory);
    function feDisplacementMap(
        string memory in2,
        string memory _in,
        string memory scale,
        string memory xChannelSelector,
        string memory yChannelSelector
        ) 
    external pure returns (string memory);
    function turbDM(string memory scale) external pure returns (string memory);
    function defs() external pure returns (string memory);
    function defsEnd() external pure returns (string memory);
    function gradToCorner(string memory id) external pure returns (string memory);
    function gradToCornerEnd() external pure returns (string memory);
    function gradStop(
        string memory clr,
        string memory ofs
    ) external pure returns (string memory);
    function linearGradient(
        string memory id,
        string memory x1,
        string memory x2,
        string memory y1,
        string memory y2
        ) 
    external pure returns (string memory);
    function linearGradientEnd() external pure returns (string memory);
    function stop(
        string memory offset,
        string memory stopColor
    ) external pure returns (string memory);
    function rect(
        string memory width,
        string memory height,
        string memory x,
        string memory y,
        string memory fill,
        string memory style
        )
    external pure returns (string memory);
    function rectEnd() external pure returns (string memory);
    function text(
        string memory width,
        string memory height,
        string memory x,
        string memory y,
        string memory fill,
        string memory textAnchor,
        string memory style
        )
    external pure returns (string memory);
    function textEnd() external pure returns (string memory);
    function circle(
        string memory cx,
        string memory cy,
        string memory r,
        string memory fill,
        string memory style
        )
    external pure returns (string memory);
    function circleEnd() external pure returns (string memory);
}

abstract contract Context {
    function _msgSender() public view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() public view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
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

contract ChaosURI is Ownable {
	string public TITLE = "Chaos";

	ISvg s = ISvg(0x5e7ac6f7d404665AB2a61240Fea7f5FbBc19c808);
	function changeSvgLib(address newSvgLib) public onlyOwner {
        s = ISvg(newSvgLib);
    }

    string public fontFamily = "Alegreya:ital,[email protected],700;0,900;1,400;1,700;1,900";
    function changeFontFamily(string memory newFontFamily) public onlyOwner {
        fontFamily = newFontFamily;
    }

    string public constant clrDark = "#2e3546";
  	string public constant clrBlue = "#283d70";
  	string public constant clrRed = "#703529";
  	string public constant clrWht = "#e0ddd5";
  	string public constant clrGold = "#c6934b";
  	uint256 public constant fs = 24;
  	uint256 public constant fsTitle = 72;
  	uint256 public constant padding = 32;
  	uint256 public constant vbx = 360;
  	uint256 public constant vby = 640;
  	uint256 public constant rectHeight = 68;

    function blurb() public pure returns (string memory) {
        return '"Chaos is the first Ancient Greek Deity."';
    }

    function jsonify(uint256 tokenId, string memory stuff) public view returns (string memory) {
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "',TITLE,' #', 
            toString(tokenId), 
            '", "description": ',
            blurb(),
            ', "image": "data:image/svg+xml;base64,', 
            Base64.encode(bytes(stuff)), 
            '"}'))));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function head() public view returns (string memory) {
    	return s.links_GoogleFont(fontFamily);
    }

    function filter(string memory id, string memory baseFrequency, string memory scale) public view returns (string memory) {
    	return string(abi.encodePacked(
    		s.filter(id),
    		s.turb(baseFrequency),
    		s.turbDM(scale),
    		s.filterEnd()
    		));
    }

    function defs() public view returns (string memory) {
    	return string(abi.encodePacked(
    		s.defs(),
    		s.linearGradient("BG","0","1","0","1"),
    		s.stop("0%",clrRed),
    		s.stop("25%",clrDark),
    		s.stop("50%",clrBlue),
    		s.stop("100%",clrGold),
    		s.linearGradientEnd(),
    		s.defsEnd()
    		));
    }

    function bg() public view returns (string memory) {
    	return string(abi.encodePacked(
    		s.rect(
    			toString(vbx - padding),
    			toString(vby - padding),
    			"0", "0","none",
    			"filter: url(#turb); fill: url(#BG);"
    			),
    		s.rectEnd()
    		));
    }

    function godName() public view returns (string memory) {
    	string memory style = string(abi.encodePacked(
    		"font-size: ",toString(fsTitle),"px;",
    		"font-style: italic;",
    		"font-weight: 900;"
    		));
    	return string(abi.encodePacked(
    		s.text(
    			"auto","auto",
    			toString(padding*3/2), 
    			toString(fsTitle + padding),
    			"#e0ddd5",
    			"start",
    			style),
    		unicode"Χάος",
    		s.textEnd()
    		));
    }

    function authorName() public view returns (string memory) {
    	string memory style = string(abi.encodePacked(
    		"font-size: ",toString(fs),"px;",
    		"font-style: italic;",
    		"font-weight: 700; text-align: right;"
    		));
    	return string(abi.encodePacked(
    		s.text(
    			"auto","auto",
    			toString(vbx - padding), 
    			toString(vby - padding),
    			clrWht,
    			"end",
    			style),
    		unicode"Ἡσίοδος",
    		s.textEnd()
    		));
    }

    function translationRect() public view returns (string memory) {
    	
    	return string(abi.encodePacked(
    		s.rect(
    			toString(vbx - padding*3), 
    			toString(rectHeight),
    			toString(padding*2),
    			toString(vby - padding*2 - rectHeight),
    			clrWht,
    			"filter: url(#turb2);"),
    		s.rectEnd()
    		));
    }

    function translation() public view returns (string memory) {
    	string memory style = string(abi.encodePacked(
    		"overflow: hidden; font-style:normal; font-weight: 400;overflow-wrap:break-all;white-space:normal;width: 100%;",
    		"font-size: ", toString(fs*9/10),"px;"
    		));
    	string memory w = toString(vbx - padding*3 - padding/2);
    	string memory x = toString(vbx/2 + 16);
		uint256 baseY = vby - padding*2 - 48 + fs/2;
    	return string(abi.encodePacked(
    		s.text(w,"auto",x,toString(baseY),clrRed,"middle",style),
    		"In truth at first", s.textEnd(),
    		s.text(w,"auto",x,toString(baseY + fs),clrRed,"middle",style),
    		"Chaos came to be", s.textEnd()
    		));
    }

    function passageRect() public view returns (string memory) {
    	
    	return string(abi.encodePacked(
    		s.rect(
    			toString(vbx - padding*3), 
    			toString(rectHeight),
    			toString(padding*2),
    			toString(vby - padding*2 - rectHeight*2),
    			clrRed,
    			"filter: url(#turb2);"),
    		s.rectEnd()
    		));
    }
    function passage() public view returns (string memory) {
    	string memory style = string(abi.encodePacked(
    		"overflow: hidden; font-style:normal; font-weight: 700;overflow-wrap:break-all;white-space:normal;width: 100%;",
    		"font-size: ", toString(fs),"px;"
    		));
    	string memory w = toString(vbx - padding*3 - padding/2);
    	string memory x = toString(vbx/2 + 16);
		uint256 baseY = vby - padding*2 - rectHeight - 48 + fs/2;
    	return string(abi.encodePacked(
    		s.text(w,"auto",x,toString(baseY),clrWht,"middle",style),
    		unicode"ἦ τοι μὲν πρώτιστα", s.textEnd(),
    		s.text(w,"auto",x,toString(baseY + fs),clrWht,"middle",style),
    		unicode"Χάος γένετ᾽", s.textEnd()
    		));
    }

    function chaos() public view returns (string memory) {
    	return string(abi.encodePacked(
    		s.circle(toString(vbx/2),toString(vby/2 - 50), "100","black","filter:url(#turb2);"),
    		s.circleEnd(),
    		s.circle(toString(vbx/2),toString(vby/2 - 4), "8",clrGold,"filter:url(#turb3);"),
    		s.circleEnd()
    		));
    }

    function svg() public view returns (string memory) {
    	string[10] memory parts;
    	parts[0] = string(abi.encodePacked(
            s.b(),
            head()
            ));
    	parts[1] = string(abi.encodePacked(
    		filter("turb","0.005","80"),
    		filter("turb2","0.05","20"),
    		filter("turb3","1","20"),
    		defs()
    		));
    	parts[2] = string(abi.encodePacked(
    		bg(),
    		godName(),
    		authorName()
    		));
    	parts[3] = string(abi.encodePacked(
    		passageRect(),
    		passage(),
    		translationRect(),
    		translation(),
    		chaos(),
    		s.end()
    		));
    	string memory preOutput = string(abi.encodePacked(
    		parts[0],parts[1],parts[2],parts[3]
    		));
    	return preOutput;

    }


    function tokenURI(uint256 tokenId) public view returns (string memory) {
    	
    	return jsonify(tokenId, svg());

    }
    function toString(uint256 value) public pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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
    constructor() Ownable() {}

}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes public constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) public pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
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