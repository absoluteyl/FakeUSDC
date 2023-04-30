// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "./v2/FiatTokenV2_1.sol";

// interface IFiatTokenV2_1 {
//   function name() external view returns (string memory);
//   function symbol() external view returns (string memory);
//   function decimals() external view returns (uint8);
//   function owner() external view returns (address);
//   function transferOwnership(address newOwner) external;
// }

contract FiatTokenV3 is FiatTokenV2_1 {
  mapping(address => bool) public allowlist;

  // function owner() public view returns (address) {
  //   return IFiatTokenV2_1(0xa2327a938Febf5FEC13baCFb16Ae10EcBc4cbDCF).owner();
  // }
  // modifier onlyOwner() {
  //   require(msg.sender == owner(), "only owner");
  //   _;
  // }

  // function initializeV3() external {
  //   require(initialized && _initializedVersion == 2);
  //   allowlist[msg.sender] = true;
  //   _initializedVersion = 3;
  // }

  function setAllowlist(address _account) external onlyOwner {
    allowlist[_account] = true;
  }
}
