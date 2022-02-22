// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "ERC20Burnable.sol";

import "Math.sol";
import "SafeMath.sol";

import "SafeMath8.sol";
import "Operator.sol";
import "IOracle.sol";

contract Bee is ERC20Burnable, Operator {

    using SafeMath for uint256;
    using SafeMath8 for uint8;

    uint256 public constant INITIAL_GENESIS_POOL_DISTRIBUTION = 25000 ether;

    uint256 public constant INITIAL_BEE_POOL_DISTRIBUTION = 75000 ether;

    bool public rewardPoolDistributed = false;

    address public beeOracle;
    
    constructor() ERC20("BEE2", "BEE2") {
        _mint(msg.sender, 1 ether); // mint 1 BEE for initial pools deployment
    }

    function setBeeOracle(address _beeOracle) public onlyOperator {
        require(_beeOracle != address(0), "oracle address cannot be 0 address");
        beeOracle = _beeOracle;
    }

    function _getBeePrice() internal view returns (uint256 _beePrice) {
        try IOracle(beeOracle).consult(address(this), 1e18) returns (uint144 _price) {
            return uint256(_price);
        } catch {
            revert("Bee: failed to fetch BEE price from Oracle");
        }
    }

    function mint(address recipient_, uint256 amount_) public onlyOperator returns (bool) {
        uint256 balanceBefore = balanceOf(recipient_);
        _mint(recipient_, amount_);
        uint256 balanceAfter = balanceOf(recipient_);
        return balanceAfter > balanceBefore;
    }

    function burn(uint256 amount) public override {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount) public override onlyOperator {
        super.burnFrom(account, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowance(sender, _msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function distributeReward(
        address _genesisPool,
        address _beePool
    ) external onlyOperator {
        require(!rewardPoolDistributed, "only can distribute once");
        require(_genesisPool != address(0), "!_genesisPool");
        require(_beePool != address(0), "!_beePool");
        rewardPoolDistributed = true;
        _mint(_genesisPool, INITIAL_GENESIS_POOL_DISTRIBUTION);
        _mint(_beePool, INITIAL_BEE_POOL_DISTRIBUTION);
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        _token.transfer(_to, _amount);
    }
}