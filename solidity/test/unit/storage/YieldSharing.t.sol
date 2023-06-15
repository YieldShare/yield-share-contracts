// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {DSTestFull} from 'test/utils/DSTestFull.sol';
import {YieldSharing} from 'contracts/storage/YieldSharing.sol';
import {ERC4626} from 'solmate/mixins/ERC4626.sol';

contract UnitYieldSharing is DSTestFull {
  using YieldSharing for YieldSharing.Data;

  YieldSharing.Data private _yieldSharing;

  address internal _sender = _label('sender');
  address internal _receiver = _label('receiver');

  function setUp() public {
    _yieldSharing = YieldSharing.load(_sender, _receiver);
  }

  function test_Start(uint256 shares, uint256 assets, uint8 percentage) public {
    assertEq(_yieldSharing.shares, 0);
    assertEq(_yieldSharing.lastAssets, 0);
    assertEq(_yieldSharing.percentage, 0);

    _yieldSharing.start(shares, assets, percentage);

    assertEq(_yieldSharing.shares, shares);
    assertEq(_yieldSharing.lastAssets, assets);
    assertEq(_yieldSharing.percentage, percentage);
  }

  function test_Stop() public {
    assertEq(_yieldSharing.shares, 0);
    assertEq(_yieldSharing.lastAssets, 0);
    assertEq(_yieldSharing.percentage, 0);

    _yieldSharing.stop();

    assertEq(_yieldSharing.shares, 0);
    assertEq(_yieldSharing.lastAssets, 0);
    assertEq(_yieldSharing.percentage, 0);
  }

  function test_StopAfterStarting(uint256 shares, uint256 assets, uint8 percentage) public {
    _yieldSharing.start(shares, assets, percentage);

    _yieldSharing.stop();

    assertEq(_yieldSharing.shares, 0);
    assertEq(_yieldSharing.lastAssets, 0);
    assertEq(_yieldSharing.percentage, 0);
  }

  function test_IsActive() public {
    assertFalse(_yieldSharing.isActive());

    _yieldSharing.start(1, 0, 0);

    assertTrue(_yieldSharing.isActive());

    _yieldSharing.stop();

    assertFalse(_yieldSharing.isActive());
  }

  function test_BalanceOf(uint256 shares, uint256 assets, uint8 percentage, uint256 currentAssets) public {
    vm.assume(shares > 0);
    vm.assume(assets > 0);
    vm.assume(assets >= shares);
    vm.assume(currentAssets < (type(uint256).max / 1e18));
    vm.assume(percentage > 0 && percentage <= 100);

    _yieldSharing.start(shares, assets, percentage);

    // Mock convertToAssets call
    ERC4626 _vault = ERC4626(_mockContract('vault'));
    vm.mockCall(address(_vault), abi.encodeWithSelector(ERC4626.convertToAssets.selector), abi.encode(currentAssets));

    (uint256 senderBalance, uint256 receiverBalance, uint256 senderAssets) = _yieldSharing.balanceOf(_vault);

    assertEq(senderBalance + receiverBalance, shares);
    assertLte(senderBalance, shares, 'senderBalance > shares');
    assertLte(receiverBalance, shares, 'receiverBalance > shares');
    assertLte(senderAssets, currentAssets, 'senderAssets > currentAssets');
    assertGte(receiverBalance, 0, 'receiverBalance < 0');
  }

  function test_BalanceOfWithZeroDiff() public {
    _yieldSharing.start(0, 0, 0);

    // Mock convertToAssets call
    ERC4626 _vault = ERC4626(_mockContract('vault'));
    vm.mockCall(address(_vault), abi.encodeWithSelector(ERC4626.convertToAssets.selector), abi.encode(0));

    (uint256 senderBalance, uint256 receiverBalance, uint256 senderAssets) = _yieldSharing.balanceOf(_vault);

    assertEq(senderBalance, 0);
    assertEq(receiverBalance, 0);
    assertEq(senderAssets, 0);
  }

  function test_BalanceOfWithNegativeDiff() public {
    _yieldSharing.start(1, 1, 1);

    // Mock convertToAssets call
    ERC4626 _vault = ERC4626(_mockContract('vault'));
    vm.mockCall(address(_vault), abi.encodeWithSelector(ERC4626.convertToAssets.selector), abi.encode(0));

    (uint256 senderBalance, uint256 receiverBalance, uint256 senderAssets) = _yieldSharing.balanceOf(_vault);

    assertEq(senderBalance, 1);
    assertEq(receiverBalance, 0);
    assertEq(senderAssets, 0);
  }
}
