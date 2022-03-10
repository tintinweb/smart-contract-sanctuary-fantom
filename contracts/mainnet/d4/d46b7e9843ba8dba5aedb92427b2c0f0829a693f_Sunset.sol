// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./BEP20.sol";

contract Sunset is BEP20 {

    // Max holding rate in basis point. (default is 5% of total supply)
    uint16 public maxHoldingRate = 500;

    // Address that are identified as botters with holding of more than 5%.
    mapping(address => bool) private _includeToBlackList;

    // Max transfer amount rate in basis points. (default is 0.5% of total supply)
    uint16 public maxTransferAmountRate = 50;

    // Addresses that excluded from antiWhale
    mapping(address => bool) private _excludedFromAntiWhale;

    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // The operator
    address private _operator;

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    modifier blackList(address sender, address recipent) {
        if (_includeToBlackList[sender] == true || _includeToBlackList[recipent] == true) {
            require(_includeToBlackList[sender] == false,"blackList: you have been blacklisted");
            require(_includeToBlackList[recipent] == false,"blackList: you have been blacklisted");
        }
        _;
    }

    modifier antiWhale(address sender, address recipient, uint256 amount) {
        if (maxTransferAmount() > 0) {
            if (
                _excludedFromAntiWhale[sender] == false
                && _excludedFromAntiWhale[recipient] == false
            ) {
                require(amount <= maxTransferAmount(), "antiWhale: transfer amount exceeds the maxTransferAmount");
            }
        }
        _;
    }

    /**
     * @notice Constructs the contract.
     */
    constructor () public BEP20("Sunset Finance", "SUN") {
        _operator = msg.sender;

        _mint(msg.sender, 10000 ether);

        _excludedFromAntiWhale[msg.sender] = true;
        _excludedFromAntiWhale[address(0)] = true;
        _excludedFromAntiWhale[address(this)] = true;
        _excludedFromAntiWhale[BURN_ADDRESS] = true;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    /// @dev overrides transfer function
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override blackList(sender, recipient) antiWhale(sender, recipient, amount) {
        super._transfer(sender, recipient, amount);
    }

    /**
     * @dev Returns the max holding amount.
     */
    function maxHolding() public view returns (uint256) {
        return totalSupply().mul(maxHoldingRate).div(10000);
    }

    /**
     * @dev Include an address to blackList.
     * Can only be called by the current operator.
     */
    function setIncludeToBlackList(address _account) public onlyOperator {
        if (balanceOf(_account) > maxHolding()) {
            _includeToBlackList[_account] = true;
        } 
        else {
            _includeToBlackList[_account] = false;
        }
    }

    /**
     * @dev Returns the max transfer amount.
     */
    function maxTransferAmount() public view returns (uint256) {
        return totalSupply().mul(maxTransferAmountRate).div(10000);
    }

    /**
     * @dev Returns the address is excluded from antiWhale or not.
     */
    function isExcludedFromAntiWhale(address _account) public view returns (bool) {
        return _excludedFromAntiWhale[_account];
    }

    /**
     * @dev Exclude or include an address from antiWhale.
     * Can only be called by the current operator.
     */
    function setExcludedFromAntiWhale(address _account, bool _excluded) public onlyOperator {
        _excludedFromAntiWhale[_account] = _excluded;
    }

    /**
     * @dev Update the max transfer amount rate.
     * Can only be called by the current operator.
     */
    function updateMaxTransferAmountRate(uint16 _maxTransferAmountRate) public onlyOperator {
        maxTransferAmountRate = _maxTransferAmountRate;
    }

    /**
     * @dev Returns the address of the current operator.
     */
    function operator() public view returns (address) {
        return _operator;
    }

    /**
     * @dev Transfers operator of the contract to a new account (`newOperator`).
     * Can only be called by the current operator.
     */
    function transferOperator(address newOperator) public onlyOperator {
        require(newOperator != address(0), "transferOperator: new operator cannot be zero address");
        _operator = newOperator;
    }
}