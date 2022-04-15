// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IDanteStrategy.sol";

/**
    (                                                                        
    )\ )                   )        (                                        
    (()/(      )         ( /(   (    )\ )  (             )                (   
    /(_))  ( /(   (     )\()) ))\  (()/(  )\   (     ( /(   (      (    ))\  
    (_))_   )(_))  )\ ) (_))/ /((_)  /(_))((_)  )\ )  )(_))  )\ )   )\  /((_) 
    |   \ ((_)_  _(_/( | |_ (_))   (_) _| (_) _(_/( ((_)_  _(_/(  ((_)(_))   
    | |) |/ _` || ' \))|  _|/ -_)   |  _| | || ' \))/ _` || ' \))/ _| / -_)  
    |___/ \__,_||_||_|  \__|\___|   |_|   |_||_||_| \__,_||_||_| \__| \___|  

 */
contract SentinelV2 is Ownable {

    // Events
    event AddNewStrategy(address indexed newStrategy);
    event RemoveStrategy(address indexed removedStrategy);
    event SetOwner(address indexed newOwner);
    event PauseAll(address caller);
    event UnpauseAll(address caller);
    event PauseError(address strategy);
    event UnpauseError(address strategy);

    // Dante addresses
    address[] strategy;

    constructor () {}

    ////////////
    // Public //
    ////////////

    function reportStrategyLength() public view returns (uint256) {
        return strategy.length;
    }

    function strategyIndex(uint256 index) public view returns (address) {
        return strategy[index];
    }
        
    function findStrategyIndex(address _strategy) public view returns (uint256, bool) {
        uint256 index;
        bool found = false;

        for (uint256 i = 0; i < strategy.length; i++) {
            if (strategy[i] == _strategy) {
                index = i;
                found = true;
            }
        }

        return (index, found);
    }

    ////////////////
    // Restricted //
    ////////////////

    function removeStrategyFromIndex(address _strategyToRemove) external onlyOwner {
        address tempAddress;
        address swapAddress;

        for (uint256 i = 0; i < strategy.length; i++) {
            if (strategy[i] == _strategyToRemove) {
                tempAddress = _strategyToRemove;
                swapAddress = strategy[strategy.length - 1];
                strategy[i] = swapAddress;
                strategy[strategy.length - 1] = tempAddress;

                strategy.pop();
                emit RemoveStrategy(tempAddress);
            }
        }

    }

    function addNewStrategy(address _strat) external onlyOwner {
        bool found = false;
        ( , found) = findStrategyIndex(_strat);
        
        if (!found) {
            strategy.push(_strat);
        }

        emit AddNewStrategy(_strat);
    }

    function pauseAll(uint256 start, uint256 end) external onlyOwner {

        for(uint256 i = start; i < end + 1; i++) {

            try DanteStrategy(strategy[i]).pause()
            {} catch {
                emit PauseError(strategy[i]);
            }
        }
    }

    function unpauseAll(uint256 start, uint256 end) external onlyOwner {
        
        for(uint256 i = start; i < end + 1; i++) {

            try DanteStrategy(strategy[i]).unpause()
            {} catch {
                emit UnpauseError(strategy[i]);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface DanteStrategy {
    function pause() external;
    function unpause() external;
    function panic() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}