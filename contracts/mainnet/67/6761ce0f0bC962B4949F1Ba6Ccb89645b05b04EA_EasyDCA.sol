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

interface DEX {
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
        uint256 treshold;
        bool isActive;
    }
    DCA[] public dcaList; // Main list which tracks all DCAs
    uint256[] public dcaHeap; // Heap which tracks the next DCA to be executed

    mapping(address => uint256[]) public userDCAs; // User list which tracks all DCAs for a user
    mapping(address => uint256) public userDCACount; // Number of DCAs created by a user

    // Allowed coins
    address[] public allowedStableCoins;
    address[] public allowedTargetCoins;

    // Dex
    address public dex;

    // Fee structure
    uint256 public fee; // In cents, for example: 50 = $0.5
    address feeCollector;

    // Purchase Event
    event Purchase(
        address indexed account,
        address indexed stableCoin,
        address indexed targetCoin,
        uint256 stableAmount,
        uint256 targetAmount,
        uint256 purchaseTimeStamp
    );

    // Constructor
    constructor() {
        // Set default values
        // Stables
        allowedStableCoins.push(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75); // USDC
        allowedStableCoins.push(0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E); // DAI
        allowedStableCoins.push(0x049d68029688eAbF473097a2fC38ef61633A3C7A); // fUSDT
        // Targets
        allowedTargetCoins.push(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83); // wFTM
        allowedTargetCoins.push(0x74b23882a30290451A17c44f4F05243b6b58C76d); // wETH
        allowedTargetCoins.push(0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE); // BOO
        allowedTargetCoins.push(0xD67de0e0a0Fd7b15dC8348Bb9BE742F3c5850454); // BNB
        allowedTargetCoins.push(0x511D35c52a3C244E7b8bd92c0C297755FbD89212); // AVAX
        allowedTargetCoins.push(0x85dec8c4B2680793661bCA91a8F129607571863d); // BRUSH
        allowedTargetCoins.push(0x321162Cd933E2Be498Cd2267a90534A804051b11); // wBTC

        // Default Fee Collector
        feeCollector = msg.sender; // Default fee collector is the contract creator

        // Default Dex, SpookySwap
        dex = 0x31F63A33141fFee63D4B26755430a390ACdD8a4d;

        // Heap initialization
        dcaHeap.push(0); // First element is 0, so we can start from index 1
        dcaList.push(
            DCA(
                address(0),
                address(0),
                address(0),
                0,
                0,
                0,
                0,
                false
            )
        ); // First element is empty, so we can start from index 1
    }

    // USER METHODS
    function addDCA(
        address _stable,
        address _target,
        uint256 _amount,
        uint256 _frequency
    ) public {
        require(
            isIncludedInList(allowedStableCoins, _stable),
            "Invalid stable coin"
        );
        require(
            isIncludedInList(allowedTargetCoins, _target),
            "Invalid target coin"
        );
        // Add DCA to main list
        dcaList.push(
            DCA(
                msg.sender,
                _stable,
                _target,
                _amount,
                _frequency,
                block.timestamp,
                block.timestamp + _frequency,
                true
            )
        );
        // Add DCA to user
        userDCACount[msg.sender]++;
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

    // HEAP METHODS
    function insertToHeap(uint256 _dcaIndex) internal {
        // Add the value to the end of our array
        dcaHeap.push(_dcaIndex);
        // Start at the end of the array
        uint256 currentIndex = dcaHeap.length - 1;
        // Bubble up the value until it reaches it's correct place (i.e. it is smaller than it's parent)
        while (
            currentIndex > 1
            && dcaList[dcaHeap[currentIndex / 2]].treshold > dcaList[dcaHeap[currentIndex]].treshold // = parent value is greater than our current value
            && dcaList[dcaHeap[currentIndex / 2]].isActive // = parent is active
        ) {
            // If the parent value is greater than our current value, we swap them
            (dcaHeap[currentIndex / 2], dcaHeap[currentIndex]) = (dcaHeap[currentIndex], dcaHeap[currentIndex / 2]);

            // change our current index to go up to the parent
            currentIndex /= 2;
        }
    }

    function removeMinFromHeap() internal returns (uint256) {
        // Ensure the heap exists
        require(dcaHeap.length > 1, "Heap is empty"); // Heap index starts from '
        // take the root value of the heap
        uint256 toReturn = dcaHeap[1];

        // Takes the last element of the array and puts it at the root
        dcaHeap[1] = dcaHeap[dcaHeap.length - 1];
        // Pop/remove the last element from the array
        dcaHeap.pop();

        // Start at the top
        uint256 currentIndex = 1;

        // Bubble down
        while ((currentIndex * 2) < (dcaHeap.length - 1)) {
            uint256 childIndex = currentIndex * 2;

            // left child value
            uint256 leftChild = dcaHeap[childIndex];
            // right child value
            uint256 rightChild = dcaHeap[childIndex + 1];

            // Compare the left and right child. if the rightChild is lower, then point child index to it's index
            if (dcaList[leftChild].treshold > dcaList[rightChild].treshold) {
                childIndex++;
            }

            // compare the current parent value with the lowest child, if the parent is lower, we're done
            if (dcaList[dcaHeap[currentIndex]].treshold < dcaList[dcaHeap[childIndex]].treshold) 
            {
                break;
            }

            // else swap the value
            (dcaHeap[currentIndex], dcaHeap[childIndex]) = (dcaHeap[childIndex], dcaHeap[currentIndex]);

            // go downt the heap
            currentIndex = childIndex;
        }
        // finally, return the top of the heap
        return toReturn;
    }

    // MAIN LOGIC METHODS
    function buyTokens(
        address _buyer,
        uint256 _amount,
        address _from,
        address _to
    ) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = _from;
        path[1] = _to;

        IERC20(_from).approve(dex, _amount);
        return
            DEX(dex).swapExactTokensForTokens(
                _amount,
                0,
                path,
                _buyer,
                block.timestamp + 1000
            )[1];
    }

    function executeDCA(uint256 _dcaIndex) internal {
        address _currentAccount = dcaList[_dcaIndex].account;
        address _currentStable = dcaList[_dcaIndex].stableCoin;

        uint8 _currentDecimals = IERC20(_currentStable).decimals();
        uint256 _currentAmount = dcaList[_dcaIndex].amount *
            (10 ** _currentDecimals);

        try
            IERC20(_currentStable).transferFrom(
                _currentAccount,
                address(this),
                _currentAmount
            )
        returns (bool) {
            address _currentTarget = dcaList[_dcaIndex].targetCoin;
            uint256 _feeAmountWithDecimals = (fee * (10 ** _currentDecimals)) /
                100;
            uint256 _amountToBuy = _currentAmount - _feeAmountWithDecimals;

            IERC20(_currentStable).transfer(
                feeCollector,
                _feeAmountWithDecimals
            );
            uint256 _purchaseAmount = buyTokens(
                _currentAccount,
                _amountToBuy,
                _currentStable,
                _currentTarget
            );

            // Update the last purchase time and re-add to the heap
            dcaList[_dcaIndex].lastPurchase = block.timestamp;
            dcaList[_dcaIndex].treshold =
                block.timestamp +
                dcaList[_dcaIndex].frequency;
            insertToHeap(_dcaIndex);

            // Emit purchase event
            emit Purchase(
                _currentAccount,
                _currentStable,
                _currentTarget,
                _amountToBuy,
                _purchaseAmount,
                block.timestamp
            );
        } catch {
            // If purchase can't happen disable the DCA order
            dcaList[_dcaIndex].isActive = false;
        }
    }

    // CHAINLINK UPKEEP (AUTOMATION) METHODS
    function checkUpkeep(
        bytes calldata
    ) external view returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded =
            (dcaHeap.length > 1) &&
            (dcaList[dcaHeap[1]].isActive && dcaList[dcaHeap[1]].treshold < block.timestamp);
    }

    function performUpkeep(bytes calldata) public {
        if (dcaList[dcaHeap[1]].treshold < block.timestamp) {
            uint256 _dcaIndex = removeMinFromHeap();

            if (dcaList[_dcaIndex].isActive) {
                executeDCA(_dcaIndex);
            }
        }
    }

    // HELPER METHODS
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

    // MANAGER METHODS
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