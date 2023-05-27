// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {IYieldShare} from '../interfaces/IYieldShare.sol';
import {ERC20} from 'isolmate/tokens/ERC20.sol';
import {ERC4626} from 'isolmate/mixins/ERC4626.sol';
import {SafeTransferLib} from 'isolmate/utils/SafeTransferLib.sol';
import {FixedPointMathLib} from 'isolmate/utils/FixedPointMathLib.sol';

contract YieldShare is IYieldShare {
  using SafeTransferLib for ERC20;
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

    emit SharesDeposited(msg.sender, shares);
  }

  function withdrawAssets(uint256 shares) external override {
    if (shares == 0) revert InvalidAmount();

    // Decrease sender shares, implicit check for enough balance
    balances[msg.sender] -= shares;

    // Withdraw from vault
    vault.redeem({shares: shares, receiver: msg.sender, owner: address(this)});

    emit SharesWithdrawn(msg.sender, shares);
  }

  function _getShareId(address from, address to) private pure returns (bytes32 shareId) {
    shareId = keccak256(abi.encode(from, to));
  }

  function startYieldSharing(uint256 shares, address to, uint8 percentage) external {
    // Decrease sender shares, implicit check for enough balance
    balances[msg.sender] -= shares;

    uint256 assets = vault.convertToAssets(shares);

    Share memory yieldShare = Share({shares: shares, lastAssets: assets, percentage: percentage});

    bytes32 shareId = _getShareId(msg.sender, to);

    yieldShares[shareId] = yieldShare;
  }

  function _balanceOf(Share storage yieldShare) private view returns (uint256 senderBalance, uint256 receiverBalance) {
    uint256 currentAssets = vault.convertToAssets(yieldShare.shares);
    uint256 lastAssets = yieldShare.lastAssets;

    uint256 diff = currentAssets - lastAssets;
    uint8 receiverPercentage = yieldShare.percentage;
    uint8 senderPercentage = 100 - receiverPercentage;

    uint256 senderAssets = diff.mulDivDown(senderPercentage, 100);
    uint256 receiverAssets = diff.mulDivDown(receiverPercentage, 100);

    senderBalance = vault.convertToShares(senderAssets);
    receiverBalance = vault.convertToShares(receiverAssets);
  }

  function balanceOf(bytes32 shareId) external view returns (uint256, uint256) {
    Share storage yieldShare = yieldShares[shareId];
    return _balanceOf(yieldShare);
  }

  function collect(address from, address to) external {
    bytes32 shareId = _getShareId(from, to);
    Share storage yieldShare = yieldShares[shareId];

    (uint256 senderBalance, uint256 receiverBalance) = _balanceOf(yieldShare);

    balances[to] += receiverBalance;

    uint256 newlastAssets = vault.convertToAssets(senderBalance); // @audit Calculate it in _balanceOf, another call not needed

    yieldShare.shares = senderBalance;
    yieldShare.lastAssets = newlastAssets;
  }

  function stopYieldSharing(address to) external {
    bytes32 shareId = _getShareId(msg.sender, to);
    Share storage yieldShare = yieldShares[shareId];

    (uint256 senderBalance, uint256 receiverBalance) = _balanceOf(yieldShare);

    balances[to] += receiverBalance;
    balances[msg.sender] += senderBalance;

    // @audit Remove percentage?
    yieldShare.shares = 0;
    yieldShare.lastAssets = 0;
  }
}
