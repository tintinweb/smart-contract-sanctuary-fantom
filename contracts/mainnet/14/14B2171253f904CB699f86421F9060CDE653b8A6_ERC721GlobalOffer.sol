// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../library/CollectionReader.sol";
import "../royalty/ICollectionRoyaltyReader.sol";
import "../payment-token/IPaymentTokenReader.sol";
import "../market-settings/IMarketSettings.sol";
import "./IERC721GlobalOffer.sol";
import "./OperatorDelegation.sol";

contract ERC721GlobalOffer is
    IERC721GlobalOffer,
    OperatorDelegation,
    ReentrancyGuard
{
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    constructor(address marketSettings_) {
        _marketSettings = IMarketSettings(marketSettings_);
        _paymentTokenRegistry = IPaymentTokenReader(
            _marketSettings.paymentTokenRegistry()
        );
    }

    IMarketSettings private _marketSettings;
    IPaymentTokenReader private _paymentTokenRegistry;

    uint256 private _currentOfferId = 0;

    mapping(address => CollectionOffers) private _erc721Offers;

    /**
     * @dev See {IERC721GlobalOffer-createOffer}.
     */
    function createOffer(
        address erc721Address,
        uint256 value,
        uint256 amount,
        uint64 expireTimestamp,
        uint32 paymentTokenId,
        address bidder
    ) external {
        require(
            _marketSettings.isCollectionTradingEnabled(erc721Address),
            "trade is not open"
        );
        require(value > 0, "offer value cannot be 0");
        require(amount > 0, "offer amount cannot be 0");
        require(
            expireTimestamp - block.timestamp >=
                _marketSettings.actionTimeOutRangeMin(),
            "expire time below minimum"
        );
        require(
            expireTimestamp - block.timestamp <=
                _marketSettings.actionTimeOutRangeMax(),
            "expire time above maximum"
        );
        require(
            _isAllowedPaymentToken(erc721Address, paymentTokenId),
            "payment token not enabled"
        );
        require(
            bidder == _msgSender() || isApprovedOperator(bidder, _msgSender()),
            "sender not bidder or approved operator"
        );
        address paymentToken = _getPaymentTokenAddress(paymentTokenId);
        uint256 totalValue = value * amount;
        require(
            IERC20(paymentToken).balanceOf(bidder) >= totalValue,
            "insufficient balance"
        );
        require(
            IERC20(paymentToken).allowance(bidder, address(this)) >= totalValue,
            "insufficient allowance"
        );

        uint256 offerId = _currentOfferId;

        Offer memory offer = Offer({
            offerId: offerId,
            value: value,
            from: bidder,
            amount: amount,
            fulfilledAmount: 0,
            expireTimestamp: expireTimestamp,
            paymentTokenId: paymentTokenId
        });

        _erc721Offers[erc721Address].offerIds.add(offerId);
        _erc721Offers[erc721Address].offers[offerId] = offer;

        _currentOfferId++;

        emit OfferCreated(erc721Address, bidder, offer, _msgSender());
    }

    /**
     * @dev See {IERC721GlobalOffer-cancelOffer}.
     */
    function cancelOffer(address erc721Address, uint256 offerId) external {
        Offer memory offer = _erc721Offers[erc721Address].offers[offerId];

        require(offer.from != address(0), "offer does not exist");

        require(
            offer.from == _msgSender() ||
                isApprovedOperator(offer.from, _msgSender()),
            "sender not bidder or approved operator"
        );

        _removeOffer(erc721Address, offerId);

        emit OfferCancelled(erc721Address, offer.from, offer, _msgSender());
    }

    /**
     * @dev See {IERC721GlobalOffer-acceptOffer}.
     */
    function acceptOffer(
        address erc721Address,
        uint256 offerId,
        uint256 tokenId
    ) external {
        address tokenOwner = CollectionReader.tokenOwner(
            erc721Address,
            tokenId
        );

        Offer memory offer = _erc721Offers[erc721Address].offers[offerId];

        (bool isValid, string memory message) = _checkAcceptOfferAction(
            erc721Address,
            offer,
            tokenId,
            tokenOwner
        );

        require(isValid, message);

        _acceptOffer(erc721Address, offer, tokenId, tokenOwner);
    }

    /**
     * @dev See {IERC721GlobalOffer-batchAcceptOffer}.
     */
    function batchAcceptOffer(
        address erc721Address,
        uint256 offerId,
        uint256[] calldata tokenIds
    ) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            address tokenOwner = CollectionReader.tokenOwner(
                erc721Address,
                tokenId
            );

            Offer memory offer = _erc721Offers[erc721Address].offers[offerId];

            (bool isValid, string memory message) = _checkAcceptOfferAction(
                erc721Address,
                offer,
                tokenId,
                tokenOwner
            );

            if (isValid) {
                _acceptOffer(erc721Address, offer, tokenId, tokenOwner);
            } else {
                emit AcceptOfferFailed(
                    erc721Address,
                    offerId,
                    tokenId,
                    message,
                    _msgSender()
                );
            }
        }
    }

    /**
     * @dev See {IERC721GlobalOffer-removeExpiredOffers}.
     */
    function removeExpiredOffers(
        RemoveExpiredOfferInput[] calldata offers
    ) external {
        for (uint256 i = 0; i < offers.length; i++) {
            address erc721Address = offers[i].erc721Address;
            uint256 offerId = offers[i].offerId;
            Offer memory offer = _erc721Offers[erc721Address].offers[offerId];

            if (
                offer.expireTimestamp != 0 &&
                offer.expireTimestamp <= block.timestamp
            ) {
                _removeOffer(erc721Address, offerId);
            }
        }
    }

    /**
     * @dev check if accept action is valid
     * if not valid, return the reason
     */
    function _checkAcceptOfferAction(
        address erc721Address,
        Offer memory offer,
        uint256 tokenId,
        address tokenOwner
    ) private view returns (bool isValid, string memory message) {
        isValid = false;

        (Status status, ) = _getOfferStatus(erc721Address, offer);
        if (status != Status.ACTIVE) {
            message = "offer is not valid";
            return (isValid, message);
        }

        if (
            tokenOwner != _msgSender() &&
            !isApprovedOperator(tokenOwner, _msgSender())
        ) {
            message = "sender not owner or approved operator";
            return (isValid, message);
        }

        if (!_isApprovedToTransferToken(erc721Address, tokenId, tokenOwner)) {
            message = "transferred not approved";
            return (isValid, message);
        }

        isValid = true;
    }

    /**
     * @dev accept an offer of a single token
     */
    function _acceptOffer(
        address erc721Address,
        Offer memory offer,
        uint256 tokenId,
        address tokenOwner
    ) private nonReentrant {
        (
            FundReceiver[] memory fundReceivers,
            ICollectionRoyaltyReader.RoyaltyAmount[] memory royaltyInfo,
            uint256 serviceFee
        ) = _getFundReceiversOfOffer(erc721Address, offer, tokenId, tokenOwner);

        _sendFundToReceivers(offer.from, fundReceivers);

        IERC721(erc721Address).safeTransferFrom({
            from: tokenOwner,
            to: offer.from,
            tokenId: tokenId
        });

        offer.fulfilledAmount = offer.fulfilledAmount + 1;

        if (offer.fulfilledAmount == offer.amount) {
            _removeOffer(erc721Address, offer.offerId);
        } else {
            _erc721Offers[erc721Address].offers[offer.offerId] = offer;
        }

        emit OfferAccepted({
            erc721Address: erc721Address,
            seller: tokenOwner,
            tokenId: tokenId,
            offer: offer,
            serviceFee: serviceFee,
            royaltyInfo: royaltyInfo,
            sender: _msgSender()
        });
    }

    /**
     * @dev get list of fund receivers, amount, and payment token
     * Note:
     * List of receivers
     * - Seller of token
     * - Service fee receiver
     * - royalty receivers
     */
    function _getFundReceiversOfOffer(
        address erc721Address,
        Offer memory offer,
        uint256 tokenId,
        address tokenOwner
    )
        private
        view
        returns (
            FundReceiver[] memory fundReceivers,
            ICollectionRoyaltyReader.RoyaltyAmount[] memory royaltyInfo,
            uint256 serviceFee
        )
    {
        address paymentToken = _getPaymentTokenAddress(offer.paymentTokenId);

        royaltyInfo = ICollectionRoyaltyReader(
            _marketSettings.royaltyRegsitry()
        ).royaltyInfo(erc721Address, tokenId, offer.value);

        fundReceivers = new FundReceiver[](royaltyInfo.length + 2);

        uint256 amountToSeller = offer.value;
        for (uint256 i = 0; i < royaltyInfo.length; i++) {
            address royaltyReceiver = royaltyInfo[i].receiver;
            uint256 royaltyAmount = royaltyInfo[i].royaltyAmount;

            fundReceivers[i + 2] = FundReceiver({
                account: royaltyReceiver,
                amount: royaltyAmount,
                paymentToken: paymentToken
            });

            amountToSeller -= royaltyAmount;
        }

        (address feeReceiver, uint256 feeAmount) = _marketSettings
            .serviceFeeInfo(offer.value);
        serviceFee = feeAmount;

        fundReceivers[1] = FundReceiver({
            account: feeReceiver,
            amount: serviceFee,
            paymentToken: paymentToken
        });

        amountToSeller -= serviceFee;

        fundReceivers[0] = FundReceiver({
            account: tokenOwner,
            amount: amountToSeller,
            paymentToken: paymentToken
        });
    }

    /**
     * @dev map payment token address
     * 0 is mapped to wrapped ether address.
     * For a given chain, wrapped ether represent it's
     * corresponding wrapped coin. e.g. WBNB for BSC, WFTM for FTM
     */
    function _getPaymentTokenAddress(
        uint32 paymentTokenId
    ) private view returns (address paymentToken) {
        if (paymentTokenId == 0) {
            paymentToken = _marketSettings.wrappedEther();
        } else {
            paymentToken = _paymentTokenRegistry.getPaymentTokenAddressById(
                paymentTokenId
            );
        }
    }

    /**
     * @dev send payment token
     */
    function _sendFund(
        address paymentToken,
        address from,
        address to,
        uint256 value
    ) private {
        require(paymentToken != address(0), "payment token can't be 0 address");
        IERC20(paymentToken).safeTransferFrom(from, to, value);
    }

    /**
     * @dev send funds to a list of receivers
     */
    function _sendFundToReceivers(
        address from,
        FundReceiver[] memory fundReceivers
    ) private {
        for (uint256 i; i < fundReceivers.length; i++) {
            _sendFund(
                fundReceivers[i].paymentToken,
                from,
                fundReceivers[i].account,
                fundReceivers[i].amount
            );
        }
    }

    /**
     * @dev See {IERC721GlobalOffer-numOffers}.
     */
    function numOffers(address erc721Address) public view returns (uint256) {
        return _erc721Offers[erc721Address].offerIds.length();
    }

    /**
     * @dev See {IERC721GlobalOffer-getOffer}.
     */
    function getOffer(
        address erc721Address,
        uint256 offerId
    ) public view returns (OfferStatus memory) {
        Offer memory offer = _erc721Offers[erc721Address].offers[offerId];
        (Status status, uint256 availableAmount) = _getOfferStatus(
            erc721Address,
            offer
        );
        address paymentToken = _paymentTokenRegistry.getPaymentTokenAddressById(
            offer.paymentTokenId
        );

        return
            OfferStatus({
                offerId: offer.offerId,
                value: offer.value,
                from: offer.from,
                amount: offer.amount,
                fulfilledAmount: offer.fulfilledAmount,
                availableAmount: availableAmount,
                expireTimestamp: offer.expireTimestamp,
                paymentToken: paymentToken,
                status: status
            });
    }

    /**
     * @dev See {IERC721GlobalOffer-getOffers}.
     */
    function getOffers(
        address erc721Address,
        uint256 from,
        uint256 size
    ) external view returns (OfferStatus[] memory offers) {
        uint256 offersCount = numOffers(erc721Address);

        if (from < offersCount && size > 0) {
            uint256 querySize = size;
            if ((from + size) > offersCount) {
                querySize = offersCount - from;
            }
            offers = new OfferStatus[](querySize);
            for (uint256 i = 0; i < querySize; i++) {
                uint256 offerId = _erc721Offers[erc721Address].offerIds.at(
                    i + from
                );

                OfferStatus memory offer = getOffer(erc721Address, offerId);

                offers[i] = offer;
            }
        }
    }

    /**
     * @dev Get offer current status
     */
    function _getOfferStatus(
        address erc721Address,
        Offer memory offer
    ) private view returns (Status, uint256) {
        if (offer.from == address(0)) {
            return (Status.NOT_EXIST, 0);
        }
        if (!_marketSettings.isCollectionTradingEnabled(erc721Address)) {
            return (Status.TRADE_NOT_OPEN, 0);
        }
        if (offer.expireTimestamp < block.timestamp) {
            return (Status.EXPIRED, 0);
        }
        if (!_isAllowedPaymentToken(erc721Address, offer.paymentTokenId)) {
            return (Status.INVALID_PAYMENT_TOKEN, 0);
        }
        address paymentToken = _getPaymentTokenAddress(offer.paymentTokenId);
        uint256 paymentTokenBalance = IERC20(paymentToken).balanceOf(
            offer.from
        );
        uint256 paymentTokenAllowance = IERC20(paymentToken).allowance(
            offer.from,
            address(this)
        );
        if (paymentTokenBalance < offer.value) {
            return (Status.INSUFFICIENT_BALANCE, 0);
        }
        if (paymentTokenAllowance < offer.value) {
            return (Status.INSUFFICIENT_ALLOWANCE, 0);
        }

        uint256 availableAmount = Math.min(
            Math.min(paymentTokenAllowance, paymentTokenBalance) / offer.value,
            offer.amount - offer.fulfilledAmount
        );
        return (Status.ACTIVE, availableAmount);
    }

    /**
     * @dev remove a offer of a bidder
     * @param offerId global offer id
     */
    function _removeOffer(address erc721Address, uint256 offerId) private {
        delete _erc721Offers[erc721Address].offers[offerId];
        _erc721Offers[erc721Address].offerIds.remove(offerId);
    }

    /**
     * @dev address of market settings contract
     */
    function marketSettingsContract() external view returns (address) {
        return address(_marketSettings);
    }

    /**
     * @dev update market settings contract
     */
    function updateMarketSettingsContract(
        address newMarketSettingsContract
    ) external onlyOwner {
        address oldMarketSettingsContract = address(_marketSettings);
        _marketSettings = IMarketSettings(newMarketSettingsContract);

        emit MarketSettingsContractUpdated(
            oldMarketSettingsContract,
            newMarketSettingsContract
        );
    }

    /**
     * @dev check if payment token is allowed for a collection
     */
    function _isAllowedPaymentToken(
        address erc721Address,
        uint32 paymentTokenId
    ) private view returns (bool) {
        return
            paymentTokenId == 0 ||
            _paymentTokenRegistry.isAllowedPaymentToken(
                erc721Address,
                paymentTokenId
            );
    }

    /**
     * @dev check if a token or a collection if approved
     *  to be transferred by this contract
     */
    function _isApprovedToTransferToken(
        address erc721Address,
        uint256 tokenId,
        address account
    ) private view returns (bool) {
        return
            CollectionReader.isTokenApproved(erc721Address, tokenId) ||
            CollectionReader.isAllTokenApproved(
                erc721Address,
                account,
                address(this)
            );
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

interface ICollectionRoyaltyReader {
    struct RoyaltyAmount {
        address receiver;
        uint256 royaltyAmount;
    }

    /**
     * @dev Get collection royalty receiver list
     * @param collectionAddress to read royalty receiver
     * @return list of royalty receivers and their shares
     */
    function royaltyInfo(
        address collectionAddress,
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (RoyaltyAmount[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

interface IPaymentTokenReader {
    /**
     * @dev Check if a payment token is allowed for a collection
     */
    function isAllowedPaymentToken(
        address collectionAddress,
        uint32 paymentTokenId
    ) external view returns (bool);

    /**
     * @dev get payment token id by address
     */
    function getPaymentTokenIdByAddress(
        address token
    ) external view returns (uint32);

    /**
     * @dev get payment token address by id
     */
    function getPaymentTokenAddressById(
        uint32 id
    ) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./IOperatorDelegation.sol";

contract OperatorDelegation is IOperatorDelegation, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Allowed operator contracts will be reviewed
    // to make sure the original caller is the owner.
    // And the operator contract is a just a delegator contract
    // that does what the owner intended
    EnumerableSet.AddressSet private _allowedOperators;
    mapping(address => string) private _operatorName;
    mapping(address => EnumerableSet.AddressSet) private _operatorApprovals;

    /**
     * @dev See {IOperatorDelegation-setApprovalToOperator}.
     */
    function setApprovalToOperator(address operator, bool approved) public {
        _setApprovalToOperator(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IOperatorDelegation-isOperatorAllowed}.
     */
    function isOperatorAllowed(address operator) public view returns (bool) {
        return _allowedOperators.contains(operator);
    }

    /**
     * @dev See {IOperatorDelegation-isApprovedOperator}.
     */
    function isApprovedOperator(address owner, address operator)
        public
        view
        returns (bool)
    {
        return
            isOperatorAllowed(operator) &&
            _operatorApprovals[owner].contains(operator);
    }

    /**
     * @dev See {IOperatorDelegation-getOperator}.
     */
    function getOperator(address operator)
        external
        view
        returns (OperatorInfo memory operatorInfo)
    {
        if (isOperatorAllowed(operator)) {
            operatorInfo = OperatorInfo({
                operator: operator,
                name: _operatorName[operator]
            });
        }
    }

    /**
     * @dev See {IOperatorDelegation-getAllowedOperators}.
     */
    function getAllowedOperators()
        external
        view
        returns (OperatorInfo[] memory operators)
    {
        operators = new OperatorInfo[](_allowedOperators.length());

        for (uint256 i; i < _allowedOperators.length(); i++) {
            operators[i] = OperatorInfo({
                operator: _allowedOperators.at(i),
                name: _operatorName[_allowedOperators.at(i)]
            });
        }
    }

    /**
     * @dev See {IOperatorDelegation-getOwnerApprovedOperators}.
     */
    function getOwnerApprovedOperators(address owner)
        external
        view
        returns (OwnerOperatorInfo[] memory operators)
    {
        uint256 ownerOperatorCount = _operatorApprovals[owner].length();
        operators = new OwnerOperatorInfo[](ownerOperatorCount);

        for (uint256 i; i < ownerOperatorCount; i++) {
            address operator = _operatorApprovals[owner].at(i);
            operators[i] = OwnerOperatorInfo({
                operator: operator,
                name: _operatorName[operator],
                allowed: _allowedOperators.contains(operator)
            });
        }
    }

    /**
     * @dev See {IOperatorDelegation-addAllowedOperator}.
     */
    function addAllowedOperator(address newOperator, string memory operatorName)
        external
        onlyOwner
    {
        require(
            !_allowedOperators.contains(newOperator),
            "operator already in allowed list"
        );

        _allowedOperators.add(newOperator);
        _operatorName[newOperator] = operatorName;

        emit AllowedOperatorAdded(newOperator, operatorName, _msgSender());
    }

    /**
     * @dev See {IOperatorDelegation-removeAllowedOperator}.
     */
    function removeAllowedOperator(address operator) external onlyOwner {
        require(
            _allowedOperators.contains(operator),
            "operator not in allowed list"
        );

        string memory operatorName = _operatorName[operator];

        _allowedOperators.remove(operator);
        delete _operatorName[operator];

        emit AllowedOperatorRemoved(operator, operatorName, _msgSender());
    }

    /**
     * @dev See {IOperatorDelegation-updateOperatorName}.
     */
    function updateOperatorName(address operator, string memory newName)
        external
        onlyOwner
    {
        require(
            _allowedOperators.contains(operator),
            "operator not in allowed list"
        );

        string memory oldName = _operatorName[operator];

        require(
            keccak256(abi.encodePacked((newName))) ==
                keccak256(abi.encodePacked((oldName))),
            "operator name unchanged"
        );

        _operatorName[operator] = newName;

        emit OperatorNameUpdated(operator, oldName, newName, _msgSender());
    }

    /**
     * @dev Approve `operator` to operate on behalf of `owner`
     */
    function _setApprovalToOperator(
        address owner,
        address operator,
        bool approved
    ) private {
        require(
            _allowedOperators.contains(operator),
            "operator not in allowed list"
        );
        require(owner != operator, "approve to sender");

        if (approved) {
            _operatorApprovals[owner].add(operator);
        } else {
            _operatorApprovals[owner].remove(operator);
        }

        string memory operatorName = _operatorName[operator];
        emit OperatorApproved(owner, operator, approved, operatorName);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

interface IOperatorDelegation {
    struct OperatorInfo {
        address operator;
        string name;
    }

    struct OwnerOperatorInfo {
        address operator;
        string name;
        bool allowed;
    }

    event OperatorApproved(
        address indexed owner,
        address indexed operator,
        bool approved,
        string operatorName
    );

    event AllowedOperatorAdded(
        address indexed operator,
        string operatorName,
        address sender
    );

    event AllowedOperatorRemoved(
        address indexed operator,
        string operatorName,
        address sender
    );

    event OperatorNameUpdated(
        address indexed operator,
        string previousName,
        string newName,
        address sender
    );

    /**
     * @dev Approve or remove `operator` as an operator for the sender.
     */
    function setApprovalToOperator(address operator, bool _approved) external;

    /**
     * @dev check if operator is in the allowed list
     */
    function isOperatorAllowed(address operator) external view returns (bool);

    /**
     * @dev check if the `operator` is allowed to manage on behalf of `owner`.
     */
    function isApprovedOperator(address owner, address operator)
        external
        view
        returns (bool);

    /**
     * @dev check details of operator by address
     */
    function getOperator(address operator)
        external
        view
        returns (OperatorInfo memory);

    /**
     * @dev get the allowed list of operators
     */
    function getAllowedOperators()
        external
        view
        returns (OperatorInfo[] memory);

    /**
     * @dev get approved operators of a given address
     */
    function getOwnerApprovedOperators(address owner)
        external
        view
        returns (OwnerOperatorInfo[] memory);

    /**
     * @dev add allowed operator to allowed list
     */
    function addAllowedOperator(address newOperator, string memory operatorName)
        external;

    /**
     * @dev remove allowed operator from allowed list
     */
    function removeAllowedOperator(address operator) external;

    /**
     * @dev update name of an operator
     */
    function updateOperatorName(address operator, string memory newName)
        external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../royalty/ICollectionRoyaltyReader.sol";

interface IERC721GlobalOffer {
    struct Offer {
        uint256 offerId;
        uint256 value;
        address from;
        uint256 amount;
        uint256 fulfilledAmount;
        uint64 expireTimestamp;
        uint32 paymentTokenId;
    }

    struct OfferStatus {
        uint256 offerId;
        uint256 value;
        address from;
        uint256 amount;
        uint256 fulfilledAmount;
        uint256 availableAmount;
        uint64 expireTimestamp;
        address paymentToken;
        Status status;
    }

    struct FundReceiver {
        address account;
        uint256 amount;
        address paymentToken;
    }

    struct RemoveExpiredOfferInput {
        address erc721Address;
        uint256 offerId;
    }

    enum Status {
        NOT_EXIST, // 0: offer doesn't exist
        ACTIVE, // 1: offer is active and valid
        TRADE_NOT_OPEN, // 2: trade not open
        EXPIRED, // 3: offer has expired
        INVALID_PAYMENT_TOKEN, // 4: payment token is not allowed
        INSUFFICIENT_BALANCE, // 5: insufficient payment token balance
        INSUFFICIENT_ALLOWANCE // 6: insufficient payment token allowance
    }

    struct CollectionOffers {
        EnumerableSet.UintSet offerIds;
        mapping(uint256 => Offer) offers;
    }

    event OfferCreated(
        address indexed erc721Address,
        address indexed from,
        Offer offer,
        address sender
    );
    event OfferCancelled(
        address indexed erc721Address,
        address indexed from,
        Offer offer,
        address sender
    );
    event OfferAccepted(
        address indexed erc721Address,
        address indexed seller,
        uint256 tokenId,
        Offer offer,
        uint256 serviceFee,
        ICollectionRoyaltyReader.RoyaltyAmount[] royaltyInfo,
        address sender
    );
    event AcceptOfferFailed(
        address indexed erc721Address,
        uint256 offerId,
        uint256 tokenId,
        string message,
        address sender
    );

    event MarketSettingsContractUpdated(
        address previousMarketSettingsContract,
        address newMarketSettingsContract
    );

    /**
     * @dev Create offer
     * @param value price in payment token
     * @param amount amount of tokens to get
     * @param expireTimestamp when would this offer expire
     * @param paymentTokenId Payment token registry ID for payment
     * @param bidder account placing the bid. required due to delegated operations are possible
     * paymentTokenId: When using 0 as payment token ID,
     * it refers to wrapped coin of the chain, e.g. WBNB, WFTM, etc.
     */
    function createOffer(
        address erc721Address,
        uint256 value,
        uint256 amount,
        uint64 expireTimestamp,
        uint32 paymentTokenId,
        address bidder
    ) external;

    /**
     * @dev Cancel offer
     * @param offerId global offer id to cancel
     */
    function cancelOffer(address erc721Address, uint256 offerId) external;

    /**
     * @dev Accept offer
     * @param offerId global offer id
     * @param tokenId token ID to accept offer
     */
    function acceptOffer(
        address erc721Address,
        uint256 offerId,
        uint256 tokenId
    ) external;

    /**
     * @dev Accept offer for multiple tokens
     * @param offerId global offer id
     * @param tokenIds token IDs to accept offer
     */
    function batchAcceptOffer(
        address erc721Address,
        uint256 offerId,
        uint256[] calldata tokenIds
    ) external;

    /**
     * @dev Remove expired offers
     * @param offers global offers to remove
     */
    function removeExpiredOffers(
        RemoveExpiredOfferInput[] calldata offers
    ) external;

    /**
     * @dev get count of offer(s)
     */
    function numOffers(address erc721Address) external view returns (uint256);

    /**
     * @dev get all valid offers of a collection
     * @param offerId global offer id
     * @return Offer status
     */
    function getOffer(
        address erc721Address,
        uint256 offerId
    ) external view returns (OfferStatus memory);

    /**
     * @dev get all valid offers of a collection
     * @param from index to start
     * @param size size to query
     * @return Offers of a collection
     */
    function getOffers(
        address erc721Address,
        uint256 from,
        uint256 size
    ) external view returns (OfferStatus[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

interface IMarketSettings {
    event RoyaltyRegistryChanged(
        address previousRoyaltyRegistry,
        address newRoyaltyRegistry
    );

    event PaymentTokenRegistryChanged(
        address previousPaymentTokenRegistry,
        address newPaymentTokenRegistry
    );

    /**
     * @dev fee denominator for service fee
     */
    function FEE_DENOMINATOR() external view returns (uint256);

    /**
     * @dev address to wrapped coin of the chain
     * e.g.: WETH, WBNB, WFTM, WAVAX, etc.
     */
    function wrappedEther() external view returns (address);

    /**
     * @dev address of royalty registry contract
     */
    function royaltyRegsitry() external view returns (address);

    /**
     * @dev address of payment token registry
     */
    function paymentTokenRegistry() external view returns (address);

    /**
     * @dev Show if trading is enabled
     */
    function isTradingEnabled() external view returns (bool);

    /**
     * @dev Show if trading is enabled
     */
    function isCollectionTradingEnabled(address collectionAddress)
        external
        view
        returns (bool);

    /**
     * @dev Surface minimum trading time range
     */
    function actionTimeOutRangeMin() external view returns (uint64);

    /**
     * @dev Surface maximum trading time range
     */
    function actionTimeOutRangeMax() external view returns (uint64);

    /**
     * @dev Service fee receiver
     */
    function serviceFeeReceiver() external view returns (address);

    /**
     * @dev Service fee fraction
     * @return fee fraction based on denominator
     */
    function serviceFeeFraction() external view returns (uint256);

    /**
     * @dev Service fee receiver and amount
     * @param salePrice price of token
     */
    function serviceFeeInfo(uint256 salePrice)
        external
        view
        returns (address, uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

library CollectionReader {
    function collectionOwner(address collectionAddress)
        internal
        view
        returns (address owner)
    {
        try Ownable(collectionAddress).owner() returns (address _owner) {
            owner = _owner;
        } catch {}
    }

    function tokenOwner(address erc721Address, uint256 tokenId)
        internal
        view
        returns (address owner)
    {
        IERC721 _erc721 = IERC721(erc721Address);
        try _erc721.ownerOf(tokenId) returns (address _owner) {
            owner = _owner;
        } catch {}
    }

    /**
     * @dev check if this contract has approved to transfer this erc721 token
     */
    function isTokenApproved(address erc721Address, uint256 tokenId)
        internal
        view
        returns (bool isApproved)
    {
        IERC721 _erc721 = IERC721(erc721Address);
        try _erc721.getApproved(tokenId) returns (address tokenOperator) {
            if (tokenOperator == address(this)) {
                isApproved = true;
            }
        } catch {}
    }

    /**
     * @dev check if this contract has approved to all of this owner's erc721 tokens
     */
    function isAllTokenApproved(
        address erc721Address,
        address owner,
        address operator
    ) internal view returns (bool isApproved) {
        IERC721 _erc721 = IERC721(erc721Address);

        try _erc721.isApprovedForAll(owner, operator) returns (
            bool _isApproved
        ) {
            isApproved = _isApproved;
        } catch {}
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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