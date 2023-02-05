/**
 *Submitted for verification at FtmScan.com on 2023-02-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IMWSWORDS {
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event TransferBatch(
        address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values
    );
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event URI(string value, uint256 indexed id);
    event Unpaused(address account);

    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) external view returns (uint256[] memory);
    function burn(address account, uint256 id, uint256 value) external;
    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;
    function cost() external view returns (uint256);
    function exists(uint256 id) external view returns (bool);
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
    function owner() external view returns (address);
    function pause() external;
    function paused() external view returns (bool);
    function renounceOwnership() external;
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
    function setApprovalForAll(address operator, bool approved) external;
    function setCost(uint256 _newCost) external;
    function setSwordv10value(uint256 _newSwordv10value) external;
    function setSwordv1value(uint256 _newSwordv1value) external;
    function setSwordv2value(uint256 _newSwordv2value) external;
    function setSwordv3value(uint256 _newSwordv3value) external;
    function setSwordv4value(uint256 _newSwordv4value) external;
    function setSwordv5value(uint256 _newSwordv5value) external;
    function setSwordv6value(uint256 _newSwordv6value) external;
    function setSwordv7value(uint256 _newSwordv7value) external;
    function setSwordv8value(uint256 _newSwordv8value) external;
    function setSwordv9value(uint256 _newSwordv9value) external;
    function setTokenUri(uint256 tokenId, string memory uri) external;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function swordv1() external view returns (uint256);
    function swordv10() external view returns (uint256);
    function swordv10value() external view returns (uint256);
    function swordv1value() external view returns (uint256);
    function swordv2() external view returns (uint256);
    function swordv2value() external view returns (uint256);
    function swordv3() external view returns (uint256);
    function swordv3value() external view returns (uint256);
    function swordv4() external view returns (uint256);
    function swordv4value() external view returns (uint256);
    function swordv5() external view returns (uint256);
    function swordv5value() external view returns (uint256);
    function swordv6() external view returns (uint256);
    function swordv6value() external view returns (uint256);
    function swordv7() external view returns (uint256);
    function swordv7value() external view returns (uint256);
    function swordv8() external view returns (uint256);
    function swordv8value() external view returns (uint256);
    function swordv9() external view returns (uint256);
    function swordv9value() external view returns (uint256);
    function token() external view returns (address);
    function totalSupply(uint256 id) external view returns (uint256);
    function transferOwnership(address newOwner) external;
    function unpause() external;
    function uri(uint256 tokenId) external view returns (string memory);
    function withdrawTokens(address _token, uint256 _amount, address _to) external;
}

interface IMAGIC {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TaxOfficeTransferred(address oldAddress, address newAddress);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function INITIAL_AIRDROP_WALLET_DISTRIBUTION() external view returns (uint256);
    function INITIAL_GENESIS_POOL_DISTRIBUTION() external view returns (uint256);
    function INITIAL_MAGIK_POOL_DISTRIBUTION() external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function autoCalculateTax() external view returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function burnThreshold() external view returns (uint256);
    function decimals() external view returns (uint8);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function disableAutoCalculateTax() external;
    function distributeReward(address _genesisPool, address _magikPool, address _airdropWallet) external;
    function enableAutoCalculateTax() external;
    function excludeAddress(address _address) external returns (bool);
    function excludedAddresses(address) external view returns (bool);
    function getTaxTiersRatesCount() external view returns (uint256 count);
    function getTaxTiersTwapsCount() external view returns (uint256 count);
    function governanceRecoverUnsupported(address _token, uint256 _amount, address _to) external;
    function includeAddress(address _address) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function isAddressExcluded(address _address) external view returns (bool);
    function isOperator() external view returns (bool);
    function magikOracle() external view returns (address);
    function mint(address recipient_, uint256 amount_) external returns (bool);
    function name() external view returns (string memory);
    function operator() external view returns (address);
    function owner() external view returns (address);
    function renounceOwnership() external;
    function rewardPoolDistributed() external view returns (bool);
    function setBurnThreshold(uint256 _burnThreshold) external returns (bool);
    function setMagikOracle(address _magikOracle) external;
    function setTaxCollectorAddress(address _taxCollectorAddress) external;
    function setTaxOffice(address _taxOffice) external;
    function setTaxRate(uint256 _taxRate) external;
    function setTaxTiersRate(uint8 _index, uint256 _value) external returns (bool);
    function setTaxTiersTwap(uint8 _index, uint256 _value) external returns (bool);
    function symbol() external view returns (string memory);
    function taxCollectorAddress() external view returns (address);
    function taxOffice() external view returns (address);
    function taxRate() external view returns (uint256);
    function taxTiersRates(uint256) external view returns (uint256);
    function taxTiersTwaps(uint256) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transferOperator(address newOperator_) external;
    function transferOwnership(address newOwner) external;

}

contract MultiSender {
    function multiERC20(IMAGIC _token, address[] calldata _to, uint256[] calldata _amts) external {
        for (uint256 i; i < _to.length; i++) {
            _token.transferFrom(msg.sender, _to[i], _amts[i]);
        }
    }
 
    function sendEther(address payable[] memory recipients, uint256[] memory amounts) public payable  {
       for (uint256 i; i < recipients.length; i++) {
            recipients[i].transfer(amounts[i]);
        }

    }


    function multiERC1155(IMWSWORDS _swords, address[] calldata _to, uint256[] calldata _amts, uint256 _id) external {
        for (uint256 i; i < _to.length; i++) {
            _swords.safeTransferFrom(msg.sender, _to[i], _id, _amts[i], new bytes(0));
        }
    }
    
}