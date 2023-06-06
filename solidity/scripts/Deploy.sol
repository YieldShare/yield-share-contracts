// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {Script} from 'forge-std/Script.sol';
import {YieldShare} from 'contracts/YieldShare.sol';
import {ERC4626, ERC20} from 'solmate/mixins/ERC4626.sol';

abstract contract Deploy is Script {
  function _deploy(ERC20 token, ERC4626 vault) internal {
    vm.startBroadcast();
    new YieldShare(token, vault);
    vm.stopBroadcast();
  }
}

contract DeployMainnet is Deploy {
  function run() external {
    ERC20 weth = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // _deploy(weth, "vault");
  }
}

contract DeployGoerli is Deploy {
  function run() external {
    ERC20 weth = ERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);

    // _deploy(weth, "vault");
  }
}
