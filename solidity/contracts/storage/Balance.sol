// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Stores the balance for a user
 *
 * The balance is tracked in vault shares
 */
library Balance {
  struct Data {
    /**
     * @dev Amount of current available vault shares
     */
    uint256 shares;
  }

  /**
   * @dev Loads the balance for the user address
   */
  function load(address user) internal pure returns (Data storage store) {
    bytes32 s = keccak256(abi.encode('Balance', user));
    assembly {
      store.slot := s
    }
  }

  /**
   * @dev Increases the shares by `amount`
   */
  function increase(Data storage self, uint256 amount) internal {
    self.shares += amount;
  }

  /**
   * @dev Decreases the shares by `amount`
   */
  function decrease(Data storage self, uint256 amount) internal {
    self.shares -= amount;
  }
}
