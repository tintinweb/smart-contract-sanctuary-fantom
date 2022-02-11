/**
 *Submitted for verification at FtmScan.com on 2022-02-05
*/

// SPDX-License-Identifier: Copyrighted
///@title A farming/staking pools factory supporting mintable or fixed supply tokens and any kind of apy and reward
///@author @drotodev aka P.C.(I)
///@notice You CAN'T use this work by forking it without explicit permission (see Copyright meaning on Wikipedia)
///@notice Anyway, use this at your own risk

pragma solidity ^0.8.4;


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

///@dev This interface, extending IERC20, allows to control mint and burn of the rewards
interface IERC20RewardToken is IERC20 {
    function mint_rewards(uint256 qty, address receiver) external;
    function burn_tokens(uint256 qty, address burned) external;
}

contract LORD {


    string public name = "LORD";
    
    struct farm_slot {
        bool active;
        uint balance;
        uint deposit_time;
        uint locked_time;
        address token;
    }

    struct farm_pool {
        mapping(uint => uint) lock_multiplier;
        mapping(address => uint) is_farming;
        mapping(address => bool) has_farmed;
        uint total_balance;
        uint min_lock;
        uint emission_rate;
        address reward;
        address owner;
        bool mintable;
        IERC20RewardToken reward_token;
        IERC20 reward_token_fixed;
    }

    address public owner;

    address[] public farms;

    mapping(address => mapping(uint => farm_slot)) public farming_unit;
    mapping(address => uint[]) farmer_pools;
    mapping(address => farm_pool) public token_pool;
    mapping(address => uint) farm_id;
    mapping(address => bool) public is_farmable;
    mapping(address => uint) public last_tx;
    mapping(address => mapping(uint => uint)) public lock_multiplier;

    mapping(address => bool) public is_auth;

    uint256 cooldown_time = 10 seconds;
    
    // in constructor pass in the address for fang token and your custom bank token
    // that will be used to pay interest
    constructor() {
        owner = msg.sender;
    }

    bool locked;

    modifier farm_owner(address token) {
        require((msg.sender == token_pool[token].owner) || (owner==msg.sender || is_auth[msg.sender]) );
        _;
    }

    modifier safe() {
        require (!locked, "Guard");
        locked = true;
        _;
        locked = false;
    }

    modifier cooldown() {
        require(block.timestamp > last_tx[msg.sender] + cooldown_time, "Calm down");
        _;
        last_tx[msg.sender] = block.timestamp;
    }

    modifier authorized() {
        require(owner==msg.sender || is_auth[msg.sender], "403");
        _;
    }
    
    ///@dev Returns the state of a specific pool owned by an user
    ///@param id The ID of the pool
    ///@param addy The address of the pool's owner
    ///@return A bool that indicates the state of the pool
    function is_unlocked (uint id, address addy) public view returns(bool) {
        return( (block.timestamp > farming_unit[addy][id].deposit_time + farming_unit[addy][id].locked_time) );
    }

    ///@notice Events

    event replenish(address token, uint qty, address from);
    event farmed(address token, uint qty, address from, uint lock);
    event withdraw(address token, uint qty, uint rewards, address from, uint id);
    event rewarded(address token, uint rewards, address from, uint id, uint lock);

    ///@notice Public farming functions

    
    ///@dev Approves spending from this contract in behalf of sender
    ///@param token Which token need to be approved
    function approveTokens(address token) public {
        bool approved = IERC20(token).approve(address(this), 2**256 - 1);
        require(approved, "Can't approve");
    }

    ///@dev Deposit farmable tokens in the contract
    ///@param _amount The number of tokens to deposit (expecting decimals too)
    ///@param token The token to use as deposit
    ///@param locking Locking time (checked against the minimum of the pool) in seconds
    function farmTokens(uint _amount, address token, uint locking) public {
        require(is_farmable[token], "Farming not supported");
        if(locking < token_pool[token].min_lock) {
            locking = token_pool[token].min_lock;
        }
        require(IERC20(token).allowance(msg.sender, address(this)) >= _amount, "Allowance?");

        // Trasnfer farmable tokens to contract for farming
        bool transferred = IERC20(token).transferFrom(msg.sender, address(this), _amount);
        require(transferred, "Not transferred");
        // Update the farming balance in mappings
        farm_id[msg.sender]++;
        uint id = farm_id[msg.sender];
        farming_unit[msg.sender][id].locked_time = locking;
        farming_unit[msg.sender][id].balance = farming_unit[msg.sender][id].balance + _amount;
        farming_unit[msg.sender][id].deposit_time = block.timestamp;
        farming_unit[msg.sender][id].token = token;
        token_pool[token].total_balance += _amount;

        // Add user to farmrs array if they haven't farmd already
        if(token_pool[token].has_farmed[msg.sender]) {
            token_pool[token].has_farmed[msg.sender] = true;
        }

        // Update farming status to track
        token_pool[token].is_farming[msg.sender]++;
        farmer_pools[msg.sender].push(id);

        // Emit an event
        emit farmed(token, _amount, msg.sender, locking);
    }


     ///@dev Unfarm tokens (if not locked)
     ///@param id The id of a pool owned by sender
     function unfarmTokens(uint id) public safe cooldown {
        require(is_unlocked(id, msg.sender), "Locking time not finished");

        uint balance = _calculate_rewards(id, msg.sender);

        // reqire the amount farmd needs to be greater then 0
        require(balance > 0, "farming balance can not be 0");
        address target_token = farming_unit[msg.sender][id].token;  
        bool mint = token_pool[target_token].mintable;
        // transfer fang tokens out of this contract to the msg.sender
        if(mint) {
            IERC20RewardToken target_reward = token_pool[target_token].reward_token;
            IERC20(target_token).transfer(msg.sender, farming_unit[msg.sender][id].balance);
            target_reward.mint_rewards(balance, msg.sender);    
        } else {
            IERC20 target_reward = token_pool[target_token].reward_token_fixed;
            IERC20(target_token).transfer(msg.sender, farming_unit[msg.sender][id].balance);
            require(target_reward.balanceOf(address(this)) >= balance, "Not enough supply");
            target_reward.transfer(msg.sender, balance);
        }
        // reset farming balance map to 0
        farming_unit[msg.sender][id].balance = 0;
        farming_unit[msg.sender][id].active = false;
        farming_unit[msg.sender][id].deposit_time = block.timestamp;
        address token = farming_unit[msg.sender][id].token;

        // update the farming status
        token_pool[token].is_farming[msg.sender]--;

        // Emit an event
        emit withdraw(token, farming_unit[msg.sender][id].balance, balance, msg.sender, id);

} 

    ///@dev Give rewards and clear the reward status  
    ///@param id The id of a pool owned by sender  
    function issueInterestToken(uint id) public safe cooldown {
        require(is_unlocked(id, msg.sender), "Locking time not finished");
        address target_token = farming_unit[msg.sender][id].token;
        uint balance = _calculate_rewards(id, msg.sender);
        bool mint = token_pool[target_token].mintable;
        if(mint) {
            IERC20RewardToken target_reward = token_pool[target_token].reward_token;            
            target_reward.mint_rewards(balance, msg.sender);
        } else {
            IERC20 target_reward = token_pool[target_token].reward_token_fixed;
            require(target_reward.balanceOf(address(this)) >= balance, "Not enough supply");
            target_reward.transfer(msg.sender, balance);
        }
        // reset the time counter so it is not double paid
        farming_unit[msg.sender][id].deposit_time = block.timestamp;  

        // Emit an event
        emit rewarded(target_token, balance, msg.sender, id, farming_unit[msg.sender][id].locked_time);

    }
        

    ///@notice Private functions

    ///@dev Helper to calculate rewards in a quick and lightweight way  
    ///@param id The id of a pool owned by addy
    ///@param addy The address to calculate the rewards for
    function _calculate_rewards(uint id, address addy) public view returns (uint) {
    	// get the users farming balance in fang
        address local_token = farming_unit[addy][id].token;
    	uint percentage = (farming_unit[addy][id].balance*100)/token_pool[local_token].total_balance;
        uint delta_time = block.timestamp - farming_unit[addy][id].deposit_time; // - initial deposit
        uint time_bonus = (token_pool[farming_unit[addy][id].token].lock_multiplier[farming_unit[addy][id].locked_time]);
        uint base_rate = token_pool[farming_unit[addy][id].token].emission_rate;
        uint bonus = (base_rate * time_bonus)/100;
        uint final_reward = base_rate + bonus;
        uint total_rewards = (final_reward * delta_time);
        uint balance = (total_rewards*percentage)/100;
        return balance;
     }

     ///@notice Control functions

     ///@dev Allows to create a new farm for a given token. Requires possession of the token and must be unique
     ///@param token The token to create the pool for
     ///@param reward The token that will be given as reward 
     ///@param min_lock The minimum amount of time accepted as locking time
     ///@param emission_rate The emission rate per block of the reward token
     ///@param mintable Specify if the reward token is to mint or to take from the contract
     ///@param token_decimals The decimals of the reward token
     function create_farmable(
         address token, 
         address reward, 
         uint min_lock, 
         uint emission_rate, 
         uint token_decimals,
         bool mintable
     ) 
     public payable safe cooldown {
         require(!is_farmable[token], "Existing!");
         require(IERC20(token).balanceOf(msg.sender)>0, "You don't own any token");
         is_farmable[token] = true;
         token_pool[token].reward = reward;
         token_pool[token].min_lock = min_lock;
         token_pool[token].emission_rate = emission_rate * token_decimals;
         token_pool[token].owner = msg.sender;
         token_pool[token].mintable = mintable;
         if(mintable) {
            token_pool[token].reward_token = IERC20RewardToken(reward);
         } else { 
            token_pool[token].reward_token_fixed = IERC20(reward);
         }
     }

     ///@dev A farm owner can add tokens to a non mintable farm to replenish it
     ///@param amount How many tokens are given
     ///@param farmable The address of a farm
     function add_to_farm_balance(uint amount, address farmable) public farm_owner(farmable) {
         require(!token_pool[farmable].mintable, "You can't add balance to a mintable token");
         require(IERC20(farmable).balanceOf(msg.sender) >= amount, "Not enough tokens");
         require(IERC20(farmable).allowance(msg.sender, address(this)) >= amount, "Please approve spending");
         bool sent = IERC20(farmable).transferFrom(msg.sender, address(this), amount);
         require(sent, "Cannot transfer");
         emit replenish(farmable, amount, msg.sender);
     }

    ///@dev Get all the pools id for a farmer
    ///@param farmer The farmer address
    ///@return An array containing the IDs
    function get_farmer_pools(address farmer) public view returns(uint[] memory) {
         return(farmer_pools[farmer]);
    }

    ///@dev Authorize or unauthorize an address to operate on this contract
    ///@param addy The target address
    ///@param booly Set true or false the authorization
    function set_authorized(address addy, bool booly) public authorized {
        is_auth[addy] = booly;
    }

    ///@dev A farm owner can transfer the farm ownership
    ///@param token The farmable token to act on
    ///@param new_owner The new owner of the farm 
    function set_farm_owner(address token, address new_owner) public farm_owner(token) {
         token_pool[token].owner = new_owner;
     }

    ///@dev A farm owner can enable or disable a farm
    ///@param token The farm to target
    ///@param status Enable or disable with true or false
    function set_farming_state(address token, bool status) public farm_owner(token) {
         is_farmable[token] = status;
     }

    ///@dev Get the status of a given farm
    ///@param token The farm to check
    ///@return Farm enabled or not enabled status
    function get_farming_state(address token) public view returns (bool) {
         return is_farmable[token];
     }

    ///@dev A farm owner can set the multiplier applied based on locking time
    ///@param token The farm to target
    ///@param time The locking time to target
    ///@param multiplier The multiplier (in %) that will be added to the emission rate
    function set_multiplier(address token, uint time, uint multiplier) public farm_owner(token) {
         lock_multiplier[token][time] = multiplier;
     }

     ///@dev Get the multiplier referred to a locking time for a farm
     ///@param token The farm to inspect
     ///@param time The locking time to inspect
     ///@return The multiplier applied to the emission rate for that farm     
     function get_multiplier(address token, uint time) public view returns(uint) {
         return lock_multiplier[token][time];
     }


    ///@notice time helpers

     ///@dev Get 1 day in seconds
     ///@return 1 day in seconds
     function HELPER_get_1_day() public pure returns(uint) {
         return(1 days);
     }

    
     ///@dev Get 1 week in seconds
     ///@return 1 week in seconds
     function HELPER_get_1_week() public pure returns(uint) {
         return(7 days);
     }

    
     ///@dev Get 30 days in seconds
     ///@return 30 days in seconds
     function HELPER_get_1_month() public pure returns(uint) {
         return(30 days);
     }
     
     
     ///@dev Get 90 days in seconds
     ///@return 90 days in seconds
     function HELPER_get_3_months() public pure returns(uint) {
         return(90 days);
     }

    
     ///@dev Get a number of days in seconds
     ///@return A number of days in seconds
     function HELPER_get_x_days(uint x) public pure returns(uint) {
         return((1 days*x));
     }

    ///@dev Fallback function to receive ETH
    receive() external payable {}
    
    ///@dev Fallback function for everything else
    fallback() external payable {}
}