// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from 'solmate/tokens/ERC20.sol';
import {ERC4626} from 'solmate/mixins/ERC4626.sol';

contract ERC4626Mock is ERC4626 {
  constructor(ERC20 _token) ERC4626(_token, 'ERC4626 Mock', 'MCK') {}

  function totalAssets() public view override returns (uint256 assets) {
    return asset.balanceOf(address(this));
  }
}
