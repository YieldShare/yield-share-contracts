// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {ERC20} from 'isolmate/tokens/ERC20.sol';
import {ERC4626} from 'isolmate/mixins/ERC4626.sol';
import {DSTestFull} from 'test/utils/DSTestFull.sol';
import {YieldShare, IYieldShare} from 'contracts/YieldShare.sol';

abstract contract Base is DSTestFull {
  address internal _owner = _label('owner');
  ERC20 internal _token = ERC20(_mockContract('token'));
  ERC4626 internal _vault = ERC4626(_mockContract('vault'));
  bytes32 internal _emptyString = keccak256(bytes(''));
  YieldShare internal _yieldShare;

  function setUp() public virtual {
    vm.prank(_owner);
    _yieldShare = new YieldShare(_token, _vault);

    // Mock ERC20 calls
    vm.mockCall(address(_token), abi.encodeWithSelector(ERC20.transferFrom.selector), abi.encode(true));
    vm.mockCall(address(_token), abi.encodeWithSelector(ERC20.approve.selector), abi.encode(true));
  }
}

contract UnitYieldShareConstructor is Base {
  function test_TokenSet(ERC20 _token) public {
    _yieldShare = new YieldShare(_token, _vault);

    assertEq(address(_yieldShare.token()), address(_token));
  }

  function test_VaultSet(ERC4626 _vault) public {
    _yieldShare = new YieldShare(_token, _vault);

    assertEq(address(_yieldShare.vault()), address(_vault));
  }
}

contract UnitYieldShareDeposit is Base {
  event SharesDeposited(address indexed user, uint256 shares);

  function test_RevertIfZeroAmount() public {
    vm.expectRevert(IYieldShare.InvalidAmount.selector);
    _yieldShare.depositAssets(0);
  }

  function test_DepositAssets(address _caller, uint256 _assets) public {
    // VM configs
    vm.assume(_caller != address(0));
    vm.assume(_assets != 0);
    vm.prank(_caller);

    // Mock all ERC calls
    vm.mockCall(address(_vault), abi.encodeWithSelector(ERC4626.deposit.selector), abi.encode(_assets));

    // Expect call to emit event
    vm.expectEmit(true, false, false, true);
    emit SharesDeposited(_caller, _assets);

    _yieldShare.depositAssets(_assets);

    assertEq(_assets, _yieldShare.balances(_caller));
  }
}

contract UnitYieldShareWithdraw is Base {
  event SharesWithdrawn(address indexed user, uint256 shares);

  function test_RevertIfZeroAmount() public {
    vm.expectRevert(IYieldShare.InvalidAmount.selector);
    _yieldShare.withdrawAssets(0);
  }

  function test_WithdrawAssets(address _caller, uint256 _assets) public {
    // VM configs
    vm.assume(_caller != address(0));
    vm.assume(_assets != 0);
    vm.startPrank(_caller);

    // Mock all ERC calls
    vm.mockCall(address(_vault), abi.encodeWithSelector(ERC4626.deposit.selector), abi.encode(_assets));
    vm.mockCall(address(_vault), abi.encodeWithSelector(ERC4626.redeem.selector), abi.encode(_assets));

    // First deposit assets
    _yieldShare.depositAssets(_assets);

    // Expect call to emit event
    vm.expectEmit(true, false, false, true);
    emit SharesWithdrawn(_caller, _assets);

    _yieldShare.withdrawAssets(_assets);

    assertEq(0, _yieldShare.balances(_caller));
  }
}
