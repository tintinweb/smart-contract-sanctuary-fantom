/**
 *Submitted for verification at FtmScan.com on 2023-07-07
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


contract DeployEscrow is ReentrancyGuard {
    address immutable public Owner;
    address public Keeper;
    address public FeeAddress;

    bool public AllowPurchases = true;
    
    mapping(address => address) public Escrows;
    mapping(address => address) public EscrowsToOwners;
    mapping(address => address) public ListingsToOwners;
    
    address[] public EscrowOwnerArray;
    address[] public ListingArray;
    
    event DeployedEscrow(address indexed Escrow, address indexed EscrowOwner);
    
    receive() external payable {}
    
    fallback() external payable {}
    
    // Owner is the team's Gnosis Safe multisig address with 2/3 confirmations needed to transact, Keeper and FeeAddress can be changed by Owner
    constructor () {
        Owner = 0x79d127e23c01a1C74ECF926cB8d73C576D99c0f1;  
        Keeper = 0xe2323D9d39226B69faFD73F7c20395010B0cC6B2; 
        FeeAddress = 0x79d127e23c01a1C74ECF926cB8d73C576D99c0f1;
    }
    modifier OnlyOwner() {
        require(msg.sender == Owner, "This function can only be run by the contract owner");
        _;
    }

    modifier OnlyEscrows() {
        require(EscrowsToOwners[msg.sender] != address(0), "This function can only be run by escrow accounts");
        _;
    }

    // Deploy Escrow account for user
    function Deploy() external nonReentrant returns (address Address) {
        address payable _EscrowOwner = payable(msg.sender);
        require(Escrows[msg.sender] == address(0), "Can only have 1 Escrow at a time, close other Escrow before creating new one!");
        MMYEscrow NewEscrow = new MMYEscrow(_EscrowOwner);
        Address = address(NewEscrow);
        require(Address != address(0), "Deploy Escrow failed!");
        emit DeployedEscrow(Address, _EscrowOwner);
        Escrows[_EscrowOwner] = Address;
        EscrowsToOwners[Address] = _EscrowOwner;
        EscrowOwnerArray.push(_EscrowOwner);
    }
    
    // Deploy buyer Escrow account during offer/purchase
    function DeployBuyerEscrow(address payable _BuyerAddress) external OnlyEscrows nonReentrant returns (address EscrowAddress) {
        require(Escrows[_BuyerAddress] == address(0), "Buyer already has an escrow account!");
        MMYEscrow NewEscrow = new MMYEscrow(_BuyerAddress);
        EscrowAddress = address(NewEscrow);
        require(EscrowAddress != address(0), "Deploy Escrow failed!");
        emit DeployedEscrow(EscrowAddress, _BuyerAddress);
        Escrows[_BuyerAddress] = EscrowAddress;
        EscrowsToOwners[EscrowAddress] = _BuyerAddress;
        EscrowOwnerArray.push(_BuyerAddress);
    }

    // Gets list of Escrow accounts currently for sale
    function GetListings(uint256 _Limit, uint256 _Offset) external view returns (address[] memory) {
        uint256 LimitPlusOffset = _Limit + _Offset;
        require(_Limit <= ListingArray.length, "Please ensure Limit is less than or equal to the ListingArray current length");
        require(_Offset < ListingArray.length, "Please ensure Offset is less than the ListingArray current length");
        uint256 n = 0;
        address[] memory Listings = new address[](_Limit);
        if (LimitPlusOffset > ListingArray.length) {
            LimitPlusOffset = ListingArray.length;
        }
        for (uint256 i = _Offset; i < LimitPlusOffset; i++) {
            address ListingAddress = ListingArray[i];
            Listings[n] = ListingAddress;
            n++;
        }
        return Listings;
    }

    // Gets the number of listings in the ListingsArray
    function GetNumberOfListings() external view returns (uint256) {
        return ListingArray.length;
    }

    // Cleans up array/mappings related to buyer and seller Escrow accounts when closed
    function ResetCloseEscrow(address _Address) external OnlyEscrows nonReentrant {
        uint256 Index = IndexOfEscrowOwnerArray(_Address);
        delete Escrows[_Address];
        delete EscrowsToOwners[msg.sender];
        EscrowOwnerArray[Index] = EscrowOwnerArray[EscrowOwnerArray.length - 1];
        EscrowOwnerArray.pop();
    }

    // Cleans up array/mappings related listings when ended
    function DeleteListing(address _Address) external OnlyEscrows nonReentrant {
        uint256 Index = IndexOfListingArray(_Address);
        delete ListingsToOwners[msg.sender];
        ListingArray[Index] = ListingArray[ListingArray.length - 1];
        ListingArray.pop();
    }

    // Sets ListingsToOwners mapping
    function SetListingsToOwners(address _Address) external OnlyEscrows nonReentrant {
        ListingsToOwners[msg.sender] = _Address;
    }

    // Push new Listing in ListingArray
    function PushListing() external OnlyEscrows nonReentrant {
        ListingArray.push(msg.sender);
    }

    // Delete any expired listings from ListingsArray and ListingsToOwners
    function CleanListings() external nonReentrant {
        require(msg.sender == Keeper, "Only the Keeper can run this function");
        for (uint256 i = 0; i < ListingArray.length; i++) {
            if (MMYEscrow(payable(ListingArray[i])).EndAt() <= block.timestamp) {
                delete ListingsToOwners[ListingArray[i]];
                ListingArray[i] = ListingArray[ListingArray.length - 1];
                ListingArray.pop();
            }
        }
    }

    // Checks if any listings are expired, if any are expired returns true if not returns false
    function CheckForExpired() external view returns (bool) {
        for (uint256 i = 0; i < ListingArray.length; i++) {
            if (MMYEscrow(payable(ListingArray[i])).EndAt() <= block.timestamp) {
                return true;
            }
        }
        return false;
    }

    // Sets the keeper address
    function SetKeeper(address _Address) external OnlyOwner nonReentrant {
        Keeper = _Address;
    }

    // Sets the keeper address
    function SetFeeAddress(address _Address) external OnlyOwner nonReentrant {
        FeeAddress = _Address;
    }

    // Sets whether or not sales can be completed in the marketplace (for turning off in case of end of life)
    function SetAllowPurchases(bool _Bool) external OnlyOwner nonReentrant {
        AllowPurchases = _Bool;
    }
    
    // Withdraw all FTM from this contract
    function WithdrawFTM() external payable OnlyOwner nonReentrant {
        require(address(this).balance > 0, "No AVAX to withdraw");
        (bool sent, ) = Owner.call{value: address(this).balance}("");
        require(sent);
    }
    
    // Withdraw any ERC20 token from this contract
    function WithdrawToken(address _tokenaddress, uint256 _Amount) external OnlyOwner nonReentrant {
        IERC20(_tokenaddress).transfer(Owner, _Amount);
    }
    
    // Private function for internal use
    function IndexOfEscrowOwnerArray(address _Target) private view returns (uint256) {
        for (uint256 i = 0; i < EscrowOwnerArray.length; i++) {
            if (EscrowOwnerArray[i] == _Target) {
                return i;
            }
        }
        revert("Not found");
    }

    // Private function for internal use
    function IndexOfListingArray(address _Target) private view returns (uint256) {
        for (uint256 i = 0; i < ListingArray.length; i++) {
            if (ListingArray[i] == _Target) {
                return i;
            }
        }
        revert("Not found");
    }
}

contract MMYEscrow is ReentrancyGuard {
    address immutable public Owner;
    
    DeployEscrow immutable MasterContract;
    MMYEscrow EscrowContract;
    
    address payable immutable public EscrowOwner;
    
    address constant private MMYEligible = 0x73F4776FBDe48C86874e6f0ff81E658c2ef364b0;  
    address constant private EsMMY = 0xe41c6c006De9147FC4c84b20cDFBFC679667343F; 
    address constant private WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; 
    address constant private MMY = 0x01e77288b38b416F972428d562454fb329350bAc; 
    address constant private MMYRewardRouter = 0x7b9e962dd8AeD0Db9A1D8a2D7A962ad8b871Ce4F; 
    address constant private stakedMmyTracker = 0x727dB8FA7861340d49d13ea78321D0C9a1a79cd5; 
    address constant private bonusMmyTracker = 0x04f23404553fcc388Ec73110A0206Dd2E76a6d95; 
    address constant private feeMmyTracker = 0xe149164D8eca659E8912DbDEC35E3f7E71Fb5789; 
    address constant private mmyVester = 0xa1a65D3639A1EFbFB18C82003330a4b1FB620C5a; 
    address constant private stakedMlpTracker = 0xFfB69477FeE0DAEB64E7dE89B57846aFa990e99C; 
    address constant private feeMlpTracker = 0x7B26207457A9F8fF4fd21A7A0434066935f1D8E7;  
    address constant private mlpVester = 0x2A3E489F713ab6F652aF930555b5bb3422711ac1; 
    
    ISwapRouter constant router = ISwapRouter(0xF491e7B69E4244ad4002BC14e878a34207E38c29); 
    IPeripheryPayments constant refundrouter = IPeripheryPayments(0xF491e7B69E4244ad4002BC14e878a34207E38c29); 
    address MMYRewardContract = 0x7b9e962dd8AeD0Db9A1D8a2D7A962ad8b871Ce4F; 
    address tokenIn = 0x01e77288b38b416F972428d562454fb329350bAc; 
    address tokenOut = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; 
    
    uint256 constant private MaxApproveValue = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    
    uint256 public SalePrice = 0;
    uint256 public EndAt;
    
    bool public SaleIneligible = false;
    bool public IsSold = false;
    bool public IsPurchased = false;
    bool public IsActive = true;
    
    event Listed(address indexed Lister);
    event Purchased(address indexed Purchaser, address indexed Lister);
    
    constructor (address payable _EscrowOwner) {
        Owner = msg.sender;
        MasterContract = DeployEscrow(payable(Owner));
        EscrowOwner = payable(_EscrowOwner);
    }  
    modifier OnlyEscrowOwner() {
        require(msg.sender == EscrowOwner);
        _;
    }
    modifier OnlyOwner() {
        require(msg.sender == Owner);
        _;
    }

    modifier ClosedEscrow() {
        require(IsActive, "This Escrow account is closed, only WithdrawWFTM() and WithdrawToken() still function");
        _;
    }
    
    receive() external payable {}
    
    fallback() external payable {}
    
    // Compound Escrow account and claim rewards for Escrow Owner (choice of receiving as FTM (true) or WFTM (false)
    function CompoundAndClaim() external payable nonReentrant ClosedEscrow OnlyEscrowOwner {
        IMMYRewardRouter(MMYRewardRouter).handleRewards(
            false,
            false,
            true,
            true,
            true,
            true,
            true
        );
        (bool sent, ) = EscrowOwner.call{value: address(this).balance}("");
        require(sent);
    }
    
    // Transfer MMY account out of Escrow to _Receiver
    function TransferOut(address _Receiver) external nonReentrant ClosedEscrow OnlyEscrowOwner {
        IERC20(MMY).approve(stakedMmyTracker, MaxApproveValue);
        IMMYRewardRouter(MMYRewardRouter).signalTransfer(_Receiver);
        if (MasterContract.ListingsToOwners(address(this)) != address(0)) {
            IMMYDeployEscrow(Owner).DeleteListing(address(this));
        }
        SalePrice = 0;
        SaleIneligible = true;
        EndAt = block.timestamp;
    }
    
    // Transfer MMY account out of Escrow to Escrow Owner
    function TransferOutEscrowOwner() external nonReentrant ClosedEscrow {
        require((MasterContract.EscrowsToOwners(msg.sender)) != address(0));
        IERC20(MMY).approve(stakedMmyTracker, MaxApproveValue);
        IMMYRewardRouter(MMYRewardRouter).signalTransfer(EscrowOwner);
        SalePrice = 0;
        SaleIneligible = true;
        EndAt = block.timestamp;
    }
    
    // Transfer MMY account in to Escrow
    function TransferIn() public nonReentrant ClosedEscrow {
        IMMYRewardRouter(MMYRewardRouter).acceptTransfer(msg.sender);
    }
    
    // Transfer MMY account in to Escrow private function
    function TransferInPrivate() private {
        IMMYRewardRouter(MMYRewardRouter).acceptTransfer(msg.sender);
    }

    // Set Escrow MMY account for sale
    function SetForSale(uint256 _SalePrice, uint8 _Length) external nonReentrant ClosedEscrow OnlyEscrowOwner {
        bool Eligible = IMMYEligible(MMYEligible).TransferEligible(address(this));
        if (Eligible) {
            IERC20(MMY).approve(stakedMmyTracker, MaxApproveValue);
            TransferInPrivate();
        }
        require(SaleIneligible == false, "Escrow not eligible for sale");
        require(SalePrice == 0 || block.timestamp >= EndAt, "Already Listed");
        require(IERC20(feeMmyTracker).balanceOf(address(this)) != 0 || IERC20(stakedMlpTracker).balanceOf(address(this)) != 0, "Escrow Account Can't be empty when listing for sale");
        require(_SalePrice > 0, "Choose a price greater than 0");
        require(_Length <= 30, "Max sale length = 30 days");
        IsPurchased = false;
        SalePrice = _SalePrice;
        EndAt = block.timestamp + _Length * 1 days;
        if (MasterContract.ListingsToOwners(address(this)) == address(0)) {
            MasterContract.SetListingsToOwners(EscrowOwner);
            MasterContract.PushListing();
        }
        emit Listed(address(this));
    }
    
    // Change price for Escrow
    function ChangePrice(uint256 _NewPrice) external nonReentrant ClosedEscrow OnlyEscrowOwner {
        require(SalePrice > 0, "Not currently for sale");
        require(block.timestamp < EndAt, "Listing is expired");
        SalePrice = _NewPrice;
    }
    
    // Make MMY account in Escrow no longer for sale (but potentially still accepting offers)
    function EndEarly() external nonReentrant ClosedEscrow OnlyEscrowOwner {
        require(SalePrice > 0, "Not currently for sale");
        require(block.timestamp < EndAt, "Already Expired");
        SalePrice = 0;
        EndAt = block.timestamp;
        IMMYDeployEscrow(Owner).DeleteListing(address(this));
    }
    
     // Allow buyer to make purchase at sellers list price (if Escrow is listed)
    function MakePurchase(bool _StartTransferOut, bool _PayInETH, uint24 _PoolFee) external payable nonReentrant ClosedEscrow {
        address Receiver = (MasterContract.Escrows(msg.sender));
        require(MasterContract.AllowPurchases(), "Purchase transactions are turned off for this contract!");
        require(SaleIneligible == false, "Escrow not eligible for sale");
        require(SalePrice > 0, "Not For Sale");
        require(block.timestamp < EndAt, "Ended/Not Available");
        if (_PayInETH) {
            FTMMMY(SalePrice, _PoolFee);
        }
        require(IERC20(MMY).balanceOf(msg.sender) >= SalePrice, "Insufficient Funds");
        require(IERC20(MMY).allowance(msg.sender, address(this)) >= SalePrice, "Please approve this contract to use your GMX");
        if (Receiver == address(0)) {
            Receiver = IMMYDeployEscrow(Owner).DeployBuyerEscrow(msg.sender);
        }
        uint256 Payout = 39 * SalePrice / 40;
        uint256 Fees = SalePrice - Payout;
        IMMYRewardRouter(MMYRewardRouter).handleRewards(
            false,
            false,
            false,
            false,
            false,
            true,
            true
        );
        (bool sent, ) = EscrowOwner.call{value: address(this).balance}("");
        require(sent);
        IERC20(MMY).transferFrom(msg.sender, EscrowOwner, Payout);
        IERC20(MMY).transferFrom(msg.sender, MasterContract.FeeAddress(), Fees);
        IMMYRewardRouter(MMYRewardRouter).signalTransfer(Receiver);
        IERC20(MMY).approve(stakedMmyTracker, MaxApproveValue);
        IMMYEscrow(Receiver).TransferIn();
        if (_StartTransferOut) {
            bool Eligible = IMMYEligible(MMYEligible).TransferEligible(msg.sender);
            require(Eligible, "Please purchase using an account that has never staked GMX/esGMX or held GLP");
            IMMYEscrow(Receiver).TransferOutEscrowOwner();
        }
        EndAt = block.timestamp;
        SalePrice = 0;
        IMMYEscrow(Receiver).SetIsPurchased();
        IsSold = true;
        IMMYDeployEscrow(Owner).DeleteListing(address(this));
        emit Purchased(Receiver, address(this));
    }
    
    
    // Close Escrow once empty
    function CloseEscrow() external nonReentrant ClosedEscrow OnlyEscrowOwner {
    	require(IERC20(MMY).balanceOf(address(this)) == 0, "Please Remove MMY");
        require(IERC20(WFTM).balanceOf(address(this)) == 0, "Please Remove WFTM");
        require(IERC20(stakedMlpTracker).balanceOf(address(this)) == 0, "Please Remove MLP");
        require(IERC20(feeMmyTracker).balanceOf(address(this)) == 0, "Please Remove staked MMY and/or bonus points");
        IMMYDeployEscrow(Owner).ResetCloseEscrow(EscrowOwner);
        IsActive = false;
    }
    
    // Withdraw all FTM from this contract
    function WithdrawFTM() external payable nonReentrant OnlyEscrowOwner {
        require(address(this).balance > 0, "No FTM to withdraw");
        (bool sent, ) = EscrowOwner.call{value: address(this).balance}("");
        require(sent);
    }
    
    // Withdraw any ERC20 token from this contract
    function WithdrawToken(address _tokenaddress, uint256 _Amount) external nonReentrant OnlyEscrowOwner {
        IERC20(_tokenaddress).transfer(EscrowOwner, _Amount);
    }
    
    // Allow purchasing Escrow account to set selling Escrow account "IsPurchased" to true during purchase
    function SetIsPurchased() external nonReentrant ClosedEscrow {
        require(MasterContract.EscrowsToOwners(msg.sender) != address(0));
        IsPurchased = true;
    }

    // Internal function for buying with FTM
    function FTMMMY(uint256 amountOut, uint24 poolFee) private {
        if (poolFee == 5050) {
            uint256 amountOutHalf1 = amountOut / 2;
            uint256 amountOutHalf2 = amountOut - amountOutHalf1;
            uint256 amountInMaxHalf1 = msg.value / 2;
            uint256 amountInMaxHalf2 = msg.value - amountInMaxHalf1;
            ISwapRouter.ExactOutputSingleParams memory params1 = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: WFTM,
                tokenOut: MMY,
                fee: 3000,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOutHalf1,
                amountInMaximum: amountInMaxHalf1,
                sqrtPriceLimitX96: 0
            }); 
            ISwapRouter.ExactOutputSingleParams memory params2 = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: WFTM,
                tokenOut: MMY,
                fee: 10000,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOutHalf2,
                amountInMaximum: amountInMaxHalf2,
                sqrtPriceLimitX96: 0
            }); 
            router.exactOutputSingle{ value: amountInMaxHalf1 }(params1);
            router.exactOutputSingle{ value: amountInMaxHalf2 }(params2);
            refundrouter.refundFTM();
            (bool success,) = msg.sender.call{ value: address(this).balance }("");
            require(success, "refund failed");
        } else if (poolFee == 7525) {
            uint256 amountOutHalf2 = amountOut / 4;
            uint256 amountOutHalf1 = amountOut - amountOutHalf2;
            uint256 amountInMaxHalf2 = msg.value / 4;
            uint256 amountInMaxHalf1 = msg.value - amountInMaxHalf2;
            ISwapRouter.ExactOutputSingleParams memory params1 = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: WFTM,
                tokenOut: MMY,
                fee: 3000,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOutHalf1,
                amountInMaximum: amountInMaxHalf1,
                sqrtPriceLimitX96: 0
            }); 
            ISwapRouter.ExactOutputSingleParams memory params2 = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: WFTM,
                tokenOut: MMY,
                fee: 10000,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOutHalf2,
                amountInMaximum: amountInMaxHalf2,
                sqrtPriceLimitX96: 0
            }); 
            router.exactOutputSingle{ value: amountInMaxHalf1 }(params1);
            router.exactOutputSingle{ value: amountInMaxHalf2 }(params2);
            refundrouter.refundFTM();
            (bool success,) = msg.sender.call{ value: address(this).balance }("");
            require(success, "refund failed");
        } else if (poolFee == 2575) {
            uint256 amountOutHalf1 = amountOut / 4;
            uint256 amountOutHalf2 = amountOut - amountOutHalf1;
            uint256 amountInMaxHalf1 = msg.value / 4;
            uint256 amountInMaxHalf2 = msg.value - amountInMaxHalf1;
            ISwapRouter.ExactOutputSingleParams memory params1 = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: WFTM,
                tokenOut: MMY,
                fee: 3000,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOutHalf1,
                amountInMaximum: amountInMaxHalf1,
                sqrtPriceLimitX96: 0
            }); 
            ISwapRouter.ExactOutputSingleParams memory params2 = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: WFTM,
                tokenOut: MMY,
                fee: 10000,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOutHalf2,
                amountInMaximum: amountInMaxHalf2,
                sqrtPriceLimitX96: 0
            }); 
            router.exactOutputSingle{ value: amountInMaxHalf1 }(params1);
            router.exactOutputSingle{ value: amountInMaxHalf2 }(params2);
            refundrouter.refundFTM();
            (bool success,) = msg.sender.call{ value: address(this).balance }("");
            require(success, "refund failed");
        }
        else {
            ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
                .ExactOutputSingleParams({
                    tokenIn: WFTM,
                    tokenOut: MMY,
                    fee: poolFee,
                    recipient: msg.sender,
                    deadline: block.timestamp,
                    amountOut: amountOut,
                    amountInMaximum: msg.value,
                    sqrtPriceLimitX96: 0
                });

            router.exactOutputSingle{ value: msg.value }(params);
            refundrouter.refundFTM();
            (bool success,) = msg.sender.call{ value: address(this).balance }("");
            require(success, "refund failed");
            }
        
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IMMYRewardRouter {
    function stakeMMY(uint256 _amount) external;
    function stakeEsMMY(uint256 _amount) external;
    function unstakeMmy(uint256 _amount) external;
    function unstakeEsMMY(uint256 _amount) external;
    function claim() external;
    function claimEsMMY() external;
    function claimFees() external;
    function compound() external;
    function handleRewards(
        bool _shouldClaimMmy,
        bool _shouldStakeMmy,
        bool _shouldClaimEsMMY,
        bool _shouldStakeEsMMY,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWFTM,
        bool _shouldConvertWFTMToFTM
    ) external;
    function signalTransfer(address _receiver) external;
    function acceptTransfer(address _sender) external;
}

interface IWFTM is IERC20 {
    function deposit() external payable;
    function withdraw(uint amount) external;
}

interface IPriceConsumerV3 {
    function getLatestPrice() external view;
}

interface IMMYEscrow {
    function TransferOutEscrowOwner() external;
    function TransferIn() external;
    function SetIsPurchased() external;
}

interface IMMYDeployEscrow {
    function DeployBuyerEscrow(address _Address) external returns (address addr);
    function ResetCloseEscrow(address _address) external;
    function DeleteListing(address _address) external;
    function SetListingsToOwners(address _Address) external;
}

interface IMMYEligible {
    function TransferEligible(address _receiver) external view returns (bool Eligible);
}

interface IPeripheryPayments {
    function refundFTM() external payable;
}

interface ISwapRouter {
    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);
}