// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {Script} from 'forge-std/Script.sol';
import {YieldShare} from 'contracts/YieldShare.sol';
import {YieldShareFactory} from 'contracts/YieldShareFactory.sol';
import {ERC4626, ERC20} from 'solmate/mixins/ERC4626.sol';
import {AaveV3ERC4626Factory, IPool, IRewardsController} from 'yield-daddy/aave-v3/AaveV3ERC4626Factory.sol';

abstract contract Deploy is Script {
  function _deployFactory(address treasury) internal returns (YieldShareFactory yieldShareFactory) {
    vm.startBroadcast();
    yieldShareFactory = new YieldShareFactory(treasury);
    vm.stopBroadcast();
  }

  function _deployYieldShare(YieldShareFactory yieldShareFactory, ERC4626 _vault) internal returns (address yieldShare) {
    vm.startBroadcast();
    yieldShare = yieldShareFactory.createYieldShareContract(_vault);
    vm.stopBroadcast();
  }
}

contract DeployMumbai is Deploy {
  function run() external {
    // Deploy a ERC4626 Aave V3 vault
    ERC20 _dai = ERC20(0xF14f9596430931E177469715c591513308244e8F); // Mumbai Aave v3 DAI
    AaveV3ERC4626Factory _aaveV3Factory = AaveV3ERC4626Factory(0x2b7098F8E07eCd12d20Ff7b80Fd57D65DB1B72A3); // Mumbai Factory

    vm.startBroadcast();
    ERC4626 _vault = ERC4626(address(_aaveV3Factory.createERC4626(_dai)));
    vm.stopBroadcast();

    // Deploy YieldShareFactory
    address treasury = address(msg.sender);
    YieldShareFactory yieldShareFactory = _deployFactory(treasury);

    // Deploy YieldShare instance
    _deployYieldShare(yieldShareFactory, _vault);
  }
}

contract DeployPolygon is Deploy {
  function run() external {
    // Deploy a ERC4626 Aave V3 vault
    ERC20 _dai = ERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063); // Polygon DAI
    AaveV3ERC4626Factory _aaveV3Factory = AaveV3ERC4626Factory(0xd847253c30502Af5Ae84275c52f24B438FDd9fE7); // Polygon Factory

    vm.startBroadcast();
    ERC4626 _vault = ERC4626(address(_aaveV3Factory.createERC4626(_dai)));
    vm.stopBroadcast();

    // Deploy YieldShareFactory
    address treasury = address(msg.sender);
    YieldShareFactory yieldShareFactory = _deployFactory(treasury);

    // Deploy YieldShare instance
    _deployYieldShare(yieldShareFactory, _vault);
  }
}

contract DeployAaveV3FactoryMumbai is Deploy {
  function run() external {
    address lendingPool = 0x0b913A76beFF3887d35073b8e5530755D60F78C7;
    address rewardRecipient = msg.sender;
    address rewardsController = 0x67D1846E97B6541bA730f0C24899B0Ba3Be0D087;

    vm.startBroadcast();
    new AaveV3ERC4626Factory(IPool(lendingPool), rewardRecipient, IRewardsController(rewardsController));
    vm.stopBroadcast();
  }
}
