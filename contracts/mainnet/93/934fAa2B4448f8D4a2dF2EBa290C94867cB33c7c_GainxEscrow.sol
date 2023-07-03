/**
 *Submitted for verification at FtmScan.com on 2023-07-03
*/

// SPDX-License-Identifier: MIT
// File: contracts/GainxPool.sol


pragma solidity ^0.8.9;

contract GainxPool {

    function poolBalance() public view returns(uint256){
        return address(this).balance;
    }

    function receiveFunds() payable public {}

    function sendFunds(address _receiver, uint256 _amount) payable public { 
        // amount will be paid in TFil by adding APY to the core amount
        // amount = core amount + APY from borrower + APY from pool (starts after time ends)
        (bool sent, ) = _receiver.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
    
    // APY of the pool depends upon the ratio between GainxToken trade volume to Total worth of NFTs locked in GainX escrows
    // GainX token trade volume per block / Total worth of NFTs in escrow during the block

    // Scenario 1: Trade volume >>> Total worth --> APY will shoot up for lenders and borrowers will suffer
    // Scenario 2: Trade volume <<< Total worth --> APY will go down for lenders and borrowers will enjoy
}
// File: contracts/GainxFuture.sol


pragma solidity ^0.8.9;

contract GainxFuture {
    mapping(uint256 => uint256) public escrowToApy;

    function _lockFutureApy(uint256 _escrowId, uint256 _apy) payable public {
        escrowToApy[_escrowId] = _apy;
    }
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: contracts/GainxInsurance.sol


pragma solidity ^0.8.9;


contract GainxInsurance {

    receive() payable external {}
    fallback() payable external {}
    
    using Counters for Counters.Counter;

    Counters.Counter private _insuranceIdCounter;

    struct Escrow {
        uint256 escrowId;
        uint256 startBlock;
        address nftAddress; // imp
        uint256 nftId;
        address lender;
        address borrower;
        uint256 amount; // imp
        uint256 tenure;  // imp
        uint256 apy; // imp
        bool isInsuared;  // imp
        bool accepted;
        bool completed;
    }
    Escrow[] public escrows;

    struct LendingStates {
        bool receivedNft;
        bool receivedFunds;
        bool receivedRepayAmt;
        bool receivedReedemTokens;
        bool completed;
    }

    mapping(uint256 => Escrow) public idToEscrow;
    mapping(uint256 => LendingStates) public idToLendingStates;
    mapping(address => uint256) public lenderToRepayAmt;

    mapping(address => Escrow[]) public lendersList;
    mapping(address => Escrow[]) public borrowersList;

    struct Insurance {
        uint256 insuranceId;
        uint256 lendingId;
        address buyer;
        uint256 amount;
        bool claimed;
    }
    Insurance[] public insurances;

    mapping(uint256 => Insurance) public idToInsurance; // returns Insurance details by ID
    mapping(address => Insurance[]) public insurancesForAddress; // returns all insurances by an address
    mapping(uint256 => Insurance) public insuranceToDeal; // returns the insurance details by lendingId

    function buyInsurance(address _buyer, uint256 _amount, uint256 _lendingId) payable public {
        uint256 _insuranceId = _insuranceIdCounter.current();

        Escrow storage currEscrow = idToEscrow[_lendingId];
        currEscrow.isInsuared = true;

        Insurance memory newInsurance = Insurance(_insuranceId, _lendingId, _buyer, _amount, false);

        insurances.push(newInsurance); // add to the insurance array
        idToInsurance[_insuranceId] = newInsurance; // insuranceId --> Insurance
        insurancesForAddress[_buyer].push(newInsurance); // add to a user's insured array
        insuranceToDeal[_lendingId] = newInsurance; // lendingId --> Insurance

        _insuranceIdCounter.increment();
    }

    function claimInsurance(uint256 _id) payable public {
        Insurance memory claimOffer = idToInsurance[_id];
        idToInsurance[_id].claimed = true;

        (bool sent, ) = claimOffer.buyer.call{value: claimOffer.amount}("");
        require(sent, "Failed to send Ether");
    }

    function getInsuranceDetailsById(uint256 _id) public view returns(Insurance memory) {
        return idToInsurance[_id];
    }

    function getAllInsurancesByAddress(address _user) public view returns(Insurance[] memory) {
        return insurancesForAddress[_user];
    }

    function getInsuranceDetailsByLendingId(uint256 _id) public view returns(Insurance memory) {
        return insuranceToDeal[_id];
    }

    function getTotalInsurances() public view returns(uint256) {
        return insurances.length;
    }
}
// File: contracts/GainxEscrow.sol


pragma solidity ^0.8.9;






contract GainxEscrow is GainxInsurance, GainxFuture, GainxPool {
    using Counters for Counters.Counter;

    address immutable redeemTokenAddress;

    constructor(address _redeemToken) {
        redeemTokenAddress = _redeemToken;
    }

    Counters.Counter private _escrowIdCounter;

    uint256 redeemTenure = 24 * 60 * 2 * 7; // 1 week ---> 7 days in blocks @2/min

    function _initEscrow(address _borrower, uint256 _amount, address _nftAddress, uint256 _nftId, uint256 _tenure, uint256 _apy) payable public {  // working
        uint256 _escrowId = _escrowIdCounter.current();

        uint256 _startBlock = block.number;
        // uint256 _endBlock = _startBlock + (_tenure * 2880);
        
        _lockFutureApy(_escrowId, _apy); // Future for APY
        
        Escrow memory newEscrow = Escrow(_escrowId, _startBlock, _nftAddress, _nftId, address(0), _borrower, _amount, _tenure, _apy, false, false, false);
        escrows.push(newEscrow);
        idToEscrow[_escrowId] = newEscrow;

        borrowersList[_borrower].push(newEscrow);

        LendingStates memory newLendingState = LendingStates(true, false, false, false, false);

        idToLendingStates[_escrowId] = newLendingState;

        _escrowIdCounter.increment();
    }

    function _withdrawNft(uint256 _escrowId) payable public {
        require(idToLendingStates[_escrowId].receivedFunds == false, "Cannot withdraw NFT now!!");

        // send the NFT back to borrower
    }

    function _acceptOffer(uint256 _escrowId, bool _isInsuared) payable public { // working
        Escrow storage currEscrow = idToEscrow[_escrowId];

        if (_isInsuared) {
            buyInsurance(msg.sender, currEscrow.amount, _escrowId);
            currEscrow.isInsuared = true;
        }

        idToLendingStates[_escrowId].receivedFunds = true;
        currEscrow.accepted = true;
        currEscrow.lender = msg.sender;

        uint256 _repayAmt = currEscrow.amount + ((currEscrow.apy * currEscrow.amount) / 100);  // amount --> 10^18 format 
        lenderToRepayAmt[msg.sender] = _repayAmt;
        lendersList[msg.sender].push(currEscrow);

        (bool sent,) = currEscrow.borrower.call{value: currEscrow.amount}("");
        require(sent, "Failed to send Ether");

        IERC20(redeemTokenAddress).transfer(msg.sender, idToEscrow[_escrowId].amount);
    }

    function _receiveRepayAmt(uint256 _escrowId) payable public {
        idToLendingStates[_escrowId].receivedRepayAmt = true;
        idToLendingStates[_escrowId].completed = true;
        idToEscrow[_escrowId].completed = true;

        // send the NFT back to borrower
    }

    function _receiveReedemAmt(uint256 _escrowId) payable public {  // working
        idToLendingStates[_escrowId].receivedReedemTokens = true;
        idToEscrow[_escrowId].completed = true;

        (bool sent, ) = idToEscrow[_escrowId].lender.call{value: lenderToRepayAmt[idToEscrow[_escrowId].lender]}("");
        require(sent, "Failed to send TFil tokens");

        // send the TFil to the lender
    }

    function getExploreListings() public view returns(Escrow[] memory) {  // working
        uint totalItemCount = escrows.length;
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToEscrow[i].accepted == false) {
                itemCount += 1;
            }    
        }

        Escrow[] memory items = new Escrow[](itemCount);

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToEscrow[i].accepted == false) {
                uint currentId = i;

                Escrow storage currentItem = idToEscrow[currentId];

                items[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }

        return items;
    }

    /*
    mapping(address => Escrow[]) public lendersList;
    mapping(address => Escrow[]) public borrowersList;
    */

    function getLendersList(address _lender) public view returns(Escrow[] memory){  // working
        uint totalItemCount = lendersList[_lender].length;
        uint currentIndex = 0;

        Escrow[] memory items = new Escrow[](totalItemCount);

        for (uint i = 0; i < totalItemCount; i++) {
                uint256 tempId = lendersList[_lender][i].escrowId;

                Escrow storage currentItem = idToEscrow[tempId];

                items[currentIndex] = currentItem;

                currentIndex += 1;
        }

        return items;
    }

    function getBorrowersList(address _borrower) public view returns(Escrow[] memory){  // working
        uint totalItemCount = borrowersList[_borrower].length;
        uint currentIndex = 0;

        Escrow[] memory items = new Escrow[](totalItemCount);

        for (uint i = 0; i < totalItemCount; i++) {
                uint currentId =  borrowersList[_borrower][i].escrowId;

                Escrow storage currentItem = idToEscrow[currentId];

                items[currentIndex] = currentItem;

                currentIndex += 1;
        }

        return items;
    }
}