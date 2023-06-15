// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Base} from 'test/unit/utils/Base.sol';
import {ERC4626} from 'solmate/mixins/ERC4626.sol';
import {IYieldShare} from 'contracts/YieldShare.sol';

contract UnitYieldShareWithdraw is Base {
  event SharesWithdrawn(address indexed user, uint256 shares);

  function test_RevertIfZeroAmountWhenWithdrawingAssets() public {
    vm.expectRevert(IYieldShare.InvalidAmount.selector);
    _yieldShare.withdrawAssets(0);
  }

  function test_WithdrawAssets(address _caller, uint256 _assets) public {
    // VM configs
    vm.assume(_caller != address(0));
    vm.assume(_assets != 0);
    vm.startPrank(_caller);

    // Mock all ERC calls
    vm.mockCall(address(_vault), abi.encodeWithSelector(ERC4626.deposit.selector), abi.encode(_assets));
    vm.mockCall(address(_vault), abi.encodeWithSelector(ERC4626.redeem.selector), abi.encode(_assets));

    // Deposit assets
    _yieldShare.depositAssets(_assets);
    assertEq(_yieldShare.getShares(_caller), _assets);

    // Expect call to emit event
    vm.expectEmit(true, false, false, true);
    emit SharesWithdrawn(_caller, _assets);

    _yieldShare.withdrawAssets(_assets);

    assertEq(_yieldShare.getShares(_caller), 0);
  }

  function test_RevertIfZeroAmountWhenWithdrawingShares() public {
    vm.expectRevert(IYieldShare.InvalidAmount.selector);
    _yieldShare.withdrawShares(0);
  }

  function test_WithdrawShares(address _caller, uint256 _shares) public {
    // VM configs
    vm.assume(_caller != address(0));
    vm.assume(_shares != 0);
    vm.startPrank(_caller);

    // Deposit assets
    _yieldShare.depositShares(_shares);
    assertEq(_yieldShare.getShares(_caller), _shares);

    // Expect call to emit event
    vm.expectEmit(true, false, false, true);
    emit SharesWithdrawn(_caller, _shares);

    _yieldShare.withdrawShares(_shares);

    assertEq(_yieldShare.getShares(_caller), 0);
  }
}
