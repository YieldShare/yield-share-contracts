// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC4626} from 'solmate/mixins/ERC4626.sol';
import {FixedPointMathLib} from 'solmate/utils/FixedPointMathLib.sol';

/**
 * @title Stores the state of a yield sharing
 *
 * The yield sharing tracks the shares being used, their last assets value and the percentage being shared
 */
library YieldSharing {
  using FixedPointMathLib for uint256;

  /**
   * @dev The fee percentage for the treasury
   */
  uint8 private constant _FEE_PERCENTAGE = 5;

  struct Data {
    /**
     * @dev Amount of shares being used to share yield
     */
    uint256 shares;
    /**
     * @dev Last assets value of the shares
     */
    uint256 lastAssets;
    /**
     * @dev Percentage being shared
     */
    uint8 percentage;
  }

  /**
   * @dev Loads the yield sharing state for the sharer/receiver tuple
   */
  function load(address sharer, address receiver) internal pure returns (Data storage store) {
    bytes32 s = keccak256(abi.encode('YieldSharing', sharer, receiver));
    assembly {
      store.slot := s
    }
  }

  /**
   * @dev Start a new yield sharing
   */
  function start(Data storage self, uint256 shares, uint256 assets, uint8 percentage) internal {
    self.shares = shares;
    self.lastAssets = assets;
    self.percentage = percentage;
  }

  /**
   * @dev Stop a yield sharing
   */
  function stop(Data storage self) internal {
    self.shares = 0;
    self.lastAssets = 0;
    self.percentage = 0;
  }

  /**
   * @dev Checks if a yield sharing is active
   */
  function isActive(Data storage self) internal view returns (bool active) {
    return self.shares != 0;
  }

  /**
   * @dev Calculates and returns the current balances of the users
   *
   * Calculate the difference between the current asset value and the last asset value of the shares
   *
   * Calculate the corresponding percentage distribution of the assets to the users
   *
   * Convert assets to shares again and return them as balances
   */
  function balanceOf(
    Data storage self,
    ERC4626 vault
  ) internal view returns (uint256 sharerBalance, uint256 receiverBalance, uint256 feeBalance, uint256 sharerAssets) {
    // Calculate assets values
    uint256 currentShares = self.shares;
    uint256 currentAssets = vault.convertToAssets(currentShares);
    uint256 lastAssets = self.lastAssets;

    // Calculate difference between current assets and last assets
    uint256 diff = currentAssets < lastAssets ? 0 : currentAssets - lastAssets;
    uint8 receiverPercentage = self.percentage;

    // Calculate percentage distribution
    uint256 receiverAssets = diff.mulDivDown(receiverPercentage, 100);
    uint256 feeAssets = diff.mulDivDown(_FEE_PERCENTAGE, 100);
    sharerAssets = currentAssets - receiverAssets - feeAssets;

    if (receiverAssets == 0) return (currentShares, 0, 0, currentAssets);

    // Calculate current price per share
    uint256 pricePerShare = currentAssets.divWadDown(currentShares);

    // Convert assets to shares
    sharerBalance = sharerAssets.divWadDown(pricePerShare);
    receiverBalance = receiverAssets.divWadDown(pricePerShare);
    feeBalance = currentShares - sharerBalance - receiverBalance;
  }
}
