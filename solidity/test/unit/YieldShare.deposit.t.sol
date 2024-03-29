// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Base} from 'test/unit/utils/Base.sol';
import {ERC4626} from 'solmate/mixins/ERC4626.sol';
import {IYieldShare} from 'contracts/YieldShare.sol';

contract UnitYieldShareDeposit is Base {
  event SharesDeposited(address indexed user, uint256 shares);

  function test_RevertIfZeroAmountWhenDepositingAssets() public {
    vm.expectRevert(IYieldShare.InvalidAmount.selector);
    _yieldShare.depositAssets(0);
  }

  function test_DepositAssets(address _caller, uint256 _assets) public {
    // VM configs
    vm.assume(_caller != address(0));
    vm.assume(_assets != 0);
    vm.prank(_caller);

    // Mock all ERC calls
    vm.mockCall(address(_vault), abi.encodeWithSelector(ERC4626.deposit.selector), abi.encode(_assets));

    // Expect call to emit event
    vm.expectEmit(true, false, false, true);
    emit SharesDeposited(_caller, _assets);

    _yieldShare.depositAssets(_assets);

    assertEq(_yieldShare.getShares(_caller), _assets);
  }

  function test_RevertIfZeroAmountWhenDepositingShares() public {
    vm.expectRevert(IYieldShare.InvalidAmount.selector);
    _yieldShare.depositShares(0);
  }

  function test_DepositShares(address _caller, uint256 _shares) public {
    // VM configs
    vm.assume(_caller != address(0));
    vm.assume(_shares != 0);
    vm.prank(_caller);

    // Expect call to emit event
    vm.expectEmit(true, false, false, true);
    emit SharesDeposited(_caller, _shares);

    _yieldShare.depositShares(_shares);

    assertEq(_yieldShare.getShares(_caller), _shares);
  }
}
