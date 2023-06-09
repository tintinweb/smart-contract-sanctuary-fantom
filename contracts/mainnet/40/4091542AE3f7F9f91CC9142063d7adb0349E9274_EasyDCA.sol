// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// Interfaces
interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function decimals() external view returns (uint8);

    function approve(address spender, uint256 amount) external returns (bool);
}

interface SpookySwap {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint[] memory amounts);
}

contract EasyDCA is Ownable {
    // DCA tracking object
    struct DCA {
        address account;
        address stableCoin;
        address targetCoin;
        uint256 amount;
        uint256 frequency;
        uint256 lastPurchase;
        bool isActive;
    }
    DCA[] public dcaList; // Main list which tracks all DCAs
    mapping(address => uint256[]) public userDCAs; // User list which tracks all DCAs for a user
    uint256[] public dcaHeap = [0]; // Heap which tracks the next DCA to be executed

    // Allowed coins
    address[] public allowedStableCoins;
    address[] public allowedTargetCoins;

    // Dex
    address public dex = 0x31F63A33141fFee63D4B26755430a390ACdD8a4d; // Default is SpookySwap

    // Fee structure
    uint256 public fee = 50; // In cents, ie. 50 = $0.5
    address feeCollector;

    // Constructor
    constructor() {
        allowedStableCoins.push(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75);
        allowedTargetCoins.push(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
        feeCollector = msg.sender; // Default fee collector is the contract creator

        // Add dummy DCA for heap
        dcaList.push(
            DCA(
                0x0000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000,
                0,
                0,
                0,
                false
            )
        );
    }

    // User Methods
    function addDCA(
        address _stable,
        address _target,
        uint256 _amount,
        uint256 _frequency
    ) public {
        require(isIncludedInList(allowedStableCoins, _stable), "Invalid stable coin");
        require(isIncludedInList(allowedTargetCoins, _target), "Invalid target coin");
        // Add DCA to main list
        dcaList.push(
            DCA(
                msg.sender,
                _stable,
                _target,
                _amount,
                _frequency,
                block.timestamp,
                true
            )
        );
        // Add DCA to user
        userDCAs[msg.sender].push(dcaList.length - 1);
        // Perform first buy wihch will add DCA to heap
        executeDCA(dcaList.length - 1);
    }

    function deleteDCA(uint256 _dcaIndex) public {
        require(
            dcaList[_dcaIndex].account == msg.sender,
            "You do not own this DCA"
        );
        // Remove from main list
        dcaList[_dcaIndex].isActive = false;
    }

    // Heap methods
    function insertToHeap(uint256 _dcaIndex) internal {
        // Add the value to the end of our array
        dcaHeap.push(_dcaIndex);
        // Start at the end of the array
        uint256 currentIndex = dcaHeap.length - 1;
        // Bubble up the value until it reaches it's correct place (i.e. it is smaller than it's parent)
        while (
            currentIndex > 1 &&
            dcaList[dcaHeap[currentIndex / 2]].lastPurchase >
            dcaList[dcaHeap[currentIndex]].lastPurchase
        ) {
            // If the parent value is greater than our current value, we swap them
            (dcaHeap[currentIndex / 2], dcaHeap[currentIndex]) = (
                _dcaIndex,
                dcaHeap[currentIndex / 2]
            );
            // change our current Index to go up to the parent
            currentIndex /= 2;
        }
    }

    function removeMinFromHeap() internal returns (uint256) {
        // Ensure the heap exists
        require(dcaHeap.length > 1);
        // take the root value of the heap
        uint256 toReturn = dcaHeap[1];

        // Takes the last element of the array and puts it at the root
        dcaHeap[1] = dcaHeap[dcaHeap.length - 1];
        // Delete the last element from the array
        delete dcaHeap[dcaHeap.length - 1];

        // Start at the top
        uint256 currentIndex = 1;

        // Bubble down
        while (currentIndex * 2 < dcaHeap.length - 1) {
            // get the current index of the children
            uint256 j = currentIndex * 2;

            // left child value
            uint256 leftChild = dcaHeap[j];
            // right child value
            uint256 rightChild = dcaHeap[j + 1];

            // Compare the left and right child. if the rightChild is lower, then point j to it's index
            if (
                dcaList[leftChild].lastPurchase >
                dcaList[rightChild].lastPurchase
            ) {
                j += 1;
            }

            // compare the current parent value with the lowest child, if the parent is lower, we're done
            if (
                dcaList[dcaHeap[currentIndex]].lastPurchase <
                dcaList[dcaHeap[j]].lastPurchase
            ) {
                break;
            }

            // else swap the value
            (dcaHeap[currentIndex], dcaHeap[j]) = (
                dcaHeap[j],
                dcaHeap[currentIndex]
            );

            // and let's keep going down the heap
            currentIndex = j;
        }
        // finally, return the top of the heap
        return toReturn;
    }

    // Chainlink Methods
    function buyTokens(address _buyer, uint256 _amount, address _from, address _to) internal {
        address[] memory path = new address[](2);
        path[0] = _from;
        path[1] = _to;

        IERC20(_from).approve(dex, _amount);
        SpookySwap(dex).swapExactTokensForTokens(_amount, 0, path, _buyer, block.timestamp + 1000);
    }

    function executeDCA(uint256 _dcaIndex) internal {
        address _currentAccount = dcaList[_dcaIndex].account;
        address _currentStable = dcaList[_dcaIndex].stableCoin;

        uint8 _currentDecimals = IERC20(_currentStable).decimals(); 
        uint256 _currentAmount = dcaList[_dcaIndex].amount * (10 ** _currentDecimals);
        
        if (IERC20(_currentStable).transferFrom(_currentAccount, address(this), _currentAmount)) {
            address _currentTarget = dcaList[_dcaIndex].targetCoin;
            uint256 _feeAmountWithDecimals = fee * (10 ** _currentDecimals) / 100;
            uint256 _amountToBuy = _currentAmount - _feeAmountWithDecimals;

            IERC20(_currentStable).transfer(feeCollector, _feeAmountWithDecimals);
            buyTokens(_currentAccount, _amountToBuy, _currentStable, _currentTarget);

            // Update the last purchase time and re-add to the heap
            dcaList[_dcaIndex].lastPurchase = block.timestamp;
            insertToHeap(_dcaIndex);
        } else { // If purchase can't happen disable the DCA order
            dcaList[_dcaIndex].isActive = false;
        }
    }

    function checkUpkeep(
        bytes calldata
    ) external view returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = (dcaList[dcaHeap[1]].lastPurchase + dcaList[dcaHeap[1]].frequency) < block.timestamp;
    }

    function performUpkeep(bytes calldata) public {
        if ((dcaList[dcaHeap[1]].lastPurchase + dcaList[dcaHeap[1]].frequency) < block.timestamp) {
            uint256 _dcaIndex = removeMinFromHeap();

            if (dcaList[_dcaIndex].isActive) {
                executeDCA(_dcaIndex);
            }
        }
    }

    // Helper Methods
    function isIncludedInList(
        address[] memory _list,
        address _token
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < _list.length; i++) {
            if (_list[i] == _token) {
                return true;
            }
        }
        return false;
    }

    // Manager Methods
    function addToStableCoinsList(address _newCoin) public onlyOwner {
        require(
            !isIncludedInList(allowedStableCoins, _newCoin),
            "Token already in list"
        );
        allowedStableCoins.push(_newCoin);
    }

    function addToTargetCoinsList(address _newCoin) public onlyOwner {
        require(
            !isIncludedInList(allowedTargetCoins, _newCoin),
            "Token already in list"
        );
        allowedTargetCoins.push(_newCoin);
    }

    function removeFromStableCoinsList(address _coin) public onlyOwner {
        require(
            isIncludedInList(allowedStableCoins, _coin),
            "Token not in list"
        );
        for (uint256 i = 0; i < allowedStableCoins.length; i++) {
            if (allowedStableCoins[i] == _coin) {
                delete allowedStableCoins[i];
                break;
            }
        }
    }

    function removeFromTargetCoinsList(address _coin) public onlyOwner {
        require(
            isIncludedInList(allowedTargetCoins, _coin),
            "Token not in list"
        );
        for (uint256 i = 0; i < allowedTargetCoins.length; i++) {
            if (allowedTargetCoins[i] == _coin) {
                delete allowedTargetCoins[i];
                break;
            }
        }
    }

    function setFee(uint256 _newFee) public onlyOwner {
        fee = _newFee;
    }

    function setFeeCollector(address _newCollector) public onlyOwner {
        feeCollector = _newCollector;
    }

    function updateDex(address _newDex) public onlyOwner {
        dex = _newDex;
    }
}