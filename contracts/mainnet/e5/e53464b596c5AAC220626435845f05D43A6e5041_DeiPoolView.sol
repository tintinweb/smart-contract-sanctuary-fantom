// Be name Khoda
// Bime Abolfazl

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ============================= DEIPoolView =============================
// ====================================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Kazem Gh: https://github.com/KazemGhareghani

import "./DEIPoolLibrary.sol";
import "../../DEI/IDEI.sol";

contract DeiPoolView {
    // Number of decimals needed to get to 18
    uint256 private immutable missing_decimals = 12;
    uint256 public minting_fee = 5000;
    uint256 public redemption_fee = 5000;

    DEIPoolLibrary poolLibrary;
    address public dei;

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;

    constructor(address _dei, address _library) {
        dei = _dei;
        poolLibrary = DEIPoolLibrary(_library);
    }

    function mint1t1DEI(uint256 collateral_amount, uint256 collateral_price)
        public
        view
        returns (uint256 dei_amount_d18)
    {
        uint256 collateral_amount_d18 = collateral_amount *
            (10**missing_decimals);
        dei_amount_d18 = poolLibrary.calcMint1t1DEI(
            collateral_price,
            collateral_amount_d18
        ); //1 DEI for each $1 worth of collateral
        dei_amount_d18 = (dei_amount_d18 * (uint256(1e6) - minting_fee)) / 1e6; //remove precision at the end
    }

    function mintAlgorithmicDEI(
        uint256 deus_amount_d18,
        uint256 deus_current_price
    ) public view returns (uint256 dei_amount_d18) {
        dei_amount_d18 = poolLibrary.calcMintAlgorithmicDEI(
            deus_current_price, // X DEUS / 1 USD
            deus_amount_d18
        );
        dei_amount_d18 =
            (dei_amount_d18 * (uint256(1e6) - (minting_fee))) /
            (1e6);
    }

    function mintFractionalDEI(
        uint256 collateral_amount,
        uint256 deus_amount,
        uint256 collateral_price,
        uint256 deus_current_price
    ) public view returns (uint256 mint_amount) {
        uint256 global_collateral_ratio = IDEIStablecoin(dei)
            .global_collateral_ratio();
        DEIPoolLibrary.MintFD_Params memory input_params;

        uint256 collateral_amount_d18 = collateral_amount *
            (10**missing_decimals);
        input_params = DEIPoolLibrary.MintFD_Params(
            deus_current_price,
            collateral_price,
            collateral_amount_d18,
            global_collateral_ratio
        );

        uint256 deus_needed;
        (mint_amount, deus_needed) = poolLibrary.calcMintFractionalDEI(
            input_params
        );
        require(deus_needed <= deus_amount, "Not enough DEUS inputted");
        mint_amount = (mint_amount * (uint256(1e6) - minting_fee)) / (1e6);
    }

    function redeem1t1DEI(uint256 dei_amount, uint256 collateral_price)
        public
        view
        returns (uint256 collateral_needed)
    {
        uint256 DEI_amount_precision = dei_amount / (10**missing_decimals);
        collateral_needed = poolLibrary.calcRedeem1t1DEI(
            collateral_price,
            DEI_amount_precision
        );

        collateral_needed =
            (collateral_needed * (uint256(1e6) - redemption_fee)) /
            (1e6);
    }

    function redeemFractionalDEI(
        uint256 dei_amount,
        uint256 collateral_price,
        uint256 deus_current_price
    ) public view returns (uint256 deus_amount, uint256 collateral_amount) {
        uint256 global_collateral_ratio = IDEIStablecoin(dei)
            .global_collateral_ratio();
        uint256 DEI_amount_post_fee = (dei_amount *
            (uint256(1e6) - redemption_fee)) / (PRICE_PRECISION);
        uint256 deus_dollar_value_d18 = DEI_amount_post_fee -
            ((DEI_amount_post_fee * global_collateral_ratio) /
                (PRICE_PRECISION));
        deus_amount =
            (deus_dollar_value_d18 * (PRICE_PRECISION)) /
            (deus_current_price);
        // Need to adjust for decimals of collateral
        uint256 DEI_amount_precision = DEI_amount_post_fee /
            (10**missing_decimals);
        uint256 collateral_dollar_value = (DEI_amount_precision *
            global_collateral_ratio) / PRICE_PRECISION;
        collateral_amount =
            (collateral_dollar_value * PRICE_PRECISION) /
            (collateral_price);
    }

    function redeemAlgorithmicDEI(
        uint256 dei_amount,
        uint256 deus_current_price
    ) public view returns (uint256 deus_amount) {
        uint256 deus_dollar_value_d18 = dei_amount;
        deus_dollar_value_d18 =
            (deus_dollar_value_d18 * (uint256(1e6) - redemption_fee)) /
            1e6; //apply fees
        deus_amount =
            (deus_dollar_value_d18 * (PRICE_PRECISION)) /
            deus_current_price;
    }
}

// Be name Khoda
// Bime Abolfazl

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

