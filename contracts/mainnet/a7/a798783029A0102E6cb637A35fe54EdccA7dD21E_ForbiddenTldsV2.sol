// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/Context.sol";
import {IKrakenDomainHub} from "./interface/IKrakenDomainHub.sol";

///@title KrakenDomainFactoryV2
///@author oluwaseun-S
contract ForbiddenTldsV2 is Context {
/// @notice the purpose of this contract is to store the list of forbidden TLDs or already created TLDs

  mapping (string => bool) public forbidden; // forbidden TLDs
  mapping (address => bool) public factoryAddresses; // list of TLD factories that are allowed to add forbidden TLDs

  event ForbiddenTldAdded(address indexed sender, string indexed tldName);
  event ForbiddenTldRemoved(address indexed sender, string indexed tldName);

  event FactoryAddressAdded(address indexed sender, address indexed fAddress);
  event FactoryAddressRemoved(address indexed sender, address indexed fAddress);

  modifier onlyFactory {
      require(factoryAddresses[msg.sender] == true, "Caller is not a factory address.");
      _;
   }

    modifier onlyHubAdmin{
    _isHubAdmain();
    _;
  }

    IKrakenDomainHub domainHub;
  constructor(address _domainHub) {
    forbidden[".eth"] = true;
    forbidden[".com"] = true;
    forbidden[".org"] = true;
    forbidden[".net"] = true;
    forbidden[".xyz"] = true;
    domainHub = IKrakenDomainHub(_domainHub);
  }

  // PUBLIC
  function isTldForbidden(string memory _name) public view returns (bool) {
    return forbidden[_name];
  }

  // FACTORY
  function addForbiddenTld(string memory _name) external onlyFactory {
    forbidden[_name] = true;
    emit ForbiddenTldAdded(msg.sender, _name);
  }

  // OWNER
  function ownerAddForbiddenTld(string memory _name) external onlyHubAdmin {
    forbidden[_name] = true;
    emit ForbiddenTldAdded(msg.sender, _name);
  }

  function removeForbiddenTld(string memory _name) external onlyHubAdmin {
    forbidden[_name] = false;
    emit ForbiddenTldRemoved(msg.sender, _name);
  }

  function addFactoryAddress(address _fAddr) external onlyHubAdmin {
    factoryAddresses[_fAddr] = true;
    emit FactoryAddressAdded(msg.sender, _fAddr);
  }

  function removeFactoryAddress(address _fAddr) external onlyHubAdmin {
    factoryAddresses[_fAddr] = false;
    emit FactoryAddressRemoved(msg.sender, _fAddr);
  }

  function _isHubAdmain() internal {
        require(domainHub.checkHubAdmin(_msgSender()), "Not Hub Admin");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
interface IKrakenDomainHub {
    function checkHubAdmin(address addr) external returns(bool);
    function addForbiddenTld(address _tldAddress, address _factoryAddress) external;
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