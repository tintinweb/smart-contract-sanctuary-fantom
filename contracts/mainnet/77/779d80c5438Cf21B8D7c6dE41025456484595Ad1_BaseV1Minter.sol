/**
 *Submitted for verification at FtmScan.com on 2022-05-05
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

library Math {
    function max(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }
}

interface ve {
    function token() external view returns (address);
    function totalSupply() external view returns (uint);
    function create_lock_for(uint, uint, address) external returns (uint);
    function transferFrom(address, address, uint) external;
}

interface underlying {
    function approve(address spender, uint value) external returns (bool);
    function mint(address, uint) external;
    function totalSupply() external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function transfer(address, uint) external returns (bool);
}

interface voter {
    function notifyRewardAmount(uint amount) external;
}

interface ve_dist {
    function checkpoint_token() external;
    function checkpoint_total_supply() external;
}

// codifies the minting rules as per ve(3,3), abstracted from the token to support any token that allows minting

contract BaseV1Minter {

    uint internal constant week = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
    uint internal constant emission = 98;
    uint internal constant tail_emission = 2;
    uint internal constant target_base = 100; // 2% per week target emission
    uint internal constant tail_base = 1000; // 0.2% per week target emission
    underlying public immutable _token;
    voter public immutable _voter;
    ve public immutable _ve;
    ve_dist public immutable _ve_dist;
    uint public weekly = 20000000e18;
    uint public active_period;
    uint internal constant lock = 86400 * 7 * 52 * 4;

    address internal initializer;
    address public fetch;

    event Mint(address indexed sender, uint weekly, uint circulating_supply, uint circulating_emission);

    constructor(
        address __voter, // the voting & distribution system
        address  __ve, // the ve(3,3) system that will be locked into
        address __ve_dist // the distribution system that ensures users aren't diluted
    ) {
        initializer = msg.sender;
        _token = underlying(ve(__ve).token());
        _voter = voter(__voter);
        _ve = ve(__ve);
        _ve_dist = ve_dist(__ve_dist);
        active_period = (block.timestamp + (2*week)) / week * week;
    }

    function initialize(
      address _fetch,
      uint max
    ) external {
        require(initializer == msg.sender);
        _token.mint(address(this), max);
        fetch = _fetch;
        initializer = address(0);
        active_period = (block.timestamp + week) / week * week;
    }

    // allow mint for fetch
    function mintForFetch(uint _amount) external {
      require(msg.sender == fetch, "Not fetch");
      _token.mint(fetch, _amount);
      emit Mint(fetch, _amount, circulating_supply(), circulating_emission());
    }

    // calculate circulating supply as total token supply - locked supply
    function circulating_supply() public view returns (uint) {
        return _token.totalSupply() - _ve.totalSupply();
    }

    // emission calculation is 2% of available supply to mint adjusted by circulating / total supply
    function calculate_emission() public view returns (uint) {
        return weekly * emission * circulating_supply() / target_base / _token.totalSupply();
    }

    // weekly emission takes the max of calculated (aka target) emission versus circulating tail end emission
    function weekly_emission() public view returns (uint) {
        return Math.max(calculate_emission(), circulating_emission());
    }

    // calculates tail end (infinity) emissions as 0.2% of total supply
    function circulating_emission() public view returns (uint) {
        return circulating_supply() * tail_emission / tail_base;
    }

    // calculate inflation and adjust ve balances accordingly
    function calculate_growth(uint _minted) public view returns (uint) {
        return _ve.totalSupply() * _minted / _token.totalSupply();
    }

    // update period can only be called once per cycle (1 week)
    function update_period() external returns (uint) {
        uint _period = active_period;
        if (block.timestamp >= _period + week && initializer == address(0)) { // only trigger if new week
            _period = block.timestamp / week * week;
            active_period = _period;
            weekly = weekly_emission();

            uint _growth = calculate_growth(weekly);
            uint _required = _growth + weekly;
            uint _balanceOf = _token.balanceOf(address(this));
            if (_balanceOf < _required) {
                _token.mint(address(this), _required-_balanceOf);
            }

            require(_token.transfer(address(_ve_dist), _growth));
            _ve_dist.checkpoint_token(); // checkpoint token balance that was just minted in ve_dist
            _ve_dist.checkpoint_total_supply(); // checkpoint supply

            _token.approve(address(_voter), weekly);
            _voter.notifyRewardAmount(weekly);

            emit Mint(msg.sender, weekly, circulating_supply(), circulating_emission());
        }
        return _period;
    }

}