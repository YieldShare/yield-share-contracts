// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {ERC20} from 'isolmate/tokens/ERC20.sol';
import {ERC4626} from 'isolmate/mixins/ERC4626.sol';
import {SafeTransferLib} from 'isolmate/utils/SafeTransferLib.sol';

contract YieldShare {
  using SafeTransferLib for ERC20;

  ERC20 public immutable token;
  ERC4626 public immutable vault;

  mapping(address => uint256) public balances;

  constructor(address _token, address _vault) {
    token = ERC20(_token);
    vault = ERC4626(_vault);
  }

  function deposit(uint256 amount) external {
    // Transfer token from the sender
    token.safeTransferFrom({from: msg.sender, to: address(this), amount: amount});

    // Approve token to vault
    token.approve({spender: address(vault), amount: amount}); // @audit Approve type(uint256).max once

    // Deposit into vault
    uint256 shares = vault.deposit({assets: amount, receiver: address(this)});

    // Store sender shares
    balances[msg.sender] += shares;
  }

  function withdraw(uint256 shares) external {
    // Decrease sender shares, implicit check for enough balance
    balances[msg.sender] -= shares;

    // Withdraw from vault
    vault.redeem({shares: shares, receiver: msg.sender, owner: address(this)});
  }
}
