// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {DSTestFull} from 'test/utils/DSTestFull.sol';
import {Balance} from 'contracts/storage/Balance.sol';

contract UnitBalance is DSTestFull {
  using Balance for Balance.Data;

  Balance.Data private balance;

  address internal _user = _label('user');

  function setUp() public {
    balance = Balance.load(_user);
  }

  function test_Increase(uint256 amount) public {
    assertEq(balance.shares, 0);

    balance.increase(amount);

    assertEq(balance.shares, amount);
  }

  function test_Decrease(uint256 amount) public {
    assertEq(balance.shares, 0);

    balance.shares = amount;
    balance.decrease(amount);

    assertEq(balance.shares, 0);
  }
}
