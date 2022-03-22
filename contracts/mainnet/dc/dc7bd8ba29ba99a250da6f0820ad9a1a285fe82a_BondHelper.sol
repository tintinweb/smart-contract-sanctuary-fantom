/**
 *Submitted for verification at FtmScan.com on 2022-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IOwnable {
  function policy() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function policy() public view override returns (address) {
        return _owner;
    }

    modifier onlyPolicy() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyPolicy() {
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyPolicy() {
        require( newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }
    
    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
    }
}

interface IBond {
    function redeem( address recipient, bool stake ) external returns ( uint amount );
    function deposit( uint amount, uint maxPrice, address depositor ) external returns ( uint depositAmount );
    function pendingPayoutFor( address depositor ) external view returns ( uint pendingPayout );

    function bondPrice() external view returns ( uint bondPrice );
    function bondInfo(address user) external view returns (
    uint payout, uint pricePaid, uint32 lastTime, uint32 vesting);
    function bondPriceInUSD() external view returns ( uint priceUSD );
    function isLiquidityBond() external view returns ( bool );
    function totalDebt() external view returns ( uint debtTotal );
    function principle() external view returns ( address tokenAddress );

    function terms() external view returns ( 
        uint controlVariable, uint minimumPrice, uint maxPayout, uint fee, uint maxDebt, uint32 vestingTerm );
}

interface IEthBond {
    function bondInfo(address user) external view returns (
        uint payout, uint pricePaid, uint32 vesting, uint32 lastTime);
    function terms() external view returns ( 
        uint controlVariable, uint minimumPrice, uint maxPayout, uint maxDebt, uint32 vestingTerm );
}

/// @title BondHelper.sol
/// @author 0xBuns (https://twitter.com/0xBuns)
/// @notice Bond helper is used to view key aspects of any bond for Luxor DAO.

contract BondHelper is Ownable {
    using SafeERC20 for IERC20;

    address[] public bonds;
    bool isInitialized;
    address WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    event BondCreated( uint amount, uint indexed price, address indexed user );

    constructor() {
        initialize();
    }
    /* ======= BOND HANDLERS ======= */
    function addBondContract( address bond ) public onlyPolicy() {
        require( bond != address(0) );
        bonds.push( bond );
    }

    function removeBondContract( uint _index ) external onlyPolicy() {
        bonds[ _index ] = address(0);
    }

    function getBondIndex(address bondAddress) public view returns (uint index) {
     for( uint i = 0; i < bonds.length; i++ ) {
            if ( bonds[i] == bondAddress ) {
                index = i;
            }    
        }
    }

    /* ======= USER HANDLERS ======= */

    function approve(address bondAddress, uint amount) public {
        uint i = getBondIndex(bondAddress);
        address principleToken = IBond( bonds[i] ).principle();
        IERC20(principleToken).approve(address(this), amount * 1e18);
    }

    function deposit(uint amount, uint slippage, address bondAddress) external {
        address user = msg.sender;
        uint i = getBondIndex(bondAddress);
        address principleToken = IBond( bonds[i] ).principle();
        uint price = IBond( bonds[i] ).bondPrice();
        uint maxPrice = price * (1 + slippage);

        IERC20( principleToken ).transferFrom( msg.sender, address(this), amount );
        IERC20( principleToken ).approve( bondAddress, amount );
        IBond( bonds[i] ).deposit(amount, maxPrice, user);

        emit BondCreated(amount, price, user);
    }

    function harvest( address bondAddress, bool stake ) external {
        uint i = getBondIndex(bondAddress);
            IBond( bonds[i] ).redeem( msg.sender, stake );
    }

    function harvestAll( bool stake ) external {
        for( uint i = 0; i < bonds.length; i++ ) {
            if ( bonds[i] != address(0) ) {
                if ( IBond( bonds[i] ).pendingPayoutFor( msg.sender ) > 0 ) {
                    IBond( bonds[i] ).redeem( msg.sender, stake );
                }
            }
        }
    }

    /* ======= USER DETAILS ======= */
    function pendingPayout(address bondAddress) external view returns (uint payout) {
        uint i = getBondIndex(bondAddress);
        payout = IBond( bonds[i] ).pendingPayoutFor( msg.sender );
    }

    /* ======= BOND DETAILS ======= */
    function principle(address bondAddress) external view returns (address principleToken) {
        uint i = getBondIndex(bondAddress);
        principleToken = IBond( bonds[i] ).principle();
    }

    function isLiquidityBond(address bondAddress) external view returns (bool) {
        uint i = getBondIndex(bondAddress);
        bool isEth = IBond( bonds[i] ).principle() == WFTM;
        return isEth ? false : IBond( bonds[i] ).isLiquidityBond();
    }
    
    function bondPrice(address bondAddress) external view returns (uint price) {
        uint i = getBondIndex(bondAddress);
        price = IBond( bonds[i] ).bondPrice();
    }

    function bondPriceUsd(address bondAddress) external view returns (uint priceUsd) {
        uint i = getBondIndex(bondAddress);
        priceUsd = IBond( bonds[i] ).bondPriceInUSD();
    }

    function lastPricePaid(address bondAddress) external view returns (uint pricePaid) {
            uint i = getBondIndex(bondAddress);
            bool isEth = IBond( bonds[i] ).principle() == WFTM;
            isEth
                ? (,pricePaid,,) = IEthBond( bonds[i] ).bondInfo(msg.sender)
                : (,pricePaid,,) = IBond( bonds[i] ).bondInfo(msg.sender);
    }
 
    function bondInfo(address bondAddress) external view returns (
        uint payout, uint pricePaid, uint32 lastTime, uint32 vesting) {
            uint i = getBondIndex(bondAddress);
             (payout,,,) = IBond( bonds[i] ).bondInfo(msg.sender);
             (,pricePaid,,) = IBond( bonds[i] ).bondInfo(msg.sender);
            bool isEth = IBond( bonds[i] ).principle() == WFTM;
            isEth 
                ? (,,vesting,) = IEthBond( bonds[i] ).bondInfo(msg.sender)
                : (,,,vesting) = IBond( bonds[i] ).bondInfo(msg.sender);
            isEth
                ? (,,,lastTime) = IEthBond( bonds[i] ).bondInfo(msg.sender)
                : (,,lastTime,) = IBond( bonds[i] ).bondInfo(msg.sender);
    }
    
    /* ======= VESTING DETAILS ======= */
    function vestingTerm(address bondAddress) external view returns (uint32 term) {
        uint i = getBondIndex(bondAddress);
        bool isEth = IBond( bonds[i] ).principle() == WFTM;
        isEth 
            ? (,,,, term) = IEthBond( bonds[i] ).terms()
            : (,,,,, term) = IBond( bonds[i] ).terms();
    }

    function vestingDays(address bondAddress) external view returns (uint32 vestDays) {
        uint i = getBondIndex(bondAddress);
        uint32 term;
        bool isEth = IBond( bonds[i] ).principle() == WFTM;
        isEth
            ? (,,,, term) = IEthBond( bonds[i] ).terms()
            : (,,,,, term) = IBond( bonds[i] ).terms();
        vestDays = term / 86400;
    }

    /* ======= MAX & MIN ======= */
    function minimumPrice(address bondAddress) external view returns (uint minPrice) {
        uint i = getBondIndex(bondAddress);
        bool isEth = IBond( bonds[i] ).principle() == WFTM;
        isEth
        ? (, minPrice ,,,) = IEthBond( bonds[i] ).terms()
        : (, minPrice ,,,,) = IBond( bonds[i] ).terms();
    }

    function maximumPayout(address bondAddress) external view returns (uint maxPayout) {
        uint i = getBondIndex(bondAddress);
        bool isEth = IBond( bonds[i] ).principle() == WFTM;
        isEth 
        ? (,, maxPayout ,,) = IEthBond( bonds[i] ).terms()
        : (,, maxPayout ,,,) = IBond( bonds[i] ).terms();
    }

    function maximumDebt(address bondAddress) external view returns (uint maxDebt) {
        uint i = getBondIndex(bondAddress);
                bool isEth = IBond( bonds[i] ).principle() == WFTM;
        isEth 
        ? (,,,, maxDebt) = IEthBond( bonds[i] ).terms()
        : (,,,, maxDebt ,) = IBond( bonds[i] ).terms();
    }

    function totalDebt(address bondAddress) external view returns (uint debt) {
        uint i = getBondIndex(bondAddress);
        debt = IBond( bonds[i] ).totalDebt();
    }

    /* ======= AUXILLIARY ======= */
    function recoverLostToken( address _token ) external returns ( bool ) {
        IERC20( _token ).safeTransfer( _owner, IERC20( _token ).balanceOf( address(this) ) );
        return true;
    }

    /* ======= LAY-Z INITIALIZATION ======= */

    function initialize() public onlyPolicy {
        require(!isInitialized, "already initialized");
        addBondContract(0xCf994423b39A6991e82443a8011Bf6749e19434b);
        addBondContract(0x80C61168e1F02e1835b541e9Ca6Bb3416a36Af6F);
        addBondContract(0x73eE5Fcd1336246C74f6448B1d528aeacF5404f2);
        addBondContract(0x13729e99A7b77469f7FD204495a7b49e25e8444a);
        addBondContract(0x376969e00621Ebf685fC3D1F216C00d19B162923);
        addBondContract(0xc421072646C51FF8983714F28e4253ad8B44bb1E);
        addBondContract(0x5612d83dfED9B387c925Ac4D19ED3aeDd71004A8);
        addBondContract(0xaC64DC47A1fe52458D3418AC7C568Edc3306130a);
        addBondContract(0xaBAD60240f1a39fce0d828eecf54d790FFF92cec);
        addBondContract(0x8dF4f6e20C64DA8DAFC8c43E434f2cFda9C3FCAE);
        addBondContract(0x0A98e728f0537f40e8dC261D633fe4a00E1aFA72);
        addBondContract(0x1a7bA76b2A421E0E730809C40bE4a685dE29307c);
        addBondContract(0x89EA4331183730F289DEAfc926cF0541364F169D);
        addBondContract(0xAbeEd495A87fccc2988F0CdaCf314F23AF52B685);
        addBondContract(0xAE08cf625d4232935D2F1b331517aC0089163DB2);
        addBondContract(0xaFADcDca5Aa1F187B357499f2e3BA94D3Cc32ad1);

        isInitialized = true;
    }
}