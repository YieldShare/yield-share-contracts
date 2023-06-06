// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {IYieldShare} from '../interfaces/IYieldShare.sol';
import {ERC4626, ERC20} from 'solmate/mixins/ERC4626.sol';
import {SafeTransferLib} from 'solmate/utils/SafeTransferLib.sol';
import {Balance} from './storage/Balance.sol';
import {YieldSharing} from './storage/YieldSharing.sol';

contract YieldShare is IYieldShare {
  using SafeTransferLib for ERC20;
  using SafeTransferLib for ERC4626;
  using Balance for Balance.Data;
  using YieldSharing for YieldSharing.Data;

  ERC20 public immutable TOKEN;
  ERC4626 public immutable VAULT;

  constructor(ERC20 _token, ERC4626 _vault) {
    TOKEN = _token;
    VAULT = _vault;
  }

  /*///////////////////////////////////////////////////////////////
                        VAULT FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  function depositAssets(uint256 amount) external override {
    if (amount == 0) revert InvalidAmount();

    // Transfer token from the sender
    TOKEN.safeTransferFrom({from: msg.sender, to: address(this), amount: amount});

    // Approve token to vault
    TOKEN.approve({spender: address(VAULT), amount: amount}); // @audit Approve type(uint256).max once

    // Deposit into vault
    uint256 shares = VAULT.deposit({assets: amount, receiver: address(this)});

    // Store sender shares
    Balance.load(msg.sender).increase(shares);

    emit SharesDeposited(msg.sender, shares);
  }

  function withdrawAssets(uint256 shares) external override {
    if (shares == 0) revert InvalidAmount();

    // Decrease sender shares, implicit check for enough balance
    Balance.load(msg.sender).decrease(shares);

    // Withdraw from vault
    VAULT.redeem({shares: shares, receiver: msg.sender, owner: address(this)});

    emit SharesWithdrawn(msg.sender, shares);
  }

  function depositShares(uint256 amount) external override {
    if (amount == 0) revert InvalidAmount();

    // Transfer shares from the sender
    VAULT.safeTransferFrom({from: msg.sender, to: address(this), amount: amount});

    // Store sender shares
    Balance.load(msg.sender).increase(amount);

    emit SharesDeposited(msg.sender, amount);
  }

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

  function startYieldSharing(uint256 shares, address to, uint8 percentage) external override {
    if (shares == 0) revert InvalidAmount();
    if (to == address(0) && msg.sender != to) revert InvalidAddress();
    if (percentage == 0 || percentage > 100) revert InvalidPercentage();

    YieldSharing.Data storage yieldSharing = YieldSharing.load(msg.sender, to);

    if (yieldSharing.isActive()) revert AlreadyActive();

    // Decrease sender shares, implicit check for enough balance
    Balance.load(msg.sender).decrease(shares);

    // Calculate current shares value
    uint256 assets = VAULT.convertToAssets(shares);

    // Start sharing yield
    yieldSharing.start(shares, assets, percentage);

    emit YieldSharingStarted(msg.sender, to, shares, assets, percentage);
  }

  function stopYieldSharing(address to) external override {
    if (to == address(0)) revert InvalidAddress();

    YieldSharing.Data storage yieldSharing = YieldSharing.load(msg.sender, to);

    // Calculate current balance
    (uint256 senderBalance, uint256 receiverBalance,) = yieldSharing.balanceOf(VAULT);

    // Update balances
    Balance.load(to).increase(receiverBalance);
    Balance.load(msg.sender).increase(senderBalance);

    // Stop sharing yield
    yieldSharing.stop();

    emit YieldSharingStopped(msg.sender, to, senderBalance, receiverBalance);
  }

  function collectYieldSharing(address from, address to) external override {
    if (from == address(0) || to == address(0)) revert InvalidAddress();

    YieldSharing.Data storage yieldSharing = YieldSharing.load(msg.sender, to);

    // Calculate current balance
    (uint256 senderBalance, uint256 receiverBalance, uint256 senderAssets) = yieldSharing.balanceOf(VAULT);

    // Update receiver balance
    Balance.load(to).increase(receiverBalance);

    // Start sharing yield with updated shares
    yieldSharing.start(senderBalance, senderAssets, yieldSharing.percentage);

    emit YieldSharingCollected(msg.sender, to, senderBalance, receiverBalance);
  }

  /*///////////////////////////////////////////////////////////////
                      VIEW FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  function balanceOf(
    address from,
    address to
  ) external view override returns (uint256 senderBalance, uint256 receiverBalance) {
    YieldSharing.Data storage yieldSharing = YieldSharing.load(from, to);
    (senderBalance, receiverBalance,) = yieldSharing.balanceOf(VAULT);
  }

  function getShares(address user) external view returns (uint256 shares) {
    Balance.Data storage balance = Balance.load(user);
    return balance.shares;
  }

  function getYieldSharing(
    address from,
    address to
  ) external view returns (uint256 shares, uint256 lastAssets, uint8 percentage) {
    YieldSharing.Data storage yieldSharing = YieldSharing.load(from, to);
    return (yieldSharing.shares, yieldSharing.lastAssets, yieldSharing.percentage);
  }
}
