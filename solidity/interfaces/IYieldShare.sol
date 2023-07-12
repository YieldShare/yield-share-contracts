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

  /**
   * @notice User has started to share yield
   * @param sharer The user that has started yield sharing
   * @param receiver The user that is receiving the yield sharing
   * @param shares The number of shares sharing yield
   * @param assets The current asset value of the shares
   * @param percentage The percentage of yield sharing
   */
  event YieldSharingStarted(
    address indexed sharer, address indexed receiver, uint256 shares, uint256 assets, uint8 percentage
  );

  /**
   * @notice User has stopped sharing yield
   * @param sharer The user that has stopped yield sharing
   * @param receiver The user that was receiving the yield sharing
   * @param sharerBalance Current settled balance of the sharer
   * @param receiverBalance Current settled balance of the receiver
   * @param feeBalance Current settled balance of the treassury
   */
  event YieldSharingStopped(
    address indexed sharer, address indexed receiver, uint256 sharerBalance, uint256 receiverBalance, uint256 feeBalance
  );

  /**
   * @notice Yield has been collected
   * @param sharer The user that is sharing yield
   * @param receiver The user that is receiving the yield sharing
   * @param sharerBalance Current share balance of the sharer (not settled)
   * @param receiverBalance Current settled balance of the receiver
   * @param feeBalance Current settled balance of the treassury
   */
  event YieldSharingCollected(
    address indexed sharer, address indexed receiver, uint256 sharerBalance, uint256 receiverBalance, uint256 feeBalance
  );

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

  /**
   * @notice Returns the ERC20 token of the contract
   *
   * @dev The token is immutable
   *
   * @return token The ERC20 token of the contract
   */
  function TOKEN() external view returns (ERC20 token);

  /**
   * @notice Returns the ERC4626 vault of the contract
   *
   * @dev The vault is immutable
   *
   * @return vault The ERC4626 vault of the contract
   */
  function VAULT() external view returns (ERC4626 vault);

  /**
   * @notice Returns the treasury address of the contract
   *
   * @dev The treasury is immutable
   *
   * @return treasury The treasury address of the contract
   */
  function TREASURY() external view returns (address treasury);

  /*///////////////////////////////////////////////////////////////
                            LOGIC
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Deposit sender assets into the contract
   *
   * @dev The assets are deposited into the vault and shares are stored as balance
   *
   * @param amount The amount of assets to deposit (can't be zero)
   */
  function depositAssets(uint256 amount) external;

  /**
   * @notice Withdraw sender assets from the contract
   *
   * @dev The assets are redeem from the vault
   *
   * @param shares The number of shares to withdraw (can't be zero)
   */
  function withdrawAssets(uint256 shares) external;

  /**
   * @notice Deposit sender shares into the contract
   *
   * @dev The shares must be from the contract vault
   *
   * @param amount The amount of shares to deposit (can't be zero)
   */
  function depositShares(uint256 amount) external;

  /**
   * @notice Withdraw sender shares from the contract
   *
   * @dev The shares are transferred to the sender
   *
   * @param shares The number of shares to withdraw (can't be zero)
   */
  function withdrawShares(uint256 shares) external;

  /**
   * @notice Start yield sharing
   *
   * @dev The sender is the sharer
   *
   * @param shares The number of shares from which share yield (can't be zero)
   * @param receiver The user that will receive the yield (can't be the sender)
   * @param percentage The percentage of the yield to share (must be between 0% and 95%)
   */
  function startYieldSharing(uint256 shares, address receiver, uint8 percentage) external;

  /**
   * @notice Stop yield sharing
   *
   * @dev The sender is the sharer
   *
   * @param receiver The user that is receiving the yield
   */
  function stopYieldSharing(address receiver) external;

  /**
   * @notice Collect yield sharing
   *
   * @dev Any address can collect yield
   * @dev To collect yield is to settle the current shares of the receiver
   *
   * @param sharer The user that is sharing yield
   * @param receiver The user that is receiving the yield
   */
  function collectYieldSharing(address sharer, address receiver) external;

  /*///////////////////////////////////////////////////////////////
                            VIEW
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns the current balance of a yield sharing
   *
   * @param sharer The user that is sharing yield
   * @param receiver The user that is receiving the yield
   *
   * @return senderBalance Current balance of the sharer
   * @return receiverBalance Current balance of the receiver
   * @return feeBalance Current balance of the treassury
   */
  function balanceOf(
    address sharer,
    address receiver
  ) external view returns (uint256 senderBalance, uint256 receiverBalance, uint256 feeBalance);

  /**
   * @notice Returns the current shares balance of a user
   *
   * @param user The user from which shares are being retrieved
   *
   * @return shares Current shares balance
   */
  function getShares(address user) external view returns (uint256 shares);

  /**
   * @notice Returns the current state of a yield sharing
   *
   * @param sharer The user that is sharing yield
   * @param receiver The user that is receiving the yield
   *
   * @return shares Shares amount sharing yield
   * @return lastAssets Last assets value of the shares
   * @return percentage Percentage of yield being shared
   */
  function getYieldSharing(
    address sharer,
    address receiver
  ) external view returns (uint256 shares, uint256 lastAssets, uint8 percentage);
}
