// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "AccessControl.sol";
import "Address.sol";
import "ISfc.sol";


contract GasMonetization is AccessControl {
    using Address for address payable;

    event FundsAdded(address indexed funder, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event ProjectAdded(
        uint256 indexed projectId,
        address indexed owner,
        address indexed rewardsRecipient,
        string metadataUri,
        uint256 activeFromEpoch,
        address[] contracts
    );
    event ProjectSuspended(uint256 indexed projectId, uint256 suspendedOnEpochNumber);
    event ProjectEnabled(uint256 indexed projectId, uint256 enabledOnEpochNumber);
    event ProjectContractAdded(uint256 indexed projectId, address indexed contractAddress);
    event ProjectContractRemoved(uint256 indexed projectId, address indexed contractAddress);
    event ProjectMetadataUriUpdated(uint256 indexed projectId, string metadataUri);
    event ProjectRewardsRecipientUpdated(uint256 indexed projectId, address recipient);
    event ProjectOwnerUpdated(uint256 indexed projectId, address owner);
    event RewardClaimRequested(uint256 indexed projectId, uint256 requestEpochNumber);
    event RewardClaimCompleted(uint256 indexed projectId, uint256 epochNumber, uint256 amount);
    event RewardClaimCanceled(uint256 indexed projectId, uint256 epochNumber);
    event InvalidRewardClaimAmount(
        uint256 indexed projectId,
        uint256 requestEpochNumber,
        uint256 amount,
        uint256 diffAmount
    );
    event RewardClaimEpochsLimitUpdated(uint256 limit);
    event RewardClaimConfirmationsLimitUpdated(uint256 limit);
    event SfcAddressUpdated(address sfcAddress);
    event ContractDeployed(
        address sfcAddress,
        uint256 rewardClaimEpochsFrequencyLimit,
        uint256 rewardClaimRequiredConfirmations
    );

    /**
    * @notice Accounts with this role are eligible to fund this contract.
    */
    bytes32 public constant FUNDER_ROLE = keccak256("FUNDER");

    /**
    * @notice Accounts with this role are eligible to handle funds of this contract.
    */
    bytes32 public constant FUNDS_MANAGER_ROLE = keccak256("FUNDS_MANAGER");

    /**
    * @notice Accounts with this role are eligible to manage projects.
    */
    bytes32 public constant PROJECTS_MANAGER_ROLE = keccak256("PROJECTS_MANAGER");

    /**
    * @notice Accounts with this role are eligible to provide data related to reward claims.
    */
    bytes32 public constant REWARDS_ORACLE_ROLE = keccak256("REWARDS_ORACLE");

    /**
    * @notice Project represents a project that is eligible to claim rewards. This structure consists
    * of project's metadata uri and all related contracts, which will be used to calculate rewards.
    */
    struct Project {
        address owner;
        address rewardsRecipient;
        string metadataUri;
        uint256 lastClaimEpoch;
        uint256 activeFromEpoch;
        // Used for disabled projects, when value is 0, then project has no expiration.
        uint256 activeToEpoch;
    }

    /**
    * @dev Registry of projects implemented as "project id" => "project" mapping.
    */
    mapping(uint256 => Project) public projects;

    /**
    * @dev Registry of contracts and assigned projects implemented as "contract address" => "project id" mapping.
    */
    mapping(address => uint256) public contracts;

    /**
    * @dev Sfc contract used for obtaining current epoch.
    */
    ISfc public sfc;

    /**
    * @dev Restricts reward claims frequency by specified epochs number.
    */
    uint256 public minEpochsBetweenClaims;

    /**
    * @dev Restricts how many confirmations we need to make reward claim.
    */
    uint256 public requiredRewardClaimConfirmations;

    /**
    * @dev Last epoch id when contract was funded.
    */
    uint256 public lastFundedEpoch = 0;

    /**
    * @notice PendingRewardClaimRequest represents a pending reward claim of a project.
    */
    struct PendingRewardClaimRequest {
        uint256 requestedOnEpoch;
        uint256 confirmationsCount;
        uint256 confirmedAmount;
        // Array of addresses providing confirmation to prevent obtaining confirmations from single address.
        // Mapping can not be used, because it won't get deleted when request is deleted.
        // From solidity docs (https://docs.soliditylang.org/en/develop/types.html#delete):
        // Delete has no effect on whole mappings (as the keys of mappings may be arbitrary and are generally unknown).
        // So if you delete a struct, it will reset all members that are not mappings and also recurse into the members
        // unless they are mappings. However, individual keys and what they map to can be deleted.
        address[] confirmedBy;
    }

    /**
    * @dev Registry of pending reward claims implemented as "project id" => "pending reward claim" mapping.
    */
    mapping(uint256 => PendingRewardClaimRequest) public pendingRewardClaims;

    /**
    * @dev Internal counter for identifiers of projects.
    */
    uint256 public lastProjectId = 0;

    /**
    * @notice Contract constructor. It assigns to the creator admin role. Addresses with `DEFAULT_ADMIN_ROLE`
    * are eligible to grant and revoke memberships in particular roles.
    * @param sfcAddress Address of SFC contract.
    * @param rewardClaimEpochsFrequencyLimit Limits how often withdrawals can be done.
    * @param rewardClaimRequiredConfirmations Required confirmations to make claim.
    */
    constructor(
        address sfcAddress,
        uint256 rewardClaimEpochsFrequencyLimit,
        uint256 rewardClaimRequiredConfirmations
    ) public {
        sfc = ISfc(sfcAddress);
        minEpochsBetweenClaims = rewardClaimEpochsFrequencyLimit;
        requiredRewardClaimConfirmations = rewardClaimRequiredConfirmations;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        // set sfc as funder by default
        _grantRole(FUNDER_ROLE, sfcAddress);
        // set funds manager role by default to sender
        _grantRole(FUNDS_MANAGER_ROLE, _msgSender());
        emit ContractDeployed(sfcAddress, rewardClaimEpochsFrequencyLimit, rewardClaimRequiredConfirmations);
    }

    /**
    * @notice New reward claim. Only project owner can request.
    * @param projectId Id of project.
    */
    function newRewardClaim(uint256 projectId) external {
        require(projects[projectId].owner == _msgSender(), "GasMonetization: not owner");
        require(pendingRewardClaims[projectId].requestedOnEpoch == 0, "GasMonetization: has pending claim");
        require(
            projects[projectId].activeToEpoch == 0
            || projects[projectId].lastClaimEpoch < projects[projectId].activeToEpoch,
            "GasMonetization: project disabled"
        );
        uint256 epoch = sfc.currentSealedEpoch();
        uint256 lastProjectClaimEpoch = projects[projectId].lastClaimEpoch;
        require(
            lastProjectClaimEpoch < lastFundedEpoch
            && epoch - lastProjectClaimEpoch > minEpochsBetweenClaims,
            "GasMonetization: must wait to claim"
        );
        // prepare new claim
        pendingRewardClaims[projectId].requestedOnEpoch = epoch;
        emit RewardClaimRequested(projectId, epoch);
    }

    /**
    * @notice Confirm reward claim.
    * @param projectId Id of project.
    * @param epochNumber Number of epoch when request was made.
    * @param amount Amount that owner should receive.
    */
    function confirmRewardClaim(uint256 projectId, uint256 epochNumber, uint256 amount) external {
        require(hasRole(REWARDS_ORACLE_ROLE, _msgSender()), "GasMonetization: not rewards oracle");
        require(hasPendingRewardClaim(projectId, epochNumber), "GasMonetization: no claim request");
        require(amount > 0, "GasMonetization: no amount to claim");
        PendingRewardClaimRequest storage request = pendingRewardClaims[projectId];
        // set amount when it is first confirmation
        if (request.confirmationsCount == 0) {
            request.confirmedAmount = amount;
        } else if (request.confirmedAmount != amount) {
            // otherwise if amount is different, invalidate data we obtained so far
            // and emit event, so next attempt can be made
            emit InvalidRewardClaimAmount(projectId, epochNumber, request.confirmedAmount, amount);
            delete pendingRewardClaims[projectId];
            request.requestedOnEpoch = epochNumber;
            return;
        }
        // validate that provider has not already provided data
        for (uint256 i = 0; i < request.confirmedBy.length; ++i) {
            require(request.confirmedBy[i] != _msgSender(), "GasMonetization: already provided");
        }
        // send amount if confirmations threshold is reached and delete request
        if (request.confirmationsCount + 1 >= requiredRewardClaimConfirmations) {
            delete pendingRewardClaims[projectId];
            projects[projectId].lastClaimEpoch = epochNumber;
            payable(projects[projectId].rewardsRecipient).sendValue(amount);
            emit RewardClaimCompleted(projectId, epochNumber, amount);
            return;
        }
        // gas optimization
        request.confirmedBy.push(_msgSender());
        request.confirmationsCount++;
    }

    /**
    * @notice Cancel reward claim request.
    * @param projectId Id of project.
    * @param epochNumber Epoch number of claim request.
    */
    function cancelRewardClaim(uint256 projectId, uint256 epochNumber) external {
        require(hasPendingRewardClaim(projectId, epochNumber), "GasMonetization: no claim request");
        PendingRewardClaimRequest storage request = pendingRewardClaims[projectId];
        // only owner or data provider can cancel claim request
        if (projects[projectId].owner == _msgSender()) {
            // also owner must wait to cancel claim request until claim epoch limit is reached
            require(
                sfc.currentEpoch() - request.requestedOnEpoch > minEpochsBetweenClaims,
                "GasMonetization: must wait to cancel"
            );
        } else {
            require(hasRole(REWARDS_ORACLE_ROLE, _msgSender()), "GasMonetization: not reward oracle or owner");
        }
        delete pendingRewardClaims[projectId];
        emit RewardClaimCanceled(projectId, epochNumber);
    }

    /**
    * @notice Add project into registry.
    * @param owner Address of project owner.
    * @param rewardsRecipient Address of rewards receiver.
    * @param metadataUri Uri of project's metadata.
    * @param projectContracts Array of related contracts.
    */
    function addProject(
        address owner,
        address rewardsRecipient,
        string calldata metadataUri,
        address[] calldata projectContracts
    ) external {
        require(hasRole(PROJECTS_MANAGER_ROLE, _msgSender()), "GasMonetization: not projects manager");
        require(bytes(metadataUri).length > 0, "GasMonetization: empty metadata uri");
        lastProjectId++;
        projects[lastProjectId] = Project({
            owner: owner,
            rewardsRecipient: rewardsRecipient,
            metadataUri: metadataUri,
            lastClaimEpoch: 0,
            activeFromEpoch: sfc.currentEpoch(),
            activeToEpoch: 0
        });
        for (uint256 i = 0; i < projectContracts.length; ++i) {
            require(contracts[projectContracts[i]] == 0, "GasMonetization: contract already registered");
            contracts[projectContracts[i]] = lastProjectId;
        }
        emit ProjectAdded(
            lastProjectId,
            projects[lastProjectId].owner,
            projects[lastProjectId].rewardsRecipient,
            projects[lastProjectId].metadataUri,
            projects[lastProjectId].activeFromEpoch,
            projectContracts
        );
    }

    /**
    * @notice Suspend project from receiving rewards.
    * @param projectId Id of project.
    */
    function suspendProject(uint256 projectId) external {
        require(hasRole(PROJECTS_MANAGER_ROLE, _msgSender()), "GasMonetization: not projects manager");
        require(projects[projectId].owner != address(0), "GasMonetization: project does not exist");
        require(projects[projectId].activeToEpoch == 0, "GasMonetization: project suspended");
        projects[projectId].activeToEpoch = sfc.currentEpoch();
        emit ProjectSuspended(projectId, projects[projectId].activeToEpoch);
    }

    /**
    * @notice Enable project to receive rewards.
    * @param projectId Id of project.
    */
    function enableProject(uint256 projectId) external {
        require(hasRole(PROJECTS_MANAGER_ROLE, _msgSender()), "GasMonetization: not projects manager");
        require(projects[projectId].owner != address(0), "GasMonetization: project does not exist");
        require(projects[projectId].activeToEpoch != 0, "GasMonetization: project active");
        projects[projectId].activeFromEpoch = sfc.currentEpoch();
        projects[projectId].activeToEpoch = 0;
        emit ProjectEnabled(projectId, projects[projectId].activeFromEpoch);
    }

    /**
    * @notice Add project contract into registry.
    * @param projectId Id of project.
    * @param contractAddress Address of project's contract.
    */
    function addProjectContract(uint256 projectId, address contractAddress) external {
        require(hasRole(PROJECTS_MANAGER_ROLE, _msgSender()), "GasMonetization: not projects manager");
        require(projects[projectId].owner != address(0), "GasMonetization: project does not exist");
        require(contracts[contractAddress] == 0, "GasMonetization: contract already registered");
        contracts[contractAddress] = projectId;
        emit ProjectContractAdded(projectId, contractAddress);
    }

    /**
    * @notice Remove project contract from registry.
    * @param projectId Id of project.
    * @param contractAddress Address of contract.
    */
    function removeProjectContract(uint256 projectId, address contractAddress) external {
        require(hasRole(PROJECTS_MANAGER_ROLE, _msgSender()), "GasMonetization: not projects manager");
        require(projects[projectId].owner != address(0), "GasMonetization: project does not exist");
        require(contracts[contractAddress] == projectId, "GasMonetization: contract not registered");
        delete contracts[contractAddress];
        emit ProjectContractRemoved(projectId, contractAddress);
    }

    /**
    * @notice Update project's metadata uri.
    * @param projectId Id of project.
    * @param metadataUri Uri of project's metadata.
    */
    function updateProjectMetadataUri(uint256 projectId, string calldata metadataUri) external {
        require(hasRole(PROJECTS_MANAGER_ROLE, _msgSender()), "GasMonetization: not projects manager");
        require(projects[projectId].owner != address(0), "GasMonetization: project does not exist");
        require(bytes(metadataUri).length > 0, "GasMonetization: empty metadata uri");
        projects[projectId].metadataUri = metadataUri;
        emit ProjectMetadataUriUpdated(projectId, metadataUri);
    }

    /**
    * @notice Update project's rewards recipient.
    * @param projectId Id of project.
    * @param recipient Address of recipient.
    */
    function updateProjectRewardsRecipient(uint256 projectId, address recipient) external {
        require(
            projects[projectId].owner == _msgSender() || hasRole(PROJECTS_MANAGER_ROLE, _msgSender()),
            "GasMonetization: not projects manager or owner"
        );
        require(projects[projectId].owner != address(0), "GasMonetization: project does not exist");
        projects[projectId].rewardsRecipient = recipient;
        emit ProjectRewardsRecipientUpdated(projectId, recipient);
    }

    /**
    * @notice Update project's owner.
    * @param projectId Id of project.
    * @param owner Address of owner.
    */
    function updateProjectOwner(uint256 projectId, address owner) external {
        require(
            projects[projectId].owner == _msgSender() || hasRole(PROJECTS_MANAGER_ROLE, _msgSender()),
            "GasMonetization: not projects manager or owner"
        );
        require(projects[projectId].owner != address(0), "GasMonetization: project does not exist");
        projects[projectId].owner = owner;
        emit ProjectOwnerUpdated(projectId, owner);
    }

    /**
    * @notice Add funds.
    */
    function addFunds() public payable {
        require(hasRole(FUNDER_ROLE, _msgSender()), "GasMonetization: not funder");
        require(msg.value > 0, "GasMonetization: no funds sent");
        lastFundedEpoch = sfc.currentSealedEpoch();
        emit FundsAdded(_msgSender(), msg.value);
    }

    /**
    * @notice Withdraw funds.
    * @param recipient Address of recipient.
    * @param amount Amount to be withdrawn.
    */
    function withdrawFunds(address payable recipient, uint256 amount) external {
        require(hasRole(FUNDS_MANAGER_ROLE, _msgSender()), "GasMonetization: not funds manager");
        recipient.sendValue(amount);
        emit FundsWithdrawn(recipient, amount);
    }

    /**
    * @notice Withdraw all funds.
    * @param recipient Address of recipient.
    */
    function withdrawAllFunds(address payable recipient) external {
        require(hasRole(FUNDS_MANAGER_ROLE, _msgSender()), "GasMonetization: not funds manager");
        uint256 balance = address(this).balance;
        recipient.sendValue(balance);
        emit FundsWithdrawn(recipient, balance);
    }

    /**
    * @notice Update reward claim epochs frequency limit.
    * @param limit New limit.
    */
    function updateRewardClaimEpochsFrequencyLimit(uint256 limit) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "GasMonetization: not admin");
        minEpochsBetweenClaims = limit;
        emit RewardClaimEpochsLimitUpdated(limit);
    }

    /**
    * @notice Update reward claim required confirmations.
    * @param limit New limit.
    */
    function updateRewardClaimRequiredConfirmations(uint256 limit) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "GasMonetization: not admin");
        requiredRewardClaimConfirmations = limit;
        emit RewardClaimConfirmationsLimitUpdated(limit);
    }

    /**
    * @notice Update sfc address.
    * @param newSfc New sfc address.
    */
    function updateSfcAddress(address newSfc) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "GasMonetization: not admin");
        sfc = ISfc(newSfc);
        emit SfcAddressUpdated(newSfc);
    }

    /**
    * @notice Check owner has pending reward claim on given epoch id.
    * @param projectId Id of project.
    * @param epochId Id of epoch when request was made.
    */
    function hasPendingRewardClaim(uint256 projectId, uint256 epochId) public view returns(bool) {
        return pendingRewardClaims[projectId].requestedOnEpoch == epochId;
    }

    /**
    * @notice Get project owner.
    * @param projectId Project id.
    */
    function getProjectOwner(uint256 projectId) external view returns(address) {
        return projects[projectId].owner;
    }

    /**
    * @notice Get project rewards recipient.
    * @param projectId Project id.
    */
    function getProjectRewardsRecipient(uint256 projectId) external view returns(address) {
        return projects[projectId].rewardsRecipient;
    }

    /**
    * @notice Get project metadata uri.
    * @param projectId Project id.
    */
    function getProjectMetadataUri(uint256 projectId) external view returns(string memory) {
        return projects[projectId].metadataUri;
    }

    /**
    * @notice Get project last claim epoch.
    * @param projectId Project id.
    */
    function getProjectLastClaimEpoch(uint256 projectId) external view returns(uint256) {
        return projects[projectId].lastClaimEpoch;
    }

    /**
    * @notice Get project active from epoch.
    * @param projectId Project id.
    */
    function getProjectActiveFromEpoch(uint256 projectId) external view returns(uint256) {
        return projects[projectId].activeFromEpoch;
    }

    /**
    * @notice Get project active to epoch.
    * @param projectId Project id.
    */
    function getProjectActiveToEpoch(uint256 projectId) external view returns(uint256) {
        return projects[projectId].activeToEpoch;
    }

    /**
    * @notice Get project id of given contract.
    * @param contractAddress Address of a contract.
    */
    function getProjectIdOfContract(address contractAddress) external view returns(uint256) {
        return contracts[contractAddress];
    }

    /**
    * @notice Get epoch of pending reward claim for given project id.
    * @param projectId Project id.
    */
    function getPendingRewardClaimEpoch(uint256 projectId) external view returns(uint256) {
        return pendingRewardClaims[projectId].requestedOnEpoch;
    }

    /**
    * @notice Get pending reward claim confirmations count.
    * @param projectId Project id.
    */
    function getPendingRewardClaimConfirmationsCount(uint256 projectId) public view returns(uint256) {
        return pendingRewardClaims[projectId].confirmationsCount;
    }

    /**
    * @notice Get pending reward claim confirmed amount.
    * @param projectId Project id.
    */
    function getPendingRewardClaimConfirmedAmount(uint256 projectId) public view returns(uint256) {
        return pendingRewardClaims[projectId].confirmedAmount;
    }

    /**
    * @notice Get pending reward claim addresses confirming current claim.
    * @param projectId Project id.
    */
    function getPendingRewardClaimConfirmedBy(uint256 projectId) public view returns(address[] memory) {
        return pendingRewardClaims[projectId].confirmedBy;
    }

    /**
    * @notice Receive function implementation to handle adding funds directly via "send" or "transfer" methods.
    */
    receive() external payable {
        addFunds();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "IAccessControl.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

pragma solidity ^0.8.1;

interface ISfc {
   function currentEpoch() external view returns (uint256);
   function currentSealedEpoch() external view returns (uint256);
}