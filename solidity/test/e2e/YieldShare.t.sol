// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {CommonE2EBase} from 'test/e2e/Common.sol';

contract E2EYieldShare is CommonE2EBase {
  uint256 private _ASSETS = 1e18; // 1 DAI
  uint8 private _PERCENTAGE = 10; // 10%

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
}
