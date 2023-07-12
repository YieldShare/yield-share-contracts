// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IYieldShareFactory} from '../interfaces/IYieldShareFactory.sol';
import {YieldShare} from './YieldShare.sol';
import {ERC4626, ERC20} from 'solmate/mixins/ERC4626.sol';
import {Owned} from 'solmate/auth/Owned.sol';

/**
 * @title Factory for creating YieldShare contracts.
 * @author YieldShare
 * @dev See IYieldShareFactory.
 */
contract YieldShareFactory is IYieldShareFactory, Owned {
  /// @inheritdoc	IYieldShareFactory
  address public treasury;

  /**
   * @notice Defines the owner to the msg.sender and sets the initial treasury address
   * @param _treasury Initial treasury address
   */
  constructor(address _treasury) Owned(msg.sender) {
    treasury = _treasury;
  }

  /// @inheritdoc	IYieldShareFactory
  function setTreasury(address _newTreasury) external override onlyOwner {
    address _oldTreasury = treasury;
    treasury = _newTreasury;

    emit TreasuryChanged(_oldTreasury, _newTreasury);
  }

  /// @inheritdoc	IYieldShareFactory
  function createYieldShareContract(ERC4626 _vault) external override onlyOwner returns (address yieldShareContract) {
    ERC20 _token = _vault.asset();

    yieldShareContract =
      address(new YieldShare{salt: bytes32(uint256(uint160(address(_vault))))}(_token, _vault, treasury));

    assert(yieldShareContract != address(0));

    emit YieldShareContractCreated(address(_vault), yieldShareContract);
  }

  /**
   * @dev Get the bytecode of the YieldShare contract.
   */
  function _getBytecode(ERC20 _token, ERC4626 _vault, address _treasury) private pure returns (bytes memory) {
    bytes memory bytecode = type(YieldShare).creationCode;

    return abi.encodePacked(bytecode, abi.encode(_token, _vault, _treasury));
  }

  /// @inheritdoc	IYieldShareFactory
  function getYieldShareContractByVault(ERC4626 _vault)
    external
    view
    override
    returns (address predictedAddress, bool isDeployed)
  {
    bytes memory bytecode = _getBytecode(_vault.asset(), _vault, treasury);

    predictedAddress = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              bytes1(0xff), address(this), bytes32(uint256(uint160(address(_vault)))), keccak256(bytecode)
            )
          )
        )
      )
    );
    isDeployed = predictedAddress.code.length != 0;
  }
}
