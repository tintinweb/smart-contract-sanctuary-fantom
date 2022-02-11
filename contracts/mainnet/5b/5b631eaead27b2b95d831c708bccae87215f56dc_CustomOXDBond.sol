// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./FixedPoint.sol";

import "./IERC20.sol";
import "./ITreasury.sol";

import "./Ownable.sol";

contract CustomOXDBond is Ownable {
    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    
    /* ======== EVENTS ======== */

    event BondCreated( uint deposit, uint payout, uint expires );
    event BondRedeemed( address recipient, uint payout, uint remaining );
    event BondPriceChanged( uint internalPrice, uint debtRatio );
    event ControlVariableAdjustment( uint initialBCV, uint newBCV, uint adjustment, bool addition );
    
    
     /* ======== STATE VARIABLES ======== */
    
    IERC20 immutable private payoutToken; // token paid for principal
    IERC20 immutable private principalToken; // inflow token
    ITreasury immutable private customTreasury; // pays for and receives principal
    address immutable private olympusDAO;
    address immutable private subsidyRouter; // pays subsidy in OHM to custom treasury
    address private olympusTreasury; // receives fee

    uint public totalPrincipalBonded;
    uint public totalPayoutGiven;
    uint public totalDebt; // total value of outstanding bonds; used for pricing
    uint public lastDecay; // reference timestamp for debt decay
    uint private payoutSinceLastSubsidy; // principal accrued since subsidy paid
    
    Terms public terms; // stores terms for new bonds
    Adjust public adjustment; // stores adjustment to BCV data
    FeeTiers[] private feeTiers; // stores fee tiers

    bool immutable private feeInPayout;

    mapping( address => Bond ) public bondInfo; // stores bond information for depositors
    
    /* ======== STRUCTS ======== */

    struct FeeTiers {
        uint tierCeilings; // principal bonded till next tier
        uint fees; // in ten-thousandths (i.e. 33300 = 3.33%)
    }

    // Info for creating new bonds
    struct Terms {
        uint controlVariable; // scaling variable for price
        uint vestingTerm; // in seconds
        uint minimumPrice; // vs principal value
        uint maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint maxDebt; // payout token decimal debt ratio, max % total supply created as debt
    }

    // Info for bond holder
    struct Bond {
        uint payout; // payout token remaining to be paid
        uint vesting; // seconds left to vest
        uint lastBlockTimestamp; // Last interaction
        uint truePricePaid; // Price paid (principal tokens per payout token) in ten-millionths - 4000000 = 0.4
    }

    // Info for incremental adjustments to control variable 
    struct Adjust {
        bool add; // addition or subtraction
        uint rate; // increment
        uint target; // BCV when adjustment finished
        uint buffer; // minimum length (in seconds) between adjustments
        uint lastBlockTimestamp; // timestamp when last adjustment made
    }
    
    /* ======== CONSTRUCTOR ======== */

    constructor(
        address _customTreasury, 
        address _principalToken, 
        address _olympusTreasury,
        address _subsidyRouter, 
        address _initialOwner, 
        address _olympusDAO,
        uint[] memory _tierCeilings, 
        uint[] memory _fees,
        bool _feeInPayout
    ) {
        require( _customTreasury != address(0) );
        customTreasury = ITreasury( _customTreasury );
        payoutToken = IERC20( ITreasury(_customTreasury).payoutToken() );
        require( _principalToken != address(0) );
        principalToken = IERC20( _principalToken );
        require( _olympusTreasury != address(0) );
        olympusTreasury = _olympusTreasury;
        require( _subsidyRouter != address(0) );
        subsidyRouter = _subsidyRouter;
        require( _initialOwner != address(0) );
        policy = _initialOwner;
        require( _olympusDAO != address(0) );
        olympusDAO = _olympusDAO;
        require(_tierCeilings.length == _fees.length, "tier length and fee length not the same");

        for(uint i; i < _tierCeilings.length; i++) {
            feeTiers.push( FeeTiers({
                tierCeilings: _tierCeilings[i],
                fees: _fees[i]
            }));
        }

        feeInPayout = _feeInPayout;
    }

    /* ======== INITIALIZATION ======== */
    
    /**
     *  @notice initializes bond parameters
     *  @param _controlVariable uint
     *  @param _vestingTerm uint
     *  @param _minimumPrice uint
     *  @param _maxPayout uint
     *  @param _maxDebt uint
     *  @param _initialDebt uint
     */
    function initializeBond( 
        uint _controlVariable, 
        uint _vestingTerm,
        uint _minimumPrice,
        uint _maxPayout,
        uint _maxDebt,
        uint _initialDebt
    ) external onlyPolicy() {
        require( currentDebt() == 0, "Debt must be 0 for initialization" );
        terms = Terms ({
            controlVariable: _controlVariable,
            vestingTerm: _vestingTerm,
            minimumPrice: _minimumPrice,
            maxPayout: _maxPayout,
            maxDebt: _maxDebt
        });
        totalDebt = _initialDebt;
        lastDecay = block.timestamp;
    }
    
    
    /* ======== POLICY FUNCTIONS ======== */

    enum PARAMETER { VESTING, PAYOUT, DEBT }
    /**
     *  @notice set parameters for new bonds
     *  @param _parameter PARAMETER
     *  @param _input uint
     */
    function setBondTerms ( PARAMETER _parameter, uint _input ) external onlyPolicy() {
        if ( _parameter == PARAMETER.VESTING ) { // 0
            require( _input >= 43200, "Vesting must be longer than 12 hours" );
            terms.vestingTerm = _input;
        } else if ( _parameter == PARAMETER.PAYOUT ) { // 1
            require( _input <= 1000, "Payout cannot be above 1 percent" );
            terms.maxPayout = _input;
        } else if ( _parameter == PARAMETER.DEBT ) { // 2
            terms.maxDebt = _input;
        }
    }

    /**
     *  @notice set control variable adjustment
     *  @param _addition bool
     *  @param _increment uint
     *  @param _target uint
     *  @param _buffer uint
     */
    function setAdjustment ( 
        bool _addition,
        uint _increment, 
        uint _target,
        uint _buffer 
    ) external onlyPolicy() {
        require( _increment <= terms.controlVariable.mul( 30 ).div( 1000 ), "Increment too large" );

        adjustment = Adjust({
            add: _addition,
            rate: _increment,
            target: _target,
            buffer: _buffer,
            lastBlockTimestamp: block.timestamp
        });
    }

    /**
     *  @notice change address of Olympus Treasury
     *  @param _olympusTreasury address
     */
    function changeOlympusTreasury(address _olympusTreasury) external {
        require( msg.sender == olympusDAO, "Only Olympus DAO" );
        olympusTreasury = _olympusTreasury;
    }

    /**
     *  @notice subsidy controller checks payouts since last subsidy and resets counter
     *  @return payoutSinceLastSubsidy_ uint
     */
    function paySubsidy() external returns ( uint payoutSinceLastSubsidy_ ) {
        require( msg.sender == subsidyRouter, "Only subsidy controller" );

        payoutSinceLastSubsidy_ = payoutSinceLastSubsidy;
        payoutSinceLastSubsidy = 0;
    }
    
    /* ======== USER FUNCTIONS ======== */
    
    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @param _maxPrice uint
     *  @param _depositor address
     *  @return uint
     */
    function deposit(uint _amount, uint _maxPrice, address _depositor) external returns (uint) {
        require( _depositor != address(0), "Invalid address" );

        decayDebt();
        
        uint nativePrice = trueBondPrice();

        require( _maxPrice >= nativePrice, "Slippage limit: more than max price" ); // slippage protection

        uint value = customTreasury.valueOfToken( address(principalToken), _amount );

        uint payout;
        uint fee;

        if(feeInPayout) {
            (payout, fee) = payoutFor( value ); // payout and fee is computed
        } else {
            (payout, fee) = payoutFor( _amount ); // payout and fee is computed
            _amount = _amount.sub(fee);
        }

        require( payout >= 10 ** payoutToken.decimals() / 100, "Bond too small" ); // must be > 0.01 payout token ( underflow protection )
        require( payout <= maxPayout(), "Bond too large"); // size protection because there is no slippage
        
        // total debt is increased
        totalDebt = totalDebt.add( value );

        require( totalDebt <= terms.maxDebt, "Max capacity reached" );
                
        // depositor info is stored
        bondInfo[ _depositor ] = Bond({ 
            payout: bondInfo[ _depositor ].payout.add( payout ),
            vesting: terms.vestingTerm,
            lastBlockTimestamp: block.timestamp,
            truePricePaid: trueBondPrice()
        });

        totalPrincipalBonded = totalPrincipalBonded.add(_amount); // total bonded increased
        totalPayoutGiven = totalPayoutGiven.add(payout); // total payout increased
        payoutSinceLastSubsidy = payoutSinceLastSubsidy.add( payout ); // subsidy counter increased

        if(feeInPayout) {
            customTreasury.sendPayoutTokens( payout.add(fee) );
            if(fee != 0) { // if fee, send to Olympus treasury
                payoutToken.safeTransfer(olympusTreasury, fee);
            }
        } else {
            customTreasury.sendPayoutTokens( payout );
            if(fee != 0) { // if fee, send to Olympus treasury
                principalToken.safeTransferFrom( msg.sender, olympusTreasury, fee );
            }
        }

        principalToken.safeTransferFrom( msg.sender, address(customTreasury), _amount ); // transfer principal bonded to custom treasury

        // indexed events are emitted
        emit BondCreated( _amount, payout, block.timestamp.add( terms.vestingTerm ) );
        emit BondPriceChanged( _bondPrice(), debtRatio() );

        adjust(); // control variable is adjusted
        return payout; 
    }
    
    /** 
     *  @notice redeem bond for user
     *  @param _depositor address
     *  @return uint
     */ 
    function redeem(address _depositor) external returns (uint) {
        Bond memory info = bondInfo[ _depositor ];
        uint percentVested = percentVestedFor( _depositor ); // (seconds since last interaction / vesting term remaining)

        if ( percentVested >= 10000 ) { // if fully vested
            delete bondInfo[ _depositor ]; // delete user info
            emit BondRedeemed( _depositor, info.payout, 0 ); // emit bond data
            payoutToken.safeTransfer( _depositor, info.payout );
            return info.payout;

        } else { // if unfinished
            // calculate payout vested
            uint payout = info.payout.mul( percentVested ).div( 10000 );

            // store updated deposit info
            bondInfo[ _depositor ] = Bond({
                payout: info.payout.sub( payout ),
                vesting: info.vesting.sub( block.timestamp.sub( info.lastBlockTimestamp ) ),
                lastBlockTimestamp: block.timestamp,
                truePricePaid: info.truePricePaid
            });

            emit BondRedeemed( _depositor, payout, bondInfo[ _depositor ].payout );
            payoutToken.safeTransfer( _depositor, payout );
            return payout;
        }
    }

    
    /* ======== INTERNAL HELPER FUNCTIONS ======== */

    /**
     *  @notice makes incremental adjustment to control variable
     */
    function adjust() internal {
        uint timestampCanAdjust = adjustment.lastBlockTimestamp.add( adjustment.buffer );
        if( adjustment.rate != 0 && block.timestamp >= timestampCanAdjust ) {
            uint initial = terms.controlVariable;
            if ( adjustment.add ) {
                terms.controlVariable = terms.controlVariable.add( adjustment.rate );
                if ( terms.controlVariable >= adjustment.target ) {
                    adjustment.rate = 0;
                }
            } else {
                terms.controlVariable = terms.controlVariable.sub( adjustment.rate );
                if ( terms.controlVariable <= adjustment.target ) {
                    adjustment.rate = 0;
                }
            }
            adjustment.lastBlockTimestamp = block.timestamp;
            emit ControlVariableAdjustment( initial, terms.controlVariable, adjustment.rate, adjustment.add );
        }
    }

    /**
     *  @notice reduce total debt
     */
    function decayDebt() internal {
        totalDebt = totalDebt.sub( debtDecay() );
        lastDecay = block.timestamp;
    }

    /**
     *  @notice calculate current bond price and remove floor if above
     *  @return price_ uint
     */
    function _bondPrice() internal returns ( uint price_ ) {
        price_ = terms.controlVariable.mul( debtRatio() ).div( 10 ** (uint256(payoutToken.decimals()).sub(8)) );
        if ( price_ < terms.minimumPrice ) {
            price_ = terms.minimumPrice;        
        } else if ( terms.minimumPrice != 0 ) {
            terms.minimumPrice = 0;
        }
    }


    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice calculate current bond premium
     *  @return price_ uint
     */
    function bondPrice() public view returns ( uint price_ ) {        
        price_ = terms.controlVariable.mul( debtRatio() ).div( 10 ** (uint256(payoutToken.decimals()).sub(8)) );
        if ( price_ < terms.minimumPrice ) {
            price_ = terms.minimumPrice;
        }
    }

    /**
     *  @notice calculate true bond price a user pays
     *  @return price_ uint
     */
    function trueBondPrice() public view returns ( uint price_ ) {
        price_ = bondPrice().add(bondPrice().mul( currentOlympusFee() ).div( 1e6 ) );
    }

    /**
     *  @notice determine maximum bond size
     *  @return uint
     */
    function maxPayout() public view returns ( uint ) {
        return payoutToken.totalSupply().mul( terms.maxPayout ).div( 100000 );
    }

    /**
     *  @notice calculate user's interest due for new bond, accounting for Olympus Fee. 
     If fee is in payout then takes in the already calcualted value. If fee is in principal token 
     than takes in the amount of principal being deposited and then calculautes the fee based on
     the amount of principal and not in terms of the payout token
     *  @param _value uint
     *  @return _payout uint
     *  @return _fee uint
     */
    function payoutFor( uint _value ) public view returns ( uint _payout, uint _fee) {
        if(feeInPayout) {
            uint total = FixedPoint.fraction( _value, bondPrice() ).decode112with18().div( 1e8 );
            _fee = total.mul( currentOlympusFee() ).div( 1e6 );
            _payout = total.sub(_fee);
        } else {
            _fee = _value.mul( currentOlympusFee() ).div( 1e6 );
            _payout = FixedPoint.fraction( customTreasury.valueOfToken(address(principalToken), _value.sub(_fee)), bondPrice() ).decode112with18().div( 1e8 );
        }
    }

    /**
     *  @notice calculate current ratio of debt to payout token supply
     *  @notice protocols using Olympus Pro should be careful when quickly adding large %s to total supply
     *  @return debtRatio_ uint
     */
    function debtRatio() public view returns ( uint debtRatio_ ) {   
        debtRatio_ = FixedPoint.fraction( 
            currentDebt().mul( 10 ** payoutToken.decimals() ), 
            payoutToken.totalSupply()
        ).decode112with18().div( 1e18 );
    }

    /**
     *  @notice calculate debt factoring in decay
     *  @return uint
     */
    function currentDebt() public view returns ( uint ) {
        return totalDebt.sub( debtDecay() );
    }

    /**
     *  @notice amount to decay total debt by
     *  @return decay_ uint
     */
    function debtDecay() public view returns ( uint decay_ ) {
        uint timestampSinceLast = block.timestamp.sub( lastDecay );
        decay_ = totalDebt.mul( timestampSinceLast ).div( terms.vestingTerm );
        if ( decay_ > totalDebt ) {
            decay_ = totalDebt;
        }
    }

    /**
     *  @notice calculate how far into vesting a depositor is
     *  @param _depositor address
     *  @return percentVested_ uint
     */
    function percentVestedFor( address _depositor ) public view returns ( uint percentVested_ ) {
        Bond memory bond = bondInfo[ _depositor ];
        uint timestampSinceLast = block.timestamp.sub( bond.lastBlockTimestamp );
        uint vesting = bond.vesting;

        if ( vesting > 0 ) {
            percentVested_ = timestampSinceLast.mul( 10000 ).div( vesting );
        } else {
            percentVested_ = 0;
        }
    }

    /**
     *  @notice calculate amount of payout token available for claim by depositor
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor( address _depositor ) external view returns ( uint pendingPayout_ ) {
        uint percentVested = percentVestedFor( _depositor );
        uint payout = bondInfo[ _depositor ].payout;

        if ( percentVested >= 10000 ) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul( percentVested ).div( 10000 );
        }
    }

    /**
     *  @notice current fee Olympus takes of each bond
     *  @return currentFee_ uint
     */
    function currentOlympusFee() public view returns( uint currentFee_ ) {
        uint tierLength = feeTiers.length;
        for(uint i; i < tierLength; i++) {
            if(totalPrincipalBonded < feeTiers[i].tierCeilings || i == tierLength - 1 ) {
                return feeTiers[i].fees;
            }
        }
    }
    
}