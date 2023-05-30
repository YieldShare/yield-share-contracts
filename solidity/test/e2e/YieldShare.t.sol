// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {CommonE2EBase} from 'test/e2e/Common.sol';

contract E2EYieldShare is CommonE2EBase {
  function test_DepositAssets() public {
    vm.startPrank(_daiWhale);

    uint256 _assets = 1e18;

    _dai.approve(address(_yieldShare), _assets);

    _yieldShare.depositAssets(_assets);

    assertEq(_yieldShare.balances(_daiWhale), _assets);
  }
}
