// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Base} from 'test/unit/utils/Base.sol';
import {ERC4626} from 'solmate/mixins/ERC4626.sol';
import {IYieldShare} from 'contracts/YieldShare.sol';

contract UnitYieldShareCollect is Base {
  event YieldSharingCollected(address indexed from, address indexed to, uint256 senderBalance, uint256 receiverBalance);

  function test_RevertIfZeroAddressFrom() public {
    vm.expectRevert(IYieldShare.InvalidAddress.selector);
    _yieldShare.collectYieldSharing(address(0), address(1));
  }

  function test_RevertIfZeroAddressTo() public {
    vm.expectRevert(IYieldShare.InvalidAddress.selector);
    _yieldShare.collectYieldSharing(address(1), address(0));
  }

  function test_CollectYieldSharing(
    address _caller,
    uint256 _shares,
    address _to,
    uint8 _percentage,
    uint256 _currentAssets
  ) public {
    // VM configs
    vm.assume(_caller != address(0));
    vm.assume(_caller != _to);
    vm.assume(_shares != 0);
    vm.assume(_to != address(0));
    vm.assume(_currentAssets < (type(uint256).max / 1e18));
    vm.assume(_percentage > 0 && _percentage <= 100);
    vm.startPrank(_caller);

    // Mock deposit shares
    vm.mockCall(address(_vault), abi.encodeWithSelector(ERC4626.deposit.selector), abi.encode(_shares));
    _yieldShare.depositAssets(_shares);

    // Mock convertToAssets call
    vm.mockCall(address(_vault), abi.encodeWithSelector(ERC4626.convertToAssets.selector), abi.encode(_shares));

    // Start yield sharing
    _yieldShare.startYieldSharing(_shares, _to, _percentage);

    // Mock convertToAssets call after starting
    vm.mockCall(address(_vault), abi.encodeWithSelector(ERC4626.convertToAssets.selector), abi.encode(_currentAssets));
    (uint256 senderBalance, uint256 receiverBalance) = _yieldShare.balanceOf(_caller, _to);

    // Expect call to emit event
    vm.expectEmit(true, true, false, true);
    emit YieldSharingCollected(_caller, _to, senderBalance, receiverBalance);

    // Stop sharing yield
    _yieldShare.collectYieldSharing(_caller, _to);

    // Asserts
    uint256 callerShares = _yieldShare.getShares(_caller);
    uint256 toShares = _yieldShare.getShares(_to);

    assertEq(callerShares, 0);
    assertGte(toShares, 0);
    assertEq(toShares, receiverBalance);
    assertEq(senderBalance + receiverBalance, _shares);

    (uint256 shares, uint256 lastAssets, uint8 percentage) = _yieldShare.getYieldSharing(_caller, _to);
    // if (senderBalance > 0) {
    assertEq(shares, senderBalance);
    assertLte(lastAssets, _currentAssets);
    assertEq(percentage, _percentage);
    // } else {
    //   assertEq(shares, 0);
    //   assertEq(lastAssets, 0);
    //   assertEq(percentage, 0);
    // }

    // Mock convertToAssets call after collecting
    vm.mockCall(address(_vault), abi.encodeWithSelector(ERC4626.convertToAssets.selector), abi.encode(lastAssets));

    (uint256 senderBalanceAfter, uint256 receiverBalanceAfter) = _yieldShare.balanceOf(_caller, _to);
    assertEq(senderBalanceAfter, senderBalance);
    assertEq(receiverBalanceAfter, 0);
  }
}
