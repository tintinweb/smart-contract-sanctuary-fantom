/**
 *Submitted for verification at FtmScan.com on 2022-02-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/**
 * @author 0xDAO
 * @title Token helper utility for front-end
 */
interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IOracle {
    function getPriceUsdcRecommended(address tokenAddress)
        external
        view
        returns (uint256);
}

contract TokensHelper {
    address public oracleAddress;
    IOracle internal oracle;

    struct TokenMetadata {
        address id;
        string name;
        string symbol;
        uint8 decimals;
        uint256 priceUsdc;
    }

    function initializeProxyStorage(address _oracleAddress) external {
        require(oracleAddress == address(0), "Already initialized");
        oracleAddress = _oracleAddress;
        oracle = IOracle(oracleAddress);
    }

    function tokensMetadata(address[] memory tokensAddresses)
        public
        view
        returns (TokenMetadata[] memory)
    {
        TokenMetadata[] memory _tokensMetadata = new TokenMetadata[](
            tokensAddresses.length
        );
        for (
            uint256 tokenIdx = 0;
            tokenIdx < tokensAddresses.length;
            tokenIdx++
        ) {
            address tokenAddress = tokensAddresses[tokenIdx];
            IERC20 token = IERC20(tokenAddress);
            _tokensMetadata[tokenIdx] = TokenMetadata({
                id: tokenAddress,
                name: token.name(),
                symbol: token.symbol(),
                decimals: token.decimals(),
                priceUsdc: oracle.getPriceUsdcRecommended(tokenAddress)
            });
        }
        return _tokensMetadata;
    }
}