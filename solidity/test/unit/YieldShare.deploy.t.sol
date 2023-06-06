// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Base} from 'test/unit/utils/Base.sol';
import {ERC20} from 'solmate/tokens/ERC20.sol';
import {ERC4626} from 'solmate/mixins/ERC4626.sol';
import {YieldShare} from 'contracts/YieldShare.sol';

contract UnitYieldShareConstructor is Base {
  function test_TokenSet(ERC20 _token) public {
    _yieldShare = new YieldShare(_token, _vault);

    assertEq(address(_yieldShare.TOKEN()), address(_token));
  }

  function test_VaultSet(ERC4626 _vault) public {
    _yieldShare = new YieldShare(_token, _vault);

    assertEq(address(_yieldShare.VAULT()), address(_vault));
  }
}
