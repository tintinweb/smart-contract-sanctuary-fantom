/**
 *Submitted for verification at FtmScan.com on 2022-03-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IBondInformationHelper {
    function name(address _bond) external view returns (string memory);

    function symbol(address _bond) external view returns (string memory);
}

interface IRedeemHelper {
    function bonds(uint256 index) external view returns (address);
}

interface ITreasury {
    function isLiquidityDepositor(address depositor)
        external
        view
        returns (bool);

    function isReserveDepositor(address depositor) external view returns (bool);

    function isRewardManager(address depositor) external view returns (bool);
}

interface IBond {
    function bondInfo(address depositor)
        external
        view
        returns (
            uint256 payout,
            uint256 vesting,
            uint256 lastBlock,
            uint256 pricePaid
        );

    function bondPrice() external view returns (uint256);

    function bondPriceInUSD() external view returns (uint256);

    function currentDebt() external view returns (uint256);

    function debtDecay() external view returns (uint256);

    function debtRatio() external view returns (uint256);

    function isLiquidityBond() external view returns (bool);

    function lastDecay() external view returns (uint256);

    function maxPayout() external view returns (uint256);

    function pendingPayoutFor(address depositor)
        external
        view
        returns (uint256 pendingPayout_);

    function percentVestedFor(address depositor)
        external
        view
        returns (uint256 percentVested_);

    function principle() external view returns (address);

    function standardizedDebtRatio() external view returns (uint256);

    function totalDebt() external view returns (uint256);
}

contract BondAggregator {
    IRedeemHelper public constant REEDEM_HELPER =
        IRedeemHelper(0x9d1530475b6282Bd92da5628E36052f70C56A208);
    ITreasury public constant TREASURY =
        ITreasury(0x6A654D988eEBCD9FfB48ECd5AF9Bd79e090D8347);
    IBondInformationHelper HELPER =
        IBondInformationHelper(0xd915Aff2F6AFB96F4d8765C663b60c8a5AdC6729);

    struct BondInformation {
        address bond;
        address principle;
        string name;
        string symbol;
        uint256 bondPrice;
        uint256 bondPriceInUSD;
        uint256 currentDebt;
        uint256 debtDecay;
        uint256 debtRatio;
        bool isLiquidityBond;
        uint256 lastDecay;
        uint256 maxPayout;
        uint256 standardizedDebtRatio;
        uint256 totalDebt;
    }

    struct DepositorBondInfo {
        address bond;
        uint256 payout;
        uint256 vesting;
        uint256 lastBlock;
        uint256 pricePaid;
        uint256 pendingPayout;
        uint256 percentVested;
    }

    function _getBondAtIndex(uint256 index) internal view returns (address) {
        address bond = address(0);
        try REEDEM_HELPER.bonds(index) returns (address bond_) {
            bond = bond_;
        } catch {}
        return bond;
    }

    function activeBonds() public view returns (address[] memory) {
        address[] memory tmp = new address[](50);

        uint8 foundCount = 0;
        for (uint256 i = 0; i < tmp.length; i++) {
            address bond = _getBondAtIndex(i);

            if (bond != address(0)) {
                if (
                    TREASURY.isRewardManager(bond) ||
                    TREASURY.isLiquidityDepositor(bond) ||
                    TREASURY.isReserveDepositor(bond)
                ) {
                    tmp[foundCount] = bond;
                    foundCount++;
                }
            }
        }

        address[] memory result = new address[](foundCount);

        for (uint8 i = 0; i < foundCount; i++) {
            result[i] = tmp[i];
        }

        return result;
    }

    function bondDetails(address _bond)
        public
        view
        returns (BondInformation memory)
    {
        IBond bond = IBond(_bond);

        bool isLP = false;
        try bond.isLiquidityBond() returns (bool lp_) {
            isLP = lp_;
        } catch {}

        return
            BondInformation({
                bond: _bond,
                principle: bond.principle(),
                name: HELPER.name(_bond),
                symbol: HELPER.symbol(_bond),
                bondPrice: bond.bondPrice(),
                bondPriceInUSD: bond.bondPriceInUSD(),
                currentDebt: bond.currentDebt(),
                debtDecay: bond.debtDecay(),
                debtRatio: bond.debtRatio(),
                isLiquidityBond: isLP,
                lastDecay: bond.lastDecay(),
                maxPayout: bond.maxPayout(),
                standardizedDebtRatio: bond.standardizedDebtRatio(),
                totalDebt: bond.totalDebt()
            });
    }

    function bondInfoForDepositor(address _bond, address depositor)
        public
        view
        returns (DepositorBondInfo memory)
    {
        IBond bond = IBond(_bond);

        (
            uint256 payout,
            uint256 vesting,
            uint256 lastBlock,
            uint256 pricePaid
        ) = bond.bondInfo(depositor);

        return
            DepositorBondInfo({
                bond: _bond,
                payout: payout,
                vesting: vesting,
                lastBlock: lastBlock,
                pricePaid: pricePaid,
                pendingPayout: bond.pendingPayoutFor(depositor),
                percentVested: bond.percentVestedFor(depositor)
            });
    }

    function activeBondsInfoForDepositor(address depositor)
        external
        view
        returns (DepositorBondInfo[] memory)
    {
        address[] memory bonds = activeBonds();
        DepositorBondInfo[] memory results = new DepositorBondInfo[](
            bonds.length
        );

        for (uint256 i = 0; i < bonds.length; i++) {
            results[i] = bondInfoForDepositor(bonds[i], depositor);
        }

        return results;
    }

    function activeBondsDetails()
        external
        view
        returns (BondInformation[] memory)
    {
        address[] memory bonds = activeBonds();
        BondInformation[] memory results = new BondInformation[](bonds.length);

        for (uint256 i = 0; i < bonds.length; i++) {
            results[i] = bondDetails(bonds[i]);
        }

        return results;
    }
}