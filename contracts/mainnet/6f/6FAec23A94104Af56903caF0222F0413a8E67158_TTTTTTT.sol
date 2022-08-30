/**
 *Submitted for verification at FtmScan.com on 2022-08-30
*/

// File: BlackList.sol



pragma solidity ^0.8.0;

abstract contract BlackList {
    mapping (address => bool) public isBlackListed;

    event AddedBlackList(address indexed _user);

    event RemovedBlackList(address indexed _user);

    function getBlackListStatus(address _maker) external view virtual returns (bool) {
        return isBlackListed[_maker];
    }

    function _addBlackList (address _evilUser) internal virtual {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function _removeBlackList (address _clearedUser) internal virtual {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }
}

// File: ReentrancyGuard.sol



pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }
}

// File: ITOKEN.sol



pragma solidity ^0.8.0;


interface ITOKEN {

    event Transfer(address indexed from, address indexed to, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

// File: ITOKENMetadata.sol



pragma solidity ^0.8.0;



interface ITOKENMetadata is ITOKEN {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// File: Context.sol



pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: Ownable.sol




pragma solidity ^0.8.0;


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: Pausable.sol



pragma solidity ^0.8.0;


abstract contract Pausable is Context {

    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: TOKEN.sol



pragma solidity ^0.8.0;





contract TOKEN is ITOKEN, ITOKENMetadata, Pausable {

    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }

        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File: Contract.sol



pragma solidity ^0.8.0;







contract TTTTTTT is Ownable, TOKEN, ReentrancyGuard, BlackList {

    uint minAmount;
    uint32 constant MULTIPLIER = 1e9;

    uint8 public fee;

    uint public balanceFee;

    bool public resetInProgress;

    uint public totalBet;

    string[] public pools;

    address[] public users;


    mapping (string => uint) public totalPoolBet;

    mapping (address => mapping (string => uint)) public betArray;

    event BuyToken(address indexed buyer, uint256 value);

    event SellToken(address indexed seller, uint256 value);

    event CreateBet(address indexed beter, string indexed pool, uint256 value);

    event WinBet(address indexed beter, string indexed pool, uint256 value);

    event NobodyWin(string indexed pool);

    event AddPool(string indexed pool);

    event RemovePool(string indexed pool);

    event ErrorAmountNotFound(address indexed seller, uint256 value);

    modifier onlyIfResetNotInProgress(){
        require(!resetInProgress, "Reward calculation, please try again later");
        _;
    }
    // "BlockchainBitcoinBet", "BTCBET"
    constructor() TOKEN("TestTest", "TTTTTTT") {
        minAmount = 1e18;
        fee = 1;
    }

    function postNewBet(string memory pool_, uint amount_) external onlyIfResetNotInProgress {
        require(amount_ >= minAmount, "Amount less than the minimum bet");
        require(balanceOf(_msgSender()) >= amount_, "Insufficient funds");
        _burn(_msgSender(), amount_);
        bool isUser = false;
        uint256 length = users.length;
        for (uint i = 0; i < length;){
            if (users[i] == _msgSender()) {
                isUser = true;
                break;
            }
            unchecked{ i++; }
        }
        if (!isUser) {
            users.push(_msgSender());
        }
        totalBet += amount_;
        totalPoolBet[pool_] += amount_;
        betArray[_msgSender()][pool_] += amount_;
        emit CreateBet(_msgSender(), pool_, amount_);
    }

    function postWinBet(string memory pool_) external onlyOwner {
        resetInProgress = true;
        uint32 leadingWinners = 0;
        uint amount_;
        uint pr_;
        uint balanceFee_ = totalBet * fee / 100;
        uint totalBet_ = totalBet - balanceFee_;
        uint totalPoolBet_ = totalPoolBet[pool_];
        uint256 length = users.length;
        for (uint i = 0; i < length;){
            amount_ = 0;
            pr_ = 0;
            if (betArray[users[i]][pool_] > 0) {
                pr_ = betArray[users[i]][pool_] * MULTIPLIER / totalPoolBet_;
                amount_ = totalBet_ * pr_ / MULTIPLIER;
                _mint(users[i], amount_);
                leadingWinners ++;
                emit WinBet(users[i], pool_, amount_);
            }
            unchecked{ i++; }
        }
        if (leadingWinners > 0) {
            balanceFee += balanceFee_;
            _reset();
        } else {
            emit NobodyWin(pool_);
        }
        resetInProgress = false;
    }

    function _reset() private {
        totalBet = 0;
        uint256 length = users.length;
        for (uint i = 0; i < length;){
            for (uint p = 0; p < pools.length; p++) {
                betArray[users[i]][pools[p]] = 0;
            }
            unchecked{ i++; }
        }
        users = [address(0)];
        users.pop();
        length = pools.length;
        for (uint32 i = 0; i < length;) {
            totalPoolBet[pools[i]] = 0;
            unchecked{ i++; }
        }
    }

    receive() external payable {
        require(msg.value >= 1e18, "You need to send minimum 1");
        _mint(_msgSender(), msg.value);
        emit BuyToken(_msgSender(), msg.value);
    }

    function postSellToken(uint amount_) external nonReentrant {
        require(balanceOf(_msgSender()) >= amount_, "Insufficient funds");
        if (address(this).balance < amount_) {
            emit ErrorAmountNotFound(_msgSender(), amount_);
            _pause();
        } else {
            _burn(_msgSender(), amount_);
            (bool success, ) = payable(_msgSender()).call{value: amount_}("");
            require(success, "Could not sell BTCBET");
            emit SellToken(_msgSender(), amount_);
        }
    }

    function putMinAmount(uint amount_) external onlyOwner{
        minAmount = amount_;
    }

    function removePool(uint index) external onlyOwner{
        require(totalPoolBet[pools[index]] == 0, "There are bets on this pool");
        emit RemovePool(pools[index]);
        pools[index] = pools[pools.length - 1];
        pools.pop();
        
    }

    function putAddPool(string memory pool_) external onlyOwner{
        pools.push(pool_);
        emit AddPool(pool_);
    }

    function putTransferOwnership(address newOwner_) external onlyOwner {
        _transferOwnership(newOwner_);
    }

    function postAddUserBlackList(address account_) external onlyOwner {
        _addBlackList(account_);
    }

    function deleteUserBlackList(address account_) external onlyOwner {
        _removeBlackList(account_);
    }

    function putPause() external onlyOwner {
        _pause();
    }

    function putUnpause() external onlyOwner {
        _unpause();
    }

    function putFee(uint8 newFee) external onlyOwner {
        fee = newFee;
    }

    function burn(address from_, uint amount_) external onlyOwner {
        _burn(from_, amount_);
    }

    function withdrawalsFeeToOwner() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: balanceFee}("");
        require(success, "Could not withdrawals");
        balanceFee = 0;
    }

    function withdrawalsAllToOwner() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Could not withdrawals");
        balanceFee = 0;
        _pause();
    }

    function getUsers() external view returns (address[] memory){
        return users;
    }

    function getPools() external view returns (string[] memory){
        return pools;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!isBlackListed[from], "Address from in black list");
        require(!isBlackListed[to], "Address to in black list");
        require(!paused(), "Token transfer while paused");
    }

    fallback() external {
        revert("You can't do that with this token.");
    }
}