// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Base} from 'test/unit/utils/Base.sol';
import {ERC4626} from 'solmate/mixins/ERC4626.sol';
import {IYieldShare} from 'contracts/YieldShare.sol';

contract UnitYieldSharing is Base {
  event YieldSharingStarted(address indexed from, address indexed to, uint256 shares, uint256 assets, uint8 percentage);

  function test_RevertIfZeroAmount() public {
    vm.expectRevert(IYieldShare.InvalidAmount.selector);
    _yieldShare.startYieldSharing(0, address(1), 1);
  }

  function test_RevertIfZeroAddressTo() public {
    vm.expectRevert(IYieldShare.InvalidAddress.selector);
    _yieldShare.startYieldSharing(1, address(0), 1);
  }

  function test_RevertIfZeroPercentage() public {
    vm.expectRevert(IYieldShare.InvalidPercentage.selector);
    _yieldShare.startYieldSharing(1, address(1), 0);
  }

  function test_RevertIfGreaterThan100Percentage() public {
    vm.expectRevert(IYieldShare.InvalidPercentage.selector);
    _yieldShare.startYieldSharing(1, address(1), 101);
  }

  function test_StartYieldSharing(address _caller, uint256 _shares, address _to, uint8 _percentage) public {
    // VM configs
    vm.assume(_caller != address(0));
    vm.assume(_shares != 0);
    vm.assume(_to != address(0));
    vm.assume(_percentage > 0 && _percentage <= 100);
    vm.startPrank(_caller);

    // Mock deposit shares
    vm.mockCall(address(_vault), abi.encodeWithSelector(ERC4626.deposit.selector), abi.encode(_shares));
    _yieldShare.depositAssets(_shares);

    // Mock convertToAssets call
    vm.mockCall(address(_vault), abi.encodeWithSelector(ERC4626.convertToAssets.selector), abi.encode(_shares));

    // Expect call to emit event
    vm.expectEmit(true, true, false, true);
    emit YieldSharingStarted(_caller, _to, _shares, _shares, _percentage);

    // Start sharing yield
    _yieldShare.startYieldSharing(_shares, _to, _percentage);

    // Asserts
    assertEq(0, _yieldShare.getShares(_caller));
    assertEq(0, _yieldShare.getShares(_to));

    (uint256 shares, uint256 lastAssets, uint8 percentage) = _yieldShare.getYieldSharing(_caller, _to);
    assertEq(_shares, shares);
    assertEq(_shares, lastAssets);
    assertEq(_percentage, percentage);

    (uint256 senderBalance, uint256 receiverBalance) = _yieldShare.balanceOf(_caller, _to);
    assertEq(_shares, senderBalance);
    assertEq(0, receiverBalance);
  }
}
