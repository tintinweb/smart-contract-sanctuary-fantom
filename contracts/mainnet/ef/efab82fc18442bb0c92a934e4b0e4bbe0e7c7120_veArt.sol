// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "libSVG/SVG.sol";
import "libSVG/JSON.sol";
//import {IVeArtProxy} from "contracts-latest/interfaces/IVeArtProxy.sol";
import "solady/utils/DateTimeLib.sol";

interface IPair {
    function current(address tokenIn, uint amountIn) external view returns(uint);
}

interface IVotingEscrow {
    function balanceOfNFT(uint) external view returns (uint);
    function totalSupply() external view returns (uint);
}

interface IVeArtProxy {
    function _tokenURI(uint _tokenId, uint _balanceOf, uint _locked_end, uint _value) external view returns (string memory output);
}

contract veArt is IVeArtProxy {
    using svg for string;

    IVotingEscrow public constant VOTING_ESCROW = IVotingEscrow(0xAE459eE7377Fb9F67518047BBA5482C2F0963236);
    IPair public constant FVM_DAI_PAIR = IPair(0x2c794004c9f289DDEcbe2Ba2B61249bdC3aAF983);
    address public constant FVM_TOKEN = 0x07BB65fAaC502d4996532F834A1B7ba5dC32Ff96;
    
    function _tokenURI(uint _tokenId, uint _balanceOf, uint _locked_end, uint _value) external view returns (string memory output) {
        veBackground.NFT_STATS memory stats = veBackground.NFT_STATS({
            id:             _tokenId,
            notionalFlow:   _value,
            notionalNote:   FVM_DAI_PAIR.current(FVM_TOKEN, _value),
            votes:          _balanceOf,
            voteInfluence:  (_balanceOf*1e7)/VOTING_ESCROW.totalSupply(),
            expiry:         _locked_end
        });

        string memory svgCard = veBackground.card(stats);

        return json.formattedMetadata(
            string.concat('lock #', utils.toString(_tokenId)),
            "Velocimeter locks, can be used to boost gauge yields, vote on token emission, and receive bribes",
            svgCard
        );
    }

    function renderSVG() public view returns (string memory) {
        veBackground.NFT_STATS memory stats = veBackground.NFT_STATS({
            id:             123,
            notionalFlow:   1000e18,
            notionalNote:   10e18,
            votes:          10e9,
            voteInfluence:  69,
            expiry:         block.timestamp + 730 days
        });
        
        return veBackground.card(stats);
    }

}

