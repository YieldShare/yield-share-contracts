// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {DSTestFull} from 'test/utils/DSTestFull.sol';
import {Balance} from 'contracts/storage/Balance.sol';

contract UnitBalance is DSTestFull {
  using Balance for Balance.Data;

  Balance.Data private _balance;

  address internal _user = _label('user');

  function setUp() public {
    _balance = Balance.load(_user);
  }

  function test_Increase(uint256 amount) public {
    assertEq(_balance.shares, 0);

    _balance.increase(amount);

    assertEq(_balance.shares, amount);
  }

  function test_Decrease(uint256 amount) public {
    assertEq(_balance.shares, 0);

    _balance.shares = amount;
    _balance.decrease(amount);

    assertEq(_balance.shares, 0);
  }
}
