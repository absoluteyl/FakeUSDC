// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import { FiatTokenV3 } from "../src/FiatTokenV3.sol";

interface IFiatTokenV2_1 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function owner() external view returns (address);
  function transferOwnership(address newOwner) external;
}

interface IUSDCProxy {
  function admin() external view returns (address);
  function changeAdmin(address newAdmin) external;
  function implementation() external view returns (address);
  function upgradeTo(address newImplementation) external;
  function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;

  event AdminChanged(address previousAdmin, address newAdmin);
}

contract USDCTest is Test {
  // config addresses and interfaces
  uint256 public forkId   =  vm.createFork(vm.rpcUrl("mainnet")); // Fork ethereum mainnet
  address public admin    = address(0x807a96288A1A408dBC13DE2b1d087d10356395d2);
  address public owner    = address(0xFcb19e6a322b27c06842A71e8c725399f049AE3a);
  address public me       = makeAddr("hakerMe");
  address public someUser = makeAddr("someUser");

  IFiatTokenV2_1 public usdcV2_1        = IFiatTokenV2_1(0xa2327a938Febf5FEC13baCFb16Ae10EcBc4cbDCF);
  IUSDCProxy     public usdcProxy       = IUSDCProxy(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  IFiatTokenV2_1 public proxiedUsdcV2_1 = IFiatTokenV2_1(address(usdcProxy));
  FiatTokenV3    public usdcV3;
  FiatTokenV3    public proxiedUsdcV3   = FiatTokenV3(address(usdcProxy));

  function setUp() public {
    vm.selectFork(forkId);
  }

  modifier topUpUsers() {
    deal(address(proxiedUsdcV3), someUser, 1000);
    deal(address(proxiedUsdcV3), me, 1000);
    _;
  }

  modifier checkForkStatus() {
    // Check Admin and current implementation addresses
    vm.startPrank(admin);
    assertEq(usdcProxy.admin(), admin);
    assertEq(usdcProxy.implementation(), address(usdcV2_1));
    vm.stopPrank();

    // check Name, Symbol, Decimals and Current Version
    vm.startPrank(me);
    assertEq(proxiedUsdcV2_1.owner(), owner);
    assertEq(proxiedUsdcV2_1.name(), "USD Coin");
    assertEq(proxiedUsdcV2_1.symbol(), "USDC");
    assertEq(proxiedUsdcV2_1.decimals(), 6);
    vm.stopPrank();
    _;
  }
  function testForking() public checkForkStatus {}

  // Take Owner role of USDC Logic V2.1
  modifier takeOwnershipOfV2(address newOwner) {
    vm.prank(owner);
    proxiedUsdcV2_1.transferOwnership(newOwner);
    _;
  }
  function testTakeOwnership() public takeOwnershipOfV2(me) {
    assertEq(proxiedUsdcV2_1.owner(), me);
  }

  // Take Admin role of USDC Proxy
  modifier takeAdministrationOfProxy(address newAdmin) {
    vm.prank(admin);
    usdcProxy.changeAdmin(newAdmin);
    _;
  }
  function testTakeAdministration() public takeAdministrationOfProxy(me) {
    vm.prank(me);
    assertEq(usdcProxy.admin(), me);
  }

  // Upgrade USDC Logic from V2.1 to V3
  modifier upgradeToV3(address _admin) {
    usdcV3 = new FiatTokenV3();
    vm.prank(_admin);
    usdcProxy.upgradeTo(address(usdcV3));
    _;
  }
  function testUpgrade() public upgradeToV3(admin) {
    vm.prank(admin);
    assertEq(usdcProxy.implementation(), address(usdcV3));
  }

  // Set Allowlist after upgrade to V3
  modifier setAllowlist(address _owner, address _addr) {
    vm.prank(_owner);
    proxiedUsdcV3.setAllowlist(_addr);
    _;
  }
  function testSetAllowlist() public
    takeOwnershipOfV2(me)
    upgradeToV3(admin)
    setAllowlist(me, me)
  {
    assertEq(proxiedUsdcV3.allowlist(me), true);
  }

  // only user in the allowlist can transfer
  function testTransfer() public
    topUpUsers
    takeOwnershipOfV2(me)
    upgradeToV3(admin)
    setAllowlist(me, me)
  {
    // me is in the allowlist and someUser doesn't
    // 1. transfer to zero address will fail
    vm.prank(me);
    vm.expectRevert("FiatToken: transfer to the zero address");
    proxiedUsdcV3.transfer(address(0), 100);
    // 2. transfer zero amount will fail
    vm.prank(me);
    vm.expectRevert("FiatToken: mint amount not greater than 0");
    proxiedUsdcV3.transfer(someUser, 0);
    // 3. transfer some amount to someUser will success
    vm.prank(me);
    proxiedUsdcV3.transfer(someUser, 100);
    assertEq(proxiedUsdcV3.balanceOf(someUser), 1100);
    assertEq(proxiedUsdcV3.balanceOf(me), 900);
    // 4. transfer amount more than balance will fail
    vm.prank(me);
    vm.expectRevert("FiatToken: transfer amount exceeds balance");
    proxiedUsdcV3.transfer(someUser, 1000);
    // 5. someUser not in the allowlist cannot transfer
    vm.prank(someUser);
    vm.expectRevert("not allowed");
    proxiedUsdcV3.transfer(me, 100);
    assertEq(proxiedUsdcV3.balanceOf(someUser), 1100);
    assertEq(proxiedUsdcV3.balanceOf(me), 900);
  }

  // only user in the allowlist can transferFrom
  function testTransferFrom() public
    topUpUsers
    takeOwnershipOfV2(me)
    upgradeToV3(admin)
    setAllowlist(me, me)
  {
    // me in the allowlist can transferFrom
    vm.prank(me);
    proxiedUsdcV3.transferFrom(someUser, me, 100);
    assertEq(proxiedUsdcV3.balanceOf(someUser), 900);
    assertEq(proxiedUsdcV3.balanceOf(me), 1100);
    vm.prank(me);
    proxiedUsdcV3.transferFrom(someUser, me, 1000);
    assertEq(proxiedUsdcV3.balanceOf(someUser), 0);
    assertEq(proxiedUsdcV3.balanceOf(me), 2000);
    vm.prank(me);
    vm.expectRevert("This account is empty, don't be so greedy");
    proxiedUsdcV3.transferFrom(someUser, me, 1000);

    // me can also transferFrom itselfto someUser
    vm.prank(me);
    proxiedUsdcV3.transferFrom(me, someUser, 100);
    assertEq(proxiedUsdcV3.balanceOf(someUser), 100);
    assertEq(proxiedUsdcV3.balanceOf(me), 1900);

    // someUser not in the allowlist cannot transferFrom
    vm.prank(someUser);
    vm.expectRevert("not allowed");
    proxiedUsdcV3.transferFrom(me, someUser, 100);
    assertEq(proxiedUsdcV3.balanceOf(someUser), 100);
    assertEq(proxiedUsdcV3.balanceOf(me), 1900);
  }
}
