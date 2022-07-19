// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./NFTToken.sol";
import "./TaxableToken.sol";

/**
 * @title Runic
 */
contract Runic is TaxableToken, NFTToken {
    using SafeERC20 for IERC20;

    constructor(uint256 taxRate_, address taxCollectorAddress_) TaxableToken(taxRate_, taxCollectorAddress_) ERC20("RUNIC", "RUNIC") {
        AccessControl._grantRole(AccessControlConstants.DEFAULT_ADMIN_ROLE, msg.sender);
        AccessControl._grantRole(AccessControlConstants.OPERATOR_ROLE, msg.sender);
        _mint(msg.sender, 100 ether);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(TaxableToken, NFTToken) returns (bool) {
        return super.supportsInterface(interfaceId) ||
        interfaceId == type(IERC20Burnable).interfaceId ||
        interfaceId == type(IERC20Mintable).interfaceId ||
        interfaceId == type(ITaxableToken).interfaceId ||
        interfaceId == type(INFTToken).interfaceId;
    }

    /**
     * @notice exclude an address from both tax and nft power requirement for to and from
     */
    function setExcludeAddress(address address_, bool exclude_) external onlyExclusionOperator onlyNFTExclusionOperator {
        TaxableToken.setExcludeFromTaxAddress(address_, exclude_);
        TaxableToken.setExcludeToTaxAddress(address_, exclude_);
        NFTToken.setExcludeFromNFTAddress(address_, exclude_);
        NFTToken.setExcludeToNFTAddress(address_, exclude_);
    }

    function _transfer(address from_, address to_, uint256 amount_) internal virtual override(ERC20, TaxableToken) {
        TaxableToken._transfer(from_, to_, amount_);
    }

    function _beforeTokenTransfer(address from_, address to_, uint256 amount_) internal virtual override(ERC20, NFTToken) {
        NFTToken._beforeTokenTransfer(from_, to_, amount_);
    }

    function _burn(address from_, uint256 amount_) internal virtual override(ERC20, TaxableToken) {
        TaxableToken._burn(from_, amount_);
    }

    function governanceRecoverUnsupported(IERC20 token_, uint256 amount_, address to_) external onlyOperator {
        token_.safeTransfer(to_, amount_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20Mintable {
    function mint(address, uint256) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20Burnable {
    function burn(uint256) external;
    function burnFrom(address, uint256) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface INFTPower {
    function getPower(uint256 tokenId) external view returns (uint256 power);
    function getUserPower(address account) external view returns (uint256 power);
    function getTotalPower() external view returns (uint256 power);
    function addPower(address account, uint256 tokenId, uint256 power) external;
    function removePower(address account, uint256 tokenId, uint256 power) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITaxableToken {
    function isAddressFromTaxExcluded(address address_) external returns (bool);
    function isAddressToTaxExcluded(address address_) external returns (bool);
    function taxRate() external view returns (uint256 rate);
    function priceFloor() external view returns (uint256 priceFloor);
    function getTaxRate() external view returns (uint256 rate);
    function setTaxCollectorAddress(address taxCollectorAddress) external;
    function setTaxTiersTwap(uint8 index, uint256 value) external;
    function setTaxTiersRate(uint8 index, uint256 value) external;
    function setAutoCalculateTax(bool enabled) external;
    function setTaxRate(uint256 taxRate) external;
    function setBurnThreshold(uint256 burnThreshold) external;
    function setPriceFloor(uint256 priceFloor) external;
    function setSellCeilingSupplyRate(uint256 sellCeilingSupplyRate_) external;
    function setSellCeilingLiquidityRate(uint256 sellCeilingLiquidityRate_) external;
    function sellingLimit() external view returns (uint256);
    function setExcludeFromTaxAddress(address address_, bool exclude) external;
    function setExcludeToTaxAddress(address address_, bool exclude) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOracleToken {
    function oracle() external view returns (address oracle);
    function setOracle(address oracle) external;
    function getPrice() external view returns (uint256 price);
    function getPriceUpdated() external view returns (uint256 price);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOracle {
    function update() external;
    function consult(address token, uint256 amountIn) external view returns (uint144 amountOut);
    function twap(address token, uint256 amountIn) external view returns (uint144 amountOut);
    function getPegPrice() external view returns (uint256 amountOut);
    function getPegPriceUpdated() external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INFTToken {
    function isAddressFromNFTExcluded(address address_) external view returns (bool);
    function isAddressToNFTExcluded(address address_) external view returns (bool);
    function nftPowerRequired() external view returns (uint256 power);
    function getNFTPowerRequired() external view returns (uint256 power);
    function setNFTTiersTwap(uint8 index, uint256 value) external;
    function setNFTTiersPowerRequired(uint8 index, uint256 value) external;
    function setAutoCalculateNFTPowerRequired(bool enabled) external;
    function setNFTPowerRequired(uint256 amount) external;
    function setExcludeFromNFTAddress(address address_, bool exclude) external;
    function setExcludeToNFTAddress(address address_, bool exclude) external;
    function addNFTContract(address contract_) external;
    function removeNFTContract(address contract_) external;
    function getNFTContracts() external view returns (address[] memory contracts_);
    function addNFTPoolsContract(address contract_) external;
    function removeNFTPoolsContract(address contract_) external;
    function getNFTPoolsContracts() external view returns (address[] memory contracts_);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface INFTPools {
    function getStakedNFTBalance(address account, address nftContract) external view returns (uint256 balance);
    function getStakedNFTPower(address account) external view returns (uint256 power);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../../dex/interfaces/IUniswapV2Pair.sol";
import "../../token/ERC20/extensions/IERC20Burnable.sol";
import "../../token/ERC20/extensions/IERC20Mintable.sol";
import "./interfaces/ITaxableToken.sol";
import "./OracleToken.sol";

/**
 * @title TaxableToken
 */
abstract contract TaxableToken is ERC20Burnable, OracleToken, IERC20Burnable, IERC20Mintable, ITaxableToken {
    using EnumerableSet for EnumerableSet.AddressSet;
    address public taxCollectorAddress;
    address public liquidityPair;           // main liquidity pair
    uint256 public override taxRate;        // current tax rate
    uint256 public burnThreshold = 1.10e18; // price threshold below which taxes will get burned
    uint256 public totalBurned;
    uint256 public override priceFloor = 0.9e18; // to block sell
    uint256 public sellCeilingSupplyRate = 10; // up to 0.1% supply for each sell
    uint256 public sellCeilingLiquidityRate = 50; // up to 0.5% in liquidity for each sell
    bool public autoCalculateTax;           // should the taxes be calculated using the tax tiers
    // tax tiers
    uint256[] public taxTiersTwaps = [0, 5e17, 6e17, 7e17, 8e17, 9e17, 9.5e17, 1e18, 1.05e18, 1.10e18, 1.20e18, 1.30e18, 1.40e18, 1.50e18];
    // tax rates in 10000 base. ex: 2000 = 20% 100 = 1%
    uint256[] public taxTiersRates = [2000, 1900, 1800, 1700, 1600, 1500, 1500, 1500, 1500, 1400, 900, 400, 200, 100];
    mapping(address => bool) public excludedFromTaxAddresses; // sender addresses excluded from tax such as contracts or liquidity pairs
    mapping(address => bool) public excludedToTaxAddresses; // receiver addresses excluded from tax
    EnumerableSet.AddressSet internal _excludedFromTaxAddresses;
    EnumerableSet.AddressSet internal _excludedToTaxAddresses;
    EnumerableSet.AddressSet internal _minters; // handles minting
    EnumerableSet.AddressSet internal _pendingMinters; // pending minters
    mapping(address => uint256) public pendingMintersDelay; // time allowed to apply the pending minter
    uint256 public constant ADD_MINTER_DELAY = 24 hours; // time delay for adding minters
    EnumerableSet.AddressSet internal _configOperators; // handles setting of tax, rates, price, etc
    EnumerableSet.AddressSet internal _pendingConfigOperators; // pending configOperators
    mapping(address => uint256) public pendingConfigOperatorsDelay; // time allowed to apply the pending config operator
    uint256 public constant ADD_CONFIG_OPERATOR_DELAY = 24 hours;
    EnumerableSet.AddressSet internal _exclusionOperators; // handles setting of exclusions
    EnumerableSet.AddressSet internal _pendingExclusionOperators; // pending exclusionOperators
    mapping(address => uint256) public pendingExclusionOperatorsDelay; // time allowed to apply the pending exclusion operator
    uint256 public constant ADD_EXCLUSION_OPERATOR_DELAY = 24 hours;

    event ExcludeFromTax(address indexed account, bool exclude);
    event ExcludeToTax(address indexed account, bool exclude);
    event AddedMinter(address indexed minter);
    event RemovedMinter(address indexed minter);
    event AddedConfigOperator(address indexed configOperator);
    event RemovedConfigOperator(address indexed configOperator);
    event AddedExclusionOperator(address indexed exclusionOperator);
    event RemovedExclusionOperator(address indexed exclusionOperator);

    error AmountTooHigh();                  // 0xfd7850ad
    error AutoCalculateTaxOn();             // 0xa3c6b0f9
    error ConfigOperatorDoesNotExist();     // 0xf35ca32f
    error ConfigOperatorExist();            // 0x8deacb7c
    error ExclusionOperatorDoesNotExist();  // 0x4b5d4a11
    error ExclusionOperatorExist();         // 0x436119d1
    error InvalidPair();                    // 0x1e4f7d8c
    error MinterDoesNotExist();             // 0x9b01446f
    error MinterExist();                    // 0x82021d69
    error NotConfigOperator();              // 0x528b7142
    error NotExclusionOperator();           // 0xe8854ec0
    error NotMinter();                      // 0xf8d2906c
    error OutOfRange();                     // 0x7db3aba7
    error PriceTooHigh();                   // 0x24fe1192
    error PriceTooLow();                    // 0xdbbbe822
    error TaxTooHigh();                     // 0xaf1ee134
    error TooEarly();                       // 0x085de625

    modifier onlyConfigOperator {
        if(!_configOperators.contains(msg.sender)) revert NotConfigOperator();
        _;
    }

    modifier onlyExclusionOperator {
        if(!_exclusionOperators.contains(msg.sender)) revert NotExclusionOperator();
        _;
    }

    constructor(uint256 taxRate_, address taxCollectorAddress_) {
        if(taxRate_ >= 10000) revert TaxTooHigh();
        if(taxCollectorAddress_ == address(0)) revert ZeroAddress();
        taxRate = taxRate_;
        taxCollectorAddress = taxCollectorAddress_;
        _minters.add(msg.sender);
        _configOperators.add(msg.sender);
        _exclusionOperators.add(msg.sender);
        setExcludeFromTaxAddress(address(this), true);
        setExcludeFromTaxAddress(msg.sender, true);
        setExcludeFromTaxAddress(address(0), true);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) ||
        interfaceId == type(IERC20Burnable).interfaceId ||
        interfaceId == type(IERC20Mintable).interfaceId ||
        interfaceId == type(ITaxableToken).interfaceId;
    }

    function isAddressFromTaxExcluded(address address_) external view virtual override returns (bool) {
        return excludedFromTaxAddresses[address_];
    }

    function isAddressToTaxExcluded(address address_) external view virtual override returns (bool) {
        return excludedToTaxAddresses[address_];
    }

    function setTaxCollectorAddress(address taxCollectorAddress_) external virtual override onlyOperator {
        if(taxCollectorAddress_ == address(0)) revert ZeroAddress();
        taxCollectorAddress = taxCollectorAddress_;
    }

    function getPendingConfigOperators() external view returns (address[] memory) {
        return _pendingConfigOperators.values();
    }

    /**
     * @notice Adds a config operator but add it to pendingConfigOperators
     */
    function addPendingConfigOperator(address configOperator_) external onlyOperator {
        if(_configOperators.contains(configOperator_)) revert ConfigOperatorExist();
        if(_pendingConfigOperators.contains(configOperator_)) revert ConfigOperatorExist();
        _pendingConfigOperators.add(configOperator_);
        pendingConfigOperatorsDelay[configOperator_] = block.timestamp + ADD_CONFIG_OPERATOR_DELAY;
    }

    /**
     * @notice Removes a pending config operator
     */
    function removePendingConfigOperator(address configOperator_) external onlyOperator {
        if(!_pendingConfigOperators.contains(configOperator_)) revert ConfigOperatorDoesNotExist();
        _pendingConfigOperators.remove(configOperator_);
        delete pendingConfigOperatorsDelay[configOperator_];
    }

    function getConfigOperators() external view returns (address[] memory) {
        return _configOperators.values();
    }

    /**
     * @notice Add pending config operator to config operators after time delay
     */
    function addConfigOperator(address configOperator_) external onlyOperator {
        if(_configOperators.contains(configOperator_)) revert ConfigOperatorExist();
        if(!_pendingConfigOperators.contains(configOperator_)) revert ConfigOperatorDoesNotExist();
        if(pendingConfigOperatorsDelay[configOperator_] > block.timestamp) revert TooEarly();
        _pendingConfigOperators.remove(configOperator_);
        delete pendingConfigOperatorsDelay[configOperator_];
        _configOperators.add(configOperator_);
        emit AddedConfigOperator(configOperator_);
    }

    /**
     * @notice Removes config operator
     */
    function removeConfigOperator(address configOperator_) external onlyOperator {
        if(!_configOperators.contains(configOperator_)) revert ConfigOperatorDoesNotExist();
        _configOperators.remove(configOperator_);
        emit RemovedConfigOperator(configOperator_);
    }

    function setTaxTiersTwap(uint8 index_, uint256 value_) external virtual override onlyConfigOperator {
        if(index_ < 0) revert IndexTooLow();
        if(index_ >= taxTiersTwaps.length) revert IndexTooHigh();
        if(index_ > 0) {
            require(value_ > taxTiersTwaps[index_ - 1]);
        }
        if(index_ < (taxTiersTwaps.length - 1)) {
            require(value_ < taxTiersTwaps[index_ + 1]);
        }
        taxTiersTwaps[index_] = value_;
    }

    function setTaxTiersRate(uint8 index_, uint256 value_) external virtual override onlyConfigOperator {
        if(index_ < 0) revert IndexTooLow();
        if(index_ >= taxTiersRates.length) revert IndexTooHigh();
        taxTiersRates[index_] = value_;
    }

    /**
     * @notice Auto-calculate tax to check tax tier for tax
     */
    function setAutoCalculateTax(bool enable_) external virtual override onlyConfigOperator {
        autoCalculateTax = enable_;
    }

    /**
     * @notice Sets the tax rate if auto-calculate tax is not on
     */
    function setTaxRate(uint256 taxRate_) external virtual override onlyConfigOperator {
        if(autoCalculateTax) revert AutoCalculateTaxOn();
        if(taxRate_ >= 10000) revert TaxTooHigh();
        taxRate = taxRate_;
    }

    /**
     * @notice Sets the threshold at which to start burning tokens when taxed
     */
    function setBurnThreshold(uint256 burnThreshold_) external virtual override onlyConfigOperator {
        burnThreshold = burnThreshold_;
    }

    /**
     * @notice Sets the price floor at which selling is prohibited
     */
    function setPriceFloor(uint256 priceFloor_) external virtual override onlyConfigOperator {
        if(priceFloor_ > 1e18) revert PriceTooHigh();
        priceFloor = priceFloor_;
    }

    /**
     * @notice Sets supply rate for percentage of supply that can be sold
     */
    function setSellCeilingSupplyRate(uint256 sellCeilingSupplyRate_) external virtual override onlyConfigOperator {
        if(sellCeilingSupplyRate_ == 0 || sellCeilingSupplyRate_ > 10000) revert OutOfRange();
        sellCeilingSupplyRate = sellCeilingSupplyRate_;
    }

    /**
     * @notice Set the rate at for percentage of liquidity that can be sold
     */
    function setSellCeilingLiquidityRate(uint256 sellCeilingLiquidityRate_) external virtual override onlyConfigOperator {
        if(sellCeilingLiquidityRate_ < 5 || sellCeilingLiquidityRate_ > 10000) revert OutOfRange();
        sellCeilingLiquidityRate = sellCeilingLiquidityRate_;
    }

    /**
     * @notice Set the main liquidity pair to check for liquidity selling limits
     */
    function setLiquidityPair(address liquidityPair_) external virtual onlyConfigOperator {
        address token0 = IUniswapV2Pair(liquidityPair_).token0();
        address token1 = IUniswapV2Pair(liquidityPair_).token1();
        if(token0 != address(this) && token1 != address(this)) revert InvalidPair();
        liquidityPair = liquidityPair_;
    }

    function getPendingExclusionOperators() external view returns (address[] memory) {
        return _pendingExclusionOperators.values();
    }

    /**
     * @notice Adds a exclusion operator but add it to pendingExclusionOperators
     */
    function addPendingExclusionOperator(address exclusionOperator_) external onlyOperator {
        if(_exclusionOperators.contains(exclusionOperator_)) revert ExclusionOperatorExist();
        if(_pendingExclusionOperators.contains(exclusionOperator_)) revert ExclusionOperatorExist();
        _pendingExclusionOperators.add(exclusionOperator_);
        pendingExclusionOperatorsDelay[exclusionOperator_] = block.timestamp + ADD_EXCLUSION_OPERATOR_DELAY;
    }

    /**
     * @notice Removes a pending exclusion operator
     */
    function removePendingExclusionOperator(address exclusionOperator_) external onlyOperator {
        if(!_pendingExclusionOperators.contains(exclusionOperator_)) revert ExclusionOperatorDoesNotExist();
        _pendingExclusionOperators.remove(exclusionOperator_);
        delete pendingExclusionOperatorsDelay[exclusionOperator_];
    }

    function getExclusionOperators() external view returns (address[] memory) {
        return _exclusionOperators.values();
    }

    /**
     * @notice Add pending exclusion operator to exclusion operators after time delay
     */
    function addExclusionOperator(address exclusionOperator_) external onlyOperator {
        if(_exclusionOperators.contains(exclusionOperator_)) revert ExclusionOperatorExist();
        if(!_pendingExclusionOperators.contains(exclusionOperator_)) revert ExclusionOperatorDoesNotExist();
        if(pendingExclusionOperatorsDelay[exclusionOperator_] > block.timestamp) revert TooEarly();
        _pendingExclusionOperators.remove(exclusionOperator_);
        delete pendingExclusionOperatorsDelay[exclusionOperator_];
        _exclusionOperators.add(exclusionOperator_);
        emit AddedExclusionOperator(exclusionOperator_);
    }

    /**
     * @notice Removes exclusion operator
     */
    function removeExclusionOperator(address exclusionOperator_) external onlyOperator {
        if(!_exclusionOperators.contains(exclusionOperator_)) revert ExclusionOperatorDoesNotExist();
        _exclusionOperators.remove(exclusionOperator_);
        emit RemovedExclusionOperator(exclusionOperator_);
    }

    function getExcludeFromTaxAddresses() external view returns (address[] memory) {
        return _excludedFromTaxAddresses.values();
    }

    /**
     * @notice Sets an address to be excluded from for transfers
     */
    function setExcludeFromTaxAddress(address address_, bool exclude_) public virtual override onlyExclusionOperator {
        if(exclude_) {
            if(!_excludedFromTaxAddresses.contains(address_)) _excludedFromTaxAddresses.add(address_);
            excludedFromTaxAddresses[address_] = true;
            emit ExcludeFromTax(address_, true);
        } else {
            if(_excludedFromTaxAddresses.contains(address_)) _excludedFromTaxAddresses.remove(address_);
            excludedFromTaxAddresses[address_] = false;
            emit ExcludeFromTax(address_, false);
        }
    }

    function getExcludeToTaxAddresses() external view returns (address[] memory) {
        return _excludedToTaxAddresses.values();
    }

    /**
     * @notice Sets an address to be excluded to for transfers
     * Must not include LP address
     */
    function setExcludeToTaxAddress(address address_, bool exclude_) public virtual override onlyExclusionOperator {
        if(exclude_) {
            if(!_excludedToTaxAddresses.contains(address_)) _excludedToTaxAddresses.add(address_);
            excludedToTaxAddresses[address_] = true;
            emit ExcludeToTax(address_, true);
        } else {
            if(_excludedToTaxAddresses.contains(address_)) _excludedToTaxAddresses.remove(address_);
            excludedToTaxAddresses[address_] = false;
            emit ExcludeToTax(address_, false);
        }
    }

    /**
     * @notice Returns the current tax rate
     */
    function getTaxRate() external view virtual override returns (uint256) {
        uint256 currentPrice = OracleToken.getPriceUpdated();
        if(autoCalculateTax) {
            for(uint8 tierId = uint8(taxTiersTwaps.length) - 1; tierId >= 0; tierId--) {
                if(currentPrice >= taxTiersTwaps[tierId]) {
                    if(taxTiersRates[tierId] >= 10000) revert TaxTooHigh();
                    return taxTiersRates[tierId];
                }
            }
        }
        return taxRate;
    }

    /**
     * @notice Updates the current tax rate based off the price and tier
     */
    function _updateTaxRate(uint256 price_) internal virtual returns (uint256) {
        if(autoCalculateTax) {
            for(uint8 tierId = uint8(taxTiersTwaps.length) - 1; tierId >= 0; tierId--) {
                if(price_ >= taxTiersTwaps[tierId]) {
                    if(taxTiersRates[tierId] >= 10000) revert TaxTooHigh();
                    taxRate = taxTiersRates[tierId];
                    return taxTiersRates[tierId];
                }
            }
        }
        return taxRate;
    }

    /**
     * @notice Gets the selling limit based off supply or liquidity
     */
    function sellingLimit() public view override returns (uint256) {
        uint256 _limitBySupply = (totalSupply() * sellCeilingSupplyRate) / 10000;
        uint256 _reserveAmount = _getAmountInReserves();
        if (_reserveAmount == 0) return _limitBySupply;
        uint256 _limitByLiquidity = (_reserveAmount * sellCeilingLiquidityRate) / 10000;
        return (_limitBySupply > _limitByLiquidity) ? _limitByLiquidity : _limitBySupply;
    }

    /**
     * @notice Gets the amount in reserve
     */
    function _getAmountInReserves() internal view returns (uint256 reserve) {
        address pair = liquidityPair;
        if(pair != address(0)) {
            (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
            if(IUniswapV2Pair(pair).token0() == address(this)) {
                reserve = reserve0;
            } else {
                reserve = reserve1;
            }
        }
        return reserve;
    }

    function getPendingMinters() external view returns (address[] memory) {
        return _pendingMinters.values();
    }

    /**
     * @notice Adds a minter but add it to pendingMinters
     */
    function addPendingMinter(address minter_) external onlyOperator {
        if(_minters.contains(minter_)) revert MinterExist();
        if(_pendingMinters.contains(minter_)) revert MinterExist();
        _pendingMinters.add(minter_);
        pendingMintersDelay[minter_] = block.timestamp + ADD_MINTER_DELAY;
    }

    /**
     * @notice Removes a pending minter
     */
    function removePendingMinter(address minter_) external onlyOperator {
        if(!_pendingMinters.contains(minter_)) revert MinterDoesNotExist();
        _pendingMinters.remove(minter_);
        delete pendingMintersDelay[minter_];
    }

    function getMinters() external view returns (address[] memory) {
        return _minters.values();
    }

    /**
     * @notice Add pending minter to minter after time delay
     */
    function addMinter(address minter_) external onlyOperator {
        if(_minters.contains(minter_)) revert MinterExist();
        if(!_pendingMinters.contains(minter_)) revert MinterDoesNotExist();
        if(pendingMintersDelay[minter_] > block.timestamp) revert TooEarly();
        _pendingMinters.remove(minter_);
        delete pendingMintersDelay[minter_];
        _minters.add(minter_);
        emit AddedMinter(minter_);
    }

    /**
     * @notice Removes minter
     */
    function removeMinter(address minter_) external onlyOperator {
        if(!_minters.contains(minter_)) revert MinterDoesNotExist();
        _minters.remove(minter_);
        emit RemovedMinter(minter_);
    }

    /**
     * @notice Minting only allowed by minters
     */
    function mint(address to_, uint256 amount_) public virtual override returns (bool) {
        if(!_minters.contains(msg.sender)) revert NotMinter();
        uint256 balanceBefore = balanceOf(to_);
        _mint(to_, amount_);
        uint256 balanceAfter = balanceOf(to_);
        return balanceAfter > balanceBefore;
    }

    function burn(uint256 amount_) public virtual override(ERC20Burnable, IERC20Burnable) {
        super.burn(amount_);
    }

    function burnFrom(address account_, uint256 amount_) public virtual override(ERC20Burnable, IERC20Burnable) {
        super.burnFrom(account_, amount_);
    }

    /**
     * @notice Allows certain addresses to transfer without check
     * Transfers are limited based off price, liquidity, and selling amount
     */
    function _transfer(address from_, address to_, uint256 amount_) internal virtual override {
        uint256 currentTaxRate;
        bool burnTax = false;
        uint256 currentPrice = OracleToken.getPriceUpdated();

        if(autoCalculateTax) {
            currentTaxRate = _updateTaxRate(currentPrice);
            if(currentPrice < burnThreshold) {
                burnTax = true;
            }
        }

        if(currentTaxRate == 0 || excludedFromTaxAddresses[from_] || excludedToTaxAddresses[to_]) {
            super._transfer(from_, to_, amount_);
        } else {
            if(currentPrice <= priceFloor) revert PriceTooLow();
            if(amount_ > sellingLimit()) revert AmountTooHigh();

            // transfer with tax
            uint256 taxAmount = (amount_ * taxRate) / 10000;
            uint256 amountAfterTax = amount_ - taxAmount;

            if(burnTax) {
                // Burn tax
                super._burn(from_, taxAmount);
            } else {
                // Transfer tax to tax collector
                super._transfer(from_, taxCollectorAddress, taxAmount);
            }

            // Transfer amount after tax to recipient
            super._transfer(from_, to_, amountAfterTax);
        }
    }

    /**
     * @notice Keeps track of burned amount
     */
    function _burn(address from_, uint256 amount_) internal virtual override {
        totalBurned += amount_;
        super._burn(from_, amount_);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../../lib/AccessControlConstants.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IOracleToken.sol";

/**
 * @title OracleToken
 */
abstract contract OracleToken is AccessControlEnumerable, IOracleToken {
    address public override oracle;

    error FailedToGetPrice();   // 0x3428a74c
    error IndexTooLow();        // 0x9d445a78
    error IndexTooHigh();       // 0xfbf22ac0
    error NotOperator();        // 0x7c214f04
    error ZeroAddress();        // 0xd92e233d

    modifier onlyOperator {
        if(!AccessControl.hasRole(AccessControlConstants.OPERATOR_ROLE, msg.sender)) revert NotOperator();
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) ||
        interfaceId == type(IOracleToken).interfaceId;
    }

    function setOracle(address oracle_) external virtual override onlyOperator {
        oracle = oracle_;
    }

    function getPrice() public view virtual override returns (uint256 price) {
        address oracle_ = oracle;
        if(oracle_ == address(0)) {
            return 1 ether;
        } else {
            return IOracle(oracle_).getPegPrice();
        }
    }

    function getPriceUpdated() public view virtual override returns (uint256 price) {
        address oracle_ = oracle;
        if(oracle_ == address(0)) {
            return 1 ether;
        } else {
            return IOracle(oracle_).getPegPriceUpdated();
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/INFTPools.sol";
import "../nft/interfaces/INFTPower.sol";
import "./interfaces/INFTToken.sol";
import "./OracleToken.sol";

/**
 * @title NFTToken
 * Requires power within NFT to sell at each twap tier
 */
abstract contract NFTToken is ERC20, OracleToken, INFTToken {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;
    EnumerableSet.AddressSet internal _nftContracts;      // supported nft contracts
    EnumerableSet.AddressSet internal _nftPoolsContracts; // supported nft pools contracts
    uint256 public override nftPowerRequired;   // the current power of nfts from nft contracts required to send
    bool public autoCalculateNFTPowerRequired;  // should nft power requirement be calculated using the nft tiers
    uint256[] public nftTiersTwaps = [0, 5e17, 6e17, 7e17, 8e17, 9e17, 9.5e17, 1e18, 1.05e18, 1.10e18, 1.20e18, 1.30e18, 1.40e18, 1.50e18];
    uint256[] public nftTiersPowerRequired = [10000, 5000, 2500, 1000, 500, 250, 100, 10, 0, 0, 0, 0, 0, 0];
    mapping(address => bool) public excludedFromNFTAddresses; // addresses excluded from nft requirement when sending
    mapping(address => bool) public excludedToNFTAddresses; // addresses excluded from nft requirement when receiving
    EnumerableSet.AddressSet internal _excludedFromNFTAddresses;
    EnumerableSet.AddressSet internal _excludedToNFTAddresses;
    EnumerableSet.AddressSet internal _nftConfigOperators; // handles setting of power
    EnumerableSet.AddressSet internal _pendingNFTConfigOperators; // pending configOperators
    mapping(address => uint256) public pendingNFTConfigOperatorsDelay; // time allowed to apply the pending config operator
    uint256 public constant ADD_NFT_CONFIG_OPERATOR_DELAY = 24 hours;
    EnumerableSet.AddressSet internal _nftExclusionOperators; // handles setting of exclusions
    EnumerableSet.AddressSet internal _pendingNFTExclusionOperators; // pending exclusionOperators
    mapping(address => uint256) public pendingNFTExclusionOperatorsDelay; // time allowed to apply the pending exclusion operator
    uint256 public constant ADD_NFT_EXCLUSION_OPERATOR_DELAY = 24 hours;

    event ErrorString(string reason);
    event ErrorPanic(uint reason);
    event ErrorBytes(bytes reason);
    event ExcludeFromNFT(address indexed account, bool exclude);
    event ExcludeToNFT(address indexed account, bool exclude);
    event AddedNFTConfigOperator(address indexed nftConfigOperator);
    event RemovedNFTConfigOperator(address indexed nftConfigOperator);
    event AddedNFTExclusionOperator(address indexed nftExclusionOperator);
    event RemovedNFTExclusionOperator(address indexed nftExclusionOperator);

    error AutoCalculateNFTPowerRequiredOn();    // 0x9360bc78
    error DoesNotExist();                       // 0xb0ce7591
    error Exist();                              // 0x65956805
    error InterfaceNotSupported();              // 0x2c7ca6d7
    error NFTConfigOperatorDoesNotExist();      // 0x7e735b49
    error NFTConfigOperatorExist();             // 0xdc4b48a9
    error NFTExclusionOperatorDoesNotExist();   // 0x1d8e4ef5
    error NFTExclusionOperatorExist();          // 0xe38ec516
    error NFTPowerRequired();                   // 0x4bad0131
    error NFTTooEarly();                        // 0x9647003d
    error NotNFTConfigOperator();               // 0x15e6bc82
    error NotNFTExclusionOperator();            // 0x75c573a0

    modifier onlyNFTConfigOperator {
        if(!_nftConfigOperators.contains(msg.sender)) revert NotNFTConfigOperator();
        _;
    }

    modifier onlyNFTExclusionOperator {
        if(!_nftExclusionOperators.contains(msg.sender)) revert NotNFTExclusionOperator();
        _;
    }

    constructor() {
        _nftConfigOperators.add(msg.sender);
        _nftExclusionOperators.add(msg.sender);
        setExcludeFromNFTAddress(address(this), true);
        setExcludeFromNFTAddress(msg.sender, true);
        setExcludeFromNFTAddress(address(0), true);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) ||
        interfaceId == type(INFTToken).interfaceId;
    }

    function isAddressFromNFTExcluded(address address_) external view virtual override returns (bool) {
        return excludedFromNFTAddresses[address_];
    }

    function isAddressToNFTExcluded(address address_) external view virtual override returns (bool) {
        return excludedToNFTAddresses[address_];
    }

    function getPendingNFTConfigOperators() external view returns (address[] memory) {
        return _pendingNFTConfigOperators.values();
    }

    /**
     * @notice Adds a nft config operator but add it to pendingConfigOperators
     */
    function addPendingNFTConfigOperator(address nftConfigOperator_) external onlyOperator {
        if(_nftConfigOperators.contains(nftConfigOperator_)) revert NFTConfigOperatorExist();
        if(_pendingNFTConfigOperators.contains(nftConfigOperator_)) revert NFTConfigOperatorExist();
        _pendingNFTConfigOperators.add(nftConfigOperator_);
        pendingNFTConfigOperatorsDelay[nftConfigOperator_] = block.timestamp + ADD_NFT_CONFIG_OPERATOR_DELAY;
    }

    /**
     * @notice Removes a pending nft config operator
     */
    function removeNFTPendingConfigOperator(address nftConfigOperator_) external onlyOperator {
        if(!_pendingNFTConfigOperators.contains(nftConfigOperator_)) revert NFTConfigOperatorDoesNotExist();
        _pendingNFTConfigOperators.remove(nftConfigOperator_);
        delete pendingNFTConfigOperatorsDelay[nftConfigOperator_];
    }

    function getNFTConfigOperators() external view returns (address[] memory) {
        return _nftConfigOperators.values();
    }

    /**
     * @notice Add pending nft config operator to config operators after time delay
     */
    function addNFTConfigOperator(address nftConfigOperator_) external onlyOperator {
        if(_nftConfigOperators.contains(nftConfigOperator_)) revert NFTConfigOperatorExist();
        if(!_pendingNFTConfigOperators.contains(nftConfigOperator_)) revert NFTConfigOperatorDoesNotExist();
        if(pendingNFTConfigOperatorsDelay[nftConfigOperator_] > block.timestamp) revert NFTTooEarly();
        _pendingNFTConfigOperators.remove(nftConfigOperator_);
        delete pendingNFTConfigOperatorsDelay[nftConfigOperator_];
        _nftConfigOperators.add(nftConfigOperator_);
        emit AddedNFTConfigOperator(nftConfigOperator_);
    }

    /**
     * @notice Removes nft config operator
     */
    function removeNFTConfigOperator(address nftConfigOperator_) external onlyOperator {
        if(!_nftConfigOperators.contains(nftConfigOperator_)) revert NFTConfigOperatorDoesNotExist();
        _nftConfigOperators.remove(nftConfigOperator_);
        emit RemovedNFTConfigOperator(nftConfigOperator_);
    }

    function setNFTTiersTwap(uint8 index_, uint256 value_) external virtual override onlyNFTConfigOperator {
        if(index_ < 0) revert IndexTooLow();
        if(index_ >= nftTiersTwaps.length) revert IndexTooHigh();
        if(index_ > 0) {
            require(value_ > nftTiersTwaps[index_ - 1]);
        }
        if(index_ < (nftTiersTwaps.length - 1)) {
            require(value_ < nftTiersTwaps[index_ + 1]);
        }
        nftTiersTwaps[index_] = value_;
    }

    function setNFTTiersPowerRequired(uint8 index_, uint256 value_) external virtual override onlyNFTConfigOperator {
        if(index_ < 0) revert IndexTooLow();
        if(index_ >= nftTiersPowerRequired.length) revert IndexTooHigh();
        nftTiersPowerRequired[index_] = value_;
    }

    /**
     * @notice Auto-calculate power to check power tier for power
     */
    function setAutoCalculateNFTPowerRequired(bool enable_) external virtual override onlyNFTConfigOperator {
        autoCalculateNFTPowerRequired = enable_;
    }

    /**
     * @notice Sets the power required if auto-calculate power is not on
     */
    function setNFTPowerRequired(uint256 power_) external virtual override onlyNFTConfigOperator {
        if(autoCalculateNFTPowerRequired) revert AutoCalculateNFTPowerRequiredOn();
        nftPowerRequired = power_;
    }

    function getPendingNFTExclusionOperators() external view returns (address[] memory) {
        return _pendingNFTExclusionOperators.values();
    }

    /**
     * @notice Adds a nft exclusion operator but add it to pendingNFTExclusionOperators
     */
    function addPendingNFTExclusionOperator(address nftExclusionOperator_) external onlyOperator {
        if(_nftExclusionOperators.contains(nftExclusionOperator_)) revert NFTExclusionOperatorExist();
        if(_pendingNFTExclusionOperators.contains(nftExclusionOperator_)) revert NFTExclusionOperatorExist();
        _pendingNFTExclusionOperators.add(nftExclusionOperator_);
        pendingNFTExclusionOperatorsDelay[nftExclusionOperator_] = block.timestamp + ADD_NFT_EXCLUSION_OPERATOR_DELAY;
    }

    /**
     * @notice Removes a pending nft exclusion operator
     */
    function removePendingNFTExclusionOperator(address nftExclusionOperator_) external onlyOperator {
        if(!_pendingNFTExclusionOperators.contains(nftExclusionOperator_)) revert NFTExclusionOperatorDoesNotExist();
        _pendingNFTExclusionOperators.remove(nftExclusionOperator_);
        delete pendingNFTExclusionOperatorsDelay[nftExclusionOperator_];
    }

    function getNFTExclusionOperators() external view returns (address[] memory) {
        return _nftExclusionOperators.values();
    }

    /**
     * @notice Add pending nft exclusion operator to nft exclusion operators after time delay
     */
    function addNFTExclusionOperator(address nftExclusionOperator_) external onlyOperator {
        if(_nftExclusionOperators.contains(nftExclusionOperator_)) revert NFTExclusionOperatorExist();
        if(!_pendingNFTExclusionOperators.contains(nftExclusionOperator_)) revert NFTExclusionOperatorDoesNotExist();
        if(pendingNFTExclusionOperatorsDelay[nftExclusionOperator_] > block.timestamp) revert NFTTooEarly();
        _pendingNFTExclusionOperators.remove(nftExclusionOperator_);
        delete pendingNFTExclusionOperatorsDelay[nftExclusionOperator_];
        _nftExclusionOperators.add(nftExclusionOperator_);
        emit AddedNFTExclusionOperator(nftExclusionOperator_);
    }

    /**
     * @notice Removes nft exclusion operator
     */
    function removeNFTExclusionOperator(address nftExclusionOperator_) external onlyOperator {
        if(!_nftExclusionOperators.contains(nftExclusionOperator_)) revert NFTExclusionOperatorDoesNotExist();
        _nftExclusionOperators.remove(nftExclusionOperator_);
        emit RemovedNFTExclusionOperator(nftExclusionOperator_);
    }

    function getExcludeFromNFTAddresses() external view returns (address[] memory) {
        return _excludedFromNFTAddresses.values();
    }

    /**
     * @notice Sets an address to be excluded from for transfers
     */
    function setExcludeFromNFTAddress(address address_, bool exclude_) public virtual override onlyNFTExclusionOperator {
        if(exclude_) {
            if(!_excludedFromNFTAddresses.contains(address_)) _excludedFromNFTAddresses.add(address_);
            excludedFromNFTAddresses[address_] = true;
            emit ExcludeFromNFT(address_, true);
        } else {
            if(_excludedFromNFTAddresses.contains(address_)) _excludedFromNFTAddresses.remove(address_);
            excludedFromNFTAddresses[address_] = false;
            emit ExcludeFromNFT(address_, false);
        }
    }

    /**
     * @notice Sets an address to be excluded to for transfers
     * Must not include LP address
     */
    function setExcludeToNFTAddress(address address_, bool exclude_) public virtual override onlyNFTExclusionOperator {
        if(exclude_) {
            if(!_excludedToNFTAddresses.contains(address_)) _excludedToNFTAddresses.add(address_);
            excludedToNFTAddresses[address_] = true;
            emit ExcludeToNFT(address_, true);
        } else {
            if(_excludedToNFTAddresses.contains(address_)) _excludedToNFTAddresses.remove(address_);
            excludedToNFTAddresses[address_] = false;
            emit ExcludeToNFT(address_, false);
        }
    }

    function getNFTContracts() external view override returns (address[] memory) {
        return _nftContracts.values();
    }

    function addNFTContract(address nftContract_) external override onlyNFTConfigOperator {
        if(_nftContracts.contains(nftContract_)) revert Exist();
        if(!IERC165(nftContract_).supportsInterface(type(INFTPower).interfaceId)) revert InterfaceNotSupported();
        _nftContracts.add(nftContract_);
    }

    function removeNFTContract(address nftContract_) external override onlyNFTConfigOperator {
        if(!_nftContracts.contains(nftContract_)) revert DoesNotExist();
        _nftContracts.remove(nftContract_);
    }

    function getNFTPoolsContracts() external view override returns (address[] memory) {
        return _nftPoolsContracts.values();
    }

    function addNFTPoolsContract(address nftPoolsContract_) external override onlyNFTConfigOperator {
        if(_nftPoolsContracts.contains(nftPoolsContract_)) revert Exist();
        if(!IERC165(nftPoolsContract_).supportsInterface(type(INFTPools).interfaceId)) revert InterfaceNotSupported();
        _nftPoolsContracts.add(nftPoolsContract_);
    }

    function removeNFTPoolsContract(address nftPoolsContract_) external override onlyNFTConfigOperator {
        if(!_nftPoolsContracts.contains(nftPoolsContract_)) revert DoesNotExist();
        _nftPoolsContracts.remove(nftPoolsContract_);
    }

    /**
     * @notice Returns the current power required
     */
    function getNFTPowerRequired() external view virtual override returns (uint256) {
        uint256 currentPrice = OracleToken.getPriceUpdated();
        if(autoCalculateNFTPowerRequired) {
            for(uint8 tierId = uint8(nftTiersTwaps.length) - 1; tierId >= 0; tierId--) {
                if(currentPrice >= nftTiersTwaps[tierId]) {
                    return nftTiersPowerRequired[tierId];
                }
            }
        }
        return nftPowerRequired;
    }

    /**
     * @notice Updates the current power required based off the price and tier
     */
    function _updateNFTPowerRequired(uint256 price_) internal virtual returns (uint256) {
        if(autoCalculateNFTPowerRequired) {
            for(uint8 tierId = uint8(nftTiersTwaps.length) - 1; tierId >= 0; tierId--) {
                if(price_ >= nftTiersTwaps[tierId]) {
                    nftPowerRequired = nftTiersPowerRequired[tierId];
                    return nftTiersPowerRequired[tierId];
                }
            }
        }
        return nftPowerRequired;
    }

    /**
     * @notice Ensures that the sender has nft power
     */
    function _beforeTokenTransfer(address from_, address to_, uint256 amount_) internal virtual override {
        uint256 currentNFTPowerRequired;

        if(autoCalculateNFTPowerRequired) {
            uint256 currentPrice = OracleToken.getPriceUpdated();
            currentNFTPowerRequired = _updateNFTPowerRequired(currentPrice);
        }

        if(currentNFTPowerRequired != 0 && !excludedFromNFTAddresses[from_] && !excludedToNFTAddresses[to_]) {
            uint256 power;
            // get power from held nft
            for(uint256 i; i < _nftContracts.length(); i++) {
                address nftContract = _nftContracts.at(i);
                try INFTPower(nftContract).getUserPower(from_) returns (uint256 val) {
                    power += val;
                } catch Error(string memory reason) {
                    emit ErrorString(reason);
                } catch Panic(uint reason) {
                    emit ErrorPanic(reason);
                } catch (bytes memory reason) {
                    emit ErrorBytes(reason);
                }
                if(power >= currentNFTPowerRequired) break;
            }
            // get power from staked nft
            for(uint256 i; i < _nftPoolsContracts.length(); i++) {
                address nftPoolsContract = _nftPoolsContracts.at(i);
                try INFTPools(nftPoolsContract).getStakedNFTPower(from_) returns (uint256 val) {
                    power += val;
                } catch Error(string memory reason) {
                    emit ErrorString(reason);
                } catch Panic(uint reason) {
                    emit ErrorPanic(reason);
                } catch (bytes memory reason) {
                    emit ErrorBytes(reason);
                }
                if(power >= currentNFTPowerRequired) break;
            }
            if(power < currentNFTPowerRequired) revert NFTPowerRequired();
        }
        super._beforeTokenTransfer(from_, to_, amount_);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library AccessControlConstants {
    /**
     * Access Control Roles
     */
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR"); // 523a704056dcd17bcf83bed8b68c59416dac1119be77755efe3bde0a64e46e0c
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");     // f0887ba65ee2024ea881d91b74c2450ef19e1557f03bed3ea9f16b037cbe2dc9
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");       // df8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW"); // 7a8dc26796a1e50e6e190b70259f58f6a4edd5b22280ceecc82b687b8e982869
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./IUniswapV2ERC20.sol";

interface IUniswapV2Pair is IUniswapV2ERC20 {
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);
    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint256);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}