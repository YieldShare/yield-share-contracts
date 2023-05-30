// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from 'solmate/tokens/ERC20.sol';
import {ERC4626} from 'solmate/mixins/ERC4626.sol';
import {DSTestFull} from 'test/utils/DSTestFull.sol';
import {YieldShare} from 'contracts/YieldShare.sol';

abstract contract Base is DSTestFull {
  address internal _owner = _label('owner');
  ERC20 internal _token = ERC20(_mockContract('token'));
  ERC4626 internal _vault = ERC4626(_mockContract('vault'));
  YieldShare internal _yieldShare;

  function setUp() public virtual {
    vm.prank(_owner);
    _yieldShare = new YieldShare(_token, _vault);

    // Mock ERC20 calls
    vm.mockCall(address(_token), abi.encodeWithSelector(ERC20.transferFrom.selector), abi.encode(true));
    vm.mockCall(address(_token), abi.encodeWithSelector(ERC20.approve.selector), abi.encode(true));
  }
}
