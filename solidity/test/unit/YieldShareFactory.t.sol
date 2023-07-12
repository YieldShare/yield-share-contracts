// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from 'solmate/tokens/ERC20.sol';
import {ERC4626} from 'solmate/mixins/ERC4626.sol';
import {DSTestFull} from 'test/utils/DSTestFull.sol';
import {YieldShare} from 'contracts/YieldShare.sol';
import {YieldShareFactory, IYieldShareFactory} from 'contracts/YieldShareFactory.sol';

contract UnitYieldShareFactory is DSTestFull {
  address internal _owner = _label('owner');
  address internal _treasury = _label('treasury');
  ERC20 internal _token = ERC20(_mockContract('token'));
  ERC4626 internal _vault = ERC4626(_mockContract('vault'));
  YieldShare internal _yieldShare;
  IYieldShareFactory internal _yieldShareFactory;

  event YieldShareContractCreated(address vault, address yieldShare);
  event TreasuryChanged(address oldTreasury, address newTreasury);

  function setUp() public {
    vm.prank(_owner);

    _yieldShareFactory = new YieldShareFactory(_treasury);

    vm.mockCall(address(_vault), abi.encodeWithSignature('asset()'), abi.encode(_token));
  }

  function test_DeployYieldShareContract() public {
    vm.startPrank(_owner);

    (address predictedAddress, bool isDeployed) = _yieldShareFactory.getYieldShareContractByVault(_vault);
    assertFalse(isDeployed);

    // Expect call to emit event
    vm.expectEmit(false, false, false, true);
    emit YieldShareContractCreated(address(_vault), predictedAddress);

    _yieldShare = YieldShare(_yieldShareFactory.createYieldShareContract(_vault));

    assertNotEq(address(_yieldShare), address(0));
    assertEq(address(_yieldShare), predictedAddress);
    assertEq(address(_yieldShare.VAULT()), address(_vault));
    assertEq(address(_yieldShare.TOKEN()), address(_token));
    assertEq(address(_yieldShare.TREASURY()), _treasury);

    (, bool isDeployedAfter) = _yieldShareFactory.getYieldShareContractByVault(_vault);
    assertTrue(isDeployedAfter);
  }

  function test_RevertIfDeployingSameYieldShareContract() public {
    vm.startPrank(_owner);

    _yieldShare = YieldShare(_yieldShareFactory.createYieldShareContract(_vault));

    vm.expectRevert();

    _yieldShare = YieldShare(_yieldShareFactory.createYieldShareContract(_vault));
  }

  function test_ChangeTreasury() public {
    vm.startPrank(_owner);

    assertEq(_yieldShareFactory.treasury(), _treasury);

    address newTreasury = address(1);

    // Expect call to emit event
    vm.expectEmit(false, false, false, true);
    emit TreasuryChanged(_treasury, newTreasury);

    _yieldShareFactory.setTreasury(newTreasury);

    assertEq(_yieldShareFactory.treasury(), address(1));
  }

  function test_DeployYieldShareContractWithDifferentTreasury() public {
    vm.startPrank(_owner);

    _yieldShare = YieldShare(_yieldShareFactory.createYieldShareContract(_vault));

    assertNotEq(address(_yieldShare), address(0));
    assertEq(address(_yieldShare.TREASURY()), _treasury);

    // Add treasury
  }
}
