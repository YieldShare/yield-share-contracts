// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {DSTestFull} from 'test/utils/DSTestFull.sol';
import {console} from 'forge-std/console.sol';
import {ERC4626} from 'solmate/mixins/ERC4626.sol';
import {ERC20} from 'solmate/tokens/ERC20.sol';
import {AaveV3ERC4626Factory} from 'yield-daddy/aave-v3/AaveV3ERC4626Factory.sol';
import {YieldShare, IYieldShare} from 'contracts/YieldShare.sol';

contract CommonE2EBase is DSTestFull {
  uint256 internal constant _FORK_BLOCK = 43_304_225;

  address internal _user = _label('user');
  address internal _owner = _label('owner');
  address internal _daiWhale = 0x4aac95EBE2eA6038982566741d1860556e265F8B;

  ERC20 internal _dai = ERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063); // Polygon DAI
  AaveV3ERC4626Factory internal _aaveV3Factory = AaveV3ERC4626Factory(0xd847253c30502Af5Ae84275c52f24B438FDd9fE7); // Polygon Factory

  ERC4626 internal _vault;
  IYieldShare internal _yieldShare;

  function setUp() public virtual {
    vm.createSelectFork(vm.rpcUrl('polygon'), _FORK_BLOCK);
    vm.prank(_owner);

    _vault = ERC4626(address(_aaveV3Factory.createERC4626(_dai)));

    _yieldShare = new YieldShare(_dai, _vault, _owner);
  }
}
