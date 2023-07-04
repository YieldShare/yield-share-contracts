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

  event YieldShareVaultCreated(address vault, address yieldShare);

  event TreasuryChanged(address oldTreasury, address newTreasury);

  /*///////////////////////////////////////////////////////////////
                            ERRORS
  //////////////////////////////////////////////////////////////*/

  error InvalidContractAddress();

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  function treasury() external view returns (address treasury);

  /*///////////////////////////////////////////////////////////////
                            LOGIC
  //////////////////////////////////////////////////////////////*/

  function setTreasury(address newTreasury) external;

  function createYieldShareContract(ERC4626 vault) external returns (address yieldShareContract);

  /*///////////////////////////////////////////////////////////////
                            VIEW
  //////////////////////////////////////////////////////////////*/

  function getYieldShareContractByVault(ERC4626 vault)
    external
    view
    returns (address predictedAddress, bool isDeployed);
}
