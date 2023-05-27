// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Yield Share Contract
 * @author agusduha & alanbenju
 * @notice This is the main contract for the yield share protocol
 */
interface IYieldShare {
  /*///////////////////////////////////////////////////////////////
                            EVENTS
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice User has deposited shares
   * @param user The user that has deposited shares
   * @param shares The number of shares deposited
   */
  event SharesDeposited(address indexed user, uint256 shares);

  /**
   * @notice User has withdrawn shares
   * @param user The user that has withdrawn shares
   * @param shares The number of shares withdrawn
   */
  event SharesWithdrawn(address indexed user, uint256 shares);

  /*///////////////////////////////////////////////////////////////
                            ERRORS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Throws if the function was called with zero amount
   */
  error InvalidAmount();

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  /*///////////////////////////////////////////////////////////////
                            LOGIC
  //////////////////////////////////////////////////////////////*/

  function depositAssets(uint256 amount) external;

  function withdrawAssets(uint256 shares) external;
}
