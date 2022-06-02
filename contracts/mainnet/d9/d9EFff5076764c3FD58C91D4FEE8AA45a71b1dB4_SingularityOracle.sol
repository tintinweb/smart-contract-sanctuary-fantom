// SPDX-License-Identifier: No License

pragma solidity ^0.8.13;

import "./interfaces/ISingularityOracle.sol";
import "./interfaces/IChainlinkFeed.sol";

/**
 * @title Singularity Oracle
 * @author Revenant Labs
 */
contract SingularityOracle is ISingularityOracle {
    struct PriceData {
        uint256 price;
        uint256 updatedAt;
        uint256 nonce;
    }

    bool public onlyUseChainlink;
    address public admin;
    uint256 public maxPriceTolerance = 0.015 ether; // 1.5%

    mapping(address => bool) public pushers;
    mapping(address => PriceData[]) public allPrices;
    mapping(address => address) public chainlinkFeeds;

    constructor(address _admin) {
        require(_admin != address(0), "SingularityOracle: ADMIN_IS_0");
        admin = _admin;
    }

    /// @dev Validates price is within bounds of reported Chainlink price
    function getLatestRound(address token) public view override returns (uint256 price, uint256 updatedAt) {
        (uint256 chainlinkPrice, uint256 _updatedAt) = _getChainlinkData(token);
        require(chainlinkPrice != 0, "SingularityOracle: CHAINLINK_PRICE_IS_0");
        if (onlyUseChainlink) {
            return (chainlinkPrice, block.timestamp); // change to _updatedAt in prod
        }

        PriceData[] memory prices = allPrices[token];
        price = prices[prices.length - 1].price;
        uint256 priceDiff = price > chainlinkPrice ? price - chainlinkPrice : chainlinkPrice - price;
        uint256 percentDiff = (priceDiff * 1 ether) / (price * 100);
        require(percentDiff <= maxPriceTolerance, "SingularityOracle: PRICE_DIFF_EXCEEDS_TOLERANCE");
        updatedAt = prices[prices.length - 1].updatedAt;
    }

    function getLatestRounds(address[] calldata tokens)
        external
        view
        override
        returns (uint256[] memory prices, uint256[] memory updatedAts)
    {
        prices = new uint256[](tokens.length);
        updatedAts = new uint256[](tokens.length);
        uint256 length = tokens.length;
        for (uint256 i; i < length; ) {
            (uint256 price, uint256 updatedAt) = getLatestRound(tokens[i]);
            prices[i] = price;
            updatedAts[i] = updatedAt;
            unchecked {
                ++i;
            }
        }
    }

    function pushPrice(address _token, uint256 _price) public {
        require(pushers[msg.sender], "SingularityOracle: NOT_PUSHER");
        require(_price != 0, "SingularityOracle: PRICE_IS_0");
        PriceData[] storage prices = allPrices[_token];
        prices.push(PriceData({price: _price, updatedAt: block.timestamp, nonce: prices.length}));
    }

    function pushPrices(address[] calldata tokens, uint256[] calldata prices) external {
        require(tokens.length == prices.length, "SingularityOracle: NOT_SAME_LENGTH");
        uint256 length = tokens.length;
        for (uint256 i; i < length; ) {
            pushPrice(tokens[i], prices[i]);
            unchecked {
                ++i;
            }
        }
    }

    function setOnlyUseChainlink(bool _onlyUseChainlink) external {
        require(msg.sender == admin, "SingularityOracle: NOT_ADMIN");
        onlyUseChainlink = _onlyUseChainlink;
    }

    function setMaxPriceTolerance(uint256 _maxPriceTolerance) external {
        require(msg.sender == admin, "SingularityOracle: NOT_ADMIN");
        require(_maxPriceTolerance != 0 && maxPriceTolerance <= 0.05 ether, "SingularityOracle: OUT_OF_BOUNDS");
        maxPriceTolerance = _maxPriceTolerance;
    }

    function setChainlinkFeed(address token, address feed) public {
        require(msg.sender == admin, "SingularityOracle: NOT_ADMIN");
        require(feed != address(0), "SingularityOracle: CHAINLINK_FEED_IS_0");
        chainlinkFeeds[token] = feed;
    }

    function setChainlinkFeeds(address[] calldata tokens, address[] calldata feeds) external {
        require(tokens.length == feeds.length, "SingularityOracle: NOT_SAME_LENGTH");
        uint256 length = tokens.length;
        for (uint256 i; i < length; ) {
            setChainlinkFeed(tokens[i], feeds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function setAdmin(address _admin) external {
        require(msg.sender == admin, "SingularityOracle: NOT_ADMIN");
        require(_admin != address(0), "SingularityOracle: ADMIN_IS_0");
        admin = _admin;
    }

    function setPusher(address _pusher, bool _allowed) external {
        require(msg.sender == admin, "SingularityOracle: NOT_ADMIN");
        pushers[_pusher] = _allowed;
    }

    function _getChainlinkData(address token) internal view returns (uint256, uint256) {
        require(chainlinkFeeds[token] != address(0), "SingularityOracle: CHAINLINK_FEED_IS_0");
        (, int256 answer, , uint256 updatedAt, ) = IChainlinkFeed(chainlinkFeeds[token]).latestRoundData();
        uint256 rawLatestAnswer = uint256(answer);
        uint8 decimals = IChainlinkFeed(chainlinkFeeds[token]).decimals();
        uint256 price;
        if (decimals <= 18) {
            price = rawLatestAnswer * 10**(18 - decimals);
        } else {
            price = rawLatestAnswer / 10**(decimals - 18);
        }

        return (price, updatedAt);
    }
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.13;

interface ISingularityOracle {
    function getLatestRound(address token) external view returns (uint256, uint256);

    function getLatestRounds(address[] calldata tokens) external view returns (uint256[] memory, uint256[] memory);
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.13;

interface IChainlinkFeed {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        );
}