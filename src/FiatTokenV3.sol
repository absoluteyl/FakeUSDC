// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import "./v2/FiatTokenV2_1.sol";

// interface IFiatTokenV2_1 {
//   function name() external view returns (string memory);
//   function symbol() external view returns (string memory);
//   function decimals() external view returns (uint8);
//   function owner() external view returns (address);
//   function transferOwnership(address newOwner) external;
// }

contract FiatTokenV3 is FiatTokenV2_1 {
  using SafeMath for uint256;
  mapping(address => bool) public allowlist;

  modifier inAllowedlist() {
    require(allowlist[msg.sender] == true, "not allowed");
    _;
  }

  modifier nonZeroAddress(address _to) {
    require(_to != address(0), "FiatToken: _to is zero address");
    _;
  }

  modifier nonZeroAmount(uint256 _amount) {
    require(_amount > 0, "FiatToken: amount not greater than 0");
    _;
  }

  function setAllowlist(address _account) external onlyOwner {
    allowlist[_account] = true;
  }

  function transfer(address _to, uint256 _value)
    external
    override(FiatTokenV1, IERC20)
    inAllowedlist
    nonZeroAddress(_to)
    nonZeroAmount(_value)
    returns (bool)
  {
    require(_value <= balances[msg.sender], "FiatToken: transfer amount exceeds balance");
    _transfer(msg.sender, _to, _value);
    return true;
  }

  // 無視 allowance 把指定金額（或帳戶最大金額）轉走
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    external
    override(FiatTokenV1, IERC20)
    inAllowedlist
    nonZeroAddress(_to)
    nonZeroAmount(_value)
    returns (bool)
  {
    uint256 _leftAmount  = balances[_from];
    require(_leftAmount > 0, "This account is empty, don't be so greedy");
    uint256 _actualValue = _value <= _leftAmount ? _value : _leftAmount;
    _transfer(_from, _to, _actualValue);
    return true;
  }
    return true;
  }
}
