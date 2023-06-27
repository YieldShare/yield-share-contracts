// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Base} from 'test/unit/utils/Base.sol';
import {ERC4626} from 'solmate/mixins/ERC4626.sol';
import {IYieldShare} from 'contracts/YieldShare.sol';

contract UnitYieldShareCollect is Base {
  event YieldSharingCollected(
    address indexed from, address indexed to, uint256 senderBalance, uint256 receiverBalance, uint256 feeBalance
  );

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
    address _from,
    address _to,
    uint8 _percentage,
    uint256 _currentAssets
  ) public {
    // VM configs
    vm.assume(_caller != address(0));
    vm.assume(_from != _to);
    vm.assume(_shares != 0);
    vm.assume(_to != address(0));
    vm.assume(_from != address(0));
    vm.assume(_currentAssets < (type(uint256).max / 1e18));
    vm.assume(_percentage > 0 && _percentage <= 95);
    vm.startPrank(_from);

    // Mock deposit shares
    vm.mockCall(address(_vault), abi.encodeWithSelector(ERC4626.deposit.selector), abi.encode(_shares));
    _yieldShare.depositAssets(_shares);

    // Mock convertToAssets call
    vm.mockCall(address(_vault), abi.encodeWithSelector(ERC4626.convertToAssets.selector), abi.encode(_shares));

    // Start yield sharing
    _yieldShare.startYieldSharing(_shares, _to, _percentage);

    // Mock convertToAssets call after starting
    vm.mockCall(address(_vault), abi.encodeWithSelector(ERC4626.convertToAssets.selector), abi.encode(_currentAssets));
    (uint256 senderBalance, uint256 receiverBalance, uint256 feeBalance) = _yieldShare.balanceOf(_from, _to);

    vm.stopPrank();
    vm.startPrank(_caller);

    // Expect call to emit event
    vm.expectEmit(true, true, false, true);
    emit YieldSharingCollected(_from, _to, senderBalance, receiverBalance, feeBalance);

    // Stop sharing yield
    _yieldShare.collectYieldSharing(_from, _to);

    {
      // Asserts
      uint256 callerShares = _yieldShare.getShares(_from);
      uint256 toShares = _yieldShare.getShares(_to);
      uint256 feeShares = _yieldShare.getShares(_owner);

      assertEq(callerShares, 0);
      assertEq(toShares, receiverBalance);
      assertEq(feeShares, feeBalance);

      assertGte(toShares, 0);
      assertGte(feeShares, 0);

      assertEq(senderBalance + receiverBalance + feeBalance, _shares);
    }

    (uint256 shares, uint256 lastAssets, uint8 percentage) = _yieldShare.getYieldSharing(_from, _to);
    assertEq(shares, senderBalance);
    assertLte(lastAssets, _currentAssets);
    assertEq(percentage, _percentage);

    // Mock convertToAssets call after collecting
    vm.mockCall(address(_vault), abi.encodeWithSelector(ERC4626.convertToAssets.selector), abi.encode(lastAssets));

    (uint256 senderBalanceAfter, uint256 receiverBalanceAfter, uint256 feeBalanceAfter) =
      _yieldShare.balanceOf(_from, _to);

    assertEq(senderBalanceAfter, senderBalance);
    assertEq(receiverBalanceAfter, 0);
    assertEq(feeBalanceAfter, 0);
  }
}