library veBackground {
    using svg for string;
    using utils for uint256; 

    struct NFT_STATS {
        uint id;
        uint notionalFlow; // notional amount
        uint notionalNote; // notion amount in DAI
        uint votes; //votes
        uint voteInfluence; // influence in bps
        uint expiry;        
    }

    string public constant VELO_GREEN = '#00e8c9';
    string public constant BG_BLACK = '#222323';

    string constant SVG_WRAP_TOP = 'xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 500 500" width="500" height="500" xmlns:xlink="http://www.w3.org/1999/xlink"';

    function card(NFT_STATS memory _stats)
        internal 
        pure
        returns (string memory)
    {
        return string('svg').el(
            string.concat(SVG_WRAP_TOP), 
            string.concat(
                defs(),
                bgCard(),
                idText(_stats.id),
                headerText(),
                transparentBox(_stats),
                veloLogo(),
                flowLogo()
            )
        );
    }

    struct curveParams {
        uint256 offset0;
        uint256 offset1;
        uint256 r;
        string cx;
    }

    function curveDefs() private pure returns (string memory curvesDefs_) {

        curveParams[8] memory curves = [
            curveParams( 0,  80, 100,   "50" ),
            curveParams(10, 100,  80,  "-20" ),
            curveParams( 0, 100,  50,   "40" ),
            curveParams( 0, 100,  80,   "100"),
            curveParams(70, 100,  75,  "-40" ),
            curveParams(50, 100,  75,   "130"),
            curveParams(50, 100,  30,   "20" ),
            curveParams(50, 100,  30,   "70" )
        ];

      
        unchecked{
            for (uint256 i = 0; i<8; ++i) {
                
                curvesDefs_ = string.concat(
                    curvesDefs_,
                    svg.radialGradient(
                        string.concat(
                            string('id').prop(string.concat('curveGradiant_', i.toString())),
                            string('r').prop(string.concat(curves[i].r.toString(), '%')),
                            string('cx').prop(string.concat(curves[i].cx, '%'))
                        ),
                        string.concat(
                            svg.gradientStop(curves[i].offset0, VELO_GREEN, string('stop-opacity').prop('1')),
                            svg.gradientStop(curves[i].offset1, VELO_GREEN, string('stop-opacity').prop('0'))
                        )
                    )
                );
            }
        }
        

    }

    function defs() private pure returns (string memory) {
        return string('defs').el(
            '',
            string.concat(
                '<path id="curve" d="m0 450 c100-0 300-250 500-250" fill="none"  stroke-width="4"/>',
                curveDefs(),
                svg.radialGradient(
                    string('id').prop('greenGradiant'),
                    string.concat(
                        svg.gradientStop(10, VELO_GREEN, ''),
                        svg.gradientStop(100, BG_BLACK, '')
                    )
                )
            )
        );
    }


    function bgCurves() private pure returns (string memory curveBG_)  {
        string[25] memory curves = [
            "0",
            "20",
            "-20",
            "-80",
            "10",
            "35",
            "-55",
            "55",
            "-75",
            "75",
            "-25",
            "-10",
            "60",
            "-60",
            "40",
            "-40",
            "80",
            "15",
            "30",
            "50",
            "70",
            "25",
            "-15",
            "15",
            "-35"
        ];
      
        unchecked{
            for (uint256 i = 0; i<25; ++i) {
                curveBG_ = string.concat(
                    curveBG_,
                    svg.use(
                        '#curve',
                        string.concat(
                            string('y').prop(curves[i]),
                            string('stroke').prop(string.concat('url(#curveGradiant_',(i%7).toString(),')'))
                        )
                    )
                );
            }
        }
    }

    function bgCard() private pure returns (string memory) {
        return string.concat(
            string.concat(
                string('x').prop('0'),
                string('y').prop('0'),
                string('width').prop('100%'),
                string('height').prop('100%'),
                string('fill').prop(BG_BLACK)
            ).rect(),
            bgCurves()
        );
    }

    function idText(uint256 _id) private pure returns (string memory) {
        return string.concat(
            svg.text(
                string.concat(
                    string('x').prop('165'),
                    string('y').prop('135'),
                    string('font-family').prop('Lucida Console'),
                    string('fill').prop(VELO_GREEN),
                    string('font-size').prop('20px'),
                    string('font-weight').prop('600')
                ),
                string.concat('Voter ID #', _id.toString())
            )
        );
    }
    

    function transparentBox(NFT_STATS memory _stats)
        private 
        pure
        returns (string memory)
    {
        return string.concat(
                    string.concat(
                        boxBase(),
                        boxStroke()
                    ).rect(),
                    boxLineProps().line(),
                    boxTextStatic(),
                    boxTextDynamic(_stats)
                );
    }

    function boxBase() private pure returns (string memory) {
        return string.concat(
            string('x').prop('45'),
            string('y').prop('155'),
            string('width').prop('410'),
            string('height').prop('320'),
            string('rx').prop('20'),
            string('fill').prop('#343636'),
            string('fill-opacity').prop('85%')
        );
    }

    function boxStroke() private pure returns (string memory) {
        return string.concat(
            string('stroke').prop('gray'),
            string('stroke-width').prop('5'),
            string('stroke-opacity').prop('10%')
        );
    }

    function boxLineProps() private pure returns (string memory) {
        return string.concat(
            string('x1').prop('45'),
            string('y1').prop('245'),
            string('x2').prop('455'),
            string('y2').prop('245'),
            string('stroke').prop('gray'),
            string('stroke-width').prop('3'),
            string('stroke-opacity').prop('10%')
        );
    }

    function boxTextStatic() private pure returns (string memory) {
        return svg.g(
            string.concat(
                string('font-family').prop('Courier'),
                string('fill').prop('white'),
                string('font-size').prop('18px')
            ),
            string.concat(
                svg.text(
                    string.concat(
                        string('x').prop('100'),
                        string('y').prop('280')
                    ),
                    'Balance:'
                ),
                svg.text(
                    string.concat(
                        string('x').prop('100'),
                        string('y').prop('315')
                    ),
                    '$DAI Value:'
                ),
                svg.text(
                    string.concat(
                        string('x').prop('100'),
                        string('y').prop('350')
                    ),
                    'Votes:'
                ),
                svg.text(
                    string.concat(
                        string('x').prop('100'),
                        string('y').prop('385')
                    ),
                    'Influence:'
                ),
                svg.text(
                    string.concat(
                        string('x').prop('100'),
                        string('y').prop('420')
                    ),
                    'Matures on:'
                )
            )
        );
    }   

    function formatExpirationDate(uint timestamp) private pure returns (string memory) {
        (uint256 year, uint256 month, uint256 day) = DateTimeLib.timestampToDate(timestamp);

        string[12] memory months = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec'
        ];

        return string.concat(
            day.toString(),
            '-',
            months[month-1],
            '-',
            year.toString()
        );
    }

    function boxTextDynamic(NFT_STATS memory _stats) private pure returns (string memory) {
        return svg.g(
            string.concat(
                string('font-family').prop('Courier'),
                string('fill').prop('white'),
                string('font-size').prop('18px')
            ),
            string.concat(
                svg.text(
                    string.concat(
                        string('x').prop('240'),
                        string('y').prop('280')
                    ),
                    string.concat(
                        (_stats.notionalFlow/1e18).toString(),
                        '.',
                        ((_stats.notionalFlow % 1e18)/1e14).toString()
                    )
                ),
                svg.text(
                    string.concat(
                        string('x').prop('240'),
                        string('y').prop('315')
                    ),
                    string.concat(
                        (_stats.notionalNote/1e18).toString(),
                        '.',
                        ((_stats.notionalNote % 1e18)/1e14).toString()
                    )
                ),
                svg.text(
                    string.concat(
                        string('x').prop('240'),
                        string('y').prop('350')
                    ),
                    string.concat(
                        (_stats.votes/1e18).toString(),
                        '.',
                        ((_stats.votes % 1e18)/1e14).toString()
                    )
                ),
                svg.text(
                    string.concat(
                        string('x').prop('240'),
                        string('y').prop('385')
                    ),
                    string.concat('0.', _stats.voteInfluence.toString(), '%')
                ),
                svg.text(
                    string.concat(
                        string('x').prop('240'),
                        string('y').prop('420')
                    ),
                    formatExpirationDate(_stats.expiry)
                )
            )
        );
    }

    function veloLogo() private pure returns (string memory) {
        return svg.g(
            '',
            string.concat(
                svg.polygon(
                    string.concat(
                        string('fill').prop(VELO_GREEN),
                        string('points').prop('42,31 53,31 73,50 93,31 104,31 73,85 Z')
                    )
                ),
                svg.polygon(
                    string.concat(
                        string('fill').prop(BG_BLACK),
                        string('points').prop('58,43 73,52 88,43 73,69 Z')
                    )
                )
            )
        );
    }

    string public constant arcLg = 'm2.2 1.6c2.3-0.074 4.1 0.76 5.5 2.5 0.87 1.2 1.3 2.5 1.3 3.9 3e-3 0.26-8e-3 0.51-0.033 0.77h-0.13c0.15-2-0.49-3.7-1.9-5.1-1.5-1.4-3.3-1.9-5.4-1.5-0.041-0.14-0.096-0.28-0.17-0.41 0.25-0.081 0.53-0.11 0.78-0.13z';

    function flowLogo() private pure returns (string memory) {
        return string.concat(
            svg.g(
                string('transform').prop('translate(75 175) scale(2.5)'),
                string.concat(
                    flowLogoOuter(),
                    flowLogoMid(),
                    flowLogoInner()
                )
            ),
            flowText()
        );
    }

    function flowLogoOuter() private pure returns (string memory) {
        return string.concat(
            svg.path(
                arcLg,
                string.concat(
                    string('id').prop('arcLg'),
                    string('fill').prop(VELO_GREEN)
                )
            ),
            svg.use(
                '#arcLg',
                string.concat(
                    string('transform').prop('rotate(120 2.5 8.5)')
                )
            ),
            svg.use(
                '#arcLg',
                string.concat(
                    string('transform').prop('rotate(240 2.5 8.5)')
                )
            )
        );
    }

    function flowLogoMid() private pure returns (string memory) {
        return string.concat(
            svg.use(
                '#arcLg',
                string.concat(
                    string('transform').prop('rotate(345 6 10)')
                )
            ),
            svg.use(
                '#arcLg',
                string.concat(
                    string('transform').prop('rotate(105 2.5 7.5) translate(0.5 0)')
                )
            ),
            svg.use(
                '#arcLg',
                string.concat(
                    string('transform').prop('translate(0 1.25) rotate(220 2.5 7.5)')
                )
            )
        );
    }

    function flowLogoInner() private pure returns (string memory) {
        return string.concat(
            svg.g(
                string('transform').prop('rotate(340 6 7) scale(0.85)'),
                flowLogoMid()
            )
        );
    }

    function flowText() private pure returns (string memory) {
        return '<text x="110" y="195" font-family="Lucida Console" fill="#00e8c9" font-size="30px" font-weight="800">FVM</text><text x="110" y="220" font-family="Courier" fill="lightGray" font-size="18px" font-weight="800">Liquidity Lab Details</text>';
    }

    function headerText() private pure returns (string memory) {
        return svg.g(
            '',
            string.concat(
                velocimeterText(),
                gradiantLine()
            )
        );
    }


    function velocimeterText() private pure returns (string memory) {
        return '<text x="125" y="45" font-family="Lucida Console" fill="#00e8c9" font-size="24px" font-weight="600">VELOCIMETER</text><text x="125" y="80" font-family="Lucida Console" fill="white" font-size="40px" font-weight="600">veFVM NFT</text>';
    }

    function gradiantLine() private pure returns (string memory) {
        return svg.ellipse(
            string.concat(
                string('cx').prop('250'),
                string('cy').prop('100'),
                string('rx').prop('200'),
                string('ry').prop('5'),
                string('fill').prop("url('#greenGradiant')")
            )
        );
    }


}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import {utils} from './Utils.sol';

