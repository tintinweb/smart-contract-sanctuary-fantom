/**
 *Submitted for verification at FtmScan.com on 2022-02-12
*/

// Sources flattened with hardhat v2.4.3 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}


// File contracts/ProtofiEscrow.sol

pragma solidity ^0.6.0;
contract ProtofiEscrowFactory {
    
    address[] public allEscrowContracts;
    uint256 public escrowCount = 0;
    mapping (address => uint256[]) creatorMapping;
    struct Trade {
        uint256 protoAmount;
        uint256 elecAmount;   
        uint256 timestamp;
    }
    Trade[] public trades;
    uint256 public tradeCount = 0;

    function createContract(address _seller, address _buyer, uint256 _elecAmount, uint256 _protoAmount) public {
        ProtofiEscrow newContract = new ProtofiEscrow(address(this), _seller,_buyer,_elecAmount,_protoAmount);
        allEscrowContracts.push(address(newContract));
        creatorMapping[msg.sender].push(escrowCount);
        escrowCount ++;
    }
    
    function getAllIdsFromCreator(address a) public view returns (uint256 [] memory) {
        return creatorMapping[a];
    }
    function getAllContracts() public view returns (address[] memory) {
        return allEscrowContracts;
    }
    function success(uint256 protoAmount, uint256 elecAmount) public {
        trades.push(Trade(protoAmount, elecAmount, now));
        tradeCount++;
    }
}

contract ProtofiEscrow {
    address public factory;

    address public seller;
    uint256 public elecAmount;

    address public buyer;
    uint256 public protoAmount;

    IERC20 public elec = IERC20(0x622265EaB66A45FA05bAc9B8d2262AA548FA449E);
    IERC20 public proto = IERC20(0xa23c4e69e5Eaf4500F2f9301717f12B578b948FB);

    bool public used = false;

    event BuyerDeposited();
    event SellerDeposited();
    event Finalized();
    event Cancelled();

    modifier ununsed() {
        require(!used, "Already used. Create new escrow");
        _;
    }
    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer");
        _;
    }
    modifier onlySeller() {
        require(msg.sender == seller, "Only seller");
        _;
    }
    modifier onlyBuyerOrSeller() {
        require(msg.sender == seller || msg.sender == buyer, "Only seller/buyer");
        _;
    }
    constructor(address _factory, address _seller, address _buyer, uint256 _elecAmount, uint256 _protoAmount) public {
        require(_seller != address(0), "cannot use 0 address");
        require(_buyer != address(0), "cannot use 0 address");
        require(_seller != _buyer, "seller must not be same as buyer");
        require(_elecAmount > 0, "Cannot sell 0 amt");
        require(_protoAmount > 0,  "Cannot sell 0 amt");
        seller = _seller;
        buyer = _buyer;
        elecAmount = _elecAmount;
        protoAmount = _protoAmount;
        factory = _factory;
    }

    receive() external payable {
        // fallback function to disallow any other deposits to the contract
        revert();
    }


    function buyerDeposit() public ununsed onlyBuyer {
        proto.transferFrom(msg.sender, address(this), protoAmount);
        emit BuyerDeposited();
    }
    function sellerDeposit() public ununsed onlySeller {
        elec.transferFrom(msg.sender, address(this), elecAmount);
        emit SellerDeposited();
    }
    
    function finalize() public ununsed onlyBuyerOrSeller {
        require(proto.balanceOf(address(this)) == protoAmount);
        require(elec.balanceOf(address(this)) == elecAmount);

        proto.transfer(seller, protoAmount);
        elec.transfer(buyer, elecAmount);
        used = true;
        emit Finalized();
        if (factory != address(0)){
            ProtofiEscrowFactory(factory).success(protoAmount, elecAmount);
        }
    }

    // assumes no one sent tokens direct to contract. else returned amount might be wrong
    function cancel() public onlyBuyerOrSeller {
        proto.transfer(buyer, proto.balanceOf(address(this)));
        elec.transfer(seller, elec.balanceOf(address(this)));
        used = true;
    }
}