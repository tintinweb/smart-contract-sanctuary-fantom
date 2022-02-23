// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "../shared/interfaces/IBond.sol";
import "../shared/types/MetaVaultAC.sol";

contract RedeemHelper is MetaVaultAC {
    address[] public bonds;

    constructor(address _authority) MetaVaultAC(IMetaVaultAuthority(_authority)) {}

    function redeemAll(address _recipient, bool _stake) external {
        for (uint256 i = 0; i < bonds.length; i++) {
            if (bonds[i] != address(0)) {
                if (IBond(bonds[i]).pendingPayoutFor(_recipient) > 0) {
                    IBond(bonds[i]).redeem(_recipient, _stake);
                }
            }
        }
    }

    function addBondContract(address _bond) external onlyPolicy {
        require(_bond != address(0));
        bonds.push(_bond);
    }

    function removeBondContract(uint256 _index) external onlyPolicy {
        bonds[_index] = address(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IBond {
    function initializeBondTerms(
        uint256 _controlVariable,
        uint256 _vestingTerm,
        uint256 _minimumPrice,
        uint256 _maxPayout,
        uint256 _fee,
        uint256 _maxDebt,
        uint256 _initialDebt
    ) external;

    function totalDebt() external view returns (uint256);

    function isLiquidityBond() external view returns (bool);

    function bondPrice() external view returns (uint256);

    function bondPriceInUSD() external view returns (uint256 price_);

    function redeem(address _recipient, bool _stake) external returns (uint256);

    function pendingPayoutFor(address _depositor) external view returns (uint256 pendingPayout_);

    function deposit(
        uint256 _amount,
        uint256 _maxPrice,
        address _depositor
    ) external returns (uint256);

    function principle() external view returns (address);

    function terms()
        external
        view
        returns (
            uint256 controlVariable, // scaling variable for price
            uint256 vestingTerm, // in blocks
            uint256 minimumPrice, // vs principle value
            uint256 maxPayout, // in thousandths of a %. i.e. 500 = 0.5%
            uint256 fee, // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
            uint256 maxDebt // 9 decimal debt ratio, max % total supply created as debt
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "../interfaces/IMetaVaultAuthority.sol";

abstract contract MetaVaultAC {
    IMetaVaultAuthority public authority;

    event AuthorityUpdated(IMetaVaultAuthority indexed authority);

    constructor(IMetaVaultAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), "MetavaultAC: caller is not the Governer");
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), "MetavaultAC: caller is not the Policy");
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), "MetavaultAC: caller is not the Vault");
        _;
    }

    function setAuthority(IMetaVaultAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IMetaVaultAuthority {
    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    function governor() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);
}