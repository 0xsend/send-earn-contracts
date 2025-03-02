// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {ISendEarn} from "./ISendEarn.sol";
import {ISplitConfig} from "./ISplitConfig.sol";
import {IFeeConfig} from "./IFeeConfig.sol";

interface ISendEarnFactory is ISplitConfig, IFeeConfig {
    /// @notice The underlying vault that SendEarn vaults uses.
    function VAULT() external view returns (address);

    /// @notice The default SendEarn vault created with the factory. This vault does not have a referrer.
    function SEND_EARN() external view returns (address);

    /// @notice Tracks existing SendEarn contracts where the affiliate is sharing the fees.
    function affiliates(address) external view returns (address);

    /// @notice Tracks which SendEarn contract a user is depositing into.
    function deposits(address) external view returns (address);

    /// @notice Sets the split to the referrer.
    function setSplit(uint256 newSplit) external;

    /// @notice Whether a SendEarn vault was created with the factory.
    function isSendEarn(address target) external view returns (bool);

    /// @notice Creates a new SendEarn vault with a referrer.
    /// @param referrer The address of the referrer. Passing address(0) will use the default SendEarn vault.
    /// @param salt The salt to use for the SendEarn vault's CREATE2 address.
    function createSendEarn(address referrer, bytes32 salt) external returns (ISendEarn sendEarn);

    /// @notice Sets the deposit vault for a user.
    /// @param vault The address of the vault to set. MUST be a known SendEarn vault. Use isSendEarn to check.
    function setDeposit(address vault) external;

    /// @notice Creates a new SendEarn vault with a referrer and deposits assets into it.
    /// @param referrer The address of the referrer. Passing address(0) will use the default SendEarn vault.
    /// @param salt The salt to use for the SendEarn vault's CREATE2 address.
    /// @param assets The amount of assets to deposit.
    /// @return sendEarn The created SendEarn vault.
    /// @return shares The amount of shares received from the deposit.
    function createAndDeposit(address referrer, bytes32 salt, uint256 assets)
        external
        returns (ISendEarn sendEarn, uint256 shares);
}