// Core SVG utility library which helps us construct
// onchain SVG's with a simple, web-like API.
library svg {

    /* GLOBAL CONSTANTS */
    string internal constant _SVG = 'xmlns="http://www.w3.org/2000/svg"';
    string internal constant _HTML = 'xmlns="http://www.w3.org/1999/xhtml"';
    string internal constant _XMLNS = 'http://www.w3.org/2000/xmlns/ ';
    string internal constant _XLINK = 'http://www.w3.org/1999/xlink ';

    
    /* MAIN ELEMENTS */
    function g(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('g', _props, _children);
    }

    function _svg(string memory _props, string memory _children)
        internal 
        pure
        returns (string memory)
    {
        return el('svg', string.concat(_SVG, ' ', _props), _children);
    }

    function style(string memory _title, string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('style', 
            string.concat(
                '.', 
                _title, 
                ' ', 
                _props)
            );
    }

    function path(string memory _d)
        internal
        pure
        returns (string memory)
    {
        return el('path', prop('d', _d, true));
    }

    function path(string memory _d, string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('path', string.concat(
                                        prop('d', _d),
                                        _props
                                        )
                );
    }

        function path(string memory _d, string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el(
                'path', 
                string.concat(
                            prop('d', _d),
                            _props
                            ),
                _children
                );
    }

    function text(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('text', _props, _children);
    }

    function line(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('line', _props);
    }

    function line(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('line', _props, _children);
    }

    function circle(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('circle', _props);
    }

    function circle(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('circle', _props, _children);
    }

    function circle(string memory cx, string memory cy, string memory r)
        internal
        pure
        returns (string memory)
    {
        
        return el('circle', 
                string.concat(
                    prop('cx', cx),
                    prop('cy', cy),
                    prop('r', r, true)
                )
        );
    }

    function circle(string memory cx, string memory cy, string memory r, string memory _children)
        internal
        pure
        returns (string memory)
    {
        
        return el('circle', 
                string.concat(
                    prop('cx', cx),
                    prop('cy', cy),
                    prop('r', r, true)
                ),
                _children   
        );
    }

    function circle(string memory cx, string memory cy, string memory r, string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        
        return el('circle', 
                string.concat(
                    prop('cx', cx),
                    prop('cy', cy),
                    prop('r', r),
                    _props
                ),
                _children   
        );
    }

    function ellipse(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('ellipse', _props);
    }

    function ellipse(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('ellipse', _props, _children);
    }

    function polygon(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('polygon', _props);
    }

    function polygon(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('polygon', _props, _children);
    }

    function polyline(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('polyline', _props);
    }

    function polyline(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('polyline', _props, _children);
    }

    function rect(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('rect', _props);
    }

    function rect(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('rect', _props, _children);
    }

    function filter(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('filter', _props, _children);
    }

    function cdata(string memory _content)
        internal
        pure
        returns (string memory)
    {
        return string.concat('<![CDATA[', _content, ']]>');
    }

    /* GRADIENTS */
    function radialGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('radialGradient', _props, _children);
    }

    function linearGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('linearGradient', _props, _children);
    }

    function gradientStop(
        uint256 offset,
        string memory stopColor,
        string memory _props
    ) internal pure returns (string memory) {
        return
            el(
                'stop',
                string.concat(
                    prop('stop-color', stopColor),
                    ' ',
                    prop('offset', string.concat(utils.toString(offset), '%')),
                    ' ',
                    _props
                ),
                utils.NULL
            );
    }

    /* ANIMATION */
    function animateTransform(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('animateTransform', _props);
    }

    function animate(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('animate', _props);
    }

    /* COMMON */
    // A generic element, can be used to construct any SVG (or HTML) element
    function el(
        string memory _tag,
        string memory _props,
        string memory _children
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<',
                _tag,
                ' ',
                _props,
                '>',
                _children,
                '</',
                _tag,
                '>'
            );
    }

    // A generic element, can be used to construct SVG (or HTML) elements without children
    function el(
        string memory _tag,
        string memory _props
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<',
                _tag,
                ' ',
                _props,
                '/>'
            );
    }

    // an SVG attribute
    function prop(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat(_key, '=', '"', _val, '" ');
    }

    function prop(string memory _key, string memory _val, bool last)
        internal
        pure
        returns (string memory)
    {
        if (last) {
            return string.concat(_key, '=', '"', _val, '"');
        } else {
            return string.concat(_key, '=', '"', _val, '" ');
        }
        
    }

    function use(string memory _href, string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('use', string.concat(
                                prop('href', _href),
                                _props
                                )
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// JSON utilities for base64 encoded ERC721 JSON metadata scheme
library json {
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// @dev JSON requires that double quotes be escaped or JSONs will not build correctly
    /// string.concat also requires an escape, use \\" or the constant DOUBLE_QUOTES to represent " in JSON
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    string constant DOUBLE_QUOTES = '\\"';

    function formattedMetadata(
        string memory name,
        string memory description,
        string memory svgImg
    )   internal
        pure
        returns (string memory)
    {
        return string.concat(
            'data:application/json;base64,',
            encode(
                bytes(
                    string.concat(
                    '{',
                    _prop('name', name),
                    _prop('description', description),
                    _xmlImage(svgImg),
                    '}'
                    )
                )
            )
        );
    }
    
    function _xmlImage(string memory _svgImg)
        internal
        pure
        returns (string memory) 
    {
        return _prop(
                        'image',
                        string.concat(
                            'data:image/svg+xml;base64,',
                            encode(bytes(_svgImg))
                        ),
                        true
        );
    }

    function _prop(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat('"', _key, '": ', '"', _val, '", ');
    }

    function _prop(string memory _key, string memory _val, bool last)
        internal
        pure
        returns (string memory)
    {
        if(last) {
            return string.concat('"', _key, '": ', '"', _val, '"');
        } else {
            return string.concat('"', _key, '": ', '"', _val, '", ');
        }
        
    }

    function _object(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat('"', _key, '": ', '{', _val, '}');
    }
     
     /**
     * taken from Openzeppelin
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for date time operations.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/DateTimeLib.sol)
///
/// Conventions:
/// --------------------------------------------------------------------+
/// Unit      | Range                | Notes                            |
/// --------------------------------------------------------------------|
/// timestamp | 0..0x1e18549868c76ff | Unix timestamp.                  |
/// epochDay  | 0..0x16d3e098039     | Days since 1970-01-01.           |
/// year      | 1970..0xffffffff     | Gregorian calendar year.         |
/// month     | 1..12                | Gregorian calendar month.        |
/// day       | 1..31                | Gregorian calendar day of month. |
/// weekday   | 1..7                 | The day of the week (1-indexed). |
/// --------------------------------------------------------------------+
/// All timestamps of days are rounded down to 00:00:00 UTC.
library DateTimeLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Weekdays are 1-indexed for a traditional rustic feel.

    // "And on the seventh day God finished his work that he had done,
    // and he rested on the seventh day from all his work that he had done."
    // -- Genesis 2:2

    uint256 internal constant MON = 1;
    uint256 internal constant TUE = 2;
    uint256 internal constant WED = 3;
    uint256 internal constant THU = 4;
    uint256 internal constant FRI = 5;
    uint256 internal constant SAT = 6;
    uint256 internal constant SUN = 7;

    // Months and days of months are 1-indexed for ease of use.

    uint256 internal constant JAN = 1;
    uint256 internal constant FEB = 2;
    uint256 internal constant MAR = 3;
    uint256 internal constant APR = 4;
    uint256 internal constant MAY = 5;
    uint256 internal constant JUN = 6;
    uint256 internal constant JUL = 7;
    uint256 internal constant AUG = 8;
    uint256 internal constant SEP = 9;
    uint256 internal constant OCT = 10;
    uint256 internal constant NOV = 11;
    uint256 internal constant DEC = 12;

    // These limits are large enough for most practical purposes.
    // Inputs that exceed these limits result in undefined behavior.

    uint256 internal constant MAX_SUPPORTED_YEAR = 0xffffffff;
    uint256 internal constant MAX_SUPPORTED_EPOCH_DAY = 0x16d3e098039;
    uint256 internal constant MAX_SUPPORTED_TIMESTAMP = 0x1e18549868c76ff;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    DATE TIME OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the number of days since 1970-01-01 from (`year`,`month`,`day`).
    /// See: https://howardhinnant.github.io/date_algorithms.html
    /// Note: Inputs outside the supported ranges result in undefined behavior.
    /// Use {isSupportedDate} to check if the inputs are supported.
    function dateToEpochDay(uint256 year, uint256 month, uint256 day)
        internal
        pure
        returns (uint256 epochDay)
    {
        /// @solidity memory-safe-assembly
        assembly {
            year := sub(year, lt(month, 3))
            let doy := add(shr(11, add(mul(62719, mod(add(month, 9), 12)), 769)), day)
            let yoe := mod(year, 400)
            let doe := sub(add(add(mul(yoe, 365), shr(2, yoe)), doy), div(yoe, 100))
            epochDay := sub(add(mul(div(year, 400), 146097), doe), 719469)
        }
    }

    /// @dev Returns (`year`,`month`,`day`) from the number of days since 1970-01-01.
    /// Note: Inputs outside the supported ranges result in undefined behavior.
    /// Use {isSupportedDays} to check if the inputs is supported.
    function epochDayToDate(uint256 epochDay)
        internal
        pure
        returns (uint256 year, uint256 month, uint256 day)
    {
        /// @solidity memory-safe-assembly
        assembly {
            epochDay := add(epochDay, 719468)
            let doe := mod(epochDay, 146097)
            let yoe :=
                div(sub(sub(add(doe, div(doe, 36524)), div(doe, 1460)), eq(doe, 146096)), 365)
            let doy := sub(doe, sub(add(mul(365, yoe), shr(2, yoe)), div(yoe, 100)))
            let mp := div(add(mul(5, doy), 2), 153)
            day := add(sub(doy, shr(11, add(mul(mp, 62719), 769))), 1)
            month := sub(add(mp, 3), mul(gt(mp, 9), 12))
            year := add(add(yoe, mul(div(epochDay, 146097), 400)), lt(month, 3))
        }
    }

    /// @dev Returns the unix timestamp from (`year`,`month`,`day`).
    /// Note: Inputs outside the supported ranges result in undefined behavior.
    /// Use {isSupportedDate} to check if the inputs are supported.
    function dateToTimestamp(uint256 year, uint256 month, uint256 day)
        internal
        pure
        returns (uint256 result)
    {
        unchecked {
            result = dateToEpochDay(year, month, day) * 86400;
        }
    }

    /// @dev Returns (`year`,`month`,`day`) from the given unix timestamp.
    /// Note: Inputs outside the supported ranges result in undefined behavior.
    /// Use {isSupportedTimestamp} to check if the inputs are supported.
    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (uint256 year, uint256 month, uint256 day)
    {
        (year, month, day) = epochDayToDate(timestamp / 86400);
    }

    /// @dev Returns the unix timestamp from
    /// (`year`,`month`,`day`,`hour`,`minute`,`second`).
    /// Note: Inputs outside the supported ranges result in undefined behavior.
    /// Use {isSupportedDateTime} to check if the inputs are supported.
    function dateTimeToTimestamp(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (uint256 result) {
        unchecked {
            result = dateToEpochDay(year, month, day) * 86400 + hour * 3600 + minute * 60 + second;
        }
    }

    /// @dev Returns (`year`,`month`,`day`,`hour`,`minute`,`second`)
    /// from the given unix timestamp.
    /// Note: Inputs outside the supported ranges result in undefined behavior.
    /// Use {isSupportedTimestamp} to check if the inputs are supported.
    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day,
            uint256 hour,
            uint256 minute,
            uint256 second
        )
    {
        unchecked {
            (year, month, day) = epochDayToDate(timestamp / 86400);
            uint256 secs = timestamp % 86400;
            hour = secs / 3600;
            secs = secs % 3600;
            minute = secs / 60;
            second = secs % 60;
        }
    }

    /// @dev Returns if the `year` is leap.
    function isLeapYear(uint256 year) internal pure returns (bool leap) {
        /// @solidity memory-safe-assembly
        assembly {
            leap := iszero(and(add(mul(iszero(mod(year, 25)), 12), 3), year))
        }
    }

    /// @dev Returns number of days in given `month` of `year`.
    function daysInMonth(uint256 year, uint256 month) internal pure returns (uint256 result) {
        bool flag = isLeapYear(year);
        /// @solidity memory-safe-assembly
        assembly {
            // `daysInMonths = [31,28,31,30,31,30,31,31,30,31,30,31]`.
            // `result = daysInMonths[month - 1] + isLeapYear(year)`.
            result :=
                add(byte(month, shl(152, 0x1F1C1F1E1F1E1F1F1E1F1E1F)), and(eq(month, 2), flag))
        }
    }

    /// @dev Returns the weekday from the unix timestamp.
    /// Monday: 1, Tuesday: 2, ....., Sunday: 7.
    function weekday(uint256 timestamp) internal pure returns (uint256 result) {
        unchecked {
            result = ((timestamp / 86400 + 3) % 7) + 1;
        }
    }

    /// @dev Returns if (`year`,`month`,`day`) is a supported date.
    /// - `1970 <= year <= MAX_SUPPORTED_YEAR`.
    /// - `1 <= month <= 12`.
    /// - `1 <= day <= daysInMonth(year, month)`.
    function isSupportedDate(uint256 year, uint256 month, uint256 day)
        internal
        pure
        returns (bool result)
    {
        uint256 md = daysInMonth(year, month);
        /// @solidity memory-safe-assembly
        assembly {
            let w := not(0)
            result :=
                and(
                    lt(sub(year, 1970), sub(MAX_SUPPORTED_YEAR, 1969)),
                    and(lt(add(month, w), 12), lt(add(day, w), md))
                )
        }
    }

    /// @dev Returns if (`year`,`month`,`day`,`hour`,`minute`,`second`) is a supported date time.
    /// - `1970 <= year <= MAX_SUPPORTED_YEAR`.
    /// - `1 <= month <= 12`.
    /// - `1 <= day <= daysInMonth(year, month)`.
    /// - `hour < 24`.
    /// - `minute < 60`.
    /// - `second < 60`.
    function isSupportedDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (bool result) {
        if (isSupportedDate(year, month, day)) {
            /// @solidity memory-safe-assembly
            assembly {
                result := and(lt(hour, 24), and(lt(minute, 60), lt(second, 60)))
            }
        }
    }

    /// @dev Returns if `epochDay` is a supported unix epoch day.
    function isSupportedEpochDay(uint256 epochDay) internal pure returns (bool result) {
        unchecked {
            result = epochDay < MAX_SUPPORTED_EPOCH_DAY + 1;
        }
    }

    /// @dev Returns if `timestamp` is a supported unix timestamp.
    function isSupportedTimestamp(uint256 timestamp) internal pure returns (bool result) {
        unchecked {
            result = timestamp < MAX_SUPPORTED_TIMESTAMP + 1;
        }
    }

    /// @dev Returns the unix timestamp of the given `n`th weekday `wd`, in `month` of `year`.
    /// Example: 3rd Friday of Feb 2022 is `nthWeekdayInMonthOfYearTimestamp(2022, 2, 3, 5)`
    /// Note: `n` is 1-indexed for traditional consistency.
    /// Invalid weekdays (i.e. `wd == 0 || wd > 7`) result in undefined behavior.
    function nthWeekdayInMonthOfYearTimestamp(uint256 year, uint256 month, uint256 n, uint256 wd)
        internal
        pure
        returns (uint256 result)
    {
        uint256 d = dateToEpochDay(year, month, 1);
        uint256 md = daysInMonth(year, month);
        /// @solidity memory-safe-assembly
        assembly {
            let diff := sub(wd, add(mod(add(d, 3), 7), 1))
            let date := add(mul(sub(n, 1), 7), add(mul(gt(diff, 6), 7), diff))
            result := mul(mul(86400, add(date, d)), and(lt(date, md), iszero(iszero(n))))
        }
    }

    /// @dev Returns the unix timestamp of the most recent Monday.
    function mondayTimestamp(uint256 timestamp) internal pure returns (uint256 result) {
        uint256 t = timestamp;
        /// @solidity memory-safe-assembly
        assembly {
            let day := div(t, 86400)
            result := mul(mul(sub(day, mod(add(day, 3), 7)), 86400), gt(t, 345599))
        }
    }

    /// @dev Returns whether the unix timestamp falls on a Saturday or Sunday.
    /// To check whether it is a week day, just take the negation of the result.
    function isWeekEnd(uint256 timestamp) internal pure returns (bool result) {
        result = weekday(timestamp) > FRI;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              DATE TIME ARITHMETIC OPERATIONS               */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Adds `numYears` to the unix timestamp, and returns the result.
    /// Note: The result will share the same Gregorian calendar month,
    /// but different Gregorian calendar years for non-zero `numYears`.
    /// If the Gregorian calendar month of the result has less days
    /// than the Gregorian calendar month day of the `timestamp`,
    /// the result's month day will be the maximum possible value for the month.
    /// (e.g. from 29th Feb to 28th Feb)
    function addYears(uint256 timestamp, uint256 numYears) internal pure returns (uint256 result) {
        (uint256 year, uint256 month, uint256 day) = epochDayToDate(timestamp / 86400);
        result = _offsetted(year + numYears, month, day, timestamp);
    }

    /// @dev Adds `numMonths` to the unix timestamp, and returns the result.
    /// Note: If the Gregorian calendar month of the result has less days
    /// than the Gregorian calendar month day of the `timestamp`,
    /// the result's month day will be the maximum possible value for the month.
    /// (e.g. from 29th Feb to 28th Feb)
    function addMonths(uint256 timestamp, uint256 numMonths)
        internal
        pure
        returns (uint256 result)
    {
        (uint256 year, uint256 month, uint256 day) = epochDayToDate(timestamp / 86400);
        month = _sub(month + numMonths, 1);
        result = _offsetted(year + month / 12, _add(month % 12, 1), day, timestamp);
    }

    /// @dev Adds `numDays` to the unix timestamp, and returns the result.
    function addDays(uint256 timestamp, uint256 numDays) internal pure returns (uint256 result) {
        result = timestamp + numDays * 86400;
    }

    /// @dev Adds `numHours` to the unix timestamp, and returns the result.
    function addHours(uint256 timestamp, uint256 numHours) internal pure returns (uint256 result) {
        result = timestamp + numHours * 3600;
    }

    /// @dev Adds `numMinutes` to the unix timestamp, and returns the result.
    function addMinutes(uint256 timestamp, uint256 numMinutes)
        internal
        pure
        returns (uint256 result)
    {
        result = timestamp + numMinutes * 60;
    }

    /// @dev Adds `numSeconds` to the unix timestamp, and returns the result.
    function addSeconds(uint256 timestamp, uint256 numSeconds)
        internal
        pure
        returns (uint256 result)
    {
        result = timestamp + numSeconds;
    }

    /// @dev Subtracts `numYears` from the unix timestamp, and returns the result.
    /// Note: The result will share the same Gregorian calendar month,
    /// but different Gregorian calendar years for non-zero `numYears`.
    /// If the Gregorian calendar month of the result has less days
    /// than the Gregorian calendar month day of the `timestamp`,
    /// the result's month day will be the maximum possible value for the month.
    /// (e.g. from 29th Feb to 28th Feb)
    function subYears(uint256 timestamp, uint256 numYears) internal pure returns (uint256 result) {
        (uint256 year, uint256 month, uint256 day) = epochDayToDate(timestamp / 86400);
        result = _offsetted(year - numYears, month, day, timestamp);
    }

    /// @dev Subtracts `numYears` from the unix timestamp, and returns the result.
    /// Note: If the Gregorian calendar month of the result has less days
    /// than the Gregorian calendar month day of the `timestamp`,
    /// the result's month day will be the maximum possible value for the month.
    /// (e.g. from 29th Feb to 28th Feb)
    function subMonths(uint256 timestamp, uint256 numMonths)
        internal
        pure
        returns (uint256 result)
    {
        (uint256 year, uint256 month, uint256 day) = epochDayToDate(timestamp / 86400);
        uint256 yearMonth = _totalMonths(year, month) - _add(numMonths, 1);
        result = _offsetted(yearMonth / 12, _add(yearMonth % 12, 1), day, timestamp);
    }

    /// @dev Subtracts `numDays` from the unix timestamp, and returns the result.
    function subDays(uint256 timestamp, uint256 numDays) internal pure returns (uint256 result) {
        result = timestamp - numDays * 86400;
    }

    /// @dev Subtracts `numHours` from the unix timestamp, and returns the result.
    function subHours(uint256 timestamp, uint256 numHours) internal pure returns (uint256 result) {
        result = timestamp - numHours * 3600;
    }

    /// @dev Subtracts `numMinutes` from the unix timestamp, and returns the result.
    function subMinutes(uint256 timestamp, uint256 numMinutes)
        internal
        pure
        returns (uint256 result)
    {
        result = timestamp - numMinutes * 60;
    }

    /// @dev Subtracts `numSeconds` from the unix timestamp, and returns the result.
    function subSeconds(uint256 timestamp, uint256 numSeconds)
        internal
        pure
        returns (uint256 result)
    {
        result = timestamp - numSeconds;
    }

    /// @dev Returns the difference in Gregorian calendar years
    /// between `fromTimestamp` and `toTimestamp`.
    /// Note: Even if the true time difference is less than a year,
    /// the difference can be non-zero is the timestamps are
    /// from diffrent Gregorian calendar years
    function diffYears(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 result)
    {
        toTimestamp - fromTimestamp;
        (uint256 fromYear,,) = epochDayToDate(fromTimestamp / 86400);
        (uint256 toYear,,) = epochDayToDate(toTimestamp / 86400);
        result = _sub(toYear, fromYear);
    }

    /// @dev Returns the difference in Gregorian calendar months
    /// between `fromTimestamp` and `toTimestamp`.
    /// Note: Even if the true time difference is less than a month,
    /// the difference can be non-zero is the timestamps are
    /// from diffrent Gregorian calendar months.
    function diffMonths(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 result)
    {
        toTimestamp - fromTimestamp;
        (uint256 fromYear, uint256 fromMonth,) = epochDayToDate(fromTimestamp / 86400);
        (uint256 toYear, uint256 toMonth,) = epochDayToDate(toTimestamp / 86400);
        result = _sub(_totalMonths(toYear, toMonth), _totalMonths(fromYear, fromMonth));
    }

    /// @dev Returns the difference in days between `fromTimestamp` and `toTimestamp`.
    function diffDays(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 result)
    {
        result = (toTimestamp - fromTimestamp) / 86400;
    }

    /// @dev Returns the difference in hours between `fromTimestamp` and `toTimestamp`.
    function diffHours(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 result)
    {
        result = (toTimestamp - fromTimestamp) / 3600;
    }

    /// @dev Returns the difference in minutes between `fromTimestamp` and `toTimestamp`.
    function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 result)
    {
        result = (toTimestamp - fromTimestamp) / 60;
    }

    /// @dev Returns the difference in seconds between `fromTimestamp` and `toTimestamp`.
    function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 result)
    {
        result = toTimestamp - fromTimestamp;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unchecked arithmetic for computing the total number of months.
    function _totalMonths(uint256 numYears, uint256 numMonths)
        private
        pure
        returns (uint256 total)
    {
        unchecked {
            total = numYears * 12 + numMonths;
        }
    }

    /// @dev Unchecked arithmetic for adding two numbers.
    function _add(uint256 a, uint256 b) private pure returns (uint256 c) {
        unchecked {
            c = a + b;
        }
    }

    /// @dev Unchecked arithmetic for subtracting two numbers.
    function _sub(uint256 a, uint256 b) private pure returns (uint256 c) {
        unchecked {
            c = a - b;
        }
    }

    /// @dev Returns the offsetted timestamp.
    function _offsetted(uint256 year, uint256 month, uint256 day, uint256 timestamp)
        private
        pure
        returns (uint256 result)
    {
        uint256 dm = daysInMonth(year, month);
        if (day >= dm) {
            day = dm;
        }
        result = dateToEpochDay(year, month, day) * 86400 + (timestamp % 86400);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Core utils used extensively to format CSS and numbers.
library utils {
    // used to simulate empty strings
    string internal constant NULL = '';

    // formats a CSS variable line. includes a semicolon for formatting.
    function setCssVar(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat('--', _key, ':', _val, ';');
    }

    // formats getting a css variable
    function getCssVar(string memory _key)
        internal
        pure
        returns (string memory)
    {
        return string.concat('var(--', _key, ')');
    }

    // formats getting a def URL
    function getDefURL(string memory _id)
        internal
        pure
        returns (string memory)
    {
        return string.concat('url(#', _id, ')');
    }

    // formats rgba white with a specified opacity / alpha
    function white_a(uint256 _a) internal pure returns (string memory) {
        return rgba(255, 255, 255, _a);
    }

    // formats rgba black with a specified opacity / alpha
    function black_a(uint256 _a) internal pure returns (string memory) {
        return rgba(0, 0, 0, _a);
    }

    // formats generic rgba color in css
    function rgba(
        uint256 _r,
        uint256 _g,
        uint256 _b,
        uint256 _a
    ) internal pure returns (string memory) {
        string memory formattedA = _a < 100
            ? string.concat('0.', utils.toString(_a))
            : '1';
        return
            string.concat(
                'rgba(',
                utils.toString(_r),
                ',',
                utils.toString(_g),
                ',',
                utils.toString(_b),
                ',',
                formattedA,
                ')'
            );
    }

    function cssBraces(
        string memory _attribute, 
        string memory _value
    )   internal
        pure
        returns (string memory)
    {
        return string.concat(
            ' {',
            _attribute,
            ': ',
            _value,
            '}'
        );
    }

    function cssBraces(
        string[] memory _attributes, 
        string[] memory _values
    )   internal
        pure
        returns (string memory)
    {
        require(_attributes.length == _values.length, "Utils: Unbalanced Arrays");
        
        uint256 len = _attributes.length;

        string memory results = ' {';

        for (uint256 i = 0; i<len; i++) {
            results = string.concat(
                                    results, 
                                    _attributes[i],
                                    ': ',
                                    _values[i],
                                     '; '
                                    );
                                    
        }

        return string.concat(results, '}');
    }

    //deals with integers (i.e. no decimals)
    function points(uint256[2][] memory pointsArray) internal pure returns (string memory) {
        require(pointsArray.length >= 3, "Utils: Array too short");

        uint256 len = pointsArray.length-1;


        string memory results = 'points="';

        for (uint256 i=0; i<len; i++){
            results = string.concat(
                                    results, 
                                    toString(pointsArray[i][0]), 
                                    ',', 
                                    toString(pointsArray[i][1]),
                                    ' '
                                    );
        }

        return string.concat(
                            results, 
                            toString(pointsArray[len][0]), 
                            ',', 
                            toString(pointsArray[len][1]),
                            '"'
                            );
    }

    // allows for a uniform precision to be applied to all points 
    function points(uint256[2][] memory pointsArray, uint256 decimalPrecision) internal pure returns (string memory) {
        require(pointsArray.length >= 3, "Utils: Array too short");

        uint256 len = pointsArray.length-1;


        string memory results = 'points="';

        for (uint256 i=0; i<len; i++){
            results = string.concat(
                                    results, 
                                    toString(pointsArray[i][0], decimalPrecision), 
                                    ',', 
                                    toString(pointsArray[i][1], decimalPrecision),
                                    ' '
                                    );
        }

        return string.concat(
                            results, 
                            toString(pointsArray[len][0], decimalPrecision), 
                            ',', 
                            toString(pointsArray[len][1], decimalPrecision),
                            '"'
                            );
    }

    // checks if two strings are equal
    function stringsEqual(string memory _a, string memory _b)
        internal
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    // returns the length of a string in characters
    function utfStringLength(string memory _str)
        internal
        pure
        returns (uint256 length)
    {
        uint256 i = 0;
        bytes memory string_rep = bytes(_str);

        while (i < string_rep.length) {
            if (string_rep[i] >> 7 == 0) i += 1;
            else if (string_rep[i] >> 5 == bytes1(uint8(0x6))) i += 2;
            else if (string_rep[i] >> 4 == bytes1(uint8(0xE))) i += 3;
            else if (string_rep[i] >> 3 == bytes1(uint8(0x1E)))
                i += 4;
                //For safety
            else i += 1;

            length++;
        }
    }

     /**
     * taken from Openzeppelin
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

        // allows the insertion of a decimal point in the returned string at precision
    function toString(uint256 value, uint256 precision) internal pure returns (string memory) {
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
        require(precision <= digits && precision > 0, "Utils: precision invalid");
        precision == digits ? digits +=2 : digits++; //adds a space for the decimal point, 2 if it is the whole uint
        
        uint256 decimalPlacement = digits - precision - 1;
        bytes memory buffer = new bytes(digits);
        
        buffer[decimalPlacement] = 0x2E; // add the decimal point, ASCII 46/hex 2E
        if (decimalPlacement == 1) {
            buffer[0] = 0x30;
        }
        
        while (value != 0) {
            digits -= 1;
            if (digits != decimalPlacement) {
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
        }

        return string(buffer);
    }

}