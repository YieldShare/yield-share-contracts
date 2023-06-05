// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Balance {
  struct Data {
    uint256 shares;
  }

  function load(address id) internal pure returns (Data storage store) {
    bytes32 s = keccak256(abi.encode('Balance', id));
    assembly {
      store.slot := s
    }
  }

  /**
   * @dev Increases the shares by `amount`.
   */
  function increase(Data storage self, uint256 amount) internal {
    self.shares += amount;
  }

  /**
   * @dev Decreases the shares by `amount`.
   */
  function decrease(Data storage self, uint256 amount) internal {
    self.shares -= amount;
  }
}