contract DEIPoolLibrary {

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;

    constructor() {}

    // ================ Structs ================
    // Needed to lower stack size
    struct MintFD_Params {
        uint256 deus_price_usd; 
        uint256 col_price_usd;
        uint256 collateral_amount;
        uint256 col_ratio;
    }

    struct BuybackDEUS_Params {
        uint256 excess_collateral_dollar_value_d18;
        uint256 deus_price_usd;
        uint256 col_price_usd;
        uint256 DEUS_amount;
    }

    // ================ Functions ================

    function calcMint1t1DEI(uint256 col_price, uint256 collateral_amount_d18) public pure returns (uint256) {
        return (collateral_amount_d18 * col_price) / (1e6);
    }

    function calcMintAlgorithmicDEI(uint256 deus_price_usd, uint256 deus_amount_d18) public pure returns (uint256) {
        return (deus_amount_d18 * deus_price_usd) / (1e6);
    }

    function calcMintFractionalDEI(MintFD_Params memory params) public pure returns (uint256, uint256) {
        // Since solidity truncates division, every division operation must be the last operation in the equation to ensure minimum error
        // The contract must check the proper ratio was sent to mint DEI. We do this by seeing the minimum mintable DEI based on each amount 
        uint256 c_dollar_value_d18;
        
        // Scoping for stack concerns
        {    
            // USD amounts of the collateral and the DEUS
            c_dollar_value_d18 = (params.collateral_amount * params.col_price_usd) / (1e6);

        }
        uint calculated_deus_dollar_value_d18 = ((c_dollar_value_d18 * (1e6)) / params.col_ratio) - c_dollar_value_d18;

        uint calculated_deus_needed = (calculated_deus_dollar_value_d18 * (1e6)) / params.deus_price_usd;

        return (
            c_dollar_value_d18 + calculated_deus_dollar_value_d18,
            calculated_deus_needed
        );
    }

    function calcRedeem1t1DEI(uint256 col_price_usd, uint256 DEI_amount) public pure returns (uint256) {
        return (DEI_amount * (1e6)) / col_price_usd;
    }

    function calcBuyBackDEUS(BuybackDEUS_Params memory params) public pure returns (uint256) {
        // If the total collateral value is higher than the amount required at the current collateral ratio then buy back up to the possible DEUS with the desired collateral
        require(params.excess_collateral_dollar_value_d18 > 0, "No excess collateral to buy back!");

        // Make sure not to take more than is available
        uint256 deus_dollar_value_d18 = (params.DEUS_amount * (params.deus_price_usd)) / (1e6);
        require(deus_dollar_value_d18 <= params.excess_collateral_dollar_value_d18, "You are trying to buy back more than the excess!");

        // Get the equivalent amount of collateral based on the market value of DEUS provided 
        uint256 collateral_equivalent_d18 = (deus_dollar_value_d18 * (1e6)) / params.col_price_usd;
        //collateral_equivalent_d18 = collateral_equivalent_d18.sub((collateral_equivalent_d18.mul(params.buyback_fee)).div(1e6));

        return collateral_equivalent_d18;

    }


    // Returns value of collateral that must increase to reach recollateralization target (if 0 means no recollateralization)
    function recollateralizeAmount(uint256 total_supply, uint256 global_collateral_ratio, uint256 global_collat_value) public pure returns (uint256) {
        uint256 target_collat_value = (total_supply * global_collateral_ratio) / (1e6); // We want 18 decimals of precision so divide by 1e6; total_supply is 1e18 and global_collateral_ratio is 1e6
        // Subtract the current value of collateral from the target value needed, if higher than 0 then system needs to recollateralize
        return target_collat_value - global_collat_value; // If recollateralization is not needed, throws a subtraction underflow
    }

    function calcRecollateralizeDEIInner(
        uint256 collateral_amount, 
        uint256 col_price,
        uint256 global_collat_value,
        uint256 dei_total_supply,
        uint256 global_collateral_ratio
    ) public pure returns (uint256, uint256) {
        uint256 collat_value_attempted = (collateral_amount * col_price) / (1e6);
        uint256 effective_collateral_ratio = (global_collat_value * (1e6)) / dei_total_supply; //returns it in 1e6
        uint256 recollat_possible = (global_collateral_ratio * dei_total_supply - (dei_total_supply * effective_collateral_ratio)) / (1e6);

        uint256 amount_to_recollat;
        if(collat_value_attempted <= recollat_possible){
            amount_to_recollat = collat_value_attempted;
        } else {
            amount_to_recollat = recollat_possible;
        }

        return ((amount_to_recollat * (1e6)) / col_price, amount_to_recollat);

    }

}

//Dar panah khoda

// Be name Khoda
// Bime Abolfazl

// SPDX-License-Identifier: GPL-2.0-or-later

interface IDEIStablecoin {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function global_collateral_ratio() external view returns (uint256);
    function dei_pools(address _address) external view returns (bool);
    function dei_pools_array() external view returns (address[] memory);
    function verify_price(bytes32 sighash, bytes[] calldata sigs) external view returns (bool);
    function dei_info(uint256[] memory collat_usd_price) external view returns (uint256, uint256, uint256);
    function getChainID() external view returns (uint256);
    function globalCollateralValue(uint256[] memory collat_usd_price) external view returns (uint256);
    function refreshCollateralRatio(uint deus_price, uint dei_price, uint256 expire_block, bytes[] calldata sigs) external;
    function useGrowthRatio(bool _use_growth_ratio) external;
    function setGrowthRatioBands(uint256 _GR_top_band, uint256 _GR_bottom_band) external;
    function setPriceBands(uint256 _top_band, uint256 _bottom_band) external;
    function activateDIP(bool _activate) external;
    function pool_burn_from(address b_address, uint256 b_amount) external;
    function pool_mint(address m_address, uint256 m_amount) external;
    function addPool(address pool_address) external;
    function removePool(address pool_address) external;
    function setNameAndSymbol(string memory _name, string memory _symbol) external;
    function setOracle(address _oracle) external;
    function setDEIStep(uint256 _new_step) external;
    function setReserveTracker(address _reserve_tracker_address) external;
    function setRefreshCooldown(uint256 _new_cooldown) external;
    function setDEUSAddress(address _deus_address) external;
    function toggleCollateralRatio() external;
}

//Dar panah khoda