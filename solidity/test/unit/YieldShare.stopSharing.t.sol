// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Base} from 'test/unit/utils/Base.sol';
import {ERC4626} from 'solmate/mixins/ERC4626.sol';
import {IYieldShare} from 'contracts/YieldShare.sol';

contract UnitYieldShareStop is Base {
  event YieldSharingStopped(
    address indexed from, address indexed to, uint256 senderBalance, uint256 receiverBalance, uint256 feeBalance
  );

  function test_RevertIfZeroAddressTo() public {
    vm.expectRevert(IYieldShare.InvalidAddress.selector);
    _yieldShare.stopYieldSharing(address(0));
  }

  function test_StopYieldSharing(
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
    vm.assume(_percentage > 0 && _percentage <= 95);
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
    (uint256 senderBalance, uint256 receiverBalance, uint256 feeBalance) = _yieldShare.balanceOf(_caller, _to);

    // Expect call to emit event
    vm.expectEmit(true, true, false, true);
    emit YieldSharingStopped(_caller, _to, senderBalance, receiverBalance, feeBalance);

    // Stop sharing yield
    _yieldShare.stopYieldSharing(_to);

    {
      // Asserts
      uint256 callerShares = _yieldShare.getShares(_caller);
      uint256 toShares = _yieldShare.getShares(_to);
      uint256 feeShares = _yieldShare.getShares(_owner);

      assertLte(callerShares, _shares);
      assertGte(toShares, 0);
      assertGte(feeShares, 0);

      assertEq(callerShares, senderBalance);
      assertEq(toShares, receiverBalance);
      assertEq(feeShares, feeBalance);

      assertEq(callerShares + toShares + feeShares, _shares);
    }

    (uint256 shares, uint256 lastAssets, uint8 percentage) = _yieldShare.getYieldSharing(_caller, _to);
    assertEq(shares, 0);
    assertEq(lastAssets, 0);
    assertEq(percentage, 0);

    (uint256 senderBalanceAfter, uint256 receiverBalanceAfter, uint256 feeBalanceAfter) =
      _yieldShare.balanceOf(_caller, _to);

    assertEq(senderBalanceAfter, 0);
    assertEq(receiverBalanceAfter, 0);
    assertEq(feeBalanceAfter, 0);
  }
}
