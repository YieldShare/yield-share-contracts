// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IYieldShare} from '../interfaces/IYieldShare.sol';
import {ERC4626, ERC20} from 'solmate/mixins/ERC4626.sol';
import {SafeTransferLib} from 'solmate/utils/SafeTransferLib.sol';
import {Balance} from './storage/Balance.sol';
import {YieldSharing} from './storage/YieldSharing.sol';
import {Multicall} from 'openzeppelin/utils/Multicall.sol';

/**
 * @title Contract for sharing a percentage of vault yield.
 * @author YieldShare
 * @dev See IYieldShare.
 */
contract YieldShare is IYieldShare, Multicall {
  using SafeTransferLib for ERC20;
  using SafeTransferLib for ERC4626;
  using Balance for Balance.Data;
  using YieldSharing for YieldSharing.Data;

  /// @inheritdoc	IYieldShare
  ERC20 public immutable TOKEN;

  /// @inheritdoc	IYieldShare
  ERC4626 public immutable VAULT;

  /// @inheritdoc	IYieldShare
  address public immutable TREASURY;

  /**
   * @notice Defines the ERC20 token, ERC4626 vault, and treasury address permanently
   * @param _token Initial treasury address
   * @param _vault Initial treasury address
   * @param _treasury Initial treasury address
   */
  constructor(ERC20 _token, ERC4626 _vault, address _treasury) {
    TOKEN = _token;
    VAULT = _vault;
    TREASURY = _treasury;
  }

  /*///////////////////////////////////////////////////////////////
                        VAULT FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /// @inheritdoc	IYieldShare
  function depositAssets(uint256 amount) external override {
    if (amount == 0) revert InvalidAmount();

    // Transfer token from the sender
    TOKEN.safeTransferFrom({from: msg.sender, to: address(this), amount: amount});

    // Approve token to vault
    TOKEN.approve({spender: address(VAULT), amount: amount});

    // Deposit into vault
    uint256 shares = VAULT.deposit({assets: amount, receiver: address(this)});

    // Store sender shares
    Balance.load(msg.sender).increase(shares);

    emit SharesDeposited(msg.sender, shares);
  }

  /// @inheritdoc	IYieldShare
  function withdrawAssets(uint256 shares) external override {
    if (shares == 0) revert InvalidAmount();

    // Decrease sender shares, implicit check for enough balance
    Balance.load(msg.sender).decrease(shares);

    // Withdraw from vault
    VAULT.redeem({shares: shares, receiver: msg.sender, owner: address(this)});

    emit SharesWithdrawn(msg.sender, shares);
  }

  /// @inheritdoc	IYieldShare
  function depositShares(uint256 amount) external override {
    if (amount == 0) revert InvalidAmount();

    // Transfer shares from the sender
    VAULT.safeTransferFrom({from: msg.sender, to: address(this), amount: amount});

    // Store sender shares
    Balance.load(msg.sender).increase(amount);

    emit SharesDeposited(msg.sender, amount);
  }

  /// @inheritdoc	IYieldShare
  function withdrawShares(uint256 shares) external override {
    if (shares == 0) revert InvalidAmount();

    // Decrease sender shares, implicit check for enough balance
    Balance.load(msg.sender).decrease(shares);

    // Transfer vault shares
    VAULT.safeTransfer({to: msg.sender, amount: shares});

    emit SharesWithdrawn(msg.sender, shares);
  }

  /*///////////////////////////////////////////////////////////////
                      YIELD SHARING FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /// @inheritdoc	IYieldShare
  function startYieldSharing(uint256 shares, address receiver, uint8 percentage) external override {
    if (shares == 0) revert InvalidAmount();
    if (receiver == address(0) && msg.sender != receiver) revert InvalidAddress();
    if (percentage == 0 || percentage > 95) revert InvalidPercentage();

    YieldSharing.Data storage yieldSharing = YieldSharing.load(msg.sender, receiver);

    if (yieldSharing.isActive()) revert AlreadyActive();

    // Decrease sender shares, implicit check for enough balance
    Balance.load(msg.sender).decrease(shares);

    // Calculate current shares value
    uint256 assets = VAULT.convertToAssets(shares);

    // Start sharing yield
    yieldSharing.start(shares, assets, percentage);

    emit YieldSharingStarted(msg.sender, receiver, shares, assets, percentage);
  }

  /// @inheritdoc	IYieldShare
  function stopYieldSharing(address receiver) external override {
    if (receiver == address(0)) revert InvalidAddress();

    YieldSharing.Data storage yieldSharing = YieldSharing.load(msg.sender, receiver);

    // Calculate current balance
    (uint256 sharerBalance, uint256 receiverBalance, uint256 feeBalance,) = yieldSharing.balanceOf(VAULT);

    // Update balances
    Balance.load(receiver).increase(receiverBalance);
    Balance.load(TREASURY).increase(feeBalance);
    Balance.load(msg.sender).increase(sharerBalance);

    // Stop sharing yield
    yieldSharing.stop();

    emit YieldSharingStopped(msg.sender, receiver, sharerBalance, receiverBalance, feeBalance);
  }

  /// @inheritdoc	IYieldShare
  function collectYieldSharing(address sharer, address receiver) external override {
    if (sharer == address(0) || receiver == address(0)) revert InvalidAddress();

    YieldSharing.Data storage yieldSharing = YieldSharing.load(sharer, receiver);

    // Calculate current balance
    (uint256 sharerBalance, uint256 receiverBalance, uint256 feeBalance, uint256 sharerAssets) =
      yieldSharing.balanceOf(VAULT);

    // Update receiver and treasury balances
    Balance.load(receiver).increase(receiverBalance);
    Balance.load(TREASURY).increase(feeBalance);

    // Start sharing yield with updated shares
    yieldSharing.start(sharerBalance, sharerAssets, yieldSharing.percentage);

    emit YieldSharingCollected(sharer, receiver, sharerBalance, receiverBalance, feeBalance);
  }

  /*///////////////////////////////////////////////////////////////
                      VIEW FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /// @inheritdoc	IYieldShare
  function balanceOf(
    address sharer,
    address receiver
  ) external view override returns (uint256 sharerBalance, uint256 receiverBalance, uint256 feeBalance) {
    YieldSharing.Data storage yieldSharing = YieldSharing.load(sharer, receiver);
    (sharerBalance, receiverBalance, feeBalance,) = yieldSharing.balanceOf(VAULT);
  }

  /// @inheritdoc	IYieldShare
  function getShares(address user) external view override returns (uint256 shares) {
    Balance.Data storage balance = Balance.load(user);
    return balance.shares;
  }

  /// @inheritdoc	IYieldShare
  function getYieldSharing(
    address sharer,
    address receiver
  ) external view override returns (uint256 shares, uint256 lastAssets, uint8 percentage) {
    YieldSharing.Data storage yieldSharing = YieldSharing.load(sharer, receiver);
    return (yieldSharing.shares, yieldSharing.lastAssets, yieldSharing.percentage);
  }
}
