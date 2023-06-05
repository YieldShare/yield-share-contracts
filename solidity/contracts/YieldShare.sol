// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {IYieldShare} from '../interfaces/IYieldShare.sol';
import {ERC20} from 'solmate/tokens/ERC20.sol';
import {ERC4626} from 'solmate/mixins/ERC4626.sol';
import {SafeTransferLib} from 'solmate/utils/SafeTransferLib.sol';
import {FixedPointMathLib} from 'solmate/utils/FixedPointMathLib.sol';

contract YieldShare is IYieldShare {
  using SafeTransferLib for ERC20;
  using SafeTransferLib for ERC4626;
  using FixedPointMathLib for uint256;

  ERC20 public immutable token;
  ERC4626 public immutable vault;

  mapping(address => uint256) public balances;

  struct Share {
    uint256 shares;
    uint256 lastAssets;
    uint8 percentage;
  }

  // shareId => Share
  mapping(bytes32 => Share) public yieldShares;

  constructor(ERC20 _token, ERC4626 _vault) {
    token = _token;
    vault = _vault;
  }

  /*///////////////////////////////////////////////////////////////
                        VAULT FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  function depositAssets(uint256 amount) external override {
    if (amount == 0) revert InvalidAmount();

    // Transfer token from the sender
    token.safeTransferFrom({from: msg.sender, to: address(this), amount: amount});

    // Approve token to vault
    token.approve({spender: address(vault), amount: amount}); // @audit Approve type(uint256).max once

    // Deposit into vault
    uint256 shares = vault.deposit({assets: amount, receiver: address(this)});

    // Store sender shares
    balances[msg.sender] += shares;

    emit SharesDeposited(msg.sender, shares); // @audit emit AssetsDeposited?
  }

  function withdrawAssets(uint256 shares) external override {
    if (shares == 0) revert InvalidAmount();

    // Decrease sender shares, implicit check for enough balance
    balances[msg.sender] -= shares;

    // Withdraw from vault
    vault.redeem({shares: shares, receiver: msg.sender, owner: address(this)});

    emit SharesWithdrawn(msg.sender, shares);
  }

  function depositShares(uint256 amount) external override {
    if (amount == 0) revert InvalidAmount();

    // Transfer shares from the sender
    vault.safeTransferFrom({from: msg.sender, to: address(this), amount: amount});

    // Store sender shares
    balances[msg.sender] += amount;

    emit SharesDeposited(msg.sender, amount);
  }

  function withdrawShares(uint256 shares) external override {
    if (shares == 0) revert InvalidAmount();

    // Decrease sender shares, implicit check for enough balance
    balances[msg.sender] -= shares;

    // Transfer vault shares
    vault.safeTransfer({to: msg.sender, amount: shares});

    emit SharesWithdrawn(msg.sender, shares);
  }

  /*///////////////////////////////////////////////////////////////
                      YIELD SHARING FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  function startYieldSharing(uint256 shares, address to, uint8 percentage) external override {
    if (shares == 0) revert InvalidAmount();
    if (to == address(0) && msg.sender != to) revert InvalidAddress();
    if (percentage == 0 || percentage > 100) revert InvalidPercentage();
    // @audit check not started yet

    // Decrease sender shares, implicit check for enough balance
    balances[msg.sender] -= shares;

    uint256 assets = vault.convertToAssets(shares);

    Share memory yieldShare = Share({shares: shares, lastAssets: assets, percentage: percentage});

    bytes32 shareId = _getShareId(msg.sender, to);

    yieldShares[shareId] = yieldShare;

    emit YieldSharingStarted(shareId, msg.sender, to, shares, assets, percentage);
  }

  function stopYieldSharing(address to) external override {
    if (to == address(0)) revert InvalidAddress();

    bytes32 shareId = _getShareId(msg.sender, to);
    Share storage yieldShare = yieldShares[shareId];

    (uint256 senderBalance, uint256 receiverBalance,) = _balanceOf(yieldShare);

    balances[to] += receiverBalance;
    balances[msg.sender] += senderBalance;

    yieldShare.shares = 0;
    yieldShare.lastAssets = 0;
    yieldShare.percentage = 0;

    emit YieldSharingStopped(shareId, msg.sender, to, senderBalance, receiverBalance);
  }

  function collectYieldSharing(address from, address to) external override {
    if (from == address(0) || to == address(0)) revert InvalidAddress();

    bytes32 shareId = _getShareId(from, to);
    Share storage yieldShare = yieldShares[shareId];

    (uint256 senderBalance, uint256 receiverBalance, uint256 senderAssets) = _balanceOf(yieldShare);

    balances[to] += receiverBalance;

    yieldShare.shares = senderBalance;
    yieldShare.lastAssets = senderAssets;

    emit YieldSharingCollected(shareId, msg.sender, to, senderBalance, receiverBalance);
  }

  /*///////////////////////////////////////////////////////////////
                      INTERNAL FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  function _getShareId(address from, address to) private pure returns (bytes32 shareId) {
    shareId = keccak256(abi.encode(from, to));
  }

  function _balanceOf(Share storage yieldShare)
    private
    view
    returns (uint256 senderBalance, uint256 receiverBalance, uint256 senderAssets)
  {
    uint256 currentShares = yieldShare.shares;
    uint256 currentAssets = vault.convertToAssets(currentShares);
    uint256 lastAssets = yieldShare.lastAssets;

    uint256 diff = currentAssets < lastAssets ? 0 : currentAssets - lastAssets;
    uint8 receiverPercentage = yieldShare.percentage;

    uint256 receiverAssets = diff.mulDivDown(receiverPercentage, 100);
    senderAssets = currentAssets - receiverAssets;

    if (receiverAssets == 0) return (currentShares, 0, currentAssets);

    uint256 pricePerShare = currentAssets.divWadDown(currentShares);

    senderBalance = senderAssets.divWadDown(pricePerShare);
    receiverBalance = currentShares - senderBalance;
  }

  /*///////////////////////////////////////////////////////////////
                      VIEW FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  function balanceOf(bytes32 shareId) external view override returns (uint256 senderBalance, uint256 receiverBalance) {
    Share storage yieldShare = yieldShares[shareId];
    (senderBalance, receiverBalance,) = _balanceOf(yieldShare);
  }
}
