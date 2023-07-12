// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC4626} from 'solmate/mixins/ERC4626.sol';

/**
 * @title Yield Share Factory Contract
 * @author YieldShare
 * @notice This is the factory contract for deploying YieldShare contracts
 */
interface IYieldShareFactory {
  /*///////////////////////////////////////////////////////////////
                            EVENTS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice A Yield Share contract has been created
   * @param vault The vault that is being used to share yield
   * @param yieldShare The yield share contract address
   */
  event YieldShareContractCreated(address vault, address yieldShare);

  /**
   * @notice The treasury has changed
   * @param oldTreasury The old YieldShare treasury address
   * @param newTreasury The new YieldShare treasury address
   */
  event TreasuryChanged(address oldTreasury, address newTreasury);

  /*///////////////////////////////////////////////////////////////
                            ERRORS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Throws if the YieldShare contract creation failed
   */
  error InvalidContractAddress();

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns the current treasury address
   * @return treasury The treasury address
   */
  function treasury() external view returns (address treasury);

  /*///////////////////////////////////////////////////////////////
                            LOGIC
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Set a new treasury address
   *
   * @dev Only owner
   *
   * @param newTreasury The new treasury address
   */
  function setTreasury(address newTreasury) external;

  /**
   * @notice Create a new yield share contract
   *
   * @dev Only owner
   *
   * @param vault The ERC4626 vault to share yield from
   *
   * @return yieldShareContract The yield share contract address
   */
  function createYieldShareContract(ERC4626 vault) external returns (address yieldShareContract);

  /*///////////////////////////////////////////////////////////////
                            VIEW
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns the precalculated yield share contract address from a vault
   *
   * @param vault The ERC4626 vault to share yield from
   *
   * @return predictedAddress The yield share predicted contract address
   * @return isDeployed True if the contract is deployed
   */

  function getYieldShareContractByVault(ERC4626 vault)
    external
    view
    returns (address predictedAddress, bool isDeployed);
}
