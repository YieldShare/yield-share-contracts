// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC4626} from 'solmate/mixins/ERC4626.sol';
import {FixedPointMathLib} from 'solmate/utils/FixedPointMathLib.sol';

library YieldSharing {
  using FixedPointMathLib for uint256;

  uint8 private constant _FEE_PERCENTAGE = 5;

  struct Data {
    uint256 shares;
    uint256 lastAssets;
    uint8 percentage;
  }

  function load(address from, address to) internal pure returns (Data storage store) {
    bytes32 s = keccak256(abi.encode('YieldSharing', from, to));
    assembly {
      store.slot := s
    }
  }

  function start(Data storage self, uint256 shares, uint256 assets, uint8 percentage) internal {
    self.shares = shares;
    self.lastAssets = assets;
    self.percentage = percentage;
  }

  function stop(Data storage self) internal {
    self.shares = 0;
    self.lastAssets = 0;
    self.percentage = 0;
  }

  function isActive(Data storage self) internal view returns (bool active) {
    return self.shares != 0;
  }

  function balanceOf(
    Data storage self,
    ERC4626 vault
  ) internal view returns (uint256 senderBalance, uint256 receiverBalance, uint256 feeBalance, uint256 senderAssets) {
    uint256 currentShares = self.shares;
    uint256 currentAssets = vault.convertToAssets(currentShares);
    uint256 lastAssets = self.lastAssets;

    uint256 diff = currentAssets < lastAssets ? 0 : currentAssets - lastAssets;
    uint8 receiverPercentage = self.percentage;

    uint256 receiverAssets = diff.mulDivDown(receiverPercentage, 100);
    uint256 feeAssets = diff.mulDivDown(_FEE_PERCENTAGE, 100);
    senderAssets = currentAssets - receiverAssets - feeAssets;

    if (receiverAssets == 0) return (currentShares, 0, 0, currentAssets);

    uint256 pricePerShare = currentAssets.divWadDown(currentShares);

    senderBalance = senderAssets.divWadDown(pricePerShare);
    receiverBalance = receiverAssets.divWadDown(pricePerShare);
    feeBalance = currentShares - senderBalance - receiverBalance;
  }
}
