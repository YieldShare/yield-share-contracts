// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC4626, ERC20} from 'solmate/mixins/ERC4626.sol';

/**
 * @title Yield Share Contract
 * @author YieldShare
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

  event YieldSharingStarted(address indexed from, address indexed to, uint256 shares, uint256 assets, uint8 percentage);

  event YieldSharingStopped(address indexed from, address indexed to, uint256 senderBalance, uint256 receiverBalance);

  event YieldSharingCollected(address indexed from, address indexed to, uint256 senderBalance, uint256 receiverBalance);

  /*///////////////////////////////////////////////////////////////
                            ERRORS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Throws if the function was called with zero amount
   */
  error InvalidAmount();

  /**
   * @notice Throws if the function was called with zero address
   */
  error InvalidAddress();

  /**
   * @notice Throws if the function was called with 0% or greater than 100%
   */
  error InvalidPercentage();

  /**
   * @notice Throws if trying to start a yield sharing that has already started
   */
  error AlreadyActive();

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  function TOKEN() external view returns (ERC20 token);

  function VAULT() external view returns (ERC4626 vault);

  /*///////////////////////////////////////////////////////////////
                            LOGIC
  //////////////////////////////////////////////////////////////*/

  function depositAssets(uint256 amount) external;

  function withdrawAssets(uint256 shares) external;

  function depositShares(uint256 amount) external;

  function withdrawShares(uint256 shares) external;

  function startYieldSharing(uint256 shares, address to, uint8 percentage) external;

  function stopYieldSharing(address to) external;

  function collectYieldSharing(address from, address to) external;

  /*///////////////////////////////////////////////////////////////
                            VIEW
  //////////////////////////////////////////////////////////////*/

  function balanceOf(
    address from,
    address to
  ) external view returns (uint256 senderBalance, uint256 receiverBalance, uint256 feeBalance);

  function getShares(address user) external view returns (uint256 shares);

  function getYieldSharing(
    address from,
    address to
  ) external view returns (uint256 shares, uint256 lastAssets, uint8 percentage);
}
