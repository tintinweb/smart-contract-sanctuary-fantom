/**
 *Submitted for verification at FtmScan.com on 2022-03-27
*/

pragma solidity =0.6.6;

contract BNBSender {
    // Welcome any Airdrop to 0x8b4359563FedBb81A8D550E6310c0507cf0547BD
    // simple bulk bnb send to multiple addresses

    //------------------------state variables
    //immutable means readonly but assignable by constructor
    address immutable smart_owner;

    //---------------------------

    constructor(address _smart_owner) public {
        smart_owner = _smart_owner; //builder of this contract
    }

    /// @notice Send the specified amounts of wei to the specified addresses
    /// @param addresses Addresses to which to send wei
    /// @param amounts Amounts for the corresponding addresses, the size of the
    /// array must be equal to the size of the addresses array

    function bnbSend(address payable[] memory addresses, uint256[] memory amounts) public payable {
        require(addresses.length > 0);
        require(addresses.length == amounts.length);

        uint256 length = addresses.length;
        uint256 currentSum = 0;
        for (uint256 i = 0; i < length; i++) {
            uint256 amount = amounts[i];
            require(amount > 0);
            currentSum += amount;
            require(currentSum <= msg.value);
            // Costs 9700 gas for existing accounts, 
            // 34700 gas for nonexistent accounts.
            // Might fail in case the destination is a smart contract with a default
            // method that uses more than 2300 gas.
            // If it fails the top level transaction will be reverted.
            addresses[i].transfer(amount);
        }
        require(currentSum == msg.value);
    }

    // allows sending BNB (native coin) to this smart contract
    receive() external payable {}

    // withdraw BNB from this smart contract
    function bnbTranfer(address payable withdrawn_address, uint amount) external payable {
        require(smart_owner == msg.sender,"N");
        withdrawn_address.transfer(amount);
    }
}