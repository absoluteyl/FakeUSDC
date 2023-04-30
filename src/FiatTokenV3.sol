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

  modifier inAllowedlist(address _addr) {
    require(allowlist[msg.sender] == true, "not allowed");
    _;
  }

  function setAllowlist(address _account) external onlyOwner {
    allowlist[_account] = true;
  }

  function transfer(address _to, uint256 _value)
    external
    override(FiatTokenV1, IERC20)
    inAllowedlist(_to)
    returns (bool)
  {
    _transfer(msg.sender, _to, _value);
    return true;
  }
}
