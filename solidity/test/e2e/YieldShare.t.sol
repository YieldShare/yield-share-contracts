// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {CommonE2EBase} from 'test/e2e/Common.sol';

contract E2EYieldShare is CommonE2EBase {
  uint256 private constant _ASSETS = 1e18; // 1 DAI
  uint8 private constant _PERCENTAGE = 10; // 10%

  function setUp() public override {
    super.setUp();
    vm.startPrank(_daiWhale);
  }

  function test_DepositAssets() public {
    // Setup
    _dai.approve(address(_yieldShare), _ASSETS);

    // Deposit
    _yieldShare.depositAssets(_ASSETS);

    // Check current balance
    assertEq(_yieldShare.balances(_daiWhale), _ASSETS);
  }

  function test_StartYieldSharing() public {
    // Setup
    _dai.approve(address(_yieldShare), _ASSETS);
    _yieldShare.depositAssets(_ASSETS);

    // Start yield sharing
    uint256 balance = _yieldShare.balances(_daiWhale);
    _yieldShare.startYieldSharing(balance, _user, _PERCENTAGE);

    // Check balances are both zero
    assertEq(_yieldShare.balances(_daiWhale), 0);
    assertEq(_yieldShare.balances(_user), 0);

    // Check yield sharing is correct
    bytes32 shareId = keccak256(abi.encode(_daiWhale, _user));
    (uint256 shares, uint256 lastAssets, uint8 percentage) = _yieldShare.yieldShares(shareId);
    assertEq(shares, balance);
    assertEq(lastAssets, balance);
    assertEq(percentage, _PERCENTAGE);

    // Check current balances
    (uint256 senderBalance, uint256 receiverBalance) = _yieldShare.balanceOf(shareId);
    assertEq(senderBalance, balance);
    assertEq(receiverBalance, 0);
    assertEq(senderBalance + receiverBalance, balance);
  }

  function test_StartYieldSharingThroughTime() public {
    // Setup
    _dai.approve(address(_yieldShare), _ASSETS);
    _yieldShare.depositAssets(_ASSETS);
    uint256 balance = _yieldShare.balances(_daiWhale);
    _yieldShare.startYieldSharing(balance, _user, _PERCENTAGE);

    // Advance time
    vm.warp(block.timestamp + 86_400);

    // Check balances are both zero
    assertEq(_yieldShare.balances(_daiWhale), 0);
    assertEq(_yieldShare.balances(_user), 0);

    // Check yield sharing is correct
    bytes32 shareId = keccak256(abi.encode(_daiWhale, _user));
    (uint256 shares, uint256 lastAssets, uint8 percentage) = _yieldShare.yieldShares(shareId);
    assertEq(shares, balance);
    assertEq(lastAssets, balance);
    assertEq(percentage, _PERCENTAGE);

    // Check current balances
    (uint256 senderBalance, uint256 receiverBalance) = _yieldShare.balanceOf(shareId);
    uint256 delta = balance / 100_000;
    assertLt(senderBalance, balance);
    assertGt(receiverBalance, 0);
    assertAlmostEq(senderBalance, balance, delta);
    assertAlmostEq(receiverBalance, 0, delta);
    assertEq(senderBalance + receiverBalance, balance);
  }

  function test_CollectYieldSharing() public {
    // Setup
    _dai.approve(address(_yieldShare), _ASSETS);
    _yieldShare.depositAssets(_ASSETS);
    uint256 balance = _yieldShare.balances(_daiWhale);
    _yieldShare.startYieldSharing(balance, _user, _PERCENTAGE);
    vm.warp(block.timestamp + 86_400);
    _yieldShare.collectYieldSharing(_daiWhale, _user);

    uint256 delta = balance / 10_000;

    // Check new balances
    assertEq(_yieldShare.balances(_daiWhale), 0);
    assertGt(_yieldShare.balances(_user), 0);
    assertAlmostEq(_yieldShare.balances(_user), 0, delta);

    // Check yield sharing is correct
    bytes32 shareId = keccak256(abi.encode(_daiWhale, _user));
    (uint256 shares, uint256 lastAssets, uint8 percentage) = _yieldShare.yieldShares(shareId);
    assertLt(shares, balance);
    assertAlmostEq(shares, balance, delta);
    assertGt(lastAssets, balance);
    assertAlmostEq(lastAssets, balance, delta);
    assertEq(percentage, _PERCENTAGE);

    // Check current balances
    (uint256 senderBalance, uint256 receiverBalance) = _yieldShare.balanceOf(shareId);
    assertLt(senderBalance, balance);
    assertAlmostEq(senderBalance, balance, delta);
    assertEq(receiverBalance, 0);
    assertEq(senderBalance + receiverBalance, shares);
  }

  function test_StopYieldSharing() public {
    // Setup
    _dai.approve(address(_yieldShare), _ASSETS);
    _yieldShare.depositAssets(_ASSETS);
    uint256 balance = _yieldShare.balances(_daiWhale);
    _yieldShare.startYieldSharing(balance, _user, _PERCENTAGE);
    vm.warp(block.timestamp + 86_400);
    _yieldShare.stopYieldSharing(_user);

    uint256 delta = balance / 10_000;

    // Check new balances
    assertLt(_yieldShare.balances(_daiWhale), balance);
    assertAlmostEq(_yieldShare.balances(_daiWhale), balance, delta);
    assertGt(_yieldShare.balances(_user), 0);
    assertAlmostEq(_yieldShare.balances(_user), 0, delta);

    // Check yield sharing is correct
    bytes32 shareId = keccak256(abi.encode(_daiWhale, _user));
    (uint256 shares, uint256 lastAssets, uint8 percentage) = _yieldShare.yieldShares(shareId);
    assertEq(shares, 0);
    assertEq(lastAssets, 0);
    assertEq(percentage, 0);

    // Check current balances
    (uint256 senderBalance, uint256 receiverBalance) = _yieldShare.balanceOf(shareId);
    assertEq(senderBalance, 0);
    assertEq(receiverBalance, 0);
  }
}
