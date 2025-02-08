// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {ISendEarn} from "./ISendEarn.sol";

interface ISendEarnFactory {
    /// @notice The address of the MetaMorpho contract that SendEarn vaults uses.
    function META_MORPHO() external view returns (address);

    /// @notice The address of the platform that receives Send Earn fees.
    function platform() external view returns (address);

    /// @notice The current split to the referrer.
    function split() external view returns (uint256);

    /// @notice Tracks existing affiliates contracts.
    function affiliates(address) external view returns (address);

    /// @notice Sets the address of the platform that receives Send Earn fees
    function setPlatform(address newPlatform) external;

    /// @notice Sets the split to the referrer.
    function setSplit(uint256 newSplit) external;

    /// @notice Whether a SendEarn vault was created with the factory.
    function isSendEarn(address target) external view returns (bool);

    /// @notice Creates a new SendEarn vault.
    /// @param initialOwner The owner of the vault.
    /// @param asset The address of the underlying asset.
    /// @param name The name of the vault.
    /// @param symbol The symbol of the vault.
    /// @param feeRecipient The address of the fee recipient.
    /// @param collections The address of the collections.
    /// @param salt The salt to use for the SendEarn vault's CREATE2 address.
    function createSendEarn(
        address initialOwner,
        address asset,
        string memory name,
        string memory symbol,
        address feeRecipient,
        address collections,
        bytes32 salt
    ) external returns (ISendEarn sendEarn);

    /// @notice Creates a new SendEarn vault with a referrer.
    /// @param asset The address of the underlying asset.
    /// @param name The name of the vault.
    /// @param symbol The symbol of the vault.
    /// @param referrer The address of the referrer.
    /// @param salt The salt to use for the SendEarn vault's CREATE2 address.
    function createSendEarnWithReferrer(
        address asset,
        string memory name,
        string memory symbol,
        address referrer,
        bytes32 salt
    ) external returns (ISendEarn sendEarn);
}
